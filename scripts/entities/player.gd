extends CharacterBody2D

var move_target: Vector2 = Vector2.ZERO
var move_speed: float = 210.0
var max_hp: float = 100.0
var hp: float = 100.0
var attack_damage: float = 14.0
var attack_range: float = 120.0
var attack_rate: float = 1.3
var dash_cooldown: float = 8.0
var dash_distance: float = 200.0

var _attack_timer: float = 0.0
var _dash_timer: float = 0.0
var _anim_time: float = 0.0
var _swing_flash: float = 0.0
var _facing: Vector2 = Vector2(0, -1)

func _ready() -> void:
	move_target = position

func setup_from_skills() -> void:
	move_speed += SaveManager.get_skill_level("player_speed") * 20.0
	attack_damage += SaveManager.get_skill_level("player_damage") * 5.0
	max_hp += SaveManager.get_skill_level("player_hp") * 25.0
	attack_range += SaveManager.get_skill_level("attack_range") * 15.0
	hp = max_hp

func tick(dt: float, enemies: Array, gm: Node) -> void:
	_anim_time += dt
	if _attack_timer > 0.0:
		_attack_timer = maxf(0.0, _attack_timer - dt)
	if _dash_timer > 0.0:
		_dash_timer = maxf(0.0, _dash_timer - dt)
	if _swing_flash > 0.0:
		_swing_flash = maxf(0.0, _swing_flash - dt)

	var to_target := move_target - position
	var dist := to_target.length()
	if dist > 2.0:
		_facing = to_target.normalized()
		position += _facing * minf(dist, move_speed * dt)

	var target := _find_nearest_enemy_in_range(enemies)
	if target != null and _attack_timer <= 0.0:
		target.take_damage(attack_damage, GameData.DamageType.PHYSICAL, "player")
		_attack_timer = 1.0 / maxf(attack_rate, 0.01)
		_swing_flash = 0.14
		if gm != null and gm.has_method("_spawn_text"):
			gm._spawn_text(target.position.x, target.position.y - 18.0, str(int(attack_damage)), Color(0.96, 0.90, 0.68), 0.7, 16)

	queue_redraw()

func set_move_target(pos: Vector2) -> void:
	move_target = pos

func get_dash_cooldown_remaining() -> float:
	return _dash_timer

func can_dash() -> bool:
	return _dash_timer <= 0.0

func dash_toward(target_pos: Vector2, enemies: Array, gm: Node) -> bool:
	if not can_dash():
		return false
	var dash_vec := target_pos - position
	if dash_vec.length() < 6.0:
		return false
	var from := position
	var to := position + dash_vec.normalized() * minf(dash_distance, dash_vec.length())
	position = to
	move_target = to
	_facing = (to - from).normalized()
	_dash_timer = dash_cooldown
	_swing_flash = 0.18

	var dash_damage := attack_damage * 2.0
	for enemy_node in enemies:
		if enemy_node.is_dead():
			continue
		if _distance_to_segment(enemy_node.position, from, to) <= 42.0:
			enemy_node.take_damage(dash_damage, GameData.DamageType.PHYSICAL, "dash")

	if gm != null:
		if gm.has_method("_spawn_text"):
			gm._spawn_text(position.x, position.y - 34.0, "DASH", Color(0.52, 0.90, 1.0), 1.0, 22)
		if gm.has_method("_trigger_shake"):
			gm._trigger_shake(0.12, 5.0)
	return true

func _find_nearest_enemy_in_range(enemies: Array) -> Node:
	var best: Node = null
	var best_dist := INF
	for enemy_node in enemies:
		if enemy_node.is_dead():
			continue
		var d := position.distance_to(enemy_node.position)
		if d <= attack_range and d < best_dist:
			best_dist = d
			best = enemy_node
	return best

func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_sq := segment.length_squared()
	if length_sq <= 0.001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(segment) / length_sq, 0.0, 1.0)
	var closest := a + segment * t
	return point.distance_to(closest)

func _draw() -> void:
	var bob := sin(_anim_time * 7.0) * 1.6
	var body_col := Color(0.22, 0.56, 0.90)
	var trim_col := Color(0.84, 0.94, 1.0)

	draw_circle(Vector2(2, 4), 13.0, Color(0, 0, 0, 0.28))
	draw_circle(Vector2(0, bob), 12.0, body_col)
	draw_circle(Vector2(0, -12 + bob), 8.0, body_col.lightened(0.12))
	draw_circle(Vector2(-2, -14 + bob), 2.2, trim_col * Color(1, 1, 1, 0.35))

	var sword_base := Vector2(0, -2 + bob)
	var sword_tip := sword_base + _facing * 16.0
	draw_line(sword_base, sword_tip, trim_col, 2.4)
	draw_line(sword_base, sword_base + _facing.rotated(PI * 0.5) * 4.0, trim_col.darkened(0.35), 1.6)

	if _swing_flash > 0.0:
		draw_circle(sword_tip, 7.0, Color(0.86, 0.96, 1.0, _swing_flash * 0.8))

	var ring_col := Color(0.48, 0.86, 1.0) if can_dash() else Color(0.34, 0.44, 0.56)
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 30, ring_col * Color(1, 1, 1, 0.44), 1.4)
	if not can_dash():
		var pct := clampf(1.0 - (_dash_timer / dash_cooldown), 0.0, 1.0)
		draw_arc(Vector2.ZERO, 18.0, -PI * 0.5, -PI * 0.5 + TAU * pct, 30, Color(0.58, 0.96, 1.0, 0.78), 2.1)
