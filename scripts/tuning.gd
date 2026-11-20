extends Node
## ============================================================================
## VOID SURVIVORS 3D: THE TUNING BLOCK
## ============================================================================
## Every gameplay number lives here, like CFG at the top of the Android game's
## www/game.js. Change a number, save (Ctrl+S), press F5 to play. That's the loop.
##
## Units: "u" means game units. The steering box is 360 u wide, exactly like the
## Android world, so every Android number (speeds, radii, ranges) carries over
## as-is. One game unit is `unit_m` metres in the 3D world.
##
## In the 3D game, "depth" is how far ahead of your ship something is (in u).
## Enemies appear far ahead and fly toward you; your shots fly away into the depth.
##
## Lines marked [3D] are new for the PC version (the Android game has no depth).
## Everything else is the Android value.
## ============================================================================

var unit_m := 0.05                    # [3D] metres per game unit (360 u = 18 m wide)

# ---------------------------------------------------------------- the play box
var box := {
	width = 360.0,                    # Android worldWidth: the box you steer in
	height = 220.0,                   # [3D] box height (the Android screen height became depth)
	margin = 12.0,                    # the ship stays this far inside the box edges
}

# ---------------------------------------------------------------- rail flight
var rail := {
	speed_mps = 26.0,                 # [3D] how fast you fly along the path (metres/s; only the scenery cares)
	camera_back = 230.0,              # [3D] camera distance behind your ship (u)
	camera_up = 6.0,                  # [3D] camera sits a little above the ship plane (u)
	camera_follow = 0.22,             # [3D] 0 = camera stays put, 1 = camera glued to the ship
	camera_fov = 60.0,                # [3D] vertical field of view (degrees)
	spawn_depth = 900.0,              # [3D] enemies appear this far ahead (u)
	escape_depth = -70.0,             # [3D] things this far behind you are gone (no XP, no bounty)
	approach_mul = 1.4,               # [3D] Android "drifts down" speeds x this = speed toward you
	aim_assist_deg = 5.0,             # [3D] forward guns bend toward an enemy inside this cone (0 = off)
	reticle_depth = 320.0,            # [3D] the aiming reticle floats this far ahead (u)
	shot_range = 1300.0,              # [3D] your bullets vanish past this depth (u)
	shake = 9.0,                      # [3D] camera shake strength when hit (u)
}

# ---------------------------------------------------------------- your ship
var player := {
	hp = 3,                           # hits you can take (VESPER's base hull)
	hit_radius = 4.0,                 # the tiny white dot is your real hitbox (bullet-hell style)
	invuln_time = 1.2,                # seconds of blinking safety after a hit
	mercy_radius = 70.0,              # getting hit erases enemy bullets this close
	fire_interval = 0.16,             # Wing Cannons: seconds between pod shots
	damage = 10.0,                    # Wing Cannons: pod bullet base damage
	bullet_speed = 720.0,
	magnet_radius = 34.0,             # how close (sideways) you must fly to pull in XP gems
	handling = 1100.0,                # how fast (u/s) the ship chases your aim point; ships multiply this
	ram_extra = 6.0,                  # ramming: enemy radius + this touches you
	ram_damage = 60.0,                # ...and the enemy takes this much
	mouse_sensitivity = 1.3,          # [3D] moving the mouse one screen-height moves the aim this many box-heights
	stick_speed = 340.0,              # [3D] keyboard / gamepad: how fast the aim point moves (u/s)
}

# ---------------------------------------------------------------- loadout and cards
var signature_cooldown := 0.8         # a ship's own weapon fires 20% faster than the same weapon picked up later
var rarity_weights := {common = 4, uncommon = 2, rare = 1}
var max_level := 5                    # max level for weapons and most passives (Hull Plating: 3)
var upgrade_choices := 3
var post_level_up_invuln := 0.8       # grace after picking a card
var ult_level := 10                   # level that offers an ultimate (milestone 2)
var slots_stage1 := [2, 2]            # weapon slots, passive slots on stage 1 (+1 each per stage)
var filler_credits := 15              # "Salvage Cache" card when everything is maxed

