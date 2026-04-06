extends Control

const SCREEN_SIZE := Vector2(480, 854)
const DIFFICULTIES := [
	{"label": "Easy", "color": Color(0.14, 0.42, 0.18)},
	{"label": "Normal", "color": Color(0.12, 0.26, 0.50)},
	{"label": "Hard", "color": Color(0.46, 0.14, 0.14)},
	{"label": "Endless", "color": Color(0.28, 0.10, 0.42)},
	{"label": "Boss Rush", "color": Color(0.52, 0.26, 0.04)},
]

var _selected_difficulty: int = 1
var _selected_map: int = GameData.MapType.CLASSIC
var _anim_time: float = 0.0
var _stars: Array = []

var _header_stats: Label
var _map_desc: Label
var _difficulty_buttons: Array[Button] = []
var _map_buttons: Dictionary = {}
var _overlay: Panel = null

func _ready() -> void:
	_generate_stars()
	_build_ui()
	SoundManager.play_menu_music()

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()

func _draw() -> void:
	var bg_top := Color(0.05, 0.09, 0.16)
	var bg_bottom := Color(0.01, 0.02, 0.05)
	for y in range(0, 854, 4):
		var t := float(y) / 854.0
		draw_rect(Rect2(0, y, 480, 4), bg_top.lerp(bg_bottom, t))

	draw_colored_polygon([
		Vector2(0, 520),
		Vector2(96, 438),
		Vector2(186, 500),
		Vector2(274, 422),
		Vector2(376, 514),
		Vector2(480, 454),
		Vector2(480, 854),
		Vector2(0, 854),
	], Color(0.06, 0.10, 0.18, 0.85))

	for star in _stars:
		var glow := 0.22 + 0.55 * (0.5 + 0.5 * sin(_anim_time * star["speed"] + star["phase"]))
		draw_circle(star["pos"], star["size"], Color(0.72, 0.84, 1.0, glow))

	draw_arc(Vector2(390, 100), 52 + sin(_anim_time) * 2.0, 0, TAU, 30, Color(0.4, 0.72, 1.0, 0.22), 2.0)
	draw_arc(Vector2(86, 734), 76 + sin(_anim_time * 0.8) * 4.0, PI * 0.8, TAU * 0.9, 36, Color(0.45, 0.85, 0.5, 0.18), 3.0)

func _generate_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7777
	for _i in range(72):
		_stars.append({
			"pos": Vector2(rng.randf_range(0.0, 480.0), rng.randf_range(0.0, 340.0)),
			"size": rng.randf_range(0.6, 2.0),
			"speed": rng.randf_range(0.4, 1.5),
			"phase": rng.randf() * TAU,
		})

