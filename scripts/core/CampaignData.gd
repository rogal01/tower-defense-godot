extends Node

var LEVELS: Array = []

func _ready() -> void:
	_build_levels()

func get_level(id: int) -> Dictionary:
	for lv in LEVELS:
		if int(lv.get("id", 0)) == id:
			return lv
	return {}

func is_unlocked(id: int) -> bool:
	if id == 1:
		return true
	return SaveManager.is_campaign_beaten(id - 1)

func get_beaten_count() -> int:
	var count := 0
	for lv in LEVELS:
		var level_id := int(lv.get("id", 0))
		if SaveManager.is_campaign_beaten(level_id):
			count += 1
	return count

func get_three_star_count() -> int:
	var count := 0
	for lv in LEVELS:
		var level_id := int(lv.get("id", 0))
		if SaveManager.get_campaign_stars(level_id) >= 3:
			count += 1
	return count

func get_total_levels() -> int:
	return LEVELS.size()

func _build_levels() -> void:
	var T := GameData.TowerType
	var P := GameData.PowerType
	var all_towers: Array = GameData.get_canonical_tower_types()
	var all_powers: Array = GameData.get_canonical_power_types()

	LEVELS = [
		{id=1,  title="The Basics",      description="Place Arrow towers to stop the goblins!", emoji="🏹", target_wave=3,  starting_gold=100, towers=[T.ARROW],                     powers=[],                         upgrades=false, hp=0.6, dmg=0.5, spd=0.8, gold=1.5, spawn=1.0, diamonds=2, hint="Tap a tower button, then tap the field to place it"},
		{id=2,  title="Magic Touch",     description="Magic towers deal more damage but cost more", emoji="🧨", target_wave=4,  starting_gold=120, towers=[T.ARROW, T.MAGIC],           powers=[],                         upgrades=false, hp=0.7, dmg=0.6, spd=0.85, gold=1.3, spawn=1.0, diamonds=2, hint="Mix Arrow and Magic towers for best coverage"},
		{id=3,  title="Heavy Artillery", description="Cannons have splash potential. Use them wisely.", emoji="💣", target_wave=5,  starting_gold=150, towers=[T.ARROW, T.MAGIC, T.CANNON], powers=[],                      upgrades=false, hp=0.8, dmg=0.7, spd=0.9, gold=1.2, spawn=1.0, diamonds=3, hint="Cannons are expensive but powerful"},
		{id=4,  title="Upgrades!",       description="Learn to upgrade your towers and hero", emoji="⬆️", target_wave=5,  starting_gold=100, towers=[T.ARROW, T.MAGIC],           powers=[],                         upgrades=true,  hp=0.9, dmg=0.8, spd=0.9, gold=1.3, spawn=1.0, diamonds=3, hint="Tap a tower to select it, then press Tower Upgrade."},
		{id=5,  title="Boss Battle",     description="Survive the first boss encounter!", emoji="☠️", target_wave=5,  starting_gold=120, towers=[T.ARROW, T.MAGIC, T.CANNON], powers=[],                      upgrades=true,  hp=0.8, dmg=0.7, spd=0.9, gold=1.2, spawn=1.0, diamonds=4, hint="Every 5th wave is a boss wave. Prepare your defenses."},
		{id=6,  title="Toxic Strategy",  description="Poison and Tesla towers join your arsenal", emoji="☠️", target_wave=7,  starting_gold=100, towers=all_towers,                   powers=[],                         upgrades=true,  hp=0.9, dmg=0.8, spd=1.0, gold=1.1, spawn=1.0, diamonds=4, hint="All 6 tower types are now available. Try Ice to slow enemies."},
		{id=7,  title="Power Surge",     description="Learn to use powers in combat", emoji="🔥", target_wave=7,  starting_gold=120, towers=[T.ARROW, T.MAGIC, T.CANNON], powers=[P.FIREBALL, P.FREEZE], upgrades=true,  hp=1.0, dmg=0.9, spd=1.0, gold=1.2, spawn=1.0, diamonds=4, hint="Fireball damages all enemies. Freeze slows them down."},
		{id=8,  title="Full Arsenal",    description="All powers unlocked. Master them all.", emoji="⚡", target_wave=8,  starting_gold=100, towers=all_towers,                   powers=all_powers,                 upgrades=true,  hp=1.0, dmg=1.0, spd=1.0, gold=1.0, spawn=1.0, diamonds=5, hint="Heal repairs your base. Lightning chains between enemies."},
		{id=9,  title="The Horde",       description="Wave after wave of massive enemy numbers", emoji="💀", target_wave=10, starting_gold=80,  towers=all_towers,                   powers=all_powers,                 upgrades=true,  hp=0.8, dmg=0.9, spd=1.0, gold=0.9, spawn=1.5, diamonds=5, hint="Lots of enemies incoming. Build wide coverage."},
		{id=10, title="Tower Budget",    description="Gold is scarce. Spend wisely!", emoji="💰", target_wave=8,  starting_gold=30,  towers=all_towers,                   powers=all_powers,                 upgrades=true,  hp=0.9, dmg=0.9, spd=1.0, gold=0.6, spawn=1.0, diamonds=5, hint="Every coin counts. Upgrade instead of building new."},
		{id=11, title="Speed Demons",    description="Enemies move fast. Freeze is your friend.", emoji="💨", target_wave=8,  starting_gold=100, towers=all_towers,                   powers=all_powers,                 upgrades=true,  hp=0.8, dmg=0.8, spd=1.5, gold=1.1, spawn=1.0, diamonds=6, hint="Use Freeze power when enemies get close to the base."},
		{id=12, title="Iron Wall",       description="Enemies are tough. Bring your best.", emoji="🛡️", target_wave=10, starting_gold=100, towers=all_towers,                   powers=all_powers,                 upgrades=true,  hp=1.5, dmg=1.3, spd=0.9, gold=1.2, spawn=1.0, diamonds=6, hint="Upgrade towers to deal with armored enemies."},
		{id=13, title="Boss Rush",       description="A boss every 3 waves. Survive!", emoji="🐉", target_wave=9,  starting_gold=120, towers=all_towers,                   powers=all_powers,                 upgrades=true,  hp=1.1, dmg=1.0, spd=1.0, gold=1.3, spawn=1.0, boss_interval=3, diamonds=7, hint="Bosses come more frequently. Keep upgrading."},
		{id=14, title="Arrows Only",     description="Only Arrow towers allowed. Pure skill.", emoji="🎯", target_wave=10, starting_gold=150, towers=[T.ARROW],                    powers=all_powers,                 upgrades=true,  hp=0.9, dmg=0.8, spd=1.0, gold=1.3, spawn=1.0, diamonds=7, hint="Upgrade your arrows and use powers to compensate."},
		{id=15, title="Night Raid",      description="Darkness falls. Enemies are stronger at night.", emoji="🌙", target_wave=8,  starting_gold=100, towers=all_towers,                   powers=all_powers,                 upgrades=true,  hp=1.2, dmg=1.1, spd=1.0, gold=1.2, spawn=1.0, diamonds=6, hint="Night increases enemy HP and reduces tower range."},
		{id=16, title="Swarm Tactics",   description="Double enemies, half HP. Overwhelm or be overwhelmed.", emoji="🐜", target_wave=8,  starting_gold=100, towers=all_towers,                   powers=all_powers,                 upgrades=true,  hp=0.5, dmg=0.7, spd=1.0, gold=1.1, spawn=2.0, diamonds=6, hint="Many weak enemies. Splash towers shine."},
		{id=17, title="No Powers",       description="Your powers are sealed. Towers only!", emoji="🔒", target_wave=8,  starting_gold=120, towers=all_towers,                   powers=[],                         upgrades=true,  hp=0.9, dmg=0.9, spd=1.0, gold=1.2, spawn=1.0, diamonds=7, hint="No powers this time. Rely on smart tower placement."},
		{id=18, title="Elite Forces",    description="Elite enemies appear every wave. Be ready.", emoji="👑", target_wave=10, starting_gold=100, towers=all_towers,                   powers=all_powers,                 upgrades=true,  hp=1.1, dmg=1.0, spd=1.0, gold=1.3, spawn=1.0, diamonds=8, hint="Elite enemies have 3x HP and better rewards."},
		{id=19, title="Gauntlet",        description="12 waves of escalating chaos", emoji="🔥", target_wave=12, starting_gold=80,  towers=all_towers,                   powers=all_powers,                 upgrades=true,  hp=1.2, dmg=1.1, spd=1.1, gold=1.0, spawn=1.3, diamonds=9, hint="This is the real test. Manage gold and upgrades carefully."},
		{id=20, title="Final Stand",     description="The ultimate challenge. Can you survive?", emoji="🏆", target_wave=15, starting_gold=80,  towers=all_towers,                   powers=all_powers,                 upgrades=true,  hp=1.4, dmg=1.3, spd=1.1, gold=0.9, spawn=1.2, diamonds=10, hint="Use everything you've learned. Good luck!"},
	]
