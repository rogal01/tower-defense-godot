# Enemy.gd — Enemy entity: path following, HP, type display, boss abilities
extends Node2D

signal died()
signal reached_base()

# ─── State ────────────────────────────────────────────────────────────────────
var enemy_type: int = GameData.EnemyType.GOBLIN
var is_boss: bool = false
var boss_type: int = -1
var boss_ability: int = -1

var hp: float = 20.0
var max_hp: float = 20.0
var speed: float = 80.0
var gold_reward: int = 3
var damage: float = 5.0
var emoji: String = "👺"
var enemy_size: float = 28.0

# Path
var path_index: int = 0
var waypoints: Array = []   # Array[Vector2]
var waypoint_idx: int = 0

# Status effects
var ice_slow: float = 1.0      # 0..1 multiplier
var ice_slow_timer: float = 0.0
var burn_timer: float = 0.0
var burn_dps: float = 0.0
var poison_timer: float = 0.0
var poison_dps: float = 0.0
var stun_timer: float = 0.0
var shield_timer: float = 0.0
var regen_rate: float = 0.0

# Boss ability timer
var boss_ability_timer: float = 5.0
var boss_ability_cd: float = 5.0
var boss_has_split: bool = false

# Charge ability
var charge_speed_mult: float = 1.0
var charge_timer: float = 0.0

# Death state
var _dead: bool = false
var _reached: bool = false

# Visual
var hit_flash_timer: float = 0.0
var _anim_time: float = 0.0
var _move_dir: Vector2 = Vector2(0, 1)
var _death_timer: float = -1.0

# ─── Enemy color palette ─────────────────────────────────────────────────────
const ENEMY_COLORS := {
	0:  {body=Color(0.30, 0.65, 0.20), eyes=Color(1.0, 0.2, 0.1)},       # Goblin - green
	1:  {body=Color(0.85, 0.85, 0.80), eyes=Color(0.1, 0.1, 0.1)},       # Skeleton - bone white
	2:  {body=Color(0.35, 0.55, 0.20), eyes=Color(0.9, 0.3, 0.1)},       # Orc - dark green
	3:  {body=Color(0.75, 0.15, 0.15), eyes=Color(1.0, 0.8, 0.0)},       # Demon - red
	4:  {body=Color(0.20, 0.50, 0.20), eyes=Color(1.0, 0.6, 0.0)},       # Dragon - dark green
	5:  {body=Color(0.80, 0.80, 0.75), eyes=Color(0.15, 0.15, 0.15)},    # Fast Skeleton
	6:  {body=Color(0.50, 0.45, 0.35), eyes=Color(0.3, 0.8, 1.0)},       # Armored Golem - stone
	7:  {body=Color(0.20, 0.15, 0.25), eyes=Color(1.0, 0.3, 0.3)},       # Bat - dark
	8:  {body=Color(0.20, 0.75, 0.30), eyes=Color(0.1, 0.3, 0.1)},       # Slime - bright green
	9:  {body=Color(0.25, 0.18, 0.15), eyes=Color(1.0, 0.1, 0.1)},       # Spider - dark brown
	10: {body=Color(0.70, 0.85, 1.0),  eyes=Color(1.0, 1.0, 0.8)},       # Wisp - light blue
	11: {body=Color(0.15, 0.12, 0.20), eyes=Color(0.6, 0.2, 0.8)},       # Shadow - dark
	12: {body=Color(0.70, 0.25, 0.15), eyes=Color(1.0, 0.9, 0.2)},       # Berserker - red-brown
	13: {body=Color(0.50, 0.35, 0.15), eyes=Color(1.0, 0.85, 0.0)},      # Commander - gold-brown
	14: {body=Color(0.50, 0.30, 0.60), eyes=Color(0.9, 0.9, 0.9)},       # Shapeshifter - purple
}

# ─── Setup ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	pass  # No child nodes needed - everything drawn in _draw()

func setup(etype: int, pos: Vector2, pidx: int, wps: Array,
		spd: float, p_hp: float, p_gold: int, p_dmg: float,
		p_emoji: String, p_regen: float) -> void:
	enemy_type = etype
	position = pos
	path_index = pidx
	waypoints = wps
	waypoint_idx = 1 if wps.size() > 1 else 0
	speed = spd
	hp = p_hp
	max_hp = p_hp
	gold_reward = p_gold
	damage = p_dmg
	emoji = p_emoji
	regen_rate = p_regen
	is_boss = false
	enemy_size = GameData.get_enemy(etype)["size"]

func setup_boss(btype: int, pos: Vector2, pidx: int, wps: Array,
		spd: float, p_hp: float, p_gold: int, p_dmg: float,
		p_emoji: String, p_ability: int) -> void:
	enemy_type = GameData.EnemyType.BOSS
	boss_type = btype
	boss_ability = p_ability
	position = pos
	path_index = pidx
	waypoints = wps
	waypoint_idx = 1 if wps.size() > 1 else 0
	speed = spd
	hp = p_hp
	max_hp = p_hp
	gold_reward = p_gold
	damage = p_dmg
	emoji = p_emoji
	is_boss = true
	enemy_size = 55.0
	boss_ability_cd = 12.0 if p_ability == GameData.BossAbility.SHIELD else 5.0
	boss_ability_timer = 5.0

