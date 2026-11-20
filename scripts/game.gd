class_name Game
extends Node3D
## VOID SURVIVORS 3D: the game. Owns the run state and runs the rules every frame.
##
## Coordinates: every gameplay position is in game units (u) in the rail's local space:
##   x = right, y = up (the steering box is 360 x 220 u, centred on 0,0),
##   z = depth ahead of your ship (enemies come from +z toward 0; your shots fly to +z).
## to_m() turns that into metres for the 3D nodes.

const FWD := Vector3(0, 0, 1)
const BB := preload("res://art/billboard.gdshader")
const BB_TOP := preload("res://art/billboard_top.gdshader")
const BB_GLOW := preload("res://art/billboard_glow.gdshader")

const LARVA_COLOR := Color("#eaa0ad")
const BLOOD_G := Color("#c4cf1f")    # acid-yellow-green bile (kept away from the gem mint)
const SHIP_COLOR := Color("#3df5ff")
const ROCKET_COLOR := Color("#ff8a3d")


class Player:
	var pos := Vector3.ZERO
	var target := Vector3.ZERO
	var vel := Vector3.ZERO
	var hp := 3
	var max_hp := 3
	var invuln := 0.0
	var magnet := 34.0
	var handling := 1100.0
	var repair_t := 0.0


class Enemy:
	var type := "larva"
	var pos := Vector3.ZERO
	var speed := 0.0
	var hp := 1.0
	var max_hp := 1.0
	var r := 14.0
	var xp := 1
	var credits := 1.0
	var age := 0.0
	var flash := 0.0
	var fire_t := 1.0
	var dead := false
	var color := Color.WHITE
	var blood := Color.WHITE
	var node: Node3D
	var meshes: Array = []
	var flashing := false


class Shot:
	var pos := Vector3.ZERO
	var vel := Vector3.ZERO
	var r := 3.0
	var dmg := 0.0
	var kind := "main"
	var pierce := 0
	var hits := {}
	var life := -1.0
	var color := Color.WHITE
	var dead := false
	var target: Enemy = null
	var retarget := 0.0
	var aoe := 0.0
	var node: Node3D


class EShot:
	var pos := Vector3.ZERO
	var vel := Vector3.ZERO
	var r := 4.0
	var dead := false


class Gem:
	var pos := Vector3.ZERO
	var vel := Vector3.ZERO
	var value := 1
	var dead := false


class Nova:
	var pos := Vector3.ZERO
	var r := 0.0
	var max_r := 0.0
	var dmg := 0.0
	var age := 0.0
	var hit := {}
	var dead := false


# --- run state
var state := "title"          # title | play | levelup | paused | over
var t := 0.0                  # stage clock (s)
var stage := 1
var level := 1
var xp := 0.0
var pending := 0
var kills := 0
var credits := 0.0
var shake := 0.0
var fire_mul := 1.0
var spawn_t := 0.0
var p := Player.new()
var weapons := {}             # id -> {lvl, t, builtin}
var passives := {}            # id -> level
var mod := {}
var choices: Array = []
var choice_level := 0
var enemies: Array = []
var shots: Array = []
var eshots: Array = []
var gems: Array = []
var novas: Array = []
var _sig := false
var _mouse := Vector3.ZERO
var _word_bursts := 0.0

# --- nodes
var U := 0.05
var rail: Rail
var play: Node3D
var camera: Camera3D
var ship: Node3D
var fx: Fx
var ui: GameUI
var eshot_batch: SpriteBatch
var gem_batch: SpriteBatch
var glow_batch: SpriteBatch
var shot_batch: SpriteBatch
var top_batch: SpriteBatch
var _larva_cache: Node3D
var _flash_mat := StandardMaterial3D.new()

# --- dev tools (command line): --autotest=SECONDS, --shot=FILE@SECONDS
var _autotest := 0.0
var _shots_todo: Array = []
var _real_t := 0.0
var _title_shot := ""
var _cards_shot := ""
var _cards_t := 0.0
var _give: Array = []


func _ready() -> void:
	U = CFG.unit_m
	_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_mat.albedo_color = Color(1, 1, 1)
	rail = Rail.new()
	add_child(rail)
	play = Node3D.new()
	play.name = "Play"
	rail.rig.add_child(play)
	camera = Camera3D.new()
	camera.fov = CFG.rail.camera_fov
	camera.near = 0.1
	camera.far = 4000.0
	rail.rig.add_child(camera)
	camera.current = true
	ship = Models.make_ship(SHIP_COLOR)
	play.add_child(ship)
	fx = Fx.new()
	play.add_child(fx)
	shot_batch = SpriteBatch.new().setup(BB, 2500)
	glow_batch = SpriteBatch.new().setup(BB_GLOW, 400, 1)
	gem_batch = SpriteBatch.new().setup(BB_TOP, 400, 2)
	eshot_batch = SpriteBatch.new().setup(BB_TOP, 1500, 3)
	top_batch = SpriteBatch.new().setup(BB_TOP, 8, 4)
	for b in [shot_batch, glow_batch, gem_batch, eshot_batch, top_batch]:
		play.add_child(b)
	ui = GameUI.new()
	add_child(ui)
	ui.game = self
	ui.card_chosen.connect(choose)
	_parse_args()
	reset_run()
	state = "title"
	ui.show_title()
	if _autotest > 0.0 or not _shots_todo.is_empty():
		start_run()


