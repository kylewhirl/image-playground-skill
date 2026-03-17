---
name: image-playground
description: Use when Codex should generate or edit an image on macOS by preferring the macOS 26+ `Image Playground Skill` shortcut and using the macOS 15 `Image gen` shortcut as backup.
---

# Image Playground

## How to use

Always change into the skill directory first and run scripts as `./scripts/...`.

macOS 26+ default flow:

```bash
cd /path/to/image-playground
./scripts/run_image_playground_shortcut.sh --prompt "a cozy orange cat in a sunlit window" --style "ChatGPT" --output-path output/cat.png --output-type public.png
```

macOS 15 backup flow:

```bash
cd /path/to/image-playground
./scripts/run_image_gen_shortcut.sh --prompt "a cozy orange cat in a sunlit window" --output-path output/cat.png
```

If the `Image gen` shortcut already ran and you only need to pull the latest cached image:

```bash
cd /path/to/image-playground
./scripts/extract_latest_chatgpt_cache_image.sh --output-path output/latest-cache-image.png
```

## Shortcut install links

- `Image Playground Skill`: [https://www.icloud.com/shortcuts/b1370f8002e3410491331b80383af5c6](https://www.icloud.com/shortcuts/b1370f8002e3410491331b80383af5c6)
- `Image gen`: [https://www.icloud.com/shortcuts/53b4fdcffbbc4b0d9482710055b471aa](https://www.icloud.com/shortcuts/53b4fdcffbbc4b0d9482710055b471aa)

## macOS 26+ default flow

Use `./scripts/run_image_playground_shortcut.sh`.

Requirements:

- Apple Intelligence enabled
- Image Playground available on the Mac
- ChatGPT extension enabled inside Image Playground
- ChatGPT extension logged into a ChatGPT account
- `Image Playground Skill` shortcut installed

Available styles:

- `ChatGPT`
- `Oil Painting (ChatGPT)`
- `Watercolor (ChatGPT)`
- `Vector (ChatGPT)`
- `Anime (ChatGPT)`
- `Print (ChatGPT)`

Image-to-image:

- Use `--image-path /absolute/path/to/source.png`
- Only use `--image-path` with `run_image_playground_shortcut.sh`

Example:

```bash
cd /path/to/image-playground
./scripts/run_image_playground_shortcut.sh --prompt "turn this into a watercolor illustration" --style "Watercolor (ChatGPT)" --image-path /absolute/path/to/source.png --output-path output/result.png --output-type public.png
```

## macOS 15 backup flow

Use `./scripts/run_image_gen_shortcut.sh` when the macOS 26+ path is unavailable or when you are on macOS 15.

Requirements:

- ChatGPT macOS app installed
- ChatGPT macOS app open
- ChatGPT macOS app logged in
- `Image gen` shortcut installed
- ChatGPT app image cache available under `~/Library/Caches/com.openai.chat/...`

## Important notes

- Use the wrapper scripts only. Do not call `shortcuts run ...` directly for this skill.
- Image generation can take a while. Do not kill a running generation just because it is slow.
- Never start a second generation while one is already running.
- Do not use absolute paths to the skill scripts. Run them from the skill directory as `./scripts/...`.
- The `Image gen` flow may only output status text like `Image`; the wrapper handles pulling the image from the ChatGPT app cache after that.

## Common failures

- The shortcut is slow: this is normal. Wait longer.
- The ChatGPT app is not logged in: open the app and log in.
- The shortcut is missing: install it from the links above.
- `There was a problem running the shortcut.`: open ChatGPT, confirm login, and run the shortcut manually once if needed.
- `no new cached ChatGPT image created after shortcut start time ...`: the shortcut finished but the app did not write a fresh cache image that the wrapper could use.
- The cache flow grabbed the wrong image: the relevant chat may not have been opened in the app, or cache ordering may not reflect the image you wanted.
- Image Playground fallback fails: Apple Intelligence, Image Playground, or the ChatGPT extension may not be available or ready.
