# Godot MCP — cài đặt (tuỳ chọn, khuyến nghị)

> Harness này **chạy được không cần MCP** (agent dùng `godot` CLI — xem `AGENTS.md` §6).
> Nhưng nếu agent client của bạn hỗ trợ MCP, lắp Godot MCP server để agent
> tạo scene/node và **đọc debug output trực tiếp** — vòng lặp feedback tốt hơn nhiều.
> **HARD RULE (`AGENTS.md` §0.2):** tool mở cửa sổ (`run_project`,
> `launch_editor`) KHÔNG được agent tự gọi — chỉ khi người dùng yêu cầu rõ ràng.

## Server

**`@coding-solo/godot-mcp`** ([Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp), MIT).
Đây là bộ tool mà harness kỳ vọng — khớp đúng các tool sau:

| Tool | Làm gì |
|---|---|
| `get_godot_version` | Lấy version Godot đã cài |
| `list_projects` | Tìm project Godot trong một thư mục |
| `get_project_info` | Metadata + cấu trúc project |
| `launch_editor` | ⚠️ Mở cửa sổ editor — CHỈ khi người dùng yêu cầu (`AGENTS.md` §0.2) |
| `run_project` | ⚠️ Chạy project có cửa sổ — CHỈ khi người dùng yêu cầu (`AGENTS.md` §0.2) |
| `stop_project` | Dừng project đang chạy |
| `get_debug_output` | Lấy console output + error |
| `create_scene` | Tạo scene mới (chọn root node type) |
| `add_node` | Thêm node vào scene (kèm properties) |
| `load_sprite` | Nạp texture vào Sprite2D |
| `export_mesh_library` | Xuất 3D scene → MeshLibrary cho GridMap |
| `save_scene` | Lưu scene (có thể tạo variant) |
| `get_uid` / `update_project_uids` | Quản lý UID (Godot 4.4+) |

> Có những Godot MCP server khác (bradypp, Quaza/Godot-MCP-Pro, ee0pdt...).
> Harness này **khớp nhất** với `@coding-solo/godot-mcp` theo bảng tool trên.

## Yêu cầu

- **Godot 4.x** đã cài (nằm trong PATH, hoặc set `GODOT_PATH` bên dưới).
- **Node.js ≥ 18** + npm.
- **Agent client hỗ trợ MCP**: ZCode / Claude Code / Cursor / Cline / Claude Desktop...

## Cài đặt (chọn client của bạn)

### Claude Code
```sh
claude mcp add godot -- npx @coding-solo/godot-mcp
# kèm biến môi trường (nếu Godot không tự nhận):
claude mcp add godot -e GODOT_PATH=/path/to/godot -e DEBUG=true -- npx @coding-solo/godot-mcp
```

### ZCode / Claude Desktop / Cline / Cursor (config JSON)

Thêm vào cấu hình MCP của client (scope **user** để dùng cho mọi project, hoặc **workspace** cho riêng project này):

```json
{
  "mcpServers": {
    "godot": {
      "command": "npx",
      "args": ["@coding-solo/godot-mcp"],
      "env": {
        "GODOT_PATH": "/path/to/godot",
        "DEBUG": "true"
      }
    }
  }
}
```

- **ZCode**: thêm MCP server ở Settings (nếu bạn đang đọc guide này trên ZCode, nhiều khả năng **đã cài sẵn** — các tool `mcp__godot__*` đang chạy).
- **Cursor**: hoặc dùng UI *Settings → Features → MCP → Add New MCP Server* (Name `godot`, Type `command`, Command `npx @coding-solo/godot-mcp`), hoặc file `.cursor/mcp.json`.

### Build từ source
```sh
git clone https://github.com/Coding-Solo/godot-mcp.git
cd godot-mcp
npm install
npm run build
```
Rồi trỏ MCP client tới `build/index.js` thay vì `npx`.

## Biến môi trường

| Biến | Ý nghĩa |
|---|---|
| `GODOT_PATH` | Đường dẫn Godot executable (đè nhận diện tự động) |
| `DEBUG` | `"true"` để bật log debug phía server |

## Kiểm tra đã chạy

Yêu cầu agent gọi 2 tool trong project (thư mục có `project.godot`):
- `get_godot_version` → trả version Godot.
- `get_project_info` (projectPath = `.`) → trả metadata project.

Trả kết quả = MCP đã sống. Lỗi/không thấy tool = xem mục dưới.

## Khắc phục

- **Godot not found** → set `GODOT_PATH` trỏ tới executable Godot.
- **Không thấy tool / connection fail** → restart agent client; chắc chắn server được thêm và **enabled**.
- **Invalid project path** → đường dẫn phải chứa file `project.godot`.
- **Build lỗi** → chạy lại `npm install` rồi `npm run build`.

## Quan hệ với workflow harness

- MCP chỉ là **cách agent lái Godot**. **State vẫn nằm trong markdown** (SESSION / features) — không thay đổi.
- `auto_test` headless trong `AGENTS.md` §6 **vẫn dùng `godot --headless` CLI** (GUT headless) — MCP không thay thế.
- **HARD RULE (`AGENTS.md` §0.2):** `launch_editor` / `run_project` mở cửa sổ Godot trên máy người dùng. Agent **KHÔNG TỰ GỌI** — chỉ khi người dùng yêu cầu rõ ràng trong session. Tự debug → `godot --headless`.
- Thiếu MCP: agent vẫn dev bình thường qua CLI. Có MCP: vòng lặp agent↔Godot chặt hơn.

## Link

- Repo: <https://github.com/Coding-Solo/godot-mcp>
- npm: [`@coding-solo/godot-mcp`](https://www.npmjs.com/package/@coding-solo/godot-mcp)
