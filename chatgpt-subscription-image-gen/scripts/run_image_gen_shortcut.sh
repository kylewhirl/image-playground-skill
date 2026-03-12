#!/usr/bin/env bash
set -euo pipefail

shortcut_name="${SHORTCUT_NAME:-Image gen}"
prompt=""
prompt_file=""

usage() {
  cat <<'EOF'
Usage:
  scripts/run_image_gen_shortcut.sh --prompt "..."
  scripts/run_image_gen_shortcut.sh --prompt-file /path/to/prompt.txt

Options:
  --prompt TEXT        Prompt text to send to the shortcut.
  --prompt-file PATH   Read prompt text from a file.
  --shortcut-name NAME Override the shortcut name. Default: Image gen
  -h, --help           Show this help text.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt)
      prompt="${2:-}"
      shift 2
      ;;
    --prompt-file)
      prompt_file="${2:-}"
      shift 2
      ;;
    --shortcut-name)
      shortcut_name="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument '$1'." >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v shortcuts >/dev/null 2>&1; then
  echo "Error: the macOS 'shortcuts' CLI is not available on PATH." >&2
  exit 1
fi

if [[ -n "$prompt" && -n "$prompt_file" ]]; then
  echo "Error: pass either --prompt or --prompt-file, not both." >&2
  exit 1
fi

if [[ -z "$prompt" && -z "$prompt_file" ]]; then
  echo "Error: a prompt is required." >&2
  usage >&2
  exit 1
fi

input_file=""

if [[ -n "$prompt_file" ]]; then
  if [[ ! -f "$prompt_file" ]]; then
    echo "Error: prompt file '$prompt_file' does not exist." >&2
    exit 1
  fi
  input_file="$prompt_file"
fi

output=""
status=0
if [[ -n "$prompt_file" ]]; then
  if ! output="$(shortcuts run "$shortcut_name" --input-path "$input_file" 2>&1)"; then
    status=$?
  fi
else
  if ! output="$(shortcuts run "$shortcut_name" --input-path - <<<"$prompt" 2>&1)"; then
    status=$?
  fi
fi

if [[ "$status" -ne 0 || "$output" == Error:* ]]; then
  if [[ -n "$output" ]]; then
    printf '%s\n' "$output" >&2
  fi
  exit 1
fi

if [[ -n "$output" ]]; then
  printf '%s\n' "$output"
fi
