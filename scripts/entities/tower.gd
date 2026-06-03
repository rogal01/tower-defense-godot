## Tower entity — owns its own state, draws itself, and ticks under GameManager.
##
## Lifecycle:
##   1. GameManager instantiates the scene and calls [method setup] with stats.
##   2. Every frame, [method tick] is called with the live enemy list. The tower
##      decides whether to shoot, picks a target by [member target_mode], and
##      spawns a projectile via the GameManager's container.
##   3. [method _process] only handles visual animation; gameplay-relevant timers
##      are advanced inside [method tick] so they pause cleanly with the game.
##
## Tap handling lives in [method _unhandled_input] — we deliberately use a
## generous 30 px touch radius so the small phone-screen towers stay tappable.
extends Node2D

## Emitted when the per-tower ability finishes cooling down (HUD uses this to
## flash the ability button so the player notices).
signal ability_fired()
## Emitted when the player taps this tower (GameManager opens the upgrade panel).
signal pressed()

# ─── State ────────────────────────────────────────────────────────────────────
var tower_type: int = GameData.TowerType.ARROW
var damage: float = 8.0
var attack_range: float = 200.0
var fire_rate: float = 1.2     # shots per second
var damage_type: int = GameData.DamageType.PHYSICAL
var ability_cooldown: float = 25.0
var level: int = 1
var target_mode: int = GameData.TargetMode.FIRST
var branch: int = 0
var branch_name: String = "Core"
var branching_enabled: bool = false

var fire_timer: float = 0.0    # time until next shot (seconds)
var ability_timer: float = 0.0

# Visual
var level_label: Label
var show_range: bool = false
var _anim_time: float = 0.0
var _shoot_flash: float = 0.0
var _recoil: float = 0.0
var _aim_dir: Vector2 = Vector2.UP
var synergy_stacks: int = 0
var synergy_mult: float = 1.0

# Projectile scene reference (passed from game)
var _proj_scene: PackedScene = null

const MAX_LEVEL := 10
const BRANCH_LEVEL := 5

# ─── Color palettes per tower type ────────────────────────────────────────────
const TOWER_COLORS := {
	0:  {base=Color(0.45, 0.30, 0.15), top=Color(0.55, 0.40, 0.20), accent=Color(0.3, 0.7, 0.2)},   # Arrow
	1:  {base=Color(0.30, 0.15, 0.50), top=Color(0.50, 0.20, 0.80), accent=Color(0.8, 0.5, 1.0)},   # Magic
	2:  {base=Color(0.35, 0.30, 0.25), top=Color(0.25, 0.22, 0.20), accent=Color(0.9, 0.3, 0.1)},   # Cannon
	3:  {base=Color(0.20, 0.30, 0.15), top=Color(0.15, 0.40, 0.10), accent=Color(0.3, 0.9, 0.2)},   # Poison
	4:  {base=Color(0.30, 0.30, 0.35), top=Color(0.50, 0.45, 0.20), accent=Color(1.0, 0.9, 0.2)},   # Tesla
	5:  {base=Color(0.20, 0.35, 0.50), top=Color(0.40, 0.70, 0.90), accent=Color(0.7, 0.95, 1.0)},  # Ice
	6:  {base=Color(0.40, 0.20, 0.10), top=Color(0.70, 0.30, 0.05), accent=Color(1.0, 0.6, 0.1)},   # Flame
	7:  {base=Color(0.15, 0.10, 0.20), top=Color(0.30, 0.10, 0.40), accent=Color(0.6, 0.2, 0.8)},   # Necro
	8:  {base=Color(0.40, 0.30, 0.15), top=Color(0.50, 0.35, 0.15), accent=Color(0.9, 0.7, 0.3)},   # Ballista
	9:  {base=Color(0.15, 0.15, 0.35), top=Color(0.25, 0.20, 0.55), accent=Color(0.4, 0.5, 1.0)},   # Vortex
	10: {base=Color(0.15, 0.35, 0.20), top=Color(0.20, 0.55, 0.30), accent=Color(0.3, 1.0, 0.5)},   # Healer
}