# ---------------------------------------------------------------- XP gems
var xp := {
	gain_rate = 0.5,                  # fraction of each gem's XP you actually get
	need_base = 6.0,                  # XP for level 2
	need_per_level = 3.0,             # extra XP needed per level
	need_curve = 0.35,                # extra XP that grows with level squared
	pull_speed = 440.0,               # how fast gems fly to you once inside the magnet
	collect_radius = 12.0,            # gem touches you: collected
	burst_speed = [30.0, 110.0],      # gems pop out of a kill this fast (bosses: up to 160)
	drift_damping = 0.02,             # the pop slows to this fraction per second
	rail_speed = 110.0,               # [3D] gems stream toward you along the rail (Android: fall at 55)
	magnet_depth_mul = 3.0,           # [3D] the magnet also reaches this many magnet-radii ahead of you
}

# ---------------------------------------------------------------- the swarm
var spawn := {
	grace_time = 1.5,                 # quiet seconds at the start
	start_interval = 1.6,             # seconds between enemy groups at the start
	min_interval = 0.5,               # ...and once fully ramped up
	ramp_seconds = 320.0,             # how long it takes to reach full intensity
	during_boss_mul = 2.5,            # fewer small enemies while a boss is up
	line_after = 10.0,                # lines of larvae join after this many seconds
}
var waves_stage1 := {single = 3.0, line = 3.0}   # (Lamprey snakes, Flayers, Bloaters join in milestone 2)

var level := {
	length = 480.0,                   # 8:00: the clock stops and the final boss arrives
	mini_bosses = [120.0, 240.0, 360.0],
	warn_time = 3.0,
}

var enemy_hp_growth_per_min := 0.35   # enemies get +35% HP per minute survived
var enemy_bullet_speed := 150.0
var enemy_bullet_speed_max := 1.7     # enemy bullets speed up through the stage, up to 1.7x
var enemy_bullet_radius := 4.0
var boss_hp_mul := 0.5
var bounty_rate := 0.6                # fraction of each kill's bounty you actually collect

var stage_scale := {                  # how much harder each stage after the first gets
	enemy_hp = 0.5, hp_growth = 0.2, boss_hp = 1.0, final_hp = 1.0,
	bullet_speed = 0.07, spawn = 0.1, fire = 0.15, credits = 0.0,
}

var enemies := {
	larva = {
		hp = 20.0, r = 14.0, xp = 1, credits = 1.0,
		speed = [70.0, 100.0],        # Android "drift down" speed; x rail.approach_mul toward you
		line_speed = 80.0,            # speed when flying in a line formation
		first_shot = [0.8, 2.0],      # seconds before its first shot
		fire_every = [1.6, 2.8],      # then one aimed shot every 1.6-2.8 s
		aim_jitter = 0.08,            # radians of sloppiness in its aim
		fire_depth = [90.0, 720.0],   # [3D] it only fires while this far ahead of you
	},
}

# ---------------------------------------------------------------- weapons
# cd = cooldown in seconds, L = weapon level (1-5). All cooldowns are multiplied
# by the cooldown modifier (ship fire rate, Rapid Fire). count = Multishot extras.
var weapons := {
	cannon = {                        # Autocannon: straight shots. VESPER's signature.
		cd = 0.16, cd_fast = 0.13, fast_at = 4,
		dmg = 8.0, dmg_per_lvl = 2.0,
		barrels = [1, 1, 2, 2, 3],    # barrels at L1..L5 (+count, max 5)
		max_barrels = 5, barrel_gap = 8.0, speed = 720.0,
	},
	spread = {                        # Spread Shot: a fan of 2+L+count shots
		cd = 0.62, cd_per_lvl = -0.05,
		dmg = 7.5, dmg_per_lvl = 1.5,
		fan_deg = 16.0, fan_deg_per_lvl = 9.0, speed = 560.0,
	},
	rockets = {                       # Homing Rockets: 1+floor(L/2)+count per salvo
		cd = 1.45, cd_per_lvl = -0.12,
		dmg = 20.0, dmg_per_lvl = 8.0,
		blast = 22.0, blast_per_lvl = 3.0,
		turn = 6.0, max_speed = 460.0, accel = 700.0, life = 3.5,
		launch_side = [120.0, 200.0], launch_back = [20.0, 60.0],
	},
	wing = {                          # Wing Cannons: two escort pods at +-24
		cd_mul_low = 1.3, cd_mul_high = 1.0, high_at = 3,
		dmg_base = 0.4, dmg_per_lvl = 0.15,   # x player.damage
		pod_offset = 24.0,
	},
}

