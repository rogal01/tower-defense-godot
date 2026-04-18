# CampaignData.gd — Mission Specification Registry
# Contains the 20-level master campaign set, synchronized with Kotlin multipliers.
# Truncated from legacy 41-level set to enforce strict parity with the source.
extends Node

var LEVELS: Array = []

func _ready() -> void:
	_build_levels()

func get_level(id: int) -> Dictionary:
	for lv in LEVELS:
		if lv["id"] == id:
			return lv
	return {}

func is_unlocked(id: int) -> bool:
	if id == 1:
		return true
	return SaveManager.is_campaign_beaten(id - 1)

func get_beaten_count() -> int:
	var count := 0
	for lv in LEVELS:
		var level_id: int = int(lv.get("id", 0))
		if SaveManager.is_campaign_beaten(level_id):
			count += 1
	return count

func get_three_star_count() -> int:
	var count := 0
	for lv in LEVELS:
		var level_id: int = int(lv.get("id", 0))
		if SaveManager.get_campaign_stars(level_id) >= 3:
			count += 1
	return count

func get_total_levels() -> int:
	return LEVELS.size()

func _build_levels() -> void:
	var T  := GameData.TowerType
	var P  := GameData.PowerType
	var M  := GameData.MapType
	var AT: Array = GameData.TowerType.values()   # all towers
	var AP: Array = GameData.PowerType.values()   # all powers

	LEVELS = [
		# ── Level 1 ──────────────────────────────────────────────────────────
		{id=1,  title="The Basics",        emoji="🏹", target_wave=3,  starting_gold=100,
		 map=M.CLASSIC,    towers=[T.ARROW],                       powers=[],
		 upgrades=false,   hp=0.6, dmg=0.5, spd=0.8, gold=1.5, spawn=1.0,
		 boss_interval=5,  diamonds=3,  star2=200,  star3=600,
		 hint="Arrow towers only. Learn to place and aim!"},

		# ── Level 2 ──────────────────────────────────────────────────────────
		{id=2,  title="Magic Touch",       emoji="🔮", target_wave=4,  starting_gold=120,
		 map=M.CLASSIC,    towers=[T.ARROW, T.MAGIC],              powers=[],
		 upgrades=false,   hp=0.7, dmg=0.6, spd=0.85, gold=1.3, spawn=1.0,
		 boss_interval=5,  diamonds=3,  star2=300,  star3=900,
		 hint="Magic towers pierce armor — combine with arrows!"},

		# ── Level 3 ──────────────────────────────────────────────────────────
		{id=3,  title="Heavy Artillery",   emoji="💣", target_wave=5,  starting_gold=150,
		 map=M.VALLEY,     towers=[T.ARROW, T.MAGIC, T.CANNON],   powers=[],
		 upgrades=false,   hp=0.8, dmg=0.7, spd=0.9, gold=1.2, spawn=1.0,
		 boss_interval=5,  diamonds=3,  star2=400,  star3=1200,
		 hint="Cannon deals splash damage — great on packed paths!"},

		# ── Level 4 ──────────────────────────────────────────────────────────
		{id=4,  title="Upgrades!",         emoji="⬆️", target_wave=5,  starting_gold=100,
		 map=M.CLASSIC,    towers=[T.ARROW, T.MAGIC],              powers=[],
		 upgrades=true,    hp=0.9, dmg=0.8, spd=0.9, gold=1.3, spawn=1.0,
		 boss_interval=5,  diamonds=3,  star2=500,  star3=1400,
		 hint="Upgrade your towers to level 3 for maximum power!"},

		# ── Level 5 ──────────────────────────────────────────────────────────
		{id=5,  title="Boss Battle",       emoji="🦁", target_wave=5,  starting_gold=120,
		 map=M.VALLEY,     towers=[T.ARROW, T.MAGIC, T.CANNON],   powers=[],
		 upgrades=true,    hp=0.8, dmg=0.7, spd=0.9, gold=1.2, spawn=1.0,
		 boss_interval=5,  diamonds=4,  star2=600,  star3=1600,
		 hint="A boss spawns at wave 5. Concentrate your fire!"},

		# ── Level 6 ──────────────────────────────────────────────────────────
		{id=6,  title="Open Armory",       emoji="⚙️", target_wave=7,  starting_gold=100,
		 map=M.CROSSROADS, towers=AT,                              powers=[],
		 upgrades=true,    hp=0.9, dmg=0.8, spd=1.0, gold=1.1, spawn=1.0,
		 boss_interval=5,  diamonds=4,  star2=700,  star3=2000,
		 hint="All towers unlocked — explore the Crossroads map!"},

		# ── Level 7 ──────────────────────────────────────────────────────────
		{id=7,  title="Power Surge",       emoji="⚡", target_wave=7,  starting_gold=120,
		 map=M.DESERT,     towers=[T.ARROW, T.MAGIC, T.CANNON],   powers=[P.FIREBALL, P.FREEZE],
		 upgrades=true,    hp=1.0, dmg=0.9, spd=1.0, gold=1.2, spawn=1.0,
		 boss_interval=5,  diamonds=4,  star2=700,  star3=2000,
		 hint="Use Fireball and Freeze — they change everything!"},

		# ── Level 8 ──────────────────────────────────────────────────────────
		{id=8,  title="Full Arsenal",      emoji="🛡️", target_wave=8,  starting_gold=100,
		 map=M.SNOW,       towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.0, dmg=1.0, spd=1.0, gold=1.0, spawn=1.0,
		 boss_interval=5,  diamonds=4,  star2=900,  star3=2400,
		 hint="All towers and all powers — no excuses!"},

		# ── Level 9 ──────────────────────────────────────────────────────────
		{id=9,  title="The Horde",         emoji="👹", target_wave=10, starting_gold=80,
		 map=M.CROSSROADS, towers=AT,                              powers=AP,
		 upgrades=true,    hp=0.8, dmg=0.9, spd=1.0, gold=0.9, spawn=1.5,
		 boss_interval=5,  diamonds=5,  star2=1000, star3=3000,
		 hint="50% more enemies — cover every path!"},

		# ── Level 10 ─────────────────────────────────────────────────────────
		{id=10, title="Tower Budget",      emoji="💰", target_wave=8,  starting_gold=30,
		 map=M.CLASSIC,    towers=AT,                              powers=AP,
		 upgrades=true,    hp=0.9, dmg=0.9, spd=1.0, gold=0.6, spawn=1.0,
		 boss_interval=5,  diamonds=5,  star2=800,  star3=2200,
		 hint="Limited gold income — every tower must count!"},

		# ── Level 11 ─────────────────────────────────────────────────────────
		{id=11, title="Speed Demons",      emoji="💨", target_wave=8,  starting_gold=100,
		 map=M.VALLEY,     towers=AT,                              powers=AP,
		 upgrades=true,    hp=0.8, dmg=0.8, spd=1.5, gold=1.1, spawn=1.0,
		 boss_interval=5,  diamonds=5,  star2=800,  star3=2400,
		 hint="Enemies move 50% faster — use Ice towers to slow them!"},

		# ── Level 12 ─────────────────────────────────────────────────────────
		{id=12, title="Iron Wall",         emoji="🧱", target_wave=10, starting_gold=100,
		 map=M.DESERT,     towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.5, dmg=1.3, spd=0.9, gold=1.2, spawn=1.0,
		 boss_interval=5,  diamonds=5,  star2=1000, star3=3000,
		 hint="Tough hard-hitting enemies — upgrade early!"},

		# ── Level 13 ─────────────────────────────────────────────────────────
		{id=13, title="Champions Arise",   emoji="👑", target_wave=10, starting_gold=120,
		 map=M.CROSSROADS, towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.1, dmg=1.0, spd=1.0, gold=1.3, spawn=1.0,
		 boss_interval=3,  diamonds=6,  star2=1200, star3=3500,
		 hint="Bosses spawn every 3 waves — stock up on Fireball!"},

		# ── Level 14 ─────────────────────────────────────────────────────────
		{id=14, title="Arrows Only",       emoji="🏹", target_wave=10, starting_gold=150,
		 map=M.DESERT,     towers=[T.ARROW],                       powers=AP,
		 upgrades=true,    hp=0.9, dmg=0.8, spd=1.0, gold=1.3, spawn=1.0,
		 boss_interval=5,  diamonds=6,  star2=1000, star3=3000,
		 hint="Only Arrow towers — max upgrades are your only hope!"},

		# ── Level 15 ─────────────────────────────────────────────────────────
		{id=15, title="Night Raid",        emoji="🌙", target_wave=8,  starting_gold=100,
		 map=M.CLASSIC,    towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.2, dmg=1.1, spd=1.0, gold=1.2, spawn=1.0,
		 boss_interval=5,  diamonds=5,  star2=900,  star3=2600,
		 hint="Tougher enemies that hit harder in the dark!"},

		# ── Level 16 ─────────────────────────────────────────────────────────
		{id=16, title="Swarm Tactics",     emoji="🐝", target_wave=8,  starting_gold=100,
		 map=M.CROSSROADS, towers=AT,                              powers=AP,
		 upgrades=true,    hp=0.5, dmg=0.7, spd=1.0, gold=1.1, spawn=2.0,
		 boss_interval=5,  diamonds=5,  star2=1200, star3=3500,
		 hint="Twice as many enemies but fragile — splash rules!"},

		# ── Level 17 ─────────────────────────────────────────────────────────
		{id=17, title="Sealed Powers",     emoji="🔒", target_wave=8,  starting_gold=140,
		 map=M.SNOW,       towers=AT,                              powers=[],
		 upgrades=true,    hp=0.9, dmg=0.9, spd=1.0, gold=1.2, spawn=1.0,
		 boss_interval=5,  diamonds=6,  star2=900,  star3=2600,
		 hint="No powers allowed — towers only!"},

		# ── Level 18 ─────────────────────────────────────────────────────────
		{id=18, title="Elite Forces",      emoji="⚔️", target_wave=10, starting_gold=100,
		 map=M.CROSSROADS, towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.1, dmg=1.0, spd=1.0, gold=1.3, spawn=1.0,
		 boss_interval=5,  diamonds=6,  star2=1100, star3=3200,
		 hint="Every enemy is elite — expect a tough fight!"},

		# ── Level 19 ─────────────────────────────────────────────────────────
		{id=19, title="The Crucible",      emoji="🔥", target_wave=12, starting_gold=80,
		 map=M.DESERT,     towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.2, dmg=1.1, spd=1.1, gold=1.0, spawn=1.3,
		 boss_interval=5,  diamonds=6,  star2=1400, star3=4000,
		 hint="Tougher and more numerous — save powers for late waves!"},

		# ── Level 20 ─────────────────────────────────────────────────────────
		{id=20, title="Final Stand",       emoji="🏔️", target_wave=15, starting_gold=80,
		 map=M.SNOW,       towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.4, dmg=1.3, spd=1.1, gold=0.9, spawn=1.2,
		 boss_interval=5,  diamonds=8,  star2=2000, star3=5500,
		 hint="The ultimate early challenge — Snow map, no mercy!"},
	]

	var fog_levels := {
		15: true,
		19: true,
	}
	var double_base_levels := {
		18: true,
	}
	var branching_levels := {
	}
	var mini_boss_intervals := {
	}
	for lv in LEVELS:
		var level_id: int = int(lv.get("id", 0))
		lv["fog"] = bool(lv.get("fog", fog_levels.has(level_id)))
		lv["double_base"] = bool(lv.get("double_base", double_base_levels.has(level_id)))
		lv["branching"] = bool(lv.get("branching", branching_levels.has(level_id)))
		lv["mini_boss_interval"] = int(lv.get("mini_boss_interval", mini_boss_intervals.get(level_id, 0)))
		if not lv.has("dual_base_pattern"):
			lv["dual_base_pattern"] = ""
		if not lv.has("mini_boss_archetypes"):
			lv["mini_boss_archetypes"] = []
