# GameData.gd — Autoload singleton: all static game data
extends Node

# ─── Enums ───────────────────────────────────────────────────────────────────

enum EnemyType {
	GOBLIN, SKELETON, ORC, DEMON, DRAGON,
	FAST_SKELETON, ARMORED_GOLEM, BAT, SLIME, SPIDER,
	WISP, SHADOW, BERSERKER, COMMANDER, SHAPESHIFTER,
	GOLEM_SHARD, MINI_ORC, MINI_SKELETON, MINI_DEMON, MINI_DRAGON,
	BOSS
}

enum DamageType {
	PHYSICAL, MAGIC, EXPLOSIVE, POISON, ELECTRIC, ICE, FIRE, DARK
}

enum TowerType {
	ARROW, MAGIC, CANNON, POISON, TESLA, ICE, FLAME, NECRO, BALLISTA, VORTEX, HEALER
}

enum BossType {
	ORC_KING, LICH_LORD, DEMON_PRINCE, DRAGON_QUEEN, SHADOW_WRAITH,
	SLIME_KING, VAMPIRE_LORD, SPIDER_QUEEN, FROST_TITAN, STONE_GOLEM
}

enum BossAbility {
	CHARGE, SUMMON, HEAL, AOE_DAMAGE, SHIELD, ROAR, TELEPORT, DRAIN, QUAKE, SPLIT
}

enum WaveModifier {
	NONE, FAST, ARMORED, REGEN, SWARM, RICH, INVISIBLE, SHIELDED,
	BOSS_RALLY, BERSERKER, SPLIT, ELITE
}

enum PowerType {
	FIREBALL, FREEZE, HEAL, LIGHTNING
}

enum MapType {
	CLASSIC, VALLEY, CROSSROADS, DESERT, SNOW, LAVA, ENCHANTED, VOLCANO
}

enum TargetMode {
	CLOSE, FIRST, LAST, STRONG
}

# ─── Tower Data ───────────────────────────────────────────────────────────────
# cost, dmg, range, fire_rate, damage_type, ability_cd, ability_name, emoji, description

var TOWERS: Dictionary = {
	TowerType.ARROW:    {cost=30,  dmg=8.0,  range=200.0, rate=1.2, dtype=DamageType.PHYSICAL, cd=25.0, ability="Volley",       emoji="🏹", desc="Rapid physical damage"},
	TowerType.MAGIC:    {cost=60,  dmg=14.0, range=220.0, rate=0.8, dtype=DamageType.MAGIC,    cd=30.0, ability="Arcane Blast", emoji="🔮", desc="Magic damage, ignores armor"},
	TowerType.CANNON:   {cost=100, dmg=30.0, range=180.0, rate=0.5, dtype=DamageType.EXPLOSIVE,cd=35.0, ability="Napalm",       emoji="💣", desc="Splash explosive damage"},
	TowerType.POISON:   {cost=80,  dmg=6.0,  range=210.0, rate=1.0, dtype=DamageType.POISON,   cd=28.0, ability="Plague",       emoji="☠️", desc="DoT poison damage"},
	TowerType.TESLA:    {cost=120, dmg=20.0, range=250.0, rate=0.7, dtype=DamageType.ELECTRIC, cd=32.0, ability="Overcharge",   emoji="⚡", desc="Chains to nearby enemies"},
	TowerType.ICE:      {cost=70,  dmg=0.0,  range=230.0, rate=0.0, dtype=DamageType.ICE,      cd=25.0, ability="Deep Freeze",  emoji="❄️", desc="Slows all enemies in range"},
	TowerType.FLAME:    {cost=90,  dmg=12.0, range=190.0, rate=0.9, dtype=DamageType.FIRE,     cd=30.0, ability="Inferno",      emoji="🔥", desc="Burns enemies over time"},
	TowerType.NECRO:    {cost=110, dmg=18.0, range=200.0, rate=0.6, dtype=DamageType.DARK,     cd=35.0, ability="Soul Harvest", emoji="💀", desc="Dark damage, heals on kill"},
	TowerType.BALLISTA: {cost=140, dmg=50.0, range=300.0, rate=0.3, dtype=DamageType.PHYSICAL, cd=40.0, ability="Siege Shot",   emoji="🎯", desc="Extreme range sniper"},
	TowerType.VORTEX:   {cost=100, dmg=4.0,  range=240.0, rate=1.5, dtype=DamageType.MAGIC,    cd=28.0, ability="Singularity",  emoji="🌀", desc="Pulls and damages enemies"},
	TowerType.HEALER:   {cost=80,  dmg=0.0,  range=220.0, rate=0.2, dtype=DamageType.MAGIC,    cd=20.0, ability="Mass Heal",    emoji="💚", desc="Repairs the base HP"},
}

