---
# ── Structured handoff ─────────────────────────────────────────────
# Quy tắc: mỗi trường là một "logged fact". Agent/dev khi resume CHỈ đọc được
# từ đây, KHÔNG được giữ state trong hội thoại (model-visible ⟺ logged).
# Schema đầy đủ: docs/WORKFLOW.md §"Kỷ luật state".
last_updated: "2026-09-02"
phase: dev                   # planned | dev | paused | done
branch: feat/F-001-m0-vertical-slice
handoff_kind: planned-next   # planned-next = làm tiếp luôn | pause = chờ người quyết
current_focus: F-001         # id feature đang làm, hoặc "none"
next_action: "Chờ tester playtest F-001 (desktop F5 hoặc web: python -m http.server 8091 trong build/web). Playwright tự chơi đã verify toàn vòng trên web (bot hạ 4 hero, end-game + legacy OK). Hài lòng → playtest.result: pass → agent merge main."

# Evidence — việc ĐÃ xong trong session này, kèm bằng chứng (commit/file).
# Không có bằng chứng = coi như chưa làm. (Ralph-handoff: evidence field)
done:
  - "Init project từ template, đặt tên Boss Roleplaying (commit be5dab4)"
  - "Định nghĩa feature F-001 + ROADMAP M0 (commit 0f1afb3, docs/features/F-001.md)"
  - "Tải asset thật: sprite Queen (sorceress CC-BY), Hero + gothic castle + FX (Gothicvania CC0, ansimuz), 2 nhạc loop CC0, 11 SFX CC0 (Juhani Junkala), font Press Start 2P (commit 2c76afe, assets/CREDITS.md)"
  - "Pipeline cắt frame + sinh SpriteFrames .tres bằng Python (tools/inspect_sprites.py, tools/slice_final.py — commit 2c76afe)"
  - "Toàn bộ source game M0: project.godot (input map, autoload×3, bus layout), arena fight 5 round, Queen 3 skill + phase 2, Hero AI (HeroBrain RefCounted test được), menu đầy đủ main/settings/pause/end/credits (commit 2c76afe)"
  - "Auto-test tĩnh PASS: validate_scripts (Godot MCP headless) 20/20 file .gd không lỗi parse; read_scene parse OK arena + main_menu, .tres SpriteFrames load được (commit 2c76afe)"
  - "Nhận godot_exe từ user, ghi docs/LOCAL.md (gitignored)"
  - "Auto-test RUNTIME PASS: --import sạch (93 asset) · smoke --quit exit 0 · tests/test_hero_brain.gd 9/9 PASS (sau khi sửa kỳ vọng frame trong test) · arena.tscn headless 120 frame không lỗi → F-001 auto_test: pass, status dev_done, đẩy PLAYTEST_QUEUE"

# Blocker — mỗi dòng: '<cái gì> (→ <điều kiện để gỡ>)'. Rỗng = không kẹt.
blockers: []

# Quyết định đang chờ người (chỉ bắt buộc khi handoff_kind: pause).
decisions_pending: []
---

# Session state — Boss Roleplaying

> **Đọc file này trước.** Đây là entry point resume cho bất kỳ AI/dev nào vào session.
> Workflow đầy đủ: `docs/WORKFLOW.md`.

## Resume nhanh
1. Đọc frontmatter trên: `current_focus` + `next_action` = việc tiếp theo.
2. `done:` = bằng chứng việc đã xong; `blockers:` = đang kẹt cái gì.
3. `handoff_kind: planned-next` → làm tiếp `next_action` luôn.
   `handoff_kind: pause` → trình bày `decisions_pending`, chờ người quyết trước khi làm tiếp.

## Bối cảnh (không vừa vào field nào)
- Game M0 đã code XONG toàn bộ (chưa chạy lần nào — chờ godot_exe để import +
  smoke test runtime). Chi tiết thiết kế: `docs/features/F-001.md`.
- Kiến trúc: entity scene tĩnh (.tscn) + UI panel code-built (UIStyle helper);
  kiểu tham chiếu dùng preload const để không phụ thuộc global class cache
  (máy chưa từng mở editor → cache chưa build; validate qua MCP vẫn sạch).
- Godot MCP có sẵn (4.7.1) nhưng tool `update_project_uids` bị lỗi scan path
  Windows (thấy 0 file) — đừng dựa vào nó để resave/uid.
- Asset layout sheet đã xác nhận bằng contact sheet: queen 17 frame
  (idle 0-1, cast 2-5, nova 6-7, projectile 8-11, hurt 12-13, death 14-16).
- Phải hỏi user godot_exe bằng chat thường (AGENTS.md §0.1), không dùng hộp chọn.
