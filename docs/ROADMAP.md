# ROADMAP — Boss Roleplaying

> Plan tổng thể của game. Agent/dev cập nhật trạng thái feature ở đây.
> Source of truth chi tiết nằm ở `docs/features/F-xxx.md` (file này chỉ là bản đồ lớn).
> Workflow đầy đủ: `docs/WORKFLOW.md`.

## Game

- **Tên:** Boss Roleplaying
- **Mô tả (1 dòng):** Game hành động 2D side-view: bạn chơi vai **Dark Queen — trùm cuối** — chống lại hero cứ bị giết lại hồi sinh và mạnh dần lên (lấy cảm hứng *The Dark Queen of Mortholme*, chỉ giữ gameplay, bỏ phần hội thoại ở giai đoạn đầu).
- **Engine:** Godot 4.7.1 (theo MCP)
- **Nền tảng mục tiêu:** PC (Windows)

## Milestone

| Milestone | Mục tiêu | Tình trạng |
|---|---|---|
| **M0 — Vertical slice** | 1 boss fight hoàn chỉnh (Queen vs hero hồi sinh ×5) + menu game đầy đủ (main / settings / pause / victory / defeat / credits) | in_dev |
| **M1 — Chiều sâu & juice** | Hero AI đa dạng hơn (dash, đỡ đòn), phase 2 boss rõ rệt, screen shake/particles, âm thanh đầy đủ, scoreboard | planned |
| **M2 — Câu chuyện & meta** | Hệ hội thoại + ending phân nhánh kiểu Mortholme (tạm hoãn theo yêu cầu — "bỏ qua phần hội thoại") | planned |

## Feature register

| ID | Tên | Priority | Status | Auto-test | Playtest | Assigned | Branch | Phụ thuộc |
|---|---|---|---|---|---|---|---|---|
| F-001 | M0 vertical slice — boss fight + menu đầy đủ | P1 | in_dev | — | — | agent | feat/F-001-m0-vertical-slice | — |

_(Thêm hàng khi tạo feature mới. Cột status/auto-test/playtest cập nhật theo feature file.)_

## Legend

- **Status:** `planned` → `in_dev` → `dev_done` → `playtesting` → `pass` → `shipped` (× `fail` quay lại `in_dev`).
- **Priority:** `P0` blocker · `P1` quan trọng · `P2` thường · `P3` nice-to-have.
- **Auto-test:** `—` chưa có · `pass` · `fail`.
- **Playtest:** `—` chưa tới · `pending` chờ tester · `pass` · `fail`.
