# CODING — Policy thiết kế code game

> **Luật cố định về CÁCH VIẾT code** (policy — không bao giờ lẫn state).
> Quy trình/lifecycle feature nằm ở `docs/WORKFLOW.md`; luật vận hành agent ở `AGENTS.md`.
>
> Tinh thần gọn một câu: **repo phải là một project Godot BÌNH THƯỜNG** —
> agent viết & test được headless, người (dev/tester) mở editor ra hiểu được ngay.
> Không chấp nhận kiểu "agent sinh một script lớn tự đẻ cả scene tree lúc runtime".

## 0. Nguyên tắc số 0 — headless-testable & human-editable

Hai ràng buộc của harness này, **cao hơn mọi nguyên tắc còn lại**:

- **Scene chạy độc lập được.** Agent không bấm F6 được (headless only —
  `AGENTS.md` §0.2). F6 của agent là:
  ```sh
  godot --headless --path . res://scenes/player.tscn --quit
  ```
  Scene mức entity nào cũng phải qua được lệnh này không lỗi.
- **Logic tách khỏi hiển thị.** Gameplay logic viết thành class test được
  không cần cửa sổ (GUT headless). `_process` mỏng — chỉ điều phối, không
  chứa logic.
- **Người mở editor ra hiểu được.** Tên node tự giải thích, wiring nối trong
  editor, KHÔNG instantiate cả cây scene bằng code lúc runtime — cây scene
  phải nhìn thấy được tĩnh, vì tester/dev người làm việc trên nó.

## 1. Everything is a Scene — mức entity

- Mỗi entity một scene riêng (`Player.tscn`, `Coin.tscn`, `HUD.tscn`), chạy và
  test độc lập (nguyên tắc 0).
- **Ngoại lệ hợp lệ:** fragment trung gian (một hàng HUD, hitbox nhỏ, sub-scene
  private) không cần chạy standalone "hữu ích" — đừng ép quy tắc F6 lên mọi
  scene con, sinh scaffolding vô nghĩa.

## 2. Call Down, Signal Up — default, không tuyệt đối

- Cha gọi trực tiếp hàm con; **component tái sử dụng KHÔNG `get_parent()`**.
- Con báo lên bằng signal — nhưng chọn kênh theo quan hệ, đừng signal-hoá mọi thứ:
  - **1:1 đã biết trước** (HealthBar lúc nào cũng thuộc HUD) → truyền tham chiếu
    xuống (`@export var bar: HealthBar`) — trace dễ hơn signal.
  - **Broadcast** (ai quan tâm thì nghe) → signal lên cha / scene sở hữu.
  - **Thật sự toàn cục** → EventBus (nguyên tắc 5).
- Ngoại lệ hợp lệ: wiring private trong sub-scene, `%UniqueName` trong cùng scene.
- Signal spaghetti khó debug hơn call — chỉ signal khi thật sự có nhiều bên nghe.

## 3. Composition vừa phải — đừng node bloat

- **Component-node** cho thứ thuộc scene tree: `HitboxComponent` (Area2D),
  `HealthComponent` (Node)… kéo thả tái dùng thay vì kế thừa sâu
  (kế thừa script >1 mức là đáng ngờ).
- **Class `RefCounted` cho logic thuần** (tính damage, AI decision, shuffle…):
  test headless không cần dựng scene, không overhead node. Đây là mức
  test-friendly cao nhất — ưu tiên cho logic game.
- Không "mọi thứ đều component": 5-7 node component/entity × hàng trăm entity
  = scene tree khó đọc với người + chi phí node không cần thiết.

## 4. Data-driven với Resource — kèm bẫy share

- Config tách khỏi logic: `class_name` extends `Resource` (`ItemData.gd`,
  `EnemyStats.gd`), lưu biến thể `.tres`, node chỉ `@export` kéo thả —
  **người chỉnh số trong Inspector, không cần đụng code**.
- ⚠ **Resource share theo mặc định:** hai node cùng trỏ `GoblinStats.tres`
  = chung MỘT instance lúc runtime; mutate `stats.hp` con này leaks sang con
  kia. Cần bản riêng → `duplicate()` hoặc bật `local_to_scene`.
- Đừng nâng mọi config lên Resource class — 2-3 biến thì `@export` thường đủ.

## 5. Autoload = bus signal thuần, KHÔNG phải kho biến

- Autoload **không chứa state** (biến toàn cục) — gốc rễ của test-leak, phụ
  thuộc init-order, state sống vô kỷ luật qua scene change.
- EventBus autoload (vd `Events.gd`) chỉ khai báo signal, chỉ dùng cho event
  **thật sự cross-cutting** (game_over, scene_changed). Mọi quan hệ còn lại
  dùng nguyên tắc 2.
- **Auto-test phải reset bus** giữa các test — autoload sống sót qua các test,
  connections leak từ test này sang test kia nếu không cleanup.

## Checklist review code (agent + dev dùng chung)

- [ ] Scene entity chạy được `godot --headless --path . <scene> --quit` không lỗi?
- [ ] Có component nào `get_parent()` / gọi ngược lên cha không?
- [ ] Logic thuần có bị nhét trong Node/`_process` không? (dời sang `RefCounted`)
- [ ] Có mutate Resource share lúc runtime không?
- [ ] Autoload có chứa biến state không? Test có reset bus không?
- [ ] Mở editor: cây scene + tên node có tự giải thích được không?
