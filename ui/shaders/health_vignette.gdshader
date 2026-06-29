shader_type canvas_item;
render_mode unshaded;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec3 tint_color = vec3(0.82, 0.03, 0.02);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	uv.x *= float(textureSize(TEXTURE, 0).y) / float(textureSize(TEXTURE, 0).x);
	float dist = length(uv) * 2.0;
	float vignette = smoothstep(0.3, 1.05, dist);
	vignette *= vignette;
	float alpha = vignette * intensity;
	COLOR = vec4(tint_color, alpha);
}
