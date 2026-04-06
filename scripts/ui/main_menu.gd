extends Control

const SCREEN_SIZE := Vector2(480, 854)
const SKIRMISH_DIFFICULTIES := [
	{
		"id": 0,
		"label": "Easy",
		"color": Color(0.15, 0.42, 0.18),
		"desc": "Extra starting gold, softer enemies, and slower wave pressure."
	},
	{
		"id": 1,
		"label": "Medium",
		"color": Color(0.12, 0.26, 0.50),
		"desc": "Standard desktop-style tower defense pacing and economy."
	},
	{
		"id": 2,
		"label": "Hard",
		"color": Color(0.46, 0.14, 0.14),
		"desc": "Lean economy, tougher enemies, and heavier spawn pressure."
	},
]

var _selected_difficulty: int = 1
var _selected_map: int = GameData.MapType.CLASSIC
var _anim_time: float = 0.0
var _stars: Array = []

var _header_stats: Label
var _campaign_status: Label
var _briefing_title: Label
var _briefing_body: Label
var _briefing_footer: Label
var _overlay: Panel = null

func _ready() -> void:
	_generate_stars()
	_build_ui()
	_refresh_header_stats()
	_refresh_campaign_status()
	_refresh_briefing()
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

	var subtitle := _label(self, "Desktop-style defense, rebuilt for mobile.", Vector2(0, 108), 15, Color(0.72, 0.80, 0.92))
	subtitle.custom_minimum_size = Vector2(480, 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_header_stats = _label(self, "", Vector2(0, 138), 13, Color(0.54, 0.68, 0.86))
	_header_stats.custom_minimum_size = Vector2(480, 22)
	_header_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_build_campaign_card()
	_build_modes_card()
	_build_briefing_card()
	_build_footer_actions()

	var footer := _label(self, "Diamonds %d   |   Games %d   |   v2.2" % [
		SaveManager.get_diamonds(),
		SaveManager.get_stat("lifetime_games")
	], Vector2(0, 828), 11, Color(0.42, 0.5, 0.64))
	footer.custom_minimum_size = Vector2(480, 20)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_campaign_card() -> void:
	var card := _panel(Vector2(18, 176), Vector2(444, 166), Color(0.04, 0.06, 0.10, 0.90))
	add_child(card)

	_label(card, "Campaign Command", Vector2(18, 14), 15, Color(1.0, 0.88, 0.34))
	var sub := _label(card, "The main progression path. Unlock levels, earn stars, and climb the full map set.", Vector2(18, 36), 13, Color(0.80, 0.88, 0.96))
	sub.custom_minimum_size = Vector2(404, 34)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var campaign_btn := _button(card, "CAMPAIGN", Vector2(18, 82), Vector2(408, 50), Color(0.34, 0.24, 0.05))
	campaign_btn.add_theme_font_size_override("font_size", 26)
	campaign_btn.pressed.connect(_on_campaign)

	_campaign_status = _label(card, "", Vector2(18, 138), 12, Color(0.68, 0.80, 0.92))
	_campaign_status.custom_minimum_size = Vector2(404, 18)

func _build_modes_card() -> void:
	var card := _panel(Vector2(18, 356), Vector2(444, 214), Color(0.03, 0.05, 0.10, 0.90))
	add_child(card)

	_label(card, "Battle Modes", Vector2(18, 14), 15, Color(0.74, 0.84, 0.98))
	_label(card, "Skirmish keeps Easy / Medium / Hard together. Endless and Boss Rush stay separate.", Vector2(18, 36), 12, Color(0.58, 0.68, 0.82))

	_mode_card(card, "Skirmish", "Classic desktop setup with map + difficulty briefing.", "Easy / Medium / Hard", 68, Color(0.08, 0.16, 0.28), _on_open_skirmish)
	_mode_card(card, "Endless", "Scaling survival mode with your best wave record tracked.", "Record %d" % SaveManager.get_endless_record(), 116, Color(0.22, 0.10, 0.34), _on_open_endless)
	_mode_card(card, "Boss Rush", "Boss every wave, faster power spikes, high-pressure lanes.", "Best Wave %d" % SaveManager.get_high_wave(), 164, Color(0.34, 0.16, 0.06), _on_open_boss_rush)

func _build_briefing_card() -> void:
	var card := _panel(Vector2(18, 586), Vector2(444, 188), Color(0.03, 0.05, 0.11, 0.92))
	add_child(card)

	_label(card, "Battle Briefing", Vector2(18, 14), 15, Color(0.82, 0.90, 1.0))
	_briefing_title = _label(card, "", Vector2(18, 40), 16, Color(1.0, 0.88, 0.28))
	_briefing_body = _label(card, "", Vector2(18, 66), 12, Color(0.76, 0.84, 0.94))
	_briefing_body.custom_minimum_size = Vector2(404, 68)
	_briefing_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_briefing_footer = _label(card, "", Vector2(18, 138), 11, Color(0.58, 0.68, 0.82))
	_briefing_footer.custom_minimum_size = Vector2(404, 18)

	var intel_btn := _button(card, "Tower Intel", Vector2(18, 154), Vector2(128, 26), Color(0.08, 0.14, 0.22))
	intel_btn.add_theme_font_size_override("font_size", 11)
	intel_btn.pressed.connect(_on_intel)

	var quick_btn := _button(card, "Quick Skirmish", Vector2(154, 154), Vector2(138, 26), Color(0.08, 0.24, 0.14))
	quick_btn.add_theme_font_size_override("font_size", 11)
	quick_btn.pressed.connect(_on_open_skirmish)

	var continue_btn := _button(card, "Next Campaign", Vector2(300, 154), Vector2(126, 26), Color(0.18, 0.16, 0.06))
	continue_btn.add_theme_font_size_override("font_size", 11)
	continue_btn.pressed.connect(_on_continue_campaign)

func _build_footer_actions() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(18, 786)
	row.custom_minimum_size = Vector2(444, 34)
	row.add_theme_constant_override("separation", 6)
	add_child(row)

	var skill_btn := _row_button("Skill Tree")
	skill_btn.pressed.connect(_on_skill_tree)
	row.add_child(skill_btn)

	var trophies_btn := _row_button("Trophies")
	trophies_btn.pressed.connect(_on_achievements)
	row.add_child(trophies_btn)

	var settings_btn := _row_button("Settings")
	settings_btn.pressed.connect(_on_settings)
	row.add_child(settings_btn)

func _mode_card(parent: Control, title: String, desc: String, record: String, y: float, color: Color, callable: Callable) -> void:
	var panel := _panel(Vector2(18, y), Vector2(408, 42), color)
	parent.add_child(panel)

	var btn := Button.new()
	btn.text = title
	btn.position = Vector2(0, 0)
	btn.size = Vector2(122, 42)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0))
	btn.add_theme_stylebox_override("normal", _button_style(color))
	btn.add_theme_stylebox_override("hover", _button_style(color.lightened(0.12)))
	btn.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.15)))
	btn.pressed.connect(callable)
	panel.add_child(btn)

	var desc_label := _label(panel, desc, Vector2(136, 6), 11, Color(0.86, 0.90, 0.96))
	desc_label.custom_minimum_size = Vector2(190, 16)
	var record_label := _label(panel, record, Vector2(136, 22), 10, Color(0.62, 0.74, 0.90))
	record_label.custom_minimum_size = Vector2(252, 14)

