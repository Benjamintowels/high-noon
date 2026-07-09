shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, blend_mix;

uniform vec4 aura_color : source_color = vec4(0.9, 0.12, 0.08, 0.32);
uniform float grow_amount = 0.025;

void vertex() {
	VERTEX += NORMAL * grow_amount;
}

void fragment() {
	ALBEDO = aura_color.rgb;
	ALPHA = aura_color.a;
}
