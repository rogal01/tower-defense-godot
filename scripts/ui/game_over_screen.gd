extends CanvasLayer

var gm: Node = null
var _next_level_id: int = -1

var _lbl_title: Label
var _lbl_score: Label
var _lbl_wave: Label
var _lbl_high: Label
var _lbl_progress: Label
var _lbl_stats: Label
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
	dimmer.color = Color(0.01, 0.02, 0.04, 0.82)
	add_child(dimmer)

	var panel := Panel.new()
	panel.position = Vector2(24, 136)
	panel.size = Vector2(432, 548)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.06, 0.10, 0.99), Color(0.42, 0.66, 0.88, 0.26), 30))
	add_child(panel)

	var top_glow := ColorRect.new()
	top_glow.position = Vector2(16, 14)
	top_glow.size = Vector2(400, 72)
	top_glow.color = Color(0.28, 0.62, 0.92, 0.10)
	panel.add_child(top_glow)

	var top_band := ColorRect.new()
	top_band.position = Vector2(0, 0)
	top_band.size = Vector2(432, 90)
	top_band.color = Color(0.06, 0.10, 0.18, 0.58)
	panel.add_child(top_band)

	var cap := Panel.new()
	cap.position = Vector2(24, 18)
	cap.size = Vector2(118, 24)
	cap.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.16, 0.24, 0.94), Color(0.54, 0.82, 0.96, 0.22), 12))
	panel.add_child(cap)
	var cap_label := _label(cap, "RUN REPORT", Vector2(0, 4), 10, Color(0.80, 0.92, 1.0))
	cap_label.custom_minimum_size = Vector2(118, 16)
	cap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_lbl_title = _label(panel, "RUN ENDED", Vector2(0, 38), 32, Color(1.0, 0.40, 0.34))
	_lbl_title.custom_minimum_size = Vector2(432, 34)
	_lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_lbl_wave = _label(panel, "Wave 0", Vector2(26, 112), 22, Color(0.78, 0.90, 1.0))
	_lbl_wave.custom_minimum_size = Vector2(380, 28)
	_lbl_wave.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_lbl_score = _label(panel, "Score 0", Vector2(26, 154), 30, Color(1.0, 0.86, 0.28))
	_lbl_score.custom_minimum_size = Vector2(380, 34)
	_lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var score_band := ColorRect.new()
	score_band.position = Vector2(36, 206)
	score_band.size = Vector2(360, 34)
	score_band.color = Color(0.08, 0.12, 0.18, 0.46)
	panel.add_child(score_band)

	_lbl_high = _label(panel, "", Vector2(26, 214), 16, Color(0.78, 0.94, 0.82))
	_lbl_high.custom_minimum_size = Vector2(380, 20)
	_lbl_high.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_lbl_stats = _label(panel, "", Vector2(34, 262), 14, Color(0.68, 0.78, 0.90))
	_lbl_stats.custom_minimum_size = Vector2(356, 54)
	_lbl_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_lbl_progress = _label(panel, "", Vector2(34, 326), 14, Color(0.86, 0.92, 1.0))
	_lbl_progress.custom_minimum_size = Vector2(356, 46)
	_lbl_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var btn_restart := _button(panel, "PLAY AGAIN", Vector2(40, 390), Vector2(352, 52), 22, Color(0.10, 0.22, 0.18))
	btn_restart.pressed.connect(_on_restart)

	_btn_next = _button(panel, "NEXT LEVEL", Vector2(40, 454), Vector2(352, 42), 18, Color(0.18, 0.14, 0.06))
	_btn_next.visible = false
	_btn_next.pressed.connect(_on_next_level)

	var btn_menu := _button(panel, "MAIN MENU", Vector2(40, 506), Vector2(352, 42), 18, Color(0.08, 0.12, 0.20))
	btn_menu.pressed.connect(_on_menu)

func _show_game_over(score: int, wave: int, is_high_score: bool) -> void:
	visible = true
	_next_level_id = -1
	_btn_next.visible = false

	var mode_line := "Reached Wave %d" % wave
	var diff_name := "Normal"
	if gm:
		match int(gm.get("difficulty")):
			0:
				diff_name = "Easy"
			2:
				diff_name = "Hard"
		if bool(gm.get("is_boss_gauntlet")):
			mode_line = "Boss Gauntlet  |  Wave %d" % wave
		elif bool(gm.get("is_boss_rush")):
			mode_line = "Boss Rush  |  Wave %d" % wave
		elif bool(gm.get("is_daily_challenge")):
			mode_line = "Daily Challenge  |  Wave %d" % wave
		elif bool(gm.get("is_randomizer_mode")):
			mode_line = "Randomizer  |  Wave %d" % wave
		elif bool(gm.get("is_endless")):
			mode_line = "Endless %s  |  Wave %d" % [diff_name, wave]

	_lbl_title.text = "RUN ENDED"
	_lbl_title.add_theme_color_override("font_color", Color(1.0, 0.40, 0.34))
	_lbl_wave.text = mode_line
	_lbl_score.text = "Score %d" % score
	if gm and bool(gm.get("is_endless")):
		_lbl_high.text = "Endless Record %d" % SaveManager.get_endless_record()
	elif is_high_score:
		_lbl_high.text = "New High Score"
	else:
		_lbl_high.text = "High Score %d" % SaveManager.get_high_score()

	var run_diamonds := int(gm.get("diamonds_this_run")) if gm else 0
	_lbl_stats.text = "Best Wave %d  |  Endless %d  |  Difficulty %s\nRun diamonds +%d" % [
		SaveManager.get_high_wave(),
		SaveManager.get_endless_record(),
		diff_name,
		run_diamonds,
	]
	_lbl_progress.text = "Lifetime clears %d  |  Total score %d" % [
		SaveManager.get_stat("lifetime_games"),
		SaveManager.get_stat("lifetime_score"),
	]

func _show_victory(stars: int, score: int, level_id: int) -> void:
	visible = true
	var level_data := CampaignData.get_level(level_id)

	_lbl_title.text = "VICTORY"
	_lbl_title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.30))
	_lbl_wave.text = "Stage %02d  |  %s" % [level_id, level_data.get("title", "Campaign")]
	_lbl_score.text = "Score %d" % score
	_lbl_high.text = "Flawless %s" % ("YES" if stars >= 3 else "NO")
	var constraints: Array[String] = []
	if not bool(level_data.get("upgrades", true)):
		constraints.append("NO UPGRADES")
	var constraints_text := "Standard rules" if constraints.is_empty() else ", ".join(constraints)
	var reward_diamonds := int(level_data.get("diamonds", 0))
	var run_bonus_diamonds := int(gm.get("diamonds_this_run")) if gm else 0
	var total_diamonds := reward_diamonds + run_bonus_diamonds

	_lbl_stats.text = "+%d diamonds earned  |  Target wave %d\n%s" % [
		total_diamonds,
		level_data.get("target_wave", 0),
		constraints_text,
	]
	var total_levels := maxi(1, CampaignData.get_total_levels())
	_lbl_progress.text = "Campaign %d / %d cleared  |  Flawless clears %d" % [
		CampaignData.get_beaten_count(),
		total_levels,
		CampaignData.get_three_star_count(),
	]

	_next_level_id = level_id + 1 if level_id < total_levels else -1
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
	get_tree().current_scene = game_node
	game_node.configure_campaign(level_data, int(gm.get("map_type")) if gm else GameData.MapType.CLASSIC)
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
	style.shadow_color = Color(0, 0, 0, 0.44)
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
