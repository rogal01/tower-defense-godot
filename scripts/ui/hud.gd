extends CanvasLayer

const SCREEN_SIZE := Vector2(480, 854)
const TOWER_NAMES := {
	GameData.TowerType.ARROW: "Arrow",
	GameData.TowerType.MAGIC: "Magic",
	GameData.TowerType.CANNON: "Cannon",
	GameData.TowerType.POISON: "Poison",
	GameData.TowerType.TESLA: "Tesla",
	GameData.TowerType.ICE: "Ice",
}
const POWER_NAMES := {
	GameData.PowerType.FIREBALL: "FIRE",
	GameData.PowerType.FREEZE: "FROST",
	GameData.PowerType.HEAL: "HEAL",
	GameData.PowerType.LIGHTNING: "BOLT",
}
const TARGET_NAMES := ["CLOSE", "FIRST", "LAST", "STRONG"]
const TUTORIAL_PAGES := [
	"Open the tower drawer, pick a tower, then place it anywhere off the road and away from the base.",
	"Watch the wave callout at the start of each round. Terrain hazards and boss warnings matter.",
	"Tap a tower to upgrade, sell, or set that specific tower's targeting mode.",
]

var gm: Node = null

var lbl_gold: Label
var lbl_wave: Label
var lbl_score: Label
var lbl_campaign: Label
var lbl_preview_title: Label
var lbl_preview_body: Label
var lbl_placement: Label
var lbl_hp: Label
var hp_fill: ColorRect
var hp_glow: ColorRect

var tower_buttons: Dictionary = {}
var power_buttons: Dictionary = {}
var tower_panel: Panel
var info_panel: Panel
var preview_panel: Panel
var campaign_panel: Panel
var tutorial_panel: Panel
var warning_panel: Panel
var wave_banner_panel: Panel
var achievement_panel: Panel
var placement_panel: Panel
var upgrade_panel: Panel

var btn_upgrade: Button
var btn_sell: Button
var btn_target: Button
var btn_speed: Button
var btn_auto_wave: Button
var btn_dash: Button
var btn_up_damage: Button
var btn_up_speed: Button
var btn_up_hp: Button
var btn_up_base: Button
var btn_repair: Button
var tutorial_next_btn: Button
var tutorial_skip_btn: Button
var tower_drawer_button: Button

var lbl_info_name: Label
var lbl_info_stats: Label
var lbl_warning_icon: Label
var lbl_warning_title: Label
var lbl_warning_body: Label
var lbl_wave_banner: Label
var lbl_tutorial_title: Label
var lbl_tutorial_body: Label
var lbl_achievement: Label
var lbl_fps: Label

var _selected_tower: Node = null
var _speed_idx: int = 0
var _wave_banner_timer: float = 0.0
var _warning_timer: float = 0.0
var _achievement_timer: float = 0.0
var _preview_timer: float = 0.0
var _wave_banner_phase: float = 0.0
var _warning_phase: float = 0.0
var _warning_priority: int = 1
var _tutorial_index: int = 0
var _tower_drawer_open: bool = false
var _tower_drawer_target_x: float = 492.0
var _tower_drawer_closed_x: float = 492.0
var _tower_drawer_open_x: float = 314.0

func _ready() -> void:
	gm = get_parent()
	_build_ui()
	_connect_signals()
	_refresh_all()
	if not SaveManager.get_bool("tutorial_seen", false):
		_show_tutorial()

func _build_ui() -> void:
	var top_fade := ColorRect.new()
	top_fade.size = Vector2(480, 188)
	top_fade.color = Color(0.03, 0.08, 0.14, 0.16)
	add_child(top_fade)

	var bottom_fade := ColorRect.new()
	bottom_fade.position = Vector2(0, 520)
	bottom_fade.size = Vector2(480, 334)
	bottom_fade.color = Color(0.01, 0.02, 0.05, 0.16)
	add_child(bottom_fade)

	var frame_top := ColorRect.new()
	frame_top.position = Vector2(18, 8)
	frame_top.size = Vector2(444, 1)
	frame_top.color = Color(0.48, 0.72, 0.94, 0.18)
	add_child(frame_top)

	var frame_bottom := ColorRect.new()
	frame_bottom.position = Vector2(18, 842)
	frame_bottom.size = Vector2(444, 1)
	frame_bottom.color = Color(0.48, 0.72, 0.94, 0.12)
	add_child(frame_bottom)

	_build_top_bar()
	_build_preview_panel()
	_build_campaign_panel()
	_build_warning_panel()
	_build_wave_banner()
	_build_achievement_banner()
	_build_power_strip()
	_build_info_panel()
	_build_upgrade_panel()
	_build_tower_panel()
	_build_tutorial_panel()
	_build_placement_panel()

