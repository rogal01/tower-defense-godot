extends Node2D

const SCREEN_SIZE := Vector2(480, 854)

var paths: Array = []
var map_type: int = GameData.MapType.CLASSIC
var base_position: Vector2 = Vector2(240, 726)
var double_base_active: bool = false
var secondary_base_position: Vector2 = Vector2(336, 726)
var terrain_zones: Array = []
var fog_of_war_active: bool = false
var fog_base_reveal_radius: float = 170.0
var fog_tower_reveal_mult: float = 0.9
var night_mode_active: bool = false

var _anim_time: float = 0.0
var _decorations: Array = []
var _ambient_particles: Array = []

func _ready() -> void:
	refresh_layout()

func refresh_layout() -> void:
	_generate_decorations()
	_generate_ambient_particles()
	queue_redraw()

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()

func _draw() -> void:
	var map_data := GameData.get_map(map_type)
	_draw_background(map_data)
	_draw_terrain_zones()
	_draw_paths(map_data.get("path_color", Color(0.48, 0.36, 0.20)))
	_draw_decorations()
	_draw_base()
	_draw_spawn_markers()
	_draw_foreground_haze()
	_draw_fog_of_war()

func _generate_decorations() -> void:
	_decorations.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 9401 + map_type * 79
	for _i in range(54):
		var pos := Vector2(rng.randf_range(18.0, 462.0), rng.randf_range(90.0, 758.0))
		if _point_blocked(pos, 34.0):
			continue
		_decorations.append({
			"pos": pos,
			"type": rng.randi_range(0, 2),
			"scale": rng.randf_range(0.65, 1.35),
			"phase": rng.randf() * TAU,
		})

func _generate_ambient_particles() -> void:
	_ambient_particles.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 501 + map_type * 13
	for _i in range(28):
		_ambient_particles.append({
			"pos": Vector2(rng.randf_range(0.0, 480.0), rng.randf_range(0.0, 320.0)),
			"size": rng.randf_range(1.2, 3.0),
			"phase": rng.randf() * TAU,
			"speed": rng.randf_range(0.3, 1.2),
		})

func _point_blocked(pos: Vector2, radius: float) -> bool:
	if pos.distance_to(base_position) < 66.0:
		return true
	if double_base_active and pos.distance_to(secondary_base_position) < 66.0:
		return true
	for path in paths:
		for idx in range(path.size() - 1):
			var closest := _closest_point_on_segment(pos, path[idx], path[idx + 1])
			if pos.distance_to(closest) < radius:
				return true
	return false

func _draw_background(map_data: Dictionary) -> void:
	var base_color: Color = map_data.get("bg_color", Color(0.10, 0.18, 0.10))
	var sky_top := base_color.lightened(0.18)
	var sky_mid := base_color.lightened(0.04)
	var sky_bottom := base_color.darkened(0.22)
	if night_mode_active:
		sky_top = sky_top.darkened(0.55)
		sky_mid = sky_mid.darkened(0.60)
		sky_bottom = sky_bottom.darkened(0.62)
		base_color = base_color.darkened(0.45)
	for y in range(0, 854, 3):
		var t := float(y) / 854.0
		var mix_a := sky_top.lerp(sky_mid, minf(t * 1.3, 1.0))
		draw_rect(Rect2(0, y, 480, 3), mix_a.lerp(sky_bottom, pow(t, 1.7)))

	var glow_color := Color(0.90, 0.78, 0.42, 0.12)
	match map_type:
		GameData.MapType.SNOW:
			glow_color = Color(0.84, 0.90, 1.0, 0.18)
		GameData.MapType.DESERT:
			glow_color = Color(1.0, 0.82, 0.48, 0.16)
	if night_mode_active:
		glow_color = Color(0.72, 0.82, 1.0, 0.14)
	draw_circle(Vector2(392, 118), 84.0, glow_color)
	draw_circle(Vector2(392, 118), 52.0, glow_color * Color(1, 1, 1, 1.25))
	if night_mode_active:
		draw_circle(Vector2(388, 112), 28.0, Color(0.92, 0.96, 1.0, 0.42))
		for idx in range(32):
			var s := float(idx)
			var sx := fmod(28.0 + s * 37.0, 476.0) + 2.0
			var sy := fmod(14.0 + s * 53.0, 308.0) + 8.0
			var twinkle := 0.18 + 0.28 * (0.5 + 0.5 * sin(_anim_time * 2.0 + s))
			draw_circle(Vector2(sx, sy), 1.1 + fmod(s, 3.0) * 0.35, Color(0.84, 0.92, 1.0, twinkle))

	draw_colored_polygon([
		Vector2(0, 262),
		Vector2(72, 206),
		Vector2(138, 240),
		Vector2(214, 182),
		Vector2(288, 242),
		Vector2(354, 218),
		Vector2(430, 248),
		Vector2(480, 228),
		Vector2(480, 854),
		Vector2(0, 854),
	], base_color.darkened(0.08))

	draw_colored_polygon([
		Vector2(0, 344),
		Vector2(88, 308),
		Vector2(164, 362),
		Vector2(250, 298),
		Vector2(334, 354),
		Vector2(398, 330),
		Vector2(480, 366),
		Vector2(480, 854),
		Vector2(0, 854),
	], base_color.darkened(0.15))

	for particle in _ambient_particles:
		var alpha := 0.10 + 0.18 * (0.5 + 0.5 * sin(_anim_time * particle["speed"] + particle["phase"]))
		var color := Color(0.82, 0.92, 1.0, alpha)
		match map_type:
			GameData.MapType.DESERT:
				color = Color(1.0, 0.88, 0.60, alpha * 0.8)
		draw_circle(particle["pos"], particle["size"], color)

	match map_type:
		GameData.MapType.SNOW:
			draw_rect(Rect2(0, 662, 480, 192), Color(0.92, 0.96, 1.0, 0.10))
		GameData.MapType.DESERT:
			draw_rect(Rect2(0, 0, 480, 854), Color(0.32, 0.22, 0.08, 0.08))
	if night_mode_active:
		draw_rect(Rect2(0, 0, 480, 854), Color(0.02, 0.04, 0.10, 0.28))

