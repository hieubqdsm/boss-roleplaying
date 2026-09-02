#!/usr/bin/env bash
# In bảng trạng thái live của mọi feature (source of truth = docs/features/F-*.md).
# Cách chạy:  bash scripts/status.sh
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DIR="$ROOT/docs/features"

if [ ! -d "$DIR" ]; then
  echo "Không tìm thấy $DIR" >&2
  exit 1
fi

printf "%-8s %-24s %-13s %-10s %-10s %s\n" "ID" "NAME" "STATUS" "AUTO_TEST" "PLAYTEST" "BRANCH"
printf "%-8s %-24s %-13s %-10s %-10s %s\n" "------" "------------------------" "-------------" "----------" "----------" "---------------------"

count=0
shopt -s nullglob
for f in "$DIR"/F-*.md; do
  count=$((count + 1))
  awk '
    /^---$/ { fm = !fm; next }
    fm {
      line = $0
      if (line ~ /^id:/)         { v = line; sub(/^id:[ \t]*/, "", v);    sub(/[ \t]+#.*$/, "", v); id = v }
      if (line ~ /^name:/)       { v = line; sub(/^name:[ \t]*/, "", v);  sub(/[ \t]+#.*$/, "", v); name = v }
      if (line ~ /^status:/)     { v = line; sub(/^status:[ \t]*/, "", v); sub(/[ \t]+#.*$/, "", v); status = v }
      if (line ~ /^auto_test:/)  { v = line; sub(/^auto_test:[ \t]*/, "", v); sub(/[ \t]+#.*$/, "", v); at = v }
      if (line ~ /^branch:/)     { v = line; sub(/^branch:[ \t]*/, "", v); sub(/[ \t]+#.*$/, "", v); br = v }
      if (line ~ /^[ \t]+result:/) { v = line; sub(/^[ \t]+result:[ \t]*/, "", v); sub(/[ \t]+#.*$/, "", v); pt = v }
    }
    END {
      if (id == "")     id = "?"
      if (name == "")   name = "?"
      if (status == "") status = "?"
      if (at == "")     at = "-"
      if (pt == "")     pt = "-"
      if (br == "")     br = "-"
      if (length(name) > 24) name = substr(name, 1, 23) "…"
      printf "%-8s %-24s %-13s %-10s %-10s %s\n", id, name, status, at, pt, br
    }
  ' "$f"
done

if [ "$count" -eq 0 ]; then
  echo "(chưa có feature nào trong $DIR — copy _TEMPLATE.md thành F-00X.md)"
fi