func _build_ui() -> void:
	var title_shadow := _label(self, "TOWER DEFENSE", Vector2(0, 54), 42, Color(0, 0, 0, 0.38))
	title_shadow.position.x += 2
	title_shadow.position.y += 3
	title_shadow.custom_minimum_size = Vector2(480, 56)
	title_shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var title := _label(self, "TOWER DEFENSE", Vector2(0, 52), 42, Color(0.78, 0.92, 1.0))
	title.custom_minimum_size = Vector2(480, 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var subtitle := _label(self, "Shape the battlefield, survive the rush.", Vector2(0, 108), 15, Color(0.72, 0.8, 0.92))
	subtitle.custom_minimum_size = Vector2(480, 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_header_stats = _label(self, "", Vector2(0, 138), 13, Color(0.54, 0.68, 0.86))
	_header_stats.custom_minimum_size = Vector2(480, 22)
	_header_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_refresh_header_stats()

	var card := _panel(Vector2(18, 176), Vector2(444, 474), Color(0.03, 0.05, 0.10, 0.88))
	add_child(card)

	_label(card, "Difficulty", Vector2(16, 16), 14, Color(0.72, 0.82, 0.96))
	for i in range(DIFFICULTIES.size()):
		var data = DIFFICULTIES[i]
		var btn := _button(card, data["label"], Vector2(16 + (i % 2) * 206, 42 + (i / 2) * 44), Vector2(190, 34))
		btn.pressed.connect(_on_difficulty_selected.bind(i))
		_difficulty_buttons.append(btn)

	_label(card, "Map", Vector2(16, 154), 14, Color(0.72, 0.82, 0.96))
	var map_types: Array = GameData.MapType.values()
	for i in range(map_types.size()):
		var map_type: int = map_types[i]
		var map_data := GameData.get_map(map_type)
		var btn := _button(card, map_data["name"], Vector2(16 + (i % 2) * 206, 180 + (i / 2) * 42), Vector2(190, 32))
		btn.pressed.connect(_on_map_selected.bind(map_type))
		_map_buttons[map_type] = btn

	_map_desc = _label(card, "", Vector2(18, 354), 14, Color(0.84, 0.9, 0.96))
	_map_desc.custom_minimum_size = Vector2(406, 48)
	_map_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var play_btn := _button(card, "PLAY", Vector2(18, 412), Vector2(408, 50), Color(0.08, 0.34, 0.14))
	play_btn.add_theme_font_size_override("font_size", 26)
	play_btn.pressed.connect(_on_play)

	var secondary_row := HBoxContainer.new()
	secondary_row.position = Vector2(18, 664)
	secondary_row.custom_minimum_size = Vector2(444, 42)
	secondary_row.add_theme_constant_override("separation", 6)
	add_child(secondary_row)

	for button_data in [
		{"label": "Campaign", "method": "_on_campaign"},
		{"label": "Skill Tree", "method": "_on_skill_tree"},
		{"label": "Trophies", "method": "_on_achievements"},
		{"label": "Settings", "method": "_on_settings"},
	]:
		var btn := Button.new()
		btn.text = button_data["label"]
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_color_override("font_color", Color(0.86, 0.92, 1.0))
		btn.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.10, 0.18)))
		btn.add_theme_stylebox_override("hover", _button_style(Color(0.12, 0.15, 0.24)))
		btn.pressed.connect(Callable(self, button_data["method"]))
		secondary_row.add_child(btn)

	var footer := _label(self, "Diamonds %d   |   Games %d   |   v2.1" % [
		SaveManager.get_diamonds(),
		SaveManager.get_stat("lifetime_games")
	], Vector2(0, 812), 11, Color(0.42, 0.5, 0.64))
	footer.custom_minimum_size = Vector2(480, 20)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_refresh_difficulty_buttons()
	_refresh_map_buttons()
	_refresh_map_desc()

func _refresh_header_stats() -> void:
	_header_stats.text = "Best Wave %d   |   High Score %d   |   Endless %d" % [
		SaveManager.get_high_wave(),
		SaveManager.get_high_score(),
		SaveManager.get_endless_record()
	]

func _refresh_difficulty_buttons() -> void:
	for i in range(_difficulty_buttons.size()):
		var btn := _difficulty_buttons[i]
		var color: Color = DIFFICULTIES[i]["color"]
		var active := i == _selected_difficulty
		btn.add_theme_stylebox_override("normal", _button_style(color if active else color.darkened(0.45)))
		btn.add_theme_stylebox_override("hover", _button_style(color.lightened(0.12)))

func _refresh_map_buttons() -> void:
	for map_type in _map_buttons:
		var btn: Button = _map_buttons[map_type]
		var map_data := GameData.get_map(map_type)
		var color: Color = map_data["bg_color"].darkened(0.18)
		var active: bool = map_type == _selected_map
		btn.add_theme_stylebox_override("normal", _button_style(color if active else color.darkened(0.38)))
		btn.add_theme_stylebox_override("hover", _button_style(color.lightened(0.12)))

func _refresh_map_desc() -> void:
	var map_data := GameData.get_map(_selected_map)
	_map_desc.text = "%s battlefield\nTerrain color: %s\nChoose a lane plan before the first wave starts." % [
		map_data["name"],
		str(map_data["path_color"])
	]

func _on_difficulty_selected(level: int) -> void:
	_selected_difficulty = level
	_refresh_difficulty_buttons()
	SoundManager.play_ui_click()

func _on_map_selected(map_type: int) -> void:
	_selected_map = map_type
	_refresh_map_buttons()
	_refresh_map_desc()
	SoundManager.play_ui_click()

func _on_play() -> void:
	SoundManager.play_ui_click()
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game_node: Node = game_scene.instantiate()
	get_tree().root.add_child(game_node)
	game_node.configure(_selected_difficulty, _selected_map)
	queue_free()

func _on_campaign() -> void:
	SoundManager.play_ui_click()
	_show_campaign_overlay()

func _on_skill_tree() -> void:
	SoundManager.play_ui_click()
	_show_skill_tree_overlay()

func _on_achievements() -> void:
	SoundManager.play_ui_click()
	_show_achievements_overlay()