# ─── Setup ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_visuals()

func _build_visuals() -> void:
	level_label = Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 10)
	level_label.custom_minimum_size = Vector2(30, 14)
	level_label.position = Vector2(-15, 16)
	add_child(level_label)

func setup(ttype: int, tdata: Dictionary, dmg_bonus_mult: float, cd_mult: float,
		initial_target_mode: int = GameData.TargetMode.FIRST, enable_branching: bool = false) -> void:
	tower_type = ttype
	damage = tdata["dmg"] * dmg_bonus_mult
	attack_range = tdata["range"]
	fire_rate = tdata["rate"]
	damage_type = tdata["dtype"]
	ability_cooldown = tdata["cd"] * cd_mult
	level = 1
	target_mode = initial_target_mode
	branch = 0
	branch_name = "Core"
	branching_enabled = enable_branching
	synergy_stacks = 0
	synergy_mult = 1.0
	fire_timer = 1.0 / maxf(fire_rate, 0.01)
	ability_timer = ability_cooldown * 0.5

	_update_level_label()
	queue_redraw()

func _update_level_label() -> void:
	if level_label:
		if level >= MAX_LEVEL:
			level_label.text = "MAX%s" % ("A" if branch == 1 else ("C" if branch == 2 else ""))
			level_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		else:
			level_label.text = "Lv%d%s" % [level, ("A" if branch == 1 else ("C" if branch == 2 else ""))]
			level_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 0.8))

# ─── Animation tick ───────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_anim_time += delta
	if _shoot_flash > 0:
		_shoot_flash -= delta
	if _recoil > 0:
		_recoil = maxf(0.0, _recoil - delta * 4.0)
	queue_redraw()

# ─── Draw tower sprite ────────────────────────────────────────────────────────

