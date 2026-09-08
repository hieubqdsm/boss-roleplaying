extends RefCounted

## AI Hero — "soul player" archetype (heuristic, không phải ML):
## spacing + stamina, lăn né i-frames, punish khi Queen hồi chiêu,
## estus (tạm tắt qua ESTUS_ENABLED), học qua chết.
## Toàn bộ dữ liệu qua CÁC CLASS TYPED (BrainConfig/Threats/Memory/BrainState)
## — không dùng Dictionary cho hợp đồng dữ liệu (review 2026-09-02).
## Thuần logic — test headless không cần scene (docs/CODING.md §0 & §3).

enum Action { WAIT, SPACING, ENGAGE, WINDUP, STRIKE, RECOVER, ROLL, RETREAT, SIP, HEAL_APPLY, STAGGER }

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

## Công tắc estus (user: tạm tắt 2026-09-02, GIỮ CODE — đổi true để bật lại).
const ESTUS_ENABLED := false

const ROLL_IFRAMES := 0.38

## Các loại đòn có thể giết hero (key ký ức memory.by).
const DAMAGE_KINDS := ["slash", "bolt", "nova", "skull"]

# Học né (giữ từ v2): chết vì đòn gì → né tốt đòn đó, có trần
const BASE_DODGE := {"bolt": 0.25, "nova": 0.5, "slash": 0.2}
const DODGE_PER_DEATH := 0.12
const DODGE_CAP := 0.85


## Cấu hình não cho 1 đời hero — Single source: BrainConfig.default().
## Game/tests cùng gọi hàm này rồi chỉnh chút xíu, khỏi lệch số.
class BrainConfig extends RefCounted:
	var attack_range := 58.0
	var preferred_range := 113.0
	var poke_rate := 0.02
	var windup_time := 0.08
	var strike_time := 0.22
	var recover_time := 0.35
	var stagger_time := 0.3
	var roll_time := 0.4
	var sip_time := 1.2

	static func default() -> BrainConfig:
		return BrainConfig.new()


## Những gì hero "nhìn thấy" mỗi frame (đổ từ hero._threats()).
class Threats extends RefCounted:
	var nova_windup := false
	var bolt_near := false
	var slash_windup := false
	var queen_recovery := false
	var hp_frac := 1.0


## Ký ức sống qua các mạng VÀ các ván chơi (lưu user://hero_memory.cfg).
class Memory extends RefCounted:
	var deaths := 0
	var by := {}          # key ∈ DAMAGE_KINDS — đếm chết theo loại đòn
	var fights := 0
	var queen_kills := 0
	var usage := {}       # key ∈ skill_uses — thói quen dùng chiêu của người chơi

	func count_death(kind: String) -> void:
		deaths += 1
		by[kind] = int(by.get(kind, 0)) + 1

	func add_usage(u: Dictionary) -> void:
		for k in u:
			usage[k] = int(usage.get(k, 0)) + int(u[k])

	func deaths_by(kind: String) -> int:
		return int(by.get(kind, 0))


## Trạng thái trong 1 đời hero. seed_value: game thật truyền randi() để
## mỗi round có vận may riêng; test giữ mặc định 12345 để deterministic.
class BrainState extends RefCounted:
	var phase: String = PHASE_SPACING
	var timer := 0.0
	var stamina := STAMINA_MAX
	var flasks := FLASKS_MAX
	var combo := 0
	var roll_dir := 1.0
	var strafe := 1.0
	var rng_seed := 12345
	var rng := RandomNumberGenerator.new()

	func _init(seed_value: int = 12345) -> void:
		rng_seed = seed_value
		rng.seed = seed_value


## Kết quả 1 bước não.
class StepResult extends RefCounted:
	var action: Action = Action.WAIT
	var move_dir := 0.0


static func dodge_chance(memory: Memory, kind: String) -> float:
	return minf(DODGE_CAP, float(BASE_DODGE.get(kind, 0.2)) + DODGE_PER_DEATH * memory.deaths_by(kind))


