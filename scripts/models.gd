class_name Models
## Builds every 3D model in code from simple shapes, with the pop-art toon material
## and ink outlines. No model files: everything is original and generated here.

const TOON := preload("res://art/toon.gdshader")
const OUTLINE := preload("res://art/outline.gdshader")
const INK := Color("#14101f")
const PAPER := Color("#fff8e7")

# Larva palette (from the Android art.js)
const EYE := Color("#c6ff3b")
const BONE := Color("#efe2c4")
const MAW := Color("#1d0812")
const BRUISE := Color("#5b2a6e")

static var _mats := {}


static func clear_cache() -> void:
	_mats.clear()


## A toon material with an ink outline (and optionally a thin white rim outside the ink,
## which every creature gets so it reads against the dark sky).
static func toon(col: Color, outline := 0.03, white_rim := false, opts := {}) -> ShaderMaterial:
	var key := "%s|%s|%s|%s" % [col.to_html(), outline, white_rim, str(opts)]
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", col)
	m.set_shader_parameter("shade", opts.get("shade", shade_of(col)))
	for k in ["highlight", "lump", "lump_freq", "glow", "halftone_px"]:
		if opts.has(k):
			m.set_shader_parameter(k, opts[k])
	if outline > 0.0:
		var o := ShaderMaterial.new()
		o.shader = OUTLINE
		o.set_shader_parameter("thickness", outline)
		o.set_shader_parameter("ink", opts.get("ink", INK))
		if opts.has("lump"):
			o.set_shader_parameter("lump", opts.lump)
			o.set_shader_parameter("lump_freq", opts.get("lump_freq", 3.0))
		m.next_pass = o
		if white_rim:
			var w := ShaderMaterial.new()
			w.shader = OUTLINE
			w.set_shader_parameter("thickness", outline * 1.6)
			w.set_shader_parameter("ink", Color(1, 0.97, 0.92))
			o.next_pass = w
	_mats[key] = m
	return m


## The cel-shadow colour: darker, pushed toward the indigo of the sky.
static func shade_of(c: Color) -> Color:
	return c.darkened(0.42).lerp(Color("#3b1f66"), 0.3)


static func tone(c: Color, amt: float) -> Color:
	return c.lightened(amt) if amt > 0.0 else c.darkened(-amt)


