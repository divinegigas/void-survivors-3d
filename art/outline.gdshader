// Inverted-hull ink outline: draws the back faces, pushed out along the normals.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;

uniform vec4 ink : source_color = vec4(0.078, 0.063, 0.122, 1.0);
uniform float thickness = 0.03;   // metres
uniform float lump = 0.0;         // must match the toon material's lump
uniform float lump_freq = 3.0;

void vertex() {
	vec3 n = normalize(NORMAL);
	if (lump > 0.0) {
		vec3 v = VERTEX * lump_freq;
		VERTEX += n * lump * (sin(v.x * 1.7 + v.y) * sin(v.y * 1.3 - v.z) * sin(v.z * 1.1 + v.x));
	}
	VERTEX += n * thickness;
}

void fragment() {
	ALBEDO = ink.rgb;
}
