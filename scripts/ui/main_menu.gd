extends Control

const SCREEN_SIZE := Vector2(480, 854)
const DIFFICULTY_OPTIONS := [
	{id=0, name="Easy", desc="More gold and lighter waves.", color=Color(0.16, 0.36, 0.20)},
	{id=1, name="Normal", desc="Balanced run with steady pressure.", color=Color(0.14, 0.18, 0.28)},
	{id=2, name="Hard", desc="Lean economy and sharper scaling.", color=Color(0.32, 0.12, 0.12)},
]
const EXTRA_MODES := [
	{id="boss_rush", title="Boss Rush", body="Every wave is a boss cycle with support pressure.", color=Color(0.34, 0.14, 0.10)},
	{id="boss_gauntlet", title="Boss Gauntlet", body="Pure duel format. One boss every wave, no minions.", color=Color(0.18, 0.10, 0.05)},
	{id="daily", title="Daily Challenge", body="Fixed daily modifier rotation with leaderboard-style consistency.", color=Color(0.10, 0.16, 0.28)},
	{id="randomizer", title="Randomizer", body="Scrambled costs, cooldowns, scaling, and stat balance each run.", color=Color(0.26, 0.18, 0.08)},
]
const PRESTIGE_SKILL_IDS := [
	"ice_power",
	"ability_cd",
	"sell_bonus",
	"resist_pierce",
	"wave_modifier",
	"prestige_gold",
]

var _header_stats: Label
var _campaign_status: Label
var _endless_summary: Label
var _hero_high_score_value: Label
var _hero_best_wave_value: Label
var _hero_endless_value: Label
var _continue_btn: Button
var _overlay: Control = null
var _anim_time: float = 0.0
var _stars: Array = []
var _selected_endless_difficulty: int = 1
var _selected_campaign_map: int = GameData.MapType.CLASSIC
var _selected_endless_map: int = GameData.MapType.CLASSIC
var _selected_extra_mode: String = "boss_gauntlet"
var _selected_extra_map: int = GameData.MapType.CLASSIC

func _ready() -> void:
	var saved_palette := SaveManager.get_string("ui_palette", GameData.current_palette)
	if saved_palette != "":
		GameData.set_palette(saved_palette)
	_generate_stars()
	_build_ui()
	_refresh_header_stats()
	_refresh_campaign_status()
	_refresh_endless_summary()
	_refresh_continue_button()
	SoundManager.play_menu_music()

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()

func _draw() -> void:
	var sky_top := Color(0.02, 0.08, 0.14)
	var sky_mid := Color(0.05, 0.12, 0.22)
	var sky_bottom := Color(0.02, 0.03, 0.08)
	for y in range(0, 854, 3):
		var t := float(y) / 854.0
		var mix_a := sky_top.lerp(sky_mid, minf(t * 1.4, 1.0))
		draw_rect(Rect2(0, y, 480, 3), mix_a.lerp(sky_bottom, pow(t, 1.8)))

	draw_circle(Vector2(392, 108), 82.0, Color(0.24, 0.64, 0.86, 0.10))
	draw_circle(Vector2(392, 108), 52.0, Color(1.0, 0.78, 0.34, 0.18))
	draw_circle(Vector2(408, 120), 120.0, Color(0.12, 0.28, 0.42, 0.06))

	draw_colored_polygon([
		Vector2(0, 274),
		Vector2(84, 220),
		Vector2(142, 250),
		Vector2(222, 188),
		Vector2(300, 250),
		Vector2(366, 220),
		Vector2(434, 250),
		Vector2(480, 226),
		Vector2(480, 854),
		Vector2(0, 854),
	], Color(0.03, 0.09, 0.14, 0.90))

	draw_colored_polygon([
		Vector2(0, 364),
		Vector2(76, 320),
		Vector2(148, 366),
		Vector2(238, 300),
		Vector2(320, 356),
		Vector2(392, 330),
		Vector2(480, 372),
		Vector2(480, 854),
		Vector2(0, 854),
	], Color(0.04, 0.07, 0.11, 0.98))

	draw_rect(Rect2(0, 594, 480, 260), Color(0.01, 0.02, 0.05, 0.18))
	draw_rect(Rect2(0, 0, 480, 170), Color(0.04, 0.10, 0.16, 0.08))

	for star in _stars:
		var glow := 0.16 + 0.55 * (0.5 + 0.5 * sin(_anim_time * star["speed"] + star["phase"]))
		draw_circle(star["pos"], star["size"], Color(0.74, 0.88, 1.0, glow))

func _generate_stars() -> void:
	_stars.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77117
	for _i in range(96):
		_stars.append({
			"pos": Vector2(rng.randf_range(0.0, 480.0), rng.randf_range(0.0, 380.0)),
			"size": rng.randf_range(0.7, 2.2),
			"speed": rng.randf_range(0.3, 1.4),
			"phase": rng.randf() * TAU,
		})

func _build_ui() -> void:
	_build_hero_panel()
	_build_campaign_card()
	_build_endless_card()
	_build_arcade_card()
	_build_utility_strip()

	var footer := _label(self, "Diamonds %d  |  Games %d  |  Boss Rush %d" % [
		SaveManager.get_diamonds(),
		SaveManager.get_stat("lifetime_games"),
		SaveManager.get_boss_rush_record(),
	], Vector2(0, 824), 11, Color(0.46, 0.60, 0.76))
	footer.custom_minimum_size = Vector2(480, 20)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_hero_panel() -> void:
	var panel := _panel(Vector2(14, 14), Vector2(452, 220), Color(0.03, 0.08, 0.13, 0.92), Color(0.40, 0.68, 0.88, 0.38), 24)
	add_child(panel)
	_add_panel_glow(panel, Color(0.30, 0.64, 0.90, 0.10), Color(1.0, 0.76, 0.28, 0.08))

	var badge := _panel(Vector2(18, 16), Vector2(124, 28), Color(0.08, 0.16, 0.24, 0.92), Color(0.56, 0.84, 0.98, 0.26), 14)
	panel.add_child(badge)
	var badge_text := _label(badge, "KOTLIN CANON", Vector2(0, 5), 11, Color(0.82, 0.94, 1.0))
	badge_text.custom_minimum_size = Vector2(124, 18)
	badge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var eyebrow := _label(panel, "CANONICAL PORT", Vector2(18, 56), 13, Color(0.96, 0.84, 0.42))
	eyebrow.custom_minimum_size = Vector2(210, 18)

	var title_shadow := _label(panel, "TOWER DEFENSE", Vector2(18, 70), 38, Color(0, 0, 0, 0.38))
	title_shadow.position += Vector2(2, 3)
	title_shadow.custom_minimum_size = Vector2(286, 44)
	var title := _label(panel, "TOWER DEFENSE", Vector2(18, 68), 38, Color(0.92, 0.98, 1.0))
	title.custom_minimum_size = Vector2(286, 44)

	var subtitle := _label(panel, "Match the Kotlin campaign, powers, and progression with a cleaner cross-engine port.", Vector2(18, 116), 13, Color(0.70, 0.84, 0.95))
	subtitle.custom_minimum_size = Vector2(244, 46)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_header_stats = _label(panel, "", Vector2(18, 164), 12, Color(0.76, 0.88, 0.98))
	_header_stats.custom_minimum_size = Vector2(250, 18)

	var orbit_card := _panel(Vector2(286, 22), Vector2(148, 176), Color(0.05, 0.10, 0.17, 0.82), Color(0.42, 0.68, 0.88, 0.22), 22)
	panel.add_child(orbit_card)
	var orbit_label := _label(orbit_card, "GAME FLOW", Vector2(0, 18), 12, Color(0.82, 0.92, 1.0))
	orbit_label.custom_minimum_size = Vector2(148, 18)
	orbit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var orbit_body := _label(orbit_card, "Campaign\nEndless\nArcade", Vector2(0, 48), 16, Color(0.90, 0.96, 1.0))
	orbit_body.custom_minimum_size = Vector2(148, 72)
	orbit_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var orbit_hint := _label(orbit_card, "Select a mode card below", Vector2(0, 136), 11, Color(0.66, 0.80, 0.94))
	orbit_hint.custom_minimum_size = Vector2(148, 16)
	orbit_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var stat_y := 188
	_hero_high_score_value = _stat_chip(panel, "HIGH SCORE", Vector2(18, stat_y), Vector2(128, 22), Color(0.10, 0.16, 0.24, 0.94), Color(0.78, 0.90, 1.0), Color(1.0, 0.86, 0.34))
	_hero_best_wave_value = _stat_chip(panel, "BEST WAVE", Vector2(162, stat_y), Vector2(128, 22), Color(0.08, 0.14, 0.20, 0.94), Color(0.74, 0.88, 0.98), Color(0.84, 0.94, 1.0))
	_hero_endless_value = _stat_chip(panel, "ENDLESS", Vector2(306, stat_y), Vector2(128, 22), Color(0.10, 0.14, 0.20, 0.94), Color(0.74, 0.88, 0.98), Color(0.82, 1.0, 0.90))

