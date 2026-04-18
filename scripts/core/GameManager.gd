# GameManager.gd — Core game controller: wave spawning, tower/enemy logic, economy, powers
extends Node2D

# ─── Signals (HUD and other nodes subscribe to these) ────────────────────────
signal gold_changed(new_gold: int)
signal score_changed(new_score: int)
signal base_hp_changed(hp: float, max_hp: float)
signal wave_changed(wave: int)
signal game_over_triggered(score: int, wave: int, is_high_score: bool)
signal wave_banner_shown(wave: int, modifier: int)
signal floating_text_requested(x: float, y: float, text: String, color: Color, duration: float, size: float)
signal tower_selected(tower_node)
signal placement_mode_changed(active: bool, tower_type: int)
signal power_targeting_mode_changed(active: bool, power_type: int)
signal campaign_won_triggered(stars: int, score: int, level_id: int)
signal warning_requested(title: String, body: String, color: Color, priority: int, duration: float)
signal game_configured

# ─── Scene references (set in game.tscn) ─────────────────────────────────────
@onready var enemy_container: Node2D = $EnemyContainer
@onready var player_container: Node2D = $PlayerContainer
@onready var tower_container: Node2D = $TowerContainer
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var effects_container: Node2D = $EffectsContainer
@onready var map_node: Node2D = $Map
@onready var hud: CanvasLayer = $HUD
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var pause_menu: CanvasLayer = $PauseMenu

# Preloaded scenes
var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var player_scene: PackedScene = preload("res://scenes/player.tscn")
var tower_scene: PackedScene = preload("res://scenes/tower.tscn")
var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
var floating_text_scene: PackedScene = preload("res://scenes/floating_text.tscn")
var powerup_scene: PackedScene = preload("res://scenes/power_up.tscn")

var powerup_timer: float = 0.0
var powerup_spawn_interval: float = 18.0
var gold: int = 50
var score: int = 0
var total_gold_earned: int = 0
var wave: int = 0
var base_hp: float = 100.0
var max_base_hp: float = 100.0
var game_over: bool = false
var is_paused: bool = false
var game_speed: int = 1        # 1, 2, or 3

# Wave state
var wave_in_progress: bool = false
var enemies_remaining: int = 0
var wave_timer: float = 5.0
var wave_delay: float = 5.0
var auto_wave: bool = false
var show_wave_banner: bool = false
var wave_banner_timer: float = 0.0
var elite_spawn_pending: bool = false
var non_boss_wave_counter: int = 0
var is_night_cycle: bool = false
var day_night_changed_this_wave: bool = false

# Difficulty / mode
var difficulty: int = 1         # 0=easy, 1=normal, 2=hard
var enemy_hp_mult: float = 1.0
var enemy_speed_mult: float = 1.0
var enemy_dmg_mult: float = 1.0
var gold_mult: float = 1.0
var spawn_rate_mult: float = 1.0
var is_endless: bool = false
var is_boss_rush: bool = false
var is_boss_gauntlet: bool = false
var is_daily_challenge: bool = false
var daily_challenge_seed: int = 0
var daily_challenge_modifiers: Array[int] = []
var is_randomizer_mode: bool = false
var randomizer_seed: int = 0
var randomizer_tower_costs: Dictionary = {}
var randomizer_power_cooldowns: Dictionary = {}
var randomizer_power_damage_mult: float = 1.0
var randomizer_start_gold: int = 50
var fog_of_war_active: bool = false
var fog_base_reveal_radius: float = 170.0
var fog_tower_reveal_mult: float = 0.9
var double_base_active: bool = false
var secondary_base_position: Vector2 = Vector2(336, 726)
var dual_base_pattern: String = "alternate"
var branching_active: bool = false
var mini_boss_interval: int = 0
var mini_bosses_pending: int = 0
var mini_boss_archetypes: Array[String] = []
var mini_boss_wave_queue: Array[String] = []
var campaign_level: Dictionary = {}   # Non-empty when in campaign mode

# Boss state
var boss_pool: Array = []
var current_boss_type: int = -1  # BossType or -1
var boss_interval: int = 5
var bosses_killed_this_run: int = 0
var current_wave_modifier: int = GameData.WaveModifier.NONE

# Economy
var interest_rate: float = 0.05
var base_hp_before_wave: float = 100.0
var diamonds_this_run: int = 0
var repairs_this_run: int = 0
var player_damage_level: int = 1
var player_speed_level: int = 1
var player_hp_level: int = 1
var base_hp_level: int = 1
var player_upgrades_bought: Dictionary = {
	"damage": false,
	"speed": false,
	"hp": false,
	"base": false,
}

# Combat tracking
var total_kills: int = 0
var combo_count: int = 0
var best_combo: int = 0
var combo_timer: float = 0.0
var combo_multiplier: float = 1.0
var crit_chance: float = 0.12

# Power cooldowns: PowerType -> float
var power_cooldowns: Dictionary = {}
var freeze_timer: float = 0.0
var powers_used_this_run: Dictionary = {}

# Targeting mode
var target_mode: int = GameData.TargetMode.FIRST

# Placement mode
var placement_active: bool = false
var placement_tower_type: int = GameData.TowerType.ARROW
var power_targeting_active: bool = false
var power_targeting_type: int = -1
var power_target_preview_pos: Vector2 = Vector2(-999, -999)

# Camera shake
var shake_timer: float = 0.0
var shake_intensity: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO

# Placement preview
var placement_preview_pos: Vector2 = Vector2(-999, -999)
var placement_preview_range: float = 200.0
var placement_preview_valid: bool = true
var placement_preview_anim: float = 0.0

# Ability flash effect
var ability_flash_color: Color = Color(0, 0, 0, 0)
var ability_flash_timer: float = 0.0

# Base damage flash effect
var base_flash_color: Color = Color(0, 0, 0, 0)
var base_flash_timer: float = 0.0

# Map / paths — array of Array[Vector2]
var paths: Array = []
var map_type: int = GameData.MapType.CLASSIC
var base_position: Vector2 = Vector2(240, 726)
var terrain_zones: Array = []
var terrain_tick_timer: float = 0.0

# Screen size
var screen_w: float = 480.0
var screen_h: float = 854.0

# Skill bonuses (loaded from SaveManager at start)
var skill_tower_damage_bonus: float = 1.0
var skill_gold_bonus: float = 1.0
var skill_ability_cd_mult: float = 1.0
var skill_sell_bonus: float = 0.0
var skill_ice_slow_bonus: float = 0.0

# Achievement tracking
var towers_placed_types: Array = []
var ability_types_used_run: Array = []
var traps_placed_run: int = 0

# Play time
var play_time: float = 0.0
var player_node: Node2D = null

# ─── Init ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	reset()
	# Connect floating text signal to local spawner
	floating_text_requested.connect(_spawn_floating_text_node)
	powerup_timer = randf_range(10.0, powerup_spawn_interval)
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_battle_music()

# Resets all game state to initial values
func reset() -> void:
	screen_w = 480.0
	screen_h = 854.0
	base_position = Vector2(screen_w * 0.5, screen_h * 0.85)
	gold = 50
	score = 0
	total_gold_earned = 0
	wave = 0
	base_hp = 100.0
	max_base_hp = 100.0
	game_over = false
	is_paused = false
	game_speed = 1
	wave_in_progress = false
	enemies_remaining = 0
	wave_timer = 5.0
	wave_delay = 5.0
	auto_wave = false
	show_wave_banner = false
	wave_banner_timer = 0.0
	elite_spawn_pending = false
	non_boss_wave_counter = 0
	is_night_cycle = false
	day_night_changed_this_wave = false
	difficulty = 1
	enemy_hp_mult = 1.0
	enemy_speed_mult = 1.0
	enemy_dmg_mult = 1.0
	gold_mult = 1.0
	spawn_rate_mult = 1.0
	is_endless = false
	is_boss_rush = false
	is_boss_gauntlet = false
	is_daily_challenge = false
	daily_challenge_seed = 0
	daily_challenge_modifiers = []
	is_randomizer_mode = false
	randomizer_seed = 0
	randomizer_tower_costs = {}
	randomizer_power_cooldowns = {}
	randomizer_power_damage_mult = 1.0
	randomizer_start_gold = 50
	fog_of_war_active = false
	double_base_active = false
	secondary_base_position = Vector2(screen_w * 0.7, screen_h * 0.85)
	dual_base_pattern = "alternate"
	branching_active = false
	mini_boss_interval = 0
	mini_bosses_pending = 0
	mini_boss_archetypes.clear()
	mini_boss_wave_queue.clear()
	campaign_level = {}
	boss_pool = []
	current_boss_type = -1
	boss_interval = 5
	bosses_killed_this_run = 0
	current_wave_modifier = GameData.WaveModifier.NONE
	interest_rate = 0.05
	base_hp_before_wave = 100.0
	diamonds_this_run = 0
	repairs_this_run = 0
	player_damage_level = 1
	player_speed_level = 1
	player_hp_level = 1
	base_hp_level = 1
	player_upgrades_bought = {
		"damage": false,
		"speed": false,
		"hp": false,
		"base": false,
	}
	total_kills = 0
	combo_count = 0
	best_combo = 0
	combo_timer = 0.0
	combo_multiplier = 1.0
	crit_chance = 0.12
	power_cooldowns = {}
	freeze_timer = 0.0
	powers_used_this_run = {}
	target_mode = GameData.TargetMode.FIRST
	placement_active = false
	placement_tower_type = GameData.TowerType.ARROW
	power_targeting_active = false
	power_targeting_type = -1
	power_target_preview_pos = Vector2(-999, -999)
	shake_timer = 0.0
	shake_intensity = 0.0
	shake_offset = Vector2.ZERO
	placement_preview_pos = Vector2(-999, -999)
	placement_preview_valid = false
	placement_preview_anim = 0.0
	paths = []
	map_type = GameData.MapType.CLASSIC
	base_position = Vector2(240, 726)
	terrain_zones = []
	terrain_tick_timer = 0.0
	towers_placed_types = []
	ability_types_used_run = []
	traps_placed_run = 0
	play_time = 0.0
	# Clear containers if they exist
	if enemy_container:
		for c in enemy_container.get_children():
			c.queue_free()
	if player_container:
		for c in player_container.get_children():
			c.queue_free()
	if tower_container:
		for c in tower_container.get_children():
			c.queue_free()
	if projectile_container:
		for c in projectile_container.get_children():
			c.queue_free()
	if effects_container:
		for c in effects_container.get_children():
			c.queue_free()
	_load_skill_bonuses()
	_init_powers()
	generate_paths()
	_generate_terrain_zones()
	_sync_map_visuals()
	_spawn_player()
	gold_changed.emit(gold)
	score_changed.emit(score)
	base_hp_changed.emit(base_hp, max_base_hp)
	wave_changed.emit(wave)

func configure(p_difficulty: int, p_map_type: int) -> void:
	if p_difficulty == 3:
		configure_endless(1, p_map_type)
		return
	clear_saved_run()
	campaign_level = {}
	is_endless = false
	is_boss_rush = false
	is_boss_gauntlet = false
	is_daily_challenge = false
	daily_challenge_seed = 0
	daily_challenge_modifiers = []
	is_randomizer_mode = false
	randomizer_seed = 0
	randomizer_tower_costs = {}
	randomizer_power_cooldowns = {}
	randomizer_power_damage_mult = 1.0
	randomizer_start_gold = 50
	fog_of_war_active = false
	double_base_active = false
	dual_base_pattern = "alternate"
	branching_active = false
	mini_boss_interval = 0
	mini_bosses_pending = 0
	mini_boss_archetypes.clear()
	mini_boss_wave_queue.clear()
	map_type = p_map_type
	secondary_base_position = _get_secondary_base_position()
	_apply_difficulty(p_difficulty)
	AchievementManager.reset_run()
	_load_skill_bonuses()
	_init_powers()
	generate_paths()
	_generate_terrain_zones()
	_sync_map_visuals()
	_spawn_player()
	_broadcast_state()

func configure_endless(p_difficulty: int, p_map_type: int) -> void:
	clear_saved_run()
	campaign_level = {}
	map_type = p_map_type
	is_endless = true
	is_boss_rush = false
	is_boss_gauntlet = false
	is_daily_challenge = false
	daily_challenge_seed = 0
	daily_challenge_modifiers = []
	is_randomizer_mode = false
	randomizer_seed = 0
	randomizer_tower_costs = {}
	randomizer_power_cooldowns = {}
	randomizer_power_damage_mult = 1.0
	randomizer_start_gold = 50
	fog_of_war_active = false
	double_base_active = false
	dual_base_pattern = "alternate"
	branching_active = false
	mini_boss_interval = 0
	mini_bosses_pending = 0
	mini_boss_archetypes.clear()
	mini_boss_wave_queue.clear()
	secondary_base_position = _get_secondary_base_position()
	_apply_standard_difficulty(p_difficulty)
	AchievementManager.reset_run()
	_load_skill_bonuses()
	_init_powers()
	generate_paths()
	_generate_terrain_zones()
	_sync_map_visuals()
	_spawn_player()
	_broadcast_state()

