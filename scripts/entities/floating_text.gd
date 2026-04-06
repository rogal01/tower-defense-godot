# FloatingText.gd — Damage/gold text that rises, scales, and fades with outline
extends Node2D

var text: String = ""
var font_size: float = 24.0
var color: Color = Color.WHITE
var duration: float = 1.0
var _elapsed: float = 0.0
var _label: Label
var _outline_label: Label
var _initial_scale: float = 0.5

func _ready() -> void:
	# Outline (shadow) label
	_outline_label = Label.new()
	_outline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outline_label.position = Vector2(1, 1)
	add_child(_outline_label)

	# Main label
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)

func setup(p_text: String, p_color: Color, p_duration: float, p_size: float) -> void:
	text = p_text
	color = p_color
	duration = p_duration
	font_size = p_size

	if _label:
		_label.text = text
		_label.add_theme_color_override("font_color", color)
		_label.add_theme_font_size_override("font_size", int(font_size))
		_label.position = Vector2(-100, -font_size * 0.5)
		_label.custom_minimum_size = Vector2(200, font_size + 4)

	if _outline_label:
		_outline_label.text = text
		_outline_label.add_theme_color_override("font_color", Color(0, 0, 0, 0.6))
		_outline_label.add_theme_font_size_override("font_size", int(font_size))
		_outline_label.position = Vector2(-99, -font_size * 0.5 + 1)
		_outline_label.custom_minimum_size = Vector2(200, font_size + 4)

	scale = Vector2(_initial_scale, _initial_scale)

func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = _elapsed / duration
	if t >= 1.0:
		queue_free()
		return

	# Rise up
	position.y -= delta * 50.0
	# Slight horizontal drift
	position.x += sin(_elapsed * 3.0) * delta * 8.0

	# Scale: pop in quickly, then settle
	var scale_t: float = minf(t * 4.0, 1.0)
	var s: float = _initial_scale + (1.0 - _initial_scale) * ease(scale_t, -2.0)
	if t > 0.7:
		s *= 1.0 - (t - 0.7) / 0.3 * 0.3
	scale = Vector2(s, s)

	# Fade out in the final 35%
	var alpha: float = 1.0 if t < 0.65 else 1.0 - (t - 0.65) / 0.35
	if _label:
		var col := color
		col.a = alpha
		_label.add_theme_color_override("font_color", col)
	if _outline_label:
		_outline_label.add_theme_color_override("font_color", Color(0, 0, 0, alpha * 0.5))

func ease(t: float, curve: float) -> float:
	if curve > 0:
		return pow(t, curve)
	else:
		return 1.0 - pow(1.0 - t, -curve)
