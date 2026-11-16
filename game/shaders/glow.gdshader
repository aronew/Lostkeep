shader_type canvas_item;
render_mode blend_add, unshaded;
// A flame's glow in the air: a soft disc, added over the scene. The falloff
// is computed here and dithered by one 8-bit step before it is written, so
// the faint outer part never breaks into rings.

uniform vec4 tint : source_color = vec4(0.95, 0.55, 0.22, 0.3);
uniform float falloff = 2.2;

float bayer(vec2 p) {
	ivec2 i = ivec2(mod(p, 4.0));
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i.x + i.y * 4]) + 0.5) / 16.0;
}

void fragment() {
	float d = clamp(1.0 - length(UV - vec2(0.5)) * 2.0, 0.0, 1.0);
	float a = pow(d, falloff) * tint.a;
	vec3 c = tint.rgb * a;
	// The scene is darkened after this (CanvasModulate), so dither by a little
	// more than one step.
	c += (bayer(FRAGCOORD.xy) - 0.5) * (2.5 / 255.0) * step(0.001, a);
	COLOR = vec4(max(c, vec3(0.0)), 1.0);
}
