# Projectile.gd — Projectile with trail effect
extends Node2D

var velocity: Vector2 = Vector2.ZERO
var travel_speed: float = 400.0
var target_pos: Vector2 = Vector2.ZERO
var start_pos: Vector2 = Vector2.ZERO
var color: Color = Color(0.9, 0.8, 0.3)
var style: String = "bolt"
var _done: bool = false
var _trail: Array = []  # Array of past positions for trail
var _impact_time: float = 0.0
var _impact_pos: Vector2 = Vector2.ZERO
var _showing_impact: bool = false
var _travel_distance: float = 0.0
var _travel_progress: float = 0.0
const MAX_TRAIL := 8

func launch(from: Vector2, to: Vector2, p_color: Color, p_speed: float = 400.0, p_style: String = "bolt") -> void:
	position = from
	start_pos = from
	target_pos = to
	color = p_color
	travel_speed = p_speed
	style = p_style
	var dir: Vector2 = (to - from).normalized()
	velocity = dir * p_speed
	_travel_distance = maxf(1.0, from.distance_to(to))
	_travel_progress = 0.0
	_trail.clear()
	queue_redraw()

func _process(delta: float) -> void:
	if _done:
		if _showing_impact:
			_impact_time += delta
			if _impact_time > 0.2:
				queue_free()
			queue_redraw()
		return
	# Store trail position
	_trail.append(position)
	if _trail.size() > MAX_TRAIL:
		_trail.pop_front()

	_travel_progress = minf(1.0, _travel_progress + (travel_speed * delta) / _travel_distance)
	var next_pos := start_pos.lerp(target_pos, _travel_progress)
	if style == "shell":
		next_pos.y -= sin(_travel_progress * PI) * 42.0
	elif style == "ember":
		next_pos.y -= sin(_travel_progress * PI) * 18.0
	elif style == "arc":
		next_pos += Vector2(0, sin(_travel_progress * 16.0) * 6.0)
	position = next_pos
	if _travel_progress >= 1.0 or position.distance_to(target_pos) < 4.0:
		_impact_pos = position
		_impact_time = 0.0
		_showing_impact = true
		_done = true
		queue_redraw()
	else:
		queue_redraw()

func _draw() -> void:
	# Trail
	if _trail.size() > 1:
		for i in range(_trail.size() - 1):
			var alpha: float = float(i) / _trail.size() * 0.4
			var width: float = float(i) / _trail.size() * 3.0 + 0.5
			var trail_pos: Vector2 = _trail[i] - position
			var trail_next: Vector2 = _trail[mini(i + 1, _trail.size() - 1)] - position
			draw_line(trail_pos, trail_next, color * Color(1, 1, 1, alpha), width, true)

	if _showing_impact:
		# Impact flash ring
		var t: float = _impact_time / 0.2
		var radius: float = 4.0 + t * 12.0
		var alpha: float = 1.0 - t
		draw_circle(_impact_pos - position, radius, color * Color(1, 1, 1, alpha * 0.3))
		draw_circle(_impact_pos - position, radius * 0.5, color * Color(1, 1, 1, alpha * 0.5))
		# Impact sparks
		for i in range(6):
			var angle: float = TAU * i / 6.0
			var spark_len: float = 6.0 * (1.0 - t)
			var start := (_impact_pos - position) + Vector2(cos(angle), sin(angle)) * 3.0
			var end := (_impact_pos - position) + Vector2(cos(angle), sin(angle)) * (3.0 + spark_len)
			draw_line(start, end, color * Color(1, 1, 1, alpha * 0.6), 1.5)
		return

	# Outer glow
	draw_circle(Vector2.ZERO, 7.0, color * Color(1, 1, 1, 0.15))
	match style:
		"shell":
			draw_circle(Vector2.ZERO, 5.5, color.darkened(0.25))
			draw_circle(Vector2.ZERO, 3.2, color)
		"orb":
			draw_circle(Vector2.ZERO, 4.5, color)
			draw_circle(Vector2.ZERO, 2.0, color.lightened(0.4))
			draw_arc(Vector2.ZERO, 8.0, _impact_time * 4.0, _impact_time * 4.0 + PI * 1.6, 14, color * Color(1, 1, 1, 0.35), 1.4)
		"blob":
			draw_circle(Vector2.ZERO, 4.5, color)
			draw_circle(Vector2(-1, -2), 1.2, Color(1, 1, 1, 0.28))
		"arc":
			draw_line(Vector2(-5, 0), Vector2(5, 0), color.lightened(0.25), 2.8)
			draw_circle(Vector2.ZERO, 2.0, Color(1, 1, 1, 0.5))
		"ember":
			draw_circle(Vector2.ZERO, 4.0, color)
			draw_circle(Vector2.ZERO, 1.6, Color(1.0, 0.95, 0.75, 0.7))
		_:
			draw_line(Vector2(-6, 0), Vector2(6, 0), color, 2.4)
			draw_colored_polygon([Vector2(7, 0), Vector2(1, -2.5), Vector2(1, 2.5)], color.lightened(0.18))