func _draw() -> void:
	var colors: Dictionary = TOWER_COLORS.get(tower_type, TOWER_COLORS[0])
	var base_col: Color = colors.base
	var top_col: Color = colors.top
	var accent: Color = colors.accent
	if branch == 1:
		accent = accent.lightened(0.18)
	elif branch == 2:
		accent = accent.lerp(Color(0.62, 0.90, 1.0), 0.35)

	# Level glow ring
	var glow_alpha: float = 0.1 + level * 0.03 + sin(_anim_time * 1.5) * 0.03
	var glow_radius: float = 18.0 + level * 0.5
	draw_arc(Vector2.ZERO, glow_radius, 0, TAU, 32, accent * Color(1, 1, 1, glow_alpha), 2.0 + level * 0.3)

	# Synergy ring: +10% damage per nearby same-type tower (up to 3 stacks).
	if synergy_stacks > 0:
		var synergy_alpha := 0.34 + sin(_anim_time * 2.6) * 0.10
		var synergy_radius := glow_radius + 4.0
		draw_arc(Vector2.ZERO, synergy_radius, 0, TAU, 40, accent.lightened(0.25) * Color(1, 1, 1, synergy_alpha), 1.8)
		for idx in range(synergy_stacks):
			var angle := -PI * 0.5 + idx * TAU / 3.0
			var pip_pos := Vector2(cos(angle), sin(angle)) * (synergy_radius + 2.0)
			draw_circle(pip_pos, 2.0, accent.lightened(0.35) * Color(1, 1, 1, 0.84))

	# Range indicator
	if show_range:
		# Dashed range circle
		var segments := 48
		for i in range(segments):
			if i % 3 == 0:
				continue
			var a1: float = TAU * i / segments
			var a2: float = TAU * (i + 1) / segments
			draw_line(
				Vector2(cos(a1), sin(a1)) * attack_range,
				Vector2(cos(a2), sin(a2)) * attack_range,
				accent * Color(1, 1, 1, 0.25), 1.5)
		# Fill
		draw_circle(Vector2.ZERO, attack_range, accent * Color(1, 1, 1, 0.04))

	# Base platform shadow
	draw_circle(Vector2(1, 2), 15.0, Color(0, 0, 0, 0.3))

	# Base platform
	_draw_hexagon(Vector2.ZERO, 14.0, base_col)
	_draw_hexagon(Vector2.ZERO, 11.5, base_col.lightened(0.15))

	# Tower-specific top structure
	var recoil_offset := _aim_dir * (_recoil * -4.0)
	var aim_rotation := clampf(_aim_dir.x, -0.9, 0.9) * 0.14
	draw_set_transform(recoil_offset, aim_rotation, Vector2.ONE)
	match tower_type:
		GameData.TowerType.ARROW:    _draw_arrow_tower(top_col, accent)
		GameData.TowerType.MAGIC:    _draw_magic_tower(top_col, accent)
		GameData.TowerType.CANNON:   _draw_cannon_tower(top_col, accent)
		GameData.TowerType.POISON:   _draw_poison_tower(top_col, accent)
		GameData.TowerType.TESLA:    _draw_tesla_tower(top_col, accent)
		GameData.TowerType.ICE:      _draw_ice_tower(top_col, accent)
		GameData.TowerType.FLAME:    _draw_flame_tower(top_col, accent)
		GameData.TowerType.NECRO:    _draw_necro_tower(top_col, accent)
		GameData.TowerType.BALLISTA: _draw_ballista_tower(top_col, accent)
		GameData.TowerType.VORTEX:   _draw_vortex_tower(top_col, accent)
		GameData.TowerType.HEALER:   _draw_healer_tower(top_col, accent)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Shoot flash
	if _shoot_flash > 0:
		var flash_alpha: float = _shoot_flash * 3.0
		draw_circle(Vector2(0, -8), 10.0, accent * Color(1, 1, 1, flash_alpha * 0.5))
		draw_line(Vector2.ZERO, _aim_dir * 18.0, accent * Color(1, 1, 1, flash_alpha * 0.8), 2.0)

	# Level pips around base
	if level > 1:
		var pip_count: int = mini(level - 1, 9)
		for i in range(pip_count):
			var angle: float = TAU * i / pip_count - PI * 0.5
			var pip_pos := Vector2(cos(angle), sin(angle)) * 16.0
			var pip_col: Color = Color(1.0, 0.85, 0.0, 0.7) if level >= MAX_LEVEL else accent * Color(1, 1, 1, 0.6)
			draw_circle(pip_pos, 1.5, pip_col)

# ─── Tower-specific drawings ──────────────────────────────────────────────────

func _draw_arrow_tower(col: Color, accent: Color) -> void:
	# Wooden post
	draw_rect(Rect2(-3, -18, 6, 14), col)
	# Bow curve
	var bow_col := accent
	draw_arc(Vector2(0, -20), 8.0, -PI * 0.7, PI * 0.7, 12, bow_col, 2.0)
	# Bowstring
	draw_line(Vector2(0, -28), Vector2(0, -12), Color(0.8, 0.75, 0.6), 1.0)
	# Arrow nocked
	draw_line(Vector2(-6, -20), Vector2(8, -20), Color(0.6, 0.45, 0.2), 1.5)
	# Arrowhead
	draw_colored_polygon([Vector2(8, -20), Vector2(5, -22.5), Vector2(5, -17.5)], Color(0.7, 0.7, 0.7))