# ─── Tick (called by GameManager each frame) ──────────────────────────────────

func tick(dt: float) -> void:
	if _dead or _reached:
		return

	_anim_time += dt

	# Status effects
	if stun_timer > 0:
		stun_timer -= dt
		queue_redraw()
		return

	# Charge timer decay
	if charge_timer > 0:
		charge_timer -= dt
		if charge_timer <= 0:
			charge_speed_mult = 1.0

	if burn_timer > 0:
		burn_timer -= dt
		hp -= burn_dps * dt

	if poison_timer > 0:
		poison_timer -= dt
		hp -= poison_dps * dt

	if regen_rate > 0 and hp < max_hp:
		hp = minf(hp + regen_rate * dt, max_hp)

	if ice_slow_timer > 0:
		ice_slow_timer -= dt
	else:
		ice_slow = 1.0

	if shield_timer > 0:
		shield_timer -= dt

	if hp <= 0:
		_die()
		return

	# Move along path
	_move_along_path(dt)

	# Hit flash
	if hit_flash_timer > 0:
		hit_flash_timer -= dt

	# Boss ability
	if is_boss:
		boss_ability_timer -= dt
		if boss_ability_timer <= 0:
			boss_ability_timer = boss_ability_cd
			_fire_boss_ability()

	queue_redraw()

# ─── Draw enemy sprite ────────────────────────────────────────────────────────

func _draw() -> void:
	if _dead or _reached:
		return

	var sz: float = enemy_size * 0.45
	if is_boss:
		sz = 20.0

	# Get colors
	var colors: Dictionary
	if is_boss:
		var bdata := GameData.get_boss(boss_type) if boss_type >= 0 else {}
		var boss_col: Color = bdata.get("color", Color(0.6, 0.1, 0.1))
		colors = {body=boss_col, eyes=Color(1.0, 0.8, 0.0)}
	else:
		colors = ENEMY_COLORS.get(enemy_type, ENEMY_COLORS[0])

	var body_col: Color = colors.body
	var eye_col: Color = colors.eyes

	# Hit flash tint
	if hit_flash_timer > 0:
		body_col = body_col.lerp(Color(1, 0.2, 0.2), 0.6)

	# Status effect overlays
	if ice_slow < 1.0:
		body_col = body_col.lerp(Color(0.5, 0.8, 1.0), 0.3)
	if burn_timer > 0:
		body_col = body_col.lerp(Color(1.0, 0.4, 0.1), 0.25)
	if poison_timer > 0:
		body_col = body_col.lerp(Color(0.3, 0.8, 0.2), 0.2)
	if stun_timer > 0:
		body_col = body_col.lerp(Color(1.0, 1.0, 0.3), 0.3)

	# Shield ring
	if shield_timer > 0:
		draw_arc(Vector2.ZERO, sz + 6, 0, TAU, 24, Color(0.3, 0.6, 1.0, 0.5 + sin(_anim_time * 4) * 0.15), 2.5)

	# Shadow
	draw_ellipse_custom(Vector2(0, sz * 0.5), sz * 0.7, sz * 0.25, Color(0, 0, 0, 0.25))

	# Walking bob
	var bob := sin(_anim_time * 8.0) * 1.5 if not (stun_timer > 0) else 0.0

	# Draw body based on type
	if is_boss:
		_draw_boss_sprite(sz, body_col, eye_col, bob)
	else:
		_draw_enemy_sprite(sz, body_col, eye_col, bob)

	# Status effect particles
	_draw_status_particles(sz)

	# HP bar
	_draw_hp_bar(sz)
	_draw_status_icons(sz)

func _draw_enemy_sprite(sz: float, body_col: Color, eye_col: Color, bob: float) -> void:
	match enemy_type:
		GameData.EnemyType.GOBLIN, GameData.EnemyType.MINI_ORC:
			_draw_humanoid(sz, body_col, eye_col, bob, true)
		GameData.EnemyType.SKELETON, GameData.EnemyType.FAST_SKELETON, GameData.EnemyType.MINI_SKELETON:
			_draw_skeleton(sz, body_col, eye_col, bob)
		GameData.EnemyType.ORC:
			_draw_humanoid(sz * 1.2, body_col, eye_col, bob, false)
		GameData.EnemyType.DEMON, GameData.EnemyType.MINI_DEMON:
			_draw_demon(sz, body_col, eye_col, bob)
		GameData.EnemyType.DRAGON, GameData.EnemyType.MINI_DRAGON:
			_draw_dragon(sz, body_col, eye_col, bob)
		GameData.EnemyType.BAT:
			_draw_bat(sz, body_col, eye_col, bob)
		GameData.EnemyType.SLIME:
			_draw_slime(sz, body_col, eye_col, bob)
		GameData.EnemyType.SPIDER:
			_draw_spider(sz, body_col, eye_col, bob)
		GameData.EnemyType.WISP:
			_draw_wisp(sz, body_col, eye_col, bob)
		GameData.EnemyType.SHADOW:
			_draw_shadow(sz, body_col, eye_col, bob)
		GameData.EnemyType.BERSERKER:
			_draw_humanoid(sz * 1.1, body_col, eye_col, bob, false)
		GameData.EnemyType.COMMANDER:
			_draw_commander(sz, body_col, eye_col, bob)
		GameData.EnemyType.SHAPESHIFTER:
			_draw_shapeshifter(sz, body_col, eye_col, bob)
		GameData.EnemyType.ARMORED_GOLEM, GameData.EnemyType.GOLEM_SHARD:
			_draw_golem(sz, body_col, eye_col, bob)
		_:
			_draw_humanoid(sz, body_col, eye_col, bob, true)