func _build_campaign_card() -> void:
	var card := _panel(Vector2(18, 248), Vector2(444, 166), Color(0.04, 0.06, 0.11, 0.95), Color(0.84, 0.66, 0.24, 0.34), 22)
	add_child(card)
	_add_panel_glow(card, Color(0.94, 0.74, 0.28, 0.06), Color(0.20, 0.10, 0.04, 0.08))
	_add_card_cap(card, "PROGRESSION", Color(1.0, 0.88, 0.34), Vector2(18, 14), 110.0)

	_label(card, "Campaign", Vector2(18, 42), 24, Color(1.0, 0.90, 0.36))
	var sub := _label(card, "Clear stages, unlock the next mission, and chase flawless clears.", Vector2(18, 74), 12, Color(0.80, 0.88, 0.96))
	sub.custom_minimum_size = Vector2(272, 40)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_campaign_status = _label(card, "", Vector2(18, 118), 13, Color(0.74, 0.84, 0.96))
	_campaign_status.custom_minimum_size = Vector2(272, 34)
	_campaign_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var chip := _panel(Vector2(310, 18), Vector2(116, 60), Color(0.10, 0.10, 0.18, 0.94), Color(0.56, 0.76, 0.94, 0.22), 18)
	card.add_child(chip)
	var chip_title := _label(chip, "Flawless", Vector2(0, 10), 11, Color(0.72, 0.84, 0.96))
	chip_title.custom_minimum_size = Vector2(116, 16)
	chip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var chip_body := _label(chip, "%d / %d" % [_get_flawless_campaign_count(), _campaign_total_levels()], Vector2(0, 28), 18, Color(0.98, 0.90, 0.46))
	chip_body.custom_minimum_size = Vector2(116, 20)
	chip_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var campaign_btn := _button(card, "OPEN CAMPAIGN", Vector2(18, 122), Vector2(408, 32), Color(0.26, 0.20, 0.06))
	campaign_btn.add_theme_font_size_override("font_size", 16)
	campaign_btn.pressed.connect(_on_campaign)

func _build_endless_card() -> void:
	var card := _panel(Vector2(18, 430), Vector2(444, 166), Color(0.04, 0.06, 0.11, 0.95), Color(0.36, 0.64, 0.88, 0.34), 22)
	add_child(card)
	_add_panel_glow(card, Color(0.28, 0.62, 0.92, 0.06), Color(0.04, 0.08, 0.14, 0.10))
	_add_card_cap(card, "SCORE CHASE", Color(0.84, 0.94, 1.0), Vector2(18, 14), 112.0)

	_label(card, "Endless", Vector2(18, 42), 24, Color(0.86, 0.94, 1.0))
	var sub := _label(card, "Choose map and difficulty, then push your best wave record.", Vector2(18, 74), 12, Color(0.80, 0.88, 0.96))
	sub.custom_minimum_size = Vector2(272, 40)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_endless_summary = _label(card, "", Vector2(18, 118), 13, Color(0.74, 0.84, 0.96))
	_endless_summary.custom_minimum_size = Vector2(272, 20)
	_endless_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var chip := _panel(Vector2(310, 18), Vector2(116, 60), Color(0.08, 0.10, 0.18, 0.94), Color(0.48, 0.76, 0.96, 0.22), 18)
	card.add_child(chip)
	var chip_title := _label(chip, "Best Run", Vector2(0, 10), 11, Color(0.72, 0.84, 0.96))
	chip_title.custom_minimum_size = Vector2(116, 16)
	chip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var chip_body := _label(chip, "Wave %d" % SaveManager.get_endless_record(), Vector2(0, 28), 18, Color(0.84, 0.94, 1.0))
	chip_body.custom_minimum_size = Vector2(116, 20)
	chip_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var endless_btn := _button(card, "CONFIGURE ENDLESS", Vector2(18, 122), Vector2(408, 32), Color(0.10, 0.18, 0.32))
	endless_btn.add_theme_font_size_override("font_size", 16)
	endless_btn.pressed.connect(_show_endless_overlay)

func _build_arcade_card() -> void:
	var card := _panel(Vector2(18, 612), Vector2(444, 166), Color(0.04, 0.06, 0.11, 0.95), Color(0.78, 0.44, 0.30, 0.34), 22)
	add_child(card)
	_add_panel_glow(card, Color(0.86, 0.46, 0.28, 0.06), Color(0.16, 0.06, 0.04, 0.10))
	_add_card_cap(card, "ARCADE", Color(0.98, 0.72, 0.44), Vector2(18, 14), 94.0)

	_label(card, "Arcade Modes", Vector2(18, 42), 24, Color(0.98, 0.86, 0.70))
	var sub := _label(card, "Boss Rush, Gauntlet, Daily Challenge, and Randomizer in one setup flow.", Vector2(18, 74), 12, Color(0.84, 0.90, 0.96))
	sub.custom_minimum_size = Vector2(272, 40)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var chip := _panel(Vector2(310, 18), Vector2(116, 60), Color(0.12, 0.08, 0.12, 0.94), Color(0.74, 0.52, 0.42, 0.22), 18)
	card.add_child(chip)
	var chip_title := _label(chip, "Selected", Vector2(0, 10), 11, Color(0.86, 0.86, 0.94))
	chip_title.custom_minimum_size = Vector2(116, 16)
	chip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var chip_body := _label(chip, _mode_name(_selected_extra_mode), Vector2(0, 28), 16, Color(1.0, 0.84, 0.58))
	chip_body.custom_minimum_size = Vector2(116, 20)
	chip_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var arcade_btn := _button(card, "CONFIGURE ARCADE", Vector2(18, 122), Vector2(408, 32), Color(0.22, 0.12, 0.08))
	arcade_btn.add_theme_font_size_override("font_size", 16)
	arcade_btn.pressed.connect(_show_extra_modes_overlay)

