class_name SpriteBatch
extends MultiMeshInstance3D
## Draws many camera-facing sprites (bullets, gems, sparks) in one go.
## Each frame: begin(), add() for every sprite, finish().
## Shapes: 0 enemy bullet, 1 player shot, 2 XP gem, 3 spark, 4 soft glow, 5 hitbox dot, 6 reticle.

var _n := 0
var _cap := 0


func setup(shader: Shader, capacity: int, priority := 0) -> SpriteBatch:
	_cap = capacity
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	mm.mesh = q
	mm.instance_count = capacity
	mm.visible_instance_count = 0
	multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.render_priority = priority
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	custom_aabb = AABB(Vector3(-5000, -5000, -5000), Vector3(10000, 10000, 10000))
	return self


func begin() -> void:
	_n = 0


## pos is in this node's local space (metres), size is the sprite's diameter in metres.
func add(pos: Vector3, shape: int, size: float, col: Color) -> void:
	if _n >= _cap:
		return
	multimesh.set_instance_transform(_n, Transform3D(Basis.IDENTITY, pos))
	multimesh.set_instance_color(_n, col)
	multimesh.set_instance_custom_data(_n, Color(shape, size, 0, 0))
	_n += 1


func finish() -> void:
	multimesh.visible_instance_count = _n
