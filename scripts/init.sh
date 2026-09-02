#!/usr/bin/env bash
# init.sh — Đặt tên cho project mới sinh từ godot-agent-harness.
# Thay {{PROJECT_NAME}} và {{DATE}} trong mọi file (trừ chính nó).
# Cách chạy:  bash scripts/init.sh "Tên Game Của Bạn"
set -euo pipefail

NAME="${1:-}"
if [ -z "$NAME" ]; then
  echo 'Cách dùng: bash scripts/init.sh "<Tên project>"' >&2
  echo 'Ví dụ:   bash scripts/init.sh "Detector X"' >&2
  exit 1
fi

# Ký tự phá sed ('/' giới hạn thay thế, '&' = whole-match) -> từ chối.
if [[ "$NAME" == *['/&']* ]]; then
  echo "Tên chứa ký tự không hợp lệ ('/' hoặc '&'). Đổi tên khác." >&2
  exit 1
fi

DATE="$(date +%Y-%m-%d)"
SELF='./scripts/init.sh'
echo "→ Đặt tên project: $NAME (ngày $DATE)"

# Xoá marker template — từ điểm này repo là một game repo hợp lệ.
rm -f ./TEMPLATE

hit=0
while IFS= read -r -d '' f; do
  if grep -qF -e '{{PROJECT_NAME}}' -e '{{DATE}}' "$f"; then
    sed -i -e "s/{{PROJECT_NAME}}/$NAME/g" -e "s/{{DATE}}/$DATE/g" "$f"
    echo "  • ${f#./}"
    hit=1
  fi
done < <(find . -type f -not -path './.git/*' -not -path "$SELF" -print0)

if [ "$hit" -eq 0 ]; then
  echo "(Không còn placeholder — có thể bạn đã chạy init rồi.)"
fi

cat <<EOF

✓ Xong. Bước tiếp theo:
  1. git init && git add -A && git commit -m "init project: $NAME"
  2. Tạo project Godot (NGƯỜI DÙNG làm): mở Godot → New Project tại thư mục này
     (hoặc: godot --path . -e) để sinh project.godot. Agent: ghi file trực tiếp,
     KHÔNG mở editor (AGENTS.md §0.2).
  3. Đọc docs/SESSION.md và làm theo next_action.
EOF