func _draw_terrain_zones() -> void:
	for zone in terrain_zones:
		var center: Vector2 = zone.get("pos", Vector2.ZERO)
		var radius: float = zone.get("radius", 40.0)
		match zone.get("kind", ""):
			"frost":
				draw_circle(center, radius, Color(0.70, 0.88, 1.0, 0.12))
				draw_arc(center, radius + 4.0, 0.0, TAU, 28, Color(0.82, 0.96, 1.0, 0.26), 2.0)
				draw_circle(center, 5.0 + sin(_anim_time * 2.0) * 1.5, Color(1.0, 1.0, 1.0, 0.22))
			"lava":
				draw_circle(center, radius, Color(1.0, 0.28, 0.08, 0.12))
				for idx in range(5):
					var angle := _anim_time * 0.9 + idx * TAU / 5.0
					var start := center + Vector2(cos(angle), sin(angle)) * radius * 0.28
					var finish := center + Vector2(cos(angle + 0.3), sin(angle + 0.3)) * radius * 0.86
					draw_line(start, finish, Color(1.0, 0.56, 0.18, 0.46), 2.0)
			"arcane":
				draw_circle(center, radius, Color(0.64, 0.26, 0.98, 0.10))
				draw_arc(center, radius, _anim_time, _anim_time + TAU, 32, Color(0.82, 0.60, 1.0, 0.34), 2.0)
				draw_arc(center, radius * 0.58, -_anim_time * 1.4, TAU - _anim_time * 1.4, 24, Color(0.96, 0.82, 1.0, 0.28), 1.4)
			"dune":
				draw_circle(center, radius, Color(0.96, 0.82, 0.46, 0.08))
				for offset in [-10.0, 0.0, 10.0]:
					draw_arc(center + Vector2(0, offset), radius * 0.65, PI * 0.08, PI * 0.92, 18, Color(1.0, 0.90, 0.58, 0.24), 1.6)

func _draw_paths(path_color: Color) -> void:
	for path in paths:
		if path.size() < 2:
			continue
		for idx in range(path.size() - 1):
			draw_line(path[idx], path[idx + 1], path_color.darkened(0.42), 34.0, true)
		for idx in range(path.size() - 1):
			draw_line(path[idx], path[idx + 1], path_color.darkened(0.14), 26.0, true)
		for idx in range(path.size() - 1):
			draw_line(path[idx], path[idx + 1], path_color, 18.0, true)
		for idx in range(path.size() - 1):
			var a: Vector2 = path[idx]
			var b: Vector2 = path[idx + 1]
			var distance := a.distance_to(b)
			var direction := (b - a).normalized()
			var offset := 0.0
			while offset < distance:
				var dash_start := a + direction * offset
				var dash_end := a + direction * minf(offset + 11.0, distance)
				draw_line(dash_start, dash_end, path_color.lightened(0.22) * Color(1, 1, 1, 0.24), 1.4, true)
				offset += 20.0

