class_name Hero
extends Node2D

## Hero — AI đánh như NGƯỜI CHƠI Dark Souls (không phải boss):
## spacing + stamina, lăn né i-frames, punish khi Queen hồi chiêu,
## húp estus khi gần chết. Não: HeroBrain. Ký ức học đòn sống qua các lần chết.

const GhostFXScene := preload("res://scenes/fx/ghost_vanish.tscn")
const SparkFXScene := preload("res://scenes/fx/hit_spark.tscn")
const HealthScript := preload("res://scripts/combat/health.gd")
const BrainScript := preload("res://scripts/combat/hero_brain.gd")
const DebugDrawScript := preload("res://scripts/fx/debug_draw.gd")

const MEMORY_PATH := "user://hero_memory.cfg"

signal died
signal damage_taken(amount: int)

@export var base_health := 55
@export var base_damage := 7
@export var base_speed := 150.0
@export var base_stagger := 0.3
@export var attack_range := 58.0
@export var windup_time := 0.3
@export var strike_time := 0.22
@export var recover_time := 0.35

var health: HealthScript
var brain := BrainScript.new()
var brain_state := {}
var target: Node2D
var invuln := 0.0
var dead := false
var round_idx := 1

## Ký ức học đòn — sống qua các lần chết VÀ qua các ván chơi (Mortholme style:
## hero nhớ bạn giữa các session). Lưu user://hero_memory.cfg.
var _memory := {"deaths": 0, "by": {}, "fights": 0, "queen_kills": 0, "usage": {}}


func load_memory() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(MEMORY_PATH) != OK:
		return
	_memory = {
		"deaths": int(cfg.get_value("hero", "deaths", 0)),
		"by": cfg.get_value("hero", "by", {}),
		"fights": int(cfg.get_value("hero", "fights", 0)),
		"queen_kills": int(cfg.get_value("hero", "queen_kills", 0)),
		"usage": cfg.get_value("hero", "usage", {}),
	}
	print("[HERO] ký ức qua các ván: chết %d lần (%s), đã đánh %d ván, từng hạ Queen %d lần" % [
		_memory["deaths"], str(_memory["by"]), _memory["fights"], _memory["queen_kills"]
	])


func save_memory(usage_this_fight: Dictionary, queen_died: bool) -> void:
	_memory["fights"] = int(_memory.get("fights", 0)) + 1
	if queen_died:
		_memory["queen_kills"] = int(_memory.get("queen_kills", 0)) + 1
	var u: Dictionary = _memory.get("usage", {})
	for k in usage_this_fight:
		u[k] = int(u.get(k, 0)) + int(usage_this_fight[k])
	_memory["usage"] = u
	_persist_memory()


func _persist_memory() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("hero", "deaths", int(_memory.get("deaths", 0)))
	cfg.set_value("hero", "by", _memory.get("by", {}))
	cfg.set_value("hero", "fights", int(_memory.get("fights", 0)))
	cfg.set_value("hero", "queen_kills", int(_memory.get("queen_kills", 0)))
	cfg.set_value("hero", "usage", _memory.get("usage", {}))
	cfg.save(MEMORY_PATH)


## Tổng số lần hero đã chết bởi đòn của người chơi (mọi ván).
func deaths_total() -> int:
	var d := 0
	for k in ["slash", "bolt", "nova", "skull"]:
		d += int(_memory.get("by", {}).get(k, 0))
	return d


## Tổng quan ký ức cho UI (màn kết thúc).
func memory_summary() -> String:
	return "Qua mọi ván: hero đã gục %d lần, từng hạ Queen %d lần" % [
		int(_memory.get("deaths", 0)), int(_memory.get("queen_kills", 0))
	]


## Thế đánh áp theo THÓI QUEN của người chơi (đếm số lần bạn dùng từng kỹ năng,
## KHÔNG đọc phím — đọc từ ký ức usage đã lưu).
func _stance_cfg() -> Dictionary:
	var u: Dictionary = _memory.get("usage", {})
	var total := int(u.get("slash", 0)) + int(u.get("bolt", 0)) + int(u.get("nova", 0))
	if total < 10:
		return {"preferred_range": attack_range + 55.0, "poke_rate": 0.02}
	var bolt_share := float(int(u.get("bolt", 0))) / float(total)
	var slash_share := float(int(u.get("slash", 0))) / float(total)
	if bolt_share > 0.5:
		# Bạn là dạng pháo thủ → hero bám sát, poke liên tục
		return {"preferred_range": attack_range + 20.0, "poke_rate": 0.035}
	if slash_share > 0.6:
		# Bạn chỉ biết chém → hero giữ xa, thả diều
		return {"preferred_range": attack_range + 95.0, "poke_rate": 0.012}
	return {"preferred_range": attack_range + 55.0, "poke_rate": 0.02}

