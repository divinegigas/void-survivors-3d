// Stage 1 "Hive Fleet" sky: deep indigo with drifting halftone dots and twinkling stars.
shader_type sky;

uniform vec4 base : source_color = vec4(0.114, 0.086, 0.282, 1.0);   // #1d1648
uniform vec4 dot_a : source_color = vec4(0.173, 0.133, 0.439, 1.0);  // #2c2270
uniform vec4 dot_b : source_color = vec4(0.231, 0.122, 0.400, 1.0);  // #3b1f66
uniform vec4 glow : source_color = vec4(0.42, 0.16, 0.48, 1.0);      // magenta haze near the horizon
uniform float dot_count = 90.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void sky() {
	vec3 d = normalize(EYEDIR);
	vec2 uv = vec2(atan(d.x, -d.z) / 6.2832 + 0.5, acos(clamp(d.y, -1.0, 1.0)) / 3.14159);
	vec3 c = base.rgb;
	c = mix(c, glow.rgb, pow(1.0 - abs(d.y), 6.0) * 0.55);
	// Halftone clouds: dot size follows a slow wavy field.
	vec2 g = uv * vec2(dot_count * 2.0, dot_count);
	vec2 cell = fract(g) - 0.5;
	vec2 id = floor(g);
	float field = 0.5 + 0.5 * sin(uv.x * 18.0 + TIME * 0.05) * sin(uv.y * 11.0 - uv.x * 7.0);
	float r = field * 0.3;
	if (length(cell) < r) c = mix(dot_a.rgb, dot_b.rgb, step(0.5, hash(id)));
	// Stars.
	vec2 sg = uv * vec2(420.0, 210.0);
	vec2 sid = floor(sg);
	float h = hash(sid);
	if (h > 0.9935) {
		float tw = 0.6 + 0.4 * sin(TIME * (2.0 + h * 6.0) + h * 40.0);
		float sd = length(fract(sg) - 0.5);
		c = mix(c, vec3(1.0, 0.97, 0.9), smoothstep(0.32, 0.0, sd) * tw);
	}
	COLOR = c;
}