func _draw_decorations() -> void:
	for deco in _decorations:
		var pos: Vector2 = deco["pos"]
		var scale: float = deco["scale"]
		match deco["type"]:
			0:
				_draw_tree(pos, scale)
			1:
				_draw_rock(pos, scale)
			_:
				_draw_shrub(pos, scale)

func _draw_tree(pos: Vector2, scale: float) -> void:
	match map_type:
		GameData.MapType.DESERT:
			draw_line(pos, pos + Vector2(0, -16 * scale), Color(0.40, 0.26, 0.12), 2.6 * scale)
			draw_line(pos + Vector2(0, -10 * scale), pos + Vector2(9 * scale, -18 * scale), Color(0.42, 0.56, 0.22), 2.4 * scale)
			draw_line(pos + Vector2(0, -8 * scale), pos + Vector2(-8 * scale, -15 * scale), Color(0.42, 0.56, 0.22), 2.2 * scale)
		_:
			draw_rect(Rect2(pos.x - 2.5 * scale, pos.y - 11.0 * scale, 5.0 * scale, 12.0 * scale), Color(0.42, 0.28, 0.12))
			var leaves := Color(0.18, 0.52, 0.24)
			if map_type == GameData.MapType.SNOW:
				leaves = Color(0.66, 0.80, 0.74)
			draw_circle(pos + Vector2(0, -15 * scale), 9.0 * scale, leaves)
			draw_circle(pos + Vector2(-6 * scale, -11 * scale), 5.0 * scale, leaves.darkened(0.06))
			draw_circle(pos + Vector2(6 * scale, -10 * scale), 5.2 * scale, leaves.lightened(0.06))

func _draw_rock(pos: Vector2, scale: float) -> void:
	var color := Color(0.42, 0.42, 0.46)
	if map_type == GameData.MapType.SNOW:
		color = Color(0.68, 0.72, 0.78)
	draw_colored_polygon([
		pos + Vector2(-8, 4) * scale,
		pos + Vector2(-5, -6) * scale,
		pos + Vector2(4, -8) * scale,
		pos + Vector2(9, -2) * scale,
		pos + Vector2(5, 5) * scale,
	], color)

func _draw_shrub(pos: Vector2, scale: float) -> void:
	var color := Color(0.20, 0.46, 0.22)
	if map_type == GameData.MapType.DESERT:
		color = Color(0.56, 0.48, 0.22)
	draw_circle(pos, 6.0 * scale, color)
	draw_circle(pos + Vector2(-4, -1) * scale, 4.2 * scale, color.lightened(0.05))
	draw_circle(pos + Vector2(4, -2) * scale, 3.8 * scale, color.darkened(0.05))

func _draw_base() -> void:
	_draw_single_base(base_position, Color(0.90, 0.24, 0.18))
	if double_base_active:
		_draw_single_base(secondary_base_position, Color(0.28, 0.62, 0.94))

func _draw_single_base(base_pos: Vector2, flag_color: Color) -> void:
	draw_circle(base_pos + Vector2(2, 3), 38.0, Color(0, 0, 0, 0.28))
	draw_circle(base_pos, 36.0, Color(0.18, 0.24, 0.34))
	draw_circle(base_pos, 28.0, Color(0.28, 0.34, 0.46))
	draw_rect(Rect2(base_pos.x - 24, base_pos.y - 20, 48, 32), Color(0.38, 0.44, 0.56))
	for idx in range(5):
		draw_rect(Rect2(base_pos.x - 22 + idx * 9.0, base_pos.y - 28, 7, 8), Color(0.46, 0.52, 0.64))
	draw_rect(Rect2(base_pos.x - 8, base_pos.y - 3, 16, 15), Color(0.40, 0.24, 0.12))
	draw_circle(base_pos + Vector2(0, -6), 8.0 + sin(_anim_time * 2.2) * 1.0, Color(0.70, 0.92, 1.0, 0.28))
	draw_circle(base_pos + Vector2(0, -6), 4.0, Color(0.94, 0.98, 1.0, 0.48))
	draw_line(base_pos + Vector2(0, -26), base_pos + Vector2(0, -46), Color(0.36, 0.28, 0.14), 2.0)
	draw_colored_polygon([
		base_pos + Vector2(0, -46),
		base_pos + Vector2(15 + sin(_anim_time * 2.6) * 2.0, -40),
		base_pos + Vector2(0, -34),
	], flag_color)

