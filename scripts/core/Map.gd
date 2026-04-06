extends Node2D

const SCREEN_SIZE := Vector2(480, 854)

var paths: Array = []
var map_type: int = GameData.MapType.CLASSIC
var base_position: Vector2 = Vector2(240, 726)
var terrain_zones: Array = []

var _anim_time: float = 0.0
var _decorations: Array = []
var _build_points: Array = []
var _stars: Array = []

func _ready() -> void:
	refresh_layout()

func refresh_layout() -> void:
	_generate_decorations()
	_generate_build_points()
	_generate_sky_particles()
	queue_redraw()

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()

func _draw() -> void:
	var map_data := GameData.get_map(map_type)
	_draw_background(map_data["bg_color"])
	_draw_terrain_zones()
	_draw_paths(map_data["path_color"])
	_draw_decorations()
	_draw_build_points()
	_draw_base()
	_draw_spawn_markers()

func _generate_decorations() -> void:
	_decorations.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 9000 + map_type * 31
	for _i in range(48):
		var pos := Vector2(rng.randf_range(18.0, 462.0), rng.randf_range(88.0, 740.0))
		if _point_blocked(pos, 32.0):
			continue
		_decorations.append({
			"pos": pos,
			"type": rng.randi_range(0, 2),
			"scale": rng.randf_range(0.7, 1.3),
			"phase": rng.randf() * TAU
		})

func _generate_build_points() -> void:
	_build_points.clear()
	for x in range(40, 441, 40):
		for y in range(120, 721, 40):
			var pos := Vector2(x, y)
			if not _point_blocked(pos, 48.0):
				_build_points.append(pos)

func _generate_sky_particles() -> void:
	_stars.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 400 + map_type * 17
	for _i in range(22):
		_stars.append({
			"pos": Vector2(rng.randf_range(0.0, 480.0), rng.randf_range(0.0, 180.0)),
			"size": rng.randf_range(1.0, 2.6),
			"phase": rng.randf() * TAU,
			"speed": rng.randf_range(0.3, 1.2)
		})

func _point_blocked(pos: Vector2, radius: float) -> bool:
	if pos.distance_to(base_position) < 64.0:
		return true
	for path in paths:
		for idx in range(path.size() - 1):
			var closest := _closest_point_on_segment(pos, path[idx], path[idx + 1])
			if pos.distance_to(closest) < radius:
				return true
	return false

func _draw_background(base_color: Color) -> void:
	var top_color := base_color.lightened(0.18)
	var bottom_color := base_color.darkened(0.18)
	for y in range(0, 854, 4):
		var t := float(y) / 854.0
		draw_rect(Rect2(0, y, 480, 4), top_color.lerp(bottom_color, t))

	var horizon := 250.0
	draw_colored_polygon([
		Vector2(0, horizon + 32),
		Vector2(64, horizon - 16),
		Vector2(148, horizon + 20),
		Vector2(244, horizon - 34),
		Vector2(340, horizon + 26),
		Vector2(430, horizon - 10),
		Vector2(480, horizon + 24),
		Vector2(480, 854),
		Vector2(0, 854),
	], base_color.darkened(0.08))

	draw_colored_polygon([
		Vector2(0, horizon + 96),
		Vector2(80, horizon + 54),
		Vector2(176, horizon + 90),
		Vector2(272, horizon + 38),
		Vector2(382, horizon + 88),
		Vector2(480, horizon + 64),
		Vector2(480, 854),
		Vector2(0, 854),
	], base_color.darkened(0.15))

	match map_type:
		GameData.MapType.SNOW:
			draw_rect(Rect2(0, 690, 480, 164), Color(0.88, 0.92, 0.96, 0.12))
		GameData.MapType.LAVA, GameData.MapType.VOLCANO:
			draw_rect(Rect2(0, 0, 480, 854), Color(0.18, 0.04, 0.0, 0.12))
		GameData.MapType.ENCHANTED:
			for star in _stars:
				var glow := 0.25 + 0.25 * (0.5 + 0.5 * sin(_anim_time * star["speed"] + star["phase"]))
				draw_circle(star["pos"], star["size"], Color(0.75, 0.55, 1.0, glow))
		_:
			for star in _stars:
				var glow := 0.12 + 0.12 * (0.5 + 0.5 * sin(_anim_time * star["speed"] + star["phase"]))
				draw_circle(star["pos"], star["size"], Color(1, 1, 1, glow))