func _build_top_bar() -> void:
	var top_bar := _make_panel(Vector2(10, 10), Vector2(460, 92), Color(0.03, 0.07, 0.12, 0.94), Color(0.40, 0.66, 0.88, 0.30), 22)
	add_child(top_bar)
	_add_panel_trim(top_bar, Color(0.28, 0.64, 0.92, 0.10), Color(0.96, 0.74, 0.24, 0.08))
	var resources_cap := _make_panel(Vector2(12, 8), Vector2(94, 18), Color(0.08, 0.14, 0.22, 0.94), Color(0.54, 0.82, 0.96, 0.20), 9)
	top_bar.add_child(resources_cap)
	var resources_label := _make_label(resources_cap, "RESOURCES", Vector2(0, 3), 9, Color(0.78, 0.90, 1.0))
	resources_label.custom_minimum_size = Vector2(94, 12)
	resources_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var flow_cap := _make_panel(Vector2(352, 8), Vector2(96, 18), Color(0.08, 0.14, 0.22, 0.94), Color(0.54, 0.82, 0.96, 0.20), 9)
	top_bar.add_child(flow_cap)
	var flow_label := _make_label(flow_cap, "FLOW", Vector2(0, 3), 9, Color(0.78, 0.90, 1.0))
	flow_label.custom_minimum_size = Vector2(96, 12)
	flow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_fps = _make_label(top_bar, "", Vector2(306, 10), 10, Color(0.72, 0.88, 1.0))
	lbl_fps.custom_minimum_size = Vector2(140, 12)
	lbl_fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_fps.visible = false

	var gold_chip := _make_panel(Vector2(12, 28), Vector2(118, 28), Color(0.09, 0.12, 0.20, 0.96), Color(0.86, 0.72, 0.24, 0.24), 14)
	top_bar.add_child(gold_chip)
	lbl_gold = _make_label(gold_chip, "Gold 50", Vector2(0, 5), 15, Color(1.0, 0.86, 0.32))
	lbl_gold.custom_minimum_size = Vector2(118, 18)
	lbl_gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var wave_chip := _make_panel(Vector2(136, 28), Vector2(92, 28), Color(0.08, 0.12, 0.20, 0.96), Color(0.50, 0.72, 0.92, 0.22), 14)
	top_bar.add_child(wave_chip)
	lbl_wave = _make_label(wave_chip, "Wave 0", Vector2(0, 5), 15, Color(0.82, 0.92, 1.0))
	lbl_wave.custom_minimum_size = Vector2(92, 18)
	lbl_wave.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var score_chip := _make_panel(Vector2(234, 28), Vector2(112, 28), Color(0.08, 0.12, 0.20, 0.96), Color(0.42, 0.58, 0.78, 0.20), 14)
	top_bar.add_child(score_chip)
	lbl_score = _make_label(score_chip, "Score 0", Vector2(0, 5), 14, Color(0.74, 0.82, 0.92))
	lbl_score.custom_minimum_size = Vector2(112, 18)
	lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	btn_speed = _make_button(top_bar, "1x", Vector2(354, 28), Vector2(38, 28), _on_speed_button, Color(0.08, 0.18, 0.22))
	btn_auto_wave = _make_button(top_bar, "Auto", Vector2(396, 28), Vector2(52, 28), _on_auto_wave_button, Color(0.10, 0.16, 0.24))
	btn_dash = _make_button(top_bar, "Dash", Vector2(296, 60), Vector2(54, 24), _on_dash_button, Color(0.08, 0.18, 0.24))
	btn_dash.add_theme_font_size_override("font_size", 10)

	var btn_pause := _make_button(top_bar, "Pause", Vector2(354, 60), Vector2(58, 24), _on_pause_button, Color(0.14, 0.10, 0.20))
	btn_pause.add_theme_font_size_override("font_size", 11)
	var btn_help := _make_button(top_bar, "Help", Vector2(416, 60), Vector2(32, 24), _on_help_button, Color(0.10, 0.14, 0.20))
	btn_help.add_theme_font_size_override("font_size", 10)

	lbl_hp = _make_label(top_bar, "HP 100 / 100", Vector2(12, 64), 13, Color(0.92, 0.96, 1.0))

	var hp_bg := ColorRect.new()
	hp_bg.position = Vector2(102, 66)
	hp_bg.size = Vector2(238, 14)
	hp_bg.color = Color(0.12, 0.03, 0.04, 0.86)
	top_bar.add_child(hp_bg)

	hp_fill = ColorRect.new()
	hp_fill.position = hp_bg.position
	hp_fill.size = hp_bg.size
	hp_fill.color = Color(0.22, 0.84, 0.34)
	top_bar.add_child(hp_fill)

	hp_glow = ColorRect.new()
	hp_glow.position = hp_bg.position
	hp_glow.size = Vector2(hp_bg.size.x, 3)
	hp_glow.color = Color(0.60, 1.0, 0.72, 0.35)
	top_bar.add_child(hp_glow)