func _draw_magic_tower(col: Color, accent: Color) -> void:
	# Stone pillar
	draw_rect(Rect2(-4, -16, 8, 12), col.darkened(0.2))
	draw_rect(Rect2(-3, -14, 6, 8), col)
	# Crystal orb floating
	var bob := sin(_anim_time * 2.5) * 2.0
	draw_circle(Vector2(0, -22 + bob), 7.0, col.lightened(0.1))
	draw_circle(Vector2(0, -22 + bob), 5.5, accent * Color(1, 1, 1, 0.7))
	draw_circle(Vector2(-2, -24 + bob), 2.0, Color(1, 1, 1, 0.4))
	# Orbiting particles
	for i in range(3):
		var angle: float = _anim_time * 2.0 + i * TAU / 3.0
		var p := Vector2(cos(angle) * 10, sin(angle) * 5 - 22 + bob)
		draw_circle(p, 1.5, accent * Color(1, 1, 1, 0.5))

func _draw_cannon_tower(col: Color, accent: Color) -> void:
	# Stone base block
	draw_rect(Rect2(-8, -6, 16, 6), col.darkened(0.1))
	# Cannon barrel
	draw_rect(Rect2(-4, -18, 8, 14), col)
	draw_rect(Rect2(-5, -10, 10, 4), col.lightened(0.1))
	# Muzzle
	draw_circle(Vector2(0, -19), 5.0, col.darkened(0.3))
	draw_circle(Vector2(0, -19), 3.5, Color(0.1, 0.1, 0.1))
	# Red stripe
	draw_rect(Rect2(-5, -14, 10, 2), accent)

func _draw_poison_tower(col: Color, accent: Color) -> void:
	# Cauldron body
	draw_arc(Vector2(0, -8), 9.0, 0, PI, 12, col.darkened(0.2), 3.0)
	draw_circle(Vector2(0, -8), 8.0, col.darkened(0.3))
	# Liquid surface
	draw_circle(Vector2(0, -10), 6.0, accent * Color(1, 1, 1, 0.8))
	# Bubbles
	var b1 := sin(_anim_time * 3.0) * 3.0
	var b2 := cos(_anim_time * 2.5) * 2.5
	draw_circle(Vector2(-2, -12 + b1 * 0.3), 2.0, accent.lightened(0.3) * Color(1, 1, 1, 0.6))
	draw_circle(Vector2(3, -13 + b2 * 0.3), 1.5, accent.lightened(0.2) * Color(1, 1, 1, 0.5))
	# Drip
	var drip_y := fmod(_anim_time * 20.0, 10.0)
	if drip_y < 6:
		draw_circle(Vector2(5, -4 + drip_y), 1.0, accent * Color(1, 1, 1, 1.0 - drip_y / 6.0))

func _draw_tesla_tower(col: Color, accent: Color) -> void:
	# Metal post
	draw_rect(Rect2(-3, -20, 6, 16), col.darkened(0.15))
	# Coil rings
	for i in range(4):
		var y := -6 - i * 4.0
		var r := 7.0 - i * 0.5
		draw_arc(Vector2(0, y), r, 0, TAU, 16, Color(0.7, 0.5, 0.2, 0.7), 1.5)
	# Top sphere
	draw_circle(Vector2(0, -24), 4.0, col.lightened(0.2))
	draw_circle(Vector2(0, -24), 2.5, accent)
	# Lightning arcs
	var arc_angle := _anim_time * 4.0
	for i in range(2):
		var a := arc_angle + i * PI
		var end := Vector2(cos(a) * 12, sin(a) * 6 - 20)
		draw_line(Vector2(0, -24), end, accent * Color(1, 1, 1, 0.6), 1.0)

func _draw_ice_tower(col: Color, accent: Color) -> void:
	# Crystal spire
	draw_colored_polygon([Vector2(0, -28), Vector2(-7, -8), Vector2(-4, -4), Vector2(4, -4), Vector2(7, -8)], col)
	# Inner crystal
	draw_colored_polygon([Vector2(0, -26), Vector2(-4, -10), Vector2(4, -10)], accent * Color(1, 1, 1, 0.5))
	# Highlight
	draw_line(Vector2(-2, -24), Vector2(-4, -12), Color(1, 1, 1, 0.3), 1.0)
	# Snow particles
	for i in range(4):
		var sx := sin(_anim_time * 1.5 + i * 1.7) * 12.0
		var sy := fmod(_anim_time * 15.0 + i * 8.0, 30.0) - 30.0
		draw_circle(Vector2(sx, sy), 1.0, Color(1, 1, 1, maxf(0, 0.5 - abs(sy) / 30.0)))

