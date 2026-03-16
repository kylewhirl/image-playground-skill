#!/usr/bin/env bash
set -euo pipefail

cache_dir="${CHATGPT_IMAGE_CACHE_DIR:-$HOME/Library/Caches/com.openai.chat/com.onevcat.Kingfisher.ImageCache/com.onevcat.Kingfisher.ImageCache.com.openai.chat}"
output_path=""
since_unix_time=""
timeout_seconds="0"
poll_interval="2"
list_only="false"

usage() {
  cat <<'EOF'
Usage:
  scripts/extract_latest_chatgpt_cache_image.sh --output-path /path/to/image.png
  scripts/extract_latest_chatgpt_cache_image.sh --list

Options:
  --output-path PATH     Copy the newest cached image to PATH.
  --cache-dir PATH       Override the ChatGPT image cache directory.
  --since-unix-time N    Only consider images with mtime strictly newer than N.
  --timeout-seconds N    Wait up to N seconds for a matching image to appear.
  --poll-interval N      Poll interval in seconds while waiting. Default: 2
  --list                 Print matching cache entries as tab-separated rows:
                         mtime size format path
  -h, --help             Show this help text.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-path)
      output_path="${2:-}"
      shift 2
      ;;
    --cache-dir)
      cache_dir="${2:-}"
      shift 2
      ;;
    --since-unix-time)
      since_unix_time="${2:-}"
      shift 2
      ;;
    --timeout-seconds)
      timeout_seconds="${2:-}"
      shift 2
      ;;
    --poll-interval)
      poll_interval="${2:-}"
      shift 2
      ;;
    --list)
      list_only="true"
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

if [[ "$list_only" != "true" && -z "$output_path" ]]; then
  echo "Error: either --output-path or --list is required." >&2
  usage >&2
  exit 1
fi

if [[ ! -d "$cache_dir" ]]; then
  echo "Error: cache directory '$cache_dir' does not exist." >&2
  exit 1
fi

if [[ -n "$since_unix_time" && ! "$since_unix_time" =~ ^[0-9]+$ ]]; then
  echo "Error: --since-unix-time must be an integer epoch timestamp." >&2
  exit 1
fi

if ! [[ "$timeout_seconds" =~ ^[0-9]+$ ]]; then
  echo "Error: --timeout-seconds must be an integer." >&2
  exit 1
fi

if ! [[ "$poll_interval" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Error: --poll-interval must be numeric." >&2
  exit 1
fi

list_candidates() {
  local file_path description format mtime size

  while IFS= read -r -d '' file_path; do
    description="$(file -b "$file_path")"
    case "$description" in
      PNG\ image\ data*)
        format="png"
        ;;
      JPEG\ image\ data*)
        format="jpg"
        ;;
      RIFF*\ Web/P\ image*|Web/P\ image*)
        format="webp"
        ;;
      *)
        continue
        ;;
    esac

    mtime="$(stat -f '%m' "$file_path")"
    size="$(stat -f '%z' "$file_path")"

    if [[ -n "$since_unix_time" && "$mtime" -le "$since_unix_time" ]]; then
      continue
    fi

    printf '%s\t%s\t%s\t%s\n' "$mtime" "$size" "$format" "$file_path"
  done < <(find "$cache_dir" -maxdepth 1 -type f -print0)
}

sorted_candidates() {
  list_candidates | sort -t $'\t' -k1,1nr -k2,2nr -k4,4r
}

if [[ "$list_only" == "true" ]]; then
  sorted_candidates
  exit 0
fi

deadline=$(( $(date +%s) + timeout_seconds ))

while true; do
  latest_line="$(sorted_candidates | head -n 1 || true)"
  if [[ -n "$latest_line" ]]; then
    IFS=$'\t' read -r latest_mtime latest_size latest_format latest_source <<<"$latest_line"
    mkdir -p "$(dirname "$output_path")"
    cp "$latest_source" "$output_path"
    printf 'Copied %s image (%s bytes, mtime %s) from %s to %s\n' \
      "$latest_format" "$latest_size" "$latest_mtime" "$latest_source" "$output_path"
    exit 0
  fi

  if (( $(date +%s) >= deadline )); then
    if [[ -n "$since_unix_time" ]]; then
      echo "Error: no cached ChatGPT image newer than '$since_unix_time' appeared in '$cache_dir'." >&2
    else
      echo "Error: no cached ChatGPT images were found in '$cache_dir'." >&2
    fi
    exit 1
  fi

  sleep "$poll_interval"
done
