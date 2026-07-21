shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, blend_mix;

uniform vec4 aura_color : source_color = vec4(0.9, 0.12, 0.08, 0.32);
uniform float grow_amount = 0.025;

void vertex() {
	// Grow is authored in world meters. Weapon FBX imports often keep ~100x
	// local scale; without compensation VERTEX += NORMAL * grow fills the
	// screen with a giant red shell.
	float model_scale = max(
		max(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz)),
		max(length(MODEL_MATRIX[2].xyz), 0.0001)
	);
	VERTEX += normalize(NORMAL) * (grow_amount / model_scale);
}

void fragment() {
	ALBEDO = aura_color.rgb;
	ALPHA = aura_color.a;
}
