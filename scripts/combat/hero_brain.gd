class_name HeroBrain
extends RefCounted

## AI Hero "tự học" — heuristic thích nghi, KHÔNG phải ML:
## - Mỗi lần chết nhớ LOẠI ĐÒN giết mình (slash/bolt/nova/skull) → những lần
##   sống dậy tăng xác suất né đúng loại đòn đó (backstep / nhảy).
## - Aggression (dmg, windup, speed) tăng theo số lần chết, CÓ TRẦN.
## Thuần logic — test headless không cần scene (docs/CODING.md §0 & §3).

enum Action { WAIT, APPROACH, RETREAT, WINDUP, STRIKE, RECOVER, STAGGER, BACKSTEP, JUMP_DODGE }

const PHASE_APPROACH := "approach"
const PHASE_WINDUP := "windup"
const PHASE_STRIKE := "strike"
const PHASE_RECOVER := "recover"
const PHASE_STAGGER := "stagger"
const PHASE_BACKSTEP := "backstep"
const PHASE_JUMP := "jump"

const BASE_DODGE := {"bolt": 0.22, "nova": 0.45, "slash": 0.12}
const DODGE_PER_DEATH := 0.13
const DODGE_CAP := 0.8


## Xác suất né loại đòn `kind` theo ký ức chết (memory = {"deaths", "by": {kind: n}}).
static func dodge_chance(memory: Dictionary, kind: String) -> float:
	var deaths := 0
	if memory.get("by", {}).has(kind):
		deaths = int(memory["by"][kind])
	return minf(DODGE_CAP, float(BASE_DODGE.get(kind, 0.2)) + DODGE_PER_DEATH * deaths)


## state: {"phase", "timer", "rng"?} — rng tự sinh (seed 12345) để test chạy được.
## threats: {"nova_windup": bool, "bolt_near": bool, "slash_windup": bool}
## Trả về {"action": Action, "move_dir": float}.
func step(dist_x: float, cfg: Dictionary, state: Dictionary, delta: float,
		threats: Dictionary = {}, memory: Dictionary = {}) -> Dictionary:
	state["timer"] = state.get("timer", 0.0) + delta
	if not state.has("rng"):
		var rng := RandomNumberGenerator.new()
		rng.seed = 12345
		state["rng"] = rng
	var rng: RandomNumberGenerator = state["rng"]
	var phase: String = state.get("phase", PHASE_APPROACH)
	var t: float = state["timer"]

	match phase:
		PHASE_WINDUP:
			if t >= float(cfg.get("windup_time", 0.45)):
				return _enter(state, PHASE_STRIKE, Action.STRIKE, 0.0)
			return _keep(Action.WINDUP, 0.0)

		PHASE_STRIKE:
			if t >= float(cfg.get("strike_time", 0.22)):
				return _enter(state, PHASE_RECOVER, Action.RECOVER, 0.0)
			return _keep(Action.STRIKE, 0.0)

		PHASE_RECOVER:
			if t >= float(cfg.get("recover_time", 0.55)):
				return _enter(state, PHASE_APPROACH, Action.APPROACH, signf(dist_x))
			return _keep(Action.RECOVER, 0.0)

		PHASE_STAGGER:
			if t >= float(cfg.get("stagger_time", 0.3)):
				return _enter(state, PHASE_APPROACH, Action.APPROACH, signf(dist_x))
			return _keep(Action.STAGGER, 0.0)

		PHASE_BACKSTEP:
			if t >= float(cfg.get("backstep_time", 0.32)):
				return _enter(state, PHASE_APPROACH, Action.APPROACH, signf(dist_x))
			return _keep(Action.BACKSTEP, -signf(dist_x))

		PHASE_JUMP:
			if t >= float(cfg.get("jump_time", 0.45)):
				return _enter(state, PHASE_APPROACH, Action.APPROACH, signf(dist_x))
			return _keep(Action.JUMP_DODGE, signf(dist_x) * 0.6)

		_: # PHASE_APPROACH — quyết định né TRƯỚC khi quyết định đánh
			if threats.get("nova_windup", false) and rng.randf() < dodge_chance(memory, "nova"):
				return _enter(state, PHASE_BACKSTEP, Action.BACKSTEP, -signf(dist_x))
			if threats.get("bolt_near", false) and rng.randf() < dodge_chance(memory, "bolt"):
				return _enter(state, PHASE_JUMP, Action.JUMP_DODGE, signf(dist_x) * 0.4)
			if threats.get("slash_windup", false) \
					and absf(dist_x) < float(cfg.get("attack_range", 58.0)) * 2.2 \
					and rng.randf() < dodge_chance(memory, "slash"):
				return _enter(state, PHASE_BACKSTEP, Action.BACKSTEP, -signf(dist_x))
			if absf(dist_x) <= float(cfg.get("attack_range", 58.0)):
				return _enter(state, PHASE_WINDUP, Action.WINDUP, 0.0)
			return _keep(Action.APPROACH, signf(dist_x))


## Hero vừa trúng đòn — não quyết định phản ứng (choáng).
func on_damaged(state: Dictionary) -> void:
	_enter(state, PHASE_STAGGER, Action.STAGGER, 0.0)


func is_telegraphing(state: Dictionary) -> bool:
	return state.get("phase", "") == PHASE_WINDUP


func is_dodging(state: Dictionary) -> bool:
	var p: String = state.get("phase", "")
	return p == PHASE_BACKSTEP or p == PHASE_JUMP


func _enter(state: Dictionary, phase: String, action: Action, dir: float) -> Dictionary:
	state["phase"] = phase
	state["timer"] = 0.0
	return {"action": action, "move_dir": dir}


func _keep(action: Action, dir: float) -> Dictionary:
	return {"action": action, "move_dir": dir}
