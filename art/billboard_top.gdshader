// Sprites drawn on top of everything (enemy bullets, XP gems, your hitbox, the reticle):
// the most important things on screen are never hidden behind a ship or a bug.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_test_disabled, depth_draw_never;
#include "res://art/billboard.gdshaderinc"
void fragment() {
	vec4 s = sprite(UV);
	ALBEDO = s.rgb;
	ALPHA = s.a;
}
