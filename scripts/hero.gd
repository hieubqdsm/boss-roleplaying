class_name Hero
extends Node2D

## Hero — AI đánh như NGƯỜI CHƠI Dark Souls (không phải boss):
## spacing + stamina, lăn né i-frames, punish khi Queen hồi chiêu, estus
## (tạm tắt — xem HeroBrain.ESTUS_ENABLED). Não: HeroBrain (typed classes).
## Ký ức học đòn sống qua các lần chết VÀ các ván (user://hero_memory.cfg).
##
## Ghi chú: `target` giữ kiểu Node2D + unsafe method calls CỐ Ý — preload
## chéo Queen↔Hero sẽ tạo dependency cycle (docs/CODING.md §2).

const GhostFXScene := preload("res://scenes/fx/ghost_vanish.tscn")
const SparkFXScene := preload("res://scenes/fx/hit_spark.tscn")
const HealthScript := preload("res://scripts/combat/health.gd")
const BrainScript := preload("res://scripts/combat/hero_brain.gd")
const Anchors := preload("res://scripts/combat/combat_anchors.gd")
const DebugDrawScript := preload("res://scripts/fx/debug_draw.gd")

const MEMORY_PATH := "user://hero_memory.cfg"

signal died
signal damage_taken(amount: int)

@export var base_health := 55
@export var base_damage := 7
@export var base_speed := 150.0
@export var base_stagger := 0.3
@export var attack_range := 58.0
@export var windup_time := 0.08
@export var strike_time := 0.22
@export var recover_time := 0.35
## Tâm vùng trúng đạn so với chân (single source: bolt/queen/debug đọc qua hit_center()).
@export var chest_anchor := Anchors.HERO_CHEST

var health: HealthScript
var brain := BrainScript.new()
var brain_state := BrainScript.BrainState.new()
var _cfg := BrainScript.BrainConfig.default()
var target: Node2D
var invuln := 0.0
var dead := false
var round_idx := 1

## Ký ức học đòn — sống qua các lần chết VÀ qua các ván chơi (Mortholme style).
var memory := BrainScript.Memory.new()

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
	# Seed runtime: mỗi round một vận may riêng (test giữ seed 12345 deterministic).
	brain_state = BrainScript.BrainState.new(randi())
	_cfg = BrainScript.BrainConfig.default()
	dead = false
	invuln = 0.9
	_respawn_flash = 0.9
	_knock_x = 0.0
	_last_action = -1
	var d := memory.deaths
	_damage = base_damage + mini(6, d)
	_speed = base_speed + minf(30.0, 2.0 * d)
	_stagger = maxf(0.16, base_stagger - 0.015 * d)
	health.reset_to(base_health)
	modulate = Color.WHITE
	sprite.play("idle")
	print("[HERO] sống dậy lần thứ %d — đã học: %s" % [round, str(memory.by)])


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
	_cfg.preferred_range = float(stance.preferred_range)
	_cfg.poke_rate = float(stance.poke_rate)
	_cfg.windup_time = maxf(0.05, windup_time - 0.004 * memory.deaths)
	_cfg.attack_range = attack_range
	_cfg.strike_time = strike_time
	_cfg.recover_time = recover_time
	_cfg.stagger_time = _stagger
	var res := brain.step(dist_x, _cfg, brain_state, delta, _threats(), memory)
	_apply_action(res, dist_x, delta)
	_last_action = res.action
	_dbg.visible = GameSettings.debug_hitbox
	if GameSettings.debug_hitbox:
		_dbg.shapes = _debug_shapes()


## Thế đánh áp theo THÓI QUEN của người chơi (từ ký ức usage, không đọc phím).
var stance := {"preferred_range": attack_range + 55.0, "poke_rate": 0.02}


