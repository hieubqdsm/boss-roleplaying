# ROADMAP — {{PROJECT_NAME}}

> Plan tổng thể của game. Agent/dev cập nhật trạng thái feature ở đây.
> Source of truth chi tiết nằm ở `docs/features/F-xxx.md` (file này chỉ là bản đồ lớn).
> Workflow đầy đủ: `docs/WORKFLOW.md`.

## Game (chưa chốt)

- **Tên:** {{PROJECT_NAME}}
- **Mô tả (1 dòng):** _<điền: dạng game gì, cảm xúc cốt lõi>_
- **Engine:** Godot 4.7 (theo MCP)
- **Nền tảng mục tiêu:** _<PC / web / mobile>_

## Milestone

| Milestone | Mục tiêu | Tình trạng |
|---|---|---|
| **M0 — Vertical slice** | Project Godot init + 1 vòng lặp gameplay nhỏ chạy được | planned |
| **M1 — _<điền>_** | _<điền>_ | planned |
| **M2 — _<điền>_** | _<điền>_ | planned |

## Feature register

| ID | Tên | Priority | Status | Auto-test | Playtest | Assigned | Branch | Phụ thuộc |
|---|---|---|---|---|---|---|---|---|
| _<F-001>_ | _<vd: Player movement>_ | _P1_ | _planned_ | — | — | — | — | — |
| _<F-002>_ | _<...>_ | _P2_ | _planned_ | — | — | — | — | — |

_(Thêm hàng khi tạo feature mới. Cột status/auto-test/playtest cập nhật theo feature file.)_

## Legend

- **Status:** `planned` → `in_dev` → `dev_done` → `playtesting` → `pass` → `shipped` (× `fail` quay lại `in_dev`).
- **Priority:** `P0` blocker · `P1` quan trọng · `P2` thường · `P3` nice-to-have.
- **Auto-test:** `—` chưa có · `pass` · `fail`.
- **Playtest:** `—` chưa tới · `pending` chờ tester · `pass` · `fail`.
