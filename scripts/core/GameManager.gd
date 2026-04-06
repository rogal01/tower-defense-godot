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
signal campaign_won_triggered(stars: int, score: int, level_id: int)
signal warning_requested(title: String, body: String, color: Color)
signal game_configured

# ─── Scene references (set in game.tscn) ─────────────────────────────────────
@onready var enemy_container: Node2D = $EnemyContainer
@onready var tower_container: Node2D = $TowerContainer
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var effects_container: Node2D = $EffectsContainer
@onready var map_node: Node2D = $Map
@onready var hud: CanvasLayer = $HUD
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var pause_menu: CanvasLayer = $PauseMenu

# Preloaded scenes
var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
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

# Difficulty / mode
var difficulty: int = 1         # 0=easy, 1=normal, 2=hard, 3=endless
var enemy_hp_mult: float = 1.0
var enemy_speed_mult: float = 1.0
var enemy_dmg_mult: float = 1.0
var gold_mult: float = 1.0
var spawn_rate_mult: float = 1.0
var is_endless: bool = false
var is_boss_rush: bool = false
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
	difficulty = 1
	enemy_hp_mult = 1.0
	enemy_speed_mult = 1.0
	enemy_dmg_mult = 1.0
	gold_mult = 1.0
	spawn_rate_mult = 1.0
	is_endless = false
	is_boss_rush = false
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
	gold_changed.emit(gold)
	score_changed.emit(score)
	base_hp_changed.emit(base_hp, max_base_hp)
	wave_changed.emit(wave)

func configure(p_difficulty: int, p_map_type: int) -> void:
	campaign_level = {}
	map_type = p_map_type
	_apply_difficulty(p_difficulty)
	AchievementManager.reset_run()
	_load_skill_bonuses()
	generate_paths()
	_generate_terrain_zones()
	_sync_map_visuals()
	game_configured.emit()
	gold_changed.emit(gold)
	score_changed.emit(score)
	base_hp_changed.emit(base_hp, max_base_hp)
	wave_changed.emit(wave)

func configure_campaign(ld: Dictionary) -> void:
	campaign_level = ld
	map_type        = ld.get("map", GameData.MapType.CLASSIC)
	difficulty      = 1
	is_endless      = false
	is_boss_rush    = false
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
	generate_paths()
	_generate_terrain_zones()
	_sync_map_visuals()
	game_configured.emit()
	gold_changed.emit(gold)
	score_changed.emit(score)
	base_hp_changed.emit(base_hp, max_base_hp)
	wave_changed.emit(wave)

func _trigger_campaign_win() -> void:
	game_over = true
	var lid: int   = campaign_level.get("id",    0)
	var star2: int = campaign_level.get("star2", 99999)
	var star3: int = campaign_level.get("star3", 99999)
	var stars: int = 1
	if   score >= star3: stars = 3
	elif score >= star2: stars = 2
	var diamonds: int = campaign_level.get("diamonds", 3)
	SaveManager.save_campaign_result(lid, stars)
	SaveManager.add_diamonds(diamonds)
	SaveManager.add_stat("lifetime_games", 1)
	SaveManager.add_stat("lifetime_waves", wave)
	SaveManager.add_stat("lifetime_score", score)
	SaveManager.flush()
	var beaten_count := CampaignData.get_beaten_count()
	var stars5_count := CampaignData.get_three_star_count()
	AchievementManager.on_campaign_result(lid, stars, base_hp >= max_base_hp,
		beaten_count, stars5_count, 40)
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_victory_stinger()
		get_node("/root/SoundManager").play_victory_music()
	campaign_won_triggered.emit(stars, score, lid)

