extends CanvasLayer

var gm: Node = null
var _next_level_id: int = -1

var _lbl_title: Label
var _lbl_score: Label
var _lbl_wave: Label
var _lbl_high: Label
var _lbl_progress: Label
var _btn_next: Button

func _ready() -> void:
	gm = get_parent()
	visible = false
	_build_ui()
	if gm:
		gm.game_over_triggered.connect(_show_game_over)
		gm.campaign_won_triggered.connect(_show_victory)

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.size = Vector2(480, 854)
	dimmer.color = Color(0, 0, 0, 0.56)
	add_child(dimmer)

	var panel := Panel.new()
	panel.position = Vector2(30, 162)
	panel.size = Vector2(420, 496)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.04, 0.12, 0.97)))
	add_child(panel)

	_lbl_title = _label(panel, "GAME OVER", Vector2(20, 18), 30, Color(1.0, 0.3, 0.3))
	_lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_title.custom_minimum_size = Vector2(380, 46)

	_lbl_wave = _label(panel, "Wave 0", Vector2(20, 78), 22, Color(0.7, 0.85, 1.0))
	_lbl_wave.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_wave.custom_minimum_size = Vector2(380, 32)

	_lbl_score = _label(panel, "Score 0", Vector2(20, 118), 26, Color(1.0, 0.85, 0.2))
	_lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_score.custom_minimum_size = Vector2(380, 36)

	_lbl_high = _label(panel, "", Vector2(20, 166), 16, Color(0.75, 0.95, 0.8))
	_lbl_high.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_high.custom_minimum_size = Vector2(380, 26)

	var stats := _label(panel, "", Vector2(20, 208), 14, Color(0.62, 0.7, 0.84))
	stats.name = "Stats"
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.custom_minimum_size = Vector2(380, 54)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_lbl_progress = _label(panel, "", Vector2(20, 268), 14, Color(0.86, 0.9, 1.0))
	_lbl_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_progress.custom_minimum_size = Vector2(380, 38)
	_lbl_progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var btn_restart := _button(panel, "PLAY AGAIN", Vector2(30, 320), Vector2(360, 52), 22, Color(0.04, 0.26, 0.08))
	btn_restart.pressed.connect(_on_restart)

	_btn_next = _button(panel, "NEXT LEVEL", Vector2(30, 384), Vector2(360, 42), 18, Color(0.20, 0.16, 0.04))
	_btn_next.visible = false
	_btn_next.pressed.connect(_on_next_level)

	var btn_menu := _button(panel, "MAIN MENU", Vector2(30, 436), Vector2(360, 42), 18, Color(0.06, 0.08, 0.18))
	btn_menu.pressed.connect(_on_menu)

func _show_game_over(score: int, wave: int, is_high_score: bool) -> void:
	visible = true
	_next_level_id = -1
	_btn_next.visible = false

	var endless_mode := gm and bool(gm.get("is_endless"))
	var difficulty_name := "Normal"
	if gm:
		match int(gm.get("difficulty")):
			0:
				difficulty_name = "Easy"
			1:
				difficulty_name = "Normal"
			2:
				difficulty_name = "Hard"

	_lbl_title.text = "GAME OVER"
	_lbl_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_lbl_score.text = "Score: %d" % score
	if endless_mode:
		_lbl_wave.text = "Endless %s - Wave %d" % [difficulty_name, wave]
		_lbl_high.text = "Endless Record: %d" % SaveManager.get_endless_record()
	else:
		_lbl_wave.text = "Reached Wave %d" % wave
		_lbl_high.text = "NEW HIGH SCORE!" if is_high_score else "High Score: %d" % SaveManager.get_high_score()

	var stats: Label = find_child("Stats")
	if stats:
		stats.text = "Best Wave: %d   Endless Record: %d" % [
			SaveManager.get_high_wave(),
			SaveManager.get_endless_record()
		]
	_lbl_progress.text = "Lifetime clears: %d" % SaveManager.get_stat("lifetime_games")

func _show_victory(stars: int, score: int, level_id: int) -> void:
	visible = true
	var level_data := CampaignData.get_level(level_id)

	_lbl_title.text = "VICTORY"
	_lbl_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.28))
	_lbl_wave.text = "Level %d: %s" % [level_id, level_data.get("title", "Campaign")]
	_lbl_score.text = "Score: %d" % score
	_lbl_high.text = "Stars: %s" % (("*").repeat(stars) + ("-").repeat(3 - stars))

	var stats: Label = find_child("Stats")
	if stats:
		stats.text = "+%d diamonds earned   Target wave %d" % [
			level_data.get("diamonds", 0),
			level_data.get("target_wave", 0)
		]

	_lbl_progress.text = "Campaign Progress: %d/40 cleared, %d three-star clears" % [
		CampaignData.get_beaten_count(),
		CampaignData.get_three_star_count()
	]

	_next_level_id = level_id + 1 if level_id < 40 else -1
	_btn_next.visible = _next_level_id > 0

func _on_restart() -> void:
	visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu() -> void:
	visible = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_next_level() -> void:
	if _next_level_id <= 0:
		return
	var level_data := CampaignData.get_level(_next_level_id)
	if level_data.is_empty():
		return
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game_node: Node = game_scene.instantiate()
	get_tree().root.add_child(game_node)
	game_node.configure_campaign(level_data)
	get_parent().queue_free()

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
	button.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(color))
	var hover := _button_style(color.lightened(0.14))
	hover.border_color = Color(0.55, 0.68, 0.95, 0.42)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := _button_style(color.darkened(0.18))
	button.add_theme_stylebox_override("pressed", pressed)
	parent.add_child(button)
	return button

func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 2
	style.border_width_bottom = 1
	style.border_color = Color(0.36, 0.42, 0.7, 0.3)
	style.shadow_color = Color(0, 0, 0, 0.48)
	style.shadow_size = 8
	return style

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.4, 0.6, 0.26)
	return style