func configure_daily_challenge(p_map_type: int) -> void:
	configure(1, p_map_type)
	is_daily_challenge = true
	var date := Time.get_date_dict_from_system()
	daily_challenge_seed = int(date.get("year", 0)) * 10000 + int(date.get("month", 0)) * 100 + int(date.get("day", 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = daily_challenge_seed
	var all_mods: Array = []
	for mod in GameData.get_canonical_wave_modifiers():
		if mod != GameData.WaveModifier.NONE:
			all_mods.append(mod)
	daily_challenge_modifiers.clear()
	for _i in range(3):
		if all_mods.is_empty():
			break
		daily_challenge_modifiers.append(all_mods[rng.randi_range(0, all_mods.size() - 1)])
	_emit_warning(
		"Daily Challenge",
		"Today's modifier rotation is active. Adapt your tower mix each wave.",
		Color(0.82, 0.90, 1.0),
		2,
		3.4
	)
	_broadcast_state()

func configure_randomizer(p_map_type: int = -1) -> void:
	var map_values: Array = GameData.get_canonical_map_types()
	var resolved_map := p_map_type
	if resolved_map < 0 or resolved_map >= map_values.size():
		resolved_map = map_values[randi() % map_values.size()]
	configure(1, resolved_map)
	is_randomizer_mode = true
	randomizer_seed = int(Time.get_unix_time_from_system())
	var rng := RandomNumberGenerator.new()
	rng.seed = randomizer_seed

	randomizer_start_gold = rng.randi_range(20, 150)
	randomizer_tower_costs.clear()
	for ttype in GameData.get_canonical_tower_types():
		var base_cost := int(GameData.get_tower(ttype).get("cost", 50))
		randomizer_tower_costs[ttype] = maxi(5, int(round(base_cost * rng.randf_range(0.5, 2.0))))

	randomizer_power_cooldowns.clear()
	for ptype in GameData.get_canonical_power_types():
		var base_cd := float(GameData.get_power(ptype).get("cooldown", 8.0))
		randomizer_power_cooldowns[ptype] = base_cd * rng.randf_range(0.4, 1.8)

	randomizer_power_damage_mult = rng.randf_range(0.5, 2.5)
	enemy_hp_mult = rng.randf_range(0.5, 2.0)
	enemy_dmg_mult = rng.randf_range(0.5, 2.0)
	enemy_speed_mult = rng.randf_range(0.7, 1.5)
	gold_mult = rng.randf_range(0.5, 2.0)
	spawn_rate_mult = rng.randf_range(0.6, 1.6)
	gold = randomizer_start_gold + SaveManager.get_skill_level("start_gold") * 25

	if is_instance_valid(player_node):
		player_node.attack_damage *= rng.randf_range(0.7, 1.5)
		player_node.move_speed *= rng.randf_range(0.7, 1.5)
		player_node.attack_range *= rng.randf_range(0.7, 1.5)

	_emit_warning(
		"Randomizer Active",
		"Economy, cooldowns, and enemy scaling are scrambled for this run.",
		Color(0.96, 0.74, 0.34),
		2,
		3.6
	)
	_broadcast_state()

func configure_continue_saved() -> bool:
	return load_game()

func configure_campaign(ld: Dictionary, selected_map: int = GameData.MapType.CLASSIC) -> void:
	clear_saved_run()
	campaign_level = ld
	map_type        = selected_map
	difficulty      = 1
	is_endless      = false
	is_boss_rush    = false
	is_boss_gauntlet = false
	is_daily_challenge = false
	daily_challenge_seed = 0
	daily_challenge_modifiers = []
	is_randomizer_mode = false
	randomizer_seed = 0
	randomizer_tower_costs = {}
	randomizer_power_cooldowns = {}
	randomizer_power_damage_mult = 1.0
	randomizer_start_gold = 50
	fog_of_war_active = false
	double_base_active = false
	dual_base_pattern = _get_dual_base_default_pattern()
	branching_active = false
	mini_boss_interval = 0
	mini_bosses_pending = 0
	mini_boss_archetypes = []
	mini_boss_wave_queue.clear()
	secondary_base_position = _get_secondary_base_position()
	boss_interval   = ld.get("boss_interval", 5)
	enemy_hp_mult    = ld.get("hp",    1.0)
	enemy_dmg_mult   = ld.get("dmg",   1.0)
	enemy_speed_mult = ld.get("spd",   1.0)
	gold_mult        = ld.get("gold",  1.0)
	spawn_rate_mult  = ld.get("spawn", 1.0)
	gold        = ld.get("starting_gold", 50)
	max_base_hp = 100.0
	base_hp     = 100.0
	AchievementManager.reset_run()
	_load_skill_bonuses()
	_init_powers()
	generate_paths()
	_generate_terrain_zones()
	_sync_map_visuals()
	_spawn_player()
	_broadcast_state()

func _broadcast_state() -> void:
	game_configured.emit()
	gold_changed.emit(gold)
	score_changed.emit(score)
	base_hp_changed.emit(base_hp, max_base_hp)
	wave_changed.emit(wave)

func _trigger_campaign_win() -> void:
	game_over = true
	clear_saved_run()
	var lid: int   = campaign_level.get("id",    0)
	var flawless := base_hp >= max_base_hp
	var stars: int = 3 if flawless else 1
	var diamonds_reward: int = campaign_level.get("diamonds", 3)
	var total_run_diamonds := diamonds_reward + diamonds_this_run
	if diamonds_reward > 0:
		AchievementManager.on_diamonds_earned(diamonds_reward)
	SaveManager.save_campaign_result(lid, flawless)
	if total_run_diamonds > 0:
		SaveManager.add_diamonds(total_run_diamonds)
		SaveManager.add_stat("lifetime_diamonds", total_run_diamonds)
	SaveManager.add_stat("lifetime_games", 1)
	SaveManager.add_stat("lifetime_waves", wave)
	SaveManager.add_stat("lifetime_score", score)
	SaveManager.add_stat("lifetime_kills", total_kills)
	SaveManager.add_stat("lifetime_gold", total_gold_earned)
	SaveManager.add_stat("lifetime_bosses", bosses_killed_this_run)
	SaveManager.set_stat_max("lifetime_best_combo", best_combo)
	SaveManager.flush()
	var beaten_count := CampaignData.get_beaten_count()
	var stars5_count := CampaignData.get_three_star_count()
	var total_levels := maxi(1, CampaignData.get_total_levels())
	AchievementManager.on_campaign_result(lid, stars, base_hp >= max_base_hp,
		beaten_count, stars5_count, total_levels)
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_victory_stinger()
		get_node("/root/SoundManager").play_victory_music()
	campaign_won_triggered.emit(stars, score, lid)

func _apply_standard_difficulty(level: int) -> void:
	difficulty = clamp(level, 0, 2)
	match difficulty:
		0:
			enemy_hp_mult = 0.72
			enemy_dmg_mult = 0.65
			enemy_speed_mult = 0.9
			gold_mult = 1.25
			spawn_rate_mult = 0.9
			gold = 85
		2:
			enemy_hp_mult = 1.45
			enemy_dmg_mult = 1.35
			enemy_speed_mult = 1.12
			gold_mult = 0.82
			spawn_rate_mult = 1.18
			gold = 35
		_:
			enemy_hp_mult = 1.0
			enemy_dmg_mult = 1.0
			enemy_speed_mult = 1.0
			gold_mult = 1.0
			spawn_rate_mult = 1.0
			gold = 55
	boss_interval = 5

func apply_endless_sub_difficulty(sub_diff: int) -> void:
	is_endless = true
	_apply_standard_difficulty(sub_diff)

func _apply_difficulty(level: int) -> void:
	is_endless = false
	is_boss_rush = false
	is_boss_gauntlet = false
	match level:
		4:
			is_boss_rush = true
			_apply_standard_difficulty(1)
			gold_mult = 1.45
			spawn_rate_mult = 0.75
			gold = 100
			boss_interval = 1
		5:
			is_boss_gauntlet = true
			_apply_standard_difficulty(1)
			gold_mult = 1.2
			spawn_rate_mult = 0.6
			gold = 90
			boss_interval = 1
		_:
			_apply_standard_difficulty(level)

func _load_skill_bonuses() -> void:
	var td := SaveManager.get_skill_level("tower_damage")
	skill_tower_damage_bonus = 1.0 + td * 0.08
	var gb := SaveManager.get_skill_level("gold_bonus")
	skill_gold_bonus = 1.0 + gb * 0.10
	var cd := SaveManager.get_skill_level("ability_cd")
	skill_ability_cd_mult = 1.0 - cd * 0.05
	var sb := SaveManager.get_skill_level("sell_bonus")
	skill_sell_bonus = sb * 0.10
	var ip := SaveManager.get_skill_level("ice_power")
	skill_ice_slow_bonus = ip * 0.15

	var sg := SaveManager.get_skill_level("start_gold")
	gold += sg * 25
	var bh := SaveManager.get_skill_level("base_hp")
	max_base_hp += bh * 20.0
	base_hp = max_base_hp

func get_tower_cost(tower_type: int) -> int:
	if is_randomizer_mode:
		return int(randomizer_tower_costs.get(tower_type, GameData.get_tower(tower_type).get("cost", 0)))
	return int(GameData.get_tower(tower_type).get("cost", 0))

func get_power_cooldown(power_type: int) -> float:
	if is_randomizer_mode:
		return float(randomizer_power_cooldowns.get(power_type, GameData.get_power(power_type).get("cooldown", 0.0)))
	return float(GameData.get_power(power_type).get("cooldown", 0.0))

func get_player_upgrade_costs() -> Dictionary:
	return {
		"damage": player_damage_level * 25,
		"speed": player_speed_level * 20,
		"hp": player_hp_level * 30,
		"base": base_hp_level * 40,
		"repair": 20,
	}

func _init_powers() -> void:
	for pt in GameData.get_canonical_power_types():
		power_cooldowns[pt] = 0.0

func _spawn_player() -> void:
	if not is_instance_valid(player_container) or player_scene == null:
		player_node = null
		return
	for child in player_container.get_children():
		child.queue_free()
	var p := player_scene.instantiate() as Node2D
	if p == null:
		player_node = null
		return
	player_container.add_child(p)
	p.position = base_position + Vector2(0, -96)
	if p.has_method("setup_from_skills"):
		p.setup_from_skills()
	player_node = p

# ─── Main Update Loop ─────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if game_over or is_paused:
		return

	var dt: float = delta * game_speed
	play_time += delta

	# Camera shake decay
	if shake_timer > 0:
		shake_timer -= delta
		var s: float = shake_intensity * clampf(shake_timer / 0.5, 0.0, 1.0)
		shake_offset = Vector2(randf_range(-s, s), randf_range(-s, s))
		if map_node:
			map_node.position = shake_offset
	elif shake_offset != Vector2.ZERO:
		shake_offset = Vector2.ZERO
		if map_node:
			map_node.position = Vector2.ZERO

	# Wave timer between waves
	if not wave_in_progress and _enemy_count() == 0:
		wave_timer -= dt
		if auto_wave or wave_timer <= 0:
			_start_next_wave()

	# Wave banner decay
	if show_wave_banner:
		wave_banner_timer -= dt
		if wave_banner_timer <= 0:
			show_wave_banner = false

	# Placement/power target preview animation
	if placement_active or power_targeting_active:
		placement_preview_anim += delta
		queue_redraw()

	# Ability flash decay
	if ability_flash_timer > 0:
		ability_flash_timer -= delta
		ability_flash_color.a = maxf(0.0, ability_flash_timer / 0.3 * 0.15)
		queue_redraw()

	# Base damage flash decay
	if base_flash_timer > 0:
		base_flash_timer -= dt
		base_flash_color.a = maxf(0.0, base_flash_timer / 0.15 * 0.25)
		queue_redraw()

	# Spawn next enemy from pool
	if wave_in_progress and enemies_remaining > 0:
		# Spawn-rate: 1 enemy when under 10 on field
		if _enemy_count() < 10 and randf() < dt * 2.5:
			_spawn_enemy()
			enemies_remaining -= 1

	# Power cooldowns
	for pt in power_cooldowns:
		if power_cooldowns[pt] > 0:
			power_cooldowns[pt] = maxf(0.0, power_cooldowns[pt] - dt)

	if freeze_timer > 0:
		freeze_timer -= dt

	# Combo decay
	if combo_timer > 0:
		combo_timer -= dt
		if combo_timer <= 0:
			if combo_count >= 5:
				_on_combo_expire()
			combo_count = 0
			combo_multiplier = 1.0

	# Power-up spawn logic
	if not game_over:
		powerup_timer -= delta
		if powerup_timer <= 0.0:
			_spawn_powerup()
			powerup_timer = randf_range(powerup_spawn_interval * 0.7, powerup_spawn_interval * 1.3)

	# Update all enemies
	_update_enemies(dt)
	_apply_terrain_effects(dt)

	# Check wave complete
	if wave_in_progress and _enemy_count() == 0 and enemies_remaining <= 0:
		_on_wave_complete()

	# Achievement gold/score checks
	AchievementManager.on_gold_checked(gold)
	AchievementManager.on_score_checked(score)

# Spawns a random power-up on the map
func _spawn_powerup() -> void:
	var pu = powerup_scene.instantiate()
	var px: float = randf_range(60, screen_w - 60)
	var py: float = randf_range(120, screen_h - 180)
	pu.position = Vector2(px, py)
	var power_types: Array = GameData.get_canonical_power_types()
	pu.power_type = power_types[randi() % power_types.size()]
	pu.connect("collected", Callable(self, "_on_powerup_collected"))
	effects_container.add_child(pu)

# Handles power-up collection
func _on_powerup_collected(power_type: int) -> void:
	use_power(power_type, Vector2(screen_w * 0.5, screen_h * 0.5))

# ─── Path Generation ──────────────────────────────────────────────────────────

func generate_paths() -> void:
	paths.clear()
	var bx: float = base_position.x
	var by: float = base_position.y
	var w: float = screen_w
	var h: float = screen_h

	match map_type:
		GameData.MapType.CLASSIC:      _gen_classic_paths(w, h, bx, by)
		GameData.MapType.VALLEY:       _gen_valley_paths(w, h, bx, by)
		GameData.MapType.CROSSROADS:   _gen_crossroads_paths(w, h, bx, by)
		GameData.MapType.DESERT:       _gen_desert_paths(w, h, bx, by)
		GameData.MapType.SNOW:         _gen_snow_paths(w, h, bx, by)
	_retarget_paths_for_active_bases()

func _jitter(base: float, range_val: float) -> float:
	return base + randf_range(-range_val, range_val)

func _get_secondary_base_position() -> Vector2:
	match map_type:
		GameData.MapType.CLASSIC:
			return Vector2(screen_w * 0.73, screen_h * 0.84)
		GameData.MapType.VALLEY:
			return Vector2(screen_w * 0.30, screen_h * 0.84)
		GameData.MapType.CROSSROADS:
			return Vector2(screen_w * 0.72, screen_h * 0.84)
		GameData.MapType.DESERT:
			return Vector2(screen_w * 0.70, screen_h * 0.84)
		GameData.MapType.SNOW:
			return Vector2(screen_w * 0.31, screen_h * 0.84)
		_:
			return Vector2(screen_w * 0.70, screen_h * 0.84)

func _get_dual_base_default_pattern() -> String:
	match map_type:
		GameData.MapType.CROSSROADS:
			return "crossroads_split"
		GameData.MapType.VALLEY:
			return "adaptive"
		_:
			return "alternate"

func _get_active_base_positions() -> Array:
	var bases: Array = [base_position]
	if double_base_active:
		bases.append(secondary_base_position)
	return bases

func _is_too_close_to_any_base(pos: Vector2, min_distance: float) -> bool:
	for base_pos in _get_active_base_positions():
		if pos.distance_to(base_pos) < min_distance:
			return true
	return false

func _gen_classic_paths(w: float, h: float, bx: float, by: float) -> void:
	var j := 0.04
	# Left path
	paths.append([
		Vector2(_jitter(w*0.08, w*j), -40),
		Vector2(_jitter(w*0.15, w*j), _jitter(h*0.10, h*j)),
		Vector2(_jitter(w*0.28, w*j), _jitter(h*0.24, h*j)),
		Vector2(_jitter(w*0.10, w*j), _jitter(h*0.40, h*j)),
		Vector2(_jitter(w*0.26, w*j), _jitter(h*0.56, h*j)),
		Vector2(_jitter(w*0.16, w*j), _jitter(h*0.70, h*j)),
		Vector2(_jitter(w*0.36, w*j), _jitter(h*0.80, h*j)),
		Vector2(bx, by),
	])
	# Center path
	paths.append([
		Vector2(_jitter(w*0.50, w*j), -40),
		Vector2(_jitter(w*0.46, w*j), _jitter(h*0.09, h*j)),
		Vector2(_jitter(w*0.58, w*j), _jitter(h*0.24, h*j)),
		Vector2(_jitter(w*0.40, w*j), _jitter(h*0.40, h*j)),
		Vector2(_jitter(w*0.56, w*j), _jitter(h*0.56, h*j)),
		Vector2(_jitter(w*0.44, w*j), _jitter(h*0.70, h*j)),
		Vector2(bx, by),
	])
	# Right path
	paths.append([
		Vector2(_jitter(w*0.92, w*j), -40),
		Vector2(_jitter(w*0.85, w*j), _jitter(h*0.10, h*j)),
		Vector2(_jitter(w*0.72, w*j), _jitter(h*0.24, h*j)),
		Vector2(_jitter(w*0.90, w*j), _jitter(h*0.40, h*j)),
		Vector2(_jitter(w*0.74, w*j), _jitter(h*0.56, h*j)),
		Vector2(_jitter(w*0.84, w*j), _jitter(h*0.70, h*j)),
		Vector2(_jitter(w*0.64, w*j), _jitter(h*0.80, h*j)),
		Vector2(bx, by),
	])

func _gen_valley_paths(w: float, h: float, bx: float, by: float) -> void:
	var j := 0.05
	paths.append([
		Vector2(_jitter(w*0.50, w*j), -40),
		Vector2(_jitter(w*0.20, w*j), _jitter(h*0.08, h*j)),
		Vector2(_jitter(w*0.80, w*j), _jitter(h*0.20, h*j)),
		Vector2(_jitter(w*0.15, w*j), _jitter(h*0.34, h*j)),
		Vector2(_jitter(w*0.85, w*j), _jitter(h*0.48, h*j)),
		Vector2(_jitter(w*0.20, w*j), _jitter(h*0.62, h*j)),
		Vector2(_jitter(w*0.75, w*j), _jitter(h*0.74, h*j)),
		Vector2(bx, by),
	])
	paths.append([
		Vector2(_jitter(w*0.35, w*j), -40),
		Vector2(_jitter(w*0.70, w*j), _jitter(h*0.12, h*j)),
		Vector2(_jitter(w*0.25, w*j), _jitter(h*0.28, h*j)),
		Vector2(_jitter(w*0.75, w*j), _jitter(h*0.42, h*j)),
		Vector2(_jitter(w*0.30, w*j), _jitter(h*0.56, h*j)),
		Vector2(_jitter(w*0.65, w*j), _jitter(h*0.70, h*j)),
		Vector2(bx, by),
	])

func _gen_crossroads_paths(w: float, h: float, bx: float, by: float) -> void:
	var j := 0.03
	paths.append([Vector2(w*0.5, -40), Vector2(w*0.5, h*0.35), Vector2(w*0.25, h*0.5), Vector2(bx, by)])
	paths.append([Vector2(w*0.5, -40), Vector2(w*0.5, h*0.35), Vector2(w*0.75, h*0.5), Vector2(bx, by)])
	paths.append([Vector2(-40, h*0.35), Vector2(w*0.25, h*0.35), Vector2(w*0.5, h*0.55), Vector2(bx, by)])
	paths.append([Vector2(w+40, h*0.35), Vector2(w*0.75, h*0.35), Vector2(w*0.5, h*0.55), Vector2(bx, by)])

func _gen_desert_paths(w: float, h: float, bx: float, by: float) -> void:
	var j := 0.04
	paths.append([
		Vector2(_jitter(w*0.15, w*j), -40),
		Vector2(_jitter(w*0.30, w*j), _jitter(h*0.15, h*j)),
		Vector2(_jitter(w*0.50, w*j), _jitter(h*0.30, h*j)),
		Vector2(_jitter(w*0.70, w*j), _jitter(h*0.15, h*j)),
		Vector2(_jitter(w*0.85, w*j), _jitter(h*0.30, h*j)),
		Vector2(_jitter(w*0.60, w*j), _jitter(h*0.55, h*j)),
		Vector2(_jitter(w*0.40, w*j), _jitter(h*0.70, h*j)),
		Vector2(bx, by),
	])
	paths.append([
		Vector2(_jitter(w*0.85, w*j), -40),
		Vector2(_jitter(w*0.65, w*j), _jitter(h*0.18, h*j)),
		Vector2(_jitter(w*0.45, w*j), _jitter(h*0.35, h*j)),
		Vector2(_jitter(w*0.55, w*j), _jitter(h*0.55, h*j)),
		Vector2(bx, by),
	])

func _gen_snow_paths(w: float, h: float, bx: float, by: float) -> void:
	_gen_classic_paths(w, h, bx, by)  # Reuse classic layout with snow theme

func _gen_lava_paths(w: float, h: float, bx: float, by: float) -> void:
	var j := 0.03
	paths.append([
		Vector2(w*0.5, -40),
		Vector2(w*0.5, h*0.20),
		Vector2(w*0.15, h*0.35),
		Vector2(w*0.15, h*0.65),
		Vector2(bx, by),
	])
	paths.append([
		Vector2(w*0.5, -40),
		Vector2(w*0.5, h*0.20),
		Vector2(w*0.85, h*0.35),
		Vector2(w*0.85, h*0.65),
		Vector2(bx, by),
	])

func _gen_enchanted_paths(w: float, h: float, bx: float, by: float) -> void:
	var j := 0.05
	paths.append([
		Vector2(_jitter(w*0.30, w*j), -40),
		Vector2(_jitter(w*0.55, w*j), _jitter(h*0.12, h*j)),
		Vector2(_jitter(w*0.20, w*j), _jitter(h*0.28, h*j)),
		Vector2(_jitter(w*0.70, w*j), _jitter(h*0.42, h*j)),
		Vector2(_jitter(w*0.25, w*j), _jitter(h*0.60, h*j)),
		Vector2(_jitter(w*0.60, w*j), _jitter(h*0.74, h*j)),
		Vector2(bx, by),
	])
	paths.append([
		Vector2(_jitter(w*0.70, w*j), -40),
		Vector2(_jitter(w*0.45, w*j), _jitter(h*0.14, h*j)),
		Vector2(_jitter(w*0.80, w*j), _jitter(h*0.30, h*j)),
		Vector2(_jitter(w*0.30, w*j), _jitter(h*0.46, h*j)),
		Vector2(_jitter(w*0.75, w*j), _jitter(h*0.62, h*j)),
		Vector2(_jitter(w*0.40, w*j), _jitter(h*0.76, h*j)),
		Vector2(bx, by),
	])

func _gen_volcano_paths(w: float, h: float, bx: float, by: float) -> void:
	var j := 0.03
	paths.append([
		Vector2(w*0.1, h*0.1),
		Vector2(w*0.3, h*0.25),
		Vector2(w*0.15, h*0.45),
		Vector2(w*0.35, h*0.60),
		Vector2(bx, by),
	])
	paths.append([
		Vector2(w*0.9, h*0.1),
		Vector2(w*0.7, h*0.25),
		Vector2(w*0.85, h*0.45),
		Vector2(w*0.65, h*0.60),
		Vector2(bx, by),
	])
	paths.append([
		Vector2(w*0.5, h*0.0),
		Vector2(w*0.5, h*0.20),
		Vector2(w*0.40, h*0.40),
		Vector2(w*0.55, h*0.60),
		Vector2(bx, by),
	])

func _retarget_paths_for_active_bases() -> void:
	if not double_base_active:
		return
	for idx in range(paths.size()):
		var path: Array = paths[idx]
		if path.is_empty():
			continue
		path[path.size() - 1] = _get_path_target_base(path, idx)

func _get_path_target_base(path: Array, path_idx: int) -> Vector2:
	var pattern := dual_base_pattern
	if pattern == "":
		pattern = _get_dual_base_default_pattern()
	var default_secondary := (path_idx % 2) == 1
	var steer_secondary := default_secondary
	var approach_point: Vector2 = path[path.size() - 2] if path.size() >= 2 else path[0]
	match pattern:
		"crossroads_split":
			# Keep left-side routes on primary and right-side routes on secondary.
			steer_secondary = approach_point.x > screen_w * 0.52
		"adaptive":
			# Use nearest-base routing and break close ties by parity.
			var d_primary := approach_point.distance_to(base_position)
			var d_secondary := approach_point.distance_to(secondary_base_position)
			if absf(d_primary - d_secondary) < 14.0:
				steer_secondary = default_secondary
			else:
				steer_secondary = d_secondary < d_primary
		_:
			steer_secondary = default_secondary
	return secondary_base_position if steer_secondary else base_position

func _sync_map_visuals() -> void:
	if map_node == null:
		return
	map_node.paths = paths
	map_node.map_type = map_type
	map_node.base_position = base_position
	map_node.set("double_base_active", double_base_active)
	map_node.set("secondary_base_position", secondary_base_position)
	map_node.set("terrain_zones", terrain_zones)
	map_node.set("fog_of_war_active", fog_of_war_active)
	map_node.set("fog_base_reveal_radius", fog_base_reveal_radius)
	map_node.set("fog_tower_reveal_mult", fog_tower_reveal_mult)
	map_node.set("night_mode_active", is_night_cycle)
	if map_node.has_method("refresh_layout"):
		map_node.refresh_layout()
	else:
		map_node.queue_redraw()

func _is_night_wave(wave_number: int) -> bool:
	if wave_number < 8:
		return false
	return ((wave_number / 8) % 2) == 1

func _update_day_night_cycle() -> void:
	var was_night := is_night_cycle
	is_night_cycle = _is_night_wave(wave)
	day_night_changed_this_wave = was_night != is_night_cycle

func _generate_terrain_zones() -> void:
	terrain_zones.clear()
	match map_type:
		GameData.MapType.SNOW:
			terrain_zones.append({"kind": "frost", "pos": Vector2(118, 292), "radius": 44.0, "strength": 0.82})
			terrain_zones.append({"kind": "frost", "pos": Vector2(336, 506), "radius": 40.0, "strength": 0.8})
		GameData.MapType.DESERT:
			terrain_zones.append({"kind": "dune", "pos": Vector2(132, 252), "radius": 44.0, "speed": 1.12})
			terrain_zones.append({"kind": "dune", "pos": Vector2(332, 560), "radius": 40.0, "speed": 1.1})

func get_next_wave_preview() -> Dictionary:
	var next_wave: int = wave + 1
	var boss_wave := is_boss_gauntlet or is_boss_rush or (boss_interval > 0 and next_wave % boss_interval == 0)
	var title := "Next Wave %d" % next_wave
	var body_lines: Array[String] = []
	if boss_wave:
		var boss_types: Array = GameData.BossType.values()
		var preview_boss: int = boss_types[next_wave % boss_types.size()]
		var boss_name: String = GameData.get_boss(preview_boss).get("name", "Boss")
		body_lines.append("Boss incoming: %s" % boss_name)
		if is_boss_gauntlet:
			body_lines.append("Boss Gauntlet: every wave is a boss duel.")
		else:
			body_lines.append("Expect heavy damage and ability casts.")
	else:
		var count: int = int((3 + next_wave * 2) * spawn_rate_mult)
		body_lines.append("Approx enemies: %d" % min(count, 100))
		body_lines.append("Likely foes: %s" % _preview_enemy_names(next_wave))
	if is_daily_challenge and not daily_challenge_modifiers.is_empty():
		var daily_mod: int = daily_challenge_modifiers[next_wave % daily_challenge_modifiers.size()]
		var daily_info: Dictionary = GameData.MODIFIER_NAMES.get(daily_mod, {})
		body_lines.append("Daily modifier: %s" % str(daily_info.get("name", "Special")))
	elif next_wave >= 3:
		body_lines.append("Possible modifier: armored, fast, swarm, or rich.")
	var next_night := _is_night_wave(next_wave)
	if next_night != is_night_cycle:
		if next_night:
			body_lines.append("Time shift: Nightfall (+20% enemy HP, -10% tower range).")
		else:
			body_lines.append("Time shift: Daylight (normal visibility and tower range).")
	if (not boss_wave) and (non_boss_wave_counter >= 4):
		body_lines.append("Elite scout expected: crown target with bonus reward.")
	if mini_boss_interval > 0 and next_wave % mini_boss_interval == 0:
		body_lines.append("Mini-boss surge: %s" % _mini_boss_preview_text())
	if double_base_active:
		body_lines.append("Dual-base layout: lane pressure is split across both cores.")
	if branching_active:
		body_lines.append("Tower branching unlocks at level 5.")
	if is_randomizer_mode:
		body_lines.append("Randomizer: costs, cooldowns, and scaling are scrambled.")
	var terrain_text := _get_map_hazard_text()
	if terrain_text != "":
		body_lines.append("Terrain: %s" % terrain_text)
	return {
		"title": title,
		"body": "\n".join(body_lines),
	}

func _preview_enemy_names(preview_wave: int) -> String:
	var options: Array[String] = []
	if preview_wave < 4:
		options = ["Goblin", "Skeleton", "Orc"]
	elif preview_wave < 8:
		options = ["Orc", "Demon", "Fast Skeleton"]
	elif preview_wave < 14:
		options = ["Demon", "Dragon", "Armored Golem"]
	else:
		options = ["Commander", "Berserker", "Shadow"]
	return ", ".join(options)

func _get_map_hazard_text() -> String:
	match map_type:
		GameData.MapType.SNOW:
			return "Frost fields slow enemies."
		GameData.MapType.DESERT:
			return "Dune gusts speed enemies up."
		_:
			return ""

func _mini_boss_preview_text() -> String:
	if not mini_boss_wave_queue.is_empty():
		var live_names: Array[String] = []
		for archetype in mini_boss_wave_queue:
			var live_readable := _mini_boss_archetype_name(archetype)
			if live_readable not in live_names:
				live_names.append(live_readable)
		return ", ".join(live_names)
	if not mini_boss_archetypes.is_empty():
		var names: Array[String] = []
		for archetype in mini_boss_archetypes:
			var readable := _mini_boss_archetype_name(archetype)
			if readable not in names:
				names.append(readable)
		return ", ".join(names)
	return "Juggernaut, Raider, Warlock"

func _mini_boss_archetype_name(archetype: String) -> String:
	match archetype:
		"juggernaut":
			return "Juggernaut"
		"raider":
			return "Raider"
		"warlock":
			return "Warlock"
		_:
			return "Elite"

func _emit_warning(title: String, body: String, color: Color, priority: int = 1, duration: float = 3.0) -> void:
	warning_requested.emit(title, body, color, priority, duration)

func _emit_wave_warning() -> void:
	if day_night_changed_this_wave:
		if is_night_cycle:
			_emit_warning(
				"Nightfall",
				"Moon phase active: enemies gain 20% HP and towers lose 10% range.",
				Color(0.56, 0.68, 0.96),
				2,
				3.8
			)
		else:
			_emit_warning(
				"Daybreak",
				"Sunlight restored. Enemy HP and tower range are back to normal.",
				Color(0.96, 0.86, 0.46),
				1,
				3.0
			)
		return
	if current_boss_type >= 0:
		var boss_name: String = str(GameData.get_boss(current_boss_type).get("name", "Boss"))
		_emit_warning(
			"Boss Wave",
			"%s is entering the field. Save your powers and cover the lane merge." % boss_name,
			Color(0.95, 0.36, 0.24),
			3,
			4.2
		)
		return
	if current_wave_modifier != GameData.WaveModifier.NONE:
		var mod_data: Dictionary = GameData.MODIFIER_NAMES.get(current_wave_modifier, {})
		_emit_warning(
			"%s Wave" % mod_data.get("name", "Danger"),
			"Wave %d has an active modifier. Adjust your tower mix before the pressure spikes." % wave,
			mod_data.get("color", Color(0.9, 0.6, 0.25)),
			2,
			3.3
		)
		return
	if elite_spawn_pending:
		_emit_warning(
			"Elite Enemy",
			"A crowned elite unit is in this wave: +HP, +damage, +gold reward.",
			Color(1.0, 0.80, 0.30),
			2,
			3.1
		)
		return
	var terrain_text := _get_map_hazard_text()
	if terrain_text != "" and wave == 1:
		_emit_warning("Terrain Alert", terrain_text, Color(0.64, 0.82, 1.0), 1, 2.8)
		return
	if double_base_active and wave == 1:
		_emit_warning(
			"Dual Base Defense",
			"This stage has two base cores. Anchor one lane per core before stacking damage.",
			Color(0.74, 0.88, 1.0),
			2,
			3.4
		)
		return
	if fog_of_war_active and wave == 1:
		_emit_warning(
			"Fog of War",
			"Only revealed enemies can be targeted. Build coverage before leaks reach the base.",
			Color(0.58, 0.74, 0.96),
			2,
			3.3
		)
		return
	if branching_active and wave == 1:
		_emit_warning(
			"Tower Branching",
			"On this stage towers branch at level 5 into Assault or Control specializations.",
			Color(0.92, 0.82, 0.40),
			1,
			2.8
		)
		return
	if mini_bosses_pending > 0 and current_boss_type < 0:
		_emit_warning(
			"Mini Boss Wave",
			"Elite units detected: %s. Focus burst damage and control." % _mini_boss_preview_text(),
			Color(0.98, 0.66, 0.30),
			2,
			3.6
		)

# ─── Wave System ──────────────────────────────────────────────────────────────

func _start_next_wave() -> void:
	wave += 1
	wave_in_progress = true
	show_wave_banner = true
	wave_banner_timer = 1.5
	wave_changed.emit(wave)
	base_hp_before_wave = base_hp
	_update_day_night_cycle()
	if double_base_active:
		_retarget_paths_for_active_bases()
		_sync_map_visuals()
	elif day_night_changed_this_wave:
		_sync_map_visuals()

	# Endless scaling
	if is_endless and wave > 10:
		var tier: float = minf((wave - 10) / 10.0, 5.0)
		enemy_hp_mult = 1.0 + tier * 0.15
		enemy_dmg_mult = 1.0 + tier * 0.10
		enemy_speed_mult = 1.0 + tier * 0.05
		spawn_rate_mult = 1.0 + tier * 0.08

	# Wave modifier
	if is_daily_challenge and not daily_challenge_modifiers.is_empty():
		current_wave_modifier = daily_challenge_modifiers[wave % daily_challenge_modifiers.size()]
	elif wave >= 3 and randf() < 0.4:
		var mods: Array = []
		for mod in GameData.get_canonical_wave_modifiers():
			if mod != GameData.WaveModifier.NONE:
				mods.append(mod)
		current_wave_modifier = mods[randi() % mods.size()] if not mods.is_empty() else GameData.WaveModifier.NONE
	else:
		current_wave_modifier = GameData.WaveModifier.NONE

	# Track map for cartographer achievement
	var map_name: String = str(GameData.get_map(map_type).get("name", "Classic"))
	SaveManager.add_map_played(map_name)
	AchievementManager.on_maps_played(SaveManager.get_maps_played().size())

	# Boss wave check
	if is_boss_gauntlet or is_boss_rush or (wave % boss_interval == 0):
		if boss_pool.is_empty():
			boss_pool = GameData.BossType.values().duplicate()
			boss_pool.shuffle()
		current_boss_type = boss_pool.pop_front()
		mini_bosses_pending = 0
		mini_boss_wave_queue.clear()
		elite_spawn_pending = false
		enemies_remaining = 1  # Boss + minions will be spawned together
		_trigger_shake(0.4, 12.0)
	else:
		current_boss_type = -1
		non_boss_wave_counter += 1
		elite_spawn_pending = non_boss_wave_counter >= 5
		if elite_spawn_pending:
			non_boss_wave_counter = 0
		var count: int = int((3 + wave * 2) * spawn_rate_mult)
		count = mini(count, 100)
		if current_wave_modifier == GameData.WaveModifier.SWARM:
			count *= 2
		if elite_spawn_pending:
			count += 1
		mini_bosses_pending = 0
		mini_boss_wave_queue.clear()
		if mini_boss_interval > 0 and wave % mini_boss_interval == 0:
			mini_bosses_pending = mini(4, 1 + int(wave / 14))
			_prepare_mini_boss_wave(mini_bosses_pending)
			count += mini_bosses_pending
		enemies_remaining = count

	wave_banner_shown.emit(wave, current_wave_modifier)
	_emit_wave_warning()
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_wave_start(current_boss_type >= 0)

	if wave >= 5 and _tower_count() == 0:
		AchievementManager.on_wave_5_no_towers()

func _on_wave_complete() -> void:
	wave_in_progress = false
	wave_timer = wave_delay if not (is_boss_rush or is_boss_gauntlet) else 3.0

	# Campaign win check
	if not campaign_level.is_empty():
		var target: int = campaign_level.get("target_wave", 0)
		if target > 0 and wave >= target:
			_trigger_campaign_win()
			return

	AchievementManager.on_wave_complete(wave, base_hp, max_base_hp, base_hp_before_wave,
		is_endless, map_type, is_randomizer_mode, game_speed)

	# Gold interest
	var interest: int = int(gold * interest_rate)
	if interest > 0:
		_add_gold(interest)
		_spawn_text(base_position.x + 60, base_position.y - 100,
			"+%dg interest!" % interest, Color(0.5, 0.85, 0.5), 1.5, 26)

	# Wave bonus gold
	var bonus_sg: int = SaveManager.get_skill_level("wave_bonus")
	var bonus: int = int((wave * 5 + bonus_sg * 15) * gold_mult * skill_gold_bonus)
	_add_gold(bonus)
	_spawn_text(base_position.x, base_position.y - 80,
		"+%dg wave bonus!" % bonus, Color(1.0, 0.85, 0.0), 1.5, 32)

# ─── Enemy Spawning ───────────────────────────────────────────────────────────

func _prepare_mini_boss_wave(count: int) -> void:
	mini_boss_wave_queue.clear()
	var pool: Array[String] = mini_boss_archetypes.duplicate()
	if pool.is_empty():
		pool = ["juggernaut", "raider", "warlock"]
	for i in range(count):
		var archetype := pool[(wave + i + randi()) % pool.size()]
		if wave < 8 and archetype == "warlock":
			archetype = "raider"
		mini_boss_wave_queue.append(archetype)

func _spawn_enemy() -> void:
	if paths.is_empty():
		return

	var path_idx: int = randi() % paths.size()
	var spawn_pt: Vector2 = paths[path_idx][0]
	var wave_scale: float = 1.0 + (wave - 1) * 0.15

	var e_node = enemy_scene.instantiate()
	enemy_container.add_child(e_node)

	if current_boss_type >= 0:
		_configure_boss(e_node, path_idx, wave_scale)
		current_boss_type = -1
		return
	if mini_bosses_pending > 0:
		var archetype := "juggernaut"
		if not mini_boss_wave_queue.is_empty():
			archetype = str(mini_boss_wave_queue.pop_front())
		_configure_mini_boss(e_node, path_idx, wave_scale, archetype)
		mini_bosses_pending -= 1
		return

	# Regular enemy
	var etype: int = _pick_enemy_type()
	var edata: Dictionary = GameData.get_enemy(etype)

	var hp_mod: float = 1.0
	var spd_mod: float = 1.0
	var gold_mod: float = 1.0
	var regen: float = 0.0

	match current_wave_modifier:
		GameData.WaveModifier.FAST:     spd_mod = 2.0
		GameData.WaveModifier.ARMORED:  hp_mod  = 1.5
		GameData.WaveModifier.REGEN:    regen   = 3.0 + wave * 0.5
		GameData.WaveModifier.SWARM:    hp_mod  = 0.5
		GameData.WaveModifier.RICH:     gold_mod = 2.0
		GameData.WaveModifier.BOSS_RALLY: spd_mod = 1.4

	var night_hp_mult := 1.2 if is_night_cycle else 1.0
	var hp: float = edata["hp"] * wave_scale * enemy_hp_mult * hp_mod * night_hp_mult
	var r_offset := Vector2(randf_range(-20, 20), randf_range(-20, 20))

	e_node.setup(
		etype,
		spawn_pt + r_offset,
		path_idx,
		paths[path_idx],
		edata["speed"] * enemy_speed_mult * spd_mod + randf_range(0, 20),
		hp,
		int(edata["gold"] * wave_scale * gold_mult * gold_mod * skill_gold_bonus),
		edata["dmg"] * wave_scale * enemy_dmg_mult,
		edata["emoji"],
		regen
	)

	if elite_spawn_pending:
		_apply_elite_enemy(e_node)
		elite_spawn_pending = false

	e_node.died.connect(_on_enemy_died.bind(e_node))
	e_node.reached_base.connect(_on_enemy_reached_base.bind(e_node))

func _apply_elite_enemy(enemy_node: Node) -> void:
	enemy_node.max_hp *= 3.0
	enemy_node.hp = enemy_node.max_hp
	enemy_node.damage *= 1.5
	enemy_node.gold_reward = int(enemy_node.gold_reward * 2.0)
	enemy_node.enemy_size *= 1.12
	enemy_node.set("is_elite", true)
	_spawn_text(enemy_node.position.x, enemy_node.position.y - 42.0, "ELITE", Color(1.0, 0.82, 0.28), 1.2, 20)

func _mini_boss_archetype_data(archetype: String) -> Dictionary:
	match archetype:
		"juggernaut":
			return {
				"types": [GameData.EnemyType.GOLEM_SHARD, GameData.EnemyType.MINI_ORC, GameData.EnemyType.ARMORED_GOLEM],
				"hp_mult": 3.0 + wave * 0.18,
				"speed_mult": 0.76,
				"damage_mult": 1.9 + wave * 0.04,
				"gold_bonus": 10.0,
				"regen": 0.7 + wave * 0.08,
				"shield": 2.6,
				"charge": false,
			}
		"raider":
			return {
				"types": [GameData.EnemyType.MINI_DEMON, GameData.EnemyType.MINI_DRAGON, GameData.EnemyType.BERSERKER],
				"hp_mult": 2.1 + wave * 0.13,
				"speed_mult": 1.32,
				"damage_mult": 1.5 + wave * 0.03,
				"gold_bonus": 8.0,
				"regen": 0.0,
				"shield": 0.8,
				"charge": true,
			}
		"warlock":
			return {
				"types": [GameData.EnemyType.COMMANDER, GameData.EnemyType.SHADOW, GameData.EnemyType.MINI_SKELETON],
				"hp_mult": 2.6 + wave * 0.15,
				"speed_mult": 0.94,
				"damage_mult": 1.7 + wave * 0.04,
				"gold_bonus": 9.0,
				"regen": 2.0 + wave * 0.2,
				"shield": 1.6,
				"charge": false,
			}
		_:
			return {
				"types": [GameData.EnemyType.MINI_ORC, GameData.EnemyType.MINI_DEMON],
				"hp_mult": 2.5 + wave * 0.14,
				"speed_mult": 1.0,
				"damage_mult": 1.6 + wave * 0.03,
				"gold_bonus": 8.0,
				"regen": 0.0,
				"shield": 1.0,
				"charge": false,
			}

func _configure_mini_boss(e_node: Node, path_idx: int, wave_scale: float, archetype: String) -> void:
	var archetype_data: Dictionary = _mini_boss_archetype_data(archetype)
	var mini_types: Array = archetype_data.get("types", [GameData.EnemyType.MINI_ORC])
	var etype: int = int(mini_types[randi() % mini_types.size()])
	var edata: Dictionary = GameData.get_enemy(etype)
	var spawn_pt: Vector2 = paths[path_idx][0]
	var night_hp_mult := 1.2 if is_night_cycle else 1.0
	var hp: float = edata["hp"] * wave_scale * enemy_hp_mult * float(archetype_data.get("hp_mult", 2.8)) * night_hp_mult
	var speed_mod: float = float(archetype_data.get("speed_mult", 1.0)) + randf_range(-0.06, 0.06)
	var gold_reward: int = int((edata["gold"] + float(archetype_data.get("gold_bonus", 8.0)) + wave * 1.3) * gold_mult * skill_gold_bonus)
	var damage_out: float = edata["dmg"] * wave_scale * enemy_dmg_mult * float(archetype_data.get("damage_mult", 1.7))
	var regen: float = float(archetype_data.get("regen", 0.0))
	e_node.setup(
		etype,
		spawn_pt + Vector2(randf_range(-26, 26), randf_range(-26, 26)),
		path_idx,
		paths[path_idx],
		edata["speed"] * enemy_speed_mult * speed_mod,
		hp,
		gold_reward,
		damage_out,
		edata["emoji"],
		regen
	)
	e_node.shield_timer = float(archetype_data.get("shield", 1.0))
	if bool(archetype_data.get("charge", false)):
		e_node.charge_speed_mult = 1.35
		e_node.charge_timer = 2.4
	e_node.died.connect(_on_enemy_died.bind(e_node))
	e_node.reached_base.connect(_on_enemy_reached_base.bind(e_node))

func _configure_boss(e_node: Node, path_idx: int, wave_scale: float) -> void:
	if current_boss_type < 0:
		return
	var bt := current_boss_type
	var bdata: Dictionary = GameData.get_boss(bt)
	var spawn_pt: Vector2 = paths[path_idx][0]

	var night_hp_mult := 1.2 if is_night_cycle else 1.0
	var hp: float = (bdata["hp"] + wave * 40.0) * wave_scale * enemy_hp_mult * night_hp_mult
	var boss_gold: int = int((bdata["gold"] + wave * 10.0) * wave_scale * gold_mult * skill_gold_bonus)

	e_node.setup_boss(
		bt,
		spawn_pt,
		path_idx,
		paths[path_idx],
		bdata["speed"] * enemy_speed_mult,
		hp,
		boss_gold,
		bdata["dmg"] * wave_scale * enemy_dmg_mult,
		bdata["emoji"],
		bdata["ability"]
	)
	e_node.died.connect(_on_enemy_died.bind(e_node))
	e_node.reached_base.connect(_on_enemy_reached_base.bind(e_node))

	# Spawn minions
	var mc: int = maxi(int(bdata["minion_count"] * spawn_rate_mult), 2)
	for i in range(mc):
		var m := enemy_scene.instantiate()
		enemy_container.add_child(m)
		var mtype: int = bdata["minion"]
		var md: Dictionary = GameData.get_enemy(mtype)
		var moffset := Vector2(randf_range(-40, 40), randf_range(-40, 40))
		m.setup(mtype, spawn_pt + moffset, path_idx, paths[path_idx],
			md["speed"] * enemy_speed_mult, md["hp"] * wave_scale * enemy_hp_mult * night_hp_mult,
			int(md["gold"] * wave_scale * gold_mult * skill_gold_bonus),
			md["dmg"] * wave_scale * enemy_dmg_mult,
			md["emoji"], 0.0)
		m.died.connect(_on_enemy_died.bind(m))
		m.reached_base.connect(_on_enemy_reached_base.bind(m))

func _pick_enemy_type() -> int:
	if wave >= 18 and randf() < 0.06: return GameData.EnemyType.SHAPESHIFTER
	if wave >= 15 and randf() < 0.07: return GameData.EnemyType.COMMANDER
	if wave >= 12 and randf() < 0.08: return GameData.EnemyType.BERSERKER
	if wave >= 10 and randf() < 0.08: return GameData.EnemyType.WISP
	if wave >= 9  and randf() < 0.08: return GameData.EnemyType.SHADOW
	if wave >= 8  and randf() < 0.12: return GameData.EnemyType.ARMORED_GOLEM
	if wave >= 7  and randf() < 0.15: return GameData.EnemyType.DRAGON
	if wave >= 5  and randf() < 0.18: return GameData.EnemyType.DEMON
	if wave >= 4  and randf() < 0.18: return GameData.EnemyType.FAST_SKELETON
	if wave >= 3  and randf() < 0.25: return GameData.EnemyType.ORC
	if wave >= 2  and randf() < 0.35: return GameData.EnemyType.SKELETON
	if randf() < 0.20:                 return GameData.EnemyType.BAT
	if randf() < 0.15:                 return GameData.EnemyType.SLIME
	if wave >= 2 and randf() < 0.12:  return GameData.EnemyType.SPIDER
	return GameData.EnemyType.GOBLIN

# ─── Enemy Update + Tower Firing ─────────────────────────────────────────────

func _update_enemies(dt: float) -> void:
	var freeze_mult: float = 0.2 if freeze_timer > 0 else 1.0
	var all_enemies: Array = enemy_container.get_children()
	var visible_enemies: Array = []
	var tower_range_mult := 0.9 if is_night_cycle else 1.0

	for enemy_node in all_enemies:
		var visible_enemy: bool = true
		if fog_of_war_active:
			visible_enemy = _is_enemy_revealed_for_fog(enemy_node)
		enemy_node.visible = visible_enemy
		if visible_enemy:
			visible_enemies.append(enemy_node)

	if is_instance_valid(player_node) and player_node.has_method("tick"):
		player_node.tick(dt, visible_enemies, self)

	_apply_tower_synergy_bonuses()
	for tower_node in tower_container.get_children():
		tower_node.tick(dt, visible_enemies, freeze_mult, tower_node.target_mode,
						tower_range_mult, skill_tower_damage_bonus, self)

	for enemy_node in all_enemies:
		enemy_node.tick(dt * freeze_mult)

func _apply_tower_synergy_bonuses() -> void:
	var towers: Array = tower_container.get_children()
	if towers.is_empty():
		return
	for tower_node in towers:
		var stacks := 0
		for other in towers:
			if other == tower_node:
				continue
			if other.tower_type != tower_node.tower_type:
				continue
			if tower_node.position.distance_to(other.position) <= 140.0:
				stacks += 1
				if stacks >= 3:
					break
		if tower_node.has_method("set_synergy_stacks"):
			tower_node.set_synergy_stacks(stacks)

func _is_enemy_revealed_for_fog(enemy_node: Node2D) -> bool:
	if enemy_node == null or enemy_node.is_dead():
		return false
	var pos: Vector2 = enemy_node.position
	for base_pos in _get_active_base_positions():
		if pos.distance_to(base_pos) <= fog_base_reveal_radius:
			return true
	for tower_node in tower_container.get_children():
		var reveal_radius: float = maxf(tower_node.attack_range * fog_tower_reveal_mult, 98.0)
		if pos.distance_to(tower_node.position) <= reveal_radius:
			return true
	if is_instance_valid(player_node):
		if pos.distance_to(player_node.position) <= 110.0:
			return true
	if placement_active and placement_preview_pos.x >= 0:
		var placement_reveal: float = maxf(placement_preview_range * 0.85, 96.0)
		if pos.distance_to(placement_preview_pos) <= placement_reveal:
			return true
	return false

func _apply_terrain_effects(dt: float) -> void:
	if terrain_zones.is_empty():
		return
	terrain_tick_timer += dt
	for enemy_node in enemy_container.get_children():
		if enemy_node.is_dead():
			continue
		for zone in terrain_zones:
			var center: Vector2 = zone.get("pos", Vector2.ZERO)
			var radius: float = zone.get("radius", 0.0)
			if enemy_node.position.distance_to(center) > radius:
				continue
			match zone.get("kind", ""):
				"frost":
					var slow: float = float(zone.get("strength", 0.85))
					if enemy_node.ice_slow > slow:
						enemy_node.ice_slow = slow
						enemy_node.ice_slow_timer = maxf(enemy_node.ice_slow_timer, 0.25)
				"lava":
					enemy_node.take_damage(zone.get("dps", 8.0) * dt, GameData.DamageType.FIRE, "terrain")
					enemy_node.burn_timer = maxf(enemy_node.burn_timer, 0.5)
					enemy_node.burn_dps = maxf(enemy_node.burn_dps, zone.get("dps", 8.0) * 0.3)
				"arcane":
					if terrain_tick_timer >= 1.0:
						enemy_node.take_damage(zone.get("pulse_damage", 12.0), GameData.DamageType.MAGIC, "terrain")
				"dune":
					enemy_node.charge_speed_mult = maxf(enemy_node.charge_speed_mult, zone.get("speed", 1.1))
					enemy_node.charge_timer = maxf(enemy_node.charge_timer, 0.2)
	if terrain_tick_timer >= 1.0:
		terrain_tick_timer = 0.0

# ─── Tower Placement ──────────────────────────────────────────────────────────

func start_placement(tower_type: int) -> void:
	cancel_power_targeting()
	placement_active = true
	placement_tower_type = tower_type
	placement_preview_range = GameData.get_tower(tower_type).get("range", 200.0)
	placement_preview_pos = Vector2(-999, -999)
	placement_preview_valid = false
	placement_mode_changed.emit(true, tower_type)

func cancel_placement() -> void:
	placement_active = false
	placement_preview_pos = Vector2(-999, -999)
	placement_preview_valid = false
	placement_mode_changed.emit(false, placement_tower_type)

func start_power_targeting(power_type: int) -> void:
	cancel_placement()
	power_targeting_active = true
	power_targeting_type = power_type
	power_target_preview_pos = Vector2(-999, -999)
	power_targeting_mode_changed.emit(true, power_type)

func cancel_power_targeting() -> void:
	if not power_targeting_active:
		return
	power_targeting_active = false
	power_target_preview_pos = Vector2(-999, -999)
	var prev_type := power_targeting_type
	power_targeting_type = -1
	power_targeting_mode_changed.emit(false, prev_type)

func try_place_tower(pos: Vector2) -> bool:
	pos = _snap_to_grid(pos)
	var tdata := GameData.get_tower(placement_tower_type)
	var cost: int = get_tower_cost(placement_tower_type)

	if gold < cost:
		_spawn_text(pos.x, pos.y - 40, "Not enough gold!", Color(1, 0.3, 0.3), 1.0, 24)
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play_error()
		return false

	# Campaign: check allowed towers
	if not campaign_level.is_empty():
		var allowed: Array = campaign_level.get("towers", [])
		if placement_tower_type not in allowed:
			_spawn_text(pos.x, pos.y - 40, "Tower locked!", Color(1, 0.3, 0.3), 1.0, 24)
			if has_node("/root/SoundManager"):
				get_node("/root/SoundManager").play_error()
			return false

	# Distance from bases
	if _is_too_close_to_any_base(pos, 60.0):
		_spawn_text(pos.x, pos.y - 40, "Too close to base core!", Color(1, 0.5, 0.3), 1.0, 22)
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play_error()
		return false

	# Distance from other towers
	for t in tower_container.get_children():
		if pos.distance_to(t.position) < 70:
			_spawn_text(pos.x, pos.y - 40, "Too close!", Color(1, 0.5, 0.3), 1.0, 22)
			if has_node("/root/SoundManager"):
				get_node("/root/SoundManager").play_error()
			return false

	# Distance from paths
	for path in paths:
		for i in range(path.size() - 1):
			var a: Vector2 = path[i]
			var b: Vector2 = path[i + 1]
			var seg := b - a
			var seg_len_sq: float = seg.length_squared()
			var t_param: float = 0.0
			if seg_len_sq > 0.01:
				t_param = clamp((pos - a).dot(seg) / seg_len_sq, 0.0, 1.0)
			var closest := a + t_param * seg
			if pos.distance_to(closest) < 50:
				_spawn_text(pos.x, pos.y - 40, "On the path!", Color(1, 0.5, 0.3), 1.0, 22)
				if has_node("/root/SoundManager"):
					get_node("/root/SoundManager").play_error()
				return false

	# Place tower
	gold -= cost
	gold_changed.emit(gold)

	var t_node = tower_scene.instantiate()
	tower_container.add_child(t_node)
	t_node.position = pos
	t_node.setup(
		placement_tower_type,
		tdata,
		skill_tower_damage_bonus,
		skill_ability_cd_mult,
		target_mode,
		branching_active
	)
	t_node.ability_fired.connect(_on_tower_ability.bind(t_node))
	t_node.pressed.connect(_on_tower_pressed.bind(t_node))

	# Achievement tracking
	var types: Array = []
	for t in tower_container.get_children():
		if t.tower_type not in types:
			types.append(t.tower_type)
	towers_placed_types = types
	AchievementManager.on_tower_placed(_tower_count(), types)
	SaveManager.add_stat("lifetime_towers", 1)
	var tower_name := str(GameData.TowerType.keys()[placement_tower_type])
	SaveManager.add_stat("tower_count_%s" % tower_name, 1)
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_place()

	cancel_placement()
	return true

func _snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, 34.0, screen_w - 34.0),
		clampf(pos.y, 108.0, screen_h - 126.0)
	)

