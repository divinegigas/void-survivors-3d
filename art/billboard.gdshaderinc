// Shared camera-facing sprite code for MultiMesh batches (bullets, gems, sparks).
// Per instance: COLOR = main colour, INSTANCE_CUSTOM.x = shape, .y = size (metres).
// Shapes: 0 enemy bullet, 1 player shot, 2 XP gem, 3 spark, 4 soft glow, 5 hitbox dot, 6 reticle ring.

uniform float min_size_per_m = 0.008;   // far sprites never shrink below this (keeps bullets readable)
varying float v_shape;
varying vec4 v_col;

const vec3 INK = vec3(0.078, 0.063, 0.122);
const vec3 PAPER = vec3(1.0, 0.973, 0.906);

void vertex() {
	v_shape = INSTANCE_CUSTOM.x;
	v_col = COLOR;
	vec3 center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float dist = length(center - INV_VIEW_MATRIX[3].xyz);
	float sz = max(INSTANCE_CUSTOM.y, dist * min_size_per_m * step(INSTANCE_CUSTOM.x, 2.5));
	vec3 world = center + (INV_VIEW_MATRIX[0].xyz * VERTEX.x + INV_VIEW_MATRIX[1].xyz * VERTEX.y) * sz;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
}

vec4 sprite(vec2 uv) {
	vec2 p = uv * 2.0 - 1.0;
	p.y = -p.y;
	float d = length(p);
	vec3 c = v_col.rgb;
	float a = 1.0;
	if (v_shape < 0.5) {                       // enemy bullet: ink rim, pink, cream core
		if (d > 1.0) discard;
		c = d > 0.71 ? INK : v_col.rgb;
		if (length(p - vec2(-0.13, 0.13)) < 0.36) c = PAPER;
	} else if (v_shape < 1.5) {                // player shot: ink rim, colour, white-hot core
		if (d > 1.0) discard;
		c = d > 0.62 ? INK : (d < 0.3 ? vec3(1.0) : v_col.rgb);
	} else if (v_shape < 2.5) {                // XP gem: a diamond with a white rim
		float m = abs(p.x) * 1.25 + abs(p.y);
		if (m > 1.0) discard;
		c = m > 0.82 ? INK : (m > 0.64 ? vec3(1.0) : v_col.rgb);
		if (p.x < 0.0 && p.y > 0.0 && m < 0.64) c = mix(c, vec3(1.0), 0.45);
	} else if (v_shape < 3.5) {                // spark: a plain dot
		if (d > 1.0) discard;
	} else if (v_shape < 4.5) {                // soft glow (additive material)
		a = pow(max(0.0, 1.0 - d), 2.0) * v_col.a;
	} else if (v_shape < 5.5) {                // hitbox: white dot, ink rim
		if (d > 1.0) discard;
		c = d > 0.6 ? INK : vec3(1.0);
	} else {                                   // reticle: a broken ring with ticks
		float ring = abs(d - 0.78);
		float ang = atan(p.y, p.x);
		float gap = step(0.18, abs(fract(ang / 6.2832 * 4.0 + 0.125) - 0.5));
		bool on_ring = ring < 0.07 && gap > 0.5;
		bool tick = (abs(p.x) < 0.05 && abs(p.y) > 0.55 && abs(p.y) < 1.0) || (abs(p.y) < 0.05 && abs(p.x) > 0.55 && abs(p.x) < 1.0);
		bool edge = ring < 0.13 && gap > 0.5 || ((abs(p.x) < 0.1 && abs(p.y) > 0.5 && abs(p.y) < 1.0) || (abs(p.y) < 0.1 && abs(p.x) > 0.5 && abs(p.x) < 1.0));
		if (!edge) discard;
		c = (on_ring || tick) ? v_col.rgb : INK;
		a = v_col.a;
	}
	return vec4(c, a);
}
