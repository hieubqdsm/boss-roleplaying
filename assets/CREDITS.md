# Asset credits — Boss Roleplaying

Toàn bộ asset tải về ngày 2026-09-02. Chi tiết license từng nguồn (bản file gốc
kèm trong repo chỉ gồm phần được dùng). Credits in-game: `scenes/credits.tscn`.

## Sprites

| Asset | Nguồn | Tác giả | License |
|---|---|---|---|
| Sorceress (Queen) | [Animated Sorcerer Witch](https://opengameart.org/content/animated-sorcerer-witch) | (xem trang OGA) | **CC-BY 3.0** — bắt buộc ghi công |
| Gothic Hero (idle/run/attack/jump/hurt) | [Gothicvania Patreon's Collection](https://opengameart.org/content/gothicvania-patreons-collection) | Luis Zuno (ansimuz) | Public domain (CC0) |
| Fire Skull, Ghost (vanish), fire-ball | Gothicvania Patreon's Collection | Luis Zuno (ansimuz) | Public domain (CC0) |
| Backgrounds: Gothic Castle, Old Dark Castle interior | Gothicvania Patreon's Collection | Luis Zuno (ansimuz) | Public domain (CC0) |

## Audio

| Asset | Nguồn | License |
|---|---|---|
| Nhạc fight: 8-bit Monstervania I | [OGA](https://opengameart.org/content/8-bit-monstervania-1) | CC0 |
| Nhạc menu: Abandoned Castle loop (starninjas) | [OGA](https://opengameart.org/content/abandoned-castle-music-loop) | CC0 |
| SFX (11 file WAV chọn từ 512) | [The Essential Retro Video Game Sound Effects Collection [512 sounds]](https://opengameart.org/content/512-sound-effects-8-bit-style) by Juhani Junkala | CC0 |

## Fonts

| Asset | Nguồn | License |
|---|---|---|
| Press Start 2P | Google Fonts (`ofl/pressstart2p`) | SIL OFL 1.1 |

## Ghi chú pipeline

- `tools/inspect_sprites.py` — dính frame theo cột alpha + contact sheet để soát layout.
- `tools/slice_final.py` — cắt frame PNG + sinh `SpriteFrames` `.tres` (queen/hero/fx).
  Layout frame đã xác nhận bằng contact sheet; chạy lại được (idempotent).