func _draw_terrain_zones() -> void:
	for zone in terrain_zones:
		var center: Vector2 = zone.get("pos", Vector2.ZERO)
		var radius: float = zone.get("radius", 40.0)
		match zone.get("kind", ""):
			"frost":
				draw_circle(center, radius, Color(0.72, 0.9, 1.0, 0.12))
				draw_arc(center, radius + 3.0, 0.0, TAU, 28, Color(0.8, 0.95, 1.0, 0.28), 2.0)
			"lava":
				draw_circle(center, radius, Color(1.0, 0.3, 0.08, 0.12))
				for idx in range(4):
					var angle := _anim_time * 0.8 + idx * TAU / 4.0
					var p1 := center + Vector2(cos(angle), sin(angle)) * radius * 0.4
					var p2 := center + Vector2(cos(angle + 0.5), sin(angle + 0.5)) * radius * 0.85
					draw_line(p1, p2, Color(1.0, 0.54, 0.18, 0.5), 2.0)
			"arcane":
				draw_circle(center, radius, Color(0.6, 0.28, 0.95, 0.1))
				draw_arc(center, radius, _anim_time, _anim_time + TAU, 30, Color(0.72, 0.5, 1.0, 0.38), 2.0)
				draw_circle(center, 5.0 + sin(_anim_time * 3.0) * 2.0, Color(0.9, 0.75, 1.0, 0.32))
			"dune":
				draw_circle(center, radius, Color(0.95, 0.78, 0.4, 0.08))
				for offset in [-10.0, 0.0, 10.0]:
					draw_arc(center + Vector2(0, offset), radius * 0.6, PI * 0.1, PI * 0.9, 18, Color(1.0, 0.88, 0.55, 0.22), 1.5)

func _draw_paths(path_color: Color) -> void:
	for path in paths:
		if path.size() < 2:
			continue
		for idx in range(path.size() - 1):
			draw_line(path[idx], path[idx + 1], path_color.darkened(0.38), 30.0, true)
		for idx in range(path.size() - 1):
			draw_line(path[idx], path[idx + 1], path_color.darkened(0.08), 22.0, true)
		for idx in range(path.size() - 1):
			draw_line(path[idx], path[idx + 1], path_color, 16.0, true)
		for idx in range(path.size() - 1):
			var a: Vector2 = path[idx]
			var b: Vector2 = path[idx + 1]
			var distance := a.distance_to(b)
			var direction := (b - a).normalized()
			var offset := 0.0
			while offset < distance:
				var dash_start := a + direction * offset
				var dash_end := a + direction * minf(offset + 10.0, distance)
				draw_line(dash_start, dash_end, path_color.lightened(0.18) * Color(1, 1, 1, 0.24), 1.2, true)
				offset += 18.0

func _draw_decorations() -> void:
	for deco in _decorations:
		var pos: Vector2 = deco["pos"]
		var scale: float = deco["scale"]
		match deco["type"]:
			0:
				_draw_tree(pos, scale)
			1:
				_draw_stone(pos, scale)
			_:
				_draw_shrub(pos, scale)

func _draw_tree(pos: Vector2, scale: float) -> void:
	match map_type:
		GameData.MapType.DESERT:
			draw_rect(Rect2(pos.x - 3.0 * scale, pos.y - 14.0 * scale, 6.0 * scale, 16.0 * scale), Color(0.24, 0.5, 0.18))
			draw_line(pos + Vector2(0, -8 * scale), pos + Vector2(10 * scale, -12 * scale), Color(0.24, 0.5, 0.18), 3.0 * scale)
		GameData.MapType.LAVA, GameData.MapType.VOLCANO:
			draw_line(pos, pos + Vector2(0, -18 * scale), Color(0.22, 0.12, 0.08), 2.5 * scale)
			draw_line(pos + Vector2(0, -10 * scale), pos + Vector2(7 * scale, -18 * scale), Color(0.22, 0.12, 0.08), 1.5 * scale)
			draw_line(pos + Vector2(0, -12 * scale), pos + Vector2(-6 * scale, -20 * scale), Color(0.22, 0.12, 0.08), 1.5 * scale)
		_:
			draw_rect(Rect2(pos.x - 2.5 * scale, pos.y - 10.0 * scale, 5.0 * scale, 12.0 * scale), Color(0.42, 0.28, 0.12))
			var leaves := Color(0.18, 0.5, 0.22)
			if map_type == GameData.MapType.SNOW:
				leaves = Color(0.62, 0.78, 0.7)
			elif map_type == GameData.MapType.ENCHANTED:
				leaves = Color(0.42, 0.28, 0.62)
			draw_circle(pos + Vector2(0, -14 * scale), 9.0 * scale, leaves)
			draw_circle(pos + Vector2(-6 * scale, -10 * scale), 5.0 * scale, leaves.darkened(0.08))
			draw_circle(pos + Vector2(6 * scale, -10 * scale), 5.0 * scale, leaves.lightened(0.08))

