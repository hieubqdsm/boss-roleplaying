# Playtest Queue — {{PROJECT_NAME}}

> Worklist hằng ngày của **tester**. Mỗi feature đến `dev_done`/`playtesting` sẽ được agent đẩy vào đây.
> Cách report kết quả: xem `docs/WORKFLOW.md` §"Cách TESTER report".

## Cách chạy một feature để test

1. Đảm bảo đang ở thư mục gốc của repo project (thư mục chứa `docs/` và `project.godot`).
2. Checkout nhánh feature: `git switch feat/F-xxx-<slug>` (xem cột Branch).
   - Hoặc chạy build/export theo ghi chú riêng của feature.
3. Mở Godot editor (hoặc `godot --path .`), chạy scene chính.
4. Đối chiếu **Playtest checklist** trong `docs/features/F-xxx.md`.
5. Ghi kết quả vào `docs/features/F-xxx.md`: `playtest.result` + `playtest.notes`.
6. Commit.

## Hàng đợi

| ID | Tên | Branch | Checklist | Ghi chú chạy | Kết quả |
|---|---|---|---|---|---|
| _<F-xxx>_ | _<tên>_ | _feat/F-xxx-slug_ | _xem F-xxx.md_ | _<cách chạy>_ | _pending_ |

_(Trống = chưa có feature nào sẵn sàng test.)_

## Đã xử lý (lịch sử gần đây)

| ID | Kết quả | Ngày | Notes ngắn |
|---|---|---|---|
| — | — | — | — |
