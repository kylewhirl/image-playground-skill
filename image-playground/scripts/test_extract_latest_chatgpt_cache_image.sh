#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/chatgpt-cache-test.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

cache_dir="$tmp_dir/cache"
output_path="$tmp_dir/latest.png"
mkdir -p "$cache_dir"

write_png() {
  local path="$1"
  /usr/bin/base64 -D >"$path" <<'EOF'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+yF9kAAAAASUVORK5CYII=
EOF
}

write_png "$cache_dir/older"
write_png "$cache_dir/newer"
write_png "$cache_dir/newest"

touch -t 202603230101.01 "$cache_dir/older"
touch -t 202603230102.01 "$cache_dir/newer"
touch -t 202603230103.01 "$cache_dir/newest"

list_output="$("$script_dir/extract_latest_chatgpt_cache_image.sh" --list --cache-dir "$cache_dir")"
first_path="$(printf '%s\n' "$list_output" | head -n 1 | awk -F '\t' '{print $4}')"
if [[ "$first_path" != "$cache_dir/newest" ]]; then
  echo "Error: expected newest cache path first, got '$first_path'." >&2
  exit 1
fi

since_time="$(stat -f '%m' "$cache_dir/newer")"
"$script_dir/extract_latest_chatgpt_cache_image.sh" \
  --cache-dir "$cache_dir" \
  --since-unix-time "$since_time" \
  --output-path "$output_path"

if [[ ! -f "$output_path" ]]; then
  echo "Error: extractor did not create '$output_path'." >&2
  exit 1
fi

if ! file "$output_path" | rg -q 'PNG image data'; then
  echo "Error: extracted output is not a PNG." >&2
  exit 1
fi

echo "Extractor test passed."