func _update_placement_preview(pos: Vector2) -> void:
	if not placement_active:
		return
	placement_preview_pos = _snap_to_grid(pos)
	placement_preview_range = GameData.get_tower(placement_tower_type).get("range", 200.0)
	placement_preview_valid = _check_placement_valid(placement_preview_pos)

func sell_tower(tower_node: Node) -> void:
	var base_cost := get_tower_cost(tower_node.tower_type)
	var sell_val := GameData.tower_sell_value(base_cost, tower_node.level, skill_sell_bonus)
	_add_gold(sell_val)
	_spawn_text(tower_node.position.x, tower_node.position.y - 40,
		"+%dg sold!" % sell_val, Color(1.0, 0.85, 0.0), 1.2, 26)
	tower_node.queue_free()

func upgrade_tower(tower_node: Node) -> bool:
	if tower_node.level >= 5:
		return false
	if not campaign_level.is_empty() and not campaign_level.get("upgrades", true):
		return false
	var base_cost := get_tower_cost(tower_node.tower_type)
	var cost := GameData.tower_upgrade_cost(base_cost, tower_node.level)
	if gold < cost:
		return false
	gold -= cost
	gold_changed.emit(gold)
	tower_node.upgrade(skill_tower_damage_bonus, skill_ability_cd_mult, false)
	if tower_node.level >= 5:
		AchievementManager.on_tower_maxed()
	# Check if all towers are upgraded (level >= 2)
	var upgraded := tower_container.get_children().filter(func(t): return t.level >= 2)
	AchievementManager.on_all_towers_upgraded(_tower_count(), upgraded.size())
	return true