func _draw_flame_tower(col: Color, accent: Color) -> void:
	# Brazier base
	draw_colored_polygon([Vector2(-8, -4), Vector2(-6, -12), Vector2(6, -12), Vector2(8, -4)], col)
	draw_rect(Rect2(-9, -4, 18, 3), col.darkened(0.2))
	# Fire flames (animated)
	var t := _anim_time
	var flame_colors := [Color(1.0, 0.2, 0.0, 0.9), Color(1.0, 0.5, 0.0, 0.8), Color(1.0, 0.8, 0.1, 0.6)]
	for i in range(3):
		var h := 10.0 + sin(t * 3.0 + i * 1.2) * 3.0
		var w := 5.0 - i * 1.0 + sin(t * 4.0 + i) * 1.0
		var ox := sin(t * 2.5 + i * 2.0) * 2.0
		draw_colored_polygon([
			Vector2(ox, -12),
			Vector2(ox - w, -12),
			Vector2(ox - w * 0.3, -12 - h),
			Vector2(ox + w * 0.3, -12 - h),
			Vector2(ox + w, -12),
		], flame_colors[i])

func _draw_necro_tower(col: Color, accent: Color) -> void:
	# Dark obelisk
	draw_colored_polygon([Vector2(0, -26), Vector2(-6, -6), Vector2(-5, -2), Vector2(5, -2), Vector2(6, -6)], col)
	# Skull face
	draw_circle(Vector2(0, -16), 5.0, Color(0.85, 0.80, 0.70))
	# Eye sockets
	draw_circle(Vector2(-2, -17), 1.5, Color(0.1, 0, 0.2))
	draw_circle(Vector2(2, -17), 1.5, Color(0.1, 0, 0.2))
	# Eye glow
	var glow := 0.5 + sin(_anim_time * 3.0) * 0.3
	draw_circle(Vector2(-2, -17), 1.0, accent * Color(1, 1, 1, glow))
	draw_circle(Vector2(2, -17), 1.0, accent * Color(1, 1, 1, glow))
	# Ethereal wisps
	for i in range(2):
		var a := _anim_time * 1.5 + i * PI
		var wp := Vector2(cos(a) * 10, sin(a) * 4 - 14)
		draw_circle(wp, 2.0, accent * Color(1, 1, 1, 0.25))

func _draw_ballista_tower(col: Color, accent: Color) -> void:
	# Large wooden base
	draw_rect(Rect2(-10, -6, 20, 6), col.darkened(0.15))
	# Crossbow arms
	draw_line(Vector2(-12, -12), Vector2(0, -8), col, 2.5)
	draw_line(Vector2(12, -12), Vector2(0, -8), col, 2.5)
	# Bow string
	draw_line(Vector2(-12, -12), Vector2(0, -16), accent.darkened(0.3), 1.0)
	draw_line(Vector2(12, -12), Vector2(0, -16), accent.darkened(0.3), 1.0)
	# Rail
	draw_rect(Rect2(-2, -18, 4, 14), col.lightened(0.1))
	# Bolt
	draw_line(Vector2(0, -22), Vector2(0, -10), accent, 2.0)
	draw_colored_polygon([Vector2(0, -24), Vector2(-2, -21), Vector2(2, -21)], Color(0.7, 0.7, 0.7))

