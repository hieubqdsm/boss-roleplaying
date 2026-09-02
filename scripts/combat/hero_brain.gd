class_name HeroBrain
extends RefCounted

## AI Hero — "soul player" archetype (heuristic, không phải ML):
## - Giữ spacing (đứng ngoài tầm chém, áp sát theo nhịp), KHÔNG face-tank.
## - Stamina: vô lăn/đòn tốn stamina, cạn thì buộc phải giữ khoảng cách hồi.
## - Lăn né CÓ i-frames, lăn QUA đòn (về phía Queen) để rồi punish.
## - Punish: chờ Queen vừa tung chiêu (recovery) → xông vào 1-2 đòn rồi rút.
## - Estus: HP thấp + an toàn → lùi ra xa húp (dùng bị đánh là mất, như DS).
## - Học qua chết: nhớ đòn nào giết mình → tăng xác suất lăn đúng loại đó.
## Thuần logic — test headless không cần scene (docs/CODING.md §0 & §3).

enum Action {
	WAIT, SPACING, ENGAGE, WINDUP, STRIKE, RECOVER,
	ROLL, RETREAT, SIP, HEAL_APPLY, STAGGER,
}

const PHASE_SPACING := "spacing"
const PHASE_ENGAGE := "engage"
const PHASE_WINDUP := "windup"
const PHASE_STRIKE := "strike"
const PHASE_RECOVER := "recover"
const PHASE_ROLL := "roll"
const PHASE_RETREAT := "retreat"
const PHASE_SIP := "sip"
const PHASE_STAGGER := "stagger"

# Stamina & estus
const STAMINA_MAX := 100.0
const STAMINA_REGEN := 26.0
const COST_ATTACK := 28.0
const COST_ROLL := 34.0
const FLASKS_MAX := 3

# Học né (giữ từ v2)
const BASE_DODGE := {"bolt": 0.25, "nova": 0.5, "slash": 0.2}
const DODGE_PER_DEATH := 0.12
const DODGE_CAP := 0.85


static func dodge_chance(memory: Dictionary, kind: String) -> float:
	var deaths := 0
	if memory.get("by", {}).has(kind):
		deaths = int(memory["by"][kind])
	return minf(DODGE_CAP, float(BASE_DODGE.get(kind, 0.2)) + DODGE_PER_DEATH * deaths)


