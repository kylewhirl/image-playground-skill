# Image Playground Skill

Codex skills for generating images with a ChatGPT subscription on macOS.

This repo includes two skills:

- `image-playground`: the macOS 26+ path using the `Image Playground Skill` shortcut
- `chatgpt-subscription-image-gen`: the macOS 15 legacy path using the `Image gen` shortcut plus Playwright

## Install

Codex on macOS 26+:

```bash
npx skills add kylewhirl/image-playground-skill --skill image-playground -g -a codex -y
```

Codex on macOS 15:

```bash
npx skills add kylewhirl/image-playground-skill --skill chatgpt-subscription-image-gen -g -a codex -y
```

If you use another provider supported by `npx skills`, replace `-a codex` with that provider's agent name.

## macOS 26: Image Playground

Use the `image-playground` skill on macOS 26 or newer.

Prerequisites:

- Apple Intelligence must be enabled.
- Image Playground must be available on the Mac.
- The ChatGPT extension must be enabled inside Image Playground.
- The ChatGPT extension must be logged into a ChatGPT account.
- The shortcut `Image Playground Skill` must be installed:
  [https://www.icloud.com/shortcuts/b1370f8002e3410491331b80383af5c6](https://www.icloud.com/shortcuts/b1370f8002e3410491331b80383af5c6)

The active skill lives in:

- [image-playground/SKILL.md](image-playground/SKILL.md)

## macOS 15: Image gen

Use the `chatgpt-subscription-image-gen` skill on macOS 15 systems where the newer Image Playground route is unavailable.

Prerequisites:

- The ChatGPT macOS app must be installed.
- The ChatGPT macOS app must be open and logged in.
- The shortcut `Image gen` must be installed:
  [https://www.icloud.com/shortcuts/53b4fdcffbbc4b0d9482710055b471aa](https://www.icloud.com/shortcuts/53b4fdcffbbc4b0d9482710055b471aa)
- The Playwright browser profile used by the agent must already be logged into ChatGPT.

The legacy skill lives in:

- [chatgpt-subscription-image-gen/SKILL.md](chatgpt-subscription-image-gen/SKILL.md)

## Repo Layout

- `image-playground/`: macOS 26+ Image Playground skill
- `chatgpt-subscription-image-gen/`: macOS 15 legacy ChatGPT shortcut skill