func _draw_vortex_tower(col: Color, accent: Color) -> void:
	# Base pedestal
	draw_rect(Rect2(-5, -8, 10, 6), col)
	# Swirling vortex
	var bob := sin(_anim_time * 2.0) * 1.5
	for i in range(5):
		var a := _anim_time * 3.0 + i * TAU / 5.0
		var r := 3.0 + i * 1.8
		var p := Vector2(cos(a) * r, sin(a) * r * 0.5 - 18 + bob)
		var alpha_val: float = 0.7 - i * 0.12
		draw_circle(p, 2.5 - i * 0.3, accent * Color(1, 1, 1, alpha_val))
	# Center glow
	draw_circle(Vector2(0, -18 + bob), 4.0, accent * Color(1, 1, 1, 0.3))
	draw_circle(Vector2(0, -18 + bob), 2.0, Color(1, 1, 1, 0.4))

func _draw_healer_tower(col: Color, accent: Color) -> void:
	# White stone pedestal
	draw_rect(Rect2(-5, -8, 10, 6), Color(0.8, 0.8, 0.8))
	# Healing crystal
	var bob := sin(_anim_time * 2.0) * 1.5
	draw_colored_polygon([
		Vector2(0, -26 + bob),
		Vector2(-5, -16 + bob),
		Vector2(0, -12 + bob),
		Vector2(5, -16 + bob),
	], accent * Color(1, 1, 1, 0.7))
	draw_colored_polygon([
		Vector2(0, -25 + bob),
		Vector2(-3, -17 + bob),
		Vector2(0, -14 + bob),
		Vector2(3, -17 + bob),
	], accent.lightened(0.3) * Color(1, 1, 1, 0.5))
	# Cross symbol
	draw_rect(Rect2(-1, -22 + bob, 2, 8), Color(1, 1, 1, 0.6))
	draw_rect(Rect2(-3, -19 + bob, 6, 2), Color(1, 1, 1, 0.6))
	# Healing particles
	for i in range(3):
		var a := _anim_time * 1.2 + i * TAU / 3.0
		var r := 8.0 + sin(_anim_time + i) * 2.0
		var hp := Vector2(cos(a) * r, sin(a) * r * 0.4 - 18 + bob)
		draw_circle(hp, 1.5, accent * Color(1, 1, 1, 0.4))

func _draw_hexagon(center: Vector2, radius: float, col: Color) -> void:
	var points: PackedVector2Array = []
	for i in range(6):
		var angle := TAU * i / 6.0 - PI / 6.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, col)

# ─── Tick (called by GameManager) ────────────────────────────────────────────

func tick(dt: float, enemies: Array, _freeze_mult: float, target_mode: int, range_mult: float,
		_dmg_bonus_mult: float, gm: Node) -> void:
	var effective_range: float = attack_range * range_mult

	# Fire cooldown countdown (unaffected by freeze)
	if fire_rate > 0 and fire_timer > 0:
		fire_timer -= dt

	# Ability cooldown
	if ability_timer > 0:
		ability_timer -= dt
		if ability_timer <= 0:
			ability_fired.emit()

	# Ice tower: constant slow aura (no projectile)
	if tower_type == GameData.TowerType.ICE:
		for e in enemies:
			if position.distance_to(e.position) <= effective_range and not e.is_dead():
				var slow: float = maxf(0.05, 0.5 - (level - 1) * 0.03)
				if e.ice_slow > slow:
					e.ice_slow = slow
					e.ice_slow_timer = 0.3
		return

	# Healer: no normal attack
	if tower_type == GameData.TowerType.HEALER:
		return

	# Find target and shoot
	if fire_timer <= 0 and fire_rate > 0:
		var target := _pick_target(enemies, target_mode, effective_range)
		if target:
			_fire_at(target, gm)
			fire_timer = 1.0 / maxf(fire_rate, 0.01)