func _build_utility_strip() -> void:
	var strip := HBoxContainer.new()
	strip.position = Vector2(18, 786)
	strip.custom_minimum_size = Vector2(444, 34)
	strip.add_theme_constant_override("separation", 6)
	add_child(strip)

	for data in [
		{"label": "Continue", "method": "_on_continue", "color": Color(0.10, 0.20, 0.14)},
		{"label": "Skills", "method": "_on_skill_tree", "color": Color(0.08, 0.12, 0.20)},
		{"label": "Trophies", "method": "_on_achievements", "color": Color(0.10, 0.16, 0.12)},
		{"label": "Stats", "method": "_on_stats", "color": Color(0.10, 0.14, 0.20)},
		{"label": "Help", "method": "_on_help", "color": Color(0.12, 0.14, 0.18)},
		{"label": "Settings", "method": "_on_settings", "color": Color(0.08, 0.10, 0.16)},
	]:
		var btn := Button.new()
		btn.text = data["label"]
		btn.custom_minimum_size = Vector2(0, 34)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.clip_text = true
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0))
		btn.add_theme_stylebox_override("normal", _button_style(data["color"], 12))
		btn.add_theme_stylebox_override("hover", _button_style(data["color"].lightened(0.10), 12, Color(0.72, 0.86, 0.98, 0.40), 2))
		btn.add_theme_stylebox_override("pressed", _button_style(data["color"].darkened(0.12), 12))
		btn.pressed.connect(Callable(self, data["method"]))
		strip.add_child(btn)
		if data["method"] == "_on_continue":
			_continue_btn = btn

func _refresh_header_stats() -> void:
	var high_score := SaveManager.get_high_score()
	var best_wave := SaveManager.get_high_wave()
	var endless := SaveManager.get_endless_record()
	_header_stats.text = "Campaign %d / %d  |  Boss Rush %d" % [
		CampaignData.get_beaten_count(),
		_campaign_total_levels(),
		SaveManager.get_boss_rush_record(),
	]
	_hero_high_score_value.text = str(high_score)
	_hero_best_wave_value.text = str(best_wave)
	_hero_endless_value.text = "W%s" % endless
	_refresh_continue_button()

func _refresh_campaign_status() -> void:
	var next := _next_campaign_level()
	if next.is_empty():
		_campaign_status.text = "Campaign cleared. Replay on different maps or chase flawless clears."
		return
	_campaign_status.text = "Next level %02d: %s\n%s" % [
		int(next.get("id", 1)),
		str(next.get("title", "Campaign")),
		_campaign_constraints_text(next),
	]

func _refresh_endless_summary() -> void:
	if _selected_endless_difficulty == 2 and not _is_hard_unlocked():
		_selected_endless_difficulty = 1
	var difficulty_name := str(DIFFICULTY_OPTIONS[_selected_endless_difficulty]["name"])
	var map_data := GameData.get_map(_selected_endless_map)
	_endless_summary.text = "Ready: %s  |  %s %s" % [
		difficulty_name,
		map_data.get("emoji", ""),
		map_data.get("name", "Classic"),
	]

func _is_hard_unlocked() -> bool:
	return SaveManager.get_bool("normal_beaten", false)

func _next_campaign_level() -> Dictionary:
	for level_data in CampaignData.LEVELS:
		var level_id := int(level_data.get("id", 0))
		if CampaignData.is_unlocked(level_id) and not SaveManager.is_campaign_beaten(level_id):
			return level_data
	return CampaignData.LEVELS[CampaignData.LEVELS.size() - 1] if not CampaignData.LEVELS.is_empty() else {}

func _get_flawless_campaign_count() -> int:
	var total := 0
	for i in range(1, _campaign_total_levels() + 1):
		if SaveManager.is_campaign_full_hp(i):
			total += 1
	return total

func _campaign_total_levels() -> int:
	return maxi(1, CampaignData.get_total_levels())

func _on_campaign() -> void:
	SoundManager.play_ui_click()
	_show_campaign_overlay()

func _show_endless_overlay() -> void:
	SoundManager.play_ui_click()
	var content := _overlay_panel("Endless Setup", "Select difficulty and map, then start the run.")
	_build_mode_difficulty_picker(content)
	_build_map_picker(content, 228, _selected_endless_map, _set_endless_map)

	var summary := _label(content, "Selected: %s on %s" % [
		DIFFICULTY_OPTIONS[_selected_endless_difficulty]["name"],
		GameData.get_map(_selected_endless_map).get("name", "Classic"),
	], Vector2(22, 692), 14, Color(0.82, 0.92, 1.0))
	summary.custom_minimum_size = Vector2(404, 18)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var start_btn := _button(content, "START ENDLESS", Vector2(22, 734), Vector2(412, 52), Color(0.10, 0.20, 0.34))
	start_btn.add_theme_font_size_override("font_size", 22)
	start_btn.pressed.connect(_start_endless_selected)

