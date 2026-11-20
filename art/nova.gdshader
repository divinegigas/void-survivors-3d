// Shockwave sphere: bright at the rim, see-through in the middle.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never, blend_add;
uniform vec4 color : source_color = vec4(1.0, 0.6, 0.35, 1.0);
uniform float alpha = 1.0;
void fragment() {
	float f = 1.0 - abs(dot(normalize(NORMAL), VIEW));
	ALBEDO = color.rgb;
	ALPHA = pow(f, 3.0) * alpha;
}
