// Pop-art cel shading: two flat tones, a screen-space halftone dot band between
// them, and a hard comic highlight. Unshaded on purpose: our own fixed "key light"
// keeps the look identical everywhere. Outlines come from outline.gdshader (next pass).
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 shade : source_color = vec4(0.35, 0.25, 0.55, 1.0);
uniform vec3 light_dir = vec3(-0.45, 0.8, 0.55);   // world space, points toward the light
uniform float halftone_px = 7.0;                  // dot grid size in screen pixels
uniform float highlight = 0.7;                    // 0 = no shiny spot
uniform float lump = 0.0;                         // organic wobble (hive chunks)
uniform float lump_freq = 3.0;
uniform float glow = 0.0;                         // 1 = flat bright colour (flames, eyes)

void vertex() {
	if (lump > 0.0) {
		vec3 v = VERTEX * lump_freq;
		VERTEX += NORMAL * lump * (sin(v.x * 1.7 + v.y) * sin(v.y * 1.3 - v.z) * sin(v.z * 1.1 + v.x));
	}
}

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 l = normalize((VIEW_MATRIX * vec4(normalize(light_dir), 0.0)).xyz);
	float ndl = dot(n, l);
	vec3 c = albedo.rgb;
	// Halftone: a 45-degree dot grid whose dots grow as the surface turns from the light.
	vec2 g = FRAGCOORD.xy / halftone_px;
	g = vec2(g.x + g.y, g.x - g.y) * 0.7071;
	vec2 cell = fract(g) - 0.5;
	float band = clamp((0.45 - ndl) / 0.6, 0.0, 1.0);
	if (ndl < -0.2 || length(cell) < band * 0.62) {
		c = shade.rgb;
	}
	vec3 h = normalize(l + VIEW);
	if (highlight > 0.0 && pow(max(dot(n, h), 0.0), 60.0) > 0.5) {
		c = mix(c, vec3(1.0, 0.97, 0.9), highlight);
	}
	c = mix(c, albedo.rgb, glow);
	ALBEDO = c;
}