func _build_preview_panel() -> void:
	preview_panel = _make_panel(Vector2(12, 108), Vector2(236, 128), Color(0.03, 0.08, 0.14, 0.95), Color(0.44, 0.72, 0.92, 0.26), 20)
	preview_panel.visible = false
	add_child(preview_panel)
	_add_panel_trim(preview_panel, Color(0.26, 0.62, 0.92, 0.10), Color(0.08, 0.12, 0.18, 0.06))
	var cap := _make_panel(Vector2(14, 12), Vector2(92, 18), Color(0.08, 0.14, 0.22, 0.94), Color(0.54, 0.82, 0.96, 0.18), 9)
	preview_panel.add_child(cap)
	var cap_text := _make_label(cap, "NEXT WAVE", Vector2(0, 3), 9, Color(0.78, 0.90, 1.0))
	cap_text.custom_minimum_size = Vector2(92, 12)
	cap_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	lbl_preview_title = _make_label(preview_panel, "Incoming", Vector2(14, 36), 18, Color(0.90, 0.96, 1.0))
	lbl_preview_body = _make_label(preview_panel, "", Vector2(14, 64), 13, Color(0.74, 0.84, 0.95))
	lbl_preview_body.custom_minimum_size = Vector2(208, 68)
	lbl_preview_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_campaign_panel() -> void:
	campaign_panel = _make_panel(Vector2(252, 108), Vector2(216, 128), Color(0.06, 0.07, 0.13, 0.95), Color(0.86, 0.70, 0.24, 0.26), 20)
	campaign_panel.visible = false
	add_child(campaign_panel)
	_add_panel_trim(campaign_panel, Color(0.94, 0.74, 0.28, 0.08), Color(0.10, 0.10, 0.16, 0.06))
	var cap := _make_panel(Vector2(14, 12), Vector2(88, 18), Color(0.10, 0.12, 0.18, 0.94), Color(0.94, 0.78, 0.32, 0.22), 9)
	campaign_panel.add_child(cap)
	var cap_text := _make_label(cap, "MISSION", Vector2(0, 3), 9, Color(1.0, 0.88, 0.40))
	cap_text.custom_minimum_size = Vector2(88, 12)
	cap_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var title := _make_label(campaign_panel, "Campaign", Vector2(14, 36), 16, Color(1.0, 0.88, 0.38))
	title.custom_minimum_size = Vector2(180, 18)
	lbl_campaign = _make_label(campaign_panel, "", Vector2(14, 58), 11, Color(0.78, 0.86, 0.95))
	lbl_campaign.custom_minimum_size = Vector2(188, 78)
	lbl_campaign.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_warning_panel() -> void:
	warning_panel = _make_panel(Vector2(48, 232), Vector2(384, 118), Color(0.16, 0.06, 0.05, 0.97), Color(0.92, 0.52, 0.32, 0.36), 22)
	warning_panel.visible = false
	add_child(warning_panel)

	lbl_warning_icon = _make_label(warning_panel, "!", Vector2(14, 12), 30, Color(1.0, 0.92, 0.6))
	lbl_warning_icon.custom_minimum_size = Vector2(32, 34)
	lbl_warning_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	lbl_warning_title = _make_label(warning_panel, "Warning", Vector2(54, 16), 22, Color(1.0, 0.90, 0.48))
	lbl_warning_body = _make_label(warning_panel, "", Vector2(54, 50), 13, Color(0.96, 0.92, 0.90))
	lbl_warning_body.custom_minimum_size = Vector2(314, 52)
	lbl_warning_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_wave_banner() -> void:
	wave_banner_panel = _make_panel(Vector2(88, 324), Vector2(304, 92), Color(0.04, 0.10, 0.16, 0.96), Color(0.56, 0.84, 0.98, 0.26), 24)
	wave_banner_panel.visible = false
	add_child(wave_banner_panel)

	lbl_wave_banner = _make_label(wave_banner_panel, "Wave 1", Vector2(0, 18), 28, Color(0.94, 0.98, 1.0))
	lbl_wave_banner.custom_minimum_size = Vector2(304, 50)
	lbl_wave_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_achievement_banner() -> void:
	achievement_panel = _make_panel(Vector2(36, 198), Vector2(408, 72), Color(0.16, 0.12, 0.04, 0.96), Color(0.90, 0.74, 0.26, 0.24), 18)
	achievement_panel.visible = false
	add_child(achievement_panel)

	lbl_achievement = _make_label(achievement_panel, "", Vector2(12, 14), 13, Color(1.0, 0.86, 0.30))
	lbl_achievement.custom_minimum_size = Vector2(382, 40)
	lbl_achievement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_power_strip() -> void:
	var strip := _make_panel(Vector2(12, 252), Vector2(62, 266), Color(0.03, 0.06, 0.10, 0.97), Color(0.38, 0.58, 0.78, 0.22), 20)
	add_child(strip)
	_add_panel_trim(strip, Color(0.28, 0.62, 0.92, 0.08), Color(0.04, 0.08, 0.12, 0.06))
	var title := _make_label(strip, "OPS", Vector2(0, 10), 10, Color(0.80, 0.92, 1.0))
	title.custom_minimum_size = Vector2(62, 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var power_types: Array = GameData.get_canonical_power_types()
	for index in range(power_types.size()):
		var ptype: int = power_types[index]
		var btn := _make_button(
			strip,
			POWER_NAMES.get(ptype, "PWR"),
			Vector2(8, 32 + index * 56),
			Vector2(46, 46),
			_on_power_button.bind(ptype),
			_power_button_color(ptype)
		)
		btn.add_theme_font_size_override("font_size", 10)
		power_buttons[ptype] = btn

func _build_info_panel() -> void:
	info_panel = _make_panel(Vector2(12, 596), Vector2(300, 136), Color(0.03, 0.07, 0.11, 0.97), Color(0.42, 0.64, 0.84, 0.24), 22)
	info_panel.visible = false
	add_child(info_panel)
	_add_panel_trim(info_panel, Color(0.28, 0.62, 0.92, 0.08), Color(0.08, 0.12, 0.18, 0.06))
	var cap := _make_panel(Vector2(14, 12), Vector2(96, 18), Color(0.08, 0.14, 0.22, 0.94), Color(0.54, 0.82, 0.96, 0.20), 9)
	info_panel.add_child(cap)
	var cap_text := _make_label(cap, "SELECTED", Vector2(0, 3), 9, Color(0.78, 0.90, 1.0))
	cap_text.custom_minimum_size = Vector2(96, 12)
	cap_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	lbl_info_name = _make_label(info_panel, "Tower", Vector2(14, 36), 18, Color(0.90, 0.96, 1.0))
	lbl_info_stats = _make_label(info_panel, "", Vector2(14, 62), 12, Color(0.76, 0.84, 0.94))
	lbl_info_stats.custom_minimum_size = Vector2(156, 74)
	lbl_info_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	btn_upgrade = _make_button(info_panel, "Upgrade", Vector2(182, 18), Vector2(104, 34), _on_upgrade_pressed, Color(0.12, 0.24, 0.16))
	btn_sell = _make_button(info_panel, "Sell", Vector2(182, 58), Vector2(104, 30), _on_sell_pressed, Color(0.20, 0.14, 0.08))
	btn_target = _make_button(info_panel, "Target", Vector2(182, 94), Vector2(104, 30), _on_target_button, Color(0.10, 0.14, 0.24))
	btn_target.add_theme_font_size_override("font_size", 10)

func _build_upgrade_panel() -> void:
	upgrade_panel = _make_panel(Vector2(82, 736), Vector2(316, 108), Color(0.03, 0.07, 0.11, 0.97), Color(0.42, 0.64, 0.84, 0.24), 20)
	add_child(upgrade_panel)
	_add_panel_trim(upgrade_panel, Color(0.28, 0.62, 0.92, 0.08), Color(0.08, 0.12, 0.18, 0.06))

	var cap := _make_panel(Vector2(12, 8), Vector2(84, 16), Color(0.08, 0.14, 0.22, 0.94), Color(0.54, 0.82, 0.96, 0.18), 8)
	upgrade_panel.add_child(cap)
	var cap_text := _make_label(cap, "UPGRADES", Vector2(0, 2), 8, Color(0.78, 0.90, 1.0))
	cap_text.custom_minimum_size = Vector2(84, 12)
	cap_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	btn_up_damage = _make_button(upgrade_panel, "ATK", Vector2(12, 30), Vector2(92, 30), _on_up_damage_pressed, Color(0.20, 0.14, 0.08))
	btn_up_speed = _make_button(upgrade_panel, "SPD", Vector2(112, 30), Vector2(92, 30), _on_up_speed_pressed, Color(0.08, 0.16, 0.24))
	btn_up_hp = _make_button(upgrade_panel, "HP", Vector2(212, 30), Vector2(92, 30), _on_up_hp_pressed, Color(0.10, 0.18, 0.14))
	btn_up_base = _make_button(upgrade_panel, "BASE", Vector2(12, 66), Vector2(142, 30), _on_up_base_pressed, Color(0.10, 0.14, 0.22))
	btn_repair = _make_button(upgrade_panel, "REPAIR", Vector2(162, 66), Vector2(142, 30), _on_repair_pressed, Color(0.12, 0.20, 0.14))
	for btn in [btn_up_damage, btn_up_speed, btn_up_hp, btn_up_base, btn_repair]:
		btn.add_theme_font_size_override("font_size", 10)

func _build_tower_panel() -> void:
	tower_panel = _make_panel(Vector2(_tower_drawer_closed_x, 188), Vector2(160, 446), Color(0.03, 0.06, 0.11, 0.98), Color(0.42, 0.66, 0.86, 0.24), 24)
	add_child(tower_panel)
	_add_panel_trim(tower_panel, Color(0.26, 0.62, 0.92, 0.10), Color(0.06, 0.10, 0.16, 0.08))

	var drawer_title := _make_label(tower_panel, "TOWER BAY", Vector2(14, 14), 15, Color(0.90, 0.96, 1.0))
	drawer_title.custom_minimum_size = Vector2(120, 18)
	var drawer_body := _make_label(tower_panel, "Pick a tower and place it off the road.", Vector2(14, 34), 10, Color(0.68, 0.82, 0.94))
	drawer_body.custom_minimum_size = Vector2(132, 24)
	drawer_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var tower_types: Array = GameData.get_canonical_tower_types()
	for index in range(tower_types.size()):
		var ttype: int = tower_types[index]
		var column := index % 2
		var row := index / 2
		var btn := _make_button(
			tower_panel,
			"%s\n%dg" % [TOWER_NAMES.get(ttype, "Tower"), GameData.get_tower(ttype)["cost"]],
			Vector2(12 + column * 68, 68 + row * 62),
			Vector2(60, 54),
			_on_tower_button.bind(ttype),
			_tower_button_color(ttype)
		)
		btn.add_theme_font_size_override("font_size", 10)
		tower_buttons[ttype] = btn

	tower_drawer_button = _make_button(self, "BUILD", Vector2(424, 356), Vector2(56, 46), _on_toggle_tower_drawer, Color(0.08, 0.16, 0.22))
	tower_drawer_button.add_theme_font_size_override("font_size", 11)

func _build_tutorial_panel() -> void:
	tutorial_panel = _make_panel(Vector2(30, 180), Vector2(420, 244), Color(0.03, 0.06, 0.10, 0.98), Color(0.48, 0.72, 0.94, 0.24), 24)
	tutorial_panel.visible = false
	add_child(tutorial_panel)
	_add_panel_trim(tutorial_panel, Color(0.28, 0.62, 0.92, 0.10), Color(0.08, 0.12, 0.18, 0.06))

	lbl_tutorial_title = _make_label(tutorial_panel, "How To Play", Vector2(18, 22), 24, Color(0.92, 0.98, 1.0))
	lbl_tutorial_body = _make_label(tutorial_panel, "", Vector2(18, 68), 15, Color(0.78, 0.88, 0.96))
	lbl_tutorial_body.custom_minimum_size = Vector2(384, 106)
	lbl_tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	tutorial_next_btn = _make_button(tutorial_panel, "Next", Vector2(224, 192), Vector2(84, 36), _on_tutorial_next, Color(0.10, 0.18, 0.24))
	tutorial_skip_btn = _make_button(tutorial_panel, "Close", Vector2(316, 192), Vector2(84, 36), _on_tutorial_close, Color(0.18, 0.10, 0.12))

func _build_placement_panel() -> void:
	placement_panel = _make_panel(Vector2(88, 536), Vector2(304, 64), Color(0.03, 0.07, 0.11, 0.94), Color(0.48, 0.72, 0.94, 0.18), 20)
	placement_panel.visible = false
	add_child(placement_panel)
	_add_panel_trim(placement_panel, Color(0.28, 0.62, 0.92, 0.08), Color(0.06, 0.10, 0.16, 0.05))

	lbl_placement = _make_label(placement_panel, "", Vector2(14, 14), 13, Color(0.88, 0.96, 1.0))
	lbl_placement.custom_minimum_size = Vector2(276, 36)
	lbl_placement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_placement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _connect_signals() -> void:
	if gm == null:
		return
	gm.gold_changed.connect(_on_gold_changed)
	gm.score_changed.connect(_on_score_changed)
	gm.base_hp_changed.connect(_on_hp_changed)
	gm.wave_changed.connect(_on_wave_changed)
	gm.wave_banner_shown.connect(_on_wave_banner)
	gm.tower_selected.connect(_on_tower_selected)
	gm.placement_mode_changed.connect(_on_placement_mode)
	if gm.has_signal("power_targeting_mode_changed"):
		gm.power_targeting_mode_changed.connect(_on_power_targeting_mode)
	if gm.has_signal("game_configured"):
		gm.game_configured.connect(_refresh_all)
	if gm.has_signal("warning_requested"):
		gm.warning_requested.connect(_show_warning)
	if AchievementManager.has_signal("achievement_unlocked"):
		AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _refresh_all() -> void:
	if gm == null:
		return
	_speed_idx = max(0, gm.game_speed - 1)
	_on_gold_changed(gm.gold)
	_on_score_changed(gm.score)
	_on_hp_changed(gm.base_hp, gm.max_base_hp)
	_on_wave_changed(gm.wave)
	_refresh_restrictions()
	_refresh_wave_preview()
	_refresh_campaign_panel()
	_refresh_speed_label()
	_refresh_dash_button()
	_refresh_tower_cost_labels()
	_refresh_upgrade_buttons()

func _process(delta: float) -> void:
	if lbl_fps != null:
		var show_fps := SaveManager.get_bool("show_fps", false)
		lbl_fps.visible = show_fps
		if show_fps:
			lbl_fps.text = "FPS %d" % Engine.get_frames_per_second()

	if _preview_timer > 0.0:
		_preview_timer -= delta
		if _preview_timer <= 0.0:
			preview_panel.visible = false

	tower_panel.position.x = lerpf(tower_panel.position.x, _tower_drawer_target_x, minf(1.0, delta * 10.0))

	if _wave_banner_timer > 0.0:
		_wave_banner_timer -= delta
		_wave_banner_phase += delta * 4.0
		var pulse := 1.0 + sin(_wave_banner_phase) * 0.035
		wave_banner_panel.scale = Vector2.ONE * pulse
		if _wave_banner_timer <= 0.0:
			wave_banner_panel.visible = false
			wave_banner_panel.scale = Vector2.ONE

	if _warning_timer > 0.0:
		_warning_timer -= delta
		_warning_phase += delta * (4.2 + float(_warning_priority))
		var pulse_strength := 0.02 + 0.01 * float(_warning_priority)
		var pulse := 1.0 + sin(_warning_phase) * pulse_strength
		warning_panel.scale = Vector2.ONE * pulse
		if _warning_timer <= 0.0:
			warning_panel.visible = false
			warning_panel.scale = Vector2.ONE

	if _achievement_timer > 0.0:
		_achievement_timer -= delta
		if _achievement_timer <= 0.0:
			achievement_panel.visible = false

	_update_power_buttons()
	_update_placement_hint()
	_refresh_dash_button()
	_refresh_upgrade_buttons()

	if _selected_tower and is_instance_valid(_selected_tower):
		_refresh_info_panel(_selected_tower)
	elif _selected_tower != null:
		_deselect_tower()

func _on_gold_changed(new_gold: int) -> void:
	lbl_gold.text = "Gold %d" % new_gold
	for ttype in tower_buttons:
		var btn: Button = tower_buttons[ttype]
		var cost: int = GameData.get_tower(ttype)["cost"]
		if gm and gm.has_method("get_tower_cost"):
			cost = gm.get_tower_cost(ttype)
		btn.modulate = Color.WHITE if new_gold >= cost else Color(0.54, 0.54, 0.54, 0.84)
	_refresh_tower_cost_labels()
	_refresh_upgrade_buttons()
	_refresh_wave_preview()
	_refresh_info_panel(_selected_tower)

func _on_score_changed(new_score: int) -> void:
	lbl_score.text = "Score %d" % new_score

func _on_hp_changed(hp: float, max_hp: float) -> void:
	if max_hp <= 0.0:
		return
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	hp_fill.size.x = 238.0 * ratio
	hp_glow.size.x = hp_fill.size.x
	if ratio > 0.5:
		hp_fill.color = Color(0.22, 0.84, 0.34)
		hp_glow.color = Color(0.62, 1.0, 0.74, 0.35)
	elif ratio > 0.25:
		hp_fill.color = Color(0.96, 0.74, 0.18)
		hp_glow.color = Color(1.0, 0.90, 0.42, 0.35)
	else:
		hp_fill.color = Color(0.92, 0.24, 0.22)
		hp_glow.color = Color(1.0, 0.62, 0.58, 0.35)
	lbl_hp.text = "HP %d / %d" % [int(hp), int(max_hp)]

func _on_wave_changed(new_wave: int) -> void:
	lbl_wave.text = "Wave %d" % new_wave
	_refresh_wave_preview()
	_refresh_campaign_panel()

func _on_wave_banner(wave_num: int, modifier: int) -> void:
	var mod_name: String = str(GameData.MODIFIER_NAMES.get(modifier, {}).get("name", ""))
	lbl_wave_banner.text = "Wave %d" % wave_num
	if modifier != GameData.WaveModifier.NONE and mod_name != "":
		lbl_wave_banner.text += "\n%s" % mod_name
	wave_banner_panel.visible = true
	_wave_banner_timer = 2.0
	_wave_banner_phase = 0.0
	preview_panel.visible = true
	_preview_timer = 2.8
	_refresh_wave_preview()

func _on_tower_selected(tower_node: Node) -> void:
	if tower_node == null or not is_instance_valid(tower_node):
		_deselect_tower()
		return
	if _selected_tower and is_instance_valid(_selected_tower) and _selected_tower != tower_node:
		_selected_tower.set_show_range(false)
	_selected_tower = tower_node
	_selected_tower.set_show_range(true)
	info_panel.visible = true
	_refresh_info_panel(_selected_tower)

func _on_placement_mode(active: bool, _tower_type: int) -> void:
	placement_panel.visible = active
	if not active:
		lbl_placement.text = ""
		return
	_update_placement_hint()

func _on_power_targeting_mode(active: bool, _power_type: int) -> void:
	placement_panel.visible = active
	if not active:
		lbl_placement.text = ""
		return
	_update_placement_hint()

func _on_achievement_unlocked(achievement: Dictionary) -> void:
	lbl_achievement.text = "%s\n%s" % [achievement.get("title", "Achievement"), achievement.get("desc", "")]
	achievement_panel.visible = true
	_achievement_timer = 3.0

func _on_tower_button(ttype: int) -> void:
	if gm == null:
		return
	if gm.has_method("get_tower_cost"):
		var cost: int = gm.get_tower_cost(ttype)
		if gm.gold < cost:
			_show_warning("Need More Gold", "Tower cost is %dg." % cost, Color(0.90, 0.46, 0.32))
			return
	var cl: Dictionary = gm.campaign_level
	if not cl.is_empty() and ttype not in cl.get("towers", []):
		_show_warning("Tower Locked", "This level restricts which towers can be built.", Color(0.88, 0.40, 0.32))
		return
	if gm.placement_active and gm.placement_tower_type == ttype:
		gm.cancel_placement()
	else:
		_deselect_tower()
		gm.start_placement(ttype)
		_set_tower_drawer(false)
	SoundManager.play_ui_click()

func _on_power_button(ptype: int) -> void:
	if gm == null:
		return
	if gm.power_targeting_active and gm.power_targeting_type == ptype:
		gm.cancel_power_targeting()
	else:
		_deselect_tower()
		gm.start_power_targeting(ptype)
	_set_tower_drawer(false)
	SoundManager.play_ui_click()

func _on_upgrade_pressed() -> void:
	if gm and _selected_tower:
		gm.upgrade_tower(_selected_tower)

func _on_sell_pressed() -> void:
	if gm and _selected_tower:
		gm.sell_tower(_selected_tower)
		_deselect_tower()

func _on_target_button() -> void:
	if gm == null:
		return
	if _selected_tower and is_instance_valid(_selected_tower):
		_selected_tower.target_mode = (_selected_tower.target_mode + 1) % TARGET_NAMES.size()
	else:
		gm.target_mode = (gm.target_mode + 1) % TARGET_NAMES.size()
	_refresh_info_panel(_selected_tower)

func _on_speed_button() -> void:
	_speed_idx = (_speed_idx + 1) % 3
	if gm:
		gm.set_game_speed(_speed_idx + 1)
	_refresh_speed_label()
	SoundManager.play_ui_click()

func _on_up_damage_pressed() -> void:
	if gm == null or not gm.has_method("upgrade_player_damage"):
		return
	if gm.upgrade_player_damage():
		SoundManager.play_ui_click()
	else:
		_show_warning("Upgrade Blocked", "Not enough gold or upgrades are disabled on this stage.", Color(0.90, 0.46, 0.32))
	_refresh_upgrade_buttons()

func _on_up_speed_pressed() -> void:
	if gm == null or not gm.has_method("upgrade_player_speed"):
		return
	if gm.upgrade_player_speed():
		SoundManager.play_ui_click()
	else:
		_show_warning("Upgrade Blocked", "Not enough gold or upgrades are disabled on this stage.", Color(0.90, 0.46, 0.32))
	_refresh_upgrade_buttons()

func _on_up_hp_pressed() -> void:
	if gm == null or not gm.has_method("upgrade_player_hp"):
		return
	if gm.upgrade_player_hp():
		SoundManager.play_ui_click()
	else:
		_show_warning("Upgrade Blocked", "Not enough gold or upgrades are disabled on this stage.", Color(0.90, 0.46, 0.32))
	_refresh_upgrade_buttons()

func _on_up_base_pressed() -> void:
	if gm == null or not gm.has_method("upgrade_base_hp"):
		return
	if gm.upgrade_base_hp():
		SoundManager.play_ui_click()
	else:
		_show_warning("Upgrade Blocked", "Not enough gold or upgrades are disabled on this stage.", Color(0.90, 0.46, 0.32))
	_refresh_upgrade_buttons()

func _on_repair_pressed() -> void:
	if gm == null or not gm.has_method("repair_base"):
		return
	if gm.repair_base():
		SoundManager.play_ui_click()
	else:
		if gm.base_hp >= gm.max_base_hp:
			_show_warning("Base Full", "Repair is unavailable because base HP is already full.", Color(0.52, 0.84, 0.62))
		else:
			_show_warning("Need More Gold", "Repair costs 20g.", Color(0.90, 0.46, 0.32))
	_refresh_upgrade_buttons()

func _on_auto_wave_button() -> void:
	if gm == null:
		return
	gm.auto_wave = not gm.auto_wave
	_refresh_speed_label()
	SoundManager.play_ui_click()

func _on_dash_button() -> void:
	if gm == null or not gm.has_method("use_dash"):
		return
	if gm.use_dash():
		SoundManager.play_ui_click()

func _on_pause_button() -> void:
	if gm:
		gm.toggle_pause()

func _on_help_button() -> void:
	_show_tutorial()

func _show_tutorial() -> void:
	_tutorial_index = 0
	_refresh_tutorial_page()
	tutorial_panel.visible = true

func _on_tutorial_next() -> void:
	_tutorial_index += 1
	if _tutorial_index >= TUTORIAL_PAGES.size():
		_on_tutorial_close()
		return
	_refresh_tutorial_page()

func _on_tutorial_close() -> void:
	tutorial_panel.visible = false
	SaveManager.set_val("tutorial_seen", true)
	SaveManager.flush()

func _refresh_tutorial_page() -> void:
	lbl_tutorial_title.text = "How To Play %d / %d" % [_tutorial_index + 1, TUTORIAL_PAGES.size()]
	lbl_tutorial_body.text = TUTORIAL_PAGES[_tutorial_index]
	tutorial_next_btn.text = "Done" if _tutorial_index == TUTORIAL_PAGES.size() - 1 else "Next"

func _refresh_info_panel(tower_node: Node) -> void:
	if tower_node == null or not is_instance_valid(tower_node):
		return
	var tdata := GameData.get_tower(tower_node.tower_type)
	var base_cost := int(tdata["cost"])
	if gm and gm.has_method("get_tower_cost"):
		base_cost = gm.get_tower_cost(tower_node.tower_type)
	var upgrade_cost := GameData.tower_upgrade_cost(base_cost, tower_node.level)
	var sell_val := GameData.tower_sell_value(base_cost, tower_node.level, gm.skill_sell_bonus if gm else 0.0)
	var branch_value: int = int(tower_node.get("branch"))
	var branch_name: String = str(tower_node.get("branch_name"))
	if branch_value <= 0:
		branch_name = "Core"
	lbl_info_name.text = "%s Tower  Lv %d" % [TOWER_NAMES.get(tower_node.tower_type, "Tower"), tower_node.level]
	lbl_info_stats.text = "DMG %.0f  RNG %.0f\nSPD %.2f  TYPE %s\nBranch %s\n%s" % [
		tower_node.damage,
		tower_node.attack_range,
		tower_node.fire_rate,
		GameData.DamageType.keys()[tower_node.damage_type],
		branch_name,
		tdata.get("desc", ""),
	]
	btn_sell.text = "Sell %dg" % sell_val
	if tower_node.level >= 10:
		btn_upgrade.text = "Max Level"
		btn_upgrade.disabled = true
	else:
		btn_upgrade.text = "Upgrade %dg" % upgrade_cost
		btn_upgrade.disabled = gm == null or gm.gold < upgrade_cost
	var target_idx: int = int(tower_node.target_mode)
	btn_target.text = "Target %s" % TARGET_NAMES[target_idx]

func _deselect_tower() -> void:
	if _selected_tower and is_instance_valid(_selected_tower):
		_selected_tower.set_show_range(false)
	_selected_tower = null
	info_panel.visible = false

func _refresh_wave_preview() -> void:
	if gm == null or not gm.has_method("get_next_wave_preview"):
		lbl_preview_body.text = "Wave preview unavailable."
		return
	var preview: Dictionary = gm.get_next_wave_preview()
	lbl_preview_title.text = preview.get("title", "Incoming")
	lbl_preview_body.text = preview.get("body", "")

func _refresh_campaign_panel() -> void:
	if gm == null:
		return
	var cl: Dictionary = gm.campaign_level
	if cl.is_empty():
		campaign_panel.visible = false
		return
	campaign_panel.visible = true
	var level_id: int = cl.get("id", 0)
	var target_wave: int = cl.get("target_wave", 0)
	var flawless := SaveManager.is_campaign_full_hp(level_id)
	var tags: Array[String] = []
	if not bool(cl.get("upgrades", true)):
		tags.append("NO-UP")
	var tag_text := " ".join(tags) if not tags.is_empty() else "STANDARD"
	lbl_campaign.text = "Stage %02d  Wave %d/%d\nFlawless %s  Clear %d\n%s" % [
		level_id,
		gm.wave,
		target_wave,
		"YES" if flawless else "NO",
		CampaignData.get_beaten_count(),
		tag_text,
	]

func _refresh_restrictions() -> void:
	if gm == null:
		return
	var cl: Dictionary = gm.campaign_level
	for ttype in tower_buttons:
		var btn: Button = tower_buttons[ttype]
		var locked: bool = (not cl.is_empty()) and (ttype not in cl.get("towers", []))
		btn.disabled = locked
		if locked:
			btn.modulate = Color(0.42, 0.42, 0.42, 0.80)
		else:
			btn.modulate = Color.WHITE
	for ptype in power_buttons:
		var pbtn: Button = power_buttons[ptype]
		var blocked: bool = (not cl.is_empty()) and (ptype not in cl.get("powers", []))
		pbtn.disabled = blocked
		if blocked:
			pbtn.modulate = Color(0.42, 0.42, 0.42, 0.80)
		else:
			pbtn.modulate = Color.WHITE
	_refresh_upgrade_buttons()

func _refresh_tower_cost_labels() -> void:
	for ttype in tower_buttons:
		var btn: Button = tower_buttons[ttype]
		var cost: int = GameData.get_tower(ttype)["cost"]
		if gm and gm.has_method("get_tower_cost"):
			cost = gm.get_tower_cost(ttype)
		btn.text = "%s\n%dg" % [TOWER_NAMES.get(ttype, "Tower"), cost]

func _refresh_upgrade_buttons() -> void:
	if upgrade_panel == null:
		return
	if gm == null or not gm.has_method("get_player_upgrade_costs"):
		upgrade_panel.visible = false
		return
	upgrade_panel.visible = true
	var costs: Dictionary = gm.get_player_upgrade_costs()
	var upgrades_allowed := true
	var cl: Dictionary = gm.campaign_level if gm else {}
	if not cl.is_empty():
		upgrades_allowed = bool(cl.get("upgrades", true))
	btn_up_damage.text = "ATK %dg" % int(costs.get("damage", 25))
	btn_up_speed.text = "SPD %dg" % int(costs.get("speed", 20))
	btn_up_hp.text = "HP %dg" % int(costs.get("hp", 30))
	btn_up_base.text = "BASE %dg" % int(costs.get("base", 40))
	btn_repair.text = "REPAIR %dg" % int(costs.get("repair", 20))
	btn_up_damage.disabled = (not upgrades_allowed) or gm.gold < int(costs.get("damage", 25))
	btn_up_speed.disabled = (not upgrades_allowed) or gm.gold < int(costs.get("speed", 20))
	btn_up_hp.disabled = (not upgrades_allowed) or gm.gold < int(costs.get("hp", 30))
	btn_up_base.disabled = (not upgrades_allowed) or gm.gold < int(costs.get("base", 40))
	btn_repair.disabled = gm.gold < int(costs.get("repair", 20)) or gm.base_hp >= gm.max_base_hp

func _update_power_buttons() -> void:
	if gm == null:
		return
	for ptype in power_buttons:
		var btn: Button = power_buttons[ptype]
		var cd: float = gm.power_cooldowns.get(ptype, 0.0)
		var active_target: bool = gm.power_targeting_active and gm.power_targeting_type == ptype
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if active_target:
			btn.modulate = Color(1.0, 0.96, 0.80, 1.0)
		if cd > 0.0:
			btn.text = "%.0fs" % ceil(cd)
			btn.disabled = true
		else:
			btn.text = POWER_NAMES.get(ptype, "PWR")
			var cl: Dictionary = gm.campaign_level
			btn.disabled = (not cl.is_empty()) and (ptype not in cl.get("powers", []))

func _update_placement_hint() -> void:
	if gm == null:
		return
	if gm.placement_active:
		var tower_name := str(TOWER_NAMES.get(gm.placement_tower_type, "Tower"))
		var state := "Move into the field"
		var color := Color(0.86, 0.94, 1.0)
		if gm.placement_preview_pos.x < 0:
			state = "Move into the field"
		elif gm.placement_preview_valid:
			state = "Tap to deploy"
			color = Color(0.72, 1.0, 0.78)
		else:
			state = "Too close to road, base, or another tower"
			color = Color(1.0, 0.62, 0.56)
		lbl_placement.text = "%s placement\n%s" % [tower_name, state]
		lbl_placement.add_theme_color_override("font_color", color)
		return

	if gm.power_targeting_active:
		var power_name := str(POWER_NAMES.get(gm.power_targeting_type, "POWER"))
		lbl_placement.text = "%s armed\nTap a target point (PPM to cancel)" % power_name
		lbl_placement.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))