func _row_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 32)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	btn.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.10, 0.18)))
	btn.add_theme_stylebox_override("hover", _button_style(Color(0.12, 0.15, 0.24)))
	btn.add_theme_stylebox_override("pressed", _button_style(Color(0.06, 0.08, 0.14)))
	return btn

func _refresh_header_stats() -> void:
	_header_stats.text = "Best Wave %d   |   High Score %d   |   Endless %d" % [
		SaveManager.get_high_wave(),
		SaveManager.get_high_score(),
		SaveManager.get_endless_record()
	]

func _refresh_campaign_status() -> void:
	var beaten_count: int = CampaignData.get_beaten_count()
	var next_level: Dictionary = _get_next_campaign_level()
	if next_level.is_empty():
		_campaign_status.text = "40/40 cleared. Replay for stars and cleaner clears."
		return
	_campaign_status.text = "Progress %d/40   |   Next Level %02d: %s" % [
		beaten_count,
		int(next_level.get("id", 1)),
		str(next_level.get("title", "Campaign"))
	]

func _refresh_briefing() -> void:
	var mode_name := _mode_name(_selected_difficulty)
	var map_data: Dictionary = GameData.get_map(_selected_map)
	_briefing_title.text = "%s on %s" % [mode_name, str(map_data.get("name", "Classic"))]
	_briefing_body.text = _build_mode_brief(_selected_difficulty, _selected_map)
	_briefing_footer.text = "Desktop notes: build killboxes on bends, keep one lane-answer tower, and save powers for boss spikes."

