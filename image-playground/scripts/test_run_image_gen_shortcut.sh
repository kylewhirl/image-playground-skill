#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/run-image-gen-test.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

cache_dir="$tmp_dir/cache"
bin_dir="$tmp_dir/bin"
output_path="$tmp_dir/generated.png"
mkdir -p "$cache_dir" "$bin_dir"

write_old_png() {
  local path="$1"
  /usr/bin/base64 -D >"$path" <<'EOF'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+yF9kAAAAASUVORK5CYII=
EOF
}

write_new_png() {
  local path="$1"
  /usr/bin/base64 -D >"$path" <<'EOF'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR42mP8z/C/HwAF/gL+0JsteQAAAABJRU5ErkJggg==
EOF
}

# Seed the cache with an older image that must not be selected.
write_old_png "$cache_dir/older"
touch -t 202603230101.01 "$cache_dir/older"

cat >"$bin_dir/shortcuts" <<EOF
#!/usr/bin/env bash
set -euo pipefail
sleep 1
cat >/dev/null
sleep 1
cp "$cache_dir/template" "$cache_dir/new-after-run"
touch "$cache_dir/new-after-run"
printf 'ImageImage\n'
EOF
chmod +x "$bin_dir/shortcuts"

write_new_png "$cache_dir/template"
touch -t 202603230104.01 "$cache_dir/template"

PATH="$bin_dir:$PATH" \
CHATGPT_IMAGE_CACHE_DIR="$cache_dir" \
"$script_dir/run_image_gen_shortcut.sh" \
  --prompt "test prompt" \
  --output-path "$output_path" \
  --cache-wait-seconds 5 \
  --cache-poll-interval 1

if [[ ! -f "$output_path" ]]; then
  echo "Error: runner did not create '$output_path'." >&2
  exit 1
fi

if ! file "$output_path" | rg -q 'PNG image data'; then
  echo "Error: output is not a PNG." >&2
  exit 1
fi

if cmp -s "$output_path" "$cache_dir/older"; then
  echo "Error: runner copied the pre-existing cache image instead of the new one." >&2
  exit 1
fi

echo "Run-image-gen shortcut test passed."