func _pick_target(enemies: Array, mode: int, range_limit: float) -> Node:
	var in_range: Array = []
	for e in enemies:
		if not e.is_dead() and position.distance_to(e.position) <= range_limit:
			in_range.append(e)

	if in_range.is_empty():
		return null

	match mode:
		GameData.TargetMode.CLOSE:
			in_range.sort_custom(func(a, b): return position.distance_to(a.position) < position.distance_to(b.position))
		GameData.TargetMode.FIRST:
			# Furthest along path (highest waypoint_idx)
			in_range.sort_custom(func(a, b): return a.waypoint_idx > b.waypoint_idx)
		GameData.TargetMode.LAST:
			in_range.sort_custom(func(a, b): return a.waypoint_idx < b.waypoint_idx)
		GameData.TargetMode.STRONG:
			in_range.sort_custom(func(a, b): return a.hp > b.hp)

	return in_range[0] if not in_range.is_empty() else null

func _fire_at(target: Node, gm: Node) -> void:
	if not gm:
		return
	var shot_damage := damage * synergy_mult
	_aim_dir = (target.position - position).normalized()
	_shoot_flash = 0.15
	_recoil = 1.0
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_shot(tower_type)

	# Chain-shot for Tesla
	if tower_type == GameData.TowerType.TESLA:
		var targets: Array = []
		var all: Array = gm.enemy_container.get_children()
		for e in all:
			if not e.is_dead() and position.distance_to(e.position) <= attack_range:
				targets.append(e)
		targets.sort_custom(func(a, b): return position.distance_to(a.position) < position.distance_to(b.position))
		var chain_dmg := shot_damage
		for e in targets.slice(0, 3):
			e.take_damage(chain_dmg, damage_type, "tower_%d" % tower_type)
			_spawn_projectile_toward(e.position, gm)
			chain_dmg *= 0.7
		return

	# Splash for Cannon and Vortex
	if tower_type == GameData.TowerType.CANNON:
		var splash_range := 80.0
		for e in gm.enemy_container.get_children():
			if not e.is_dead() and target.position.distance_to(e.position) <= splash_range:
				var splash_dmg := shot_damage * (0.6 if e != target else 1.0)
				e.take_damage(splash_dmg, damage_type, "tower_%d" % tower_type)
		_spawn_projectile_toward(target.position, gm)
		return

	# Flame: apply burn
	if tower_type == GameData.TowerType.FLAME:
		target.take_damage(shot_damage, damage_type, "tower_%d" % tower_type)
		target.burn_timer = maxf(target.burn_timer, 3.0)
		target.burn_dps = shot_damage * 0.3
		_spawn_projectile_toward(target.position, gm)
		return

	# Poison: apply DoT
	if tower_type == GameData.TowerType.POISON:
		target.take_damage(shot_damage, damage_type, "tower_%d" % tower_type)
		target.poison_timer = maxf(target.poison_timer, 4.0)
		target.poison_dps = shot_damage * 0.4
		_spawn_projectile_toward(target.position, gm)
		return

	# Default: single target
	var resist := GameData.get_resistance(target.enemy_type, damage_type)
	var actual_dmg := shot_damage * resist
	var is_crit: bool = randf() < gm.crit_chance
	if is_crit:
		actual_dmg *= 2.0
	target.take_damage(actual_dmg, damage_type, "tower_%d" % tower_type)
	gm._spawn_text(target.position.x, target.position.y - 20,
		("%.0f!" if is_crit else "%.0f") % actual_dmg,
		Color(1.0, 0.9, 0.0) if is_crit else Color(0.9, 0.9, 0.9), 0.8, 20 if not is_crit else 26)
	_spawn_projectile_toward(target.position, gm)

func _spawn_projectile_toward(target_pos: Vector2, gm: Node) -> void:
	if not gm.projectile_scene:
		return
	var p = gm.projectile_scene.instantiate()
	gm.projectile_container.add_child(p)
	var color := _get_projectile_color()
	p.launch(position, target_pos, color, _get_projectile_speed(), _get_projectile_style())

