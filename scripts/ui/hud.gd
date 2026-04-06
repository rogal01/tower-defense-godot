extends CanvasLayer

const SCREEN_SIZE := Vector2(480, 854)
const TOWER_NAMES := {
	GameData.TowerType.ARROW: "Arrow",
	GameData.TowerType.MAGIC: "Magic",
	GameData.TowerType.CANNON: "Cannon",
	GameData.TowerType.POISON: "Poison",
	GameData.TowerType.TESLA: "Tesla",
	GameData.TowerType.ICE: "Ice",
	GameData.TowerType.FLAME: "Flame",
	GameData.TowerType.NECRO: "Necro",
	GameData.TowerType.BALLISTA: "Ballista",
	GameData.TowerType.VORTEX: "Vortex",
	GameData.TowerType.HEALER: "Healer",
}
const POWER_NAMES := {
	GameData.PowerType.FIREBALL: "Fire",
	GameData.PowerType.FREEZE: "Freeze",
	GameData.PowerType.HEAL: "Heal",
	GameData.PowerType.LIGHTNING: "Bolt",
}
const TARGET_NAMES := ["CLOSE", "FIRST", "LAST", "STRONG"]
const TUTORIAL_PAGES := [
	"Build on marked ground, not on the road. Tap a tower button, then tap a build marker to place it.",
	"Preview panels show the next wave. Watch for boss warnings, dangerous modifiers, and map terrain effects.",
	"Tap a tower to upgrade or sell it. Powers cost gold, and faster game speed is great once your defense is stable.",
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

var btn_upgrade: Button
var btn_sell: Button
var btn_target: Button
var btn_speed: Button
var btn_auto_wave: Button
var tutorial_next_btn: Button
var tutorial_skip_btn: Button

var lbl_info_name: Label
var lbl_info_stats: Label
var lbl_warning_title: Label
var lbl_warning_body: Label
var lbl_wave_banner: Label
var lbl_tutorial_title: Label
var lbl_tutorial_body: Label
var lbl_achievement: Label

var _selected_tower: Node = null
var _speed_idx: int = 0
var _wave_banner_timer: float = 0.0
var _warning_timer: float = 0.0
var _achievement_timer: float = 0.0
var _wave_banner_pulse: float = 0.0
var _warning_color: Color = Color(0.9, 0.35, 0.2)
var _tutorial_index: int = 0

func _ready() -> void:
	gm = get_parent()
	_build_ui()
	_connect_signals()
	_refresh_all()
	if not SaveManager.get_bool("tutorial_seen", false):
		_show_tutorial()

func _build_ui() -> void:
	var root_bg := ColorRect.new()
	root_bg.size = SCREEN_SIZE
	root_bg.color = Color(0, 0, 0, 0)
	add_child(root_bg)

	_build_top_bar()
	_build_preview_panel()
	_build_campaign_panel()
	_build_warning_panel()
	_build_wave_banner()
	_build_achievement_banner()
	_build_info_panel()
	_build_tower_panel()
	_build_power_strip()
	_build_tutorial_panel()

	lbl_placement = _make_label(get_viewport(), "", Vector2(34, 566), 13, Color(1.0, 0.93, 0.72))
	lbl_placement.custom_minimum_size = Vector2(360, 56)
	lbl_placement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_placement.visible = false

func _build_top_bar() -> void:
	var top_bar := _make_panel(Vector2(0, 0), Vector2(480, 62), Color(0.04, 0.05, 0.10, 0.95))
	add_child(top_bar)

	lbl_gold = _make_label(top_bar, "Gold: 50", Vector2(10, 10), 17, Color(1.0, 0.84, 0.2))
	lbl_wave = _make_label(top_bar, "Wave 0", Vector2(142, 10), 17, Color(0.76, 0.9, 1.0))
	lbl_score = _make_label(top_bar, "Score 0", Vector2(268, 10), 15, Color(0.74, 0.8, 0.92))

	btn_speed = _make_button(top_bar, "1x", Vector2(330, 8), Vector2(42, 28), _on_speed_button)
	btn_auto_wave = _make_button(top_bar, "Auto", Vector2(376, 8), Vector2(48, 28), _on_auto_wave_button)
	var btn_pause := _make_button(top_bar, "Pause", Vector2(428, 8), Vector2(44, 28), _on_pause_button)
	btn_pause.add_theme_font_size_override("font_size", 11)

	var btn_help := _make_button(top_bar, "Help", Vector2(428, 32), Vector2(44, 22), _on_help_button)
	btn_help.add_theme_font_size_override("font_size", 10)

	lbl_hp = _make_label(top_bar, "HP 100/100", Vector2(10, 36), 13, Color(1.0, 0.85, 0.85))

	var hp_bg := ColorRect.new()
	hp_bg.position = Vector2(116, 38)
	hp_bg.size = Vector2(302, 14)
	hp_bg.color = Color(0.15, 0.05, 0.05, 0.88)
	top_bar.add_child(hp_bg)

	hp_fill = ColorRect.new()
	hp_fill.position = hp_bg.position
	hp_fill.size = hp_bg.size
	hp_fill.color = Color(0.2, 0.8, 0.3)
	top_bar.add_child(hp_fill)

	hp_glow = ColorRect.new()
	hp_glow.position = hp_bg.position
	hp_glow.size = Vector2(hp_bg.size.x, 3)
	hp_glow.color = Color(0.55, 1.0, 0.65, 0.35)
	top_bar.add_child(hp_glow)

func _build_preview_panel() -> void:
	preview_panel = _make_panel(Vector2(10, 74), Vector2(250, 118), Color(0.05, 0.08, 0.16, 0.92))
	add_child(preview_panel)

	lbl_preview_title = _make_label(preview_panel, "Next Wave", Vector2(12, 10), 18, Color(0.86, 0.93, 1.0))
	lbl_preview_body = _make_label(preview_panel, "", Vector2(12, 38), 13, Color(0.76, 0.83, 0.95))
	lbl_preview_body.custom_minimum_size = Vector2(224, 72)
	lbl_preview_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_campaign_panel() -> void:
	campaign_panel = _make_panel(Vector2(268, 74), Vector2(202, 118), Color(0.09, 0.09, 0.16, 0.92))
	add_child(campaign_panel)

	lbl_campaign = _make_label(campaign_panel, "", Vector2(12, 10), 14, Color(1.0, 0.86, 0.28))
	lbl_campaign.custom_minimum_size = Vector2(176, 86)
	lbl_campaign.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_warning_panel() -> void:
	warning_panel = _make_panel(Vector2(50, 214), Vector2(380, 98), Color(0.16, 0.06, 0.05, 0.96))
	warning_panel.visible = false
	add_child(warning_panel)

	lbl_warning_title = _make_label(warning_panel, "Warning", Vector2(14, 12), 24, Color(1.0, 0.86, 0.35))
	lbl_warning_body = _make_label(warning_panel, "", Vector2(14, 48), 14, Color(0.95, 0.92, 0.9))
	lbl_warning_body.custom_minimum_size = Vector2(350, 40)
	lbl_warning_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_wave_banner() -> void:
	wave_banner_panel = _make_panel(Vector2(74, 326), Vector2(332, 94), Color(0.04, 0.06, 0.18, 0.96))
	wave_banner_panel.visible = false
	add_child(wave_banner_panel)

	lbl_wave_banner = _make_label(wave_banner_panel, "Wave 1", Vector2(16, 16), 28, Color(0.92, 0.96, 1.0))
	lbl_wave_banner.custom_minimum_size = Vector2(300, 54)
	lbl_wave_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_achievement_banner() -> void:
	achievement_panel = _make_panel(Vector2(36, 196), Vector2(408, 68), Color(0.14, 0.11, 0.03, 0.95))
	achievement_panel.visible = false
	add_child(achievement_panel)

	lbl_achievement = _make_label(achievement_panel, "", Vector2(12, 12), 13, Color(1.0, 0.84, 0.22))
	lbl_achievement.custom_minimum_size = Vector2(384, 44)
	lbl_achievement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_info_panel() -> void:
	info_panel = _make_panel(Vector2(10, 602), Vector2(404, 120), Color(0.04, 0.05, 0.11, 0.96))
	info_panel.visible = false
	add_child(info_panel)

	lbl_info_name = _make_label(info_panel, "Tower", Vector2(12, 10), 16, Color(0.88, 0.95, 1.0))
	lbl_info_stats = _make_label(info_panel, "", Vector2(12, 34), 12, Color(0.72, 0.8, 0.9))
	lbl_info_stats.custom_minimum_size = Vector2(228, 72)
	lbl_info_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	btn_upgrade = _make_button(info_panel, "Upgrade", Vector2(250, 10), Vector2(138, 38), _on_upgrade_pressed)
	btn_sell = _make_button(info_panel, "Sell", Vector2(250, 54), Vector2(138, 28), _on_sell_pressed)
	btn_target = _make_button(info_panel, "Target: FIRST", Vector2(250, 86), Vector2(138, 24), _on_target_button)
	btn_target.add_theme_font_size_override("font_size", 10)

func _build_tower_panel() -> void:
	tower_panel = _make_panel(Vector2(0, 726), Vector2(480, 128), Color(0.03, 0.05, 0.11, 0.98))
	add_child(tower_panel)

	var tower_types: Array = GameData.TowerType.values()
	for index in range(tower_types.size()):
		var ttype: int = tower_types[index]
		var column := index % 6
		var row := index / 6
		var btn := _make_button(
			tower_panel,
			"%s\n%dg" % [TOWER_NAMES.get(ttype, "Tower"), GameData.get_tower(ttype)["cost"]],
			Vector2(8 + column * 78, 8 + row * 56),
			Vector2(72, 48),
			_on_tower_button.bind(ttype)
		)
		btn.add_theme_font_size_override("font_size", 10)
		tower_buttons[ttype] = btn

func _build_power_strip() -> void:
	var strip := _make_panel(Vector2(418, 360), Vector2(54, 234), Color(0.05, 0.05, 0.12, 0.94))
	add_child(strip)

	var power_types: Array = GameData.PowerType.values()
	for index in range(power_types.size()):
		var ptype: int = power_types[index]
		var btn := _make_button(
			strip,
			POWER_NAMES.get(ptype, "Power"),
			Vector2(6, 8 + index * 56),
			Vector2(42, 48),
			_on_power_button.bind(ptype)
		)
		btn.add_theme_font_size_override("font_size", 10)
		power_buttons[ptype] = btn

func _build_tutorial_panel() -> void:
	tutorial_panel = _make_panel(Vector2(28, 170), Vector2(424, 250), Color(0.03, 0.05, 0.10, 0.98))
	tutorial_panel.visible = false
	add_child(tutorial_panel)

	lbl_tutorial_title = _make_label(tutorial_panel, "How To Play", Vector2(16, 16), 24, Color(0.9, 0.96, 1.0))
	lbl_tutorial_body = _make_label(tutorial_panel, "", Vector2(16, 58), 15, Color(0.78, 0.86, 0.95))
	lbl_tutorial_body.custom_minimum_size = Vector2(392, 120)
	lbl_tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	tutorial_next_btn = _make_button(tutorial_panel, "Next", Vector2(226, 192), Vector2(86, 38), _on_tutorial_next)
	tutorial_skip_btn = _make_button(tutorial_panel, "Close", Vector2(320, 192), Vector2(86, 38), _on_tutorial_close)

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
	if gm.has_signal("game_configured"):
		gm.game_configured.connect(_refresh_all)
	if gm.has_signal("warning_requested"):
		gm.warning_requested.connect(_show_warning)
	if AchievementManager.has_signal("achievement_unlocked"):
		AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _refresh_all() -> void:
	if gm == null:
		return
	_on_gold_changed(gm.gold)
	_on_score_changed(gm.score)
	_on_hp_changed(gm.base_hp, gm.max_base_hp)
	_on_wave_changed(gm.wave)
	_refresh_restrictions()
	_refresh_wave_preview()
	_refresh_campaign_panel()
	_refresh_speed_label()

func _process(delta: float) -> void:
	if _wave_banner_timer > 0.0:
		_wave_banner_timer -= delta
		_wave_banner_pulse += delta * 4.0
		var pulse := 1.0 + sin(_wave_banner_pulse) * 0.04
		wave_banner_panel.scale = Vector2.ONE * pulse
		if _wave_banner_timer <= 0.0:
			wave_banner_panel.visible = false
			wave_banner_panel.scale = Vector2.ONE

	if _warning_timer > 0.0:
		_warning_timer -= delta
		if _warning_timer <= 0.0:
			warning_panel.visible = false

	if _achievement_timer > 0.0:
		_achievement_timer -= delta
		if _achievement_timer <= 0.0:
			achievement_panel.visible = false

	_update_power_buttons()
	_update_placement_hint()

	if _selected_tower and is_instance_valid(_selected_tower):
		_refresh_info_panel(_selected_tower)
	elif _selected_tower != null:
		_deselect_tower()

func _on_gold_changed(new_gold: int) -> void:
	lbl_gold.text = "Gold: %d" % new_gold
	for ttype in tower_buttons:
		var btn: Button = tower_buttons[ttype]
		var cost: int = GameData.get_tower(ttype)["cost"]
		btn.modulate = Color.WHITE if new_gold >= cost else Color(0.48, 0.48, 0.48)
	_refresh_wave_preview()
	_refresh_info_panel(_selected_tower)

func _on_score_changed(new_score: int) -> void:
	lbl_score.text = "Score %d" % new_score

func _on_hp_changed(hp: float, max_hp: float) -> void:
	if max_hp <= 0.0:
		return
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	hp_fill.size.x = 302.0 * ratio
	hp_glow.size.x = hp_fill.size.x
	if ratio > 0.5:
		hp_fill.color = Color(0.24, 0.82, 0.32)
		hp_glow.color = Color(0.55, 1.0, 0.68, 0.35)
	elif ratio > 0.25:
		hp_fill.color = Color(0.95, 0.75, 0.18)
		hp_glow.color = Color(1.0, 0.92, 0.4, 0.35)
	else:
		hp_fill.color = Color(0.88, 0.24, 0.24)
		hp_glow.color = Color(1.0, 0.55, 0.55, 0.35)
	lbl_hp.text = "HP %d/%d" % [int(hp), int(max_hp)]

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
	_wave_banner_timer = 2.2
	_wave_banner_pulse = 0.0
	_refresh_wave_preview()

func _on_tower_selected(tower_node: Node) -> void:
	if _selected_tower and is_instance_valid(_selected_tower) and _selected_tower != tower_node:
		_selected_tower.set_show_range(false)
	_selected_tower = tower_node
	if is_instance_valid(_selected_tower):
		_selected_tower.set_show_range(true)
		info_panel.visible = true
		_refresh_info_panel(_selected_tower)

func _on_placement_mode(active: bool, _tower_type: int) -> void:
	lbl_placement.visible = active
	if not active:
		lbl_placement.text = ""
		return
	_update_placement_hint()

func _on_achievement_unlocked(achievement: Dictionary) -> void:
	lbl_achievement.text = "%s\n%s" % [achievement.get("title", "Achievement"), achievement.get("desc", "")]
	achievement_panel.visible = true
	_achievement_timer = 3.4

func _on_tower_button(ttype: int) -> void:
	if gm == null:
		return
	var cl: Dictionary = gm.campaign_level
	if not cl.is_empty() and ttype not in cl.get("towers", []):
		_show_warning("Tower Locked", "This level restricts which towers can be built.", Color(0.85, 0.35, 0.3))
		return
	if gm.placement_active and gm.placement_tower_type == ttype:
		gm.cancel_placement()
	else:
		_deselect_tower()
		gm.start_placement(ttype)
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_ui_click()

func _on_power_button(ptype: int) -> void:
	if gm == null:
		return
	gm.use_power(ptype, Vector2(240, 360))

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
	gm.target_mode = (gm.target_mode + 1) % TARGET_NAMES.size()
	_refresh_info_panel(_selected_tower)

func _on_speed_button() -> void:
	_speed_idx = (_speed_idx + 1) % 3
	if gm:
		gm.set_game_speed(_speed_idx + 1)
	_refresh_speed_label()
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_ui_click()

func _on_auto_wave_button() -> void:
	if gm == null:
		return
	gm.auto_wave = not gm.auto_wave
	btn_auto_wave.text = "Auto On" if gm.auto_wave else "Auto Off"
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_ui_click()

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
	lbl_tutorial_title.text = "How To Play %d/%d" % [_tutorial_index + 1, TUTORIAL_PAGES.size()]
	lbl_tutorial_body.text = TUTORIAL_PAGES[_tutorial_index]
	tutorial_next_btn.text = "Done" if _tutorial_index == TUTORIAL_PAGES.size() - 1 else "Next"

func _refresh_info_panel(tower_node: Node) -> void:
	if tower_node == null or not is_instance_valid(tower_node):
		return
	var tdata := GameData.get_tower(tower_node.tower_type)
	var upgrade_cost := GameData.tower_upgrade_cost(tdata["cost"], tower_node.level)
	var sell_val := GameData.tower_sell_value(tdata["cost"], tower_node.level, gm.skill_sell_bonus if gm else 0.0)
	lbl_info_name.text = "%s Tower Lv%d" % [TOWER_NAMES.get(tower_node.tower_type, "Tower"), tower_node.level]
	lbl_info_stats.text = "DMG %.0f  RNG %.0f  SPD %.2f\nType: %s\n%s" % [
		tower_node.damage,
		tower_node.attack_range,
		tower_node.fire_rate,
		GameData.DamageType.keys()[tower_node.damage_type],
		tdata.get("desc", "")
	]
	btn_sell.text = "Sell %dg" % sell_val
	if tower_node.level >= 10:
		btn_upgrade.text = "Max Level"
		btn_upgrade.disabled = true
	else:
		btn_upgrade.text = "Upgrade %dg" % upgrade_cost
		btn_upgrade.disabled = gm == null or gm.gold < upgrade_cost
	btn_target.text = "Target: %s" % TARGET_NAMES[gm.target_mode if gm else 0]

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
	lbl_preview_title.text = preview.get("title", "Next Wave")
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
	var stars: int = SaveManager.get_campaign_stars(level_id)
	var beaten := CampaignData.get_beaten_count()
	lbl_campaign.text = "Campaign %d/40\nWave %d/%d\nStars %d   Cleared %d" % [
		level_id,
		gm.wave,
		target_wave,
		stars,
		beaten
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
			btn.modulate = Color(0.35, 0.35, 0.35, 0.7)
		else:
			btn.modulate = Color.WHITE
	for ptype in power_buttons:
		var pbtn: Button = power_buttons[ptype]
		var blocked: bool = (not cl.is_empty()) and (ptype not in cl.get("powers", []))
		pbtn.disabled = blocked
		if blocked:
			pbtn.modulate = Color(0.35, 0.35, 0.35, 0.7)
		else:
			pbtn.modulate = Color.WHITE

func _update_power_buttons() -> void:
	if gm == null:
		return
	for ptype in power_buttons:
		var btn: Button = power_buttons[ptype]
		var cd: float = gm.power_cooldowns.get(ptype, 0.0)
		if cd > 0.0:
			btn.text = "%.0fs" % ceil(cd)
		else:
			btn.text = POWER_NAMES.get(ptype, "Power")

func _update_placement_hint() -> void:
	if gm == null or not gm.placement_active:
		return
	var tname: String = str(TOWER_NAMES.get(gm.placement_tower_type, "Tower"))
	var state: String = "Ready"
	var color: Color = Color(1.0, 0.93, 0.72)
	if gm.placement_preview_pos.x < 0:
		state = "Move over a build marker"
	elif gm.placement_preview_valid:
		state = "Tap to place"
		color = Color(0.72, 1.0, 0.76)
	else:
		state = "Blocked spot"
		color = Color(1.0, 0.6, 0.55)
	lbl_placement.text = "%s placement\n%s" % [tname, state]
	lbl_placement.modulate = color

func _refresh_speed_label() -> void:
	btn_speed.text = "%dx" % (_speed_idx + 1)
	if gm:
		btn_auto_wave.text = "Auto On" if gm.auto_wave else "Auto Off"

func _show_warning(title: String, body: String, color: Color = Color(0.85, 0.35, 0.28)) -> void:
	_warning_color = color
	lbl_warning_title.text = title
	lbl_warning_body.text = body
	lbl_warning_title.add_theme_color_override("font_color", color.lightened(0.25))
	warning_panel.visible = true
	_warning_timer = 2.8
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_warning()

func _make_panel(pos: Vector2, size: Vector2, color: Color) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
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
	style.border_color = Color(0.35, 0.45, 0.7, 0.25)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _make_label(parent: Node, text: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _make_button(parent: Control, text: String, pos: Vector2, size: Vector2, callable: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = size
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color(0.87, 0.92, 1.0))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.14, 0.24)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.42, 0.52, 0.78, 0.25)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.12)
	hover.border_color = Color(0.56, 0.7, 0.95, 0.45)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = style.bg_color.darkened(0.18)
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled := style.duplicate() as StyleBoxFlat
	disabled.bg_color = style.bg_color.darkened(0.32)
	button.add_theme_stylebox_override("disabled", disabled)
	parent.add_child(button)
	button.pressed.connect(callable)
	return button