func _build_mode_difficulty_picker(content: Control) -> void:
	_label(content, "Difficulty", Vector2(22, 116), 16, Color(0.95, 0.90, 0.50))
	for idx in range(DIFFICULTY_OPTIONS.size()):
		var data: Dictionary = DIFFICULTY_OPTIONS[idx]
		var hard_locked := idx == 2 and not _is_hard_unlocked()
		var selected := idx == _selected_endless_difficulty
		var btn := _button(
			content,
			"%s%s" % [data["name"], " (Locked)" if hard_locked else ""],
			Vector2(22 + idx * 138, 144),
			Vector2(128, 46),
			data["color"] if selected and not hard_locked else data["color"].darkened(0.18)
		)
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_stylebox_override("normal", _button_style(
			data["color"] if selected and not hard_locked else data["color"].darkened(0.18),
			18,
			Color(0.94, 0.80, 0.30, 0.70) if selected and not hard_locked else Color(0.42, 0.56, 0.72, 0.24),
			2 if selected and not hard_locked else 1
		))
		btn.add_theme_stylebox_override("hover", _button_style(
			data["color"].lightened(0.10),
			18,
			Color(0.70, 0.84, 0.98, 0.38),
			2 if selected and not hard_locked else 1
		))
		btn.disabled = hard_locked
		btn.pressed.connect(_set_endless_difficulty.bind(idx))
	var diff_desc := _label(content, str(DIFFICULTY_OPTIONS[_selected_endless_difficulty]["desc"]), Vector2(22, 196), 12, Color(0.70, 0.84, 0.96))
	diff_desc.custom_minimum_size = Vector2(404, 26)
	diff_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_map_picker(content: Control, start_y: float, selected_map: int, callable: Callable) -> void:
	_label(content, "Map", Vector2(22, start_y), 16, Color(0.95, 0.90, 0.50))
	var map_types: Array = GameData.get_canonical_map_types()
	for index in range(map_types.size()):
		var map_id: int = map_types[index]
		var column := index % 2
		var row := index / 2
		var map_data := GameData.get_map(map_id)
		var selected := map_id == selected_map
		var color: Color = map_data.get("bg_color", Color(0.08, 0.10, 0.16))
		var btn := _button(
			content,
			"%s  %s" % [map_data.get("emoji", ""), map_data.get("name", "Map")],
			Vector2(22 + column * 206, start_y + 28 + row * 56),
			Vector2(196, 46),
			color.lightened(0.10) if selected else color.darkened(0.08)
		)
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_stylebox_override("normal", _button_style(
			color.lightened(0.10) if selected else color.darkened(0.08),
			16,
			Color(0.94, 0.80, 0.30, 0.65) if selected else Color(0.42, 0.56, 0.72, 0.24),
			2 if selected else 1
		))
		btn.pressed.connect(callable.bind(map_id))

func _set_endless_difficulty(level: int) -> void:
	if level == 2 and not _is_hard_unlocked():
		return
	_selected_endless_difficulty = level
	_refresh_endless_summary()
	_show_endless_overlay()

func _set_endless_map(map_id: int) -> void:
	_selected_endless_map = map_id
	_refresh_endless_summary()
	_show_endless_overlay()

func _start_endless_selected() -> void:
	_close_overlay()
	SoundManager.play_ui_click()
	var scene: PackedScene = load("res://scenes/game.tscn")
	var node: Node = scene.instantiate()
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	node.configure_endless(_selected_endless_difficulty, _selected_endless_map)
	queue_free()

func _show_extra_modes_overlay() -> void:
	SoundManager.play_ui_click()
	var content := _overlay_panel("Extra Modes", "Boss modes plus daily and randomizer variants in one setup panel.")
	_label(content, "Mode", Vector2(22, 116), 16, Color(0.95, 0.90, 0.50))
	for idx in range(EXTRA_MODES.size()):
		var data: Dictionary = EXTRA_MODES[idx]
		var selected := str(data["id"]) == _selected_extra_mode
		var column := idx % 2
		var row := idx / 2
		var btn := _button(
			content,
			data["title"],
			Vector2(22 + column * 206, 144 + row * 56),
			Vector2(196, 48),
			data["color"] if selected else data["color"].darkened(0.16)
		)
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_stylebox_override("normal", _button_style(
			data["color"] if selected else data["color"].darkened(0.16),
			18,
			Color(0.94, 0.80, 0.30, 0.65) if selected else Color(0.42, 0.56, 0.72, 0.24),
			2 if selected else 1
		))
		btn.pressed.connect(_set_extra_mode.bind(data["id"]))
	var mode_desc := _label(content, str(_mode_body(_selected_extra_mode)), Vector2(22, 260), 12, Color(0.74, 0.86, 0.96))
	mode_desc.custom_minimum_size = Vector2(404, 26)
	mode_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_build_map_picker(content, 298, _selected_extra_map, _set_extra_map)

	var summary := _label(content, "Selected: %s on %s" % [
		_mode_name(_selected_extra_mode),
		GameData.get_map(_selected_extra_map).get("name", "Classic"),
	], Vector2(22, 692), 14, Color(0.82, 0.92, 1.0))
	summary.custom_minimum_size = Vector2(404, 18)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var start_btn := _button(content, "START %s" % _mode_name(_selected_extra_mode).to_upper(), Vector2(22, 734), Vector2(412, 52), Color(0.18, 0.12, 0.08))
	start_btn.add_theme_font_size_override("font_size", 20)
	start_btn.pressed.connect(_start_extra_mode)

func _set_extra_mode(mode_id: String) -> void:
	_selected_extra_mode = str(mode_id)
	_show_extra_modes_overlay()

func _set_extra_map(map_id: int) -> void:
	_selected_extra_map = map_id
	_show_extra_modes_overlay()

func _mode_name(mode_id: String) -> String:
	for data in EXTRA_MODES:
		if str(data["id"]) == mode_id:
			return str(data["title"])
	return "Mode"

func _mode_body(mode_id: String) -> String:
	for data in EXTRA_MODES:
		if str(data["id"]) == mode_id:
			return str(data["body"])
	return ""

func _start_extra_mode() -> void:
	_close_overlay()
	SoundManager.play_ui_click()
	var scene: PackedScene = load("res://scenes/game.tscn")
	var node: Node = scene.instantiate()
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	match _selected_extra_mode:
		"boss_rush":
			node.configure(4, _selected_extra_map)
		"boss_gauntlet":
			node.configure(5, _selected_extra_map)
		"daily":
			if node.has_method("configure_daily_challenge"):
				node.configure_daily_challenge(_selected_extra_map)
			else:
				node.configure(1, _selected_extra_map)
		"randomizer":
			if node.has_method("configure_randomizer"):
				node.configure_randomizer(_selected_extra_map)
			else:
				node.configure(1, _selected_extra_map)
		_:
			node.configure(4, _selected_extra_map)
	queue_free()

func _on_skill_tree() -> void:
	SoundManager.play_ui_click()
	_show_skill_tree_overlay()

func _on_continue() -> void:
	if not SaveManager.get_bool("save_has_run", false):
		return
	SoundManager.play_ui_click()
	var scene: PackedScene = load("res://scenes/game.tscn")
	var node: Node = scene.instantiate()
	get_tree().root.add_child(node)
	var loaded := false
	if node.has_method("configure_continue_saved"):
		loaded = node.configure_continue_saved()
	if loaded:
		get_tree().current_scene = node
		queue_free()
	else:
		node.queue_free()
		_refresh_continue_button()

func _on_achievements() -> void:
	SoundManager.play_ui_click()
	_show_achievements_overlay()

func _on_stats() -> void:
	SoundManager.play_ui_click()
	_show_stats_overlay()

func _on_help() -> void:
	SoundManager.play_ui_click()
	_show_help_overlay()

func _on_settings() -> void:
	SoundManager.play_ui_click()
	_show_settings_overlay()

func _refresh_continue_button() -> void:
	if _continue_btn == null:
		return
	var has_save := SaveManager.get_bool("save_has_run", false)
	_continue_btn.disabled = not has_save
	_continue_btn.text = "Continue" if has_save else "No Save"

