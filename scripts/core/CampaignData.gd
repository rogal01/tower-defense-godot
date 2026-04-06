# CampaignData.gd — All 40 campaign level definitions
# Each level: id, title, emoji, target_wave, starting_gold, map,
#             towers (Array, empty=all), powers (Array, empty=none allowed),
#             upgrades (bool), hp/dmg/spd/gold/spawn multipliers,
#             boss_interval, diamonds, star2, star3, hint
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
	for i in range(1, 41):
		if SaveManager.is_campaign_beaten(i):
			count += 1
	return count

func get_three_star_count() -> int:
	var count := 0
	for i in range(1, 41):
		if SaveManager.get_campaign_stars(i) >= 3:
			count += 1
	return count

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
		 map=M.LAVA,       towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.1, dmg=1.0, spd=1.0, gold=1.3, spawn=1.0,
		 boss_interval=3,  diamonds=6,  star2=1200, star3=3500,
		 hint="Bosses spawn every 3 waves — stock up on Fireball!"},

		# ── Level 14 ─────────────────────────────────────────────────────────
		{id=14, title="Arrows Only",       emoji="🏹", target_wave=10, starting_gold=150,
		 map=M.ENCHANTED,  towers=[T.ARROW],                       powers=AP,
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
		 map=M.LAVA,       towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.1, dmg=1.0, spd=1.0, gold=1.3, spawn=1.0,
		 boss_interval=5,  diamonds=6,  star2=1100, star3=3200,
		 hint="Every enemy is elite — expect a tough fight!"},

		# ── Level 19 ─────────────────────────────────────────────────────────
		{id=19, title="The Crucible",      emoji="🔥", target_wave=12, starting_gold=80,
		 map=M.ENCHANTED,  towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.2, dmg=1.1, spd=1.1, gold=1.0, spawn=1.3,
		 boss_interval=5,  diamonds=6,  star2=1400, star3=4000,
		 hint="Tougher and more numerous — save powers for late waves!"},

		# ── Level 20 ─────────────────────────────────────────────────────────
		{id=20, title="Final Stand",       emoji="🏔️", target_wave=15, starting_gold=80,
		 map=M.VOLCANO,    towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.4, dmg=1.3, spd=1.1, gold=0.9, spawn=1.2,
		 boss_interval=5,  diamonds=8,  star2=2000, star3=5500,
		 hint="The ultimate early challenge — Volcano map, no mercy!"},

		# ── Level 21 ─────────────────────────────────────────────────────────
		{id=21, title="Poison Mastery",    emoji="☠️", target_wave=8,  starting_gold=130,
		 map=M.ENCHANTED,  towers=[T.POISON],                      powers=AP,
		 upgrades=true,    hp=0.9, dmg=0.8, spd=1.0, gold=1.3, spawn=1.0,
		 boss_interval=5,  diamonds=5,  star2=900,  star3=2600,
		 hint="Poison only — stack DoT on every enemy!"},

		# ── Level 22 ─────────────────────────────────────────────────────────
		{id=22, title="Chain Reaction",    emoji="⚡", target_wave=8,  starting_gold=150,
		 map=M.LAVA,       towers=[T.TESLA],                       powers=AP,
		 upgrades=true,    hp=0.85, dmg=0.8, spd=1.0, gold=1.2, spawn=1.0,
		 boss_interval=5,  diamonds=5,  star2=900,  star3=2600,
		 hint="Tesla only — chain lightning shreds clustered enemies!"},

		# ── Level 23 ─────────────────────────────────────────────────────────
		{id=23, title="Frozen Fortress",   emoji="❄️", target_wave=10, starting_gold=100,
		 map=M.SNOW,       towers=[T.ICE, T.ARROW, T.CANNON],     powers=[P.FIREBALL, P.FREEZE],
		 upgrades=true,    hp=1.1, dmg=1.0, spd=1.2, gold=1.1, spawn=1.0,
		 boss_interval=5,  diamonds=6,  star2=1100, star3=3200,
		 hint="Freeze everything then shatter it with Cannon splash!"},

		# ── Level 24 ─────────────────────────────────────────────────────────
		{id=24, title="No Upgrades",       emoji="🚫", target_wave=10, starting_gold=120,
		 map=M.DESERT,     towers=AT,                              powers=AP,
		 upgrades=false,   hp=0.9, dmg=0.85, spd=1.0, gold=1.2, spawn=1.0,
		 boss_interval=5,  diamonds=6,  star2=1000, star3=3000,
		 hint="Tower upgrades are locked — quantity over quality!"},

		# ── Level 25 ─────────────────────────────────────────────────────────
		{id=25, title="Desert Siege",      emoji="🏜️", target_wave=12, starting_gold=90,
		 map=M.DESERT,     towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.2, dmg=1.1, spd=1.1, gold=1.0, spawn=1.0,
		 boss_interval=5,  diamonds=6,  star2=1400, star3=4000,
		 hint="Long siege through the desert — manage gold carefully!"},

		# ── Level 26 ─────────────────────────────────────────────────────────
		{id=26, title="Triple Threat",     emoji="👿", target_wave=15, starting_gold=130,
		 map=M.VOLCANO,    towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.2, dmg=1.1, spd=1.0, gold=1.4, spawn=1.0,
		 boss_interval=3,  diamonds=8,  star2=2000, star3=5500,
		 hint="Bosses every 3 waves — Volcano is no place for the weak!"},

		# ── Level 27 ─────────────────────────────────────────────────────────
		{id=27, title="Toxin Tide",        emoji="🧪", target_wave=10, starting_gold=110,
		 map=M.ENCHANTED,  towers=[T.ARROW, T.POISON, T.FLAME],   powers=AP,
		 upgrades=true,    hp=1.3, dmg=1.1, spd=1.0, gold=1.1, spawn=1.0,
		 boss_interval=5,  diamonds=6,  star2=1100, star3=3200,
		 hint="Burn and poison together — stack your DoT effects!"},

		# ── Level 28 ─────────────────────────────────────────────────────────
		{id=28, title="Brittle Bastion",   emoji="💥", target_wave=10, starting_gold=150,
		 map=M.LAVA,       towers=AT,                              powers=AP,
		 upgrades=true,    hp=0.7, dmg=1.5, spd=1.0, gold=1.3, spawn=1.0,
		 boss_interval=5,  diamonds=6,  star2=1200, star3=3500,
		 hint="Enemies deal massive damage — never let one through!"},

		# ── Level 29 ─────────────────────────────────────────────────────────
		{id=29, title="The Marathon",      emoji="🏃", target_wave=20, starting_gold=80,
		 map=M.CROSSROADS, towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.1, dmg=1.1, spd=1.05, gold=1.0, spawn=1.1,
		 boss_interval=5,  diamonds=8,  star2=2500, star3=7000,
		 hint="20 waves — pace yourself and manage your economy!"},

		# ── Level 30 ─────────────────────────────────────────────────────────
		{id=30, title="True Champion",     emoji="🥇", target_wave=20, starting_gold=50,
		 map=M.VOLCANO,    towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.6, dmg=1.5, spd=1.15, gold=0.8, spawn=1.3,
		 boss_interval=5,  diamonds=10, star2=3000, star3=8000,
		 hint="20 waves on Volcano with brutal enemies!"},

		# ── Level 31 ─────────────────────────────────────────────────────────
		{id=31, title="Playing with Fire", emoji="🔥", target_wave=8,  starting_gold=120,
		 map=M.LAVA,       towers=[T.ARROW, T.FLAME],              powers=AP,
		 upgrades=true,    hp=1.0, dmg=0.9, spd=1.0, gold=1.2, spawn=1.0,
		 boss_interval=5,  diamonds=5,  star2=900,  star3=2600,
		 hint="Flame towers burn enemies over time — combine with arrows!"},

		# ── Level 32 ─────────────────────────────────────────────────────────
		{id=32, title="Dark Arts",         emoji="💀", target_wave=8,  starting_gold=120,
		 map=M.ENCHANTED,  towers=[T.ARROW, T.MAGIC, T.NECRO],    powers=AP,
		 upgrades=true,    hp=1.1, dmg=0.9, spd=1.0, gold=1.1, spawn=1.0,
		 boss_interval=5,  diamonds=5,  star2=900,  star3=2600,
		 hint="Necro towers curse enemies with death — very powerful!"},

		# ── Level 33 ─────────────────────────────────────────────────────────
		{id=33, title="Siege Warfare",     emoji="🎯", target_wave=10, starting_gold=150,
		 map=M.DESERT,     towers=[T.BALLISTA, T.ARROW],           powers=AP,
		 upgrades=true,    hp=1.2, dmg=1.0, spd=1.0, gold=1.2, spawn=1.0,
		 boss_interval=5,  diamonds=6,  star2=1200, star3=3500,
		 hint="Ballista has extreme range and pierce — pick off bosses!"},

		# ── Level 34 ─────────────────────────────────────────────────────────
		{id=34, title="Event Horizon",     emoji="🌀", target_wave=8,  starting_gold=120,
		 map=M.SNOW,       towers=[T.VORTEX, T.CANNON, T.ICE],    powers=AP,
		 upgrades=true,    hp=1.0, dmg=0.9, spd=1.0, gold=1.2, spawn=1.0,
		 boss_interval=5,  diamonds=5,  star2=900,  star3=2600,
		 hint="Vortex sucks enemies in — pair with Cannon for insane splash!"},

		# ── Level 35 ─────────────────────────────────────────────────────────
		{id=35, title="Fire & Ice",        emoji="🌡️", target_wave=10, starting_gold=100,
		 map=M.SNOW,       towers=[T.FLAME, T.ICE],                powers=[P.FIREBALL, P.FREEZE],
		 upgrades=true,    hp=1.2, dmg=1.1, spd=1.2, gold=1.1, spawn=1.0,
		 boss_interval=5,  diamonds=6,  star2=1100, star3=3200,
		 hint="Freeze with Ice then incinerate with Flame — fast enemies!"},

		# ── Level 36 ─────────────────────────────────────────────────────────
		{id=36, title="Necro Rush",        emoji="💀", target_wave=10, starting_gold=100,
		 map=M.VALLEY,     towers=[T.NECRO, T.POISON, T.ARROW],   powers=AP,
		 upgrades=true,    hp=0.6, dmg=0.7, spd=1.0, gold=1.0, spawn=2.5,
		 boss_interval=5,  diamonds=6,  star2=1800, star3=5000,
		 hint="Massive swarms — Necro's AoE curse handles large groups!"},

		# ── Level 37 ─────────────────────────────────────────────────────────
		{id=37, title="Gravity Well",      emoji="🌀", target_wave=10, starting_gold=130,
		 map=M.ENCHANTED,  towers=[T.VORTEX, T.TESLA],             powers=AP,
		 upgrades=true,    hp=1.1, dmg=1.0, spd=1.0, gold=1.2, spawn=1.0,
		 boss_interval=5,  diamonds=6,  star2=1200, star3=3500,
		 hint="Vortex + Tesla chain = devastating area control!"},

		# ── Level 38 ─────────────────────────────────────────────────────────
		{id=38, title="Dead Eye",          emoji="🎯", target_wave=10, starting_gold=180,
		 map=M.CROSSROADS, towers=[T.BALLISTA, T.ICE],             powers=AP,
		 upgrades=true,    hp=1.0, dmg=1.0, spd=1.0, gold=1.3, spawn=1.0,
		 boss_interval=5,  diamonds=6,  star2=1200, star3=3500,
		 hint="Ballista picks off any enemy — Ice keeps them in range!"},

		# ── Level 39 ─────────────────────────────────────────────────────────
		{id=39, title="Full Armory",       emoji="⚔️", target_wave=15, starting_gold=100,
		 map=M.VOLCANO,    towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.3, dmg=1.2, spd=1.1, gold=1.0, spawn=1.0,
		 boss_interval=5,  diamonds=10, star2=2200, star3=6000,
		 hint="All towers, brutal enemies — the penultimate challenge!"},

		# ── Level 40 ─────────────────────────────────────────────────────────
		{id=40, title="Absolute Zero",     emoji="🔱", target_wave=25, starting_gold=60,
		 map=M.VOLCANO,    towers=AT,                              powers=AP,
		 upgrades=true,    hp=1.8, dmg=1.6, spd=1.2, gold=0.7, spawn=1.4,
		 boss_interval=5,  diamonds=20, star2=5000, star3=12000,
		 hint="The final test. 25 waves. Brutal everything. Good luck."},
	]
