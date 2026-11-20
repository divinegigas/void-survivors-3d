class_name Rail
extends Node3D
## The rail: a long, gently winding loop the ship flies along on its own, plus the
## stage 1 "Hive Fleet" scenery (sky, drifting hive chunks, speed lines).
##
## Everything you fight lives inside `rig`, which rides the rail. So gameplay happens
## in a calm local space (the steering box) while the world streams past.

const SKY := preload("res://art/sky.gdshader")

var curve := Curve3D.new()
var length_m := 1.0
var offset := 0.0                 # how far along the rail we are (metres)
var rig := Node3D.new()           # moves along the rail; the camera and the play box live in here
var _chunks: Array = []           # [{node, off, lat}]
var _lines: MultiMeshInstance3D
var _line_pos: Array = []
var _basis := Basis.IDENTITY


func _ready() -> void:
	name = "Rail"
	_build_curve()
	_build_environment()
	add_child(rig)
	rig.name = "Rig"
	_build_chunks()
	_build_speed_lines()
	_place_rig(true)


func _build_curve() -> void:
	# A big wobbly loop (about 9 km), so a whole 8-minute stage never sees the seam.
	var n := 28
	var pts: Array = []
	for i in n:
		var a := float(i) / n * TAU
		var r := 1400.0 + 160.0 * sin(a * 3.0) + 90.0 * sin(a * 5.0 + 1.0)
		pts.append(Vector3(cos(a) * r, 45.0 * sin(a * 4.0) + 25.0 * sin(a * 7.0), sin(a) * r))
	for i in n + 1:
		var p: Vector3 = pts[i % n]
		var tan: Vector3 = (pts[(i + 1) % n] - pts[(i - 1 + n) % n]) * 0.25
		curve.add_point(p, -tan, tan)
	curve.bake_interval = 2.0
	length_m = curve.get_baked_length()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var mat := ShaderMaterial.new()
	mat.shader = SKY
	sky.sky_material = mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = Color("#2a1d5a")
	env.fog_density = 0.0035
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func frame_at(off: float) -> Transform3D:
	var o := fposmod(off, length_m)
	var p := curve.sample_baked(o, true)
	var ahead := curve.sample_baked(fposmod(o + 6.0, length_m), true)
	return Transform3D(Basis.looking_at(ahead - p, Vector3.UP), p)


func advance(dt: float) -> void:
	offset = fposmod(offset + CFG.rail.speed_mps * dt, length_m)
	_place_rig(false)
	_update_chunks()
	_update_speed_lines(dt)


func _place_rig(snap: bool) -> void:
	var t := frame_at(offset)
	# Smooth the turning so the camera never jitters on the curve.
	_basis = t.basis if snap else _basis.slerp(t.basis, 0.08).orthonormalized()
	rig.transform = Transform3D(_basis, t.origin)


# --- hive chunks: lumpy rocks and pods floating beside the rail, recycled ahead of you
func _build_chunks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var cols := [Color("#3b2560"), Color("#4a2a6a"), Color("#33285e"), Color("#5a2f5e")]
	for i in 70:
		var far := i >= 55
		var size := rng.randf_range(40.0, 90.0) if far else rng.randf_range(1.5, 6.0)
		var node := Models.make_chunk(size, cols[i % cols.size()].darkened(0.25 if far else 0.0), i)
		add_child(node)
		var c := {node = node, off = rng.randf_range(20.0, 700.0), lat = _lateral(rng, far),
			spin = Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3), 0), far = far}
		_chunks.append(c)
		_place_chunk(c)


func _lateral(rng: RandomNumberGenerator, far: bool) -> Vector2:
	# Keep the steering box (about 18 x 11 m) and a wide margin around it clear.
	var a := rng.randf() * TAU
	var r := rng.randf_range(260.0, 480.0) if far else rng.randf_range(40.0, 110.0)
	return Vector2(cos(a) * r, sin(a) * r * 0.7)


func _place_chunk(c: Dictionary) -> void:
	var t := frame_at(c.off)
	c.node.position = t.origin + t.basis.x * c.lat.x + t.basis.y * c.lat.y


func _update_chunks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for c in _chunks:
		var d := wrapf(c.off - offset, -length_m / 2, length_m / 2)
		if d < -40.0:
			c.off = offset + rng.randf_range(500.0, 750.0)
			c.lat = _lateral(rng, c.far)
			_place_chunk(c)
		c.node.rotation += c.spin * 0.016


# --- speed lines: faint streaks rushing past (in rig space, so they follow the camera)
func _build_speed_lines() -> void:
	_lines = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var b := BoxMesh.new()
	b.size = Vector3(0.04, 0.04, 6.0)
	mm.mesh = b
	mm.instance_count = 70
	_lines.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.62, 0.55, 1.0, 0.28)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_lines.material_override = mat
	_lines.custom_aabb = AABB(Vector3(-200, -200, -400), Vector3(400, 400, 600))
	rig.add_child(_lines)
	for i in mm.instance_count:
		_line_pos.append(_new_line_pos(randf_range(-160.0, 20.0)))


func _new_line_pos(z: float) -> Vector3:
	var a := randf() * TAU
	var r := randf_range(11.0, 40.0)
	return Vector3(cos(a) * r, sin(a) * r * 0.75, z)


func _update_speed_lines(dt: float) -> void:
	var mm := _lines.multimesh
	for i in _line_pos.size():
		var p: Vector3 = _line_pos[i]
		p.z += (CFG.rail.speed_mps * 4.0) * dt
		if p.z > 20.0:
			p = _new_line_pos(-160.0)
		_line_pos[i] = p
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
