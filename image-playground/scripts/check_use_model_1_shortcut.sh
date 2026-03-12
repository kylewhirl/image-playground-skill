#!/usr/bin/env bash
set -euo pipefail

shortcut_name="${SHORTCUT_NAME:-Use Model 1}"
probe_prompt="${1:-Codex shortcut availability probe}"
probe_style="${2:-ChatGPT}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v shortcuts >/dev/null 2>&1; then
  echo "Error: the macOS 'shortcuts' CLI is not available on PATH." >&2
  exit 1
fi

list_output=""
shortcut_installed="unknown"
if list_output="$(shortcuts list --show-identifiers 2>/dev/null)"; then
  if printf '%s\n' "$list_output" | grep -Fq "${shortcut_name} ("; then
    shortcut_installed="yes"
  else
    shortcut_installed="no"
  fi
fi

payload="$(python3 "$script_dir/build_use_model_1_payload.py" "$probe_prompt" "$probe_style")"
payload_file="$(mktemp "${TMPDIR:-/tmp}/use-model-1-probe.XXXXXX.json")"
trap 'rm -f "$payload_file"' EXIT
printf '%s\n' "$payload" >"$payload_file"

output=""
status=0
if ! output="$(shortcuts run "$shortcut_name" --input-path "$payload_file" 2>&1)"; then
  status=$?
fi

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

if [[ "$shortcut_installed" == "no" && "$runtime_error" != "true" ]]; then
  cat >&2 <<EOF
Shortcut '$shortcut_name' is not installed.

Shortcuts CLI output:
$output
EOF
  exit 2
fi

cat >&2 <<EOF
Shortcut probe failed for '$shortcut_name'.

The shortcut appears to exist, but the run did not complete.
Open the ChatGPT app, confirm you are logged in, run the shortcut manually once if needed, and retry.
This probe sends a structured JSON payload for style '$probe_style' using the external-provider style object.

Shortcuts CLI output:
$output
EOF
exit 2