# ---------------------------------------------------------------- passives
var passives := {
	rapid = 0.9,                      # Rapid Fire: weapon cooldowns x0.9 per level
	power = 0.12,                     # Power Core: +12% damage per level
	tractor = 0.3,                    # Tractor Beam: +30% pickup radius per level
	datacore = 0.1,                   # Data Core: +10% XP per level
	velocity = 0.15,                  # Velocity Rounds: +15% projectile speed per level
	velocity_pierce = [0, 0, 0, 1, 1, 2],   # pierce at L0..L5
	area = 0.15,                      # Blast Amplifier: +15% area per level
	bounty = 0.2,                     # Bounty Hunter: +20% credits per level
	multi_count = [0, 1, 1, 2, 2, 3], # Multishot: extra projectiles at L0..L5
	multi_dmg = 0.05,                 # ...and +5% damage at L2 and at L4
	crit = 0.07,                      # Targeting Computer: +7% chance of double damage per level
	repair_base = 52.0, repair_per_lvl = -7.0,   # Nano Repair: 1 hull every 52-7L s
	reactive_r = 60.0, reactive_r_per_lvl = 15.0, reactive_r_l5 = 40.0,
	reactive_dmg = 30.0, reactive_dmg_per_lvl = 20.0, reactive_invuln = 1.5,
}

# ---------------------------------------------------------------- ships
# hull, power (damage x), fire rate (x), pickup (magnet x), handling (x)
var ships := {
	vesper  = {weapon = "cannon",  hp = 3, dmg = 1.00, rate = 1.00, magnet = 1.00, handling = 1.00},
	trident = {weapon = "wing",    hp = 3, dmg = 0.90, rate = 1.15, magnet = 1.00, handling = 1.00},
	hornet  = {weapon = "rockets", hp = 3, dmg = 1.10, rate = 0.95, magnet = 1.00, handling = 1.00},
	bulwark = {weapon = "flak",    hp = 5, dmg = 1.00, rate = 0.90, magnet = 1.00, handling = 0.70},
	halo    = {weapon = "disc",    hp = 3, dmg = 1.00, rate = 1.00, magnet = 1.35, handling = 1.00},
	tide    = {weapon = "wave",    hp = 3, dmg = 0.95, rate = 1.00, magnet = 1.00, handling = 0.95},
	hive    = {weapon = "drone",   hp = 3, dmg = 1.00, rate = 1.00, magnet = 1.20, handling = 0.90},
	lance   = {weapon = "laser",   hp = 2, dmg = 1.25, rate = 1.00, magnet = 1.00, handling = 1.15},
	corona  = {weapon = "orbit",   hp = 4, dmg = 0.95, rate = 1.00, magnet = 1.00, handling = 1.10},
	tempest = {weapon = "chain",   hp = 3, dmg = 1.00, rate = 1.10, magnet = 1.00, handling = 1.00},
	needle  = {weapon = "rail",    hp = 2, dmg = 1.30, rate = 0.95, magnet = 1.00, handling = 1.20},
	pulsar  = {weapon = "nova",    hp = 4, dmg = 1.05, rate = 1.00, magnet = 1.00, handling = 0.85},
}
var ship := "vesper"                  # the ship you fly (the Hangar arrives in milestone 2)


## XP needed to go from `lvl` to `lvl + 1`: round(6 + 3(L-1) + 0.35(L-1)^2)
func xp_need(lvl: int) -> int:
	var l := float(lvl - 1)
	return int(round(xp.need_base + xp.need_per_level * l + xp.need_curve * l * l))