func _apply_difficulty(level: int) -> void:
	difficulty = level
	is_endless = (level == 3)
	is_boss_rush = (level == 4)
	match level:
		0: # Easy
			enemy_hp_mult = 0.7; enemy_dmg_mult = 0.6; enemy_speed_mult = 0.85
			gold_mult = 1.3; spawn_rate_mult = 0.8; gold = 80
		1: # Normal
			enemy_hp_mult = 1.0; enemy_dmg_mult = 1.0; enemy_speed_mult = 1.0
			gold_mult = 1.0; spawn_rate_mult = 1.0; gold = 50
		2: # Hard
			enemy_hp_mult = 1.5; enemy_dmg_mult = 1.4; enemy_speed_mult = 1.15
			gold_mult = 0.8; spawn_rate_mult = 1.3; gold = 30
		3: # Endless
			enemy_hp_mult = 1.0; enemy_dmg_mult = 1.0; enemy_speed_mult = 1.0
			gold_mult = 1.0; spawn_rate_mult = 1.0; gold = 50
		4: # Boss Rush
			enemy_hp_mult = 1.0; enemy_dmg_mult = 1.0; enemy_speed_mult = 1.0
			gold_mult = 1.5; spawn_rate_mult = 0.8; gold = 100; boss_interval = 1
		_:
			enemy_hp_mult = 1.0; gold = 50

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

func _init_powers() -> void:
	for pt in GameData.PowerType.values():
		power_cooldowns[pt] = 0.0

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

	# Placement preview animation
	if placement_active:
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
	var power_types: Array = GameData.PowerType.values()
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
		GameData.MapType.LAVA:         _gen_lava_paths(w, h, bx, by)
		GameData.MapType.ENCHANTED:    _gen_enchanted_paths(w, h, bx, by)
		GameData.MapType.VOLCANO:      _gen_volcano_paths(w, h, bx, by)

func _jitter(base: float, range_val: float) -> float:
	return base + randf_range(-range_val, range_val)

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

func _sync_map_visuals() -> void:
	if map_node == null:
		return
	map_node.paths = paths
	map_node.map_type = map_type
	map_node.base_position = base_position
	map_node.set("terrain_zones", terrain_zones)
	if map_node.has_method("refresh_layout"):
		map_node.refresh_layout()
	else:
		map_node.queue_redraw()

func _generate_terrain_zones() -> void:
	terrain_zones.clear()
	match map_type:
		GameData.MapType.SNOW:
			terrain_zones.append({"kind": "frost", "pos": Vector2(118, 292), "radius": 44.0, "strength": 0.82})
			terrain_zones.append({"kind": "frost", "pos": Vector2(336, 506), "radius": 40.0, "strength": 0.8})
		GameData.MapType.LAVA:
			terrain_zones.append({"kind": "lava", "pos": Vector2(152, 378), "radius": 42.0, "dps": 12.0})
			terrain_zones.append({"kind": "lava", "pos": Vector2(316, 566), "radius": 38.0, "dps": 10.0})
		GameData.MapType.VOLCANO:
			terrain_zones.append({"kind": "lava", "pos": Vector2(132, 328), "radius": 46.0, "dps": 16.0})
			terrain_zones.append({"kind": "lava", "pos": Vector2(344, 486), "radius": 44.0, "dps": 14.0})
			terrain_zones.append({"kind": "lava", "pos": Vector2(238, 640), "radius": 40.0, "dps": 12.0})
		GameData.MapType.ENCHANTED:
			terrain_zones.append({"kind": "arcane", "pos": Vector2(144, 262), "radius": 40.0, "pulse_damage": 14.0})
			terrain_zones.append({"kind": "arcane", "pos": Vector2(322, 480), "radius": 36.0, "pulse_damage": 16.0})
		GameData.MapType.DESERT:
			terrain_zones.append({"kind": "dune", "pos": Vector2(132, 252), "radius": 44.0, "speed": 1.12})
			terrain_zones.append({"kind": "dune", "pos": Vector2(332, 560), "radius": 40.0, "speed": 1.1})

func get_next_wave_preview() -> Dictionary:
	var next_wave: int = wave + 1
	var boss_wave := is_boss_rush or (boss_interval > 0 and next_wave % boss_interval == 0)
	var title := "Next Wave %d" % next_wave
	var body_lines: Array[String] = []
	if boss_wave:
		var boss_types: Array = GameData.BossType.values()
		var preview_boss: int = boss_types[next_wave % boss_types.size()]
		var boss_name: String = GameData.get_boss(preview_boss).get("name", "Boss")
		body_lines.append("Boss incoming: %s" % boss_name)
		body_lines.append("Expect heavy damage and ability casts.")
	else:
		var count: int = int((3 + next_wave * 2) * spawn_rate_mult)
		body_lines.append("Approx enemies: %d" % min(count, 100))
		body_lines.append("Likely foes: %s" % _preview_enemy_names(next_wave))
	if next_wave >= 3:
		body_lines.append("Possible modifier: armored, fast, swarm, or rich.")
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
		GameData.MapType.LAVA, GameData.MapType.VOLCANO:
			return "Lava vents burn anything standing in them."
		GameData.MapType.ENCHANTED:
			return "Arcane wells pulse magic damage."
		GameData.MapType.DESERT:
			return "Dune gusts speed enemies up."
		_:
			return ""