# ─── Power Usage ──────────────────────────────────────────────────────────────

func upgrade_player_damage() -> bool:
	if not campaign_level.is_empty() and not campaign_level.get("upgrades", true):
		return false
	var cost := player_damage_level * 25
	if gold < cost:
		return false
	gold -= cost
	player_damage_level += 1
	player_upgrades_bought["damage"] = true
	_check_upgrade_all_achievement()
	if is_instance_valid(player_node):
		player_node.attack_damage += 5.0
	gold_changed.emit(gold)
	_spawn_text(base_position.x - 84.0, base_position.y - 104.0, "ATK UP", Color(0.98, 0.80, 0.44), 0.9, 20)
	return true

func upgrade_player_speed() -> bool:
	if not campaign_level.is_empty() and not campaign_level.get("upgrades", true):
		return false
	var cost := player_speed_level * 20
	if gold < cost:
		return false
	gold -= cost
	player_speed_level += 1
	player_upgrades_bought["speed"] = true
	_check_upgrade_all_achievement()
	if is_instance_valid(player_node):
		player_node.move_speed += 30.0
	gold_changed.emit(gold)
	_spawn_text(base_position.x - 16.0, base_position.y - 104.0, "SPD UP", Color(0.70, 0.92, 1.0), 0.9, 20)
	return true