func _draw_humanoid(sz: float, col: Color, eye_col: Color, bob: float, pointy_ears: bool) -> void:
	# Body
	draw_circle(Vector2(0, bob), sz * 0.7, col)
	# Head
	draw_circle(Vector2(0, -sz * 0.6 + bob), sz * 0.45, col.lightened(0.1))
	# Eyes
	draw_circle(Vector2(-sz * 0.15, -sz * 0.65 + bob), sz * 0.1, eye_col)
	draw_circle(Vector2(sz * 0.15, -sz * 0.65 + bob), sz * 0.1, eye_col)
	# Pointy ears
	if pointy_ears:
		draw_line(Vector2(-sz * 0.35, -sz * 0.7 + bob), Vector2(-sz * 0.55, -sz * 0.95 + bob), col.lightened(0.1), 2.0)
		draw_line(Vector2(sz * 0.35, -sz * 0.7 + bob), Vector2(sz * 0.55, -sz * 0.95 + bob), col.lightened(0.1), 2.0)
	# Feet
	var step := sin(_anim_time * 8.0) * 2.0
	draw_circle(Vector2(-sz * 0.25, sz * 0.6 + step), sz * 0.18, col.darkened(0.2))
	draw_circle(Vector2(sz * 0.25, sz * 0.6 - step), sz * 0.18, col.darkened(0.2))

func _draw_skeleton(sz: float, col: Color, eye_col: Color, bob: float) -> void:
	# Ribcage lines
	for i in range(3):
		var y := -sz * 0.1 + i * sz * 0.2 + bob
		draw_line(Vector2(-sz * 0.3, y), Vector2(sz * 0.3, y), col, 1.5)
	# Spine
	draw_line(Vector2(0, -sz * 0.3 + bob), Vector2(0, sz * 0.4 + bob), col, 2.0)
	# Skull
	draw_circle(Vector2(0, -sz * 0.55 + bob), sz * 0.4, col)
	# Eye sockets
	draw_circle(Vector2(-sz * 0.12, -sz * 0.6 + bob), sz * 0.1, eye_col)
	draw_circle(Vector2(sz * 0.12, -sz * 0.6 + bob), sz * 0.1, eye_col)
	# Jaw
	draw_line(Vector2(-sz * 0.15, -sz * 0.4 + bob), Vector2(sz * 0.15, -sz * 0.4 + bob), col.darkened(0.2), 1.5)
	# Leg bones
	var step := sin(_anim_time * 8.0) * 2.0
	draw_line(Vector2(0, sz * 0.4 + bob), Vector2(-sz * 0.3, sz * 0.7 + step + bob), col, 1.5)
	draw_line(Vector2(0, sz * 0.4 + bob), Vector2(sz * 0.3, sz * 0.7 - step + bob), col, 1.5)

func _draw_demon(sz: float, col: Color, eye_col: Color, bob: float) -> void:
	# Body
	draw_circle(Vector2(0, bob), sz * 0.65, col)
	# Head
	draw_circle(Vector2(0, -sz * 0.55 + bob), sz * 0.4, col.lightened(0.05))
	# Horns
	draw_line(Vector2(-sz * 0.25, -sz * 0.8 + bob), Vector2(-sz * 0.4, -sz * 1.15 + bob), Color(0.3, 0.1, 0.1), 2.5)
	draw_line(Vector2(sz * 0.25, -sz * 0.8 + bob), Vector2(sz * 0.4, -sz * 1.15 + bob), Color(0.3, 0.1, 0.1), 2.5)
	# Glowing eyes
	draw_circle(Vector2(-sz * 0.12, -sz * 0.6 + bob), sz * 0.1, eye_col)
	draw_circle(Vector2(sz * 0.12, -sz * 0.6 + bob), sz * 0.1, eye_col)
	# Tail
	var tail_wave := sin(_anim_time * 3.0) * 4.0
	draw_line(Vector2(0, sz * 0.5 + bob), Vector2(sz * 0.5 + tail_wave, sz * 0.3 + bob), col.darkened(0.2), 2.0)