func _show_campaign_overlay() -> void:
	var content := _overlay_panel("Campaign", "Choose an unlocked stage, pick a map, and push Kotlin campaign progression.")

	var summary := _label(content, "Progress %d / %d  |  Flawless %d" % [CampaignData.get_beaten_count(), _campaign_total_levels(), _get_flawless_campaign_count()], Vector2(22, 96), 15, Color(0.90, 0.96, 1.0))
	summary.custom_minimum_size = Vector2(380, 24)
	var legend := _label(content, "Map selection stays separate from level selection, matching the Kotlin flow.", Vector2(22, 120), 11, Color(0.64, 0.78, 0.92))
	legend.custom_minimum_size = Vector2(404, 18)
	_build_map_picker(content, 146, _selected_campaign_map, _set_campaign_map)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(18, 300)
	scroll.size = Vector2(420, 482)
	content.add_child(scroll)

	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(402, 0)
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	for level_data in CampaignData.LEVELS:
		var level_id := int(level_data.get("id", 0))
		var unlocked := CampaignData.is_unlocked(level_id)
		var beaten := SaveManager.is_campaign_beaten(level_id)
		var flawless := SaveManager.is_campaign_full_hp(level_id)
		var row := _panel(Vector2.ZERO, Vector2(402, 98), Color(0.06, 0.08, 0.14, 0.94), Color(0.42, 0.58, 0.78, 0.20), 16)
		row.custom_minimum_size = Vector2(402, 98)
		list.add_child(row)
		var badge := _panel(Vector2(8, 10), Vector2(56, 64), Color(0.08, 0.12, 0.20, 0.96), Color(0.50, 0.66, 0.84, 0.28), 12)
		row.add_child(badge)
		var badge_title := _label(badge, "%02d" % level_id, Vector2(0, 8), 20, Color(0.90, 0.96, 1.0))
		badge_title.custom_minimum_size = Vector2(56, 22)
		badge_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var badge_flawless := _label(badge, "FL" if flawless else "--", Vector2(0, 38), 11, Color(1.0, 0.88, 0.48))
		badge_flawless.custom_minimum_size = Vector2(56, 14)
		badge_flawless.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var title := _label(row, "%s  %s" % [level_data.get("emoji", ""), level_data.get("title", "Campaign")], Vector2(74, 10), 15, Color(0.92, 0.98, 1.0))
		title.custom_minimum_size = Vector2(224, 18)
		title.clip_text = true
		var description := _label(row, str(level_data.get("description", "")), Vector2(74, 29), 10, Color(0.70, 0.82, 0.95))
		description.custom_minimum_size = Vector2(224, 14)
		description.clip_text = true

		var status_line := "Locked"
		if unlocked:
			status_line = "Cleared" if beaten else "Unlocked"
		var target_wave := int(level_data.get("target_wave", 0))
		var meta := _label(row, "Wave %d  |  %s" % [target_wave, status_line], Vector2(74, 48), 11, Color(0.68, 0.82, 0.96))
		meta.custom_minimum_size = Vector2(224, 14)
		meta.clip_text = true

		var tags := _campaign_constraint_tokens(level_data)
		var tags_text := "Tags: " + (", ".join(tags) if not tags.is_empty() else "Standard")
		var constraints := _label(row, tags_text, Vector2(74, 67), 10, Color(0.58, 0.72, 0.90))
		constraints.custom_minimum_size = Vector2(224, 14)
		constraints.clip_text = true

		var row_color := _campaign_row_color(level_data, beaten)
		var row_btn := _button(row, "PLAY" if unlocked else "LOCKED", Vector2(306, 27), Vector2(88, 44), row_color)
		row_btn.add_theme_font_size_override("font_size", 14)
		row_btn.disabled = not unlocked
		if unlocked:
			row_btn.pressed.connect(_start_campaign_level.bind(level_data))

func _campaign_constraint_tokens(level_data: Dictionary) -> Array:
	var tokens: Array = []
	if not bool(level_data.get("upgrades", true)):
		tokens.append("NO UPGRADES")
	return tokens

func _campaign_constraints_text(level_data: Dictionary) -> String:
	var tokens := _campaign_constraint_tokens(level_data)
	return "Constraints: " + (", ".join(tokens) if not tokens.is_empty() else "Standard")

func _campaign_row_color(level_data: Dictionary, beaten: bool) -> Color:
	var color := Color(0.08, 0.18, 0.12) if beaten else Color(0.08, 0.10, 0.18)
	return color

func _start_campaign_level(level_data: Dictionary) -> void:
	_close_overlay()
	SoundManager.play_ui_click()
	var scene: PackedScene = load("res://scenes/game.tscn")
	var node: Node = scene.instantiate()
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	node.configure_campaign(level_data, _selected_campaign_map)
	queue_free()

func _set_campaign_map(map_id: int) -> void:
	_selected_campaign_map = map_id

func _show_skill_tree_overlay() -> void:
	var content := _overlay_panel("Skill Tree", "Spend diamonds on permanent upgrades. Prestige unlocks Page 2 skills.")
	var diamonds := SaveManager.get_diamonds()
	var prestige_level := SaveManager.get_prestige_count()
	_label(content, "Diamonds: %d  |  Prestige: %d" % [diamonds, prestige_level], Vector2(22, 96), 16, Color(0.78, 0.92, 1.0))

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(18, 132)
	scroll.size = Vector2(420, 650)
	content.add_child(scroll)

	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(402, 0)
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	var skill_ids: Array = GameData.SKILLS.keys()
	skill_ids.sort()
	var page1_ids: Array = []
	var page2_ids: Array = []
	for raw_id in skill_ids:
		var skill_id := str(raw_id)
		if _is_prestige_skill(skill_id):
			page2_ids.append(skill_id)
		else:
			page1_ids.append(skill_id)

	var page1_header := Label.new()
	page1_header.text = "Page 1 - Core Skills"
	page1_header.custom_minimum_size = Vector2(402, 26)
	page1_header.add_theme_font_size_override("font_size", 16)
	page1_header.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	list.add_child(page1_header)

	for skill_id in page1_ids:
		var data: Dictionary = GameData.SKILLS[skill_id]
		var level := SaveManager.get_skill_level(skill_id)
		var cost := _skill_upgrade_cost(skill_id, data)
		var btn := _button(
			list,
			"%s\nLv %d/%d   Cost %d\n%s" % [data["label"], level, data["max"], cost, data["desc"]],
			Vector2.ZERO,
			Vector2(0, 92),
			Color(0.08, 0.12, 0.20)
		)
		btn.custom_minimum_size = Vector2(402, 92)
		btn.disabled = level >= int(data["max"]) or diamonds < cost
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(_upgrade_skill.bind(skill_id, data))

	var all_page1_maxed := true
	for skill_id in page1_ids:
		var data: Dictionary = GameData.SKILLS[skill_id]
		if SaveManager.get_skill_level(skill_id) < int(data.get("max", 1)):
			all_page1_maxed = false
			break
	var prestige_cost := 50 + prestige_level * 30
	var can_prestige := all_page1_maxed and diamonds >= prestige_cost
	var prestige_text := "PRESTIGE (%d diamonds)" % prestige_cost
	if not all_page1_maxed:
		prestige_text = "PRESTIGE LOCKED (max all Page 1 skills)"
	elif diamonds < prestige_cost:
		prestige_text = "PRESTIGE (%d diamonds needed)" % prestige_cost
	var prestige_btn := _button(list, prestige_text, Vector2.ZERO, Vector2(0, 48), Color(0.24, 0.18, 0.08))
	prestige_btn.custom_minimum_size = Vector2(402, 48)
	prestige_btn.add_theme_font_size_override("font_size", 13)
	prestige_btn.disabled = not can_prestige
	prestige_btn.pressed.connect(_on_prestige.bind(prestige_cost, all_page1_maxed))

	var page2_header := Label.new()
	page2_header.text = "Page 2 - Prestige Skills"
	page2_header.custom_minimum_size = Vector2(402, 26)
	page2_header.add_theme_font_size_override("font_size", 16)
	page2_header.add_theme_color_override("font_color", Color(0.90, 0.84, 0.50))
	list.add_child(page2_header)

	if prestige_level < 1:
		var locked := Label.new()
		locked.text = "Prestige once to unlock Page 2."
		locked.custom_minimum_size = Vector2(402, 34)
		locked.add_theme_font_size_override("font_size", 13)
		locked.add_theme_color_override("font_color", Color(0.62, 0.70, 0.80))
		list.add_child(locked)
	else:
		for skill_id in page2_ids:
			var data: Dictionary = GameData.SKILLS[skill_id]
			var level := SaveManager.get_skill_level(skill_id)
			var cost := _skill_upgrade_cost(skill_id, data)
			var btn := _button(
				list,
				"%s\nLv %d/%d   Cost %d\n%s" % [data["label"], level, data["max"], cost, data["desc"]],
				Vector2.ZERO,
				Vector2(0, 92),
				Color(0.16, 0.12, 0.20)
			)
			btn.custom_minimum_size = Vector2(402, 92)
			btn.disabled = level >= int(data["max"]) or diamonds < cost
			btn.add_theme_font_size_override("font_size", 12)
			btn.pressed.connect(_upgrade_skill.bind(skill_id, data))

