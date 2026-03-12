#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
prompt="a cozy orange cat in a sunlit window"
style="ChatGPT"
skip_run="false"
output_path="$(cd "$script_dir/../.." && pwd)/output/tahoe-smoke-test.png"
output_type="public.png"

usage() {
  cat <<'EOF'
Usage:
  scripts/tahoe_smoke_test.sh [--prompt "..."] [--style "ChatGPT"] [--output-path output.png] [--skip-run]

Options:
  --prompt TEXT   Prompt to send through the Tahoe shortcut flow.
  --style TEXT    Style name. Default: ChatGPT
  --output-path   Where to save the returned image. Default: output/tahoe-smoke-test.png
  --output-type   Output UTI. Default: public.png
  --skip-run      Only verify the shortcut probe; do not run a real prompt.
  -h, --help      Show this help text.
EOF
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
    --output-path)
      output_path="${2:-}"
      shift 2
      ;;
    --output-type)
      output_type="${2:-}"
      shift 2
      ;;
    --skip-run)
      skip_run="true"
      shift
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

"$script_dir/check_image_playground_shortcut.sh" "$prompt" "$style"

if [[ "$skip_run" == "true" ]]; then
  echo "Tahoe smoke test finished after shortcut probe."
  exit 0
fi

"$script_dir/run_image_playground_shortcut.sh" --prompt "$prompt" --style "$style" --output-path "$output_path" --output-type "$output_type"
echo "Tahoe smoke test completed."
