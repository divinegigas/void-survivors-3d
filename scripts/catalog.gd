class_name Catalog
## Names, tiers, colours and card text for weapons and passives (the numbers live in tuning.gd).
## Text matches the Android game (www/game.js WEAPONS / PASSIVES).

const INK := Color("#14101f")
const PAPER := Color("#fff8e7")
const GOLD := Color("#ffd60a")
const RED := Color("#ff3b3b")
const MINT := Color("#8dffbf")
const XP_GREEN := Color("#3ddc4a")
const DIM := Color("#9d97c4")
const SHOT_PINK := Color("#ff3fa4")

const TIER := {
	common = {name = "COMMON", color = Color("#3ddc4a")},
	uncommon = {name = "UNCOMMON", color = Color("#a45cff")},
	rare = {name = "RARE", color = Color("#ffd60a")},
	ult = {name = "ULTIMATE", color = Color("#ff3b3b")},
}

## Weapons wired into this build. (All 13 are listed in DESIGN.md; the rest arrive in milestone 2.)
const WEAPONS := {
	cannon = {name = "Autocannon", tier = "common", color = Color("#fff8e7"),
		levels = ["Rapid-fire forward cannon", "More damage", "Twin barrels", "Faster fire", "Triple barrels"]},
	spread = {name = "Spread Shot", tier = "common", color = Color("#ffd23f"),
		levels = ["Fires a fan of 3 shots", "4 shots, wider", "5 shots, more damage", "6 shots, faster", "7 shots, max fan"]},
	rockets = {name = "Homing Rockets", tier = "common", color = Color("#ff8a3d"),
		levels = ["Seeker missiles hunt enemies down", "2 rockets per salvo", "Bigger blasts, faster reload", "3 rockets per salvo", "Heavy warheads"]},
	wing = {name = "Wing Cannons", tier = "common", color = Color("#3df5ff"),
		levels = ["Two escort pods with rapid-fire cannons", "Pods hit harder", "Pods fire faster", "Pods hit even harder", "Pods at full power"]},
}

const PASSIVES := {
	rapid = {name = "Rapid Fire", tier = "common", color = Color("#3df5ff"), levels = ["-10% weapon cooldowns"]},
	power = {name = "Power Core", tier = "common", color = Color("#ff5d5d"), levels = ["+12% damage"]},
	area = {name = "Blast Amplifier", tier = "uncommon", color = Color("#ffb35d"), levels = ["+15% blast radius and weapon size"]},
	multi = {name = "Multishot", tier = "rare", color = Color("#ffd23f"),
		levels = ["+1 projectile for most weapons", "+5% damage", "+2 projectiles", "+5% damage", "+3 projectiles"]},
	velocity = {name = "Velocity Rounds", tier = "uncommon", color = Color("#9dffef"),
		levels = ["+15% projectile speed", "+15% projectile speed", "+15% speed, bullets pierce 1 enemy", "+15% projectile speed", "+15% speed, bullets pierce 2 enemies"]},
	crit = {name = "Targeting Computer", tier = "rare", color = Color("#ffe45d"), levels = ["+7% chance of double damage"]},
	reactive = {name = "Reactive Armor", tier = "uncommon", color = Color("#ff9d5d"),
		levels = ["Getting hit blasts nearby enemies and bullets away", "Bigger blast", "Longer safety blink after a hit", "Bigger, stronger blast", "Massive blast"]},
	plating = {name = "Hull Plating", tier = "common", color = Color("#b9c4ff"), max = 3, levels = ["+1 max hull (and repair 1)"]},
	repair = {name = "Nano Repair", tier = "rare", color = Color("#5dff9e"),
		levels = ["Repair 1 hull every 45s", "Every 38s", "Every 31s", "Every 24s", "Every 17s"]},
	tractor = {name = "Tractor Beam", tier = "common", color = Color("#5dff9e"), levels = ["+30% crystal pickup range"]},
	datacore = {name = "Data Core", tier = "common", color = Color("#c86bff"), levels = ["+10% XP"]},
	bounty = {name = "Bounty Hunter", tier = "uncommon", color = Color("#ffd23f"), levels = ["+20% credits from kills"]},
}


static func info(id: String) -> Dictionary:
	if WEAPONS.has(id):
		return WEAPONS[id]
	return PASSIVES.get(id, {})


## Card text for level `lvl` (0 = the "new" text). Passives with one line repeat it.
static func level_text(id: String, lvl: int) -> String:
	var lv: Array = info(id).levels
	return lv[min(lvl, lv.size() - 1)]


static func passive_max(id: String) -> int:
	return PASSIVES[id].get("max", CFG.max_level)