func _on_campaign() -> void:
	SoundManager.play_ui_click()
	_show_campaign_overlay()

func _on_continue_campaign() -> void:
	var next_level: Dictionary = _get_next_campaign_level()
	if next_level.is_empty():
		_on_campaign()
		return
	_start_campaign_level(next_level)

func _on_open_skirmish() -> void:
	SoundManager.play_ui_click()
	_show_skirmish_overlay()

func _on_open_endless() -> void:
	SoundManager.play_ui_click()
	_show_special_mode_overlay(3)

func _on_open_boss_rush() -> void:
	SoundManager.play_ui_click()
	_show_special_mode_overlay(4)

func _on_skill_tree() -> void:
	SoundManager.play_ui_click()
	_show_skill_tree_overlay()

func _on_achievements() -> void:
	SoundManager.play_ui_click()
	_show_achievements_overlay()

func _on_settings() -> void:
	SoundManager.play_ui_click()
	_show_settings_overlay()

func _on_intel() -> void:
	SoundManager.play_ui_click()
	_show_intel_overlay()

func _show_skirmish_overlay() -> void:
	var overlay := _overlay_panel("Skirmish Setup")
	_label(overlay, "Choose a map, then pick Easy / Medium / Hard in a separate desktop-style setup flow.", Vector2(18, 62), 14, Color(0.78, 0.86, 0.96)).custom_minimum_size = Vector2(420, 34)

	_label(overlay, "Difficulty", Vector2(18, 106), 15, Color(1.0, 0.88, 0.30))
	for idx in range(SKIRMISH_DIFFICULTIES.size()):
		var data: Dictionary = SKIRMISH_DIFFICULTIES[idx]
		var option_id: int = int(data.get("id", idx))
		var option_color: Color = data.get("color", Color(0.12, 0.22, 0.34))
		var active: bool = option_id == _selected_difficulty
		var btn := _button(
			overlay,
			str(data.get("label", "Mode")),
			Vector2(18 + idx * 144, 132),
			Vector2(132, 36),
			option_color if active else option_color.darkened(0.35)
		)
		btn.pressed.connect(_on_skirmish_difficulty_selected.bind(option_id))

	var desc := _label(overlay, _get_skirmish_desc(_selected_difficulty), Vector2(18, 176), 12, Color(0.70, 0.80, 0.92))
	desc.custom_minimum_size = Vector2(420, 34)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_build_map_picker(overlay, "Map", 224, "skirmish")

	var briefing := _label(overlay, _build_mode_brief(_selected_difficulty, _selected_map), Vector2(18, 466), 13, Color(0.86, 0.90, 0.96))
	briefing.custom_minimum_size = Vector2(420, 170)
	briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var launch := _button(overlay, "Launch Skirmish", Vector2(18, 760), Vector2(420, 46), Color(0.08, 0.30, 0.14))
	launch.add_theme_font_size_override("font_size", 22)
	launch.pressed.connect(_launch_skirmish)

func _show_special_mode_overlay(mode_id: int) -> void:
	var overlay := _overlay_panel(_mode_name(mode_id))
	_label(overlay, _mode_long_desc(mode_id), Vector2(18, 62), 14, Color(0.78, 0.86, 0.96)).custom_minimum_size = Vector2(420, 40)

	var stat_text: String = ""
	if mode_id == 3:
		stat_text = "Best endless wave: %d" % SaveManager.get_endless_record()
	else:
		stat_text = "Boss pressure mode. Boss every wave, faster power spikes."
	var stat_label := _label(overlay, stat_text, Vector2(18, 106), 13, Color(1.0, 0.88, 0.30))
	stat_label.custom_minimum_size = Vector2(420, 22)

	_build_map_picker(overlay, "Map", 146, "endless" if mode_id == 3 else "boss")

	var briefing := _label(overlay, _build_mode_brief(mode_id, _selected_map), Vector2(18, 388), 13, Color(0.86, 0.90, 0.96))
	briefing.custom_minimum_size = Vector2(420, 216)
	briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var launch_label := "Start Endless" if mode_id == 3 else "Start Boss Rush"
	var launch_color := Color(0.20, 0.10, 0.34) if mode_id == 3 else Color(0.32, 0.16, 0.06)
	var launch := _button(overlay, launch_label, Vector2(18, 760), Vector2(420, 46), launch_color)
	launch.add_theme_font_size_override("font_size", 22)
	launch.pressed.connect(_launch_special.bind(mode_id))

