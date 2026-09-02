extends SceneTree
const BrainScript := preload("res://scripts/combat/hero_brain.gd")

## Unit test headless cho HeroBrain (logic AI thuần).
## Chạy:  godot --headless --path . -s res://tests/test_hero_brain.gd
## (cần godot_exe trong docs/LOCAL.md — xem AGENTS.md §1b)

var _fails := 0


func _init() -> void:
	_test_approach_until_range()
	_test_windup_strike_recover_cycle()
	_test_stagger_interrupt()
	print("")
	if _fails == 0:
		print("test_hero_brain: ALL PASS")
		quit(0)
	else:
		print("test_hero_brain: %d FAIL" % _fails)
		quit(1)


func _cfg() -> Dictionary:
	return {
		"attack_range": 58.0,
		"windup_time": 0.45,
		"strike_time": 0.22,
		"recover_time": 0.55,
		"stagger_time": 0.30,
		"retreat_time": 0.35,
	}


func _tick(brain: BrainScript, state: Dictionary, dist: float, frames: int, d := 1.0 / 60.0) -> Dictionary:
	var res := {}
	for i in frames:
		res = brain.step(dist, _cfg(), state, d)
	return res


func _test_approach_until_range() -> void:
	var brain := BrainScript.new()
	var state := {}
	var res := _tick(brain, state, 400.0, 30)
	_expect(res["action"] == BrainScript.Action.APPROACH, "xa → APPROACH")
	_expect(float(res["move_dir"]) > 0.0, "xa bên phải → đi sang phải")
	res = _tick(brain, state, 40.0, 1)
	_expect(res["action"] == BrainScript.Action.WINDUP, "vào tầm → WINDUP")


func _test_windup_strike_recover_cycle() -> void:
	var brain := BrainScript.new()
	var state := {}
	_tick(brain, state, 40.0, 1)  # vào windup
	var res := _tick(brain, state, 40.0, 30)  # 0.5s >= windup
	_expect(res["action"] == BrainScript.Action.STRIKE, "hết windup → STRIKE (đúng 1 frame)")
	res = _tick(brain, state, 40.0, 1)
	_expect(res["action"] == BrainScript.Action.RECOVER, "xong strike → RECOVER")
	res = _tick(brain, state, 500.0, 40)
	_expect(res["action"] == BrainScript.Action.APPROACH, "hết recover → APPROACH")


func _test_stagger_interrupt() -> void:
	var brain := BrainScript.new()
	var state := {}
	_tick(brain, state, 40.0, 1)  # windup
	brain.on_damaged(state)
	var res := _tick(brain, state, 40.0, 1)
	_expect(res["action"] == BrainScript.Action.STAGGER, "bị đánh giữa windup → STAGGER")
	_expect(brain.is_telegraphing(state) == false, "stagger tắt telegraph")
	res = _tick(brain, state, 40.0, 25)  # 0.42s > stagger 0.3
	_expect(res["action"] == BrainScript.Action.WINDUP, "hết stagger → quay lại WINDUP")


func _expect(cond: bool, what: String) -> void:
	if cond:
		print("  PASS: %s" % what)
	else:
		_fails += 1
		print("  FAIL: %s" % what)