func _upgrade_skill(skill_id: String, data: Dictionary) -> void:
	if _is_prestige_skill(skill_id) and SaveManager.get_prestige_count() < 1:
		return
	var cost := _skill_upgrade_cost(skill_id, data)
	if SaveManager.spend_diamonds(cost):
		SaveManager.set_skill_level(skill_id, SaveManager.get_skill_level(skill_id) + 1)
		SaveManager.flush()
		SoundManager.play_place()
		_show_skill_tree_overlay()

func _skill_upgrade_cost(skill_id: String, data: Dictionary) -> int:
	var level := SaveManager.get_skill_level(skill_id)
	var base_cost := int(data.get("base_cost", data.get("cost", 1)))
	var step_cost := int(data.get("step_cost", 0))
	return max(0, base_cost + level * step_cost)

func _is_prestige_skill(skill_id: String) -> bool:
	return skill_id in PRESTIGE_SKILL_IDS

func _on_prestige(cost: int, all_page1_maxed: bool) -> void:
	if not all_page1_maxed:
		return
	if not SaveManager.spend_diamonds(cost):
		return
	SaveManager.do_prestige()
	AchievementManager.on_prestige()
	SaveManager.flush()
	SoundManager.play_victory_stinger()
	_show_skill_tree_overlay()

func _show_achievements_overlay() -> void:
	var content := _overlay_panel("Trophies", "A clean list of milestones unlocked across the whole game.")
	var unlocked := 0
	for achievement in AchievementManager.ACHIEVEMENTS:
		if SaveManager.is_achievement_unlocked(achievement["id"]):
			unlocked += 1
	_label(content, "%d / %d unlocked" % [unlocked, AchievementManager.ACHIEVEMENTS.size()], Vector2(22, 96), 16, Color(0.78, 0.92, 1.0))

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(18, 132)
	scroll.size = Vector2(420, 650)
	content.add_child(scroll)

	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(402, 0)
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	for achievement in AchievementManager.ACHIEVEMENTS:
		var done := SaveManager.is_achievement_unlocked(achievement["id"])
		var row := _panel(
			Vector2.ZERO,
			Vector2(402, 66),
			Color(0.08, 0.18, 0.12, 0.96) if done else Color(0.07, 0.08, 0.13, 0.94),
			Color(0.54, 0.80, 0.58, 0.24) if done else Color(0.36, 0.46, 0.62, 0.20),
			16
		)
		row.custom_minimum_size = Vector2(402, 66)
		list.add_child(row)
		var lbl := _label(row, "%s\n%s" % [achievement["title"], achievement["desc"]], Vector2(12, 10), 13, Color(0.95, 1.0, 0.95) if done else Color(0.58, 0.66, 0.76))
		lbl.custom_minimum_size = Vector2(378, 40)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _show_stats_overlay() -> void:
	var content := _overlay_panel("Stats", "Lifetime combat, progression, and records.")
	var favorite_tower := "None yet"
	var favorite_count := 0
	for ttype in GameData.get_canonical_tower_types():
		var key_name := str(GameData.TowerType.keys()[ttype])
		var count := SaveManager.get_stat("tower_count_%s" % key_name)
		if count > favorite_count:
			favorite_count = count
			var readable := key_name.to_lower().replace("_", " ")
			if readable.length() > 0:
				readable = readable[0].to_upper() + readable.substr(1)
			favorite_tower = "%s %s" % [GameData.get_tower(ttype).get("emoji", ""), readable]

	var unlocked := 0
	for achievement in AchievementManager.ACHIEVEMENTS:
		if SaveManager.is_achievement_unlocked(achievement["id"]):
			unlocked += 1

	var stats := RichTextLabel.new()
	stats.position = Vector2(18, 132)
	stats.size = Vector2(420, 650)
	stats.scroll_active = true
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.add_theme_font_size_override("normal_font_size", 14)
	stats.add_theme_color_override("default_color", Color(0.78, 0.88, 0.96))
	stats.text = "\n".join([
		"Combat",
		"• Total kills: %d" % SaveManager.get_stat("lifetime_kills"),
		"• Bosses defeated: %d" % SaveManager.get_stat("lifetime_bosses"),
		"• Best combo: %dx" % SaveManager.get_stat("lifetime_best_combo"),
		"• Towers placed: %d" % SaveManager.get_stat("lifetime_towers"),
		"• Favorite tower: %s" % favorite_tower,
		"",
		"Progress",
		"• Games played: %d" % SaveManager.get_stat("lifetime_games"),
		"• Total waves: %d" % SaveManager.get_stat("lifetime_waves"),
		"• Lifetime score: %d" % SaveManager.get_stat("lifetime_score"),
		"• Lifetime gold: %d" % SaveManager.get_stat("lifetime_gold"),
		"",
		"Records",
		"• High score: %d" % SaveManager.get_high_score(),
		"• Best wave: %d" % SaveManager.get_high_wave(),
		"• Endless record: wave %d" % SaveManager.get_endless_record(),
		"• Boss Rush record: %d bosses" % SaveManager.get_boss_rush_record(),
		"• Diamonds: %d" % SaveManager.get_diamonds(),
		"• Achievements: %d / %d" % [unlocked, AchievementManager.ACHIEVEMENTS.size()],
		"",
		"Campaign",
		"• Cleared: %d / %d" % [CampaignData.get_beaten_count(), _campaign_total_levels()],
		"• Flawless clears: %d" % _get_flawless_campaign_count(),
	])
	stats.text = _build_stats_text(favorite_tower, unlocked)
	content.add_child(stats)