func _draw_stone(pos: Vector2, scale: float) -> void:
	var color := Color(0.42, 0.42, 0.45)
	if map_type == GameData.MapType.SNOW:
		color = Color(0.6, 0.62, 0.68)
	elif map_type == GameData.MapType.LAVA or map_type == GameData.MapType.VOLCANO:
		color = Color(0.34, 0.18, 0.12)
	draw_colored_polygon([
		pos + Vector2(-7, 3) * scale,
		pos + Vector2(-5, -5) * scale,
		pos + Vector2(3, -8) * scale,
		pos + Vector2(8, -2) * scale,
		pos + Vector2(5, 4) * scale,
	], color)

func _draw_shrub(pos: Vector2, scale: float) -> void:
	var color := Color(0.2, 0.46, 0.2)
	if map_type == GameData.MapType.ENCHANTED:
		color = Color(0.36, 0.24, 0.52)
	elif map_type == GameData.MapType.DESERT:
		color = Color(0.54, 0.46, 0.2)
	draw_circle(pos, 6.0 * scale, color)
	draw_circle(pos + Vector2(-4, -2) * scale, 4.0 * scale, color.lightened(0.06))
	draw_circle(pos + Vector2(4, -1) * scale, 3.6 * scale, color.darkened(0.06))

func _draw_build_points() -> void:
	for build_pos in _build_points:
		var pulse := 0.10 + 0.05 * (0.5 + 0.5 * sin(_anim_time * 2.0 + build_pos.x * 0.02 + build_pos.y * 0.03))
		var color := Color(0.55, 0.76, 1.0, pulse)
		draw_colored_polygon([
			build_pos + Vector2(0, -9),
			build_pos + Vector2(9, 0),
			build_pos + Vector2(0, 9),
			build_pos + Vector2(-9, 0),
		], color)
		draw_arc(build_pos, 11.0, 0.0, TAU, 16, Color(0.7, 0.86, 1.0, pulse * 1.4), 1.0)

func _draw_base() -> void:
	draw_circle(base_position + Vector2(2, 3), 34.0, Color(0, 0, 0, 0.25))
	draw_circle(base_position, 32.0, Color(0.24, 0.26, 0.38))
	draw_rect(Rect2(base_position.x - 21, base_position.y - 18, 42, 30), Color(0.34, 0.36, 0.5))
	for idx in range(5):
		draw_rect(Rect2(base_position.x - 20 + idx * 8.0, base_position.y - 24, 6, 7), Color(0.42, 0.44, 0.56))
	draw_rect(Rect2(base_position.x - 7, base_position.y - 3, 14, 15), Color(0.42, 0.24, 0.12))
	draw_line(base_position + Vector2(0, -24), base_position + Vector2(0, -42), Color(0.36, 0.28, 0.14), 2.0)
	draw_colored_polygon([
		base_position + Vector2(0, -42),
		base_position + Vector2(14 + sin(_anim_time * 3.0) * 2.0, -37),
		base_position + Vector2(0, -33),
	], Color(0.86, 0.22, 0.16))

func _draw_spawn_markers() -> void:
	for path in paths:
		if path.is_empty():
			continue
		var spawn: Vector2 = path[0]
		var draw_pos := Vector2(clamp(spawn.x, 16.0, 464.0), clamp(spawn.y, 16.0, 838.0))
		var pulse := 10.0 + sin(_anim_time * 3.0 + draw_pos.x * 0.02) * 2.0
		draw_arc(draw_pos, pulse, 0.0, TAU, 18, Color(1.0, 0.38, 0.24, 0.45), 2.0)
		draw_circle(draw_pos, 4.0, Color(1.0, 0.48, 0.3, 0.65))

func _closest_point_on_segment(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var segment := b - a
	var length_sq := segment.length_squared()
	if length_sq <= 0.001:
		return a
	var t := clampf((point - a).dot(segment) / length_sq, 0.0, 1.0)
	return a + segment * t
