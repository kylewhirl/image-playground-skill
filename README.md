# Image Playground Skill

Skills for generating images with a ChatGPT subscription on macOS.

This repo is not specific to Codex. It is meant for any CLI or IDE that supports installing and invoking skills from a GitHub repository.

This repo includes two skills:

- `image-playground`: the recommended skill, with a macOS 26+ Image Playground primary path and a macOS 15 fallback path
- `chatgpt-subscription-image-gen`: the macOS 15 legacy path using the `Image gen` shortcut plus Playwright

## Install

If your tool supports [`npx skills`](https://www.npmjs.com/package/skills), install directly from GitHub and choose the skill you want.

Recommended install for most users:

```bash
npx skills add kylewhirl/image-playground-skill --skill image-playground -g -a codex -y
```

Install the dedicated macOS 15 legacy skill only if you want that path on its own:

```bash
npx skills add kylewhirl/image-playground-skill --skill chatgpt-subscription-image-gen -g -a codex -y
```

If your environment is not Codex, replace `-a codex` with the agent/provider name supported by your skills installer.

## macOS 26: Image Playground

Use the `image-playground` skill for both cases:

- macOS 26+: primary Image Playground path
- macOS 15 or macOS 26 failures: fallback `Image gen` path

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

## Responsible Use

- Use these skills in accordance with OpenAI's terms and the terms for any connected app or platform.
- Do not use these skills to evade usage limits, rate limits, access controls, or account restrictions.
- Do not modify these skills to automate prohibited behavior, abusive bulk generation, or other actions that violate platform policies.