func _show_help_overlay() -> void:
	var content := _overlay_panel("Help", "Quick reference for controls, towers, powers, and modes.")
	var help := RichTextLabel.new()
	help.position = Vector2(18, 132)
	help.size = Vector2(420, 650)
	help.scroll_active = true
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("normal_font_size", 13)
	help.add_theme_color_override("default_color", Color(0.78, 0.88, 0.96))
	help.text = _build_help_text()
	content.add_child(help)

func _build_stats_text(favorite_tower: String, unlocked_count: int) -> String:
	return "\n".join([
		"Combat",
		"- Total kills: %d" % SaveManager.get_stat("lifetime_kills"),
		"- Bosses defeated: %d" % SaveManager.get_stat("lifetime_bosses"),
		"- Best combo: %dx" % SaveManager.get_stat("lifetime_best_combo"),
		"- Towers placed: %d" % SaveManager.get_stat("lifetime_towers"),
		"- Powers used: %d" % SaveManager.get_stat("lifetime_powers_used"),
		"- Favorite tower: %s" % favorite_tower,
		"",
		"Progress",
		"- Games played: %d" % SaveManager.get_stat("lifetime_games"),
		"- Total waves: %d" % SaveManager.get_stat("lifetime_waves"),
		"- Lifetime score: %d" % SaveManager.get_stat("lifetime_score"),
		"- Lifetime gold: %d" % SaveManager.get_stat("lifetime_gold"),
		"- Lifetime diamonds earned: %d" % SaveManager.get_stat("lifetime_diamonds"),
		"",
		"Records",
		"- High score: %d" % SaveManager.get_high_score(),
		"- Best wave: %d" % SaveManager.get_high_wave(),
		"- Endless record: wave %d" % SaveManager.get_endless_record(),
		"- Boss Rush record: %d bosses" % SaveManager.get_boss_rush_record(),
		"- Diamonds: %d" % SaveManager.get_diamonds(),
		"- Achievements: %d / %d" % [unlocked_count, AchievementManager.ACHIEVEMENTS.size()],
		"",
		"Campaign",
		"- Cleared: %d / %d" % [CampaignData.get_beaten_count(), _campaign_total_levels()],
		"- Flawless clears: %d" % _get_flawless_campaign_count(),
	])

func _build_help_text() -> String:
	return "\n".join([
		"BASE",
		"- Defend the base at the bottom. If base HP reaches 0, the run ends.",
		"- Campaign in parity mode uses Kotlin restrictions and rewards only.",
		"",
		"PLAYER",
		"- Click or drag to move your hero.",
		"- The hero auto-attacks enemies in range.",
		"- Use Dash from the HUD for a short burst reposition.",
		"",
		"TOWERS",
		"- Open the BUILD drawer, choose a tower, then place it off the road and away from bases.",
		"- Placement preview: white/blue means valid, red means blocked.",
		"- Tap a tower to upgrade, sell, use ability, or change targeting (CLOSE/FIRST/LAST/STRONG).",
		"- Some campaign stages limit available towers or disable upgrades.",
		"",
		"POWERS",
		"- FIREBALL: area burst damage.",
		"- FREEZE: global slow on enemies.",
		"- HEAL: restores base HP.",
		"- LIGHTNING: chained strikes from target point.",
		"",
		"MODES",
		"- Campaign: handcrafted stages with restrictions, flawless clears, and progression unlocks.",
		"- Endless: choose difficulty and map, then survive as long as possible.",
		"- Extra Modes: Boss Rush, Boss Gauntlet, Daily Challenge, and Randomizer.",
		"",
		"TIPS",
		"- Mix damage types to bypass resistances.",
		"- Use wave warnings and terrain info before committing gold.",
		"- Keep one fast-response tower near each base exit.",
	])

func _show_settings_overlay() -> void:
	var content := _overlay_panel("Settings", "Audio, accessibility, and profile controls.")

	_label(content, "Master Volume", Vector2(24, 104), 15, Color(0.82, 0.92, 1.0))
	var master_slider := HSlider.new()
	master_slider.position = Vector2(186, 108)
	master_slider.size = Vector2(220, 18)
	master_slider.min_value = -30
	master_slider.max_value = 0
	master_slider.step = 1
	master_slider.value = SoundManager.master_volume_db
	content.add_child(master_slider)
	master_slider.value_changed.connect(func(value: float): SoundManager.set_master_volume(value))

	_label(content, "Music Volume", Vector2(24, 150), 15, Color(0.82, 0.92, 1.0))
	var music_slider := HSlider.new()
	music_slider.position = Vector2(186, 154)
	music_slider.size = Vector2(220, 18)
	music_slider.min_value = -30
	music_slider.max_value = 0
	music_slider.step = 1
	music_slider.value = SoundManager.music_volume_db
	content.add_child(music_slider)
	music_slider.value_changed.connect(func(value: float): SoundManager.set_music_volume(value))

	_label(content, "SFX Volume", Vector2(24, 196), 15, Color(0.82, 0.92, 1.0))
	var sfx_slider := HSlider.new()
	sfx_slider.position = Vector2(186, 200)
	sfx_slider.size = Vector2(220, 18)
	sfx_slider.min_value = -30
	sfx_slider.max_value = 0
	sfx_slider.step = 1
	sfx_slider.value = SoundManager.sfx_volume_db
	content.add_child(sfx_slider)
	sfx_slider.value_changed.connect(func(value: float): SoundManager.set_sfx_volume(value))

	var show_fps := CheckBox.new()
	show_fps.text = "Show FPS Counter"
	show_fps.position = Vector2(24, 242)
	show_fps.button_pressed = SaveManager.get_bool("show_fps", false)
	show_fps.add_theme_font_size_override("font_size", 14)
	show_fps.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0))
	content.add_child(show_fps)
	show_fps.toggled.connect(func(enabled: bool):
		SaveManager.set_val("show_fps", enabled)
		SaveManager.flush()
	)

	var shake_toggle := CheckBox.new()
	shake_toggle.text = "Screen Shake"
	shake_toggle.position = Vector2(232, 242)
	shake_toggle.button_pressed = SaveManager.get_bool("screen_shake", true)
	shake_toggle.add_theme_font_size_override("font_size", 14)
	shake_toggle.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0))
	content.add_child(shake_toggle)
	shake_toggle.toggled.connect(func(enabled: bool):
		SaveManager.set_val("screen_shake", enabled)
		SaveManager.flush()
	)

	_label(content, "Palette", Vector2(24, 286), 15, Color(0.82, 0.92, 1.0))
	var palette := OptionButton.new()
	palette.position = Vector2(186, 282)
	palette.size = Vector2(190, 28)
	palette.add_theme_font_size_override("font_size", 13)
	palette.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0))
	palette.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.12, 0.20), 12))
	palette.add_theme_stylebox_override("hover", _button_style(Color(0.12, 0.16, 0.26), 12, Color(0.72, 0.86, 0.98, 0.40), 2))
	palette.add_theme_stylebox_override("pressed", _button_style(Color(0.06, 0.10, 0.18), 12))
	var palettes := GameData.get_palette_names()
	for idx in range(palettes.size()):
		palette.add_item(palettes[idx], idx)
		if palettes[idx] == GameData.current_palette:
			palette.selected = idx
	content.add_child(palette)
	palette.item_selected.connect(func(idx: int):
		GameData.set_palette(palettes[idx])
		SaveManager.set_val("ui_palette", palettes[idx])
		SaveManager.flush()
		queue_redraw()
	)

	_label(content, "Quick Music", Vector2(24, 332), 15, Color(0.82, 0.92, 1.0))
	var music_row := HBoxContainer.new()
	music_row.position = Vector2(24, 362)
	music_row.custom_minimum_size = Vector2(382, 40)
	music_row.add_theme_constant_override("separation", 10)
	content.add_child(music_row)

	for track_data in [
		{"label": "Menu", "method": "play_menu_music"},
		{"label": "Battle", "method": "play_battle_music"},
		{"label": "Victory", "method": "play_victory_music"},
	]:
		var btn := Button.new()
		btn.text = track_data["label"]
		btn.custom_minimum_size = Vector2(0, 38)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0))
		btn.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.12, 0.20), 12))
		btn.add_theme_stylebox_override("hover", _button_style(Color(0.12, 0.16, 0.26), 12))
		btn.pressed.connect(Callable(SoundManager, track_data["method"]))
		music_row.add_child(btn)

	var reset_btn := _button(content, "RESET PROGRESS", Vector2(24, 420), Vector2(382, 44), Color(0.26, 0.10, 0.08))
	reset_btn.add_theme_font_size_override("font_size", 16)
	reset_btn.pressed.connect(func():
		SaveManager.reset_progress()
		SoundManager.play_ui_click()
		get_tree().reload_current_scene()
	)

