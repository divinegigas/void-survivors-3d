class_name Weapons
## Weapon behaviour, one function per weapon. Same rules as the Android game's WEAPONS,
## turned to fire forward into the depth. All numbers come from CFG.weapons.
##
## `g` is the Game. `w` is the weapon's state: {lvl, t, builtin}.

static func update(g: Game, id: String, w: Dictionary, dt: float) -> void:
	match id:
		"cannon": _cannon(g, w, dt)
		"spread": _spread(g, w, dt)
		"rockets": _rockets(g, w, dt)
		"wing": _wing(g, w, dt)


static func _cannon(g: Game, w: Dictionary, dt: float) -> void:
	w.t -= dt
	if w.t > 0.0:
		return
	var c: Dictionary = CFG.weapons.cannon
	var lvl: int = w.lvl
	w.t = g.cd(c.cd_fast if lvl >= c.fast_at else c.cd)
	var n: int = mini(c.max_barrels, c.barrels[lvl - 1] + g.mod.count)
	var dmg: float = c.dmg + c.dmg_per_lvl * lvl
	for i in n:
		var from := g.p.pos + Vector3((i - (n - 1) / 2.0) * c.barrel_gap, 0, 16)
		g.gun_shot(from, g.aim_dir(from), c.speed, dmg, Color("#ffd60a"))


static func _spread(g: Game, w: Dictionary, dt: float) -> void:
	w.t -= dt
	if w.t > 0.0:
		return
	var c: Dictionary = CFG.weapons.spread
	var lvl: int = w.lvl
	w.t = g.cd(c.cd + c.cd_per_lvl * lvl)
	var n: int = 2 + lvl + g.mod.count
	var fan := deg_to_rad(c.fan_deg + c.fan_deg_per_lvl * lvl)
	var from := g.p.pos + Vector3(0, 0, 10)
	var centre := g.aim_dir(from)
	for i in n:
		var a := -fan / 2.0 + fan * (float(i) / (n - 1))
		g.gun_shot(from, centre.rotated(Vector3.UP, -a), c.speed, c.dmg + c.dmg_per_lvl * lvl, Catalog.WEAPONS.spread.color)


static func _rockets(g: Game, w: Dictionary, dt: float) -> void:
	w.t -= dt
	if w.t > 0.0:
		return
	var c: Dictionary = CFG.weapons.rockets
	var lvl: int = w.lvl
	w.t = g.cd(c.cd + c.cd_per_lvl * lvl)
	var n: int = 1 + lvl / 2 + g.mod.count
	for i in n:
		var side := 1.0 if i % 2 else -1.0
		var vel := Vector3(side * randf_range(c.launch_side[0], c.launch_side[1]), randf_range(-30, 30),
			-randf_range(c.launch_back[0], c.launch_back[1]))
		g.add_rocket(g.p.pos + Vector3(side * 10, 0, 0), vel, c.dmg + c.dmg_per_lvl * lvl,
			(c.blast + c.blast_per_lvl * lvl) * g.mod.area)


static func _wing(g: Game, w: Dictionary, dt: float) -> void:
	w.t -= dt
	if w.t > 0.0:
		return
	var c: Dictionary = CFG.weapons.wing
	var lvl: int = w.lvl
	w.t = g.cd(CFG.player.fire_interval * (c.cd_mul_high if lvl >= c.high_at else c.cd_mul_low))
	var dmg: float = CFG.player.damage * (c.dmg_base + c.dmg_per_lvl * lvl)
	for side in [-1.0, 1.0]:
		var from: Vector3 = g.p.pos + Vector3(side * c.pod_offset, 0, 4)
		g.gun_shot(from, Game.FWD, CFG.player.bullet_speed, dmg, Catalog.WEAPONS.wing.color)
