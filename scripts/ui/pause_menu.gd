# PauseMenu.gd — Pause overlay with resume, restart, main menu options
extends CanvasLayer

var gm: Node = null

func _ready() -> void:
	gm = get_parent()
	visible = false
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(480, 854)
	var bg_color: Color = GameData.get_palette_color("background").darkened(0.2)
	bg_color.a = 0.5
	bg.color = bg_color
	add_child(bg)

	var panel := Panel.new()
	panel.position = Vector2(70, 230)
	panel.size = Vector2(340, 340)
	var style := StyleBoxFlat.new()
	var panel_color: Color = GameData.get_palette_color("ui_panel")
	panel_color.a = 0.97
	style.bg_color = panel_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 2
	style.border_width_bottom = 1
	var border_color: Color = GameData.get_palette_color("accent")
	border_color.a = 0.3
	style.border_color = border_color
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	# Top accent line
	var accent := ColorRect.new()
	accent.position = Vector2(0, 0)
	accent.size = Vector2(340, 2)
	var accent_color: Color = GameData.get_palette_color("accent")
	accent_color.a = 0.4
	accent.color = accent_color
	panel.add_child(accent)

	var title := Label.new()
	title.text = "P A U S E D"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 20)
	title.custom_minimum_size = Vector2(340, 40)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", GameData.get_palette_color("accent"))
	panel.add_child(title)

	_make_btn(panel, "RESUME",    Vector2(30, 80),  Vector2(280, 54), 22, GameData.get_palette_color("button"), _on_resume)
	_make_btn(panel, "RESTART",   Vector2(30, 148), Vector2(280, 54), 22, GameData.get_palette_color("danger"), _on_restart)
	_make_btn(panel, "MAIN MENU", Vector2(30, 216), Vector2(280, 54), 22, GameData.get_palette_color("ui_panel").darkened(0.2), _on_menu)

func _on_resume() -> void:
	if gm:
		gm.toggle_pause()

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _make_btn(parent: Control, text: String, pos: Vector2, sz: Vector2,
		font_sz: int, col: Color, callable: Callable) -> Button:
	var btn := Button.new(); btn.text = text; btn.position = pos; btn.size = sz
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_color", GameData.get_palette_color("button_text"))
	var style := StyleBoxFlat.new(); style.bg_color = col
	style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
	style.border_width_left = 1; style.border_width_right = 1
	style.border_width_top = 1; style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.4, 0.6, 0.25)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = col.lightened(0.2)
	hover.border_color = Color(0.5, 0.6, 0.9, 0.4)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed_s := style.duplicate() as StyleBoxFlat
	pressed_s.bg_color = col.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", pressed_s)
	parent.add_child(btn)
	btn.pressed.connect(callable)
	return btn
