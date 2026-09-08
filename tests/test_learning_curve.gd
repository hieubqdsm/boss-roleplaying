extends SceneTree
const BrainScript := preload("res://scripts/combat/hero_brain.gd")

## Đo đường cong HỌC của AI hero — controlled experiment:
## Queen mẫu cố định (chém 12 dmg, telegraph 0.2s, chu kỳ 1.4s), hero ở
## 113px (đúng khoảng giữ trong game), điều khiển bằng đúng não HeroBrain.step().
## Config dùng BrainConfig.default() — single source với game (review 2026-09-02).
## Chạy:  godot --headless --path . -s res://tests/test_learning_curve.gd

const LIVES := 8
const DT := 1.0 / 60.0
const SLASH_DMG := 12
const HERO_HP := 55
const INVULN_SPAWN := 0.9
const LIFE_CAP := 60.0

var _fails := 0


func _init() -> void:
	_test_learning_curve()
	_test_rng_seed_determinism()
	print("")
	if _fails == 0:
		print("test_learning_curve: ALL PASS")
		quit(0)
	else:
		print("test_learning_curve: %d FAIL" % _fails)
		quit(1)


func _test_learning_curve() -> void:
	var brain := BrainScript.new()
	var state := BrainScript.BrainState.new()
	var memory := BrainScript.Memory.new()
	var cfg := BrainScript.BrainConfig.default()

	var lives := []
	for life in LIVES:
		var r := _simulate_life(brain, state, cfg, memory)
		r["dodge_prob"] = BrainScript.dodge_chance(memory, "slash")
		r["dodge_ratio"] = float(r["dodges"]) / float(maxi(1, r["faced"]))
		r["hit_ratio"] = float(r["hits"]) / float(maxi(1, r["faced"]))
		lives.append(r)
		print("  mạng %d: sống %5.1fs | đòn phải mặt %2d | né %2d | trúng %2d | P(né) %.2f" % [
			life + 1, r["time"], r["faced"], r["dodges"], r["hits"], r["dodge_prob"]
		])
		memory.count_death("slash")

	var early := lives.slice(0, 3)
	var late := lives.slice(LIVES - 3, LIVES)
	var early_dodge := _avg(early, "dodge_ratio")
	var late_dodge := _avg(late, "dodge_ratio")
	var early_time := _avg(early, "time")
	var late_time := _avg(late, "time")
	print("  ── nửa đầu: né %.0f%%, sống TB %.1fs ── nửa sau: né %.0f%%, sống TB %.1fs" % [
		early_dodge * 100.0, early_time, late_dodge * 100.0, late_time
	])

	var mono := true
	for i in range(1, LIVES):
		if lives[i]["dodge_prob"] < lives[i - 1]["dodge_prob"] - 0.001:
			mono = false
	_expect(mono, "P(né) không bao giờ giảm qua các mạng")
	_expect(late_dodge > early_dodge, "tỷ lệ né thực tế: nửa sau (%.0f%%) > nửa đầu (%.0f%%)" % [late_dodge * 100.0, early_dodge * 100.0])
	var early_hit := _avg(early, "hit_ratio")
	var late_hit := _avg(late, "hit_ratio")
	_expect(late_hit < early_hit, "tỷ lệ đòn trúng: nửa sau (%.0f%%) < nửa đầu (%.0f%%)" % [late_hit * 100.0, early_hit * 100.0])
	_expect(late_time > early_time, "sống TB nửa sau (%.1fs) > nửa đầu (%.1fs)" % [late_time, early_time])
	_expect(memory.deaths == LIVES and int(memory.by.get("slash", 0)) == LIVES, "ký ức ghi đủ %d cái chết" % LIVES)


## Một mạng sống: queen chém theo mẫu cố định, hero điều khiển bởi brain.step().
func _simulate_life(brain: BrainScript, state: BrainScript.BrainState,
		cfg: BrainScript.BrainConfig, memory: BrainScript.Memory) -> Dictionary:
	var hp := HERO_HP
	var invuln := INVULN_SPAWN
	var slash_timer := 0.8
	var windup_left := 0.0
	var faced := 0
	var dodges := 0
	var hits := 0
	var t := 0.0

	while hp > 0 and t < LIFE_CAP:
		var threats := BrainScript.Threats.new()
		threats.slash_windup = windup_left > 0.0
		threats.hp_frac = float(hp) / float(HERO_HP)
		brain.step(113.0, cfg, state, DT, threats, memory)  # dist 113: đúng khoảng hero giữ trong game
		t += DT
		invuln = maxf(0.0, invuln - DT)

		if windup_left > 0.0:
			windup_left -= DT
			if windup_left <= 0.0:
				faced += 1
				var dodging: bool = brain.is_rolling(state) or invuln > 0.0
				if dodging:
					dodges += 1
				else:
					hits += 1
					hp -= SLASH_DMG
					brain.on_damaged(state)   # trúng đòn → mất thế như trong game
		else:
			slash_timer -= DT
			if slash_timer <= 0.0:
				windup_left = 0.2
				slash_timer = 1.4

	return {"time": t, "faced": faced, "dodges": dodges, "hits": hits}


## RNG seed: cùng seed → cùng chuỗi quyết định (test deterministic);
## seed khác → khác chuỗi (game truyền randi() mỗi round — hết lặp pattern).
func _test_rng_seed_determinism() -> void:
	var a := BrainScript.BrainState.new(777)
	var b := BrainScript.BrainState.new(777)
	var c := BrainScript.BrainState.new(778)
	var cfg := BrainScript.BrainConfig.default()
	var memory := BrainScript.Memory.new()
	var same := true
	var diff := false
	for i in 60:
		var threats := BrainScript.Threats.new()
		threats.slash_windup = i % 30 == 0
		var ra := BrainScript.new().step(150.0, cfg, a, DT, threats, memory)
		var rb := BrainScript.new().step(150.0, cfg, b, DT, threats, memory)
		var rc := BrainScript.new().step(150.0, cfg, c, DT, threats, memory)
		if ra.action != rb.action:
			same = false
		if ra.action != rc.action:
			diff = true
	_expect(same, "cùng seed 777 → 2 não ra quyết định giống hệt nhau (deterministic)")
	_expect(diff, "khác seed → có bước quyết định khác nhau (hết lặp pattern giữa các round)")


func _avg(arr: Array, key: String) -> float:
	var s := 0.0
	for r in arr:
		s += float(r[key])
	return s / float(arr.size())


func _expect(cond: bool, what: String) -> void:
	if cond:
		print("  PASS: %s" % what)
	else:
		_fails += 1
		print("  FAIL: %s" % what)