func upgrade_player_hp() -> bool:
	if not campaign_level.is_empty() and not campaign_level.get("upgrades", true):
		return false
	var cost := player_hp_level * 30
	if gold < cost:
		return false
	gold -= cost
	player_hp_level += 1
	player_upgrades_bought["hp"] = true
	_check_upgrade_all_achievement()
	if is_instance_valid(player_node):
		player_node.max_hp += 25.0
		player_node.hp = player_node.max_hp
	gold_changed.emit(gold)
	_spawn_text(base_position.x + 48.0, base_position.y - 104.0, "HP UP", Color(0.72, 1.0, 0.80), 0.9, 20)
	return true

func upgrade_base_hp() -> bool:
	if not campaign_level.is_empty() and not campaign_level.get("upgrades", true):
		return false
	var cost := base_hp_level * 40
	if gold < cost:
		return false
	gold -= cost
	base_hp_level += 1
	player_upgrades_bought["base"] = true
	_check_upgrade_all_achievement()
	max_base_hp += 30.0
	base_hp = minf(max_base_hp, base_hp + 30.0)
	gold_changed.emit(gold)
	base_hp_changed.emit(base_hp, max_base_hp)
	_spawn_text(base_position.x, base_position.y - 132.0, "BASE UP", Color(0.86, 0.94, 1.0), 1.0, 22)
	return true

