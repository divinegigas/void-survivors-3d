class_name Icons
## Little code-drawn icons for weapons and passives (used by the HUD and the level-up cards).
## `c` is the centre, `s` the half-size in pixels.

const INK := Color("#14101f")


static func draw(ci: CanvasItem, id: String, c: Vector2, s: float, col: Color) -> void:
	var w := maxf(2.0, s * 0.16)
	match id:
		"cannon":
			for i in 3:
				var x := c.x + (i - 1) * s * 0.5
				_bar(ci, Vector2(x, c.y - s * 0.8), Vector2(x, c.y + s * 0.8), w * 1.3, col)
		"spread":
			for i in 5:
				var a := -PI / 2 + (i - 2) * 0.32
				_bar(ci, c + Vector2(0, s * 0.7), c + Vector2(0, s * 0.7) + Vector2(cos(a), sin(a)) * s * 1.4, w, col)
		"rockets":
			_poly(ci, [c + Vector2(0, -s), c + Vector2(s * 0.4, -s * 0.3), c + Vector2(s * 0.4, s * 0.6),
				c + Vector2(s * 0.75, s), c + Vector2(-s * 0.75, s), c + Vector2(-s * 0.4, s * 0.6), c + Vector2(-s * 0.4, -s * 0.3)], col)
		"wing":
			for sd in [-1.0, 1.0]:
				var x: float = c.x + sd * s * 0.55
				_poly(ci, [Vector2(x, c.y - s), Vector2(x + s * 0.4, c.y - s * 0.2), Vector2(x + s * 0.15, c.y - s * 0.2),
					Vector2(x + s * 0.15, c.y + s), Vector2(x - s * 0.15, c.y + s), Vector2(x - s * 0.15, c.y - s * 0.2), Vector2(x - s * 0.4, c.y - s * 0.2)], col)
		"rapid":
			for k in 2:
				var o := (k - 0.5) * s * 0.8
				_line(ci, [c + Vector2(o - s * 0.35, -s * 0.7), c + Vector2(o + s * 0.35, 0), c + Vector2(o - s * 0.35, s * 0.7)], w * 1.4, col)
		"power":
			_poly(ci, [c + Vector2(0, -s), c + Vector2(s, s * 0.8), c + Vector2(-s, s * 0.8)], col)
		"area":
			for k in 3:
				_ring(ci, c, s * (0.35 + k * 0.32), w, col)
		"multi":
			for k in 3:
				var a := -PI / 2 + k * TAU / 3
				_dot(ci, c + Vector2(cos(a), sin(a)) * s * 0.55, s * 0.36, col)
		"velocity":
			_poly(ci, [c + Vector2(s, 0), c + Vector2(-s * 0.2, -s * 0.8), c + Vector2(-s * 0.2, -s * 0.3), c + Vector2(-s, -s * 0.3),
				c + Vector2(-s, s * 0.3), c + Vector2(-s * 0.2, s * 0.3), c + Vector2(-s * 0.2, s * 0.8)], col)
		"crit":
			_ring(ci, c, s * 0.7, w, col)
			for a in [0.0, PI / 2, PI, PI * 1.5]:
				var d := Vector2(cos(a), sin(a))
				_bar(ci, c + d * s * 0.35, c + d * s * 1.05, w, col)
		"reactive":
			var pts: Array = []
			for k in 16:
				var a := k * TAU / 16
				pts.append(c + Vector2(cos(a), sin(a)) * s * (1.0 if k % 2 == 0 else 0.5))
			_poly(ci, pts, col)
		"plating":
			var hx: Array = []
			for k in 6:
				var a := PI / 6 + k * TAU / 6
				hx.append(c + Vector2(cos(a), sin(a)) * s * 0.95)
			_poly(ci, hx, col)
		"repair":
			_bar(ci, c + Vector2(0, -s * 0.85), c + Vector2(0, s * 0.85), s * 0.5, col)
			_bar(ci, c + Vector2(-s * 0.85, 0), c + Vector2(s * 0.85, 0), s * 0.5, col)
		"tractor":
			_line(ci, [c + Vector2(-s * 0.7, -s * 0.9), c + Vector2(-s * 0.7, s * 0.1), c + Vector2(-s * 0.45, s * 0.65),
				c + Vector2(0, s * 0.85), c + Vector2(s * 0.45, s * 0.65), c + Vector2(s * 0.7, s * 0.1), c + Vector2(s * 0.7, -s * 0.9)], w * 2.0, col)
		"datacore":
			_poly(ci, [c + Vector2(0, -s), c + Vector2(s * 0.75, 0), c + Vector2(0, s), c + Vector2(-s * 0.75, 0)], col)
		"bounty":
			_ring(ci, c, s * 0.85, w * 1.2, col)
			_line(ci, [c + Vector2(s * 0.35, -s * 0.35), c + Vector2(-s * 0.3, -s * 0.35), c + Vector2(-s * 0.3, 0),
				c + Vector2(s * 0.3, 0), c + Vector2(s * 0.3, s * 0.35), c + Vector2(-s * 0.35, s * 0.35)], w, col)
			_bar(ci, c + Vector2(0, -s * 0.6), c + Vector2(0, s * 0.6), w * 0.8, col)
		"repair_fill":
			_bar(ci, c + Vector2(0, -s * 0.85), c + Vector2(0, s * 0.85), s * 0.5, col)
			_bar(ci, c + Vector2(-s * 0.85, 0), c + Vector2(s * 0.85, 0), s * 0.5, col)
		"cache":
			_ring(ci, c, s * 0.85, w * 1.4, col)
			_dot(ci, c, s * 0.35, col)
		_:
			_dot(ci, c, s * 0.6, col)


# Helpers: everything gets a fat ink edge first, pop-art style.
static func _poly(ci: CanvasItem, pts: Array, col: Color) -> void:
	var p := PackedVector2Array(pts)
	var closed := p.duplicate()
	closed.append(p[0])
	ci.draw_polyline(closed, INK, 5.0, true)
	ci.draw_colored_polygon(p, col)


static func _line(ci: CanvasItem, pts: Array, w: float, col: Color) -> void:
	var p := PackedVector2Array(pts)
	ci.draw_polyline(p, INK, w + 4.0, true)
	ci.draw_polyline(p, col, w, true)


static func _bar(ci: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	ci.draw_line(a, b, INK, w + 4.0, true)
	ci.draw_line(a, b, col, w, true)


static func _ring(ci: CanvasItem, c: Vector2, r: float, w: float, col: Color) -> void:
	ci.draw_arc(c, r, 0, TAU, 32, INK, w + 4.0, true)
	ci.draw_arc(c, r, 0, TAU, 32, col, w, true)


static func _dot(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c, r + 2.0, INK)
	ci.draw_circle(c, r, col)