func _draw_dragon(sz: float, col: Color, eye_col: Color, bob: float) -> void:
	# Body (elongated)
	draw_colored_polygon([
		Vector2(0, -sz * 0.8 + bob),
		Vector2(-sz * 0.5, -sz * 0.2 + bob),
		Vector2(-sz * 0.4, sz * 0.4 + bob),
		Vector2(0, sz * 0.6 + bob),
		Vector2(sz * 0.4, sz * 0.4 + bob),
		Vector2(sz * 0.5, -sz * 0.2 + bob),
	], col)
	# Head
	draw_circle(Vector2(0, -sz * 0.7 + bob), sz * 0.35, col.lightened(0.1))
	# Eyes
	draw_circle(Vector2(-sz * 0.1, -sz * 0.75 + bob), sz * 0.08, eye_col)
	draw_circle(Vector2(sz * 0.1, -sz * 0.75 + bob), sz * 0.08, eye_col)
	# Wings
	var wing_flap := sin(_anim_time * 4.0) * 3.0
	draw_colored_polygon([
		Vector2(-sz * 0.3, -sz * 0.3 + bob),
		Vector2(-sz * 1.0, -sz * 0.6 + bob + wing_flap),
		Vector2(-sz * 0.7, -sz * 0.1 + bob + wing_flap * 0.5),
	], col.darkened(0.15))
	draw_colored_polygon([
		Vector2(sz * 0.3, -sz * 0.3 + bob),
		Vector2(sz * 1.0, -sz * 0.6 + bob + wing_flap),
		Vector2(sz * 0.7, -sz * 0.1 + bob + wing_flap * 0.5),
	], col.darkened(0.15))
	# Snout/horns
	draw_line(Vector2(-sz * 0.15, -sz * 0.9 + bob), Vector2(-sz * 0.2, -sz * 1.1 + bob), col.darkened(0.2), 1.5)
	draw_line(Vector2(sz * 0.15, -sz * 0.9 + bob), Vector2(sz * 0.2, -sz * 1.1 + bob), col.darkened(0.2), 1.5)

func _draw_bat(sz: float, col: Color, eye_col: Color, bob: float) -> void:
	# Body (small)
	draw_circle(Vector2(0, bob), sz * 0.4, col)
	# Eyes
	draw_circle(Vector2(-sz * 0.1, -sz * 0.1 + bob), sz * 0.08, eye_col)
	draw_circle(Vector2(sz * 0.1, -sz * 0.1 + bob), sz * 0.08, eye_col)
	# Wings (flapping)
	var flap := sin(_anim_time * 10.0) * 4.0
	draw_colored_polygon([
		Vector2(-sz * 0.2, bob),
		Vector2(-sz * 1.0, -sz * 0.3 + bob + flap),
		Vector2(-sz * 0.8, sz * 0.2 + bob + flap * 0.5),
		Vector2(-sz * 0.2, sz * 0.15 + bob),
	], col.lightened(0.1))
	draw_colored_polygon([
		Vector2(sz * 0.2, bob),
		Vector2(sz * 1.0, -sz * 0.3 + bob + flap),
		Vector2(sz * 0.8, sz * 0.2 + bob + flap * 0.5),
		Vector2(sz * 0.2, sz * 0.15 + bob),
	], col.lightened(0.1))
	# Ears
	draw_colored_polygon([Vector2(-sz * 0.1, -sz * 0.25 + bob), Vector2(-sz * 0.2, -sz * 0.5 + bob), Vector2(0, -sz * 0.2 + bob)], col.lightened(0.05))
	draw_colored_polygon([Vector2(sz * 0.1, -sz * 0.25 + bob), Vector2(sz * 0.2, -sz * 0.5 + bob), Vector2(0, -sz * 0.2 + bob)], col.lightened(0.05))

func _draw_slime(sz: float, col: Color, eye_col: Color, bob: float) -> void:
	# Squish animation
	var squish := 1.0 + sin(_anim_time * 4.0) * 0.1
	var inv_squish := 1.0 / squish
	# Body blob
	draw_ellipse_custom(Vector2(0, bob * 0.5), sz * 0.7 * squish, sz * 0.5 * inv_squish, col * Color(1, 1, 1, 0.8))
	draw_ellipse_custom(Vector2(0, -sz * 0.05 + bob * 0.5), sz * 0.55 * squish, sz * 0.4 * inv_squish, col.lightened(0.15) * Color(1, 1, 1, 0.7))
	# Highlight
	draw_circle(Vector2(-sz * 0.15, -sz * 0.15 + bob * 0.5), sz * 0.12, Color(1, 1, 1, 0.25))
	# Eyes
	draw_circle(Vector2(-sz * 0.15, -sz * 0.1 + bob * 0.5), sz * 0.09, eye_col)
	draw_circle(Vector2(sz * 0.15, -sz * 0.1 + bob * 0.5), sz * 0.09, eye_col)

func _draw_spider(sz: float, col: Color, eye_col: Color, bob: float) -> void:
	# Body
	draw_circle(Vector2(0, sz * 0.1 + bob), sz * 0.35, col)
	draw_circle(Vector2(0, -sz * 0.2 + bob), sz * 0.25, col.lightened(0.1))
	# Eyes (multiple)
	for i in range(4):
		var ex := -sz * 0.12 + i * sz * 0.08
		draw_circle(Vector2(ex, -sz * 0.25 + bob), sz * 0.04, eye_col)
	# Legs (8 total)
	var step := sin(_anim_time * 8.0)
	for side in [-1, 1]:
		for i in range(4):
			var base_angle := -0.3 + i * 0.3
			var leg_offset := step * 2.0 * (1 if i % 2 == 0 else -1)
			var start := Vector2(side * sz * 0.25, -sz * 0.1 + i * sz * 0.12 + bob)
			var mid := Vector2(side * sz * 0.7, -sz * 0.2 + i * sz * 0.15 + bob + leg_offset)
			var end := Vector2(side * sz * 0.6, sz * 0.3 + i * sz * 0.05 + bob + leg_offset * 0.5)
			draw_line(start, mid, col.lightened(0.1), 1.0)
			draw_line(mid, end, col.lightened(0.1), 1.0)