func _on_settings() -> void:
	SoundManager.play_ui_click()
	_show_settings_overlay()

func _show_campaign_overlay() -> void:
	var overlay := _overlay_panel("Campaign")
	var stars_total := 0
	for i in range(1, 41):
		stars_total += SaveManager.get_campaign_stars(i)
	var summary := _label(overlay, "Progress %d/40 levels   |   %d/120 stars" % [CampaignData.get_beaten_count(), stars_total], Vector2(18, 62), 15, Color(1.0, 0.88, 0.34))
	summary.custom_minimum_size = Vector2(380, 24)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(14, 98)
	scroll.size = Vector2(452, 716)
	overlay.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(440, 0)
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	for level_data in CampaignData.LEVELS:
		var level_id: int = level_data["id"]
		var unlocked := CampaignData.is_unlocked(level_id)
		var beaten := SaveManager.is_campaign_beaten(level_id)
		var stars := SaveManager.get_campaign_stars(level_id)
		var btn_color := Color(0.08, 0.22, 0.12) if beaten else Color(0.08, 0.10, 0.18)
		var btn := _button(vbox, "%02d  %s   [%s]" % [level_id, level_data["title"], ("*").repeat(stars) + ("-").repeat(3 - stars)], Vector2.ZERO, Vector2(0, 46), btn_color)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(440, 46)
		btn.disabled = not unlocked
		if unlocked:
			btn.pressed.connect(_start_campaign_level.bind(level_data))
		else:
			btn.text = "%02d  %s   [LOCKED]" % [level_id, level_data["title"]]

func _start_campaign_level(level_data: Dictionary) -> void:
	if _overlay:
		_overlay.queue_free()
	SoundManager.play_ui_click()
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game_node: Node = game_scene.instantiate()
	get_tree().root.add_child(game_node)
	game_node.configure_campaign(level_data)
	queue_free()

func _show_skill_tree_overlay() -> void:
	var overlay := _overlay_panel("Skill Tree")
	_label(overlay, "Diamonds: %d" % SaveManager.get_diamonds(), Vector2(18, 62), 16, Color(0.6, 0.84, 1.0))

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(14, 98)
	scroll.size = Vector2(452, 716)
	overlay.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.custom_minimum_size = Vector2(440, 0)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)

	for skill_id in GameData.SKILLS.keys():
		var data: Dictionary = GameData.SKILLS[skill_id]
		var level := SaveManager.get_skill_level(skill_id)
		var btn := _button(grid, "%s  Lv%d/%d\nCost %d" % [data["label"], level, data["max"], data["cost"]], Vector2.ZERO, Vector2(0, 70), Color(0.08, 0.12, 0.20))
		btn.custom_minimum_size = Vector2(214, 70)
		btn.disabled = level >= data["max"] or SaveManager.get_diamonds() < data["cost"]
		btn.pressed.connect(_upgrade_skill.bind(skill_id, data))

func _upgrade_skill(skill_id: String, data: Dictionary) -> void:
	if SaveManager.spend_diamonds(int(data["cost"])):
		SaveManager.set_skill_level(skill_id, SaveManager.get_skill_level(skill_id) + 1)
		SaveManager.flush()
		SoundManager.play_place()
		if _overlay:
			_overlay.queue_free()
		_show_skill_tree_overlay()