func repair_base() -> bool:
	var cost := 20
	if gold < cost:
		return false
	if base_hp >= max_base_hp:
		return false
	gold -= cost
	base_hp = minf(max_base_hp, base_hp + 30.0)
	repairs_this_run += 1
	AchievementManager.on_base_healed(repairs_this_run)
	gold_changed.emit(gold)
	base_hp_changed.emit(base_hp, max_base_hp)
	_spawn_text(base_position.x, base_position.y - 64.0, "REPAIR +30", Color(0.52, 0.94, 0.58), 1.0, 24)
	return true

func use_power(power_type: int, target_pos: Vector2) -> bool:
	var cd_remaining: float = power_cooldowns.get(power_type, 0.0)
	if cd_remaining > 0:
		return false
	# Campaign: check allowed powers
	if not campaign_level.is_empty():
		var allowed_p: Array = campaign_level.get("powers", [])
		if power_type not in allowed_p:
			return false
	var pdata := GameData.get_power(power_type)
	# Check gold cost
	var cost: int = pdata.get("cost", 0)
	if gold < cost:
		_spawn_text(screen_w * 0.5, screen_h * 0.4, "Not enough gold!", Color(1, 0.3, 0.3), 1.0, 24)
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play_error()
		return false
	gold -= cost
	gold_changed.emit(gold)
	power_cooldowns[power_type] = get_power_cooldown(power_type) * skill_ability_cd_mult
	AchievementManager.on_power_used(power_type)
	powers_used_this_run[power_type] = true
	SaveManager.add_stat("lifetime_powers_used", 1)
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_power(power_type)

	match power_type:
		GameData.PowerType.FIREBALL: _power_fireball(target_pos)
		GameData.PowerType.FREEZE:   _power_freeze()
		GameData.PowerType.HEAL:     _power_heal()
		GameData.PowerType.LIGHTNING: _power_lightning(target_pos)
	return true

func _power_fireball(_pos: Vector2) -> void:
	var base_dmg := 50.0 * randomizer_power_damage_mult
	for e in enemy_container.get_children():
		if not e.is_dead():
			e.take_damage(base_dmg, GameData.DamageType.FIRE, "power")
	_spawn_text(screen_w * 0.5, screen_h * 0.4, "🔥 FIREBALL!", Color(1.0, 0.4, 0.0), 1.5, 32)
	_trigger_shake(0.3, 8.0)

func _power_freeze() -> void:
	freeze_timer = 4.0
	_spawn_text(screen_w * 0.5, screen_h * 0.4, "❄️ FREEZE!", Color(0.4, 0.85, 1.0), 1.5, 36)

func _power_heal() -> void:
	base_hp = minf(base_hp + 50.0, max_base_hp)
	base_hp_changed.emit(base_hp, max_base_hp)
	repairs_this_run += 1
	AchievementManager.on_base_healed(repairs_this_run)
	_spawn_text(base_position.x, base_position.y - 60,
		"💚 HEALED +50", Color(0.2, 0.9, 0.4), 1.5, 32)

func _power_lightning(pos: Vector2) -> void:
	var targets: Array = []
	for e in enemy_container.get_children():
		if not e.is_dead():
			targets.append(e)
	targets.sort_custom(func(a, b): return a.position.distance_to(pos) < b.position.distance_to(pos))
	var chain_count := mini(5, targets.size())
	var dmg := 80.0 * randomizer_power_damage_mult
	for i in range(chain_count):
		targets[i].take_damage(dmg, GameData.DamageType.ELECTRIC, "power")
		dmg *= 0.8
	_spawn_text(pos.x, pos.y - 30, "⚡ LIGHTNING!", Color(1.0, 0.9, 0.0), 1.5, 34)
	_trigger_shake(0.2, 6.0)

# ─── Enemy Death / Base Damage ────────────────────────────────────────────────

func _on_enemy_died(enemy_node: Node) -> void:
	if enemy_node.is_queued_for_deletion():
		return
	var gold_reward: int = enemy_node.gold_reward
	var etype: int = enemy_node.enemy_type

	_add_gold(gold_reward)
	total_kills += 1
	var pts: int = int(gold_reward * 2 * combo_multiplier)
	score += pts
	score_changed.emit(score)

	# Combo
	combo_count += 1
	combo_timer = 2.0
	combo_multiplier = minf(1.0 + combo_count * 0.1, 8.0)
	if combo_count > best_combo:
		best_combo = combo_count

	AchievementManager.on_enemy_killed(etype, -1, combo_count)
	if etype == GameData.EnemyType.BOSS:
		bosses_killed_this_run += 1
		_trigger_shake(0.5, 15.0)
		var boss_diamonds: int = mini(2 + wave / 5, 10)
		diamonds_this_run += boss_diamonds
		AchievementManager.on_diamonds_earned(boss_diamonds)

	_spawn_text(enemy_node.position.x, enemy_node.position.y - 30,
		"+%d" % gold_reward, Color(1.0, 0.85, 0.0), 0.9, 22)
	enemy_node.queue_free()

func _on_enemy_reached_base(enemy_node: Node) -> void:
	if game_over:
		return
	var dmg: float = enemy_node.damage
	base_hp -= dmg
	base_hp = maxf(base_hp, 0.0)
	base_hp_changed.emit(base_hp, max_base_hp)
	_trigger_shake(0.25, 8.0)
	_trigger_base_flash(Color(1.0, 0.2, 0.2, 0.15))
	_spawn_text(enemy_node.position.x, enemy_node.position.y - 40,
		"-%.0f HP" % dmg, Color(1.0, 0.2, 0.2), 1.2, 28)
	enemy_node.queue_free()

	if base_hp <= 0:
		_trigger_game_over()

func _trigger_game_over() -> void:
	game_over = true
	clear_saved_run()
	if difficulty == 1 and wave >= 10:
		SaveManager.set_val("normal_beaten", true)
	var is_new_high := SaveManager.submit_score(score)
	SaveManager.submit_wave(wave)
	if is_endless:
		SaveManager.submit_endless(wave)
	if is_boss_rush:
		SaveManager.submit_boss_rush(wave)
	if diamonds_this_run > 0:
		SaveManager.add_diamonds(diamonds_this_run)
		SaveManager.add_stat("lifetime_diamonds", diamonds_this_run)
	SaveManager.add_stat("lifetime_kills", total_kills)
	SaveManager.add_stat("lifetime_bosses", bosses_killed_this_run)
	SaveManager.add_stat("lifetime_games", 1)
	SaveManager.add_stat("lifetime_waves", wave)
	SaveManager.add_stat("lifetime_score", score)
	SaveManager.add_stat("lifetime_gold", total_gold_earned)
	SaveManager.set_stat_max("lifetime_best_combo", best_combo)
	SaveManager.flush()
	game_over_triggered.emit(score, wave, is_new_high)

# ─── Tower Ability Callbacks ──────────────────────────────────────────────────

func _on_tower_ability(tower_node: Node) -> void:
	var ttype: int = tower_node.tower_type
	if ttype not in ability_types_used_run:
		ability_types_used_run.append(ttype)
		AchievementManager.on_ability_used(ttype)

	match ttype:
		GameData.TowerType.ARROW:      _ability_volley(tower_node)
		GameData.TowerType.MAGIC:      _ability_arcane_blast(tower_node)
		GameData.TowerType.CANNON:     _ability_napalm(tower_node)
		GameData.TowerType.POISON:     _ability_plague(tower_node)
		GameData.TowerType.TESLA:      _ability_overcharge(tower_node)
		GameData.TowerType.ICE:        _ability_deep_freeze(tower_node)

func _ability_volley(t: Node) -> void:
	var targets := _enemies_in_range(t.position, t.attack_range * 1.5, 8)
	for e in targets:
		e.take_damage(t.damage * 1.5, GameData.DamageType.PHYSICAL, "ability")
	_spawn_text(t.position.x, t.position.y - 40, "🏹 VOLLEY!", Color(0.9, 0.7, 0.2), 1.0, 28)

func _ability_arcane_blast(t: Node) -> void:
	var targets := _enemies_in_range(t.position, t.attack_range * 1.3, 999)
	for e in targets:
		e.take_damage(t.damage * 2.5, GameData.DamageType.MAGIC, "ability")
	_spawn_text(t.position.x, t.position.y - 40, "🔮 BLAST!", Color(0.6, 0.2, 1.0), 1.0, 28)
	_trigger_shake(0.25, 8.0)
	_trigger_ability_flash(Color(0.6, 0.2, 1.0, 0.15))

func _ability_napalm(t: Node) -> void:
	var targets := _enemies_in_range(t.position, t.attack_range, 999)
	for e in targets:
		e.take_damage(t.damage * 3.0, GameData.DamageType.EXPLOSIVE, "ability")
		e.burn_timer = 3.0; e.burn_dps = 8.0
	_spawn_text(t.position.x, t.position.y - 40, "💣 NAPALM!", Color(1.0, 0.4, 0.0), 1.0, 30)
	_trigger_shake(0.3, 10.0)

func _ability_plague(t: Node) -> void:
	var targets := _enemies_in_range(t.position, t.attack_range * 1.5, 999)
	for e in targets:
		e.poison_timer = 6.0; e.poison_dps = t.damage * 0.8
	_spawn_text(t.position.x, t.position.y - 40, "☠️ PLAGUE!", Color(0.4, 0.9, 0.3), 1.0, 28)

