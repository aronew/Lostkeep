shader_type canvas_item;
// The screen vignette: the edges sink into violet shadow, drawing the eye to
// the centre. A faint warm lift in the middle keeps Kleo readable.

uniform float strength = 0.62;
uniform float inner = 0.38;
uniform float outer = 1.02;
uniform vec4 shadow : source_color = vec4(0.035, 0.02, 0.07, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV - 0.5;
	uv.x *= 640.0 / 360.0;
	float d = length(uv);
	float v = smoothstep(inner, outer, d);
	// Pixel-art banding: eight steps instead of a smooth ramp.
	v = floor(v * 8.0 + 0.5) / 8.0;
	COLOR = vec4(shadow.rgb, v * strength);
}