func _emit_wave_warning() -> void:
	if current_boss_type >= 0:
		var boss_name: String = str(GameData.get_boss(current_boss_type).get("name", "Boss"))
		warning_requested.emit(
			"Boss Wave",
			"%s is entering the field. Save your powers and cover the lane merge." % boss_name,
			Color(0.95, 0.36, 0.24)
		)
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play_warning(true)
		return
	if current_wave_modifier != GameData.WaveModifier.NONE:
		var mod_data: Dictionary = GameData.MODIFIER_NAMES.get(current_wave_modifier, {})
		warning_requested.emit(
			"%s Wave" % mod_data.get("name", "Danger"),
			"Wave %d has an active modifier. Adjust your tower mix before the pressure spikes." % wave,
			mod_data.get("color", Color(0.9, 0.6, 0.25))
		)
		if has_node("/root/SoundManager"):
			get_node("/root/SoundManager").play_warning(false)
		return
	var terrain_text := _get_map_hazard_text()
	if terrain_text != "" and wave == 1:
		warning_requested.emit("Terrain Alert", terrain_text, Color(0.64, 0.82, 1.0))

# ─── Wave System ──────────────────────────────────────────────────────────────

func _start_next_wave() -> void:
	wave += 1
	wave_in_progress = true
	show_wave_banner = true
	wave_banner_timer = 1.5
	wave_changed.emit(wave)
	base_hp_before_wave = base_hp

	# Endless scaling
	if is_endless and wave > 10:
		var tier: float = minf((wave - 10) / 10.0, 5.0)
		enemy_hp_mult = 1.0 + tier * 0.15
		enemy_dmg_mult = 1.0 + tier * 0.10
		enemy_speed_mult = 1.0 + tier * 0.05
		spawn_rate_mult = 1.0 + tier * 0.08

	# Wave modifier (random from wave 3)
	if wave >= 3 and randf() < 0.4:
		var mods := [GameData.WaveModifier.FAST, GameData.WaveModifier.ARMORED,
					 GameData.WaveModifier.REGEN, GameData.WaveModifier.SWARM,
					 GameData.WaveModifier.RICH, GameData.WaveModifier.SHIELDED,
					 GameData.WaveModifier.BOSS_RALLY, GameData.WaveModifier.BERSERKER]
		current_wave_modifier = mods[randi() % mods.size()]
	else:
		current_wave_modifier = GameData.WaveModifier.NONE

	# Track map for cartographer achievement
	var map_name: String = GameData.MapType.keys()[map_type]
	SaveManager.add_map_played(map_name)
	AchievementManager.on_maps_played(SaveManager.get_maps_played().size())

	# Boss wave check
	if is_boss_rush or (wave % boss_interval == 0):
		if boss_pool.is_empty():
			boss_pool = GameData.BossType.values().duplicate()
			boss_pool.shuffle()
		current_boss_type = boss_pool.pop_front()
		enemies_remaining = 1  # Boss + minions will be spawned together
		_trigger_shake(0.4, 12.0)
	else:
		current_boss_type = -1
		var count: int = int((3 + wave * 2) * spawn_rate_mult)
		count = mini(count, 100)
		if current_wave_modifier == GameData.WaveModifier.SWARM:
			count *= 2
		enemies_remaining = count

	wave_banner_shown.emit(wave, current_wave_modifier)
	_emit_wave_warning()
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_wave_start(current_boss_type >= 0)

	if wave >= 5 and _tower_count() == 0:
		AchievementManager.on_wave_5_no_towers()

