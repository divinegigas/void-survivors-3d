// Comic kill starburst: a spiky star with an ink rim, always facing the camera.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;
uniform vec4 color : source_color = vec4(1.0, 0.84, 0.04, 1.0);
uniform float points = 11.0;
uniform float spin = 0.0;
uniform float alpha = 1.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x) + spin;
	float s = abs(fract(a / 6.2832 * points) - 0.5) * 2.0;
	float edge = mix(0.5, 1.0, s * s);
	if (r > edge) discard;
	vec3 c = r > edge - 0.12 ? vec3(0.078, 0.063, 0.122) : color.rgb;
	if (r < edge * 0.45) c = mix(c, vec3(1.0, 0.973, 0.906), 0.85);
	ALBEDO = c;
	ALPHA = alpha;
}
