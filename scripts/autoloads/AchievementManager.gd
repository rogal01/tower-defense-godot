# AchievementManager.gd — Autoload singleton: 56 achievements
extends Node

signal achievement_unlocked(achievement: Dictionary)

# Each achievement: id, title, description, emoji
const ACHIEVEMENTS: Array = [
	{id="first_kill",       title="First Blood",      desc="Kill your first enemy",                  emoji="⚔️"},
	{id="wave_5",           title="Survivor",          desc="Reach wave 5",                           emoji="🛡️"},
	{id="wave_10",          title="Veteran",           desc="Reach wave 10",                          emoji="🏅"},
	{id="wave_20",          title="Warlord",           desc="Reach wave 20",                          emoji="🎖️"},
	{id="wave_30",          title="Legend",            desc="Reach wave 30",                          emoji="👑"},
	{id="wave_50",          title="Epic Defender",     desc="Reach wave 50",                          emoji="🏆"},
	{id="wave_100",         title="Centurion",         desc="Reach wave 100",                         emoji="💯"},
	{id="kills_50",         title="Slayer",            desc="Kill 50 enemies",                        emoji="🗡️"},
	{id="kills_200",        title="Destroyer",         desc="Kill 200 enemies",                       emoji="💥"},
	{id="kills_500",        title="Annihilator",       desc="Kill 500 enemies",                       emoji="☠️"},
	{id="kills_1000",       title="Extinction",        desc="Kill 1000 enemies",                      emoji="💀"},
	{id="combo_10",         title="Combo Master",      desc="Get a 10x combo",                        emoji="🔥"},
	{id="combo_20",         title="Chain Reaction",    desc="Get a 20x combo",                        emoji="⚡"},
	{id="combo_30",         title="Unstoppable",       desc="Get a 30x combo",                        emoji="🔥"},
	{id="combo_50",         title="Godlike",           desc="Get a 50x combo",                        emoji="⚡"},
	{id="score_10000",      title="Legendary Score",   desc="Reach 10000 score",                      emoji="🥇"},
	{id="boss_kill",        title="Boss Slayer",       desc="Kill your first boss",                   emoji="🐉"},
	{id="5_bosses",         title="Boss Buster",       desc="Kill 5 bosses in one run",               emoji="👹"},
	{id="10_bosses",        title="Boss Legend",       desc="Kill 10 bosses in one run",              emoji="🐲"},
	{id="5_towers",         title="Builder",           desc="Place 5 towers",                         emoji="🏗️"},
	{id="10_towers",        title="Architect",         desc="Place 10 towers",                        emoji="🏰"},
	{id="all_tower_types",  title="Arsenal",           desc="Use all tower types",                    emoji="⚙️"},
	{id="use_power",        title="Power User",        desc="Use a power for first time",             emoji="✨"},
	{id="all_powers",       title="Elementalist",      desc="Use all 4 powers in one run",            emoji="🌊"},
	{id="max_tower",        title="Maxed Out",         desc="Upgrade a tower to max level",           emoji="🔧"},
	{id="rich",             title="Wealthy",           desc="Accumulate 500 gold",                    emoji="💰"},
	{id="rich_1000",        title="Prosperous",        desc="Accumulate 1000 gold",                   emoji="💎"},
	{id="gold_hoarder",     title="Gold Hoarder",      desc="Have 2000 gold at once",                 emoji="🏦"},
	{id="score_1000",       title="High Scorer",       desc="Reach 1000 score",                       emoji="🎯"},
	{id="score_5000",       title="High Roller",       desc="Reach 5000 score",                       emoji="🏅"},
	{id="score_10000",      title="Legendary Score",   desc="Reach 10000 score",                      emoji="🥇"},
	{id="diamond_10",       title="Diamond Miner",     desc="Earn 10 diamonds in one run",            emoji="💎"},
	{id="diamond_50",       title="Diamond Mine",      desc="Earn 50 diamonds in one run",            emoji="💎"},
	{id="repaired_3",       title="Repairman",         desc="Heal base HP 3 times",                   emoji="🔨"},
	{id="upgrade_all",      title="Upgrade Expert",    desc="Upgrade all placed towers",              emoji="⬆️"},
	{id="endless_10",       title="Endless Warrior",   desc="Reach wave 10 in Endless",              emoji="∞"},
	{id="no_damage",        title="Untouchable",       desc="Complete a wave without base damage",    emoji="🛡️"},
	{id="speed_demon",      title="Speed Demon",       desc="Beat wave 10 on 3x speed",              emoji="💨"},
	{id="survivor_1hp",     title="Last Stand",        desc="Win a wave with base at 1 HP",           emoji="❤️"},
	{id="campaign_5",       title="Campaigner",        desc="Complete 5 campaign levels",             emoji="🗺️"},
	{id="campaign_10",      title="Strategist",        desc="Complete 10 campaign levels",            emoji="🏅"},
	{id="campaign_all",     title="Conqueror",         desc="Complete all campaign levels",           emoji="👑"},
	{id="campaign_no_damage",title="Flawless",         desc="Beat campaign level without base damage",emoji="🛡️"},
	{id="campaign_3star",   title="Perfectionist",     desc="Get 3 stars on 5 campaign levels",      emoji="⭐"},
	{id="trap_first",       title="Trapper",           desc="Place your first trap",                  emoji="🪤"},
	{id="trap_10",          title="Minefield",         desc="Place 10 traps in one run",              emoji="💣"},
	{id="mine_triple",      title="Triple Threat",     desc="Kill 3 enemies with one mine",           emoji="💥"},
	{id="bounty_first",     title="Bounty Hunter",     desc="Complete your first bounty",             emoji="🎯"},
	{id="bounty_all",       title="Bounty King",       desc="Complete all 3 bounties in one run",     emoji="👑"},
	{id="volcano_win",      title="Volcanic Victory",  desc="Reach wave 15 on Volcano map",           emoji="🌋"},
	{id="streak_no_tower",  title="Lone Wolf",         desc="Reach wave 5 with no towers placed",    emoji="🐺"},
	{id="all_maps",         title="Cartographer",      desc="Play on all 8 maps",                     emoji="🌍"},
	{id="boss_rush_5",      title="Gauntlet",          desc="Defeat 5 bosses in Boss Rush",           emoji="🗡️"},
	{id="randomizer_win",   title="Chaos Master",      desc="Reach wave 15 in Randomizer",            emoji="🎲"},
	{id="ability_all",      title="Tactician",         desc="Use abilities on 5 tower types in one run",emoji="✨"},
	{id="prestige_first",   title="Reborn",            desc="Prestige for the first time",            emoji="👑"},
]