func _draw_wisp(sz: float, col: Color, eye_col: Color, bob: float) -> void:
	# Ethereal glow (outer)
	var pulse := sin(_anim_time * 3.0) * 0.15
	draw_circle(Vector2(0, bob), sz * 0.8, col * Color(1, 1, 1, 0.15 + pulse))
	draw_circle(Vector2(0, bob), sz * 0.55, col * Color(1, 1, 1, 0.3 + pulse))
	# Core
	draw_circle(Vector2(0, bob), sz * 0.35, col.lightened(0.3))
	draw_circle(Vector2(0, bob), sz * 0.2, eye_col * Color(1, 1, 1, 0.8))
	# Trailing particles
	for i in range(3):
		var ta := _anim_time * 2.0 + i * TAU / 3.0
		var tp := Vector2(cos(ta) * sz * 0.6, sin(ta) * sz * 0.3 + bob + sz * 0.3)
		draw_circle(tp, sz * 0.08, col * Color(1, 1, 1, 0.3))

func _draw_shadow(sz: float, col: Color, eye_col: Color, bob: float) -> void:
	# Dark ethereal body
	var fade := 0.6 + sin(_anim_time * 2.0) * 0.1
	# Wispy body
	draw_circle(Vector2(0, bob), sz * 0.6, col * Color(1, 1, 1, fade))
	# Hood/cloak shape
	draw_colored_polygon([
		Vector2(0, -sz * 0.8 + bob),
		Vector2(-sz * 0.5, -sz * 0.2 + bob),
		Vector2(-sz * 0.4, sz * 0.5 + bob),
		Vector2(sz * 0.4, sz * 0.5 + bob),
		Vector2(sz * 0.5, -sz * 0.2 + bob),
	], col * Color(1, 1, 1, fade * 0.8))
	# Glowing eyes
	draw_circle(Vector2(-sz * 0.12, -sz * 0.3 + bob), sz * 0.08, eye_col)
	draw_circle(Vector2(sz * 0.12, -sz * 0.3 + bob), sz * 0.08, eye_col)

func _draw_commander(sz: float, col: Color, eye_col: Color, bob: float) -> void:
	_draw_humanoid(sz, col, eye_col, bob, false)
	# Crown
	draw_colored_polygon([
		Vector2(-sz * 0.3, -sz * 0.85 + bob),
		Vector2(-sz * 0.25, -sz * 1.1 + bob),
		Vector2(-sz * 0.1, -sz * 0.9 + bob),
		Vector2(0, -sz * 1.15 + bob),
		Vector2(sz * 0.1, -sz * 0.9 + bob),
		Vector2(sz * 0.25, -sz * 1.1 + bob),
		Vector2(sz * 0.3, -sz * 0.85 + bob),
	], Color(1.0, 0.85, 0.0))

func _draw_shapeshifter(sz: float, col: Color, eye_col: Color, bob: float) -> void:
	# Morphing body
	var morph := _anim_time * 1.5
	var points := PackedVector2Array()
	for i in range(8):
		var a := TAU * i / 8.0
		var r := sz * 0.5 + sin(morph + i * 1.3) * sz * 0.15
		points.append(Vector2(cos(a) * r, sin(a) * r + bob))
	draw_colored_polygon(points, col * Color(1, 1, 1, 0.7))
	# Core
	draw_circle(Vector2(0, bob), sz * 0.25, col.lightened(0.2))
	# Eyes (shifting position)
	var ex := sin(morph * 0.7) * sz * 0.1
	draw_circle(Vector2(ex - sz * 0.08, -sz * 0.1 + bob), sz * 0.06, eye_col)
	draw_circle(Vector2(ex + sz * 0.08, -sz * 0.1 + bob), sz * 0.06, eye_col)

func _draw_golem(sz: float, col: Color, eye_col: Color, bob: float) -> void:
	# Blocky body
	draw_rect(Rect2(-sz * 0.45, -sz * 0.3 + bob, sz * 0.9, sz * 0.8), col)
	# Head
	draw_rect(Rect2(-sz * 0.3, -sz * 0.7 + bob, sz * 0.6, sz * 0.45), col.lightened(0.1))
	# Eyes
	draw_circle(Vector2(-sz * 0.1, -sz * 0.5 + bob), sz * 0.08, eye_col)
	draw_circle(Vector2(sz * 0.1, -sz * 0.5 + bob), sz * 0.08, eye_col)
	# Cracks
	draw_line(Vector2(-sz * 0.2, -sz * 0.1 + bob), Vector2(-sz * 0.05, sz * 0.2 + bob), col.darkened(0.3), 1.0)
	draw_line(Vector2(sz * 0.15, 0 + bob), Vector2(sz * 0.3, sz * 0.3 + bob), col.darkened(0.3), 1.0)
	# Arms
	var step := sin(_anim_time * 4.0) * 1.5
	draw_rect(Rect2(-sz * 0.7, -sz * 0.2 + bob + step, sz * 0.25, sz * 0.5), col.darkened(0.1))
	draw_rect(Rect2(sz * 0.45, -sz * 0.2 + bob - step, sz * 0.25, sz * 0.5), col.darkened(0.1))

