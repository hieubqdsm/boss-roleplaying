extends SceneTree
const BrainScript := preload("res://scripts/combat/hero_brain.gd")

## Unit test headless cho HeroBrain v3 (AI kiểu "soul player").
## Chạy:  godot --headless --path . -s res://tests/test_hero_brain.gd
## (godot_exe nằm trong docs/LOCAL.md — xem AGENTS.md §1b)

var _fails := 0


func _init() -> void:
	_test_spacing_far_moves_toward()
	_test_engage_windup_strike()
	_test_stagger_interrupt()
	_test_dodge_learning()
	_test_stamina_cost()
	_test_estus_sip()
	_test_punish_on_recovery()
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
		"preferred_range": 113.0,
		"windup_time": 0.3,
		"strike_time": 0.22,
		"recover_time": 0.35,
		"stagger_time": 0.3,
		"roll_time": 0.4,
		"sip_time": 1.2,
	}


func _tick(brain: BrainScript, state: Dictionary, dist: float, frames: int,
		threats := {}, memory := {}, d := 1.0 / 60.0) -> Dictionary:
	var res := {}
	for i in frames:
		res = brain.step(dist, _cfg(), state, d, threats, memory)
	return res


func _test_spacing_far_moves_toward() -> void:
	var brain := BrainScript.new()
	var state := {}
	var res := _tick(brain, state, 400.0, 5)
	_expect(res["action"] == BrainScript.Action.SPACING, "xa → giữ spacing")
	_expect(float(res["move_dir"]) > 0.0, "ngoài tầm ưa thích → tiến nhẹ về phía Queen")


func _test_engage_windup_strike() -> void:
	var brain := BrainScript.new()
	var state := {}
	var res := _tick(brain, state, 40.0, 2)
	_expect(res["action"] == BrainScript.Action.WINDUP, "vào tầm đánh → WINDUP ngay")
	_expect(float(state["stamina"]) < BrainScript.STAMINA_MAX, "đòn tấn công tốn stamina")
	res = _tick(brain, state, 40.0, 20)  # 0.33s >= windup 0.3
	_expect(res["action"] == BrainScript.Action.STRIKE, "hết windup → STRIKE")
	res = _tick(brain, state, 40.0, 15)  # 0.25s >= strike 0.22
	_expect(res["action"] == BrainScript.Action.RECOVER, "xong strike → RECOVER")
	res = _tick(brain, state, 500.0, 25)  # recover xong, đã xa
	var end_action := int(res["action"])
	_expect(end_action == BrainScript.Action.RETREAT or end_action == BrainScript.Action.SPACING
		or end_action == BrainScript.Action.ROLL or end_action == BrainScript.Action.WINDUP,
		"hết đòn → rút/lăn/spacing (không bám chém)")


func _test_stagger_interrupt() -> void:
	var brain := BrainScript.new()
	var state := {}
	_tick(brain, state, 40.0, 2)  # vào windup
	brain.on_damaged(state)
	var res := _tick(brain, state, 40.0, 1)
	_expect(res["action"] == BrainScript.Action.STAGGER, "bị đánh giữa windup → mất thế")
	_expect(brain.is_telegraphing(state) == false, "stagger tắt telegraph")
	res = _tick(brain, state, 500.0, 25)  # 0.42s > stagger 0.3
	_expect(res["action"] == BrainScript.Action.SPACING, "hết stagger → quay về spacing")


func _test_dodge_learning() -> void:
	var m0 := {"deaths": 0, "by": {}}
	_expect(absf(BrainScript.dodge_chance(m0, "bolt") - 0.25) < 0.001, "chưa chết lần nào → né bolt cơ bản 0.25")
	var m3 := {"deaths": 3, "by": {"bolt": 3}}
	_expect(absf(BrainScript.dodge_chance(m3, "bolt") - (0.25 + 0.12 * 3)) < 0.001, "chết vì bolt ×3 → né bolt 0.61")
	var m10 := {"deaths": 10, "by": {"bolt": 10}}
	_expect(absf(BrainScript.dodge_chance(m10, "bolt") - 0.85) < 0.001, "trần né 0.85")
	_expect(absf(BrainScript.dodge_chance(m3, "nova") - 0.5) < 0.001, "nova chưa từng giết → vẫn 0.5 cơ bản")


func _test_stamina_cost() -> void:
	var brain := BrainScript.new()
	var state := {}
	# cạn stamina trong tầm đánh → KHÔNG vào windup, rút ra hồi
	state["stamina"] = 5.0
	var res := _tick(brain, state, 40.0, 2)
	_expect(int(res["action"]) != BrainScript.Action.WINDUP and \
		int(res["action"]) != BrainScript.Action.STRIKE, "stamina cạn → không đánh, lùi hồi")
	# hồi đủ từ từ
	_tick(brain, state, 300.0, 240)  # 4s regen
	_expect(float(state["stamina"]) > 90.0, "spacing hồi stamina về ~đầy")


func _test_estus_sip() -> void:
	if not BrainScript.ESTUS_ENABLED:
		var brain := BrainScript.new()
		var state := {}
		var res := _tick(brain, state, 300.0, 2, {"hp_frac": 0.15})
		_expect(int(res["action"]) != BrainScript.Action.SIP, "estus tắt → HP thấp cũng không húp")
		return
	var brain := BrainScript.new()
	var state := {}
	var threats := {"hp_frac": 0.2}
	var res := _tick(brain, state, 300.0, 1, threats)
	_expect(res["action"] == BrainScript.Action.SIP, "HP < 35% + an toàn + xa → húp estus")
	res = _tick(brain, state, 300.0, 72, threats)  # đúng 1.2s — frame HEAL_APPLY
	_expect(res["action"] == BrainScript.Action.HEAL_APPLY, "húp xong → hồi máu")
	_expect(int(state["flasks"]) == 2, "húp xong mất 1 bình (còn 2)")
	res = _tick(brain, state, 300.0, 1, {"hp_frac": 1.0})
	_expect(int(state["flasks"]) == 2, "không húp thêm khi máu đầy")


func _test_punish_on_recovery() -> void:
	var brain := BrainScript.new()
	var state := {}
	var threats := {"queen_recovery": true}
	var res := _tick(brain, state, 250.0, 1, threats)
	_expect(res["action"] == BrainScript.Action.ENGAGE, "Queen hồi chiêu trong 330px → lao vào punish")


func _expect(cond: bool, what: String) -> void:
	if cond:
		print("  PASS: %s" % what)
	else:
		_fails += 1
		print("  FAIL: %s" % what)