static func part(parent: Node3D, mesh: Mesh, mat: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func sphere(r: float, segs := 16) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = maxi(6, segs / 2)
	return s


static func cyl(top: float, bottom: float, h: float, segs := 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = segs
	c.rings = 1
	return c


static func box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


# ---------------------------------------------------------------------------
# VESPER: an arrowhead fighter with swept wings. Nose points to -Z (forward).
# ---------------------------------------------------------------------------
static func make_ship(col := Color("#3df5ff")) -> Node3D:
	var root := Node3D.new()
	root.name = "Ship"
	var body := toon(col, 0.035)
	var dark := toon(Color("#2a3f8f"), 0.03)
	var glass := toon(Color("#ff3fa4"), 0.025, false, {highlight = 1.0})
	var paper := toon(PAPER, 0.025)
	# fuselage: a long cone, nose forward
	part(root, cyl(0.04, 0.3, 1.7), body, Vector3(0, 0, -0.1), Vector3(-90, 0, 0))
	# canopy
	part(root, sphere(0.16), glass, Vector3(0, 0.15, -0.05), Vector3.ZERO, Vector3(0.8, 0.7, 1.6))
	# swept wings
	for sd in [-1.0, 1.0]:
		part(root, box(Vector3(0.85, 0.06, 0.42)), body, Vector3(sd * 0.48, -0.02, 0.32), Vector3(0, sd * 28.0, sd * -4.0))
		part(root, box(Vector3(0.12, 0.05, 0.5)), dark, Vector3(sd * 0.86, 0.0, 0.5), Vector3(0, sd * 12.0, 0))
		# wing-tip fins
		part(root, box(Vector3(0.04, 0.26, 0.24)), paper, Vector3(sd * 0.9, 0.12, 0.58), Vector3(-15, 0, 0))
	# tail and engine
	part(root, box(Vector3(0.05, 0.34, 0.3)), dark, Vector3(0, 0.2, 0.6), Vector3(-20, 0, 0))
	part(root, cyl(0.17, 0.2, 0.22), dark, Vector3(0, 0, 0.8), Vector3(-90, 0, 0))
	var flame := part(root, cyl(0.15, 0.01, 0.6, 10), toon(Color("#ff3fa4"), 0.02, false, {glow = 1.0}),
		Vector3(0, 0, 1.18), Vector3(90, 0, 0))
	flame.name = "Flame"
	return root


# ---------------------------------------------------------------------------
# LARVA: a pulsing maggot with a lamprey mouth facing you (+Z) and lime eyes.
# r_m is its hit radius in metres. Segments and mouth follow the Android drawing.
# ---------------------------------------------------------------------------
static func make_larva(r_m: float, col: Color) -> Node3D:
	var root := Node3D.new()
	var k := r_m / 14.0        # Android drawing units -> metres
	var segs := Node3D.new()
	segs.name = "Segs"
	root.add_child(segs)
	var specs := [[-9.0, 6.0, tone(col, -0.18)], [-2.0, 8.5, col], [6.0, 9.0, tone(col, 0.12)]]
	for s in specs:
		part(segs, sphere(s[1] * k, 18), toon(s[2], 0.03, true), Vector3(0, 0, s[0] * k), Vector3.ZERO, Vector3(1, 0.88, 0.95))
	# bruises
	var bruise := toon(BRUISE, 0.0, false, {highlight = 0.0})
	for b in [[-4.0, 3.0, -3.0, 2.0], [3.0, 4.5, -8.0, 1.5], [5.0, 3.0, 1.0, 1.6]]:
		part(segs, sphere(b[3] * k, 8), bruise, Vector3(b[0], b[1], b[2]) * k)
	# lamprey mouth on the front, ringed with bone teeth pointing inward
	var mouth := Node3D.new()
	mouth.name = "Mouth"
	mouth.position = Vector3(0, -1.0 * k, 13.5 * k)
	root.add_child(mouth)
	part(mouth, cyl(5.2 * k, 5.2 * k, 1.2 * k, 16), toon(MAW, 0.02, false, {highlight = 0.0}), Vector3.ZERO, Vector3(90, 0, 0))
	var tooth := cyl(0.0, 0.9 * k, 2.4 * k, 6)
	var bone := toon(BONE, 0.015)
	for i in 8:
		var a := i * TAU / 8.0
		var t := part(mouth, tooth, bone, Vector3(cos(a), sin(a), 0.2) * 4.2 * k)
		t.rotation = Vector3(0, 0, a + PI / 2)
	# three eyes that will track you
	var eyes := Node3D.new()
	eyes.name = "Eyes"
	root.add_child(eyes)
	var eye_mat := toon(EYE, 0.02, false, {glow = 0.6})
	var pupil := toon(INK, 0.0, false, {highlight = 0.0})
	for e in [[-5.5, 6.0, 9.0, 1.9], [5.0, 6.5, 8.0, 1.5], [1.5, 7.5, 3.0, 1.2]]:
		var eye := Node3D.new()
		eye.position = Vector3(e[0], e[1], e[2]) * k
		eyes.add_child(eye)
		part(eye, sphere(e[3] * k, 12), eye_mat)
		part(eye, sphere(e[3] * 0.5 * k, 8), pupil, Vector3(0, 0, -e[3] * 0.75 * k))
	return root


# ---------------------------------------------------------------------------
# Hive chunk: a lumpy organic rock for the scenery (kept dim so it never competes with bullets).
# ---------------------------------------------------------------------------
static func make_chunk(size_m: float, col: Color, seed_val: int) -> Node3D:
	var root := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var mat := toon(col, size_m * 0.025, false, {lump = size_m * 0.18, lump_freq = 2.2 / size_m, highlight = 0.0, halftone_px = 9.0})
	part(root, sphere(size_m, 24), mat, Vector3.ZERO, Vector3.ZERO,
		Vector3(rng.randf_range(0.8, 1.3), rng.randf_range(0.6, 1.0), rng.randf_range(0.8, 1.4)))
	# pustules (some chunks are hive pods)
	if rng.randf() < 0.5:
		var pus := toon(Color("#8a6a3a"), size_m * 0.02, false, {highlight = 0.0})
		for i in rng.randi_range(2, 5):
			var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 1), rng.randf_range(-1, 1)).normalized()
			part(root, sphere(size_m * rng.randf_range(0.15, 0.3), 10), pus, d * size_m * 0.85)
	return root