func _draw_boss_sprite(sz: float, col: Color, eye_col: Color, bob: float) -> void:
	# Aura ring
	var pulse := sin(_anim_time * 2.0) * 2.0
	draw_arc(Vector2(0, bob), sz + 4 + pulse, 0, TAU, 24, col * Color(1, 1, 1, 0.2), 3.0)
	# Large intimidating body
	draw_circle(Vector2(0, bob), sz * 0.9, col)
	draw_circle(Vector2(0, bob), sz * 0.7, col.lightened(0.1))
	# Head
	draw_circle(Vector2(0, -sz * 0.7 + bob), sz * 0.5, col.lightened(0.05))
	# Crown/horns
	draw_colored_polygon([
		Vector2(-sz * 0.35, -sz * 0.9 + bob),
		Vector2(-sz * 0.45, -sz * 1.3 + bob),
		Vector2(-sz * 0.15, -sz * 1.0 + bob),
		Vector2(0, -sz * 1.4 + bob),
		Vector2(sz * 0.15, -sz * 1.0 + bob),
		Vector2(sz * 0.45, -sz * 1.3 + bob),
		Vector2(sz * 0.35, -sz * 0.9 + bob),
	], Color(0.7, 0.1, 0.1))
	# Eyes (large, glowing)
	draw_circle(Vector2(-sz * 0.15, -sz * 0.75 + bob), sz * 0.12, Color(0, 0, 0))
	draw_circle(Vector2(sz * 0.15, -sz * 0.75 + bob), sz * 0.12, Color(0, 0, 0))
	draw_circle(Vector2(-sz * 0.15, -sz * 0.75 + bob), sz * 0.08, eye_col)
	draw_circle(Vector2(sz * 0.15, -sz * 0.75 + bob), sz * 0.08, eye_col)
	# Arms
	var arm_swing := sin(_anim_time * 3.0) * 3.0
	draw_line(Vector2(-sz * 0.6, -sz * 0.15 + bob), Vector2(-sz * 1.0, sz * 0.2 + bob + arm_swing), col.darkened(0.2), 4.0)
	draw_line(Vector2(sz * 0.6, -sz * 0.15 + bob), Vector2(sz * 1.0, sz * 0.2 + bob - arm_swing), col.darkened(0.2), 4.0)

func _draw_status_particles(sz: float) -> void:
	# Burn particles
	if burn_timer > 0:
		for i in range(3):
			var fa := _anim_time * 5.0 + i * 2.1
			var fy := -fmod(fa * 8.0, sz * 1.2)
			var fx := sin(fa * 1.5) * sz * 0.4
			if fy > -sz * 1.2:
				draw_circle(Vector2(fx, fy), 2.0, Color(1.0, 0.5 + randf() * 0.3, 0, 0.6))
	# Poison drip
	if poison_timer > 0:
		var drip_y := fmod(_anim_time * 15.0, sz)
		draw_circle(Vector2(sz * 0.3, drip_y), 1.5, Color(0.2, 0.8, 0.1, 0.7))
	# Ice crystals
	if ice_slow < 1.0:
		for i in range(2):
			var ia := _anim_time * 0.5 + i * PI
			var ip := Vector2(cos(ia) * sz * 0.5, sin(ia) * sz * 0.3)
			draw_circle(ip, 2.0, Color(0.6, 0.9, 1.0, 0.5))
	# Stun stars
	if stun_timer > 0:
		for i in range(3):
			var sa := _anim_time * 3.0 + i * TAU / 3.0
			var sp := Vector2(cos(sa) * sz * 0.5, -sz * 0.7 + sin(sa) * sz * 0.15)
			draw_circle(sp, 1.5, Color(1.0, 1.0, 0.3, 0.7))

func _draw_hp_bar(sz: float) -> void:
	var bar_w := sz * 1.8
	var bar_h := 3.0 if not is_boss else 4.0
	var bar_y := sz * 0.8 + 3.0
	var pct: float = clampf(hp / max_hp, 0.0, 1.0)

	# Background
	draw_rect(Rect2(-bar_w * 0.5 - 1, bar_y - 1, bar_w + 2, bar_h + 2), Color(0, 0, 0, 0.6))
	# Fill
	var hp_col: Color = lerp(Color(1, 0.1, 0.1), Color(0.1, 0.9, 0.2), pct)
	if is_boss:
		hp_col = lerp(Color(1, 0.1, 0.1), Color(1.0, 0.6, 0.0), pct)
	draw_rect(Rect2(-bar_w * 0.5, bar_y, bar_w * pct, bar_h), hp_col)
	# Highlight line
	if pct > 0.05:
		draw_line(Vector2(-bar_w * 0.5, bar_y), Vector2(-bar_w * 0.5 + bar_w * pct, bar_y), hp_col.lightened(0.3) * Color(1, 1, 1, 0.5), 1.0)