var _knock_x := 0.0
var _damage := 7
var _speed := 150.0
var _stagger := 0.3
var _respawn_flash := 0.0
var _last_action := -1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	health = $Health
	health.died.connect(_on_died)
	sprite.play("idle")
	_dbg = DebugDrawScript.new()
	add_child(_dbg)


var _dbg: DebugDraw


func setup_round(round: int) -> void:
	round_idx = round
	brain_state = {}
	dead = false
	invuln = 0.9
	_respawn_flash = 0.9
	_knock_x = 0.0
	_last_action = -1
	var d := int(_memory.get("deaths", 0))
	_damage = base_damage + mini(6, d)
	_speed = base_speed + minf(30.0, 2.0 * d)
	_stagger = maxf(0.16, base_stagger - 0.015 * d)
	health.reset_to(base_health)
	modulate = Color.WHITE
	sprite.play("idle")
	print("[HERO] sống dậy lần thứ %d — đã học: %s" % [round, str(_memory.get("by", {}))])


func _physics_process(delta: float) -> void:
	if dead:
		return
	invuln = maxf(0.0, invuln - delta)
	_respawn_flash = maxf(0.0, _respawn_flash - delta)
	if _respawn_flash > 0.0 and fmod(_respawn_flash, 0.18) < 0.09:
		modulate.a = 0.45
	else:
		modulate.a = 1.0

	if not is_instance_valid(target) or target.is_dead():
		sprite.play("idle")
		return

	var dist_x := target.global_position.x - global_position.x
	var stance := _stance_cfg()
	var cfg := {
		"attack_range": attack_range,
		"preferred_range": float(stance["preferred_range"]),
		"poke_rate": float(stance["poke_rate"]),
		"windup_time": maxf(0.24, windup_time - 0.01 * int(_memory.get("deaths", 0))),
		"strike_time": strike_time,
		"recover_time": recover_time,
		"stagger_time": _stagger,
		"roll_time": 0.4,
		"sip_time": 1.2,
	}
	var res := brain.step(dist_x, cfg, brain_state, delta, _threats(), _memory)
	_apply_action(res, dist_x, delta)
	_last_action = int(res["action"])
	_dbg.visible = GameSettings.debug_hitbox
	if GameSettings.debug_hitbox:
		_dbg.shapes = _debug_shapes()

func _threats() -> Dictionary:
	var th := {
		"nova_windup": false, "bolt_near": false, "slash_windup": false,
		"queen_recovery": false, "hp_frac": float(health.health) / float(health.max_health),
	}
	if is_instance_valid(target) and not target.is_dead() and target.has_method("is_charging_nova"):
		if target.is_charging_nova():
			var r: float = target.get_nova_radius()
			th["nova_windup"] = global_position.distance_to(target.global_position) < r * 1.15
		th["slash_windup"] = target.is_charging_slash()
		th["queen_recovery"] = target.is_recovering()
	for b in get_tree().get_nodes_in_group("queen_bolts"):
		if is_instance_valid(b) and absf(b.global_position.x - global_position.x) < 240.0:
			th["bolt_near"] = true
			break
	return th


