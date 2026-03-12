#!/usr/bin/env bash
set -euo pipefail

shortcut_name="${SHORTCUT_NAME:-Use Model 1}"
prompt=""
style="ChatGPT"
json_file=""
output_path=""
output_type=""
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  scripts/run_use_model_1_shortcut.sh --prompt "..." [--style "ChatGPT"] [--output-path output.png]
  scripts/run_use_model_1_shortcut.sh --json-file /path/to/payload.json

Options:
  --prompt TEXT          Prompt text to send to the shortcut.
  --style TEXT           Style name. Default: ChatGPT
  --json-file PATH       Read the full JSON payload from a file.
  --output-path PATH     Save the shortcut output to a file.
  --output-type UTI      Optional output UTI, for example public.png.
  --shortcut-name NAME   Override the shortcut name. Default: Use Model 1
  -h, --help             Show this help text.
EOF
}

validate_style() {
  case "$1" in
    "ChatGPT")
      ;;
    *)
      echo "Error: unsupported built-in style '$1'." >&2
      echo "Only 'ChatGPT' is currently wired with an exact verified style object." >&2
      echo "Use --json-file if you want to pass a fully serialized style object for another variant." >&2
      exit 1
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt)
      prompt="${2:-}"
      shift 2
      ;;
    --style)
      style="${2:-}"
      shift 2
      ;;
    --json-file)
      json_file="${2:-}"
      shift 2
      ;;
    --output-path)
      output_path="${2:-}"
      shift 2
      ;;
    --output-type)
      output_type="${2:-}"
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

if [[ -n "$prompt" && -n "$json_file" ]]; then
  echo "Error: pass either --prompt/--style or --json-file, not both." >&2
  exit 1
fi

if [[ -z "$prompt" && -z "$json_file" ]]; then
  echo "Error: either --prompt or --json-file is required." >&2
  usage >&2
  exit 1
fi

output=""
status=0

run_shortcut() {
  local input_path="$1"
  local -a cmd=("shortcuts" "run" "$shortcut_name" "--input-path" "$input_path")

  if [[ -n "$output_path" ]]; then
    mkdir -p "$(dirname "$output_path")"
    cmd+=("--output-path" "$output_path")
  fi

  if [[ -n "$output_type" ]]; then
    cmd+=("--output-type" "$output_type")
  fi

  if ! output="$("${cmd[@]}" 2>&1)"; then
    status=$?
  fi
}

if [[ -n "$json_file" ]]; then
  if [[ ! -f "$json_file" ]]; then
    echo "Error: JSON file '$json_file' does not exist." >&2
    exit 1
  fi

  run_shortcut "$json_file"
else
  validate_style "$style"
  payload="$(python3 "$script_dir/build_use_model_1_payload.py" "$prompt" "$style")"
  input_file="$(mktemp "${TMPDIR:-/tmp}/use-model-1-run.XXXXXX.json")"
  trap 'rm -f "$input_file"' EXIT
  printf '%s\n' "$payload" >"$input_file"

  run_shortcut "$input_file"
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
