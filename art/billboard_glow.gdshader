// Soft additive glows (behind XP gems, engine flames).
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, blend_add, depth_draw_never;
#include "res://art/billboard.gdshaderinc"
void fragment() {
	vec4 s = sprite(UV);
	ALBEDO = s.rgb;
	ALPHA = s.a;
}
