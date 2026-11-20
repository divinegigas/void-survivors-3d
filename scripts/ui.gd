class_name GameUI
extends CanvasLayer
## Everything 2D on top of the 3D view: the HUD, the level-up cards, title, pause and results.
## Pop-art style: Bangers lettering with fat ink outlines, slanted panels with hard shadows.

signal card_chosen(index: int)

const BANGERS := preload("res://fonts/Bangers-Regular.ttf")
const COMIC := preload("res://fonts/ComicNeue-Bold.ttf")
const INK := Color("#14101f")
const PAPER := Color("#fff8e7")

var game: Game
var hud: Hud
var _cards_root: Control
var _cards: Array = []
var _title: Control
var _pause: Control
var _over: Control
var _over_label: Label
var _ui_lock := 0.0


func _ready() -> void:
	layer = 10
	hud = Hud.new()
	hud.ui = self
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	_title = _build_title()
	_pause = _build_pause()
	_over = _build_over()
	_cards_root = Control.new()
	_cards_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cards_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cards_root)


func _process(delta: float) -> void:
	_ui_lock = maxf(0.0, _ui_lock - delta)
	hud.queue_redraw()


# ---------------------------------------------------------------- helpers
static func big_label(text: String, size: int, col: Color, outline := 18) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", BANGERS)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_shadow_color", Color(INK, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 6)
	l.add_theme_constant_override("shadow_offset_y", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func body_label(text: String, size: int, col := PAPER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", COMIC)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func slant_box(fill: Color, border: Color, skew := 0.12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(6)
	sb.skew = Vector2(skew, 0)
	sb.shadow_color = INK
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(10, 10)
	sb.set_content_margin_all(24)
	return sb


func _screen(dim := 0.55) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(INK, dim)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	box.name = "Box"
	root.add_child(box)
	root.visible = false
	add_child(root)
	return root


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", BANGERS)
	b.add_theme_font_size_override("font_size", 44)
	b.add_theme_color_override("font_color", PAPER)
	b.add_theme_color_override("font_focus_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_stylebox_override("normal", slant_box(Color("#2c2270"), PAPER))
	b.add_theme_stylebox_override("hover", slant_box(Color("#ffd60a"), INK))
	b.add_theme_stylebox_override("focus", slant_box(Color("#ffd60a"), INK))
	b.add_theme_stylebox_override("pressed", slant_box(Color("#ff3fa4"), INK))
	b.custom_minimum_size = Vector2(420, 80)
	b.pressed.connect(cb)
	return b


# ---------------------------------------------------------------- screens
func _build_title() -> Control:
	var root := _screen(0.25)
	var box: VBoxContainer = root.get_node("Box")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	row.add_child(big_label("VOID SURVIVORS", 170, PAPER, 28))
	row.add_child(big_label("3D", 170, Color("#ff3fa4"), 28))
	box.add_child(row)
	box.add_child(big_label("STAGE 1 · HIVE FLEET  —  MILESTONE 1 SLICE", 46, Color("#3df5ff"), 14))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	box.add_child(spacer)
	var go := big_label("CLICK  OR  PRESS  ENTER / (A)  TO  LAUNCH", 64, Color("#ffd60a"), 16)
	go.name = "Go"
	box.add_child(go)
	box.add_child(body_label("Steer: mouse, WASD / arrow keys, or the left stick.   Your guns fire on their own.\n"
		+ "Dodge the pink shots: only the white dot in your ship can be hit.\n"
		+ "Fly over the mint gems to level up.   Esc: pause.   F11: fullscreen.", 30, PAPER))
	box.add_child(body_label("Esc on this screen quits.", 24, Catalog.DIM))
	return root


func _build_pause() -> Control:
	var root := _screen(0.6)
	var box: VBoxContainer = root.get_node("Box")
	box.add_child(big_label("PAUSED", 150, PAPER, 26))
	box.add_child(_button("RESUME  (ESC)", func(): game.resume()))
	box.add_child(_button("RESTART  (R)", func(): game.start_run()))
	box.add_child(_button("QUIT TO TITLE  (Q)", func(): game.quit_to_title()))
	for b in box.get_children():
		if b is Button:
			b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return root


func _build_over() -> Control:
	var root := _screen(0.6)
	var box: VBoxContainer = root.get_node("Box")
	box.add_child(big_label("SHOT DOWN!", 170, Catalog.RED, 28))
	_over_label = body_label("", 40)
	box.add_child(_over_label)
	box.add_child(big_label("ENTER / (A): FLY AGAIN      ESC: TITLE", 52, Color("#ffd60a"), 14))
	return root


func _hide_all() -> void:
	for c in [_title, _pause, _over]:
		c.visible = false
	for c in _cards:
		c.queue_free()
	_cards.clear()
	for c in _cards_root.get_children():
		c.queue_free()


func show_title() -> void:
	_hide_all()
	hud.visible = false
	_title.visible = true
	var go: Control = _title.get_node("Box/Go")
	var tw := go.create_tween().set_loops()
	tw.tween_property(go, "modulate:a", 0.35, 0.6)
	tw.tween_property(go, "modulate:a", 1.0, 0.6)


func show_play() -> void:
	_hide_all()
	hud.visible = true


func show_pause() -> void:
	_hide_all()
	_pause.visible = true
	(_pause.get_node("Box").get_child(1) as Button).grab_focus()


func show_over() -> void:
	_hide_all()
	hud.visible = true
	var m := int(game.t) / 60
	var s := int(game.t) % 60
	_over_label.text = "Survived %d:%02d    ·    Level %d    ·    %d kills    ·    %d credits" % [m, s, game.level, game.kills, int(game.credits)]
	_over.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not game:
		return
	if game.state == "paused" and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			game.start_run()
		elif event.keycode == KEY_Q:
			game.quit_to_title()
	elif game.state == "levelup" and _ui_lock <= 0.0 and event is InputEventKey and event.pressed and not event.echo:
		var i: int = [KEY_1, KEY_2, KEY_3].find(event.keycode)
		if i >= 0 and i < _cards.size():
			_pick(i)
	elif game.state == "title" and event.is_action_pressed("pause"):
		get_tree().quit()
	elif game.state == "over" and event.is_action_pressed("pause"):
		game.quit_to_title()


# ---------------------------------------------------------------- level-up cards
func show_cards(choices: Array) -> void:
	_hide_all()
	hud.visible = true
	_ui_lock = 0.4          # ignore input briefly so a held key doesn't pick by accident
	var dim := ColorRect.new()
	dim.color = Color(INK, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards_root.add_child(dim)
	var vs := _cards_root.get_viewport_rect().size
	var title := big_label("LEVEL UP!", 150, Color("#ffd60a"), 28)
	title.size = Vector2(vs.x, 170)
	title.position = Vector2(0, 70)
	title.rotation_degrees = -3.0
	title.pivot_offset = Vector2(vs.x / 2, 85)
	_cards_root.add_child(title)
	var sub := body_label("LV %d  —  pick one: click, 1 / 2 / 3, or arrows + Enter / (A)" % game.level, 32)
	sub.size = Vector2(vs.x, 50)
	sub.position = Vector2(0, 250)
	_cards_root.add_child(sub)
	var tw := title.create_tween()
	title.scale = Vector2(1.6, 1.6)
	tw.tween_property(title, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var w := 470.0
	var h := 600.0
	var gap := 60.0
	var n := choices.size()
	var x0 := (vs.x - (n * w + (n - 1) * gap)) / 2.0
	for i in n:
		var card := Card.new()
		card.setup(game, choices[i], i)
		card.size = Vector2(w, h)
		var final := Vector2(x0 + i * (w + gap), 330)
		card.position = final + Vector2((-1 if i % 2 == 0 else 1) * vs.x, 0)
		card.pressed.connect(_pick.bind(i))
		_cards_root.add_child(card)
		_cards.append(card)
		var ct := card.create_tween()
		ct.tween_interval(0.05 + 0.07 * i)
		ct.tween_property(card, "position", final, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in n:
		_cards[i].focus_neighbor_left = _cards[(i - 1 + n) % n].get_path()
		_cards[i].focus_neighbor_right = _cards[(i + 1) % n].get_path()
	if n > 0:
		_cards[0].grab_focus()


func _pick(i: int) -> void:
	if _ui_lock > 0.0:
		return
	card_chosen.emit(i)


# ---------------------------------------------------------------- little effects
func float_text(text: String, col: Color) -> void:
	var l := big_label(text, 48, col, 12)
	var vs := hud.get_viewport_rect().size
	l.size = Vector2(400, 60)
	l.position = Vector2(vs.x / 2 - 200, vs.y * 0.62)
	hud.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 90, 1.0)
	tw.tween_property(l, "modulate:a", 0.0, 1.0).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)


func hurt() -> void:
	hud.hurt_t = 0.35


# ============================================================================
# A level-up card: tier-coloured slanted frame, big icon, name, tag line and description.
# ============================================================================
class Card extends Button:
	var game: Game
	var choice: Dictionary
	var index := 0
	var title := ""
	var desc := ""
	var tag := ""
	var tier_name := ""
	var tier_col := Color.WHITE
	var icon_col := Color.WHITE
	var icon_id := ""

	func setup(g: Game, c: Dictionary, i: int) -> void:
		game = g
		choice = c
		index = i
		focus_mode = Control.FOCUS_ALL
		var empty := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(s, empty)
		mouse_entered.connect(func(): grab_focus())
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		_describe()

	func _describe() -> void:
		var nw := game.slot_weapons().size()
		var np := game.passives.size()
		var slots := game.slot_count()
		if choice.kind == "fill":
			if choice.id == "repair":
				title = "Field Repair"; desc = "Restore 1 hull point"; icon_id = "repair_fill"; tier_col = Catalog.XP_GREEN
			else:
				title = "Salvage Cache"; desc = "+%d credits" % CFG.filler_credits; icon_id = "cache"; tier_col = Catalog.GOLD
			icon_col = tier_col
			tag = "BONUS"
			tier_name = "BONUS"
			return
		var is_w: bool = choice.kind == "wup" or choice.kind == "wnew"
		var d := Catalog.info(choice.id)
		var t: Dictionary = Catalog.TIER[d.tier]
		title = d.name
		tier_name = t.name
		tier_col = t.color
		icon_col = d.color
		icon_id = choice.id
		match choice.kind:
			"wnew":
				desc = Catalog.level_text(choice.id, 0); tag = "NEW WEAPON · %d/%d" % [nw + 1, slots.x]
			"pnew":
				desc = Catalog.level_text(choice.id, 0); tag = "NEW PASSIVE · %d/%d" % [np + 1, slots.y]
			_:
				var lvl: int = game.weapons[choice.id].lvl if is_w else game.passives[choice.id]
				var sig := "SHIP " if is_w and game.weapons[choice.id].builtin else ""
				desc = Catalog.level_text(choice.id, lvl)
				tag = "%s%s · LV %d → %d" % [sig, "WEAPON" if is_w else "PASSIVE", lvl, lvl + 1]

	func _draw() -> void:
		var hot := has_focus()
		var w := size.x
		var h := size.y
		var sk := 40.0
		var lift := Vector2(0, -16) if hot else Vector2.ZERO
		var pts := PackedVector2Array([Vector2(sk, 0), Vector2(w, 0), Vector2(w - sk, h), Vector2(0, h)])
		var shadow := PackedVector2Array()
		for p in pts:
			shadow.append(p + Vector2(14, 14))
		var body := PackedVector2Array()
		for p in pts:
			body.append(p + lift)
		draw_colored_polygon(shadow, INK)
		draw_colored_polygon(body, Color("#241a52") if not hot else Color("#33267a"))
		var edge := body.duplicate()
		edge.append(body[0])
		draw_polyline(edge, INK, 16.0)
		draw_polyline(edge, tier_col, 8.0 if not hot else 11.0)
		# tier banner
		var bh := 54.0
		var banner := PackedVector2Array([Vector2(sk - 2, 6), Vector2(w - 8, 6), Vector2(w - 8 - sk * bh / h, bh), Vector2(sk - 2 - sk * bh / h, bh)])
		for i in banner.size():
			banner[i] += lift
		draw_colored_polygon(banner, tier_col)
		var f: Font = BANGERS
		draw_string(f, Vector2(0, 46) + lift, tier_name, HORIZONTAL_ALIGNMENT_CENTER, w, 40, INK)
		# icon in an ink disc
		var c := Vector2(w / 2.0, 165) + lift
		draw_circle(c, 82, INK)
		draw_circle(c, 74, Color("#3b2f86"))
		draw_arc(c, 74, 0, TAU, 48, tier_col, 5.0, true)
		Icons.draw(self, icon_id, c, 44.0, icon_col)
		# name (shrinks to fit)
		var fs := 58
		while fs > 30 and f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w - 70:
			fs -= 2
		var tp := Vector2(10, 320) + lift
		draw_string_outline(f, tp, title, HORIZONTAL_ALIGNMENT_CENTER, w - 20, fs, 14, INK)
		draw_string(f, tp, title, HORIZONTAL_ALIGNMENT_CENTER, w - 20, fs, PAPER)
		draw_string(COMIC, Vector2(10, 370) + lift, tag, HORIZONTAL_ALIGNMENT_CENTER, w - 20, 24, tier_col)
		draw_multiline_string(COMIC, Vector2(40, 430) + lift, desc, HORIZONTAL_ALIGNMENT_CENTER, w - 80, 32, 4, PAPER)
		# key hint
		var kc := Vector2(w / 2.0, h - 40) + lift
		draw_circle(kc, 26, INK)
		draw_circle(kc, 21, tier_col if hot else Color("#5a5480"))
		draw_string(f, kc + Vector2(-30, 12), str(index + 1), HORIZONTAL_ALIGNMENT_CENTER, 60, 34, INK)


# ============================================================================
# The HUD: XP bar, level, clock with stage progress, hull hearts, credits, loadout.
# ============================================================================
class Hud extends Control:
	var ui: GameUI
	var hurt_t := 0.0

	func _draw() -> void:
		var g := ui.game
		if g == null:
			return
		hurt_t = maxf(0.0, hurt_t - get_process_delta_time())
		var vs := get_viewport_rect().size
		var f: Font = BANGERS
		# XP bar
		var need := float(CFG.xp_need(g.level))
		var k := clampf(g.xp / need, 0.0, 1.0)
		var bar := Rect2(24, 18, vs.x - 48, 24)
		draw_rect(bar.grow(4), INK)
		draw_rect(bar, Color("#3a3366"))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)), Catalog.XP_GREEN)
		draw_rect(Rect2(bar.position + Vector2(0, 3), Vector2(bar.size.x * k, 5)), Color(1, 1, 1, 0.35))
		# level
		_text(f, Vector2(28, 108), "LV %d" % g.level, 64, PAPER)
		# hull hearts
		for i in g.p.max_hp:
			_heart(Vector2(48 + i * 58, 150), 22.0, Catalog.RED if i < g.p.hp else Color("#3a3366"))
		# clock and stage progress
		var tt := minf(g.t, CFG.level.length)
		var clock := "%d:%02d" % [int(tt) / 60, int(tt) % 60]
		_text(f, Vector2(0, 112), clock, 72, PAPER, HORIZONTAL_ALIGNMENT_CENTER, vs.x)
		var pw := 520.0
		var px := (vs.x - pw) / 2.0
		var py := 132.0
		draw_rect(Rect2(px - 3, py - 3, pw + 6, 12), INK)
		draw_rect(Rect2(px, py, pw, 6), Color("#3a3366"))
		draw_rect(Rect2(px, py, pw * tt / CFG.level.length, 6), Color("#ff3fa4"))
		var marks: Array = CFG.level.mini_bosses.duplicate()
		marks.append(CFG.level.length)
		for i in marks.size():
			var mx: float = px + pw * marks[i] / CFG.level.length
			var last := i == marks.size() - 1
			draw_circle(Vector2(mx, py + 3), 14.0 if last else 10.0, INK)
			draw_circle(Vector2(mx, py + 3), 10.0 if last else 7.0, Catalog.RED if tt >= marks[i] else (Color("#d81b60") if last else Color("#6b6590")))
		# credits and kills
		_text(f, Vector2(0, 104), "%d CR" % int(g.credits), 56, Catalog.GOLD, HORIZONTAL_ALIGNMENT_RIGHT, vs.x - 30)
		_text(COMIC, Vector2(0, 148), "KILLS %d" % g.kills, 30, PAPER, HORIZONTAL_ALIGNMENT_RIGHT, vs.x - 30)
		# loadout (bottom left): signature + weapon slots, then passive slots
		var slots := g.slot_count()
		var y0 := vs.y - 190.0
		var x := 30.0
		for id in g.weapons:
			if g.weapons[id].builtin:
				_tile(Vector2(x, y0), id, g.weapons[id].lvl, CFG.max_level, Catalog.GOLD)
				x += 96
		x += 14
		var ws := g.slot_weapons()
		for i in slots.x:
			if i < ws.size():
				_tile(Vector2(x, y0), ws[i], g.weapons[ws[i]].lvl, CFG.max_level, Catalog.TIER[Catalog.info(ws[i]).tier].color)
			else:
				_tile(Vector2(x, y0), "", 0, 0, Color("#5a5480"))
			x += 96
		x = 30.0 + 96 + 14
		var ps := g.passives.keys()
		for i in slots.y:
			if i < ps.size():
				_tile(Vector2(x, y0 + 96), ps[i], g.passives[ps[i]], Catalog.passive_max(ps[i]), Catalog.TIER[Catalog.info(ps[i]).tier].color)
			else:
				_tile(Vector2(x, y0 + 96), "", 0, 0, Color("#5a5480"))
			x += 96
		# hurt flash
		if hurt_t > 0.0:
			var a := hurt_t / 0.35 * 0.45
			var e := 70.0
			draw_rect(Rect2(0, 0, vs.x, e), Color(1, 0.1, 0.2, a))
			draw_rect(Rect2(0, vs.y - e, vs.x, e), Color(1, 0.1, 0.2, a))
			draw_rect(Rect2(0, 0, e, vs.y), Color(1, 0.1, 0.2, a))
			draw_rect(Rect2(vs.x - e, 0, e, vs.y), Color(1, 0.1, 0.2, a))

	func _text(f: Font, pos: Vector2, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
		draw_string_outline(f, pos, s, align, width, size, 14, INK)
		draw_string(f, pos, s, align, width, size, col)

	func _heart(c: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 40:
			var tt := float(i) / 40.0 * TAU
			pts.append(c + Vector2(16.0 * pow(sin(tt), 3), -(13.0 * cos(tt) - 5.0 * cos(2 * tt) - 2.0 * cos(3 * tt) - cos(4 * tt))) * r / 16.0)
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_colored_polygon(pts, col)
		draw_polyline(closed, INK, 5.0, true)

	func _tile(pos: Vector2, id: String, lvl: int, mx: int, col: Color) -> void:
		var s := 80.0
		var sk := 12.0
		var pts := PackedVector2Array([pos + Vector2(sk, 0), pos + Vector2(s + sk, 0), pos + Vector2(s, s), pos + Vector2(0, s)])
		var sh := PackedVector2Array()
		for p in pts:
			sh.append(p + Vector2(6, 6))
		draw_colored_polygon(sh, INK)
		draw_colored_polygon(pts, Color("#241a52") if id != "" else Color(0.14, 0.1, 0.3, 0.6))
		var edge := pts.duplicate()
		edge.append(pts[0])
		draw_polyline(edge, col, 4.0)
		if id == "":
			return
		Icons.draw(self, id, pos + Vector2(s / 2 + 6, s / 2 - 6), 20.0, Catalog.info(id).color)
		for i in mx:
			var pc := pos + Vector2(14 + i * (s - 16) / maxf(1, mx), s - 10)
			draw_rect(Rect2(pc, Vector2(10, 6)), INK)
			draw_rect(Rect2(pc + Vector2(1, 1), Vector2(8, 4)), col if i < lvl else Color("#3a3366"))
