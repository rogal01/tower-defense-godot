extends CanvasLayer

var gm: Node = null

func _ready() -> void:
	gm = get_parent()
	visible = false
	_build_ui()

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.size = Vector2(480, 854)
	dimmer.color = Color(0.01, 0.02, 0.04, 0.78)
	add_child(dimmer)

	var panel := Panel.new()
	panel.position = Vector2(40, 202)
	panel.size = Vector2(400, 426)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.06, 0.10, 0.99), Color(0.44, 0.68, 0.90, 0.26), 28))
	add_child(panel)

	var top_glow := ColorRect.new()
	top_glow.position = Vector2(16, 14)
	top_glow.size = Vector2(368, 62)
	top_glow.color = Color(0.28, 0.62, 0.92, 0.10)
	panel.add_child(top_glow)

	var top_band := ColorRect.new()
	top_band.position = Vector2(0, 0)
	top_band.size = Vector2(400, 78)
	top_band.color = Color(0.06, 0.10, 0.18, 0.55)
	panel.add_child(top_band)

	var cap := Panel.new()
	cap.position = Vector2(24, 18)
	cap.size = Vector2(112, 24)
	cap.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.16, 0.24, 0.94), Color(0.54, 0.82, 0.96, 0.22), 12))
	panel.add_child(cap)
	var cap_label := _label(cap, "TACTICAL HOLD", Vector2(0, 4), 10, Color(0.80, 0.92, 1.0))
	cap_label.custom_minimum_size = Vector2(112, 16)
	cap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var title := _label(panel, "PAUSED", Vector2(0, 34), 32, Color(0.92, 0.98, 1.0))
	title.custom_minimum_size = Vector2(400, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var body := _label(panel, "Take a breath, review the battlefield, then jump back in with a cleaner plan.", Vector2(38, 106), 15, Color(0.74, 0.84, 0.94))
	body.custom_minimum_size = Vector2(324, 42)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var stat_band := ColorRect.new()
	stat_band.position = Vector2(30, 164)
	stat_band.size = Vector2(340, 30)
	stat_band.color = Color(0.07, 0.12, 0.18, 0.46)
	panel.add_child(stat_band)
	var stat_label := _label(panel, "Resume to continue the current wave and tower setup.", Vector2(44, 172), 11, Color(0.70, 0.84, 0.96))
	stat_label.custom_minimum_size = Vector2(312, 16)
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var resume_btn := _button(panel, "RESUME", Vector2(40, 214), Vector2(320, 54), 22, Color(0.10, 0.22, 0.18))
	resume_btn.pressed.connect(_on_resume)

	var restart_btn := _button(panel, "RESTART RUN", Vector2(40, 282), Vector2(320, 46), 18, Color(0.22, 0.12, 0.08))
	restart_btn.pressed.connect(_on_restart)

	var menu_btn := _button(panel, "MAIN MENU", Vector2(40, 340), Vector2(320, 46), 18, Color(0.08, 0.12, 0.20))
	menu_btn.pressed.connect(_on_menu)

func _on_resume() -> void:
	if gm:
		gm.toggle_pause()

func _on_restart() -> void:
	if gm and gm.has_method("clear_saved_run"):
		gm.clear_saved_run()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _label(parent: Control, text: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Control, text: String, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = size
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(color, 18))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.10), 18, Color(0.72, 0.86, 0.98, 0.38), 2))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.12), 18))
	parent.add_child(button)
	return button

func _panel_style(color: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = border
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 12
	return style

func _button_style(color: Color, radius: int, border: Color = Color(0.42, 0.58, 0.76, 0.22), border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.border_color = border
	return style