func _show_achievements_overlay() -> void:
	var overlay := _overlay_panel("Achievements")
	var unlocked := 0
	for achievement in AchievementManager.ACHIEVEMENTS:
		if SaveManager.is_achievement_unlocked(achievement["id"]):
			unlocked += 1
	_label(overlay, "%d/%d unlocked" % [unlocked, AchievementManager.ACHIEVEMENTS.size()], Vector2(18, 62), 16, Color(0.7, 0.84, 1.0))

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(14, 98)
	scroll.size = Vector2(452, 716)
	overlay.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(440, 0)
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	for achievement in AchievementManager.ACHIEVEMENTS:
		var done := SaveManager.is_achievement_unlocked(achievement["id"])
		var row_color := Color(0.07, 0.18, 0.10) if done else Color(0.07, 0.08, 0.13)
		var row := _panel(Vector2.ZERO, Vector2(440, 58), row_color)
		row.custom_minimum_size = Vector2(440, 58)
		vbox.add_child(row)
		var text_color := Color(0.95, 1.0, 0.95) if done else Color(0.56, 0.62, 0.74)
		var lbl := _label(row, "%s\n%s" % [achievement["title"], achievement["desc"]], Vector2(10, 8), 13, text_color)
		lbl.custom_minimum_size = Vector2(420, 40)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _show_settings_overlay() -> void:
	var overlay := _overlay_panel("Settings")

	_label(overlay, "Music Volume", Vector2(20, 72), 15, Color(0.82, 0.9, 1.0))
	var music_slider := HSlider.new()
	music_slider.position = Vector2(180, 74)
	music_slider.size = Vector2(220, 18)
	music_slider.min_value = -30
	music_slider.max_value = 0
	music_slider.step = 1
	music_slider.value = SoundManager.music_volume_db
	overlay.add_child(music_slider)
	music_slider.value_changed.connect(func(value: float): SoundManager.set_music_volume(value))

	_label(overlay, "SFX Volume", Vector2(20, 118), 15, Color(0.82, 0.9, 1.0))
	var sfx_slider := HSlider.new()
	sfx_slider.position = Vector2(180, 120)
	sfx_slider.size = Vector2(220, 18)
	sfx_slider.min_value = -30
	sfx_slider.max_value = 0
	sfx_slider.step = 1
	sfx_slider.value = SoundManager.sfx_volume_db
	overlay.add_child(sfx_slider)
	sfx_slider.value_changed.connect(func(value: float): SoundManager.set_sfx_volume(value))

	_label(overlay, "Palette", Vector2(20, 168), 15, Color(0.82, 0.9, 1.0))
	var palette := OptionButton.new()
	palette.position = Vector2(180, 164)
	palette.size = Vector2(180, 28)
	var palettes := GameData.get_palette_names()
	for idx in range(palettes.size()):
		palette.add_item(palettes[idx], idx)
		if palettes[idx] == GameData.current_palette:
			palette.selected = idx
	overlay.add_child(palette)
	palette.item_selected.connect(func(idx: int):
		GameData.set_palette(palettes[idx])
		queue_redraw()
	)

	var music_row := HBoxContainer.new()
	music_row.position = Vector2(20, 224)
	music_row.custom_minimum_size = Vector2(390, 38)
	music_row.add_theme_constant_override("separation", 8)
	overlay.add_child(music_row)

	for track_data in [
		{"label": "Menu", "method": "play_menu_music"},
		{"label": "Battle", "method": "play_battle_music"},
		{"label": "Victory", "method": "play_victory_music"},
	]:
		var btn := Button.new()
		btn.text = track_data["label"]
		btn.custom_minimum_size = Vector2(0, 34)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
		btn.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.12, 0.20)))
		btn.add_theme_stylebox_override("hover", _button_style(Color(0.12, 0.16, 0.26)))
		btn.pressed.connect(Callable(SoundManager, track_data["method"]))
		music_row.add_child(btn)

	_label(overlay, "Generated soundtrack and SFX are now loaded from WAV assets in assets/audio.", Vector2(20, 286), 13, Color(0.66, 0.76, 0.9)).custom_minimum_size = Vector2(408, 56)

func _overlay_panel(title: String) -> Panel:
	if _overlay:
		_overlay.queue_free()
	_overlay = _panel(Vector2(0, 0), SCREEN_SIZE, Color(0.02, 0.03, 0.06, 0.96))
	add_child(_overlay)

	var header := _panel(Vector2(12, 12), Vector2(456, 50), Color(0.05, 0.08, 0.16))
	_overlay.add_child(header)
	var title_label := _label(header, title, Vector2(14, 12), 24, Color(0.92, 0.96, 1.0))
	title_label.custom_minimum_size = Vector2(300, 26)
	var close_btn := _button(header, "Close", Vector2(360, 8), Vector2(82, 34), Color(0.22, 0.08, 0.08))
	close_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		if _overlay:
			_overlay.queue_free()
			_overlay = null
	)
	return _overlay

func _label(parent: Control, text: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _panel(pos: Vector2, size: Vector2, color: Color) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	panel.add_theme_stylebox_override("panel", _panel_style(color))
	return panel

func _button(parent: Control, text: String, pos: Vector2, size: Vector2, color: Color = Color(0.08, 0.12, 0.20)) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = size
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(color))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.18)))
	parent.add_child(button)
	return button

func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.38, 0.5, 0.78, 0.24)
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 6
	return style

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.46, 0.56, 0.82, 0.28)
	return style