func _ability_overcharge(t: Node) -> void:
	var targets := _enemies_in_range(t.position, t.attack_range * 1.2, 999)
	for e in targets:
		e.take_damage(t.damage * 4.0, GameData.DamageType.ELECTRIC, "ability")
		e.stun_timer = 1.5
	_spawn_text(t.position.x, t.position.y - 40, "⚡ OVERCHARGE!", Color(1.0, 0.9, 0.0), 1.0, 28)

func _ability_deep_freeze(t: Node) -> void:
	var targets := _enemies_in_range(t.position, t.attack_range * 1.5, 999)
	for e in targets:
		e.ice_slow = 0.05; e.ice_slow_timer = 4.0
	_spawn_text(t.position.x, t.position.y - 40, "❄️ DEEP FREEZE!", Color(0.4, 0.85, 1.0), 1.2, 28)

func _ability_inferno(t: Node) -> void:
	var targets := _enemies_in_range(t.position, t.attack_range, 999)
	for e in targets:
		e.burn_timer = 5.0; e.burn_dps = t.damage * 1.2
	_spawn_text(t.position.x, t.position.y - 40, "🔥 INFERNO!", Color(1.0, 0.3, 0.0), 1.0, 30)

func _ability_soul_harvest(t: Node) -> void:
	var killed: int = 0
	for e in _enemies_in_range(t.position, t.attack_range * 1.2, 999):
		if e.hp < e.max_hp * 0.15:
			e.take_damage(e.hp + 1, GameData.DamageType.DARK, "ability")
			killed += 1
	if killed > 0:
		_add_gold(killed * 3)
	_spawn_text(t.position.x, t.position.y - 40, "💀 SOUL HARVEST!", Color(0.5, 0.1, 0.9), 1.2, 28)

func _ability_siege_shot(t: Node) -> void:
	# Fire a piercing shot through all enemies in front
	var targets := _enemies_in_range(t.position, t.attack_range, 999)
	for e in targets:
		e.take_damage(t.damage * 6.0, GameData.DamageType.PHYSICAL, "ability")
	_spawn_text(t.position.x, t.position.y - 40, "🎯 SIEGE SHOT!", Color(0.8, 0.6, 0.2), 1.0, 30)

func _ability_singularity(t: Node) -> void:
	# Pull enemies toward tower
	for e in _enemies_in_range(t.position, t.attack_range * 1.3, 999):
		var pull_dir: Vector2 = (t.position - e.position).normalized()
		e.position += pull_dir * 60
		e.take_damage(t.damage * 3.0, GameData.DamageType.MAGIC, "ability")
	_spawn_text(t.position.x, t.position.y - 40, "🌀 SINGULARITY!", Color(0.5, 0.2, 0.9), 1.2, 28)

func _ability_mass_heal(t: Node) -> void:
	var heal_amt := maxf(max_base_hp * 0.12, 8.0)
	base_hp = minf(base_hp + heal_amt, max_base_hp)
	base_hp_changed.emit(base_hp, max_base_hp)
	repairs_this_run += 1
	AchievementManager.on_base_healed(repairs_this_run)
	_spawn_text(base_position.x, base_position.y - 60,
		"💚 MASS HEAL +%d" % int(heal_amt), Color(0.2, 0.9, 0.4), 1.2, 26)

# ─── Tower selection callback ─────────────────────────────────────────────────

func _on_tower_pressed(tower_node: Node) -> void:
	if not placement_active:
		tower_selected.emit(tower_node)

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _add_gold(amount: int) -> void:
	gold += amount
	total_gold_earned += amount
	gold_changed.emit(gold)

func _spawn_text(x: float, y: float, text: String, color: Color, duration: float, size: float) -> void:
	floating_text_requested.emit(x, y, text, color, duration, size)

func _spawn_floating_text_node(x: float, y: float, text: String, color: Color, duration: float, size: float) -> void:
	if not is_instance_valid(effects_container):
		return
	var ft = floating_text_scene.instantiate()
	effects_container.add_child(ft)
	ft.position = Vector2(x, y)
	ft.setup(text, color, duration, size)

func _trigger_shake(duration: float, intensity: float) -> void:
	if not SaveManager.get_bool("screen_shake", true):
		return
	shake_timer = duration
	shake_intensity = intensity

func _check_upgrade_all_achievement() -> void:
	if bool(player_upgrades_bought.get("damage", false)) \
	and bool(player_upgrades_bought.get("speed", false)) \
	and bool(player_upgrades_bought.get("hp", false)) \
	and bool(player_upgrades_bought.get("base", false)):
		AchievementManager.check("upgrade_all")

func _enemy_count() -> int:
	return enemy_container.get_child_count()

func _tower_count() -> int:
	return tower_container.get_child_count()

func _enemies_in_range(pos: Vector2, radius: float, max_count: int) -> Array:
	var result: Array = []
	for e in enemy_container.get_children():
		if e.position.distance_to(pos) <= radius and not e.is_dead():
			result.append(e)
			if result.size() >= max_count:
				break
	return result

func move_player_to(pos: Vector2) -> void:
	if not is_instance_valid(player_node) or not player_node.has_method("set_move_target"):
		return
	player_node.set_move_target(_snap_to_grid(pos))

func use_dash() -> bool:
	if not is_instance_valid(player_node):
		return false
	var enemies: Array = []
	for enemy_node in enemy_container.get_children():
		if not enemy_node.is_dead():
			enemies.append(enemy_node)
	var target_pos: Vector2 = _snap_to_grid(Vector2(screen_w * 0.5, screen_h * 0.5))
	var move_target_variant: Variant = player_node.get("move_target")
	if move_target_variant is Vector2:
		target_pos = move_target_variant
	if player_node.has_method("dash_toward"):
		return player_node.dash_toward(target_pos, enemies, self)
	return false

func get_dash_cooldown_remaining() -> float:
	if not is_instance_valid(player_node) or not player_node.has_method("get_dash_cooldown_remaining"):
		return 0.0
	return player_node.get_dash_cooldown_remaining()

func has_saved_run() -> bool:
	return SaveManager.get_bool("save_has_run", false)

func clear_saved_run() -> void:
	SaveManager.set_val("save_has_run", false)
	SaveManager.flush()

func save_game() -> void:
	SaveManager.set_val("save_has_run", true)
	SaveManager.set_val("save_wave", wave)
	SaveManager.set_val("save_gold", gold)
	SaveManager.set_val("save_score", score)
	SaveManager.set_val("save_total_kills", total_kills)
	SaveManager.set_val("save_total_gold_earned", total_gold_earned)
	SaveManager.set_val("save_base_hp", base_hp)
	SaveManager.set_val("save_max_base_hp", max_base_hp)
	SaveManager.set_val("save_difficulty", difficulty)
	SaveManager.set_val("save_map", map_type)
	SaveManager.set_val("save_is_endless", is_endless)
	SaveManager.set_val("save_is_boss_rush", is_boss_rush)
	SaveManager.set_val("save_is_boss_gauntlet", is_boss_gauntlet)
	SaveManager.set_val("save_is_daily_challenge", is_daily_challenge)
	SaveManager.set_val("save_daily_seed", daily_challenge_seed)
	SaveManager.set_val("save_daily_mods", daily_challenge_modifiers.duplicate())
	SaveManager.set_val("save_is_randomizer_mode", is_randomizer_mode)
	SaveManager.set_val("save_randomizer_seed", randomizer_seed)
	SaveManager.set_val("save_randomizer_tower_costs", randomizer_tower_costs.duplicate())
	SaveManager.set_val("save_randomizer_power_cooldowns", randomizer_power_cooldowns.duplicate())
	SaveManager.set_val("save_randomizer_power_damage_mult", randomizer_power_damage_mult)
	SaveManager.set_val("save_randomizer_start_gold", randomizer_start_gold)
	SaveManager.set_val("save_enemy_hp_mult", enemy_hp_mult)
	SaveManager.set_val("save_enemy_dmg_mult", enemy_dmg_mult)
	SaveManager.set_val("save_enemy_speed_mult", enemy_speed_mult)
	SaveManager.set_val("save_gold_mult", gold_mult)
	SaveManager.set_val("save_spawn_rate_mult", spawn_rate_mult)
	SaveManager.set_val("save_boss_interval", boss_interval)
	SaveManager.set_val("save_non_boss_wave_counter", non_boss_wave_counter)
	SaveManager.set_val("save_is_night_cycle", is_night_cycle)
	SaveManager.set_val("save_player_damage_level", player_damage_level)
	SaveManager.set_val("save_player_speed_level", player_speed_level)
	SaveManager.set_val("save_player_hp_level", player_hp_level)
	SaveManager.set_val("save_base_hp_level", base_hp_level)
	SaveManager.set_val("save_repairs", repairs_this_run)
	SaveManager.set_val("save_bosses_killed_this_run", bosses_killed_this_run)
	SaveManager.set_val("save_diamonds_this_run", diamonds_this_run)
	SaveManager.set_val("save_best_combo", best_combo)
	SaveManager.set_val("save_combo_count", combo_count)
	SaveManager.set_val("save_combo_timer", combo_timer)
	SaveManager.set_val("save_combo_multiplier", combo_multiplier)
	SaveManager.set_val("save_towers_placed_types", towers_placed_types.duplicate())
	SaveManager.set_val("save_ability_types_used_run", ability_types_used_run.duplicate())
	SaveManager.set_val("save_powers_used_this_run", powers_used_this_run.duplicate())
	SaveManager.set_val("save_traps_placed_run", traps_placed_run)
	SaveManager.set_val("save_towers", _serialize_towers())
	if is_instance_valid(player_node):
		SaveManager.set_val("save_player_hp", float(player_node.hp))
		SaveManager.set_val("save_player_max_hp", float(player_node.max_hp))
		SaveManager.set_val("save_player_damage", float(player_node.attack_damage))
		SaveManager.set_val("save_player_speed", float(player_node.move_speed))
		SaveManager.set_val("save_player_range", float(player_node.attack_range))
	var saved_power_cooldowns: Dictionary = {}
	for power_type in power_cooldowns.keys():
		saved_power_cooldowns[power_type] = power_cooldowns[power_type]
	SaveManager.set_val("save_power_cooldowns", saved_power_cooldowns)
	SaveManager.flush()

func _serialize_towers() -> Array:
	var serialized: Array = []
	for tower_node in tower_container.get_children():
		if not is_instance_valid(tower_node):
			continue
		serialized.append({
			"x": float(tower_node.position.x),
			"y": float(tower_node.position.y),
			"tower_type": int(tower_node.tower_type),
			"level": int(tower_node.level),
			"target_mode": int(tower_node.target_mode),
			"branch": int(tower_node.branch),
			"branch_name": str(tower_node.branch_name),
			"branching_enabled": bool(tower_node.branching_enabled),
			"fire_timer": float(tower_node.fire_timer),
			"ability_timer": float(tower_node.ability_timer),
			"damage": float(tower_node.damage),
			"attack_range": float(tower_node.attack_range),
			"fire_rate": float(tower_node.fire_rate),
			"damage_type": int(tower_node.damage_type),
			"ability_cooldown": float(tower_node.ability_cooldown),
		})
	return serialized

func _restore_towers_from_save(saved_data: Variant) -> void:
	if not (saved_data is Array):
		return
	for tower_node in tower_container.get_children():
		tower_node.queue_free()
	for raw in saved_data:
		if not (raw is Dictionary):
			continue
		var data: Dictionary = raw
		var ttype := int(data.get("tower_type", GameData.TowerType.ARROW))
		var tdata := GameData.get_tower(ttype)
		var t_node = tower_scene.instantiate()
		tower_container.add_child(t_node)
		t_node.position = _snap_to_grid(Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0))))
		t_node.setup(
			ttype,
			tdata,
			skill_tower_damage_bonus,
			skill_ability_cd_mult,
			int(data.get("target_mode", target_mode)),
			bool(data.get("branching_enabled", branching_active))
		)
		t_node.level = int(data.get("level", t_node.level))
		t_node.target_mode = int(data.get("target_mode", t_node.target_mode))
		t_node.branch = int(data.get("branch", t_node.branch))
		t_node.branch_name = str(data.get("branch_name", t_node.branch_name))
		t_node.fire_timer = float(data.get("fire_timer", t_node.fire_timer))
		t_node.ability_timer = float(data.get("ability_timer", t_node.ability_timer))
		t_node.damage = float(data.get("damage", t_node.damage))
		t_node.attack_range = float(data.get("attack_range", t_node.attack_range))
		t_node.fire_rate = float(data.get("fire_rate", t_node.fire_rate))
		t_node.damage_type = int(data.get("damage_type", t_node.damage_type))
		t_node.ability_cooldown = float(data.get("ability_cooldown", t_node.ability_cooldown))
		if t_node.has_method("_update_level_label"):
			t_node.call("_update_level_label")
		t_node.queue_redraw()
		t_node.ability_fired.connect(_on_tower_ability.bind(t_node))
		t_node.pressed.connect(_on_tower_pressed.bind(t_node))