func _on_wave_complete() -> void:
	wave_in_progress = false
	wave_timer = wave_delay if not is_boss_rush else 3.0

	# Campaign win check
	if not campaign_level.is_empty():
		var target: int = campaign_level.get("target_wave", 0)
		if target > 0 and wave >= target:
			_trigger_campaign_win()
			return

	AchievementManager.on_wave_complete(wave, base_hp, max_base_hp, base_hp_before_wave,
		is_endless, map_type, false, game_speed)

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

	var hp: float = edata["hp"] * wave_scale * enemy_hp_mult * hp_mod
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

	if current_wave_modifier == GameData.WaveModifier.SHIELDED:
		e_node.shield_timer = 3.0

	e_node.died.connect(_on_enemy_died.bind(e_node))
	e_node.reached_base.connect(_on_enemy_reached_base.bind(e_node))

func _configure_boss(e_node: Node, path_idx: int, wave_scale: float) -> void:
	if current_boss_type < 0:
		return
	var bt := current_boss_type
	var bdata: Dictionary = GameData.get_boss(bt)
	var spawn_pt: Vector2 = paths[path_idx][0]

	var hp: float = (bdata["hp"] + wave * 40.0) * wave_scale * enemy_hp_mult
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
			md["speed"] * enemy_speed_mult, md["hp"] * wave_scale * enemy_hp_mult,
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

	for tower_node in tower_container.get_children():
		tower_node.tick(dt, all_enemies, freeze_mult, target_mode,
						skill_tower_damage_bonus, self)

	for enemy_node in all_enemies:
		enemy_node.tick(dt * freeze_mult)

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

func try_place_tower(pos: Vector2) -> bool:
	pos = _snap_to_grid(pos)
	var tdata := GameData.get_tower(placement_tower_type)
	var cost: int = tdata["cost"]

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

	# Distance from base
	if pos.distance_to(base_position) < 60:
		_spawn_text(pos.x, pos.y - 40, "Too close to base!", Color(1, 0.5, 0.3), 1.0, 22)
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
	t_node.setup(placement_tower_type, tdata, skill_tower_damage_bonus, skill_ability_cd_mult)
	t_node.ability_fired.connect(_on_tower_ability.bind(t_node))
	t_node.pressed.connect(_on_tower_pressed.bind(t_node))

	# Achievement tracking
	var types: Array = []
	for t in tower_container.get_children():
		if t.tower_type not in types:
			types.append(t.tower_type)
	towers_placed_types = types
	AchievementManager.on_tower_placed(_tower_count(), types)
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_place()

	cancel_placement()
	return true

func _snap_to_grid(pos: Vector2) -> Vector2:
	var snapped := Vector2(round(pos.x / 40.0) * 40.0, round(pos.y / 40.0) * 40.0)
	snapped.x = clampf(snapped.x, 40.0, screen_w - 40.0)
	snapped.y = clampf(snapped.y, 120.0, screen_h - 140.0)
	return snapped

func _update_placement_preview(pos: Vector2) -> void:
	if not placement_active:
		return
	placement_preview_pos = _snap_to_grid(pos)
	placement_preview_range = GameData.get_tower(placement_tower_type).get("range", 200.0)
	placement_preview_valid = _check_placement_valid(placement_preview_pos)

func sell_tower(tower_node: Node) -> void:
	var tdata := GameData.get_tower(tower_node.tower_type)
	var sell_val := GameData.tower_sell_value(tdata["cost"], tower_node.level, skill_sell_bonus)
	_add_gold(sell_val)
	_spawn_text(tower_node.position.x, tower_node.position.y - 40,
		"+%dg sold!" % sell_val, Color(1.0, 0.85, 0.0), 1.2, 26)
	tower_node.queue_free()

func upgrade_tower(tower_node: Node) -> bool:
	if tower_node.level >= 10:
		return false
	if not campaign_level.is_empty() and not campaign_level.get("upgrades", true):
		return false
	var tdata := GameData.get_tower(tower_node.tower_type)
	var cost := GameData.tower_upgrade_cost(tdata["cost"], tower_node.level)
	if gold < cost:
		return false
	gold -= cost
	gold_changed.emit(gold)
	tower_node.upgrade(skill_tower_damage_bonus, skill_ability_cd_mult)
	if tower_node.level >= 10:
		AchievementManager.on_tower_maxed()
	# Check if all towers are upgraded (level >= 2)
	var upgraded := tower_container.get_children().filter(func(t): return t.level >= 2)
	AchievementManager.on_all_towers_upgraded(_tower_count(), upgraded.size())
	return true

