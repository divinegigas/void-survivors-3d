class_name Fx
extends Node3D
## Comic effects inside the play box: sparks and ichor, POW!/SPLAT! starbursts, shockwave spheres.
## Positions are game units (x right, y up, z = depth ahead), like the rest of the game.

const BILLBOARD := preload("res://art/billboard.gdshader")
const STARBURST := preload("res://art/starburst.gdshader")
const NOVA := preload("res://art/nova.gdshader")
const BANGERS := preload("res://fonts/Bangers-Regular.ttf")

const WORDS_SMALL := ["POP!", "ZAP!", "BAM!", "POW!"]
const WORDS_MED := ["BLAM!", "KRAK!", "KA-POW!", "WHAM!"]
const SPLATS_SMALL := ["SPLAT!", "SPLUT!", "GLORP!"]
const SPLATS_MED := ["SPLORCH!", "SQUELCH!", "SPLAT!"]

var U := 0.05
var sparks_batch: SpriteBatch
var _sparks: Array = []        # [pos, vel, life, max_life, size, color]
var _bursts: Array = []        # {root, star_mat, label, age, life, size}
var _waves: Array = []         # {mesh, mat, age, life, max}
var _star_mesh := QuadMesh.new()
var _sphere := SphereMesh.new()


func _ready() -> void:
	U = CFG.unit_m
	sparks_batch = SpriteBatch.new().setup(BILLBOARD, 700)
	add_child(sparks_batch)
	_sphere.radius = 1.0
	_sphere.height = 2.0
	_sphere.radial_segments = 24
	_sphere.rings = 12


static func to_m(p: Vector3, u: float) -> Vector3:
	return Vector3(p.x, p.y, -p.z) * u


func clear() -> void:
	_sparks.clear()
	for b in _bursts:
		b.root.queue_free()
	_bursts.clear()
	for w in _waves:
		w.mesh.queue_free()
	_waves.clear()


func sparks(pos: Vector3, col: Color, n: int, speed := 120.0) -> void:
	for i in n:
		if _sparks.size() > 650:
			return
		var v := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(0.3, 1.0) * speed
		var life := randf_range(0.25, 0.6)
		_sparks.append([pos, v, life, life, randf_range(2.0, 4.5), col])


## A comic starburst, optionally with a word slammed on top. size is in game units.
func burst(pos: Vector3, size: float, word: String, col: Color, word_col := Color("#fff8e7")) -> void:
	if _bursts.size() > 14:
		var old: Dictionary = _bursts.pop_front()
		old.root.queue_free()
	var root := Node3D.new()
	root.position = to_m(pos, U)
	add_child(root)
	var star := MeshInstance3D.new()
	star.mesh = _star_mesh
	var mat := ShaderMaterial.new()
	mat.shader = STARBURST
	mat.set_shader_parameter("color", col)
	mat.set_shader_parameter("points", float(randi_range(9, 13)))
	mat.set_shader_parameter("spin", randf() * TAU)
	mat.render_priority = -1
	star.material_override = mat
	star.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(star)
	var label: Label3D = null
	if word != "":
		label = Label3D.new()
		label.text = word
		label.font = BANGERS
		label.font_size = 96
		label.outline_size = 22
		label.outline_modulate = Color("#14101f")
		label.modulate = word_col
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.render_priority = 0
		label.outline_render_priority = -1
		label.pixel_size = size * U * 0.012
		label.position = Vector3(0, 0, 0.05)
		root.add_child(label)
	_bursts.append({root = root, star = star, mat = mat, label = label, age = 0.0, life = 0.75 if word != "" else 0.3, size = size})


## A visual shockwave (the damage, if any, is handled by the game).
func wave(pos: Vector3, max_r: float, col: Color, life := 0.45) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _sphere
	var mat := ShaderMaterial.new()
	mat.shader = NOVA
	mat.set_shader_parameter("color", col)
	mi.material_override = mat
	mi.position = to_m(pos, U)
	mi.scale = Vector3.ONE * 0.01
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_waves.append({mesh = mi, mat = mat, age = 0.0, life = life, max = max_r})


func update(dt: float) -> void:
	# sparks
	sparks_batch.begin()
	var keep: Array = []
	for s in _sparks:
		s[2] -= dt
		if s[2] <= 0.0:
			continue
		s[1] *= pow(0.08, dt)
		s[0] += s[1] * dt
		var k: float = s[2] / s[3]
		sparks_batch.add(to_m(s[0], U), 3, s[4] * U * (0.4 + 0.6 * k), s[5])
		keep.append(s)
	_sparks = keep
	sparks_batch.finish()
	# bursts: pop in big, settle, then shrink away
	var keep_b: Array = []
	for b in _bursts:
		b.age += dt
		var t: float = b.age / b.life
		if t >= 1.0:
			b.root.queue_free()
			continue
		var pop: float = 1.25 - 0.25 * minf(1.0, b.age / 0.08) if b.age < 0.08 else 1.0
		var shrink := 1.0 if t < 0.6 else 1.0 - (t - 0.6) / 0.4
		var s: float = b.size * U * 2.0 * pop * shrink
		b.star.scale = Vector3.ONE * maxf(0.001, s)
		if b.label:
			b.label.scale = Vector3.ONE * maxf(0.001, pop * shrink)
		keep_b.append(b)
	_bursts = keep_b
	# shockwaves
	var keep_w: Array = []
	for w in _waves:
		w.age += dt
		var t: float = w.age / w.life
		if t >= 1.0:
			w.mesh.queue_free()
			continue
		w.mesh.scale = Vector3.ONE * maxf(0.01, w.max * U * minf(1.0, t / 0.6))
		w.mat.set_shader_parameter("alpha", 1.0 - t)
		keep_w.append(w)
	_waves = keep_w


func random_word(splat: bool, big: bool) -> String:
	if splat:
		return (SPLATS_MED if big else SPLATS_SMALL).pick_random()
	return (WORDS_MED if big else WORDS_SMALL).pick_random()