func _draw_spawn_markers() -> void:
	for path in paths:
		if path.is_empty():
			continue
		var spawn: Vector2 = path[0]
		var draw_pos := Vector2(clamp(spawn.x, 16.0, 464.0), clamp(spawn.y, 16.0, 838.0))
		var pulse := 10.0 + sin(_anim_time * 3.0 + draw_pos.x * 0.02) * 2.0
		draw_arc(draw_pos, pulse, 0.0, TAU, 18, Color(1.0, 0.42, 0.28, 0.42), 2.0)
		draw_circle(draw_pos, 4.0, Color(1.0, 0.54, 0.32, 0.62))

func _draw_foreground_haze() -> void:
	match map_type:
		GameData.MapType.SNOW:
			draw_rect(Rect2(0, 580, 480, 274), Color(0.96, 0.98, 1.0, 0.03))

func _draw_fog_of_war() -> void:
	if not fog_of_war_active:
		return
	var reveal_sources := _collect_fog_reveal_sources()
	# Smooth circular sampling keeps fog readable without visible square tiles.
	draw_rect(Rect2(0, 0, SCREEN_SIZE.x, SCREEN_SIZE.y), Color(0.02, 0.03, 0.07, 0.10))
	var cell_size := 14.0
	var circle_radius := cell_size * 0.86
	var y := 0.0
	while y < SCREEN_SIZE.y:
		var x := 0.0
		while x < SCREEN_SIZE.x:
			var center := Vector2(x + cell_size * 0.5, y + cell_size * 0.5)
			var reveal: float = _fog_reveal_strength(center, reveal_sources)
			var alpha := lerpf(0.88, 0.05, smoothstep(0.0, 1.0, reveal))
			if alpha > 0.02:
				draw_circle(center, circle_radius, Color(0.02, 0.03, 0.07, alpha))
			x += cell_size
		y += cell_size

	for source in reveal_sources:
		var src_pos: Vector2 = source.get("pos", Vector2.ZERO)
		var src_radius: float = float(source.get("radius", 0.0))
		if src_radius > 0.0:
			draw_circle(src_pos, src_radius * 0.28, Color(0.70, 0.84, 1.0, 0.05))
			draw_arc(src_pos, src_radius, 0.0, TAU, 44, Color(0.70, 0.84, 1.0, 0.10), 1.2)

func _collect_fog_reveal_sources() -> Array:
	var reveal_sources: Array = []
	reveal_sources.append({
		"pos": base_position,
		"radius": fog_base_reveal_radius,
	})
	if double_base_active:
		reveal_sources.append({
			"pos": secondary_base_position,
			"radius": fog_base_reveal_radius,
		})
	var owner := get_parent()
	if owner == null:
		return reveal_sources
	var tower_container: Node = owner.get_node_or_null("TowerContainer")
	if tower_container != null:
		for tower_node in tower_container.get_children():
			var base_range: float = float(tower_node.get("attack_range"))
			if base_range <= 0.0:
				continue
			var reveal_radius: float = maxf(base_range * fog_tower_reveal_mult, 98.0)
			reveal_sources.append({
				"pos": tower_node.position,
				"radius": reveal_radius,
			})
	var player_container: Node = owner.get_node_or_null("PlayerContainer")
	if player_container != null and player_container.get_child_count() > 0:
		var player_node := player_container.get_child(0) as Node2D
		if player_node != null:
			reveal_sources.append({
				"pos": player_node.position,
				"radius": 112.0,
			})
	var placement_active: bool = bool(owner.get("placement_active"))
	if placement_active:
		var preview_pos: Vector2 = owner.get("placement_preview_pos")
		if preview_pos.x >= 0.0:
			var preview_range: float = float(owner.get("placement_preview_range"))
			reveal_sources.append({
				"pos": preview_pos,
				"radius": maxf(preview_range * 0.85, 96.0),
			})
	return reveal_sources

func _fog_reveal_strength(point: Vector2, reveal_sources: Array) -> float:
	var reveal: float = 0.0
	for source in reveal_sources:
		var src_pos: Vector2 = source.get("pos", Vector2.ZERO)
		var src_radius: float = float(source.get("radius", 0.0))
		if src_radius <= 0.0:
			continue
		var dist: float = point.distance_to(src_pos)
		if dist > src_radius:
			continue
		var local_reveal := 1.0 - dist / src_radius
		reveal = maxf(reveal, local_reveal)
	return clampf(reveal, 0.0, 1.0)

func _closest_point_on_segment(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var segment := b - a
	var length_sq := segment.length_squared()
	if length_sq <= 0.001:
		return a
	var t := clampf((point - a).dot(segment) / length_sq, 0.0, 1.0)
	return a + segment * t
