extends Node

const MUSIC_PATHS := {
	"menu": "res://assets/audio/menu_theme.wav",
	"battle": "res://assets/audio/battle_theme.wav",
	"victory": "res://assets/audio/victory_theme.wav",
}

const SFX_PATHS := {
	"ui_click": "res://assets/audio/ui_click.wav",
	"place": "res://assets/audio/place.wav",
	"error": "res://assets/audio/error.wav",
	"warning": "res://assets/audio/warning.wav",
	"wave_start": "res://assets/audio/wave_start.wav",
	"boss_warning": "res://assets/audio/boss_warning.wav",
	"victory_stinger": "res://assets/audio/victory_stinger.wav",
	"shot_arrow": "res://assets/audio/shot_arrow.wav",
	"shot_magic": "res://assets/audio/shot_magic.wav",
	"shot_cannon": "res://assets/audio/shot_cannon.wav",
	"shot_tesla": "res://assets/audio/shot_tesla.wav",
	"shot_flame": "res://assets/audio/shot_flame.wav",
}

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var master_volume_db: float = 0.0
var music_volume_db: float = -12.0
var sfx_volume_db: float = -8.0
var _current_music: String = ""

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

	for _i in range(8):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)

	master_volume_db = SaveManager.get_float("master_volume_db", 0.0)
	music_volume_db = SaveManager.get_float("music_volume_db", -12.0)
	sfx_volume_db = SaveManager.get_float("sfx_volume_db", -8.0)
	_apply_volumes()

func _apply_volumes() -> void:
	if music_player:
		music_player.volume_db = music_volume_db + master_volume_db
	for player in sfx_players:
		player.volume_db = sfx_volume_db + master_volume_db

func set_master_volume(volume_db: float) -> void:
	master_volume_db = volume_db
	_apply_volumes()
	SaveManager.set_val("master_volume_db", volume_db)
	SaveManager.flush()

func set_music_volume(volume_db: float) -> void:
	music_volume_db = volume_db
	_apply_volumes()
	SaveManager.set_val("music_volume_db", volume_db)
	SaveManager.flush()

func set_sfx_volume(volume_db: float) -> void:
	sfx_volume_db = volume_db
	_apply_volumes()
	SaveManager.set_val("sfx_volume_db", volume_db)
	SaveManager.flush()

func play_menu_music() -> void:
	_play_music("menu")

func play_battle_music() -> void:
	_play_music("battle")

func play_victory_music() -> void:
	_play_music("victory")

func stop_music() -> void:
	if music_player:
		music_player.stop()
	_current_music = ""

func play_ui_click() -> void:
	_play_sfx("ui_click")

func play_place() -> void:
	_play_sfx("place")

func play_error() -> void:
	_play_sfx("error")

func play_warning(is_boss: bool = false) -> void:
	_play_sfx("boss_warning" if is_boss else "warning")

func play_wave_start(is_boss: bool = false) -> void:
	_play_sfx("boss_warning" if is_boss else "wave_start")

func play_victory_stinger() -> void:
	_play_sfx("victory_stinger")

func play_shot(tower_type: int) -> void:
	match tower_type:
		GameData.TowerType.ARROW, GameData.TowerType.BALLISTA:
			_play_sfx("shot_arrow")
		GameData.TowerType.MAGIC, GameData.TowerType.NECRO, GameData.TowerType.VORTEX:
			_play_sfx("shot_magic")
		GameData.TowerType.CANNON:
			_play_sfx("shot_cannon")
		GameData.TowerType.TESLA:
			_play_sfx("shot_tesla")
		GameData.TowerType.FLAME, GameData.TowerType.POISON:
			_play_sfx("shot_flame")
		_:
			_play_sfx("ui_click")

func play_power(power_type: int) -> void:
	match power_type:
		GameData.PowerType.FIREBALL:
			_play_sfx("shot_cannon")
		GameData.PowerType.FREEZE:
			_play_sfx("shot_magic")
		GameData.PowerType.HEAL:
			_play_sfx("place")
		GameData.PowerType.LIGHTNING:
			_play_sfx("shot_tesla")

func _play_music(key: String) -> void:
	if _current_music == key and music_player.playing:
		return
	var path: String = str(MUSIC_PATHS.get(key, ""))
	if path == "":
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	music_player.stream = stream
	music_player.volume_db = music_volume_db + master_volume_db
	music_player.play()
	_current_music = key

func _play_sfx(key: String) -> void:
	var path: String = str(SFX_PATHS.get(key, ""))
	if path == "" or sfx_players.is_empty():
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	var player: AudioStreamPlayer = sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % sfx_players.size()
	player.stop()
	player.stream = stream
	player.volume_db = sfx_volume_db + master_volume_db
	player.play()