# ─── Power Usage ──────────────────────────────────────────────────────────────

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
	power_cooldowns[power_type] = pdata["cooldown"] * skill_ability_cd_mult
	AchievementManager.on_power_used(power_type)
	powers_used_this_run[power_type] = true
	if has_node("/root/SoundManager"):
		get_node("/root/SoundManager").play_power(power_type)

	match power_type:
		GameData.PowerType.FIREBALL: _power_fireball(target_pos)
		GameData.PowerType.FREEZE:   _power_freeze()
		GameData.PowerType.HEAL:     _power_heal()
		GameData.PowerType.LIGHTNING: _power_lightning(target_pos)
	return true

func _power_fireball(_pos: Vector2) -> void:
	var base_dmg := 50.0
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
	var dmg := 80.0
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
	_spawn_text(base_position.x, base_position.y - 40,
		"-%.0f HP" % dmg, Color(1.0, 0.2, 0.2), 1.2, 28)
	enemy_node.queue_free()

	if base_hp <= 0:
		_trigger_game_over()

func _trigger_game_over() -> void:
	game_over = true
	var is_new_high := SaveManager.submit_score(score)
	SaveManager.submit_wave(wave)
	if is_endless:
		SaveManager.submit_endless(wave)
	SaveManager.add_stat("lifetime_kills", total_kills)
	SaveManager.add_stat("lifetime_games", 1)
	SaveManager.add_stat("lifetime_waves", wave)
	SaveManager.add_stat("lifetime_score", score)
	SaveManager.add_stat("lifetime_gold", total_gold_earned)
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
		GameData.TowerType.FLAME:      _ability_inferno(tower_node)
		GameData.TowerType.NECRO:      _ability_soul_harvest(tower_node)
		GameData.TowerType.BALLISTA:   _ability_siege_shot(tower_node)
		GameData.TowerType.VORTEX:     _ability_singularity(tower_node)
		GameData.TowerType.HEALER:     _ability_mass_heal(tower_node)

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
	shake_timer = duration
	shake_intensity = intensity

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
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		var pressed: bool = event.pressed if event is InputEventMouseButton else event.pressed
		if pressed:
			var pos: Vector2 = event.position
			if placement_active:
				_update_placement_preview(pos)
				try_place_tower(pos)

# ─── Speed control ────────────────────────────────────────────────────────────

func set_game_speed(speed: int) -> void:
	game_speed = clamp(speed, 1, 3)

func toggle_pause() -> void:
	is_paused = !is_paused
	if pause_menu:
		pause_menu.visible = is_paused

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
	if not placement_active or placement_preview_pos.x < 0:
		return
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
		draw_circle(placement_preview_pos, 10.0, accent * Color(1, 1, 1, 0.1))
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
	queue_redraw()

func _get_tower_accent_color(ttype: int) -> Color:
	match ttype:
		GameData.TowerType.ARROW:    return Color(0.3, 0.7, 0.2)
		GameData.TowerType.MAGIC:    return Color(0.8, 0.5, 1.0)
		GameData.TowerType.CANNON:   return Color(0.9, 0.3, 0.1)
		GameData.TowerType.POISON:   return Color(0.3, 0.9, 0.2)
		GameData.TowerType.TESLA:    return Color(1.0, 0.9, 0.2)
		GameData.TowerType.ICE:      return Color(0.7, 0.95, 1.0)
		GameData.TowerType.FLAME:    return Color(1.0, 0.6, 0.1)
		GameData.TowerType.NECRO:    return Color(0.6, 0.2, 0.8)
		GameData.TowerType.BALLISTA: return Color(0.9, 0.7, 0.3)
		GameData.TowerType.VORTEX:   return Color(0.4, 0.5, 1.0)
		GameData.TowerType.HEALER:   return Color(0.3, 1.0, 0.5)
		_:                           return Color(0.9, 0.8, 0.3)

func _check_tower_tap(pos: Vector2) -> void:
	for t in tower_container.get_children():
		if pos.distance_to(t.position) < 30:
			tower_selected.emit(t)
			return

func _check_placement_valid(pos: Vector2) -> bool:
	if pos.distance_to(base_position) < 60:
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