func _build_map_picker(parent: Control, title: String, start_y: float, popup_kind: String) -> void:
	_label(parent, title, Vector2(18, start_y), 15, Color(1.0, 0.88, 0.30))
	var map_types: Array = GameData.MapType.values()
	for idx in range(map_types.size()):
		var map_type: int = int(map_types[idx])
		var map_data: Dictionary = GameData.get_map(map_type)
		var map_color: Color = map_data.get("bg_color", Color(0.12, 0.22, 0.12)).darkened(0.12)
		var active: bool = map_type == _selected_map
		var btn := _button(
			parent,
			str(map_data.get("name", "Map")),
			Vector2(18 + (idx % 2) * 210, start_y + 28 + int(idx / 2) * 42),
			Vector2(198, 32),
			map_color if active else map_color.darkened(0.30)
		)
		btn.pressed.connect(_on_popup_map_selected.bind(map_type, popup_kind))

func _launch_skirmish() -> void:
	_start_game(_selected_difficulty, _selected_map)

func _launch_special(mode_id: int) -> void:
	_start_game(mode_id, _selected_map)

func _start_game(mode_id: int, map_type: int) -> void:
	SoundManager.play_ui_click()
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game_node: Node = game_scene.instantiate()
	get_tree().root.add_child(game_node)
	game_node.configure(mode_id, map_type)
	queue_free()

func _on_skirmish_difficulty_selected(level: int) -> void:
	_selected_difficulty = level
	_refresh_briefing()
	SoundManager.play_ui_click()
	_show_skirmish_overlay()

func _on_popup_map_selected(map_type: int, popup_kind: String) -> void:
	_selected_map = map_type
	_refresh_briefing()
	SoundManager.play_ui_click()
	match popup_kind:
		"skirmish":
			_show_skirmish_overlay()
		"endless":
			_show_special_mode_overlay(3)
		"boss":
			_show_special_mode_overlay(4)

func _show_campaign_overlay() -> void:
	var overlay := _overlay_panel("Campaign")
	var stars_total: int = 0
	for i in range(1, 41):
		stars_total += SaveManager.get_campaign_stars(i)

	var summary := _label(overlay, "Progress %d/40 levels   |   %d/120 stars" % [CampaignData.get_beaten_count(), stars_total], Vector2(18, 62), 15, Color(1.0, 0.88, 0.34))
	summary.custom_minimum_size = Vector2(380, 24)

	var next_level: Dictionary = _get_next_campaign_level()
	if not next_level.is_empty():
		var continue_btn := _button(overlay, "Continue Level %02d" % int(next_level.get("id", 1)), Vector2(308, 58), Vector2(140, 32), Color(0.18, 0.16, 0.06))
		continue_btn.pressed.connect(_start_campaign_level.bind(next_level))

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(14, 98)
	scroll.size = Vector2(452, 716)
	overlay.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(440, 0)
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	for level_data in CampaignData.LEVELS:
		var level_id: int = int(level_data.get("id", 0))
		var unlocked: bool = CampaignData.is_unlocked(level_id)
		var beaten: bool = SaveManager.is_campaign_beaten(level_id)
		var stars: int = SaveManager.get_campaign_stars(level_id)
		var btn_color: Color = Color(0.08, 0.22, 0.12) if beaten else Color(0.08, 0.10, 0.18)
		var title: String = "%02d  %s   [%s]" % [level_id, str(level_data.get("title", "Campaign")), ("*").repeat(stars) + ("-").repeat(3 - stars)]
		var btn := _button(vbox, title, Vector2.ZERO, Vector2(0, 46), btn_color)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(440, 46)
		btn.disabled = not unlocked
		if unlocked:
			btn.pressed.connect(_start_campaign_level.bind(level_data))
		else:
			btn.text = "%02d  %s   [LOCKED]" % [level_id, str(level_data.get("title", "Campaign"))]

func _start_campaign_level(level_data: Dictionary) -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null
	SoundManager.play_ui_click()
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game_node: Node = game_scene.instantiate()
	get_tree().root.add_child(game_node)
	game_node.configure_campaign(level_data)
	queue_free()