func _exit_tree() -> void:
	if _larva_cache:
		_larva_cache.free()
	Models.clear_cache()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest="):
			_autotest = float(a.get_slice("=", 1))
		elif a.begins_with("--give="):
			_give = Array(a.get_slice("=", 1).split(","))
		elif a.begins_with("--title-shot="):
			_title_shot = a.get_slice("=", 1)
		elif a.begins_with("--cards-shot="):
			_cards_shot = a.get_slice("=", 1)
		elif a.begins_with("--shot="):
			var v := a.get_slice("=", 1)
			_shots_todo.append([v.get_slice("@", 0), float(v.get_slice("@", 1))])


# ============================================================================
# Run setup
# ============================================================================
func reset_run() -> void:
	for e: Enemy in enemies:
		e.node.queue_free()
	for s: Shot in shots:
		if s.node:
			s.node.queue_free()
	enemies.clear(); shots.clear(); eshots.clear(); gems.clear(); novas.clear()
	fx.clear()
	t = 0.0; level = 1; xp = 0.0; pending = 0; kills = 0; credits = 0.0; shake = 0.0
	stage = 1
	fire_mul = 1.0 + CFG.stage_scale.fire * stage_d()
	spawn_t = CFG.spawn.grace_time
	weapons = {}
	passives = {}
	p = Player.new()
	p.pos = Vector3(0, -40, 0)
	p.target = p.pos
	var sh: Dictionary = CFG.ships[CFG.ship]
	weapons[sh.weapon] = {lvl = 1, t = 0.0, builtin = true}
	for g in _give:      # dev option: start with these weapons/passives (id or id:level)
		var id: String = g.get_slice(":", 0)
		var lv := int(g.get_slice(":", 1)) if g.contains(":") else 1
		if Catalog.WEAPONS.has(id):
			if weapons.has(id):
				weapons[id].lvl = lv
			else:
				weapons[id] = {lvl = lv, t = 0.0, builtin = false}
		elif Catalog.PASSIVES.has(id):
			passives[id] = lv
	recalc_mods()
	p.hp = p.max_hp


func start_run() -> void:
	reset_run()
	state = "play"
	ui.show_play()
	_capture_mouse(true)


func stage_d() -> int:
	return stage - 1


func slot_count() -> Vector2i:
	var s: Array = CFG.slots_stage1
	return Vector2i(s[0] + stage_d(), s[1] + stage_d())


func pl(id: String) -> int:
	return passives.get(id, 0)


## All modifiers in one place (Hangar upgrades arrive in milestone 2, so those are level 0 here).
func recalc_mods() -> void:
	var sh: Dictionary = CFG.ships[CFG.ship]
	var ps: Dictionary = CFG.passives
	mod = {
		dmg = sh.dmg + ps.power * pl("power") + (ps.multi_dmg if pl("multi") >= 2 else 0.0) + (ps.multi_dmg if pl("multi") >= 4 else 0.0),
		cd = (1.0 / sh.rate) * pow(ps.rapid, pl("rapid")),
		area = 1.0 + ps.area * pl("area"),
		count = ps.multi_count[pl("multi")],
		speed = 1.0 + ps.velocity * pl("velocity"),
		pierce = ps.velocity_pierce[pl("velocity")],
		crit = ps.crit * pl("crit"),
		xp = 1.0 + ps.datacore * pl("datacore"),
		credit = 1.0 + ps.bounty * pl("bounty"),
	}
	p.magnet = CFG.player.magnet_radius * (sh.magnet + ps.tractor * pl("tractor"))
	p.max_hp = sh.hp + pl("plating")
	p.handling = CFG.player.handling * sh.handling


## Cooldown helper: the signature weapon fires 20% faster.
func cd(base: float) -> float:
	return base * mod.cd * (CFG.signature_cooldown if _sig else 1.0)


func repair_every() -> float:
	return CFG.passives.repair_base + CFG.passives.repair_per_lvl * pl("repair")


# ============================================================================
# Main loop
# ============================================================================
func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	_real_t += delta
	if _autotest > 0.0:
		_run_autotest()
		return
	if state == "play" or state == "title":
		rail.advance(dt)
	if state == "play":
		if not _shots_todo.is_empty():
			_bot_steer()
		step(dt)
		fx.update(dt)
	render(dt)
	_check_screenshots()