func _get_projectile_color() -> Color:
	match tower_type:
		GameData.TowerType.MAGIC:    return Color(0.6, 0.2, 1.0)
		GameData.TowerType.CANNON:   return Color(0.6, 0.3, 0.0)
		GameData.TowerType.POISON:   return Color(0.2, 0.9, 0.2)
		GameData.TowerType.TESLA:    return Color(1.0, 0.9, 0.0)
		GameData.TowerType.ICE:      return Color(0.4, 0.85, 1.0)
		GameData.TowerType.FLAME:    return Color(1.0, 0.4, 0.0)
		GameData.TowerType.NECRO:    return Color(0.4, 0.0, 0.7)
		GameData.TowerType.BALLISTA: return Color(0.8, 0.6, 0.2)
		GameData.TowerType.VORTEX:   return Color(0.3, 0.4, 0.9)
		GameData.TowerType.HEALER:   return Color(0.1, 0.9, 0.4)
		_:                           return Color(0.9, 0.8, 0.3)

func _get_projectile_speed() -> float:
	match tower_type:
		GameData.TowerType.BALLISTA: return 620.0
		GameData.TowerType.CANNON: return 320.0
		GameData.TowerType.TESLA: return 760.0
		GameData.TowerType.FLAME: return 360.0
		GameData.TowerType.VORTEX: return 300.0
		_: return 460.0

func _get_projectile_style() -> String:
	match tower_type:
		GameData.TowerType.CANNON: return "shell"
		GameData.TowerType.TESLA: return "arc"
		GameData.TowerType.BALLISTA: return "bolt"
		GameData.TowerType.FLAME: return "ember"
		GameData.TowerType.POISON: return "blob"
		GameData.TowerType.VORTEX: return "orb"
		GameData.TowerType.MAGIC: return "orb"
		_: return "bolt"

# ─── Upgrade ──────────────────────────────────────────────────────────────────

func upgrade(dmg_mult: float, cd_mult: float, enable_branching: bool = false) -> void:
	if level >= MAX_LEVEL:
		return
	level += 1
	damage *= 1.12 * maxf(dmg_mult, 1.0)
	attack_range *= 1.04
	fire_rate *= 1.06
	ability_cooldown = maxf(ability_cooldown * 0.95 * cd_mult, 3.0)
	if branch == 0 and level >= BRANCH_LEVEL and (enable_branching or branching_enabled):
		_apply_branch_bonus()
	fire_timer = 0.0
	_update_level_label()
	queue_redraw()

func _apply_branch_bonus() -> void:
	var utility_towers := [
		GameData.TowerType.ICE,
		GameData.TowerType.HEALER,
		GameData.TowerType.VORTEX,
		GameData.TowerType.POISON,
		GameData.TowerType.TESLA,
	]
	if tower_type in utility_towers:
		branch = 2
		branch_name = "Control"
		damage *= 1.10
		attack_range *= 1.18
		fire_rate *= 1.16
		ability_cooldown = maxf(ability_cooldown * 0.82, 2.5)
	else:
		branch = 1
		branch_name = "Assault"
		damage *= 1.27
		attack_range *= 1.08
		fire_rate *= 1.05

# ─── Input ────────────────────────────────────────────────────────────────────

## Picks up taps anywhere in the viewport and emits [signal pressed] if the tap
## landed within 30 px of this tower. We listen via `_unhandled_input` (rather
## than an Area2D) because the playfield is dense — adding per-tower input areas
## was creating overlap headaches with the path tiles and projectile spawners.
func _unhandled_input(event: InputEvent) -> void:
	var is_tap := event is InputEventScreenTouch \
		or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)
	if not is_tap or not event.pressed:
		return
	if position.distance_to(event.position) <= 30:
		pressed.emit()

func set_show_range(visible_val: bool) -> void:
	show_range = visible_val
	queue_redraw()

func set_synergy_stacks(stacks: int) -> void:
	var clamped := clampi(stacks, 0, 3)
	if clamped == synergy_stacks:
		return
	synergy_stacks = clamped
	synergy_mult = 1.0 + float(synergy_stacks) * 0.10
	queue_redraw()