# ─── Enemy Base Stats ─────────────────────────────────────────────────────────
# hp, speed, gold, dmg, emoji, size

var ENEMIES: Dictionary = {
	EnemyType.GOBLIN:        {hp=20,  speed=80,  gold=3,  dmg=5,  emoji="👺", size=28},
	EnemyType.SKELETON:      {hp=35,  speed=100, gold=5,  dmg=8,  emoji="💀", size=28},
	EnemyType.ORC:           {hp=60,  speed=60,  gold=8,  dmg=12, emoji="👹", size=32},
	EnemyType.DEMON:         {hp=80,  speed=90,  gold=12, dmg=15, emoji="😈", size=30},
	EnemyType.DRAGON:        {hp=150, speed=70,  gold=20, dmg=20, emoji="🐉", size=36},
	EnemyType.FAST_SKELETON: {hp=25,  speed=150, gold=6,  dmg=6,  emoji="💨", size=26},
	EnemyType.ARMORED_GOLEM: {hp=120, speed=40,  gold=15, dmg=18, emoji="🪨", size=38},
	EnemyType.BAT:           {hp=15,  speed=120, gold=2,  dmg=4,  emoji="🦇", size=22},
	EnemyType.SLIME:         {hp=30,  speed=50,  gold=4,  dmg=6,  emoji="🟢", size=28},
	EnemyType.SPIDER:        {hp=25,  speed=110, gold=4,  dmg=7,  emoji="🕷️", size=26},
	EnemyType.WISP:          {hp=18,  speed=130, gold=8,  dmg=3,  emoji="✨", size=22},
	EnemyType.SHADOW:        {hp=40,  speed=100, gold=10, dmg=10, emoji="👤", size=28},
	EnemyType.BERSERKER:     {hp=50,  speed=70,  gold=10, dmg=14, emoji="🦾", size=32},
	EnemyType.COMMANDER:     {hp=70,  speed=55,  gold=15, dmg=10, emoji="👑", size=34},
	EnemyType.SHAPESHIFTER:  {hp=45,  speed=90,  gold=12, dmg=9,  emoji="🔄", size=30},
	EnemyType.GOLEM_SHARD:   {hp=35,  speed=70,  gold=5,  dmg=8,  emoji="🪨", size=24},
	EnemyType.MINI_ORC:      {hp=20,  speed=80,  gold=3,  dmg=5,  emoji="👹", size=22},
	EnemyType.MINI_SKELETON: {hp=15,  speed=100, gold=2,  dmg=4,  emoji="💀", size=20},
	EnemyType.MINI_DEMON:    {hp=25,  speed=90,  gold=4,  dmg=6,  emoji="😈", size=22},
	EnemyType.MINI_DRAGON:   {hp=30,  speed=75,  gold=5,  dmg=7,  emoji="🐲", size=24},
}

# ─── Boss Data ────────────────────────────────────────────────────────────────