func _refresh_speed_label() -> void:
	btn_speed.text = "%dx" % (_speed_idx + 1)
	if gm:
		btn_auto_wave.text = "Auto On" if gm.auto_wave else "Auto Off"

func _refresh_dash_button() -> void:
	if btn_dash == null:
		return
	if gm == null or not gm.has_method("get_dash_cooldown_remaining"):
		btn_dash.visible = false
		return
	btn_dash.visible = true
	var cd: float = gm.get_dash_cooldown_remaining()
	if cd > 0.01:
		btn_dash.text = "D %.0fs" % ceil(cd)
		btn_dash.disabled = true
	else:
		btn_dash.text = "Dash"
		btn_dash.disabled = false

func _on_toggle_tower_drawer() -> void:
	_set_tower_drawer(not _tower_drawer_open)
	SoundManager.play_ui_click()

func _set_tower_drawer(open: bool) -> void:
	_tower_drawer_open = open
	_tower_drawer_target_x = _tower_drawer_open_x if open else _tower_drawer_closed_x
	tower_drawer_button.text = "HIDE" if _tower_drawer_open else "BUILD"

func _show_warning(title: String, body: String, color: Color = Color(0.90, 0.42, 0.30), priority: int = 1, duration: float = 2.8) -> void:
	_warning_priority = clamp(priority, 1, 3)
	_warning_phase = 0.0
	lbl_warning_title.text = title
	lbl_warning_body.text = body
	lbl_warning_icon.text = "!!!" if _warning_priority >= 3 else ("!!" if _warning_priority == 2 else "i")
	lbl_warning_title.add_theme_color_override("font_color", color.lightened(0.18))
	lbl_warning_icon.add_theme_color_override("font_color", color.lightened(0.24))
	var bg := color.darkened(0.78)
	bg.a = 0.96
	var border := color.lightened(0.08)
	border.a = 0.72
	warning_panel.add_theme_stylebox_override("panel", _panel_style(bg, border, 22))
	warning_panel.visible = true
	warning_panel.scale = Vector2.ONE
	_warning_timer = maxf(1.8, duration)
	SoundManager.play_warning(_warning_priority >= 3)

