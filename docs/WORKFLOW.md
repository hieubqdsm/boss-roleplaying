# Workflow — {{PROJECT_NAME}}

Quy trình làm việc cho phát triển game Godot với **agent AI + dev + tester tay**.
Mọi state nằm trong file đã commit → bất kỳ AI/dev/tester nào cũng resume được.

## Vai trò

| Vai trò | Làm gì | Đọc file nào trước |
|---|---|---|
| **Agent (AI)** | Dev feature, chạy auto-test, cập nhật trạng thái | `SESSION.md` → `ROADMAP.md` |
| **Dev (người)** | Dev/review, có thể tiếp nhận feature từ agent | `SESSION.md` → `ROADMAP.md` |
| **Tester (tay)** | Chơi thử feature `dev_done`, ghi kết quả playtest | `PLAYTEST_QUEUE.md` |

## State machine (mỗi feature)

```
planned → in_dev → dev_done → playtesting → pass → shipped
   ↑         ↑        ↑              ↓
   └─────────┴────────┴───── fail (notes) → quay lại in_dev
```

Hai kênh test **độc lập**:
- `auto_test` — agent tự chạy (GUT / scene test headless). Trạng thái `none|pass|fail`.
- `playtest.result` — tester quyết định. Trạng thái `pending|pass|fail`. **Tester là người ghi.**

Feature chỉ merge vào `main` khi `auto_test != fail` VÀ `playtest.result == pass`.

## Các artefact

| File | Vai trò | Ai ghi |
|---|---|---|
| `docs/ROADMAP.md` | Plan tổng thể: milestone + bảng feature (id, status, priority, depends_on, assigned) | Agent / dev |
| `docs/CODING.md` | Policy viết code game: scene-first, headless-testable, composition vừa phải | Policy cố định — agent / dev tuân theo |
| `docs/features/F-xxx.md` | Mỗi feature 1 file. Frontmatter = source of truth (status, auto_test, playtest). | Agent ghi status/auto_test; **tester ghi playtest.result+notes** |
| `docs/SESSION.md` | **Entry point resume** — focus hiện tại, next action, blockers. Ai vào cũng đọc file này trước. | Agent ghi trước khi kết thúc session |
| `docs/PLAYTEST_QUEUE.md` | Worklist hằng ngày của tester | Agent cập nhật, tester dùng |
| `scripts/status.sh` | In bảng trạng thái live từ frontmatter mọi feature | (chỉ đọc) |

## Kỷ luật state (durable / in-flight / policy)

Mọi thông tin chia 3 loại — **đặt đúng loại vào đúng file**, không trộn lẫn:

| Loại | Là gì | Nằm ở đâu |
|---|---|---|
| **Durable (bền vững)** | Fact phải sống qua reload/restart: status feature, kết quả test, commit | Frontmatter `docs/features/F-xxx.md` (đã commit) |
| **In-flight (đang chạy)** | Trạng thái công việc hiện tại: đang làm feature nào, bước kế tiếp | Frontmatter `docs/SESSION.md` (`current_focus`, `next_action`) |
| **Policy (luật)** | Quy tắc cố định: điều kiện merge, định nghĩa "pass", cách viết code | `docs/WORKFLOW.md` (quy trình) + `docs/CODING.md` (code) — KHÔNG bao giờ lẫn vào state |

**Invariant — model-visible ⟺ logged:** bất cứ thứ gì agent biết/quyết định **phải nằm trong file đã commit**. Không bao giờ giữ state chỉ trong hội thoại: hết context = mất state. Nếu agent "nhớ" điều gì mà không có trong `docs/`, coi như điều đó không tồn tại.

**Handoff có cấu trúc:** `SESSION.md` là bản handoff có schema (`current_focus`, `next_action`, `done`, `blockers`, `decisions_pending`). Khi kết thúc session, `done:` phải liệt kê việc đã xong **kèm bằng chứng** (commit/file). Không có bằng chứng = coi như chưa làm.

## Protocol ĐẦU session (resume) — cho bất kỳ ai

Đọc theo thứ tự:
1. `docs/SESSION.md` → biết focus hiện tại + `next_action` + blockers.
2. `docs/ROADMAP.md` → bức tranh lớn.
3. Chạy `bash scripts/status.sh` (hoặc quét `docs/features/*.md`) → bảng trạng thái.
4. Tester → mở `docs/PLAYTEST_QUEUE.md`.
5. Tiếp tục từ `next_action` trong SESSION.md.

> Nếu `SESSION.md` ghi `handoff_kind: planned-next` → cứ tiếp tục luôn.
> Nếu `handoff_kind: pause` → trình bày điểm dừng, chờ người quyết trước khi làm tiếp.

## Protocol KẾT THÚC / tạm dừng session

Agent phải làm trước khi thoát:
1. Commit mọi thay đổi (1 commit / bước logic).
2. Cập nhật `docs/features/F-xxx.md`: `status`, `auto_test`, §Lịch sử thay đổi.
3. Cập nhật `docs/ROADMAP.md` (hàng feature tương ứng).
4. Nếu feature tới giai đoạn test → đẩy vào `docs/PLAYTEST_QUEUE.md`.
5. Ghi `docs/SESSION.md` (handoff có cấu trúc): `current_focus`, `phase`, `next_action`, `handoff_kind`, `done` (evidence kèm commit/file), `blockers`, và `decisions_pending` nếu `handoff_kind: pause`.
6. Commit các file docs này.

## Song song hoá (nhiều feature / nhiều người)

- **Mỗi feature = 1 nhánh** `feat/F-xxx-<slug>`. Hai người làm hai feature không đụng file.
- Frontmatter `assigned:` cho biết ai đang giữ. ROADMAP hiện thị ownership.
- `main` = chỉ nhận feature đã `playtest.result == pass` (merge qua nhánh).
- Muốn chạy nhiều instance Godot cùng lúc (test 2 nhánh song song) → dùng `git worktree add`.
- Chỉ 1 người cập nhật `ROADMAP.md` / `SESSION.md` tại một thời điểm (merge nhanh để tránh xung đột).

## Cách TESTER report kết quả

1. Mở `docs/PLAYTEST_QUEUE.md` → chọn feature `dev_done`/`playtesting`.
2. Checkout nhánh `feat/F-xxx-<slug>` (hoặc chạy build theo hướng dẫn trong queue).
3. Chơi, đối chiếu §Playtest checklist trong `docs/features/F-xxx.md`.
4. Sửa 2 dòng trong frontmatter `docs/features/F-xxx.md`:
   - `playtest.result: pass` (hoặc `fail`)
   - `playtest.notes: "<ghi chú/lỗi nếu có>"`
5. (Tuỳ chọn) cập nhật §Lịch sử thay đổi với ngày + kết quả.
6. Commit. Agent đọc lại ở session sau → biết pass/fail → merge hoặc sửa.

## Cách AGENT biết "cái nào test xong / tiếp tục ở đâu"

- Đọc `SESSION.md` (`current_focus` + `next_action`) → biết đang làm gì.
- Chạy `scripts/status.sh` → bảng `STATUS / AUTO_TEST / PLAYTEST` mọi feature.
- Feature `playtest.result == pass` → sẵn sàng merge.
- Feature `playtest.result == fail` → đọc `playtest.notes`, sửa (quay `in_dev`).