func _refresh_stance() -> void:
	var u: Dictionary = memory.usage
	var total := int(u.get("slash", 0)) + int(u.get("bolt", 0)) + int(u.get("nova", 0))
	if total < 10:
		stance = {"preferred_range": attack_range + 55.0, "poke_rate": 0.02}
	elif float(int(u.get("bolt", 0))) / float(total) > 0.5:
		stance = {"preferred_range": attack_range + 20.0, "poke_rate": 0.035}   # pháo thủ → bám sát
	elif float(int(u.get("slash", 0))) / float(total) > 0.6:
		stance = {"preferred_range": attack_range + 95.0, "poke_rate": 0.012}   # chém thủ → thả diều
	else:
		stance = {"preferred_range": attack_range + 55.0, "poke_rate": 0.02}


## Quét mối đe doạ xung quanh: telegraph của Queen + đạn đang bay tới gần.
func _threats() -> BrainScript.Threats:
	var th := BrainScript.Threats.new()
	th.hp_frac = float(health.health) / float(health.max_health)
	if is_instance_valid(target) and not target.is_dead() and target.has_method("is_charging_nova"):
		if target.is_charging_nova():
			var r: float = target.get_nova_radius()
			th.nova_windup = global_position.distance_to(target.global_position) < r * 1.15
		th.slash_windup = target.is_charging_slash()
		th.queen_recovery = target.is_recovering()
	for b in get_tree().get_nodes_in_group("queen_bolts"):
		if is_instance_valid(b) and absf(b.global_position.x - global_position.x) < 240.0:
			th.bolt_near = true
			break
	return th


func _apply_action(res: BrainScript.StepResult, dist_x: float, delta: float) -> void:
	var action := res.action
	# Báo log khi đổi trạng thái "đặc biệt"
	if action != _last_action:
		match action:
			BrainScript.Action.ROLL:
				invuln = maxf(invuln, BrainScript.ROLL_IFRAMES)  # i-frame của cú lăn
			BrainScript.Action.ENGAGE:
				print("[HERO] lao vào tấn công")
			BrainScript.Action.SIP:
				print("[HERO] lùi ra húp estus (còn %d)" % brain_state.flasks)
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
	var move := res.move_dir * _speed * speed_scale
	_knock_x = move_toward(_knock_x, 0.0, Anchors.HERO_KNOCK_DECAY * delta)
	position.x += (move + _knock_x) * delta
	sprite.flip_h = dist_x < 0.0

	match action:
		BrainScript.Action.WINDUP:
			sprite.play("run")   # vung khi đang tiến — hết khựng
			sprite.modulate = Color(1.0, 0.7, 0.7)
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


## Tâm vùng trúng đạn (đạn/phép của Queen nhắm đây; debug vẽ đây).
func hit_center() -> Vector2:
	return global_position + chest_anchor


## Debug: ĐỎ = hitbox thân / XANH LÁ = bất tử (i-frame lăn, mới hồi sinh).
## VÀNG = tầm chém của hero.
func _debug_shapes() -> Array:
	var dodging := invuln > 0.0 or brain.is_rolling(brain_state)
	var col := Color(0.25, 1.0, 0.45, 0.9) if dodging else Color(1.0, 0.3, 0.3, 0.85)
	var shapes := [
		{"type": "arc", "pos": chest_anchor, "radius": Anchors.HERO_HIT_RADIUS, "color": col, "points": 24},
		{"type": "dot", "pos": chest_anchor, "radius": 2.0, "color": col},
	]
	var dir := 1.0
	if is_instance_valid(target):
		dir = signf(target.global_position.x - global_position.x)
	shapes.append({"type": "line",
		"from": Vector2(dir * attack_range * Anchors.HERO_STRIKE_RANGE_MULT, -110),
		"to": Vector2(dir * attack_range * Anchors.HERO_STRIKE_RANGE_MULT, 20),
		"color": Color(1.0, 0.85, 0.3, 0.8)})
	return shapes


func _strike_hit() -> void:
	if not is_instance_valid(target) or target.is_dead():
		return
	var dx := absf(target.global_position.x - global_position.x)
	if dx <= attack_range * Anchors.HERO_STRIKE_RANGE_MULT:
		target.apply_hero_hit(_damage, global_position.x)