func _make_panel(pos: Vector2, size: Vector2, color: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	panel.add_theme_stylebox_override("panel", _panel_style(color, border, radius))
	return panel

func _make_label(parent: Node, text: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _make_button(parent: Node, text: String, pos: Vector2, size: Vector2, callable: Callable, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = size
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(color, 14))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.10), 14, Color(0.70, 0.84, 0.98, 0.38), 2))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.14), 14))
	button.add_theme_stylebox_override("disabled", _button_style(color.darkened(0.24), 14, Color(0.34, 0.44, 0.56, 0.18), 1))
	parent.add_child(button)
	button.pressed.connect(callable)
	return button

func _add_panel_trim(panel: Panel, top_color: Color, bottom_color: Color) -> void:
	var top_glow := ColorRect.new()
	top_glow.position = Vector2(10, 10)
	top_glow.size = Vector2(panel.size.x - 20.0, 34)
	top_glow.color = top_color
	panel.add_child(top_glow)

	var bottom_glow := ColorRect.new()
	bottom_glow.position = Vector2(14, panel.size.y - 34.0)
	bottom_glow.size = Vector2(panel.size.x - 28.0, 18)
	bottom_glow.color = bottom_color
	panel.add_child(bottom_glow)

func _tower_button_color(ttype: int) -> Color:
	match ttype:
		GameData.TowerType.ARROW:
			return Color(0.12, 0.18, 0.28)
		GameData.TowerType.MAGIC:
			return Color(0.16, 0.12, 0.28)
		GameData.TowerType.CANNON:
			return Color(0.24, 0.12, 0.10)
		GameData.TowerType.POISON:
			return Color(0.10, 0.20, 0.14)
		GameData.TowerType.ICE, GameData.TowerType.TESLA:
			return Color(0.08, 0.18, 0.24)
		_:
			return Color(0.08, 0.14, 0.22)

func _power_button_color(ptype: int) -> Color:
	match ptype:
		GameData.PowerType.FIREBALL:
			return Color(0.24, 0.12, 0.08)
		GameData.PowerType.FREEZE:
			return Color(0.08, 0.16, 0.26)
		GameData.PowerType.HEAL:
			return Color(0.08, 0.20, 0.14)
		GameData.PowerType.LIGHTNING:
			return Color(0.18, 0.16, 0.08)
		_:
			return Color(0.10, 0.16, 0.22)

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
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 8
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