func _show_intel_overlay() -> void:
	var overlay := _overlay_panel("Tower Intel")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(14, 62)
	scroll.size = Vector2(452, 752)
	overlay.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(438, 0)
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	_intel_block(vbox, "Desktop Playbook", "Use Arrow or Ballista to trim lanes early, then pivot into Cannon or Flame on bends. Magic and Tesla are your anti-armor / anti-shield answers. Ice buys time, Poison stretches wave value.")
	_intel_block(vbox, "Wave Control", "Desktop tower defense is usually won by shaping a killzone. Stack two damage types on the same bend, hold one emergency power, and leave one tower slot flexible for the wave modifier.")
	_intel_block(vbox, "Map Intel", "Classic: balanced start.\nCrossroads: great for splash.\nDesert: faster lanes, value slows.\nSnow: control heavy routes.\nLava / Volcano: terrain damage punishes stalled enemies.\nEnchanted: magic pressure rewards burst.")
	_intel_block(vbox, "Boss Advice", "Boss Rush wants single-target towers first, then support. Save Fireball or Lightning for lane collapses and keep at least one long-range finisher online.")

func _intel_block(parent: VBoxContainer, title: String, body: String) -> void:
	var panel := _panel(Vector2.ZERO, Vector2(438, 108), Color(0.05, 0.08, 0.14, 0.92))
	panel.custom_minimum_size = Vector2(438, 108)
	parent.add_child(panel)

	var t := _label(panel, title, Vector2(12, 10), 15, Color(1.0, 0.88, 0.28))
	t.custom_minimum_size = Vector2(410, 18)
	var b := _label(panel, body, Vector2(12, 34), 12, Color(0.80, 0.88, 0.96))
	b.custom_minimum_size = Vector2(410, 64)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

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
		var level: int = SaveManager.get_skill_level(skill_id)
		var btn := _button(grid, "%s  Lv%d/%d\nCost %d" % [str(data.get("label", skill_id)), level, int(data.get("max", 0)), int(data.get("cost", 0))], Vector2.ZERO, Vector2(0, 70), Color(0.08, 0.12, 0.20))
		btn.custom_minimum_size = Vector2(214, 70)
		btn.disabled = level >= int(data.get("max", 0)) or SaveManager.get_diamonds() < int(data.get("cost", 0))
		btn.pressed.connect(_upgrade_skill.bind(skill_id, data))

func _upgrade_skill(skill_id: String, data: Dictionary) -> void:
	if SaveManager.spend_diamonds(int(data.get("cost", 0))):
		SaveManager.set_skill_level(skill_id, SaveManager.get_skill_level(skill_id) + 1)
		SaveManager.flush()
		SoundManager.play_place()
		_show_skill_tree_overlay()

func _show_achievements_overlay() -> void:
	var overlay := _overlay_panel("Achievements")
	var unlocked: int = 0
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
		var done: bool = SaveManager.is_achievement_unlocked(achievement["id"])
		var row_color: Color = Color(0.07, 0.18, 0.10) if done else Color(0.07, 0.08, 0.13)
		var row := _panel(Vector2.ZERO, Vector2(440, 58), row_color)
		row.custom_minimum_size = Vector2(440, 58)
		vbox.add_child(row)
		var text_color: Color = Color(0.95, 1.0, 0.95) if done else Color(0.56, 0.62, 0.74)
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
	var palettes: Array = GameData.get_palette_names()
	for idx in range(palettes.size()):
		var palette_name: String = str(palettes[idx])
		palette.add_item(palette_name, idx)
		if palette_name == GameData.current_palette:
			palette.selected = idx
	overlay.add_child(palette)
	palette.item_selected.connect(func(idx: int):
		GameData.set_palette(str(palettes[idx]))
		queue_redraw()
	)

	var music_row := HBoxContainer.new()
	music_row.position = Vector2(20, 224)
	music_row.custom_minimum_size = Vector2(390, 38)
	music_row.add_theme_constant_override("separation", 8)
	overlay.add_child(music_row)

	var menu_btn := _row_button("Menu")
	menu_btn.pressed.connect(func(): SoundManager.play_menu_music())
	music_row.add_child(menu_btn)

	var battle_btn := _row_button("Battle")
	battle_btn.pressed.connect(func(): SoundManager.play_battle_music())
	music_row.add_child(battle_btn)

	var victory_btn := _row_button("Victory")
	victory_btn.pressed.connect(func(): SoundManager.play_victory_music())
	music_row.add_child(victory_btn)

	var note := _label(overlay, "Audio now uses real WAV-backed music and SFX, and the front-end layout is split into Campaign / Skirmish / Endless / Boss Rush.", Vector2(20, 286), 13, Color(0.66, 0.76, 0.9))
	note.custom_minimum_size = Vector2(408, 56)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

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