## Queen đánh trúng hero. cause: "slash" | "bolt" | "nova" | "skull".
func take_hit(dmg: int, from_x: float, knockback_x := Anchors.DEFAULT_KNOCK, cause := "slash") -> void:
	if dead or invuln > 0.0:
		return
	cause_last = cause
	health.take_damage(dmg)
	damage_taken.emit(dmg)
	GameAudio.play_sfx("hit_hero")
	var spark := SparkFXScene.instantiate()
	get_parent().add_child(spark)
	spark.global_position = hit_center()
	if not dead:
		brain.on_damaged(brain_state)  # mất thế — ngắt cả húp máu
		_knock_x = knockback_x
		sprite.modulate = Color.WHITE


func _on_died() -> void:
	dead = true
	memory.count_death(cause_last)
	_persist_memory()  # chết là ghi sổ ngay — đóng game giữa chừng vẫn nhớ
	print("[HERO] gục ở round %d — chết vì '%s' (tổng chết: %d)" % [round_idx, cause_last, memory.deaths])
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


# ── Ký ức qua các ván (Mortholme: hero nhớ bạn giữa các session) ──

func load_memory() -> void:
	_refresh_stance()
	var cfg := ConfigFile.new()
	if cfg.load(MEMORY_PATH) != OK:
		return
	memory.deaths = int(cfg.get_value("hero", "deaths", 0))
	memory.by = cfg.get_value("hero", "by", {})
	memory.fights = int(cfg.get_value("hero", "fights", 0))
	memory.queen_kills = int(cfg.get_value("hero", "queen_kills", 0))
	memory.usage = cfg.get_value("hero", "usage", {})
	_refresh_stance()
	print("[HERO] ký ức qua các ván: chết %d lần (%s), đã đánh %d ván, từng hạ Queen %d lần" % [
		memory.deaths, str(memory.by), memory.fights, memory.queen_kills
	])


func save_memory(usage_this_fight: Dictionary, queen_died: bool) -> void:
	memory.fights += 1
	if queen_died:
		memory.queen_kills += 1
	memory.add_usage(usage_this_fight)
	_persist_memory()


func _persist_memory() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("hero", "deaths", memory.deaths)
	cfg.set_value("hero", "by", memory.by)
	cfg.set_value("hero", "fights", memory.fights)
	cfg.set_value("hero", "queen_kills", memory.queen_kills)
	cfg.set_value("hero", "usage", memory.usage)
	cfg.save(MEMORY_PATH)


## Tổng số lần hero đã chết bởi đòn của người chơi (mọi ván).
func deaths_total() -> int:
	var d := 0
	for k in BrainScript.DAMAGE_KINDS:
		d += memory.deaths_by(k)
	return d


## Bản ký ức cho web bridge / UI.
func memory_dict() -> Dictionary:
	return {
		"deaths": memory.deaths,
		"by": memory.by.duplicate(),
		"fights": memory.fights,
		"queen_kills": memory.queen_kills,
	}


## Tổng quan ký ức cho UI (màn kết thúc).
func memory_summary() -> String:
	return "Qua mọi ván: hero đã gục %d lần, từng hạ Queen %d lần" % [
		memory.deaths, memory.queen_kills
	]


## Cho HUD đọc: stamina 0..1 và số bình estus còn.
func stamina_frac() -> float:
	return brain_state.stamina / BrainScript.STAMINA_MAX


func flasks_left() -> int:
	return brain_state.flasks


## Debug info cho web bridge — log-driven test (thay screenshot).
func debug_info() -> Dictionary:
	return {
		"phase": brain_state.phase,
		"action": BrainScript.action_name(_last_action),
		"x": int(position.x),
		"hp": health.health,
		"stamina": int(brain_state.stamina),
		"flasks": brain_state.flasks,
		"rolling": brain.is_rolling(brain_state),
		"invuln": invuln > 0.0,
	}
