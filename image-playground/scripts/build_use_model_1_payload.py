#!/usr/bin/env python3

import json
import sys


SUPPORTED_STYLES = {
    "ChatGPT": {
        "title": {"key": "ChatGPT"},
        "subtitle": {"key": "ChatGPT"},
        "image": {
            "type": "URL",
            "uri": "intents-remote-image-proxy:?proxyIdentifier=A1E11A41-FD81-D2E6-4BEE-6CBDC92DF54D.png&storageServiceIdentifier=com.apple.Intents.INImageServiceConnection",
            "storageServiceIdentifier": "com.apple.Intents.INImageServiceConnection",
        },
        "identifier": "z_external_provider",
    }
}


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: build_use_model_1_payload.py <prompt> <style>", file=sys.stderr)
        return 1

    prompt = sys.argv[1]
    style_name = sys.argv[2]
    style = SUPPORTED_STYLES.get(style_name)
    if style is None:
        print(f"Unsupported style: {style_name}", file=sys.stderr)
        return 1

    payload = {
        "prompt": prompt,
        "style": style,
    }
    print(json.dumps(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