func _input(event: InputEvent) -> void:
	if state == "play" and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rel: Vector2 = event.relative
		var k: float = CFG.box.height / maxf(1.0, get_viewport().get_visible_rect().size.y) * CFG.player.mouse_sensitivity
		_mouse += Vector3(rel.x, -rel.y, 0) * k
	if event.is_action_pressed("pause"):
		if state == "play":
			state = "paused"
			_capture_mouse(false)
			ui.show_pause()
		elif state == "paused":
			resume()
		get_viewport().set_input_as_handled()
	elif state == "title" and (event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed)):
		start_run()
		get_viewport().set_input_as_handled()
	elif state == "over" and event.is_action_pressed("ui_accept"):
		start_run()
		get_viewport().set_input_as_handled()
	elif state == "play" and event is InputEventMouseButton and event.pressed:
		_capture_mouse(true)


func resume() -> void:
	state = "play"
	ui.show_play()
	_capture_mouse(true)


func quit_to_title() -> void:
	reset_run()
	state = "title"
	_capture_mouse(false)
	ui.show_title()


func _capture_mouse(on: bool) -> void:
	if _autotest > 0.0:
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if on else Input.MOUSE_MODE_VISIBLE


func step(dt: float) -> void:
	t += dt
	shake = maxf(0.0, shake - dt)
	_word_bursts = maxf(0.0, _word_bursts - dt)

	# --- steering: the aim point moves, the ship chases it at its handling speed
	var mv := Input.get_vector("move_left", "move_right", "move_down", "move_up")
	p.target += Vector3(mv.x, mv.y, 0) * CFG.player.stick_speed * dt + _mouse
	_mouse = Vector3.ZERO
	var hw: float = CFG.box.width / 2.0 - CFG.box.margin
	var hh: float = CFG.box.height / 2.0 - CFG.box.margin
	p.target.x = clampf(p.target.x, -hw, hw)
	p.target.y = clampf(p.target.y, -hh, hh)
	var before := p.pos
	var d := p.target - p.pos
	var stp := p.handling * dt
	p.pos = p.target if d.length() <= stp else p.pos + d.normalized() * stp
	p.vel = (p.pos - before) / dt
	p.invuln = maxf(0.0, p.invuln - dt)

	# --- passive timers
	if passives.has("repair"):
		p.repair_t -= dt
		if p.repair_t <= 0.0:
			p.repair_t = repair_every()
			if p.hp < p.max_hp:
				p.hp += 1
				ui.float_text("+1 HULL", Catalog.XP_GREEN)

	# --- weapons (the signature weapon gets the signature cooldown bonus)
	for id in weapons:
		_sig = weapons[id].builtin
		Weapons.update(self, id, weapons[id], dt)
	_sig = false

	# --- the swarm
	spawn_t -= dt
	if spawn_t <= 0.0:
		var k := clampf(t / CFG.spawn.ramp_seconds, 0.0, 1.0)
		spawn_t = lerpf(CFG.spawn.start_interval, CFG.spawn.min_interval, k) * randf_range(0.7, 1.3) \
			* (1.0 - CFG.stage_scale.spawn * stage_d())
		spawn_pattern()

	_update_shots(dt)
	for e: Enemy in enemies:
		if not e.dead:
			_update_enemy(e, dt)
	_update_novas(dt)
	_update_eshots(dt)
	_update_gems(dt)

	# --- tidy up
	for e: Enemy in enemies:
		if e.dead:
			e.node.queue_free()
	enemies = enemies.filter(func(e): return not e.dead)
	for s: Shot in shots:
		if s.dead and s.node:
			s.node.queue_free()
	shots = shots.filter(func(s): return not s.dead)
	eshots = eshots.filter(func(b): return not b.dead)
	gems = gems.filter(func(o): return not o.dead)
	novas = novas.filter(func(n): return not n.dead)

	# --- level up?
	if state == "play":
		while xp >= CFG.xp_need(level):
			xp -= CFG.xp_need(level)
			level += 1
			pending += 1
		if pending > 0:
			open_level_up()


# ============================================================================
# Shooting
# ============================================================================
## Aim assist: bend a forward shot toward the enemy closest to straight ahead, if one is
## inside the assist cone. Returns a unit direction.
func aim_dir(from: Vector3) -> Vector3:
	var e := aim_target(from)
	return (e.pos - from).normalized() if e else FWD


func aim_target(from: Vector3) -> Enemy:
	if CFG.rail.aim_assist_deg <= 0.0:
		return null
	var best: Enemy = null
	var best_cos := cos(deg_to_rad(CFG.rail.aim_assist_deg))
	for e: Enemy in enemies:
		if e.dead or e.pos.z < from.z + 20.0:
			continue
		var c := (e.pos - from).normalized().dot(FWD)
		if c > best_cos:
			best_cos = c
			best = e
	return best