var BOSSES: Dictionary = {
	BossType.ORC_KING:     {name="Orc King",     emoji="👹", hp=700,  speed=35, gold=120, dmg=45, minion=EnemyType.MINI_ORC,      minion_count=6,  ability=BossAbility.CHARGE,     color=Color(0.20, 0.40, 0.10)},
	BossType.LICH_LORD:    {name="Lich Lord",    emoji="💀", hp=600,  speed=45, gold=100, dmg=35, minion=EnemyType.MINI_SKELETON,  minion_count=8,  ability=BossAbility.SUMMON,     color=Color(0.40, 0.10, 0.60)},
	BossType.DEMON_PRINCE: {name="Demon Prince", emoji="😈", hp=900,  speed=40, gold=150, dmg=55, minion=EnemyType.MINI_DEMON,     minion_count=5,  ability=BossAbility.AOE_DAMAGE, color=Color(0.70, 0.10, 0.10)},
	BossType.DRAGON_QUEEN: {name="Dragon Queen", emoji="🐲", hp=1100, speed=30, gold=200, dmg=60, minion=EnemyType.MINI_DRAGON,    minion_count=4,  ability=BossAbility.ROAR,       color=Color(0.90, 0.30, 0.00)},
	BossType.SHADOW_WRAITH:{name="Shadow Wraith",emoji="👻", hp=550,  speed=60, gold=90,  dmg=30, minion=EnemyType.SHADOW,         minion_count=10, ability=BossAbility.TELEPORT,   color=Color(0.10, 0.20, 0.20)},
	BossType.SLIME_KING:   {name="Slime King",   emoji="🟢", hp=800,  speed=25, gold=110, dmg=25, minion=EnemyType.SLIME,          minion_count=12, ability=BossAbility.SPLIT,      color=Color(0.00, 0.90, 0.40)},
	BossType.VAMPIRE_LORD: {name="Vampire Lord", emoji="🧛", hp=750,  speed=50, gold=130, dmg=40, minion=EnemyType.BAT,            minion_count=8,  ability=BossAbility.DRAIN,      color=Color(0.50, 0.05, 0.30)},
	BossType.SPIDER_QUEEN: {name="Spider Queen", emoji="🕷️", hp=650,  speed=45, gold=100, dmg=35, minion=EnemyType.SPIDER,         minion_count=7,  ability=BossAbility.SUMMON,     color=Color(0.20, 0.10, 0.10)},
	BossType.FROST_TITAN:  {name="Frost Titan",  emoji="❄️", hp=1200, speed=20, gold=180, dmg=50, minion=EnemyType.WISP,           minion_count=6,  ability=BossAbility.QUAKE,      color=Color(0.00, 0.50, 0.80)},
	BossType.STONE_GOLEM:  {name="Stone Golem",  emoji="🪨", hp=1400, speed=15, gold=220, dmg=65, minion=EnemyType.GOLEM_SHARD,    minion_count=5,  ability=BossAbility.SHIELD,     color=Color(0.30, 0.20, 0.10)},
}

# ─── Damage Resistances ───────────────────────────────────────────────────────
# resistance[enemy_type][damage_type] — <1.0 resistant, >1.0 weak

