#!/usr/bin/env bash
set -euo pipefail

shortcut_name="${SHORTCUT_NAME:-Image Playground Skill}"
probe_prompt="${1:-Codex shortcut availability probe}"
probe_style="${2:-ChatGPT}"

if ! command -v shortcuts >/dev/null 2>&1; then
  echo "Error: the macOS 'shortcuts' CLI is not available on PATH." >&2
  exit 1
fi

json_payload="$(python3 -c 'import json, sys; print(json.dumps({"prompt": sys.argv[1], "style": sys.argv[2]}, separators=(",", ":")))' "$probe_prompt" "$probe_style")"
payload_file="$(mktemp "${TMPDIR:-/tmp}/image-playground-probe.XXXXXX.json")"
log_file="$(mktemp "${TMPDIR:-/tmp}/image-playground-probe-log.XXXXXX.txt")"
trap 'rm -f "$payload_file" "$log_file"' EXIT
printf '%s\n' "$json_payload" >"$payload_file"

status=0
if ! shortcuts run "$shortcut_name" -i "$payload_file" >"$log_file" 2>&1; then
  status=$?
fi
output="$(cat "$log_file")"

runtime_error="false"
case "$output" in
  *"You are logged out. Please open the ChatGPT app to log in."*|\
  *"There was a problem running the shortcut."*|\
  *"Running was cancelled"*|\
  *"Couldn’t communicate with a helper application."*)
    runtime_error="true"
    ;;
esac

if [[ "$status" -eq 0 && "$output" != Error:* ]]; then
  echo "Shortcut probe succeeded for '$shortcut_name'."
  if [[ -n "$output" ]]; then
    printf '%s\n' "$output"
  fi
  exit 0
fi

if [[ "$runtime_error" != "true" ]]; then
  cat >&2 <<EOF
Shortcut '$shortcut_name' is not installed.
Install it from:
https://www.icloud.com/shortcuts/b1370f8002e3410491331b80383af5c6

Shortcuts CLI output:
$output
EOF
  exit 2
fi

cat >&2 <<EOF
Shortcut probe failed for '$shortcut_name'.

The shortcut appears to exist, but the run did not complete.
Open the ChatGPT app, confirm you are logged in, run the shortcut manually once if needed, and retry.
This probe writes prompt/style JSON to a temporary file and passes its absolute path with -i.

Shortcuts CLI output:
$output
EOF
exit 2