func _apply_action(res: Dictionary, dist_x: float, delta: float) -> void:
	var action := int(res["action"])
	# Báo log khi đổi trạng thái "đặc biệt"
	if action != _last_action:
		match action:
			BrainScript.Action.ROLL:
				invuln = maxf(invuln, 0.38)  # i-frame của cú lăn
			BrainScript.Action.ENGAGE:
				print("[HERO] lao vào tấn công")
			BrainScript.Action.SIP:
				print("[HERO] lùi ra húp estus (còn %d)" % int(brain_state.get("flasks", 0)))
			BrainScript.Action.HEAL_APPLY:
				health.heal(health.max_health)
				GameAudio.play_sfx("round_start")
				print("[HERO] húp xong — đầy máu!")

	var speed_scale := 1.0
	match action:
		BrainScript.Action.ROLL:
			speed_scale = 2.3
		BrainScript.Action.RETREAT:
			speed_scale = 1.3
		BrainScript.Action.ENGAGE:
			speed_scale = 1.45
	var move := float(res["move_dir"]) * _speed * speed_scale
	_knock_x = move_toward(_knock_x, 0.0, 900.0 * delta)
	position.x += (move + _knock_x) * delta
	sprite.flip_h = dist_x < 0.0

	match action:
		BrainScript.Action.WINDUP:
			sprite.play("idle")
			# Người chơi không "nháy đỏ" như boss — chỉ cảnh giác một nhịp ngắn.
			sprite.modulate = Color(1.0, 0.7, 0.7) if fmod(brain_state["timer"], 0.1) < 0.05 else Color.WHITE
		BrainScript.Action.STRIKE:
			if sprite.animation != "attack" or not sprite.is_playing():
				sprite.play("attack")
				_strike_hit()
			sprite.modulate = Color.WHITE
		BrainScript.Action.ROLL:
			sprite.play("jump")
			sprite.modulate = Color(0.85, 0.9, 1.0)
		BrainScript.Action.SIP:
			sprite.play("idle")
			sprite.modulate = Color(0.55, 1.0, 0.6)
		BrainScript.Action.HEAL_APPLY:
			sprite.modulate = Color(0.8, 1.0, 0.85)
		BrainScript.Action.STAGGER:
			sprite.play("hurt")
			sprite.modulate = Color.WHITE
		_:
			# SPACING / ENGAGE / RETREAT / RECOVER
			sprite.modulate = Color.WHITE
			if absf(move) > 12.0:
				sprite.play("run")
			else:
				sprite.play("idle")


func is_dead() -> bool:
	return dead


## Debug: ĐỎ = hitbox thân (đạn/phép của Queen trúng đây) / XANH LÁ = bất tử
## (i-frame lăn, mới hồi sinh). VÀNG = tầm chém của hero.
func _debug_shapes() -> Array:
	var dodging := invuln > 0.0 or brain.is_rolling(brain_state)
	var col := Color(0.25, 1.0, 0.45, 0.9) if dodging else Color(1.0, 0.3, 0.3, 0.85)
	var shapes := [
		{"type": "arc", "pos": Vector2(0, -44), "radius": 26.0, "color": col, "points": 24},
		{"type": "dot", "pos": Vector2(0, -44), "radius": 2.0, "color": col},
	]
	var dir := 1.0
	if is_instance_valid(target):
		dir = signf(target.global_position.x - global_position.x)
	shapes.append({"type": "line", "from": Vector2(dir * attack_range * 1.35, -110),
		"to": Vector2(dir * attack_range * 1.35, 20), "color": Color(1.0, 0.85, 0.3, 0.8)})
	return shapes


func _strike_hit() -> void:
	if not is_instance_valid(target) or target.is_dead():
		return
	var dx := absf(target.global_position.x - global_position.x)
	if dx <= attack_range * 1.35:
		target.apply_hero_hit(_damage, global_position.x)


## Queen đánh trúng hero. cause: "slash" | "bolt" | "nova" | "skull".
func take_hit(dmg: int, from_x: float, knockback_x := 240.0, cause := "slash") -> void:
	if dead or invuln > 0.0:
		return
	cause_last = cause
	health.take_damage(dmg)
	damage_taken.emit(dmg)
	GameAudio.play_sfx("hit_hero")
	var spark := SparkFXScene.instantiate()
	get_parent().add_child(spark)
	spark.global_position = global_position + Vector2(0, -44)
	if not dead:
		brain.on_damaged(brain_state)  # mất thế — ngắt cả húp máu
		_knock_x = knockback_x
		sprite.modulate = Color.WHITE


func _on_died() -> void:
	dead = true
	_memory["deaths"] = int(_memory.get("deaths", 0)) + 1
	var by: Dictionary = _memory.get("by", {})
	by[cause_last] = int(by.get(cause_last, 0)) + 1
	_memory["by"] = by
	_persist_memory()  # chết là ghi sổ ngay — đóng game giữa chừng vẫn nhớ
	print("[HERO] gục ở round %d — chết vì '%s' (tổng chết: %d)" % [round_idx, cause_last, _memory["deaths"]])
	GameAudio.play_sfx("hero_die")
	sprite.play("hurt")
	var ghost := GhostFXScene.instantiate()
	get_parent().add_child(ghost)
	ghost.global_position = global_position + Vector2(0, -48)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(hide)
	died.emit()


## Loại đòn cuối cùng trúng — để ghi vào ký ức khi chết.
var cause_last := "slash"