## state: {"phase","timer","rng","stamina","flasks","combo","roll_dir","strafe"}
## threats: {"nova_windup","bolt_near","slash_windup","queen_recovery","hp_frac"}
## Trả về {"action": Action, "move_dir": float}.
func step(dist_x: float, cfg: Dictionary, state: Dictionary, delta: float,
		threats: Dictionary = {}, memory: Dictionary = {}) -> Dictionary:
	_defaults(state)
	state["timer"] = float(state["timer"]) + delta
	var rng: RandomNumberGenerator = state["rng"]
	var phase: String = state["phase"]
	var t: float = state["timer"]
	var adist := absf(dist_x)
	var toward := signf(dist_x)
	var attack_range := float(cfg.get("attack_range", 58.0))
	var preferred := float(cfg.get("preferred_range", attack_range + 55.0))

	# Hồi stamina khi không dốc sức (đứng spacing / rút lui / hồi đòn)
	if phase == PHASE_SPACING or phase == PHASE_RETREAT or phase == PHASE_RECOVER or phase == PHASE_SIP:
		state["stamina"] = minf(STAMINA_MAX, float(state["stamina"]) + STAMINA_REGEN * delta)

	match phase:
		PHASE_WINDUP:
			if t >= float(cfg.get("windup_time", 0.3)):
				return _enter(state, PHASE_STRIKE, Action.STRIKE, 0.0)
			return _keep(Action.WINDUP, 0.0)

		PHASE_STRIKE:
			if t >= float(cfg.get("strike_time", 0.22)):
				return _enter(state, PHASE_RECOVER, Action.RECOVER, 0.0)
			return _keep(Action.STRIKE, 0.0)

		PHASE_RECOVER:
			if t >= float(cfg.get("recover_time", 0.35)):
				# Combo thứ 2 kiểu người chơi, hoặc rút lui — KHÔNG bám chém
				if int(state["combo"]) < 2 and float(state["stamina"]) >= COST_ATTACK \
						and adist < attack_range * 1.2 and rng.randf() < 0.45:
					state["combo"] = int(state["combo"]) + 1
					state["stamina"] = float(state["stamina"]) - COST_ATTACK
					return _enter(state, PHASE_WINDUP, Action.WINDUP, 0.0)
				if float(state["stamina"]) >= COST_ROLL and rng.randf() < 0.4:
					return _start_roll(state, -toward)
				return _enter(state, PHASE_RETREAT, Action.RETREAT, -toward)
			return _keep(Action.RECOVER, 0.0)

		PHASE_ROLL:
			if t >= float(cfg.get("roll_time", 0.4)):
				return _enter(state, PHASE_SPACING, Action.SPACING, _spacing_dir(state, adist, preferred, toward))
			return _keep(Action.ROLL, float(state["roll_dir"]))

		PHASE_RETREAT:
			if t >= 0.55 or adist > preferred + 20.0:
				return _enter(state, PHASE_SPACING, Action.SPACING, _spacing_dir(state, adist, preferred, toward))
			return _keep(Action.RETREAT, -toward)

		PHASE_SIP:
			if t >= float(cfg.get("sip_time", 1.2)):
				state["flasks"] = int(state["flasks"]) - 1
				_enter(state, PHASE_SPACING, Action.SPACING, 0.0)
				return {"action": Action.HEAL_APPLY, "move_dir": 0.0}
			return _keep(Action.SIP, 0.0)

		PHASE_STAGGER:
			if t >= float(cfg.get("stagger_time", 0.3)):
				return _enter(state, PHASE_SPACING, Action.SPACING, _spacing_dir(state, adist, preferred, toward))
			return _keep(Action.STAGGER, 0.0)

		PHASE_ENGAGE:
			if adist <= attack_range:
				if float(state["stamina"]) >= COST_ATTACK:
					state["combo"] = 1
					state["stamina"] = float(state["stamina"]) - COST_ATTACK
					return _enter(state, PHASE_WINDUP, Action.WINDUP, 0.0)
				return _enter(state, PHASE_RETREAT, Action.RETREAT, -toward)
			if t >= 0.8:
				return _enter(state, PHASE_SPACING, Action.SPACING, _spacing_dir(state, adist, preferred, toward))
			return _keep(Action.ENGAGE, toward)

		_: # PHASE_SPACING — não "người chơi": chờ cửa, né, húp máu
			# 1) Sắp chết + an toàn → húp estus
			if float(threats.get("hp_frac", 1.0)) < 0.35 and int(state["flasks"]) > 0 \
					and adist > 230.0 and not threats.get("bolt_near", false) \
					and not threats.get("nova_windup", false):
				return _enter(state, PHASE_SIP, Action.SIP, 0.0)
			# 2) Né — lăn QUA đòn (về phía Queen) hoặc lùi xa nova
			if threats.get("nova_windup", false) and rng.randf() < dodge_chance(memory, "nova"):
				return _start_roll(state, -toward)
			if threats.get("bolt_near", false) and rng.randf() < dodge_chance(memory, "bolt"):
				return _start_roll(state, toward if rng.randf() < 0.5 else -toward)
			if threats.get("slash_windup", false) and adist < attack_range * 2.4 \
					and rng.randf() < dodge_chance(memory, "slash"):
				return _start_roll(state, toward)
			# 3) Punish: Queen vừa tung chiêu (đang hồi) + còn sức → xông vào
			if threats.get("queen_recovery", false) and adist < 330.0 \
					and float(state["stamina"]) >= COST_ATTACK + 10.0:
				return _enter(state, PHASE_ENGAGE, Action.ENGAGE, toward)
			# 4) Đủ gần + đủ stamina → đâm vào ăn một đòn rồi rút (poke)
			if adist <= attack_range and float(state["stamina"]) >= COST_ATTACK + 20.0:
				return _enter(state, PHASE_ENGAGE, Action.ENGAGE, toward)
			# 4b) Đầy sức + trong vùng ưa thích → chủ động áp sát (người chơi biết
			#     tạo cơ hội, không chỉ đứng chờ Queen hụt chiêu)
			if float(state["stamina"]) >= 80.0 and adist < preferred + 40.0 \
					and rng.randf() < 0.02:
				return _enter(state, PHASE_ENGAGE, Action.ENGAGE, toward)
			# 5) Cạn stamina → chủ động lùi ra hồi
			if float(state["stamina"]) < 40.0 and adist < preferred:
				return _enter(state, PHASE_RETREAT, Action.RETREAT, -toward)
			return _keep(Action.SPACING, _spacing_dir(state, adist, preferred, toward))


func _spacing_dir(state: Dictionary, adist: float, preferred: float, toward: float) -> float:
	# Dao động nhẹ quanh tầm ưa thích — như người chơi di chuyển qua lại canh me.
	if adist > preferred + 15.0:
		return toward
	if adist < preferred - 15.0:
		return -toward
	state["strafe"] = -float(state["strafe"])
	return float(state["strafe"]) * 0.35


func _start_roll(state: Dictionary, dir: float) -> Dictionary:
	state["stamina"] = float(state["stamina"]) - COST_ROLL
	state["roll_dir"] = dir
	return _enter(state, PHASE_ROLL, Action.ROLL, dir)


## Hero vừa trúng đòn — mất thế (ngắt húp máu, ngắt combo).
func on_damaged(state: Dictionary) -> void:
	_enter(state, PHASE_STAGGER, Action.STAGGER, 0.0)


func is_telegraphing(state: Dictionary) -> bool:
	return state.get("phase", "") == PHASE_WINDUP


func is_rolling(state: Dictionary) -> bool:
	return state.get("phase", "") == PHASE_ROLL


func is_sipping(state: Dictionary) -> bool:
	return state.get("phase", "") == PHASE_SIP


func _defaults(state: Dictionary) -> void:
	if not state.has("phase"):
		state["phase"] = PHASE_SPACING
	if not state.has("timer"):
		state["timer"] = 0.0
	if not state.has("rng"):
		var rng := RandomNumberGenerator.new()
		rng.seed = 12345
		state["rng"] = rng
	if not state.has("stamina"):
		state["stamina"] = STAMINA_MAX
	if not state.has("flasks"):
		state["flasks"] = FLASKS_MAX
	if not state.has("combo"):
		state["combo"] = 0
	if not state.has("roll_dir"):
		state["roll_dir"] = 1.0
	if not state.has("strafe"):
		state["strafe"] = 1.0


func _enter(state: Dictionary, phase: String, action: Action, dir: float) -> Dictionary:
	state["phase"] = phase
	state["timer"] = 0.0
	return {"action": action, "move_dir": dir}


func _keep(action: Action, dir: float) -> Dictionary:
	return {"action": action, "move_dir": dir}
