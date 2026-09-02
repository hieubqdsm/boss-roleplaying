---
id: F-xxx
name: <tên tính năng ngắn>
status: planned            # planned | in_dev | dev_done | playtesting | pass | fail | shipped
branch: feat/F-xxx-<slug>
priority: P2               # P0 (blocker) | P1 | P2 | P3
assigned: <agent | tên dev>
depends_on: []             # id feature phụ thuộc, vd: [F-003]
auto_test: none            # none | pass | fail   ← agent chạy (GUT / scene test)
playtest:
  assigned: <tester>
  result: pending          # pending | pass | fail   ← TESTER ghi
  checklist: []            # vd: ["Player di chuyển WASD", "Va chạm tường chặn lại"]
  notes: ""
---

<!--
  CÁCH DÙNG: copy file này thành docs/features/F-00X.md, điền các trường.
  Frontmatter là source of truth — agent/ROADMAP/status.sh đọc từ đây.
  Tester chỉ cần sửa 2 dòng: playtest.result + playtest.notes.
-->

# <tên tính năng>

## Mô tả
<Feature này làm gì, đóng vai trò gì trong game.>

## Acceptance criteria (khi nào coi là xong)
- [ ] <yêu cầu 1>
- [ ] <yêu cầu 2>

## Kế hoạch / sub-tasks (cell)
- [ ] <bước 1>
- [ ] <bước 2>

## Cách test tự động (auto_test)
<GHI lệnh/test cụ thể, vd: "GUT: res://tests/test_player.gd". Nếu không có auto test, ghi "không có".>

## Playtest checklist (cho tester)
- [ ] <điều cần kiểm khi chơi thử>
- [ ] <...>

## Lịch sử thay đổi
- <YYYY-MM-DD> — <commit> — <thay đổi gì, vì sao>
