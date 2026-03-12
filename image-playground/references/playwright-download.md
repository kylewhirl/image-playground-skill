# Playwright Download Workflow

Use this reference only when you need the browser side of the workflow.

## Goal

On `https://chatgpt.com/images`, detect the newest generated image and save it locally without guessing at screenshot coordinates.

## Selector Strategy

Prefer this order:

1. `My images` heading:

```js
[...document.querySelectorAll("h2")].find((el) => el.textContent?.trim() === "My images")
```

2. First image tile below that heading:

```js
const heading = [...document.querySelectorAll("h2")].find((el) => el.textContent?.trim() === "My images");
const section = heading?.parentElement?.nextElementSibling;
const firstTile = section?.querySelector("button");
```

3. Explicit download button on that tile:

```js
firstTile?.querySelector("button[aria-label='Download this image']");
```

4. First descendant image source:

```js
const img = firstTile?.querySelector("img");
img?.currentSrc || img?.src || null;
```

The older fallback is the user-provided grid snippet with `div[role="button"]`. Treat that as a fallback when the verified `My images` structure is not present.

## Baseline Extraction

Before generating a new image, capture the current first-tile signature:

```js
() => {
  const heading = [...document.querySelectorAll("h2")].find((el) => el.textContent?.trim() === "My images");
  const section = heading?.parentElement?.nextElementSibling;
  const tile = section?.querySelector("button");
  const img = tile?.querySelector("img");
  return {
    signature: img?.currentSrc || img?.src || null,
    alt: img?.alt || null,
    text: tile?.textContent?.trim() || null,
  };
}
```

After the shortcut runs, poll until `signature` changes.

## Fallback After Click

If the grid only exposes a thumbnail or a `blob:` URL, click the first tile, then inspect the largest visible image:

```js
() => {
  const visible = [...document.querySelectorAll("img")]
    .map((img) => ({
      src: img.currentSrc || img.src || null,
      width: img.naturalWidth || 0,
      height: img.naturalHeight || 0,
      visible: Boolean(img.offsetWidth || img.offsetHeight || img.getClientRects().length),
    }))
    .filter((item) => item.visible && item.src);

  visible.sort((a, b) => (b.width * b.height) - (a.width * a.height));
  return visible[0] || null;
}
```

## Download Guidance

- If the tile exposes `Download this image`, prefer clicking that button.
- If the source is `https://...`, prefer Playwright's authenticated request context so cookies are preserved.
- If the source is `blob:...`, fetch it inside the page context and return bytes or a data URL.
- If the source is `data:...`, decode and write it directly.

## Failure Modes

- `Log in` button visible and no tiles: the browser session is not authenticated.
- First tile never changes after shortcut run: wait longer; ChatGPT image history can lag.
- First tile changes but download fails with 401/403: use Playwright request context instead of `curl`.
- First tile is not the new image: compare the baseline signature before and after generation instead of assuming ordering alone.