# Runtime per-run tracking
var _powers_used_this_run: Dictionary = {}   # PowerType -> bool
var _ability_types_used: Dictionary = {}     # TowerType -> bool
var _kills_this_run: int = 0
var _bosses_killed_this_run: int = 0
var _diamonds_this_run: int = 0

func _ready() -> void:
	pass

# Call from GameManager at run start
func reset_run() -> void:
	_powers_used_this_run.clear()
	_ability_types_used.clear()
	_kills_this_run = 0
	_bosses_killed_this_run = 0
	_diamonds_this_run = 0

# Main unlock function — also fires signal for banner
func check(id: String) -> void:
	if SaveManager.is_achievement_unlocked(id):
		return
	SaveManager.unlock_achievement(id)
	var ach: Dictionary = _find(id)
	if not ach.is_empty():
		achievement_unlocked.emit(ach)

func _find(id: String) -> Dictionary:
	for a in ACHIEVEMENTS:
		if a["id"] == id:
			return a
	return {}

func is_unlocked(id: String) -> bool:
	return SaveManager.is_achievement_unlocked(id)

func get_all() -> Array:
	return ACHIEVEMENTS

# ─── Kill event ───────────────────────────────────────────────────────────────

func on_enemy_killed(enemy_type: int, _tower_type: int, combo: int) -> void:
	_kills_this_run += 1
	var total := SaveManager.get_stat("lifetime_kills") + _kills_this_run

	check("first_kill")
	if _kills_this_run >= 50:   check("kills_50")
	if _kills_this_run >= 200:  check("kills_200")
	if _kills_this_run >= 500:  check("kills_500")
	if total >= 1000:           check("kills_1000")
	if combo >= 10:             check("combo_10")
	if combo >= 20:             check("combo_20")
	if combo >= 30:             check("combo_30")
	if combo >= 50:             check("combo_50")

	if enemy_type == GameData.EnemyType.BOSS:
		_bosses_killed_this_run += 1
		check("boss_kill")
		if _bosses_killed_this_run >= 5:  check("5_bosses")
		if _bosses_killed_this_run >= 10: check("10_bosses")

