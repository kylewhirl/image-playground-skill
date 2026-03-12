#!/usr/bin/env bash
set -euo pipefail

shortcut_name="${SHORTCUT_NAME:-Image gen}"
install_url="https://www.icloud.com/shortcuts/53b4fdcffbbc4b0d9482710055b471aa"
probe_text="${1:-Codex shortcut availability probe}"

if ! command -v shortcuts >/dev/null 2>&1; then
  echo "Error: the macOS 'shortcuts' CLI is not available on PATH." >&2
  exit 1
fi

shortcut_installed="unknown"
list_output=""
if list_output="$(shortcuts list --show-identifiers 2>/dev/null)"; then
  if printf '%s\n' "$list_output" | grep -Fq "${shortcut_name} ("; then
    shortcut_installed="yes"
  else
    shortcut_installed="no"
  fi
fi

output=""
status=0
if ! output="$(shortcuts run "$shortcut_name" --input-path - <<<"$probe_text" 2>&1)"; then
  status=$?
fi

runtime_error="false"
case "$output" in
  *"You are logged out. Please open the ChatGPT app to log in."*|\
  *"There was a problem running the shortcut."*|\
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

Install or re-install the shortcut from:
$install_url

Shortcuts CLI output:
$output
EOF
  exit 2
fi

cat >&2 <<EOF
Shortcut probe failed for '$shortcut_name'.

The shortcut appears to exist, but the run did not complete.
Open the ChatGPT app, confirm you are logged in, run the shortcut manually once if needed, and retry.
This probe uses a throwaway text input and may create a temporary ChatGPT image history entry.

Shortcuts CLI output:
$output
EOF
exit 2
