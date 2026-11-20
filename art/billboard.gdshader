// Depth-tested sprites (player shots, sparks).
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
#include "res://art/billboard.gdshaderinc"
void fragment() {
	vec4 s = sprite(UV);
	ALBEDO = s.rgb;
}