func _get_next_campaign_level() -> Dictionary:
	for level_data in CampaignData.LEVELS:
		var level_id: int = int(level_data.get("id", 0))
		if CampaignData.is_unlocked(level_id) and not SaveManager.is_campaign_beaten(level_id):
			return level_data
	if not CampaignData.LEVELS.is_empty():
		return CampaignData.LEVELS[CampaignData.LEVELS.size() - 1]
	return {}

func _mode_name(mode_id: int) -> String:
	match mode_id:
		0:
			return "Easy Skirmish"
		1:
			return "Medium Skirmish"
		2:
			return "Hard Skirmish"
		3:
			return "Endless"
		4:
			return "Boss Rush"
		_:
			return "Skirmish"

func _mode_long_desc(mode_id: int) -> String:
	match mode_id:
		3:
			return "Infinite survival with scaling after wave 10. Great for chasing records and testing long-run tower builds."
		4:
			return "A desktop-style pressure mode with a boss every wave. Build for burst, backup lanes, and emergency power timing."
		_:
			return "Standard skirmish rules with pre-battle map selection and a clean difficulty split."

func _get_skirmish_desc(mode_id: int) -> String:
	for option in SKIRMISH_DIFFICULTIES:
		if int(option.get("id", -1)) == mode_id:
			return str(option.get("desc", "Skirmish"))
	return "Standard skirmish setup."

func _build_mode_brief(mode_id: int, map_type: int) -> String:
	var map_data: Dictionary = GameData.get_map(map_type)
	var lines: Array[String] = []
	lines.append("Map: %s" % str(map_data.get("name", "Classic")))
	lines.append("Terrain: %s" % _map_hazard_text(map_type))
	lines.append("Recommended towers: %s" % _map_recommendation(map_type))
	match mode_id:
		0:
			lines.append("Economy: 80 starting gold, low pressure, slower spawn curve.")
			lines.append("Use this to learn pathing, placement markers, and terrain zones.")
		1:
			lines.append("Economy: 50 starting gold, baseline wave pacing, balanced boss cadence.")
			lines.append("This is the closest fit to classic desktop tower defense rhythm.")
		2:
			lines.append("Economy: 30 starting gold, stronger enemies, faster scaling.")
			lines.append("Plan a real killbox early and keep one backup lane answer ready.")
		3:
			lines.append("Endless rules: infinite waves, scaling after wave 10, best record tracked.")
			lines.append("Open with stable income and pivot into long-range finishers for late waves.")
		4:
			lines.append("Boss Rush rules: boss every wave, bonus gold, no quiet rounds.")
			lines.append("Lean into burst towers, saved powers, and single-target upgrades.")
		_:
			lines.append("Balanced battle setup.")
	return "\n".join(lines)

func _map_hazard_text(map_type: int) -> String:
	match map_type:
		GameData.MapType.CLASSIC:
			return "Clean starter lanes with no major gimmick."
		GameData.MapType.VALLEY:
			return "Long approach lanes reward snipers and sustained damage."
		GameData.MapType.CROSSROADS:
			return "Intersections favor splash towers and overlap range."
		GameData.MapType.DESERT:
			return "Dune gusts speed enemies up in hot zones."
		GameData.MapType.SNOW:
			return "Frost zones naturally slow enemies."
		GameData.MapType.LAVA:
			return "Lava patches burn stalled enemies."
		GameData.MapType.ENCHANTED:
			return "Arcane wells pulse burst magic damage."
		GameData.MapType.VOLCANO:
			return "Heavy lava pressure punishes slow boss pushes."
		_:
			return "Balanced terrain."

func _map_recommendation(map_type: int) -> String:
	match map_type:
		GameData.MapType.CROSSROADS:
			return "Cannon, Flame, Tesla"
		GameData.MapType.DESERT:
			return "Ice, Poison, Ballista"
		GameData.MapType.SNOW:
			return "Cannon, Magic, Healer"
		GameData.MapType.LAVA, GameData.MapType.VOLCANO:
			return "Ballista, Magic, Healer"
		GameData.MapType.ENCHANTED:
			return "Magic, Tesla, Vortex"
		_:
			return "Arrow, Magic, Cannon"

func _label(parent: Node, text: String, pos: Vector2, font_size: int, color: Color) -> Label:
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

func _button(parent: Node, text: String, pos: Vector2, size: Vector2, color: Color = Color(0.08, 0.12, 0.20)) -> Button:
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
