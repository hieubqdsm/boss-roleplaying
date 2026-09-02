---
# ── Structured handoff ─────────────────────────────────────────────
# Quy tắc: mỗi trường là một "logged fact". Agent/dev khi resume CHỈ đọc được
# từ đây, KHÔNG được giữ state trong hội thoại (model-visible ⟺ logged).
# Schema đầy đủ: docs/WORKFLOW.md §"Kỷ luật state".
last_updated: "{{DATE}}"
phase: planned                 # planned | dev | paused | done
branch: main
handoff_kind: planned-next     # planned-next = làm tiếp luôn | pause = chờ người quyết
current_focus: none            # id feature đang làm, hoặc "none"
next_action: "Nếu file TEMPLATE còn ở gốc: đây là BẢN TEMPLATE — tạo repo game mới (copy template + bash scripts/init.sh '<Tên>') chứ không dev tại đây. Nếu đã init: khởi tạo project.godot ở gốc repo + chốt mô tả game & milestone M0 trong docs/ROADMAP.md, rồi tạo F-001."

# Evidence — việc ĐÃ xong trong session này, kèm bằng chứng (commit/file).
# Không có bằng chứng = coi như chưa làm. (Ralph-handoff: evidence field)
done: []

# Blocker — mỗi dòng: '<cái gì> (→ <điều kiện để gỡ>)'. Rỗng = không kẹt.
blockers: []

# Quyết định đang chờ người (chỉ bắt buộc khi handoff_kind: pause).
decisions_pending:
  - "Chưa chốt mô tả game + milestone M0 (xem docs/ROADMAP.md)"
---

# Session state — {{PROJECT_NAME}}

> **Đọc file này trước.** Đây là entry point resume cho bất kỳ AI/dev nào vào session.
> Workflow đầy đủ: `docs/WORKFLOW.md`.

## Resume nhanh
1. Đọc frontmatter trên: `current_focus` + `next_action` = việc tiếp theo.
2. `done:` = bằng chứng việc đã xong; `blockers:` = đang kẹt cái gì.
3. `handoff_kind: planned-next` → làm tiếp `next_action` luôn.
   `handoff_kind: pause` → trình bày `decisions_pending`, chờ người quyết trước.

## Bối cảnh (không vừa vào field nào)
- Project Godot chưa có `project.godot` — bước đầu tiên là tạo project trong Godot.