var RESISTANCES: Dictionary = {
	EnemyType.SKELETON:      {DamageType.PHYSICAL:0.5, DamageType.MAGIC:1.5, DamageType.EXPLOSIVE:1.3, DamageType.FIRE:1.3, DamageType.DARK:0.7},
	EnemyType.ORC:           {DamageType.PHYSICAL:0.7, DamageType.EXPLOSIVE:1.3, DamageType.ICE:1.2, DamageType.FIRE:1.2},
	EnemyType.DEMON:         {DamageType.ICE:1.5, DamageType.POISON:0.5, DamageType.MAGIC:0.8, DamageType.FIRE:0.3, DamageType.DARK:0.5},
	EnemyType.DRAGON:        {DamageType.PHYSICAL:0.6, DamageType.ICE:1.4, DamageType.MAGIC:1.2, DamageType.FIRE:0.4, DamageType.DARK:1.3},
	EnemyType.SHADOW:        {DamageType.PHYSICAL:0.3, DamageType.MAGIC:1.5, DamageType.ELECTRIC:1.3, DamageType.FIRE:1.4, DamageType.DARK:0.2},
	EnemyType.WISP:          {DamageType.PHYSICAL:0.6, DamageType.ICE:1.4, DamageType.ELECTRIC:0.7, DamageType.DARK:1.5},
	EnemyType.ARMORED_GOLEM: {DamageType.PHYSICAL:0.3, DamageType.EXPLOSIVE:1.5, DamageType.MAGIC:1.4, DamageType.ELECTRIC:1.2, DamageType.FIRE:1.1, DamageType.DARK:1.3},
	EnemyType.FAST_SKELETON: {DamageType.PHYSICAL:0.6, DamageType.MAGIC:1.4, DamageType.EXPLOSIVE:1.2, DamageType.FIRE:1.3, DamageType.DARK:0.7},
	EnemyType.GOLEM_SHARD:   {DamageType.PHYSICAL:0.5, DamageType.EXPLOSIVE:1.5, DamageType.MAGIC:1.3, DamageType.FIRE:0.8},
	EnemyType.BERSERKER:     {DamageType.ICE:1.3, DamageType.FIRE:0.7, DamageType.DARK:1.2, DamageType.PHYSICAL:0.8},
	EnemyType.COMMANDER:     {DamageType.PHYSICAL:0.6, DamageType.MAGIC:1.3, DamageType.ELECTRIC:1.4, DamageType.DARK:1.2},
}

# ─── Power Data ───────────────────────────────────────────────────────────────

var POWERS: Dictionary = {
	PowerType.FIREBALL:  {name="Fireball",  emoji="🔥", cost=40, cooldown=8.0,  color=Color(1.0, 0.3, 0.0), desc="AoE explosion"},
	PowerType.FREEZE:    {name="Freeze",    emoji="❄️", cost=30, cooldown=12.0, color=Color(0.4, 0.8, 1.0), desc="Freeze all enemies"},
	PowerType.HEAL:      {name="Heal",      emoji="💚", cost=25, cooldown=15.0, color=Color(0.2, 0.9, 0.4), desc="Restore base HP"},
	PowerType.LIGHTNING: {name="Lightning", emoji="⚡", cost=50, cooldown=10.0, color=Color(1.0, 0.9, 0.0), desc="Chain lightning"},
}

# ─── Map Data ─────────────────────────────────────────────────────────────────

var MAPS: Dictionary = {
	MapType.CLASSIC:    {name="Classic",    emoji="🌿", bg_color=Color(0.12, 0.22, 0.12), path_color=Color(0.50, 0.38, 0.20)},
	MapType.VALLEY:     {name="Valley",     emoji="🏔️", bg_color=Color(0.15, 0.20, 0.10), path_color=Color(0.45, 0.35, 0.18)},
	MapType.CROSSROADS: {name="Crossroads", emoji="🛤️", bg_color=Color(0.10, 0.18, 0.10), path_color=Color(0.50, 0.40, 0.20)},
	MapType.DESERT:     {name="Desert",     emoji="🏜️", bg_color=Color(0.30, 0.25, 0.10), path_color=Color(0.70, 0.58, 0.30)},
	MapType.SNOW:       {name="Snow",       emoji="❄️", bg_color=Color(0.70, 0.75, 0.80), path_color=Color(0.60, 0.60, 0.65)},
	MapType.LAVA:       {name="Lava",       emoji="🌋", bg_color=Color(0.20, 0.08, 0.04), path_color=Color(0.60, 0.15, 0.05)},
	MapType.ENCHANTED:  {name="Enchanted",  emoji="🔮", bg_color=Color(0.10, 0.05, 0.20), path_color=Color(0.35, 0.20, 0.45)},
	MapType.VOLCANO:    {name="Volcano",    emoji="🌋", bg_color=Color(0.18, 0.05, 0.02), path_color=Color(0.55, 0.12, 0.04)},
}

# ─── Skill Tree ───────────────────────────────────────────────────────────────
# max_level, cost_per_level (diamonds), description, effect_per_level