func gun_shot(from: Vector3, dir: Vector3, speed: float, dmg: float, col: Color, r := 3.0) -> void:
	var s := Shot.new()
	s.pos = from
	s.vel = dir * speed * mod.speed
	s.dmg = dmg
	s.color = col
	s.r = r
	s.pierce = mod.pierce
	shots.append(s)


func add_rocket(from: Vector3, vel: Vector3, dmg: float, aoe: float) -> void:
	var s := Shot.new()
	s.kind = "rocket"
	s.pos = from
	s.vel = vel
	s.dmg = dmg
	s.aoe = aoe
	s.r = 4.0
	s.life = CFG.weapons.rockets.life
	s.color = ROCKET_COLOR
	var n := Node3D.new()
	Models.part(n, Models.cyl(0.05, 0.1, 0.5, 8), Models.toon(ROCKET_COLOR, 0.025), Vector3.ZERO, Vector3(-90, 0, 0))
	Models.part(n, Models.cyl(0.07, 0.0, 0.25, 8), Models.toon(Color("#ffd60a"), 0.0, false, {glow = 1.0}), Vector3(0, 0, 0.35), Vector3(90, 0, 0))
	play.add_child(n)
	s.node = n
	shots.append(s)


func _update_shots(dt: float) -> void:
	var c: Dictionary = CFG.weapons.rockets
	for s: Shot in shots:
		if s.dead:
			continue
		if s.life >= 0.0:
			s.life -= dt
			if s.life <= 0.0:
				s.dead = true
				continue
		if s.kind == "rocket":
			s.retarget -= dt
			if s.retarget <= 0.0 and (s.target == null or s.target.dead):
				s.retarget = 0.15
				s.target = nearest_enemy(s.pos, 2000.0)
			var dir: Vector3 = s.vel.normalized()
			var want: Vector3 = (s.target.pos - s.pos).normalized() if s.target and not s.target.dead else FWD
			var ang := dir.angle_to(want)
			if ang > 0.0001:
				dir = dir.slerp(want, minf(1.0, c.turn * dt / ang))
			var sp := minf(c.max_speed * mod.speed, s.vel.length() + c.accel * dt)
			s.vel = dir * sp
			if randf() < 0.6:
				fx.sparks(s.pos, ROCKET_COLOR, 1, 15.0)
		var prev: Vector3 = s.pos
		s.pos += s.vel * dt
		if s.pos.z > CFG.rail.shot_range or s.pos.z < -100.0 or absf(s.pos.x) > 400.0 or absf(s.pos.y) > 300.0:
			s.dead = true
			continue
		for e: Enemy in enemies:
			if e.dead:
				continue
			var rr: float = s.r + e.r
			if _seg_dist2(prev, s.pos, e.pos) > rr * rr:
				continue
			if s.hits.has(e):
				continue
			if s.kind == "rocket":
				explode(s.pos, s.aoe, s.dmg)
				s.dead = true
				break
			hit_enemy(e, s.dmg, false)
			if s.pierce > 0:
				s.pierce -= 1
				s.hits[e] = true
			else:
				s.dead = true
				break


func nearest_enemy(from: Vector3, max_dist: float) -> Enemy:
	var best: Enemy = null
	var bd := max_dist * max_dist
	for e: Enemy in enemies:
		if e.dead:
			continue
		var d := from.distance_squared_to(e.pos)
		if d < bd:
			bd = d
			best = e
	return best


func explode(at: Vector3, radius: float, dmg: float) -> void:
	for e: Enemy in enemies:
		if not e.dead and at.distance_to(e.pos) < radius + e.r:
			hit_enemy(e, dmg, true)
	fx.sparks(at, Color("#ff8c1a"), 8, 140.0)
	fx.burst(at, radius * 0.9, "", Color("#ff8c1a"))
	fx.wave(at, radius, ROCKET_COLOR, 0.3)


# ============================================================================
# Enemies
# ============================================================================
func spawn_pattern() -> void:
	var wv: Dictionary = CFG.waves_stage1
	var options := [["single", wv.single], ["line", wv.line if t > CFG.spawn.line_after else 0.0]]
	var total := 0.0
	for o in options:
		total += o[1]
	var r := randf() * total
	var pick := "single"
	for o in options:
		r -= o[1]
		if r <= 0.0:
			pick = o[0]
			break
	var L: Dictionary = CFG.enemies.larva
	var hw: float = CFG.box.width / 2.0 - 30.0
	var hh: float = CFG.box.height / 2.0 - 20.0
	var depth: float = CFG.rail.spawn_depth
	match pick:
		"single":
			spawn_enemy("larva", Vector3(randf_range(-hw, hw), randf_range(-hh, hh), depth), randf_range(L.speed[0], L.speed[1]))
		"line":
			# a V of 3-5 larvae across the box (the Android "line", turned into depth)
			var n := randi_range(3, 5)
			var gap := (hw * 2.0) / (n - 1)
			var y := randf_range(-hh, hh)
			for i in n:
				spawn_enemy("larva", Vector3(-hw + i * gap, y, depth + absf(i - (n - 1) / 2.0) * 18.0), L.line_speed)


