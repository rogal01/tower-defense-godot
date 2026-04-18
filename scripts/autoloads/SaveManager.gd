# SaveManager.gd — Autoload singleton: persistent save/load
extends Node

const SAVE_PATH := "user://save.cfg"
const SCHEMA_VERSION := 3

var _cfg := ConfigFile.new()
var _dirty := false

func _ready() -> void:
	_load()

func _load() -> void:
	var err := _cfg.load(SAVE_PATH)
	if err != OK:
		# Fresh install — write defaults
		_cfg.set_value("meta", "version", SCHEMA_VERSION)
		_save_now()
		return
	var version := int(_cfg.get_value("meta", "version", 0))
	if version != SCHEMA_VERSION:
		reset_progress()

# ─── Generic get/set ──────────────────────────────────────────────────────────

func get_int(key: String, default_val: int = 0) -> int:
	return int(_cfg.get_value("game", key, default_val))

func get_float(key: String, default_val: float = 0.0) -> float:
	return float(_cfg.get_value("game", key, default_val))

func get_bool(key: String, default_val: bool = false) -> bool:
	return bool(_cfg.get_value("game", key, default_val))

func get_string(key: String, default_val: String = "") -> String:
	return str(_cfg.get_value("game", key, default_val))

func get_val(key: String, default_val: Variant = null) -> Variant:
	return _cfg.get_value("game", key, default_val)

func set_val(key: String, value: Variant) -> void:
	_cfg.set_value("game", key, value)
	_dirty = true

func flush() -> void:
	if _dirty:
		_save_now()

func _save_now() -> void:
	_cfg.save(SAVE_PATH)
	_dirty = false

# ─── Skill tree ───────────────────────────────────────────────────────────────

func get_skill_level(skill_id: String) -> int:
	return int(_cfg.get_value("skills", "skill_%s" % skill_id, 0))

func set_skill_level(skill_id: String, level: int) -> void:
	_cfg.set_value("skills", "skill_%s" % skill_id, level)
	_dirty = true

func get_diamonds() -> int:
	return int(_cfg.get_value("skills", "diamonds", 0))

func add_diamonds(amount: int) -> void:
	var current := get_diamonds()
	_cfg.set_value("skills", "diamonds", current + amount)
	_dirty = true

func spend_diamonds(amount: int) -> bool:
	var current := get_diamonds()
	if current < amount:
		return false
	_cfg.set_value("skills", "diamonds", current - amount)
	_dirty = true
	return true

func get_prestige_count() -> int:
	return int(_cfg.get_value("skills", "prestige_level", 0))

func do_prestige() -> void:
	var p := get_prestige_count() + 1
	_cfg.set_value("skills", "prestige_level", p)
	# Reset base skill levels on prestige
	for key in GameData.SKILLS.keys():
		if not key in GameData.PRESTIGE_SKILL_IDS:
			_cfg.set_value("skills", "skill_%s" % key, 0)
	_dirty = true
	flush()

# ─── Achievements ─────────────────────────────────────────────────────────────

func is_achievement_unlocked(id: String) -> bool:
	return bool(_cfg.get_value("achievements", id, false))

func unlock_achievement(id: String) -> void:
	if not is_achievement_unlocked(id):
		_cfg.set_value("achievements", id, true)
		_dirty = true
		flush()

# ─── High scores & stats ──────────────────────────────────────────────────────

func get_high_score() -> int:
	return int(_cfg.get_value("scores", "high_score", 0))

func submit_score(score: int) -> bool:
	var prev := get_high_score()
	if score > prev:
		_cfg.set_value("scores", "high_score", score)
		_dirty = true
		flush()
		return true
	return false

func get_high_wave() -> int:
	return int(_cfg.get_value("scores", "high_wave", 0))

func submit_wave(wave: int) -> bool:
	var prev := get_high_wave()
	if wave > prev:
		_cfg.set_value("scores", "high_wave", wave)
		_dirty = true
		flush()
		return true
	return false

