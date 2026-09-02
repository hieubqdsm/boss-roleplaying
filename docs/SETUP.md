# SETUP — hỏi người dùng một lần, ghi lại, khỏi hỏi lại

> Agent đọc file này khi cần thông tin nằm trên máy người dùng.
> Quy tắc giao tiếp: xem `AGENTS.md` §1b. Ngắn gọn: LOCAL.md → which/env → HỎI.
> **Hỏi = tin nhắn chat thường rồi chờ trả lời** — không dùng select-list/hộp chọn.
> **Không tự scan đĩa tìm đường dẫn.**

## Vì sao

Agent mặc định sẽ cố "tự tìm" godot giữa các ổ đĩa — chậm, và quét lung tung
dữ liệu cá nhân của người dùng. Những thông tin chỉ người dùng biết chắc
(thứ gì cài ở đâu trên máy họ) thì hỏi là nhanh nhất: 10 giây của họ
thay cho 10 phút dò xét. Hỏi xong **phải ghi lại** — session sau đọc,
không hỏi lại câu đã có lời giải.

## Cần hỏi gì (danh sách chuẩn)

| Thông tin | Hỏi khi nào | Dùng cho |
|---|---|---|
| Đường dẫn godot exe (bản `_console` nếu Windows) | lần đầu chạy/headless test | auto-test, export |
| Version Godot | lần đầu | project.godot features |
| Export templates đã cài chưa (đúng version?) | khi cần export web/desktop | build |
| Node.js / Python + thư viện | khi cần tooling (Playwright, PIL...) | pipeline |

## Format `docs/LOCAL.md`

File này **đã được .gitignore** — ghi thoải mái path máy, không lo push.
Tạo khi nhận câu trả lời đầu tiên:

```markdown
# LOCAL — cấu hình máy (gitignored, không commit)

- godot_exe: "D:\\Tools\\Godot_v4.7.1\\Godot_v4.7.1-stable_win64_console.exe"
- godot_version: 4.7.1
- export_templates: có (4.7.1.stable, gồm web)
- node: v24.11.1
- python: 3.10 (có PIL, numpy)
- ghi_chu: bản _console mới hiện stdout trong terminal Windows
```

Session sau: đọc file này ở bước 1 của protocol (AGENTS.md §1) — thấy
`godot_exe` là dùng luôn, không hỏi lại, không `find`.
