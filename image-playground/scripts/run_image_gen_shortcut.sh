#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
shortcut_name="${SHORTCUT_NAME:-Image gen}"
cache_dir="${CHATGPT_IMAGE_CACHE_DIR:-$HOME/Library/Caches/com.openai.chat/com.onevcat.Kingfisher.ImageCache/com.onevcat.Kingfisher.ImageCache.com.openai.chat}"
lock_dir="${TMPDIR:-/tmp}/image-gen-shortcut.lock"
prompt=""
prompt_file=""
output_path=""
cache_wait_seconds="120"
cache_poll_interval="2"

usage() {
  cat <<'EOF'
Usage:
  scripts/run_image_gen_shortcut.sh --prompt "..." [--output-path /path/to/image.png]
  scripts/run_image_gen_shortcut.sh --prompt-file /path/to/prompt.txt [--output-path /path/to/image.png]

Options:
  --prompt TEXT            Prompt text to send to the shortcut.
  --prompt-file PATH       Read prompt text from a file.
  --output-path PATH       Copy the newest cached ChatGPT image to PATH.
  --cache-dir PATH         Override the ChatGPT image cache directory.
  --cache-wait-seconds N   Wait up to N seconds for a new cached image. Default: 120
  --cache-poll-interval N  Poll interval in seconds while waiting. Default: 2
  --shortcut-name NAME     Override the shortcut name. Default: Image gen
  -h, --help               Show this help text.
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
    --output-path)
      output_path="${2:-}"
      shift 2
      ;;
    --cache-dir)
      cache_dir="${2:-}"
      shift 2
      ;;
    --cache-wait-seconds)
      cache_wait_seconds="${2:-}"
      shift 2
      ;;
    --cache-poll-interval)
      cache_poll_interval="${2:-}"
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

if ! [[ "$cache_wait_seconds" =~ ^[0-9]+$ ]]; then
  echo "Error: --cache-wait-seconds must be an integer." >&2
  exit 1
fi

if ! [[ "$cache_poll_interval" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Error: --cache-poll-interval must be numeric." >&2
  exit 1
fi

if ! mkdir "$lock_dir" 2>/dev/null; then
  lock_pid=""
  if [[ -f "$lock_dir/pid" ]]; then
    lock_pid="$(cat "$lock_dir/pid" 2>/dev/null || true)"
  fi
  echo "Error: another image generation run is already in progress${lock_pid:+ (pid $lock_pid)}. Wait for it to finish. Do not start a duplicate run or kill the running shortcut." >&2
  exit 1
fi
trap 'rm -rf "$lock_dir"' EXIT
printf '%s\n' "$$" >"$lock_dir/pid"

input_file=""
baseline_cache_listing=""
run_started_at=""

copy_cache_line() {
  local cache_line="$1"
  local mtime size format source_path

  IFS=$'\t' read -r mtime size format source_path <<<"$cache_line"
  mkdir -p "$(dirname "$output_path")"
  cp "$source_path" "$output_path"
  printf 'Copied %s image (%s bytes, mtime %s) from %s to %s\n' \
    "$format" "$size" "$mtime" "$source_path" "$output_path"
}

find_new_cache_line() {
  awk -F '\t' -v since="$run_started_at" '
    NR == FNR {
      if (length($0) > 0) {
        seen[$0] = 1
      }
      next
    }
    !seen[$0] && $1 >= since {
      print
      exit
    }
  ' <(printf '%s\n' "$baseline_cache_listing") <(printf '%s\n' "$current_cache_listing")
}

if [[ -n "$prompt_file" ]]; then
  if [[ ! -f "$prompt_file" ]]; then
    echo "Error: prompt file '$prompt_file' does not exist." >&2
    exit 1
  fi
  input_file="$prompt_file"
fi

if [[ -n "$output_path" ]]; then
  run_started_at="$(date +%s)"
  baseline_cache_listing="$("$script_dir/extract_latest_chatgpt_cache_image.sh" --list --cache-dir "$cache_dir" 2>/dev/null || true)"
fi

output=""
status=0
# Important: do not add --output-path/--output-type here.
# The Image gen shortcut returns status text like "Image"; the actual image must be
# extracted from the ChatGPT app cache after the shortcut completes.
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

if [[ -z "$output_path" ]]; then
  exit 0
fi

deadline=$(( $(date +%s) + cache_wait_seconds ))
while true; do
  current_cache_listing="$("$script_dir/extract_latest_chatgpt_cache_image.sh" --list --cache-dir "$cache_dir" 2>/dev/null || true)"
  new_cache_line="$(find_new_cache_line || true)"
  if [[ -n "$new_cache_line" ]]; then
    copy_cache_line "$new_cache_line"
    exit 0
  fi

  if (( $(date +%s) >= deadline )); then
    echo "Error: no new cached ChatGPT image created after shortcut start time '$run_started_at' appeared in '$cache_dir' within ${cache_wait_seconds}s." >&2
    exit 1
  fi

  sleep "$cache_poll_interval"
done
