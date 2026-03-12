---
name: chatgpt-subscription-image-gen
description: Legacy and fallback ChatGPT subscription image generation for macOS systems where the newer Image Playground external-provider workflow is unavailable. Invoke the macOS Shortcuts CLI shortcut named `Image gen`, then use Playwright against `https://chatgpt.com/images` to find and download the newest result. Use when Codex must automate ChatGPT subscription image generation on pre-Tahoe Macs, verify or install the required shortcut, or retrieve the latest generated asset from ChatGPT image history.
---

# ChatGPT Subscription Image Gen

Use this skill for macOS workflows that rely on a logged-in ChatGPT subscription, the Shortcuts app, and browser automation instead of the OpenAI Images API.

## Positioning

- Treat this skill as the legacy and fallback path.
- Prefer it on systems where the newer Image Playground external-provider route is unavailable or unsupported.
- Keep it working even after a Tahoe-native image-generation skill exists, because the shortcut plus browser-history path remains useful on older macOS versions and as a recovery path.

## Prerequisites

- Require macOS and the `shortcuts` CLI.
- Require the shortcut named `Image gen`.
- Require the ChatGPT macOS app to be open and logged in if the shortcut depends on the app session.
- Require a browser session already logged in to ChatGPT at `https://chatgpt.com`.
- Require Playwright tooling. Prefer the installed `playwright` skill wrapper at `~/.codex/skills/playwright/scripts/playwright_cli.sh`.

## Workflow

1. Verify the shortcut first:

```bash
scripts/check_image_gen_shortcut.sh
```

For a single-command smoke test of the legacy path:

```bash
scripts/legacy_smoke_test.sh --prompt "a cozy orange cat in a sunlit window"
```

If the probe says the shortcut is missing, tell the user to install it from:

`https://www.icloud.com/shortcuts/53b4fdcffbbc4b0d9482710055b471aa`

If the shortcut exists but the run fails, tell the user to open the ChatGPT app, confirm they are logged in, and run the shortcut manually once if needed before retrying.

2. Capture the current latest image signature before generating a new one. Use Playwright on `https://chatgpt.com/images`, locate the `My images` section, and extract the first tile's `img.currentSrc || img.src`. Keep that value so you can detect the next image after generation. Prefer the snippet in `references/playwright-download.md`.

3. Run the actual prompt through the shortcut:

```bash
scripts/run_image_gen_shortcut.sh --prompt "a studio product photo of a matte black coffee grinder"
```

4. Poll `https://chatgpt.com/images` with Playwright until the first tile's signature changes from the baseline value.

5. Download the newest image:
- Prefer the first tile inside the `My images` section. In the verified March 11, 2026 layout, these are `button` tiles and the newest item appears first.
- Prefer the tile's explicit `Download this image` button when it is present.
- If no download button is present, prefer a descendant `img.currentSrc` or `img.src`.
- If the first tile exposes only a low-resolution thumbnail, click the tile and inspect the visible dialog/lightbox for the largest visible `img`.
- If the image source is an authenticated URL, download it with Playwright's authenticated request context instead of unauthenticated `curl`.
- If the image source is a `blob:` URL, fetch it in the page context and convert it to a data URL or bytes before saving.

## Playwright Strategy

- Navigate to `https://chatgpt.com/images`.
- Wait for the `My images` heading and at least one tile beneath it.
- Read the first tile before clicking anything.
- Prefer the explicit `Download this image` button when available.
- Use DOM-derived sources before relying on screenshots or pixel scraping.
- Re-snapshot after clicks or modal opens.
- If the page shows `Log in` and no image tiles, stop and tell the user that the current browser context is not authenticated.

## Shortcut Scripts

- `scripts/check_image_gen_shortcut.sh`: run a lightweight probe through the `Image gen` shortcut with test input over stdin. This may create a throwaway image entry.
- `scripts/run_image_gen_shortcut.sh`: send the real prompt to the `Image gen` shortcut from either `--prompt` or `--prompt-file`.
- `scripts/legacy_smoke_test.sh`: verify the shortcut is callable, then optionally run a real prompt through the legacy shortcut path.

## Guardrails

- Do not use this skill for API-key-based image generation; use the API image skill instead.
- Do not assume the ChatGPT Images DOM is stable. Prefer resilient selectors and inspect current DOM state with Playwright.
- Keep downloads inside the current project, typically under `output/` or another user-requested path.
- If generation succeeds but no new tile appears, wait and poll before retrying the shortcut. History can lag behind generation.

## Reference

- Download workflow and Playwright snippets: `references/playwright-download.md`