var SKILLS: Dictionary = {
	"start_gold":    {max=5, cost=3, base_cost=3, step_cost=2, label="Start Gold",      desc="+25g starting gold per level"},
	"base_hp":       {max=5, cost=4, base_cost=4, step_cost=3, label="Base HP",         desc="+20 base HP per level"},
	"player_damage": {max=5, cost=5, base_cost=5, step_cost=3, label="Hero Damage",     desc="+5 hero attack per level"},
	"player_speed":  {max=5, cost=3, base_cost=3, step_cost=2, label="Hero Speed",      desc="+20 hero speed per level"},
	"player_hp":     {max=5, cost=4, base_cost=4, step_cost=3, label="Hero HP",         desc="+25 hero HP per level"},
	"tower_damage":  {max=5, cost=6, base_cost=6, step_cost=4, label="Tower Damage",    desc="+8% tower damage per level"},
	"gold_bonus":    {max=5, cost=5, base_cost=5, step_cost=3, label="Gold Bonus",      desc="+10% gold income per level"},
	"diamond_luck":  {max=3, cost=8, base_cost=8, step_cost=6, label="Diamond Luck",    desc="+2% diamond drop chance per level"},
	"wave_bonus":    {max=5, cost=4, base_cost=4, step_cost=3, label="Wave Bonus",      desc="+15 wave completion gold per level"},
	"attack_range":  {max=4, cost=5, base_cost=5, step_cost=4, label="Hero Range",      desc="+30 hero attack range per level"},
	# Prestige
	"ice_power":     {max=5, cost=6, base_cost=6, step_cost=4, label="Ice Power",       desc="+15% ice slow effect per level"},
	"ability_cd":    {max=5, cost=5, base_cost=5, step_cost=3, label="Ability CD",      desc="-5% tower ability cooldown per level"},
	"sell_bonus":    {max=5, cost=4, base_cost=4, step_cost=2, label="Sell Bonus",      desc="+10% tower sell value per level"},
	"resist_pierce": {max=5, cost=7, base_cost=7, step_cost=5, label="Resist Pierce",   desc="-10% enemy resistance per level"},
	"wave_modifier": {max=3, cost=8, base_cost=8, step_cost=6, label="Wave Modifier",   desc="+1 modifier chance per level"},
	"prestige_gold": {max=5, cost=5, base_cost=5, step_cost=4, label="Prestige Gold",   desc="+50g starting gold in prestige"},
}

# ─── Wave Modifier Descriptions ───────────────────────────────────────────────

var MODIFIER_NAMES: Dictionary = {
	WaveModifier.NONE:       {name="Normal",      emoji="",   color=Color.WHITE},
	WaveModifier.FAST:       {name="Fast",        emoji="💨", color=Color(1.0, 0.8, 0.2)},
	WaveModifier.ARMORED:    {name="Armored",     emoji="🛡️", color=Color(0.6, 0.6, 0.8)},
	WaveModifier.REGEN:      {name="Regenerating",emoji="💚", color=Color(0.2, 0.9, 0.4)},
	WaveModifier.SWARM:      {name="Swarm",       emoji="🐝", color=Color(0.9, 0.7, 0.1)},
	WaveModifier.RICH:       {name="Rich",        emoji="💰", color=Color(1.0, 0.85, 0.0)},
	WaveModifier.INVISIBLE:  {name="Invisible",   emoji="👁️", color=Color(0.5, 0.5, 0.7)},
	WaveModifier.SHIELDED:   {name="Shielded",    emoji="🔵", color=Color(0.3, 0.6, 1.0)},
	WaveModifier.BOSS_RALLY: {name="Boss Rally",  emoji="👑", color=Color(0.9, 0.3, 0.1)},
	WaveModifier.BERSERKER:  {name="Berserker",   emoji="🦾", color=Color(0.9, 0.2, 0.2)},
	WaveModifier.SPLIT:      {name="Split",       emoji="✂️", color=Color(0.8, 0.5, 0.9)},
	WaveModifier.ELITE:      {name="Elite",       emoji="⭐", color=Color(1.0, 0.9, 0.0)},
}

# ─── Helper Functions ─────────────────────────────────────────────────────────