func on_wave_complete(wave: int, base_hp: float, _max_base_hp: float, base_hp_before: float,
		is_endless: bool, map_type: int, is_randomizer: bool, game_speed: int) -> void:
	if wave >= 5:   check("wave_5")
	if wave >= 10:  check("wave_10")
	if wave >= 20:  check("wave_20")
	if wave >= 30:  check("wave_30")
	if wave >= 50:  check("wave_50")
	if wave >= 100: check("wave_100")
	if base_hp >= base_hp_before:
		check("no_damage")
	if base_hp <= 1.0:
		check("survivor_1hp")
	if game_speed >= 3 and wave >= 10:
		check("speed_demon")
	if is_endless and wave >= 10:
		check("endless_10")
	if map_type == GameData.MapType.VOLCANO and wave >= 15:
		check("volcano_win")
	if is_randomizer and wave >= 15:
		check("randomizer_win")

func on_tower_placed(tower_count: int, tower_types_set: Array) -> void:
	if tower_count >= 5:  check("5_towers")
	if tower_count >= 10: check("10_towers")
	if tower_types_set.size() >= 11:
		check("all_tower_types")

func on_power_used(power_type: int) -> void:
	check("use_power")
	_powers_used_this_run[power_type] = true
	if _powers_used_this_run.size() >= 4:
		check("all_powers")

func on_ability_used(tower_type: int) -> void:
	_ability_types_used[tower_type] = true
	if _ability_types_used.size() >= 5:
		check("ability_all")

func on_tower_maxed() -> void:
	check("max_tower")

func on_all_towers_upgraded(towers_count: int, upgraded_count: int) -> void:
	if towers_count > 0 and towers_count == upgraded_count:
		check("upgrade_all")

func on_gold_checked(gold: int) -> void:
	if gold >= 500:  check("rich")
	if gold >= 1000: check("rich_1000")
	if gold >= 2000: check("gold_hoarder")

func on_score_checked(score: int) -> void:
	if score >= 1000:  check("score_1000")
	if score >= 5000:  check("score_5000")
	if score >= 10000: check("score_10000")

func on_diamonds_earned(count: int) -> void:
	_diamonds_this_run += count
	if _diamonds_this_run >= 10: check("diamond_10")
	if _diamonds_this_run >= 50: check("diamond_50")

func on_base_healed(repairs_this_run: int) -> void:
	if repairs_this_run >= 3: check("repaired_3")

func on_campaign_result(_level_id: int, _stars: int, no_damage: bool,
		beaten_count: int, stars5_count: int, total_levels: int) -> void:
	if beaten_count >= 5:           check("campaign_5")
	if beaten_count >= 10:          check("campaign_10")
	if beaten_count >= total_levels: check("campaign_all")
	if no_damage:                   check("campaign_no_damage")
	if stars5_count >= 5:           check("campaign_3star")

func on_trap_placed(traps_this_run: int) -> void:
	if traps_this_run == 1: check("trap_first")
	if traps_this_run >= 10: check("trap_10")

func on_mine_triple_kill() -> void:
	check("mine_triple")

func on_bounty_complete(total_completed: int) -> void:
	if total_completed >= 1: check("bounty_first")
	if total_completed >= 3: check("bounty_all")

func on_boss_rush(bosses_defeated: int) -> void:
	if bosses_defeated >= 5: check("boss_rush_5")

func on_prestige() -> void:
	check("prestige_first")

func on_maps_played(maps_count: int) -> void:
	if maps_count >= 8: check("all_maps")

func on_wave_5_no_towers() -> void:
	check("streak_no_tower")