func load_game() -> bool:
	if not has_saved_run():
		return false
	reset()
	map_type = SaveManager.get_int("save_map", GameData.MapType.CLASSIC)
	difficulty = SaveManager.get_int("save_difficulty", 1)
	is_endless = SaveManager.get_bool("save_is_endless", false)
	is_boss_rush = SaveManager.get_bool("save_is_boss_rush", false)
	is_boss_gauntlet = SaveManager.get_bool("save_is_boss_gauntlet", false)
	is_daily_challenge = SaveManager.get_bool("save_is_daily_challenge", false)
	daily_challenge_seed = SaveManager.get_int("save_daily_seed", 0)
	daily_challenge_modifiers = []
	var daily_mods_var: Variant = SaveManager.get_val("save_daily_mods", [])
	if daily_mods_var is Array:
		for mod in daily_mods_var:
			daily_challenge_modifiers.append(int(mod))
	is_randomizer_mode = SaveManager.get_bool("save_is_randomizer_mode", false)
	randomizer_seed = SaveManager.get_int("save_randomizer_seed", 0)
	randomizer_tower_costs = {}
	var tower_costs_var: Variant = SaveManager.get_val("save_randomizer_tower_costs", {})
	if tower_costs_var is Dictionary:
		for key in tower_costs_var.keys():
			randomizer_tower_costs[int(key)] = int(tower_costs_var[key])
	randomizer_power_cooldowns = {}
	var random_cds_var: Variant = SaveManager.get_val("save_randomizer_power_cooldowns", {})
	if random_cds_var is Dictionary:
		for key in random_cds_var.keys():
			randomizer_power_cooldowns[int(key)] = float(random_cds_var[key])
	randomizer_power_damage_mult = SaveManager.get_float("save_randomizer_power_damage_mult", 1.0)
	randomizer_start_gold = SaveManager.get_int("save_randomizer_start_gold", 50)
	enemy_hp_mult = SaveManager.get_float("save_enemy_hp_mult", enemy_hp_mult)
	enemy_dmg_mult = SaveManager.get_float("save_enemy_dmg_mult", enemy_dmg_mult)
	enemy_speed_mult = SaveManager.get_float("save_enemy_speed_mult", enemy_speed_mult)
	gold_mult = SaveManager.get_float("save_gold_mult", gold_mult)
	spawn_rate_mult = SaveManager.get_float("save_spawn_rate_mult", spawn_rate_mult)
	boss_interval = SaveManager.get_int("save_boss_interval", boss_interval)
	non_boss_wave_counter = SaveManager.get_int("save_non_boss_wave_counter", 0)
	is_night_cycle = SaveManager.get_bool("save_is_night_cycle", false)
	player_damage_level = SaveManager.get_int("save_player_damage_level", 1)
	player_speed_level = SaveManager.get_int("save_player_speed_level", 1)
	player_hp_level = SaveManager.get_int("save_player_hp_level", 1)
	base_hp_level = SaveManager.get_int("save_base_hp_level", 1)
	repairs_this_run = SaveManager.get_int("save_repairs", 0)
	bosses_killed_this_run = SaveManager.get_int("save_bosses_killed_this_run", 0)
	diamonds_this_run = SaveManager.get_int("save_diamonds_this_run", 0)
	best_combo = SaveManager.get_int("save_best_combo", 0)
	combo_count = SaveManager.get_int("save_combo_count", 0)
	combo_timer = SaveManager.get_float("save_combo_timer", 0.0)
	combo_multiplier = SaveManager.get_float("save_combo_multiplier", 1.0)
	towers_placed_types = []
	var saved_tower_types: Variant = SaveManager.get_val("save_towers_placed_types", [])
	if saved_tower_types is Array:
		for tower_type in saved_tower_types:
			towers_placed_types.append(int(tower_type))
	ability_types_used_run = []
	var saved_ability_types: Variant = SaveManager.get_val("save_ability_types_used_run", [])
	if saved_ability_types is Array:
		for tower_type in saved_ability_types:
			ability_types_used_run.append(int(tower_type))
	powers_used_this_run = {}
	var saved_powers_used: Variant = SaveManager.get_val("save_powers_used_this_run", {})
	if saved_powers_used is Dictionary:
		for key in saved_powers_used.keys():
			powers_used_this_run[int(key)] = bool(saved_powers_used[key])
	traps_placed_run = SaveManager.get_int("save_traps_placed_run", 0)
	var saved_towers: Variant = SaveManager.get_val("save_towers", [])

	generate_paths()
	_generate_terrain_zones()
	_sync_map_visuals()
	_spawn_player()

	wave = SaveManager.get_int("save_wave", 0)
	gold = SaveManager.get_int("save_gold", gold)
	score = SaveManager.get_int("save_score", 0)
	total_kills = SaveManager.get_int("save_total_kills", 0)
	total_gold_earned = SaveManager.get_int("save_total_gold_earned", 0)
	base_hp = SaveManager.get_float("save_base_hp", base_hp)
	max_base_hp = SaveManager.get_float("save_max_base_hp", max_base_hp)
	if is_instance_valid(player_node):
		player_node.hp = SaveManager.get_float("save_player_hp", player_node.hp)
		player_node.max_hp = SaveManager.get_float("save_player_max_hp", player_node.max_hp)
		player_node.attack_damage = SaveManager.get_float("save_player_damage", player_node.attack_damage)
		player_node.move_speed = SaveManager.get_float("save_player_speed", player_node.move_speed)
		player_node.attack_range = SaveManager.get_float("save_player_range", player_node.attack_range)
	_restore_towers_from_save(saved_towers)
	if towers_placed_types.is_empty():
		var live_types: Array = []
		for tower_node in tower_container.get_children():
			if tower_node.tower_type not in live_types:
				live_types.append(tower_node.tower_type)
		towers_placed_types = live_types

	_init_powers()
	var saved_power_cooldowns: Variant = SaveManager.get_val("save_power_cooldowns", {})
	if saved_power_cooldowns is Dictionary:
		for power_type in saved_power_cooldowns.keys():
			power_cooldowns[int(power_type)] = float(saved_power_cooldowns[power_type])
	combo_multiplier = maxf(1.0, combo_multiplier)
	if AchievementManager.has_method("restore_run_progress"):
		AchievementManager.restore_run_progress(
			total_kills,
			bosses_killed_this_run,
			diamonds_this_run,
			powers_used_this_run,
			ability_types_used_run
		)

	wave_in_progress = false
	enemies_remaining = 0
	wave_timer = 4.0
	current_boss_type = -1
	show_wave_banner = false
	game_over = false
	is_paused = false
	placement_active = false
	power_targeting_active = false
	placement_preview_pos = Vector2(-999, -999)
	power_target_preview_pos = Vector2(-999, -999)
	_broadcast_state()
	_emit_warning(
		"Run Loaded",
		"Continue resumed from wave %d." % wave,
		Color(0.72, 0.90, 1.0),
		1,
		2.4
	)
	return true

func _on_combo_expire() -> void:
	var bonus: int = combo_count * 2
	_add_gold(bonus)
	_spawn_text(screen_w * 0.5, screen_h * 0.42,
		"%dx COMBO! +%dg" % [combo_count, bonus], Color(1.0, 0.6, 0.0), 2.0, 40)

# ─── Input: tap to place tower or use power ───────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if game_over or is_paused:
		return
	if placement_active:
		if event is InputEventMouseMotion:
			_update_placement_preview(event.position)
		elif event is InputEventScreenDrag:
			_update_placement_preview(event.position)
	elif power_targeting_active:
		if event is InputEventMouseMotion:
			power_target_preview_pos = _snap_to_grid(event.position)
		elif event is InputEventScreenDrag:
			power_target_preview_pos = _snap_to_grid(event.position)
	elif event is InputEventScreenDrag:
		move_player_to(event.position)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		move_player_to(event.position)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if placement_active:
			cancel_placement()
			return
		if power_targeting_active:
			cancel_power_targeting()
			return

	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		var pressed: bool = event.pressed if event is InputEventMouseButton else event.pressed
		if pressed:
			var pos: Vector2 = event.position
			if placement_active:
				_update_placement_preview(pos)
				try_place_tower(pos)
			elif power_targeting_active:
				power_target_preview_pos = _snap_to_grid(pos)
				if use_power(power_targeting_type, power_target_preview_pos):
					cancel_power_targeting()
			else:
				if not _check_tower_tap(pos):
					tower_selected.emit(null)
					move_player_to(pos)

# ─── Speed control ────────────────────────────────────────────────────────────

func set_game_speed(speed: int) -> void:
	game_speed = clamp(speed, 1, 3)

func toggle_pause() -> void:
	is_paused = !is_paused
	if pause_menu:
		pause_menu.visible = is_paused
	if is_paused and not game_over and wave > 0:
		save_game()

func _trigger_ability_flash(color: Color) -> void:
	ability_flash_color = color
	ability_flash_timer = 0.3

func _trigger_base_flash(color: Color) -> void:
	base_flash_color = color
	base_flash_timer = 0.15

func _draw() -> void:
	# Ability flash overlay
	if ability_flash_timer > 0 and ability_flash_color.a > 0:
		draw_rect(Rect2(0, 0, screen_w, screen_h), ability_flash_color)

	# Base damage flash overlay
	if base_flash_timer > 0 and base_flash_color.a > 0:
		draw_rect(Rect2(0, 0, screen_w, screen_h), base_flash_color)

	# Placement preview
	if placement_active and placement_preview_pos.x >= 0:
		var accent := _get_tower_accent_color(placement_tower_type)
		var pulse := sin(placement_preview_anim * 3.0) * 0.08
		if placement_preview_valid:
			draw_circle(placement_preview_pos, placement_preview_range, accent * Color(1, 1, 1, 0.06 + pulse))
			for i in range(48):
				if i % 3 == 0:
					continue
				var a1: float = TAU * i / 48
				var a2: float = TAU * (i + 1) / 48
				draw_line(
					Vector2(cos(a1), sin(a1)) * placement_preview_range + placement_preview_pos,
					Vector2(cos(a2), sin(a2)) * placement_preview_range + placement_preview_pos,
					accent * Color(1, 1, 1, 0.3), 1.5)
			draw_circle(placement_preview_pos, 14.0, accent * Color(1, 1, 1, 0.15))
			draw_circle(placement_preview_pos, 10.0, accent * Color(1, 1, 1, 0.10))
			_draw_tower_ghost(placement_preview_pos, accent, true)
		else:
			draw_circle(placement_preview_pos, placement_preview_range, Color(1, 0.1, 0.1, 0.04))
			for i in range(48):
				if i % 3 == 0:
					continue
				var a1: float = TAU * i / 48
				var a2: float = TAU * (i + 1) / 48
				draw_line(
					Vector2(cos(a1), sin(a1)) * placement_preview_range + placement_preview_pos,
					Vector2(cos(a2), sin(a2)) * placement_preview_range + placement_preview_pos,
					Color(1, 0.2, 0.2, 0.2), 1.5)
			_draw_tower_ghost(placement_preview_pos, Color(1.0, 0.34, 0.24), false)

	# Power targeting preview
	if power_targeting_active and power_target_preview_pos.x >= 0:
		var power_col := _get_power_accent_color(power_targeting_type)
		var pulse := 0.08 + 0.06 * (0.5 + 0.5 * sin(placement_preview_anim * 4.0))
		var inner_r := 18.0
		var outer_r := 42.0
		draw_circle(power_target_preview_pos, outer_r, power_col * Color(1, 1, 1, pulse * 0.35))
		draw_arc(power_target_preview_pos, outer_r, 0.0, TAU, 36, power_col * Color(1, 1, 1, 0.54), 1.8)
		draw_arc(power_target_preview_pos, inner_r, 0.0, TAU, 24, power_col * Color(1, 1, 1, 0.78), 1.6)
		draw_line(power_target_preview_pos + Vector2(-10, 0), power_target_preview_pos + Vector2(10, 0), power_col.lightened(0.35), 1.4)
		draw_line(power_target_preview_pos + Vector2(0, -10), power_target_preview_pos + Vector2(0, 10), power_col.lightened(0.35), 1.4)

	if placement_active or power_targeting_active:
		queue_redraw()

func _get_tower_accent_color(ttype: int) -> Color:
	match ttype:
		GameData.TowerType.ARROW:    return Color(0.3, 0.7, 0.2)
		GameData.TowerType.MAGIC:    return Color(0.8, 0.5, 1.0)
		GameData.TowerType.CANNON:   return Color(0.9, 0.3, 0.1)
		GameData.TowerType.POISON:   return Color(0.3, 0.9, 0.2)
		GameData.TowerType.TESLA:    return Color(1.0, 0.9, 0.2)
		GameData.TowerType.ICE:      return Color(0.7, 0.95, 1.0)
		_:                           return Color(0.9, 0.8, 0.3)

func _get_power_accent_color(power_type: int) -> Color:
	match power_type:
		GameData.PowerType.FIREBALL: return Color(1.0, 0.46, 0.20)
		GameData.PowerType.FREEZE: return Color(0.62, 0.90, 1.0)
		GameData.PowerType.HEAL: return Color(0.38, 0.96, 0.56)
		GameData.PowerType.LIGHTNING: return Color(1.0, 0.90, 0.34)
		_: return Color(0.86, 0.90, 1.0)

func _draw_tower_ghost(pos: Vector2, accent: Color, valid: bool) -> void:
	var body := accent if valid else Color(1.0, 0.34, 0.24)
	var outline := body * Color(1, 1, 1, 0.66 if valid else 0.46)
	draw_circle(pos, 12.0, body * Color(1, 1, 1, 0.12))
	draw_circle(pos, 8.0, outline * Color(1, 1, 1, 0.36))
	var core := PackedVector2Array([
		Vector2(pos.x, pos.y - 19),
		Vector2(pos.x - 6.5, pos.y - 7.5),
		Vector2(pos.x - 4.0, pos.y + 4.0),
		Vector2(pos.x + 4.0, pos.y + 4.0),
		Vector2(pos.x + 6.5, pos.y - 7.5),
	])
	draw_colored_polygon(core, outline * Color(1, 1, 1, 0.85))
	draw_polyline(core, outline.darkened(0.25), 1.2, true)
	draw_line(pos + Vector2(0, -3), pos + Vector2(0, -16), outline.lightened(0.12), 1.6)

func _check_tower_tap(pos: Vector2) -> bool:
	for t in tower_container.get_children():
		if pos.distance_to(t.position) < 30:
			tower_selected.emit(t)
			return true
	return false

func _check_placement_valid(pos: Vector2) -> bool:
	if _is_too_close_to_any_base(pos, 60.0):
		return false
	for t in tower_container.get_children():
		if pos.distance_to(t.position) < 70:
			return false
	for path in paths:
		for i in range(path.size() - 1):
			var a: Vector2 = path[i]
			var b: Vector2 = path[i + 1]
			var seg := b - a
			var seg_len_sq: float = seg.length_squared()
			var t_param: float = 0.0
			if seg_len_sq > 0.01:
				t_param = clamp((pos - a).dot(seg) / seg_len_sq, 0.0, 1.0)
			var closest := a + t_param * seg
			if pos.distance_to(closest) < 50:
				return false
	return true