func spawn_enemy(type: String, pos: Vector3, speed: float) -> Enemy:
	var d: Dictionary = CFG.enemies[type]
	var sc: Dictionary = CFG.stage_scale
	var k := stage_d()
	var e := Enemy.new()
	e.type = type
	e.pos = pos
	e.speed = speed * CFG.rail.approach_mul
	e.hp = d.hp * (1.0 + CFG.enemy_hp_growth_per_min * (1.0 + sc.hp_growth * k) * t / 60.0) * (1.0 + sc.enemy_hp * k)
	e.max_hp = e.hp
	e.r = d.r
	e.xp = d.xp
	e.credits = d.credits * (1.0 + sc.credits * k)
	e.fire_t = randf_range(d.first_shot[0], d.first_shot[1])
	e.color = LARVA_COLOR
	e.blood = BLOOD_G
	e.node = _make_larva()
	play.add_child(e.node)
	e.node.position = to_m(e.pos)
	e.age = randf() * 3.0
	_collect_meshes(e.node, e.meshes)
	enemies.append(e)
	return e


func _make_larva() -> Node3D:
	if _larva_cache == null:
		_larva_cache = Models.make_larva(CFG.enemies.larva.r * U, LARVA_COLOR)
	return _larva_cache.duplicate()


func _collect_meshes(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		_collect_meshes(c, out)


func _update_enemy(e: Enemy, dt: float) -> void:
	e.age += dt
	e.flash = maxf(0.0, e.flash - dt)
	match e.type:
		"larva":
			var L: Dictionary = CFG.enemies.larva
			e.pos.z -= e.speed * dt
			e.fire_t -= dt * fire_mul
			if e.fire_t <= 0.0 and e.pos.z > L.fire_depth[0] and e.pos.z < L.fire_depth[1]:
				e.fire_t = randf_range(L.fire_every[0], L.fire_every[1])
				var from := e.pos + Vector3(0, 0, -e.r * 0.9)
				enemy_shot(from, _jitter((p.pos - from).normalized(), L.aim_jitter))
	if e.pos.z < CFG.rail.escape_depth:
		e.dead = true       # escaped: no XP, no bounty
		return
	# Ramming the player hurts both of you.
	if e.pos.distance_to(p.pos) < e.r + CFG.player.ram_extra:
		if damage_player():
			hit_enemy(e, CFG.player.ram_damage, false)


func _jitter(dir: Vector3, amt: float) -> Vector3:
	var right := dir.cross(Vector3.UP).normalized()
	if right.length_squared() < 0.5:
		right = Vector3.RIGHT
	var up := right.cross(dir).normalized()
	return (dir + right * randf_range(-amt, amt) + up * randf_range(-amt, amt)).normalized()


func enemy_shot(from: Vector3, dir: Vector3, speed_mul := 1.0) -> void:
	var sp: float = CFG.enemy_bullet_speed * minf(CFG.enemy_bullet_speed_max, 1.0 + t / CFG.level.length) \
		* (1.0 + CFG.stage_scale.bullet_speed * stage_d()) * speed_mul
	var b := EShot.new()
	b.pos = from
	b.vel = dir * sp
	b.r = CFG.enemy_bullet_radius
	eshots.append(b)


func hit_enemy(e: Enemy, dmg: float, quiet: bool) -> void:
	if e.dead:
		return
	var d: float = dmg * mod.dmg
	if mod.crit > 0.0 and randf() < mod.crit:
		d *= 2.0
		if not quiet:
			fx.sparks(e.pos, Color("#ffe45d"), 3)
	e.hp -= d
	e.flash = 0.06
	if not quiet:
		fx.sparks(e.pos + Vector3(0, 0, -e.r * 0.5), e.color, 2)
	if e.hp <= 0.0:
		kill_enemy(e)


func kill_enemy(e: Enemy) -> void:
	e.dead = true
	kills += 1
	# comic kill: mostly a splash of ichor, sometimes a word (half of them wet)
	var wet := randf() < 0.5
	if randf() < 0.18 and _word_bursts < 3.0:
		_word_bursts += 0.75
		fx.burst(e.pos, 30.0, fx.random_word(wet, false), e.blood if wet else Catalog.GOLD)
	else:
		fx.burst(e.pos, e.r * 1.4, "", e.blood)
	fx.sparks(e.pos, e.blood, 9, 170.0)
	fx.sparks(e.pos, e.color, 14)
	fx.sparks(e.pos, Color.WHITE, 5)
	# bounty
	credits += e.credits * mod.credit * CFG.bounty_rate
	# XP: big gems worth 5 for chunky enemies, the rest as 1s
	var v := e.xp
	var bs: Array = CFG.xp.burst_speed
	while v > 0:
		var val := 5 if v >= 5 else 1
		v -= val
		var o := Gem.new()
		o.pos = e.pos
		var a := randf() * TAU
		var sp := randf_range(bs[0], bs[1])
		o.vel = Vector3(cos(a) * sp, sin(a) * sp, 30.0)
		o.value = val
		gems.append(o)


# ============================================================================
# You
# ============================================================================
func damage_player() -> bool:
	if p.invuln > 0.0 or state != "play":
		return false
	p.hp -= 1
	var ps: Dictionary = CFG.passives
	p.invuln = CFG.player.invuln_time * (ps.reactive_invuln if pl("reactive") >= 3 else 1.0)
	if pl("reactive") > 0:
		var l := pl("reactive")
		var n := Nova.new()
		n.pos = p.pos
		n.max_r = ps.reactive_r + ps.reactive_r_per_lvl * l + (ps.reactive_r_l5 if l >= 5 else 0.0)
		n.dmg = ps.reactive_dmg + ps.reactive_dmg_per_lvl * l
		novas.append(n)
		fx.wave(n.pos, n.max_r, Catalog.PASSIVES.reactive.color, 0.55)
	shake = 0.4
	fx.sparks(p.pos, SHIP_COLOR, 20)
	fx.burst(p.pos + Vector3(0, 26, 0), 30.0, ["OOF!", "WHAM!", "ARGH!"].pick_random(), Catalog.RED)
	ui.hurt()
	clear_bullets_near(p.pos, CFG.player.mercy_radius)      # mercy
	if p.hp <= 0:
		game_over()
	return true


func clear_bullets_near(at: Vector3, r: float) -> void:
	for b: EShot in eshots:
		if b.pos.distance_squared_to(at) < r * r:
			b.dead = true


func game_over() -> void:
	state = "over"
	_capture_mouse(false)
	ui.show_over()


func _update_novas(dt: float) -> void:
	for n: Nova in novas:
		n.age += dt
		n.r = n.max_r * minf(1.0, n.age / 0.35)
		for e: Enemy in enemies:
			if e.dead or n.hit.has(e):
				continue
			if e.pos.distance_to(n.pos) < n.r + e.r:
				n.hit[e] = true
				hit_enemy(e, n.dmg, false)
		clear_bullets_near(n.pos, n.r)
		if n.age > 0.55:
			n.dead = true


func _update_eshots(dt: float) -> void:
	var hr: float = CFG.player.hit_radius
	for b: EShot in eshots:
		if b.dead:
			continue
		var prev := b.pos
		b.pos += b.vel * dt
		if b.pos.z < CFG.rail.escape_depth or b.pos.z > 1500.0 or absf(b.pos.x) > 300.0 or absf(b.pos.y) > 240.0:
			b.dead = true
			continue
		var rr := hr + b.r * 0.6
		if p.invuln <= 0.0 and _seg_dist2(prev, b.pos, p.pos) < rr * rr:
			b.dead = true
			damage_player()


func _update_gems(dt: float) -> void:
	var X: Dictionary = CFG.xp
	for o: Gem in gems:
		var flat := Vector2(p.pos.x - o.pos.x, p.pos.y - o.pos.y).length()
		var ahead := o.pos.z - p.pos.z
		if flat < p.magnet and ahead < p.magnet * X.magnet_depth_mul and ahead > -30.0:
			var to := p.pos - o.pos
			var d := to.length()
			if d > 0.001:
				o.pos += to / d * minf(X.pull_speed * dt, d)
		else:
			o.vel *= pow(X.drift_damping, dt)
			o.pos += o.vel * dt
			o.pos.z -= X.rail_speed * dt
		if o.pos.distance_to(p.pos) < X.collect_radius:
			o.dead = true
			xp += o.value * mod.xp * X.gain_rate
			fx.sparks(o.pos, Catalog.MINT, 2)
		elif o.pos.z < CFG.rail.escape_depth:
			o.dead = true      # missed gems are lost


## Squared distance from point c to the segment a-b (so fast things can't skip past each other).
static func _seg_dist2(a: Vector3, b: Vector3, c: Vector3) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 1e-9:
		return a.distance_squared_to(c)
	var k := clampf((c - a).dot(ab) / l2, 0.0, 1.0)
	return (a + ab * k).distance_squared_to(c)


# ============================================================================
# Level-up cards (same rules as the Android buildChoices)
# ============================================================================
func slot_weapons() -> Array:
	return weapons.keys().filter(func(id): return not weapons[id].builtin)


func _tier_of(id: String) -> String:
	return Catalog.info(id).tier


func _pick_weighted(arr: Array) -> Dictionary:
	var wts: Array = arr.map(func(c): return float(CFG.rarity_weights[_tier_of(c.id)]))
	var total := 0.0
	for w in wts:
		total += w
	var r := randf() * total
	for i in arr.size():
		r -= wts[i]
		if r <= 0.0:
			var c: Dictionary = arr[i]
			arr.remove_at(i)
			return c
	return arr.pop_back()


func build_choices() -> Array:
	var ups: Array = []
	var new_w: Array = []
	var new_p: Array = []
	for id in weapons:
		if weapons[id].lvl < CFG.max_level:
			ups.append({kind = "wup", id = id})
	for id in passives:
		if passives[id] < Catalog.passive_max(id):
			ups.append({kind = "pup", id = id})
	var slots := slot_count()
	if slot_weapons().size() < slots.x:
		for id in Catalog.WEAPONS:
			if not weapons.has(id):
				new_w.append({kind = "wnew", id = id})
	if passives.size() < slots.y:
		for id in Catalog.PASSIVES:
			if not passives.has(id):
				new_p.append({kind = "pnew", id = id})
	var out: Array = []
	for i in CFG.upgrade_choices:
		var has_new := new_w.size() + new_p.size() > 0
		if ups.is_empty() and not has_new:
			break
		var want_new := has_new and (ups.is_empty() or randf() < 0.5)
		if want_new:
			var src: Array = (new_w if randf() < 0.5 else new_p) if (new_w.size() and new_p.size()) else (new_w if new_w.size() else new_p)
			out.append(_pick_weighted(src))
		else:
			out.append(ups.pop_at(randi() % ups.size()))
	# Everything maxed and the slots full: fillers.
	if out.size() < CFG.upgrade_choices:
		out.append({kind = "fill", id = "cache"})
	if out.size() < CFG.upgrade_choices and p.hp < p.max_hp:
		out.append({kind = "fill", id = "repair"})
	return out


func open_level_up() -> void:
	state = "levelup"
	choice_level = level - pending + 1
	choices = build_choices()
	_capture_mouse(false)
	ui.show_cards(choices)


func choose(i: int) -> void:
	if state != "levelup" or i < 0 or i >= choices.size():
		return
	var c: Dictionary = choices[i]
	match c.kind:
		"wnew": weapons[c.id] = {lvl = 1, t = 0.0, builtin = false}
		"wup": weapons[c.id].lvl += 1
		"pnew": passives[c.id] = 1
		"pup": passives[c.id] += 1
		"fill":
			if c.id == "repair":
				p.hp = mini(p.max_hp, p.hp + 1)
			else:
				credits += CFG.filler_credits
	var before := p.max_hp
	recalc_mods()
	if p.max_hp > before:
		p.hp += p.max_hp - before       # Hull Plating repairs too
	if c.id == "repair" and c.kind == "pnew":
		p.repair_t = repair_every()
	pending -= 1
	if pending > 0:
		open_level_up()
	else:
		state = "play"
		p.invuln = maxf(p.invuln, CFG.post_level_up_invuln)
		ui.show_play()
		_capture_mouse(true)


# ============================================================================
# Drawing (positions -> nodes and sprite batches)
# ============================================================================
func to_m(v: Vector3) -> Vector3:
	return Vector3(v.x, v.y, -v.z) * U


func render(_dt: float) -> void:
	var now := _real_t
	# ship: bank into turns, blink while invulnerable
	ship.position = to_m(p.pos)
	var roll := clampf(-p.vel.x * 0.0011, -0.7, 0.7)
	var pitch := clampf(p.vel.y * 0.0007, -0.4, 0.4)
	ship.rotation.z = lerpf(ship.rotation.z, roll, 0.2)
	ship.rotation.x = lerpf(ship.rotation.x, pitch, 0.2)
	ship.visible = p.invuln <= 0.0 or fmod(now, 0.16) < 0.09 or state != "play"
	var flame := ship.get_node("Flame") as Node3D
	flame.scale = Vector3(1, 1, 1) * (0.85 + 0.3 * sin(now * 40.0))
	# camera: sits behind the box and drifts a little with the ship; shakes when hit
	var f: float = CFG.rail.camera_follow
	var cam := Vector3(p.pos.x * f, p.pos.y * f + CFG.rail.camera_up, -CFG.rail.camera_back)
	if shake > 0.0:
		cam += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * CFG.rail.shake * shake / 0.4
	camera.position = to_m(cam)
	# enemies: pulse, eyes track you, flash when hit
	var ship_world := ship.global_position
	for e: Enemy in enemies:
		e.node.position = to_m(e.pos)
		var segs := e.node.get_node("Segs") as Node3D
		var pulse := sin(e.age * 6.0)
		segs.scale = Vector3(1.0 + pulse * 0.05, 1.0 - pulse * 0.04, 1.0 + pulse * 0.06)
		for eye in e.node.get_node("Eyes").get_children():
			var ep: Vector3 = eye.global_position
			if ep.distance_to(ship_world) > 0.05:
				eye.look_at(ship_world, rail.rig.global_basis.y)
		var fl := e.flash > 0.0
		if fl != e.flashing:
			e.flashing = fl
			for m in e.meshes:
				m.material_overlay = _flash_mat if fl else null
	for s: Shot in shots:
		if s.node:
			s.node.position = to_m(s.pos)
			var dir := to_m(s.vel).normalized()
			if dir.length_squared() > 0.5:
				s.node.basis = Basis.looking_at(dir, Vector3.UP)
	# sprites
	shot_batch.begin()
	for s: Shot in shots:
		if s.kind == "main":
			# a tracer streak: overlapping sprites that taper toward the tail
			var tail: Vector3 = s.vel * 0.005
			for k in 5:
				shot_batch.add(to_m(s.pos - tail * k), 1, s.r * (2.6 - 0.3 * k) * U, s.color)
	shot_batch.finish()
	eshot_batch.begin()
	for b: EShot in eshots:
		eshot_batch.add(to_m(b.pos), 0, b.r * 3.1 * U, Catalog.SHOT_PINK)
	eshot_batch.finish()
	gem_batch.begin()
	glow_batch.begin()
	for o: Gem in gems:
		var sz := (9.0 if o.value >= 5 else 6.5) * U * 1.6
		gem_batch.add(to_m(o.pos), 2, sz, Catalog.MINT)
		glow_batch.add(to_m(o.pos), 4, sz * 3.0, Color(Catalog.MINT, 0.5))
	gem_batch.finish()
	glow_batch.finish()
	# your hitbox and the aiming reticle (red-gold when the assist has locked on)
	top_batch.begin()
	if state == "play" or state == "levelup" or state == "paused":
		var lock := aim_target(p.pos + Vector3(0, 0, 16))
		if lock:
			top_batch.add(to_m(lock.pos), 6, lock.r * 3.2 * U, Color("#ffd60a"))
		else:
			top_batch.add(to_m(p.pos + FWD * CFG.rail.reticle_depth), 6, 34.0 * U, Color("#3df5ff", 0.9))
			top_batch.add(to_m(p.pos + FWD * CFG.rail.reticle_depth * 0.5), 6, 22.0 * U, Color("#ff3fa4", 0.8))
		top_batch.add(to_m(p.pos), 5, CFG.player.hit_radius * 2.2 * U, Color.WHITE)
	top_batch.finish()


# ============================================================================
# Dev tools: a robot pilot for automatic tests and screenshots (not used in normal play)
# ============================================================================
func _bot_steer() -> void:
	# Drift toward the nearest gem; dodge the closest incoming bullet.
	var goal := Vector3(sin(t * 0.7) * 120.0, cos(t * 0.5) * 60.0, 0)
	var best := 1e9
	for o: Gem in gems:
		var d := o.pos.distance_to(p.pos)
		if d < best:
			best = d
			goal = Vector3(o.pos.x, o.pos.y, 0)
	for b: EShot in eshots:
		if b.pos.z > 0.0 and b.pos.z < 140.0 and Vector2(b.pos.x - p.pos.x, b.pos.y - p.pos.y).length() < 30.0:
			goal = p.pos + Vector3(p.pos.x - b.pos.x, p.pos.y - b.pos.y, 0).normalized() * 80.0
			break
	p.target = p.target.lerp(goal, 0.1)


func _run_autotest() -> void:
	var dt := 1.0 / 60.0
	for i in 40:
		if state == "levelup":
			choose(randi() % choices.size())
		elif state == "over":
			print("AUTOTEST died at %.1fs, level %d, kills %d" % [t, level, kills])
			start_run()
		_bot_steer()
		rail.advance(dt)
		step(dt)
		fx.update(dt)
		if t >= _autotest:
			print("AUTOTEST done: t=%.1f level=%d kills=%d hp=%d/%d enemies=%d eshots=%d gems=%d credits=%.1f" %
				[t, level, kills, p.hp, p.max_hp, enemies.size(), eshots.size(), gems.size(), credits])
			print("AUTOTEST loadout: weapons=%s passives=%s" % [str(weapons.keys().map(func(k): return "%s L%d" % [k, weapons[k].lvl])), str(passives)])
			get_tree().quit()
			return
	render(dt)


func _check_screenshots() -> void:
	if _title_shot != "" and _real_t > 2.5:
		_save_shot(_title_shot)
		_title_shot = ""
		get_tree().quit()
		return
	if _shots_todo.is_empty():
		return
	if state == "levelup":
		_cards_t += get_process_delta_time()
		if _cards_t > 0.9:
			_cards_t = 0.0
			if _cards_shot != "":
				_save_shot(_cards_shot)
				_cards_shot = ""
			choose(randi() % choices.size())
		return
	var s: Array = _shots_todo[0]
	if t >= s[1]:
		_save_shot(s[0])
		_shots_todo.pop_front()
		if _shots_todo.is_empty():
			get_tree().quit()


func _save_shot(path: String) -> void:
	get_viewport().get_texture().get_image().save_png(path)
	print("SCREENSHOT ", path, " t=%.1f state=%s level=%d" % [t, state, level])
