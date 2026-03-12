#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
prompt="a cozy orange cat in a sunlit window"
skip_run="false"

usage() {
  cat <<'EOF'
Usage:
  scripts/legacy_smoke_test.sh [--prompt "..."] [--skip-run]

Options:
  --prompt TEXT   Prompt to send through the legacy shortcut flow.
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

"$script_dir/check_image_gen_shortcut.sh"

if [[ "$skip_run" == "true" ]]; then
  echo "Legacy smoke test finished after shortcut probe."
  exit 0
fi

"$script_dir/run_image_gen_shortcut.sh" --prompt "$prompt"
echo "Legacy smoke test completed."
