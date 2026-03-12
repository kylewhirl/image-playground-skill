---
name: image-playground
description: Use when Codex should generate or edit an image on macOS 26+ by running the `Image Playground Skill` shortcut with a JSON payload file containing `prompt`, `style`, and optional `image_path`, then save the returned image to disk.
---

# Image Playground

Run the shortcut `Image Playground Skill`.

If the shortcut does not exist, install it from:
[https://www.icloud.com/shortcuts/b1370f8002e3410491331b80383af5c6](https://www.icloud.com/shortcuts/b1370f8002e3410491331b80383af5c6)

Run it with:

```bash
scripts/run_image_playground_shortcut.sh --prompt "a cozy orange cat in a sunlit window" --style "ChatGPT" --output-path output/cat.png --output-type public.png
```

Available styles:

- `ChatGPT`
- `Oil Painting (ChatGPT)`
- `Watercolor (ChatGPT)`
- `Vector (ChatGPT)`
- `Anime (ChatGPT)`
- `Print (ChatGPT)`

Expected input structure:

```json
{
  "prompt": "a cozy orange cat in a sunlit window",
  "style": "ChatGPT",
  "image_path": "/absolute/path/to/source.png"
}
```

Pass `image_path` only when doing image-to-image generation, and use an absolute path.

The wrapper script writes that JSON to a temporary file, then runs `shortcuts run "Image Playground Skill" -i /absolute/path/to/payload.json`.

If you get `There was a problem running the shortcut.`, open the ChatGPT app, confirm you are logged in, and run the shortcut manually once.
