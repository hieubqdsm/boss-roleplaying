class_name HeroBrain
extends RefCounted

## Logic AI của Hero — thuần dữ liệu, test headless không cần scene
## (docs/CODING.md §0 & §3). HeroBrain KHÔNG đụng node/hiển thị.

enum Action { WAIT, APPROACH, RETREAT, WINDUP, STRIKE, RECOVER, STAGGER }

## state: { "phase": String, "timer": float }
## cfg các khoá:
##   attack_range: float   — khoảng cách bắt đầu lấy đòn
##   windup_time: float    — thời gian giơ kiếm (telegraph)
##   strike_time: float    — thời gian vung kiếm (gây damage giữa khoảng này)
##   recover_time: float   — hồi sau đòn
##   stagger_time: float   — choáng khi bị đánh
##   retreat_time: float   — lùi né sau khi bị đánh xa
## Trả về Dictionary { "action": Action, "move_dir": float (-1..1) }.
## Hero gọi step() mỗi physics frame với delta thật; STRIKE trả về đúng 1 frame.

const PHASE_APPROACH := "approach"
const PHASE_WINDUP := "windup"
const PHASE_STRIKE := "strike"
const PHASE_RECOVER := "recover"
const PHASE_STAGGER := "stagger"
const PHASE_RETREAT := "retreat"


func step(dist_x: float, cfg: Dictionary, state: Dictionary, delta: float) -> Dictionary:
	state["timer"] = state.get("timer", 0.0) + delta
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

		PHASE_RETREAT:
			if t >= float(cfg.get("retreat_time", 0.35)):
				return _enter(state, PHASE_APPROACH, Action.APPROACH, signf(dist_x))
			return _keep(Action.RETREAT, -signf(dist_x))

		_: # PHASE_APPROACH
			if absf(dist_x) <= float(cfg.get("attack_range", 58.0)):
				return _enter(state, PHASE_WINDUP, Action.WINDUP, 0.0)
			return _keep(Action.APPROACH, signf(dist_x))


## Hero vừa trúng đòn — não quyết định phản ứng (choáng).
func on_damaged(state: Dictionary) -> void:
	_enter(state, PHASE_STAGGER, Action.STAGGER, 0.0)


func is_telegraphing(state: Dictionary) -> bool:
	return state.get("phase", "") == PHASE_WINDUP


func _enter(state: Dictionary, phase: String, action: Action, dir: float) -> Dictionary:
	state["phase"] = phase
	state["timer"] = 0.0
	return {"action": action, "move_dir": dir}


func _keep(action: Action, dir: float) -> Dictionary:
	return {"action": action, "move_dir": dir}
