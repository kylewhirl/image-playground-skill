#!/usr/bin/env bash
set -euo pipefail

shortcut_name="${SHORTCUT_NAME:-Image Playground Skill}"
tmp_root="${TMPDIR:-/tmp}"
prompt=""
style="ChatGPT"
image_path=""
json_payload=""
output_path=""
output_type=""

usage() {
  cat <<'EOF'
Usage:
  scripts/run_image_playground_shortcut.sh --prompt "..." [--style "ChatGPT"] [--image-path /path/to/source.png] [--output-path output.png]
  scripts/run_image_playground_shortcut.sh --json '{"prompt":"...","style":"ChatGPT"}' [--output-path output.png]

Options:
  --prompt TEXT          Prompt text to send to the shortcut.
  --style TEXT           Style name. Default: ChatGPT
  --image-path PATH      Optional source image path to include in the JSON.
  --json TEXT            Full JSON payload to write to a temp file for the shortcut.
  --output-path PATH     Save the shortcut output to a file.
  --output-type UTI      Optional output UTI, for example public.png.
  --shortcut-name NAME   Override the shortcut name. Default: Image Playground Skill
  -h, --help             Show this help text.
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
    --image-path)
      image_path="${2:-}"
      shift 2
      ;;
    --json)
      json_payload="${2:-}"
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

if [[ -n "$json_payload" && ( -n "$prompt" || -n "$image_path" || "$style" != "ChatGPT" ) ]]; then
  echo "Error: pass either --json or --prompt/--style/--image-path, not both." >&2
  exit 1
fi

if [[ -z "$json_payload" && -z "$prompt" ]]; then
  echo "Error: either --prompt or --json is required." >&2
  usage >&2
  exit 1
fi

if [[ -n "$image_path" && ! -f "$image_path" ]]; then
  echo "Error: image path '$image_path' does not exist." >&2
  exit 1
fi

if [[ -z "$json_payload" ]]; then
  json_payload="$(python3 -c 'import json, sys; payload = {"prompt": sys.argv[1], "style": sys.argv[2]}; image_path = sys.argv[3]; payload["image_path"] = image_path if image_path else None; payload = {k:v for k,v in payload.items() if v is not None}; print(json.dumps(payload, separators=(",", ":")))' "$prompt" "$style" "$image_path")"
fi

mkdir -p "$tmp_root"
payload_file="$(mktemp "$tmp_root/image-playground-payload.XXXXXX")"
log_file="$(mktemp "$tmp_root/image-playground-log.XXXXXX")"
trap 'rm -f "$payload_file" "$log_file"' EXIT
printf '%s\n' "$json_payload" >"$payload_file"

cmd=("shortcuts" "run" "$shortcut_name" "-i" "$payload_file")
if [[ -n "$output_path" ]]; then
  mkdir -p "$(dirname "$output_path")"
  cmd+=("--output-path" "$output_path")
fi
if [[ -n "$output_type" ]]; then
  cmd+=("--output-type" "$output_type")
fi

status=0
if ! "${cmd[@]}" >"$log_file" 2>&1; then
  status=$?
fi
output="$(cat "$log_file")"

if [[ "$status" -ne 0 || "$output" == Error:* ]]; then
  case "$output" in
    *"not found"*|*"No shortcut named"*|*"Could not find"*|*"not exist"*)
      printf '%s\n' "Install '$shortcut_name' from: https://www.icloud.com/shortcuts/b1370f8002e3410491331b80383af5c6" >&2
      ;;
    *"There was a problem running the shortcut."*)
      printf '%s\n' "Open the ChatGPT app, confirm you are logged in, and run the shortcut manually once if needed." >&2
      ;;
  esac
  if [[ -n "$output" ]]; then
    printf '%s\n' "$output" >&2
  fi
  exit 1
fi

if [[ -n "$output" ]]; then
  printf '%s\n' "$output"
fi