func _overlay_panel(title: String, subtitle: String) -> Control:
	_close_overlay()
	_overlay = Control.new()
	_overlay.size = SCREEN_SIZE
	add_child(_overlay)

	var dimmer := ColorRect.new()
	dimmer.size = SCREEN_SIZE
	dimmer.color = Color(0.01, 0.02, 0.04, 0.82)
	_overlay.add_child(dimmer)

	var content := _panel(Vector2(12, 12), Vector2(456, 830), Color(0.03, 0.05, 0.10, 0.99), Color(0.40, 0.62, 0.84, 0.28), 26)
	_overlay.add_child(content)
	_add_panel_glow(content, Color(0.30, 0.66, 0.92, 0.08), Color(1.0, 0.74, 0.30, 0.06))

	var header_band := ColorRect.new()
	header_band.position = Vector2(18, 18)
	header_band.size = Vector2(420, 72)
	header_band.color = Color(0.06, 0.10, 0.18, 0.48)
	content.add_child(header_band)

	var title_chip := _panel(Vector2(22, 22), Vector2(120, 24), Color(0.08, 0.16, 0.24, 0.92), Color(0.54, 0.82, 0.96, 0.24), 12)
	content.add_child(title_chip)
	var chip_text := _label(title_chip, "CONTROL DECK", Vector2(0, 4), 10, Color(0.80, 0.92, 1.0))
	chip_text.custom_minimum_size = Vector2(120, 16)
	chip_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var title_label := _label(content, title, Vector2(22, 48), 28, Color(0.92, 0.97, 1.0))
	title_label.custom_minimum_size = Vector2(300, 30)
	var subtitle_label := _label(content, subtitle, Vector2(22, 84), 13, Color(0.66, 0.80, 0.94))
	subtitle_label.custom_minimum_size = Vector2(360, 32)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var close_btn := _button(content, "Close", Vector2(344, 30), Vector2(90, 34), Color(0.20, 0.08, 0.08))
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(func():
		SoundManager.play_ui_click()
		_close_overlay()
	)

	return content

func _close_overlay() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null

func _panel(pos: Vector2, size: Vector2, color: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	panel.add_theme_stylebox_override("panel", _panel_style(color, border, radius))
	return panel

func _button(parent: Control, text: String, pos: Vector2, size: Vector2, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = size
	btn.clip_text = true
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	btn.add_theme_stylebox_override("normal", _button_style(color, 16))
	btn.add_theme_stylebox_override("hover", _button_style(color.lightened(0.08), 16, Color(0.72, 0.86, 0.98, 0.42), 2))
	btn.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.14), 16))
	var disabled := _button_style(color.darkened(0.25), 16, Color(0.30, 0.40, 0.52, 0.20), 1)
	btn.add_theme_stylebox_override("disabled", disabled)
	parent.add_child(btn)
	return btn

func _label(parent: Node, text: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _stat_chip(parent: Control, title: String, pos: Vector2, size: Vector2, bg: Color, title_color: Color, value_color: Color) -> Label:
	var chip := _panel(pos, size, bg, Color(0.42, 0.62, 0.82, 0.18), 12)
	parent.add_child(chip)
	var title_label := _label(chip, title, Vector2(8, 4), 9, title_color)
	title_label.custom_minimum_size = Vector2(size.x - 16.0, 10)
	var value_label := _label(chip, "0", Vector2(8, 12), 13, value_color)
	value_label.custom_minimum_size = Vector2(size.x - 16.0, 14)
	return value_label

func _add_card_cap(parent: Control, text: String, color: Color, pos: Vector2, width: float) -> void:
	var cap := _panel(pos, Vector2(width, 22), Color(0.08, 0.12, 0.18, 0.94), color * Color(1, 1, 1, 0.28), 11)
	parent.add_child(cap)
	var lbl := _label(cap, text, Vector2(0, 3), 10, color)
	lbl.custom_minimum_size = Vector2(width, 14)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _add_panel_glow(parent: Control, top_color: Color, bottom_color: Color) -> void:
	var top_glow := ColorRect.new()
	top_glow.position = Vector2(12, 12)
	top_glow.size = Vector2(parent.size.x - 24.0, 54)
	top_glow.color = top_color
	parent.add_child(top_glow)

	var bottom_glow := ColorRect.new()
	bottom_glow.position = Vector2(18, parent.size.y - 72.0)
	bottom_glow.size = Vector2(parent.size.x - 36.0, 42)
	bottom_glow.color = bottom_color
	parent.add_child(bottom_glow)

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
	style.shadow_color = Color(0, 0, 0, 0.34)
	style.shadow_size = 10
	return style

func _button_style(color: Color, radius: int, border: Color = Color(0.42, 0.56, 0.72, 0.26), border_width: int = 1) -> StyleBoxFlat:
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