# ─── Color Palettes / Themes ─────────────────────────────────────────────────
# Each palette is a dictionary of named colors (for UI, projectiles, backgrounds, etc)
var COLOR_PALETTES: Dictionary = {
	"Classic": {
		"background": Color(0.12, 0.22, 0.12),
		"ui_panel": Color(0.18, 0.18, 0.22),
		"button": Color(0.30, 0.40, 0.20),
		"button_text": Color(0.95, 0.95, 0.95),
		"accent": Color(0.50, 0.80, 0.30),
		"projectile": Color(0.90, 0.90, 0.30),
		"enemy": Color(0.80, 0.20, 0.20),
		"tower": Color(0.20, 0.40, 0.80),
		"health": Color(0.20, 0.90, 0.40),
		"danger": Color(0.90, 0.20, 0.20),
	},
	"Dark": {
		"background": Color(0.08, 0.10, 0.12),
		"ui_panel": Color(0.12, 0.12, 0.16),
		"button": Color(0.22, 0.22, 0.28),
		"button_text": Color(0.90, 0.90, 0.90),
		"accent": Color(0.60, 0.30, 0.80),
		"projectile": Color(0.80, 0.60, 0.90),
		"enemy": Color(0.60, 0.10, 0.30),
		"tower": Color(0.30, 0.60, 0.90),
		"health": Color(0.20, 0.80, 0.60),
		"danger": Color(0.90, 0.30, 0.40),
	},
	"Pastel": {
		"background": Color(0.95, 0.92, 0.90),
		"ui_panel": Color(0.85, 0.85, 0.92),
		"button": Color(0.80, 0.90, 0.80),
		"button_text": Color(0.30, 0.30, 0.30),
		"accent": Color(0.90, 0.70, 0.80),
		"projectile": Color(0.80, 0.80, 0.95),
		"enemy": Color(0.90, 0.60, 0.60),
		"tower": Color(0.60, 0.80, 0.90),
		"health": Color(0.60, 0.90, 0.70),
		"danger": Color(0.95, 0.60, 0.60),
	},
	# Add more palettes as desired
}

# The currently selected palette name (default to "Classic")
var current_palette: String = "Classic"

# Returns the color for a given key in the current palette
func get_palette_color(key: String) -> Color:
	if COLOR_PALETTES.has(current_palette) and COLOR_PALETTES[current_palette].has(key):
		return COLOR_PALETTES[current_palette][key]
	# fallback: try Classic, then white
	if COLOR_PALETTES["Classic"].has(key):
		return COLOR_PALETTES["Classic"][key]
	return Color(1,1,1)

# Returns a list of available palette names
func get_palette_names() -> Array:
	return COLOR_PALETTES.keys()

# Sets the current palette (if valid)
func set_palette(name: String) -> void:
	if COLOR_PALETTES.has(name):
		current_palette = name


func get_resistance(enemy_type: int, damage_type: int) -> float:
	if RESISTANCES.has(enemy_type) and RESISTANCES[enemy_type].has(damage_type):
		return RESISTANCES[enemy_type][damage_type]
	return 1.0

func get_tower(type: int) -> Dictionary:
	return TOWERS.get(type, TOWERS[TowerType.ARROW])

func get_enemy(type: int) -> Dictionary:
	return ENEMIES.get(type, ENEMIES[EnemyType.GOBLIN])

func get_boss(type: int) -> Dictionary:
	return BOSSES.get(type, BOSSES[BossType.ORC_KING])

func get_power(type: int) -> Dictionary:
	return POWERS.get(type, POWERS[PowerType.FIREBALL])

func get_map(type: int) -> Dictionary:
	return MAPS.get(type, MAPS[MapType.CLASSIC])

func tower_upgrade_cost(_base_cost: int, level: int) -> int:
	return level * 50

func tower_sell_value(base_cost: int, level: int, sell_bonus_pct: float = 0.0) -> int:
	var base_val: int = int(base_cost * 0.6) + (level - 1) * 15
	return int(base_val * (1.0 + sell_bonus_pct))