func _draw_status_icons(sz: float) -> void:
	var icons: Array = []
	if burn_timer > 0:
		icons.append(Color(1.0, 0.42, 0.12))
	if poison_timer > 0:
		icons.append(Color(0.3, 0.9, 0.22))
	if ice_slow < 1.0:
		icons.append(Color(0.62, 0.9, 1.0))
	if shield_timer > 0:
		icons.append(Color(0.38, 0.65, 1.0))
	if regen_rate > 0:
		icons.append(Color(0.55, 1.0, 0.6))
	if icons.is_empty():
		return
	var start_x := -((icons.size() - 1) * 6.0)
	var base_y := sz * 1.05 + 10.0
	for idx in range(icons.size()):
		var icon_pos := Vector2(start_x + idx * 12.0, base_y)
		draw_circle(icon_pos, 4.0, Color(0, 0, 0, 0.35))
		draw_circle(icon_pos, 3.0, icons[idx])

func draw_ellipse_custom(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var points := PackedVector2Array()
	for i in range(16):
		var a := TAU * i / 16.0
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(points, col)

func _move_along_path(dt: float) -> void:
	if waypoints.is_empty() or waypoint_idx >= waypoints.size():
		_reach_base()
		return

	var target: Vector2 = waypoints[waypoint_idx]
	var dir: Vector2 = (target - position)
	var dist: float = dir.length()
	var effective_speed: float = speed * charge_speed_mult * ice_slow * dt

	# Berserker enemy type rage: scales from 1.0x at full HP to 2.5x near death
	if enemy_type == GameData.EnemyType.BERSERKER:
		var rage := 1.0 + (1.0 - hp / max_hp) * 1.5
		effective_speed *= rage

	# Berserker wave modifier: 1.5x speed below 50% HP
	var gm_ref := _get_game_manager()
	if gm_ref and gm_ref.current_wave_modifier == GameData.WaveModifier.BERSERKER:
		if hp < max_hp * 0.5:
			effective_speed *= 1.5

	if dist < effective_speed + 1.0:
		position = target
		waypoint_idx += 1
		if waypoint_idx >= waypoints.size():
			_reach_base()
	else:
		position += dir.normalized() * effective_speed

func _fire_boss_ability() -> void:
	# Signal up to GameManager via the container's parent
	var gm := _get_game_manager()
	if gm == null:
		return
	match boss_ability:
		GameData.BossAbility.CHARGE:
			charge_speed_mult = 3.0
			charge_timer = 2.0
			gm._spawn_text(position.x, position.y - enemy_size, "💨 CHARGE!", Color(1, 0.6, 0), 1.2, 30)
		GameData.BossAbility.AOE_DAMAGE:
			var range_sq := 200.0 * 200.0
			for t in gm.tower_container.get_children():
				if position.distance_squared_to(t.position) < range_sq:
					t.fire_timer += 2.0
			if position.distance_to(gm.base_position) < 200:
				gm.base_hp -= 15.0
				gm.base_hp_changed.emit(gm.base_hp, gm.max_base_hp)
			gm._spawn_text(position.x, position.y - enemy_size, "🔥 AOE!", Color(1, 0.2, 0), 1.2, 32)
			gm._trigger_shake(0.3, 10.0)
		GameData.BossAbility.SHIELD:
			shield_timer = 5.0
			gm._spawn_text(position.x, position.y - enemy_size, "🛡️ SHIELD!", Color(0.3, 0.6, 1), 1.5, 28)
		GameData.BossAbility.ROAR:
			for e in gm.enemy_container.get_children():
				if e != self and position.distance_to(e.position) < 250 and not e.is_dead():
					e.ice_slow = 1.0
					e.charge_speed_mult = 2.0
					e.charge_timer = 3.0
			if position.distance_to(gm.base_position) < 200:
				gm.base_hp -= 15.0
				gm.base_hp_changed.emit(gm.base_hp, gm.max_base_hp)
			gm._spawn_text(position.x, position.y - enemy_size, "💨 ROAR!", Color(1, 0.4, 0), 1.2, 32)
		GameData.BossAbility.TELEPORT:
			if waypoint_idx < waypoints.size() - 2:
				waypoint_idx += 2
				position = waypoints[waypoint_idx]
			gm._spawn_text(position.x, position.y - enemy_size, "💨 TELEPORT!", Color(0.2, 0.5, 0.8), 1.0, 28)
		GameData.BossAbility.DRAIN:
			var stolen: int = mini(10 + gm.wave, gm.gold)
			if stolen > 0:
				gm.gold -= stolen
				gm.gold_changed.emit(gm.gold)
				hp = minf(hp + stolen * 2, max_hp * 1.2)
				gm._spawn_text(position.x, position.y - enemy_size, "🔮 DRAIN! -%dg" % stolen, Color(0.8, 0.2, 1.0), 1.2, 28)
		GameData.BossAbility.QUAKE:
			for t in gm.tower_container.get_children():
				t.fire_timer += 0.8
			gm._trigger_shake(1.0, 20.0)
			gm._spawn_text(position.x, position.y - enemy_size, "🌋 QUAKE!", Color(0.7, 0.5, 0.2), 1.5, 32)
		GameData.BossAbility.SPLIT:
			if not boss_has_split and hp < max_hp * 0.5:
				boss_has_split = true
				var bdata := GameData.get_boss(boss_type)
				var mt: int = bdata["minion"]
				var md := GameData.get_enemy(mt)
				var clone_hp := hp * 0.3
				hp = hp * 0.4
				for _i in range(2):
					var m = gm.enemy_scene.instantiate()
					gm.enemy_container.add_child(m)
					var offset := Vector2(randf_range(-40, 40), randf_range(-25, 25))
					m.setup(mt, position + offset, path_index, waypoints,
						md["speed"] * gm.enemy_speed_mult, clone_hp, bdata["gold"] / 4,
						damage * 0.5, md["emoji"], 0.0)
					m.waypoint_idx = waypoint_idx
					m.died.connect(gm._on_enemy_died.bind(m))
					m.reached_base.connect(gm._on_enemy_reached_base.bind(m))
				gm._spawn_text(position.x, position.y - enemy_size, "✂️ SPLIT!", Color(0.4, 0.8, 0.9), 1.2, 28)
		GameData.BossAbility.SUMMON:
			var bdata := GameData.get_boss(boss_type)
			var mt: int = bdata["minion"]
			var md := GameData.get_enemy(mt)
			for _i in range(3):
				var m = gm.enemy_scene.instantiate()
				gm.enemy_container.add_child(m)
				var offset := Vector2(randf_range(-50, 50), randf_range(-30, 30))
				m.setup(mt, position + offset, path_index, waypoints,
					md["speed"] * gm.enemy_speed_mult,
					md["hp"] * (1.0 + gm.wave * 0.15) * gm.enemy_hp_mult,
					int(md["gold"] * gm.gold_mult), md["dmg"] * gm.enemy_dmg_mult,
					md["emoji"], 0.0)
				m.waypoint_idx = waypoint_idx
				m.died.connect(gm._on_enemy_died.bind(m))
				m.reached_base.connect(gm._on_enemy_reached_base.bind(m))
			gm._spawn_text(position.x, position.y - enemy_size, "✨ SUMMON!", Color(0.5, 0.1, 0.9), 1.2, 28)

func _die() -> void:
	if _dead:
		return
	_dead = true
	# Spawn death particles
	_spawn_death_particles()
	died.emit()

func _spawn_death_particles() -> void:
	var colors := [Color(1.0, 0.3, 0.1, 0.8), Color(1.0, 0.6, 0.1, 0.6), Color(0.9, 0.9, 0.2, 0.5)]
	var count: int = 8 if is_boss else 5
	for i in range(count):
		var angle := TAU * i / count + randf_range(-0.3, 0.3)
		var speed := randf_range(60, 120) if is_boss else randf_range(40, 80)
		var p = ColorRect.new()
		p.size = Vector2(3, 3) if is_boss else Vector2(2, 2)
		p.color = colors[i % colors.size()]
		p.position = Vector2(-1.5, -1.5) if is_boss else Vector2(-1, -1)
		add_child(p)
		var tween = create_tween()
		tween.tween_property(p, "position", Vector2(cos(angle), sin(angle)) * speed * 0.3, 0.4)
		tween.parallel().tween_property(p, "modulate:a", 0.0, 0.4)
		tween.tween_callback(p.queue_free)

func _reach_base() -> void:
	if _reached:
		return
	_reached = true
	reached_base.emit()

func take_damage(dmg: float, dtype: int, _source: String) -> void:
	if _dead:
		return
	var resist := GameData.get_resistance(enemy_type, dtype)
	var actual_dmg := dmg * resist
	if shield_timer > 0:
		actual_dmg *= 0.3
	hp -= actual_dmg
	hit_flash_timer = 0.15
	# Spawn hit spark
	_spawn_hit_spark(dtype)
	if hp <= 0:
		_die()

func _spawn_hit_spark(dtype: int) -> void:
	var spark_color: Color
	match dtype:
		GameData.DamageType.FIRE: spark_color = Color(1.0, 0.4, 0.0, 0.8)
		GameData.DamageType.ICE: spark_color = Color(0.4, 0.85, 1.0, 0.8)
		GameData.DamageType.ELECTRIC: spark_color = Color(1.0, 0.9, 0.0, 0.8)
		GameData.DamageType.POISON: spark_color = Color(0.3, 0.9, 0.2, 0.8)
		GameData.DamageType.MAGIC: spark_color = Color(0.6, 0.2, 1.0, 0.8)
		GameData.DamageType.DARK: spark_color = Color(0.5, 0.1, 0.8, 0.8)
		_: spark_color = Color(1.0, 1.0, 1.0, 0.6)
	var count: int = 4 if is_boss else 3
	for i in range(count):
		var angle := TAU * i / count + randf_range(-0.4, 0.4)
		var dist := randf_range(8, 15) if is_boss else randf_range(5, 10)
		var spark = ColorRect.new()
		spark.size = Vector2(2, 2)
		spark.color = spark_color
		spark.position = Vector2(-1, -1)
		add_child(spark)
		var tween = create_tween()
		tween.tween_property(spark, "position", Vector2(cos(angle), sin(angle)) * dist, 0.25)
		tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.25)
		tween.tween_callback(spark.queue_free)

func is_dead() -> bool:
	return _dead or _reached

func _get_game_manager() -> Node:
	# Walk up: EnemyContainer -> Game (GameManager)
	var parent = get_parent()
	if parent:
		return parent.get_parent()
	return null
