# SaveManager.gd — Autoload singleton: persistent save/load
extends Node

const SAVE_PATH := "user://save.cfg"
const SCHEMA_VERSION := 1

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

# ─── Generic get/set ──────────────────────────────────────────────────────────

func get_int(key: String, default_val: int = 0) -> int:
	return int(_cfg.get_value("game", key, default_val))

func get_float(key: String, default_val: float = 0.0) -> float:
	return float(_cfg.get_value("game", key, default_val))

func get_bool(key: String, default_val: bool = false) -> bool:
	return bool(_cfg.get_value("game", key, default_val))

func get_string(key: String, default_val: String = "") -> String:
	return str(_cfg.get_value("game", key, default_val))

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
	return int(_cfg.get_value("skills", skill_id, 0))

func set_skill_level(skill_id: String, level: int) -> void:
	_cfg.set_value("skills", skill_id, level)
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
	return int(_cfg.get_value("skills", "prestige", 0))

func do_prestige() -> void:
	var p := get_prestige_count() + 1
	_cfg.set_value("skills", "prestige", p)
	# Reset base skill levels on prestige
	for key in GameData.SKILLS.keys():
		if not key in ["prestige_gold", "ice_power", "ability_cd", "sell_bonus", "resist_pierce", "wave_modifier"]:
			_cfg.set_value("skills", key, 0)
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

# Stats accumulation
func add_stat(key: String, amount: int) -> void:
	var v := int(_cfg.get_value("stats", key, 0))
	_cfg.set_value("stats", key, v + amount)
	_dirty = true

func get_stat(key: String) -> int:
	return int(_cfg.get_value("stats", key, 0))

# ─── Campaign ─────────────────────────────────────────────────────────────────

func is_campaign_beaten(level_id: int) -> bool:
	return bool(_cfg.get_value("campaign", "beaten_%d" % level_id, false))

func get_campaign_stars(level_id: int) -> int:
	return int(_cfg.get_value("campaign", "stars_%d" % level_id, 0))

func save_campaign_result(level_id: int, stars: int) -> void:
	_cfg.set_value("campaign", "beaten_%d" % level_id, true)
	var prev := get_campaign_stars(level_id)
	if stars > prev:
		_cfg.set_value("campaign", "stars_%d" % level_id, stars)
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

func get_stars() -> int:
	return int(_cfg.get_value("skills", "stars", 0))

func add_stars(amount: int) -> void:
	var current := get_stars()
	_cfg.set_value("skills", "stars", current + amount)
	_dirty = true

func spend_stars(amount: int) -> bool:
	var current := get_stars()
	if current < amount:
		return false
	_cfg.set_value("skills", "stars", current - amount)
	_dirty = true
	return true

func get_upgrade_level(upg_id: String) -> int:
	return int(_cfg.get_value("upgrades", upg_id, 0))

func set_upgrade_level(upg_id: String, level: int) -> void:
	_cfg.set_value("upgrades", upg_id, level)
	_dirty = true
