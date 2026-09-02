extends SceneTree
const BrainScript := preload("res://scripts/combat/hero_brain.gd")

## Đo đường cong HỌC của AI hero — mô phỏng controlled experiment:
## Queen theo mẫu cố định (chém 12 dmg, telegraph 0.12s, chu kỳ 1.4s),
## hero đứng ở 200px (ngoài tầm chém — chỉ bị đánh bởi mẫu cố định đó).
## Cùng hàm não step()/dodge_chance() và cùng cách cập nhật ký ức như hero.gd.
## Kỳ vọng NẾU HỌC HOẠT ĐỘNG: về sau mỗi mạng
##   - tỷ lệ né (roll kịp lúc telegraph) CAO HƠN
##   - tỷ lệ đòn trúng THẤP HƠN
##   - thời gian sống DÀI HƠN
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
	print("")
	if _fails == 0:
		print("test_learning_curve: ALL PASS")
		quit(0)
	else:
		print("test_learning_curve: %d FAIL" % _fails)
		quit(1)


func _test_learning_curve() -> void:
	var brain := BrainScript.new()
	var state := {}
	var memory := {"deaths": 0, "by": {}}
	var cfg := {
		"attack_range": 58.0, "preferred_range": 113.0, "poke_rate": 0.02,
		"windup_time": 0.08, "strike_time": 0.22, "recover_time": 0.35,
		"stagger_time": 0.3, "roll_time": 0.4, "sip_time": 1.2,
	}

	var lives := []
	for life in LIVES:
		var r := _simulate_life(brain, state, cfg, memory)
		r["life"] = life + 1
		r["dodge_prob"] = BrainScript.dodge_chance(memory, "slash")
		r["dodge_ratio"] = float(r["dodges"]) / float(maxi(1, r["faced"]))
		r["hit_ratio"] = float(r["hits"]) / float(maxi(1, r["faced"]))
		lives.append(r)
		print("  mạng %d: sống %5.1fs | đòn phải mặt %2d | né %2d | trúng %2d | P(né) %.2f" % [
			life + 1, r["time"], r["faced"], r["dodges"], r["hits"], r["dodge_prob"]
		])
		# ký ức cập nhật như hero._on_died
		memory["deaths"] = int(memory.get("deaths", 0)) + 1
		var by: Dictionary = memory.get("by", {})
		by["slash"] = int(by.get("slash", 0)) + 1
		memory["by"] = by

	var early := lives.slice(0, 3)
	var late := lives.slice(LIVES - 3, LIVES)
	var early_dodge := _avg(early, "dodge_ratio")
	var late_dodge := _avg(late, "dodge_ratio")
	var early_time := _avg(early, "time")
	var late_time := _avg(late, "time")
	print("  ── nửa đầu: né %.0f%%, sống TB %.1fs ── nửa sau: né %.0f%%, sống TB %.1fs" % [
		early_dodge * 100.0, early_time, late_dodge * 100.0, late_time
	])

	# 1) P(né) tăng đơn điệu theo số lần chết (trần 0.85)
	var mono := true
	for i in range(1, LIVES):
		if lives[i]["dodge_prob"] < lives[i - 1]["dodge_prob"] - 0.001:
			mono = false
	_expect(mono, "P(né) không bao giờ giảm qua các mạng")

	# 2) né thực tế nửa sau tốt hơn nửa đầu
	_expect(late_dodge > early_dodge, "tỷ lệ né thực tế: nửa sau (%.0f%%) > nửa đầu (%.0f%%)" % [late_dodge * 100.0, early_dodge * 100.0])

	# 3) tỷ lệ trúng nửa sau thấp hơn
	var early_hit := _avg(early, "hit_ratio")
	var late_hit := _avg(late, "hit_ratio")
	_expect(late_hit < early_hit, "tỷ lệ đòn trúng: nửa sau (%.0f%%) < nửa đầu (%.0f%%)" % [late_hit * 100.0, early_hit * 100.0])

	# 4) sống dai hơn về sau (chỉ số học tổng hợp)
	_expect(late_time > early_time, "sống TB nửa sau (%.1fs) > nửa đầu (%.1fs)" % [late_time, early_time])

	# 5) ký ức đếm đủ
	_expect(int(memory["deaths"]) == LIVES and int(memory["by"]["slash"]) == LIVES, "ký ức ghi đủ %d cái chết" % LIVES)


## Một mạng sống: queen chém theo mẫu cố định, hero điều khiển bởi brain.step().
func _simulate_life(brain: BrainScript, state: Dictionary, cfg: Dictionary, memory: Dictionary) -> Dictionary:
	var hp := HERO_HP
	var invuln := INVULN_SPAWN
	var slash_timer := 0.8   # đòn chém đầu sau 0.8s
	var windup_left := 0.0
	var faced := 0
	var dodges := 0
	var hits := 0
	var t := 0.0

	while hp > 0 and t < LIFE_CAP:
		var threats := {
			"slash_windup": windup_left > 0.0,
			"nova_windup": false, "bolt_near": false,
			"queen_recovery": false, "hp_frac": float(hp) / float(HERO_HP),
		}
		brain.step(113.0, cfg, state, DT, threats, memory)   # dist 113: đúng khoảng hero giữ trong game
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
				windup_left = 0.12
				slash_timer = 1.4

	return {"time": t, "faced": faced, "dodges": dodges, "hits": hits}


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
