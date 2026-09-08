extends SceneTree
const BrainScript := preload("res://scripts/combat/hero_brain.gd")

## Unit test headless cho HeroBrain (AI kiểu "soul player", typed containers).
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


## Single source: cùng BrainConfig.default() mà game dùng (review: hết config copy).
func _cfg() -> BrainScript.BrainConfig:
	return BrainScript.BrainConfig.default()


func _tick(brain: BrainScript, state: BrainScript.BrainState, dist: float, frames: int,
		threats := BrainScript.Threats.new(), memory := BrainScript.Memory.new()) -> BrainScript.StepResult:
	var res := BrainScript.StepResult.new()
	for i in frames:
		res = brain.step(dist, _cfg(), state, 1.0 / 60.0, threats, memory)
	return res


func _test_spacing_far_moves_toward() -> void:
	var brain := BrainScript.new()
	var state := BrainScript.BrainState.new()
	var res := _tick(brain, state, 400.0, 5)
	_expect(res.action == BrainScript.Action.SPACING, "xa → giữ spacing")
	_expect(res.move_dir > 0.0, "ngoài tầm ưa thích → tiến nhẹ về phía Queen")


func _test_engage_windup_strike() -> void:
	var brain := BrainScript.new()
	var state := BrainScript.BrainState.new()
	var res := _tick(brain, state, 40.0, 2)
	_expect(res.action == BrainScript.Action.WINDUP, "vào tầm đánh → WINDUP ngay")
	_expect(state.stamina < BrainScript.STAMINA_MAX, "đòn tấn công tốn stamina")
	res = _tick(brain, state, 40.0, 6)  # 0.1s >= windup 0.08 (và chưa qua strike 0.22)
	_expect(res.action == BrainScript.Action.STRIKE, "hết windup → STRIKE")
	res = _tick(brain, state, 40.0, 15)  # 0.25s >= strike 0.22
	_expect(res.action == BrainScript.Action.RECOVER, "xong strike → RECOVER")
	res = _tick(brain, state, 500.0, 25)  # recover xong, đã xa
	var end_action := res.action
	_expect(end_action == BrainScript.Action.RETREAT or end_action == BrainScript.Action.SPACING
		or end_action == BrainScript.Action.ROLL or end_action == BrainScript.Action.WINDUP,
		"hết đòn → rút/lăn/spacing (không bám chém)")


func _test_stagger_interrupt() -> void:
	var brain := BrainScript.new()
	var state := BrainScript.BrainState.new()
	_tick(brain, state, 40.0, 2)  # vào windup
	brain.on_damaged(state)
	var res := _tick(brain, state, 40.0, 1)
	_expect(res.action == BrainScript.Action.STAGGER, "bị đánh giữa windup → mất thế")
	_expect(brain.is_telegraphing(state) == false, "stagger tắt telegraph")
	res = _tick(brain, state, 500.0, 25)  # 0.42s > stagger 0.3
	_expect(res.action == BrainScript.Action.SPACING, "hết stagger → quay về spacing")


func _test_dodge_learning() -> void:
	var m0 := BrainScript.Memory.new()
	_expect(absf(BrainScript.dodge_chance(m0, "bolt") - 0.25) < 0.001, "chưa chết lần nào → né bolt cơ bản 0.25")
	var m3 := BrainScript.Memory.new()
	for i in 3:
		m3.count_death("bolt")
	_expect(absf(BrainScript.dodge_chance(m3, "bolt") - (0.25 + 0.12 * 3)) < 0.001, "chết vì bolt ×3 → né bolt 0.61")
	var m10 := BrainScript.Memory.new()
	for i in 10:
		m10.count_death("bolt")
	_expect(absf(BrainScript.dodge_chance(m10, "bolt") - 0.85) < 0.001, "trần né 0.85")
	_expect(absf(BrainScript.dodge_chance(m3, "nova") - 0.5) < 0.001, "nova chưa từng giết → vẫn 0.5 cơ bản")


func _test_stamina_cost() -> void:
	var brain := BrainScript.new()
	var state := BrainScript.BrainState.new()
	# cạn stamina trong tầm đánh → KHÔNG vào windup, rút ra hồi
	state.stamina = 5.0
	var res := _tick(brain, state, 40.0, 2)
	_expect(res.action != BrainScript.Action.WINDUP and \
		res.action != BrainScript.Action.STRIKE, "stamina cạn → không đánh, lùi hồi")
	# hồi đủ từ từ
	_tick(brain, state, 300.0, 240)  # 4s regen
	_expect(state.stamina > 90.0, "spacing hồi stamina về ~đầy")


func _test_estus_sip() -> void:
	if not BrainScript.ESTUS_ENABLED:
		var brain := BrainScript.new()
		var state := BrainScript.BrainState.new()
		var th := BrainScript.Threats.new()
		th.hp_frac = 0.15
		var res := _tick(brain, state, 300.0, 2, th)
		_expect(res.action != BrainScript.Action.SIP, "estus tắt → HP thấp cũng không húp")
		return
	var brain := BrainScript.new()
	var state := BrainScript.BrainState.new()
	var threats := BrainScript.Threats.new()
	threats.hp_frac = 0.2
	var res := _tick(brain, state, 300.0, 1, threats)
	_expect(res.action == BrainScript.Action.SIP, "HP < 35% + an toàn + xa → húp estus")
	res = _tick(brain, state, 300.0, 72, threats)  # đúng 1.2s — frame HEAL_APPLY
	_expect(res.action == BrainScript.Action.HEAL_APPLY, "húp xong → hồi máu")
	_expect(state.flasks == 2, "húp xong mất 1 bình (còn 2)")
	res = _tick(brain, state, 300.0, 1, BrainScript.Threats.new())
	_expect(state.flasks == 2, "không húp thêm khi máu đầy")


func _test_punish_on_recovery() -> void:
	var brain := BrainScript.new()
	var state := BrainScript.BrainState.new()
	var threats := BrainScript.Threats.new()
	threats.queen_recovery = true
	var res := _tick(brain, state, 250.0, 1, threats)
	_expect(res.action == BrainScript.Action.ENGAGE, "Queen hồi chiêu trong 330px → lao vào punish")


func _expect(cond: bool, what: String) -> void:
	if cond:
		print("  PASS: %s" % what)
	else:
		_fails += 1
		print("  FAIL: %s" % what)