func get_endless_record() -> int:
	return int(_cfg.get_value("scores", "endless_high", 0))

func submit_endless(wave: int) -> bool:
	var prev := get_endless_record()
	if wave > prev:
		_cfg.set_value("scores", "endless_high", wave)
		_dirty = true
		flush()
		return true
	return false

func get_boss_rush_record() -> int:
	return int(_cfg.get_value("scores", "boss_rush_high", 0))

func submit_boss_rush(wave: int) -> bool:
	var prev := get_boss_rush_record()
	if wave > prev:
		_cfg.set_value("scores", "boss_rush_high", wave)
		_dirty = true
		flush()
		return true
	return false

# Stats accumulation
func add_stat(key: String, amount: int) -> void:
	var v := int(_cfg.get_value("stats", key, 0))
	_cfg.set_value("stats", key, v + amount)
	_dirty = true

func get_stat(key: String) -> int:
	return int(_cfg.get_value("stats", key, 0))

func set_stat_max(key: String, value: int) -> void:
	var current := int(_cfg.get_value("stats", key, 0))
	if value > current:
		_cfg.set_value("stats", key, value)
		_dirty = true

# ─── Campaign ─────────────────────────────────────────────────────────────────

func is_campaign_beaten(level_id: int) -> bool:
	return bool(_cfg.get_value("campaign", "beaten_%d" % level_id, false))

func is_campaign_full_hp(level_id: int) -> bool:
	return bool(_cfg.get_value("campaign", "full_hp_%d" % level_id, false))

func get_campaign_stars(level_id: int) -> int:
	if not is_campaign_beaten(level_id):
		return 0
	return 3 if is_campaign_full_hp(level_id) else 1

func save_campaign_result(level_id: int, full_hp: bool) -> void:
	_cfg.set_value("campaign", "beaten_%d" % level_id, true)
	if full_hp:
		_cfg.set_value("campaign", "full_hp_%d" % level_id, true)
	_dirty = true
	flush()

# ─── Maps played (for cartographer achievement) ───────────────────────────────

func get_maps_played() -> Array:
	var s := str(_cfg.get_value("stats", "maps_played", ""))
	if s.is_empty():
		return []
	return s.split(",")

func add_map_played(map_name: String) -> void:
	var arr := get_maps_played()
	if map_name not in arr:
		arr.append(map_name)
		_cfg.set_value("stats", "maps_played", ",".join(arr))
		_dirty = true

# Tower mastery kills
func get_mastery_kills(tower_type_name: String) -> int:
	return int(_cfg.get_value("mastery", tower_type_name, 0))

func add_mastery_kills(tower_type_name: String, kills: int) -> void:
	var k := get_mastery_kills(tower_type_name)
	_cfg.set_value("mastery", tower_type_name, k + kills)
	_dirty = true

# ─── Tech tree / Stars ─────────────────────────────────────────────────────

func reset_progress() -> void:
	var keep_music := get_float("music_volume_db", -12.0)
	var keep_sfx := get_float("sfx_volume_db", -8.0)
	var keep_master := get_float("master_volume_db", 0.0)
	var keep_show_fps := get_bool("show_fps", false)
	var keep_screen_shake := get_bool("screen_shake", true)
	var keep_palette := get_string("ui_palette", GameData.current_palette)

	_cfg = ConfigFile.new()
	_cfg.set_value("meta", "version", SCHEMA_VERSION)
	_cfg.set_value("game", "music_volume_db", keep_music)
	_cfg.set_value("game", "sfx_volume_db", keep_sfx)
	_cfg.set_value("game", "master_volume_db", keep_master)
	_cfg.set_value("game", "show_fps", keep_show_fps)
	_cfg.set_value("game", "screen_shake", keep_screen_shake)
	_cfg.set_value("game", "ui_palette", keep_palette)
	_dirty = true
	flush()
