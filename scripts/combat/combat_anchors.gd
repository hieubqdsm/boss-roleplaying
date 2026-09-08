extends RefCounted

## Hợp đồng toạ độ & lực tác động dùng chung giữa các entity — SINGLE SOURCE.
## Trước đây các con số này nằm rải rác trong queen.gd / hero.gd / bolt.gd
## (bị review chỉ ra là magic numbers — đổi 1 chỗ quên 2 chỗ là đòn trượt).
## Dùng: const Anchors := preload("res://scripts/combat/combat_anchors.gd")

# ── Hero ──
## Tâm vùng trúng đạn của hero (so với chân position) — Queen/bolt/debug cùng nhắm đây.
const HERO_CHEST := Vector2(0, -44)
const HERO_HIT_RADIUS := 26.0
## Tầm chém thật của hero = attack_range * hệ số này.
const HERO_STRIKE_RANGE_MULT := 1.35

# ── Knockback / i-frames ──
const DEFAULT_KNOCK := 240.0
const SLASH_KNOCK := 220.0
const NOVA_KNOCK := 520.0
const HERO_KNOCK_DECAY := 900.0

# ── Queen hồi chiêu (cửa sổ hero punish) ──
const SLASH_RECOVERY := 0.55
const BOLT_RECOVERY := 0.35
const NOVA_RECOVERY := 0.6