func step(dist_x: float, cfg: BrainConfig, state: BrainState, delta: float,
		threats: Threats, memory: Memory) -> StepResult:
	state.timer += delta
	var rng := state.rng
	var phase := state.phase
	var t := state.timer
	var adist := absf(dist_x)
	var toward := signf(dist_x)
	var attack_range := cfg.attack_range
	var preferred := cfg.preferred_range

	# Hồi stamina khi không dốc sức
	if phase == PHASE_SPACING or phase == PHASE_RETREAT or phase == PHASE_RECOVER or phase == PHASE_SIP:
		state.stamina = minf(STAMINA_MAX, state.stamina + STAMINA_REGEN * delta)

	match phase:
		PHASE_WINDUP:
			# vung kiếm khi vẫn tiến — không đứng khựng
			if t >= cfg.windup_time:
				return _enter(state, PHASE_STRIKE, Action.STRIKE, 0.0)
			return _keep(Action.WINDUP, toward * 0.6)

		PHASE_STRIKE:
			if t >= cfg.strike_time:
				return _enter(state, PHASE_RECOVER, Action.RECOVER, 0.0)
			return _keep(Action.STRIKE, 0.0)

		PHASE_RECOVER:
			if t >= cfg.recover_time:
				# Combo thứ 2 kiểu người chơi, hoặc rút lui — KHÔNG bám chém
				if state.combo < 2 and state.stamina >= COST_ATTACK \
						and adist < attack_range * 1.2 and rng.randf() < 0.45:
					state.combo += 1
					state.stamina -= COST_ATTACK
					return _enter(state, PHASE_WINDUP, Action.WINDUP, 0.0)
				if state.stamina >= COST_ROLL and rng.randf() < 0.4:
					return _start_roll(state, -toward)
				return _enter(state, PHASE_RETREAT, Action.RETREAT, -toward)
			return _keep(Action.RECOVER, 0.0)

		PHASE_ROLL:
			if t >= cfg.roll_time:
				return _enter(state, PHASE_SPACING, Action.SPACING, _spacing_dir(state, adist, preferred, toward))
			return _keep(Action.ROLL, state.roll_dir)

		PHASE_RETREAT:
			if t >= 0.55 or adist > preferred + 20.0:
				return _enter(state, PHASE_SPACING, Action.SPACING, _spacing_dir(state, adist, preferred, toward))
			return _keep(Action.RETREAT, -toward)

		PHASE_SIP:
			if t >= cfg.sip_time:
				state.flasks -= 1
				_enter(state, PHASE_SPACING, Action.SPACING, 0.0)
				var done := StepResult.new()
				done.action = Action.HEAL_APPLY
				return done
			return _keep(Action.SIP, 0.0)

		PHASE_STAGGER:
			if t >= cfg.stagger_time:
				return _enter(state, PHASE_SPACING, Action.SPACING, _spacing_dir(state, adist, preferred, toward))
			return _keep(Action.STAGGER, 0.0)

		PHASE_ENGAGE:
			if adist <= attack_range:
				if state.stamina >= COST_ATTACK:
					state.combo = 1
					state.stamina -= COST_ATTACK
					return _enter(state, PHASE_WINDUP, Action.WINDUP, 0.0)
				return _enter(state, PHASE_RETREAT, Action.RETREAT, -toward)
			if t >= 0.8:
				return _enter(state, PHASE_SPACING, Action.SPACING, _spacing_dir(state, adist, preferred, toward))
			return _keep(Action.ENGAGE, toward)

		_: # PHASE_SPACING — não "người chơi": chờ cửa, né, húp máu
			# 1) Sắp chết + an toàn → húp estus (tạm tắt qua ESTUS_ENABLED)
			if ESTUS_ENABLED and threats.hp_frac < 0.35 and state.flasks > 0 \
					and adist > 230.0 and not threats.bolt_near and not threats.nova_windup:
				return _enter(state, PHASE_SIP, Action.SIP, 0.0)
			# 2) Né — lăn QUA đòn (về phía Queen) hoặc lùi xa nova
			if threats.nova_windup and rng.randf() < dodge_chance(memory, "nova"):
				return _start_roll(state, -toward)
			if threats.bolt_near and rng.randf() < dodge_chance(memory, "bolt"):
				return _start_roll(state, toward if rng.randf() < 0.5 else -toward)
			if threats.slash_windup and adist < attack_range * 2.4 \
					and rng.randf() < dodge_chance(memory, "slash"):
				return _start_roll(state, toward)
			# 3) Punish: Queen vừa tung chiêu (đang hồi) + còn sức → xông vào
			if threats.queen_recovery and adist < 330.0 \
					and state.stamina >= COST_ATTACK + 10.0:
				return _enter(state, PHASE_ENGAGE, Action.ENGAGE, toward)
			# 4) Đủ gần + đủ stamina → đâm vào ăn một đòn rồi rút (poke)
			if adist <= attack_range and state.stamina >= COST_ATTACK + 20.0:
				return _enter(state, PHASE_ENGAGE, Action.ENGAGE, toward)
			# 4b) Đầy sức + trong vùng ưa thích → chủ động áp sát (poke_rate theo
			#     thói quen người chơi: pháo thủ → bám sát hơn)
			if state.stamina >= 80.0 and adist < preferred + 40.0 \
					and rng.randf() < cfg.poke_rate:
				return _enter(state, PHASE_ENGAGE, Action.ENGAGE, toward)
			# 5) Cạn stamina → chủ động lùi ra hồi
			if state.stamina < 40.0 and adist < preferred:
				return _enter(state, PHASE_RETREAT, Action.RETREAT, -toward)
			return _keep(Action.SPACING, _spacing_dir(state, adist, preferred, toward))


func _spacing_dir(state: BrainState, adist: float, preferred: float, toward: float) -> float:
	# Dao động nhẹ quanh tầm ưa thích — như người chơi di chuyển qua lại canh me.
	if adist > preferred + 15.0:
		return toward
	if adist < preferred - 15.0:
		return -toward
	state.strafe = -state.strafe
	return state.strafe * 0.35


func _start_roll(state: BrainState, dir: float) -> StepResult:
	state.stamina -= COST_ROLL
	state.roll_dir = dir
	return _enter(state, PHASE_ROLL, Action.ROLL, dir)


## Hero vừa trúng đòn — mất thế (ngắt húp máu, ngắt combo).
func on_damaged(state: BrainState) -> void:
	_enter(state, PHASE_STAGGER, Action.STAGGER, 0.0)


func is_telegraphing(state: BrainState) -> bool:
	return state.phase == PHASE_WINDUP


func is_rolling(state: BrainState) -> bool:
	return state.phase == PHASE_ROLL


func is_sipping(state: BrainState) -> bool:
	return state.phase == PHASE_SIP


func _enter(state: BrainState, phase: String, action: Action, dir: float) -> StepResult:
	state.phase = phase
	state.timer = 0.0
	var res := StepResult.new()
	res.action = action
	res.move_dir = dir
	return res


func _keep(action: Action, dir: float) -> StepResult:
	var res := StepResult.new()
	res.action = action
	res.move_dir = dir
	return res
