shader_type canvas_item;
// Drifting fog: scrolling noise, thicker toward the bottom of the band,
// quantised into a few levels so it reads as painted haze.
render_mode unshaded;

uniform sampler2D noise : repeat_enable, filter_linear;
uniform vec4 tint : source_color = vec4(0.42, 0.62, 0.64, 1.0);
uniform float density = 0.3;
uniform vec2 drift = vec2(0.006, 0.0);
uniform vec2 scale = vec2(1.0, 1.0);
uniform float levels = 5.0;
// Fades the band's left and right ends over this share of its width (0: none).
uniform float side_fade = 0.0;

void fragment() {
	vec2 uv = UV * scale + drift * TIME;
	float n = texture(noise, uv).r * 0.65 + texture(noise, uv * 2.3 + vec2(0.37, 0.11) - drift * TIME * 0.6).r * 0.35;
	float body = smoothstep(0.0, 0.55, UV.y) * (1.0 - smoothstep(0.85, 1.0, UV.y));
	float a = clamp((n - 0.35) * 1.8, 0.0, 1.0) * body * density;
	if (side_fade > 0.0) {
		a *= smoothstep(0.0, side_fade, UV.x) * smoothstep(0.0, side_fade, 1.0 - UV.x);
	}
	a = floor(a * levels * 4.0 + 0.5) / (levels * 4.0);
	COLOR = vec4(tint.rgb, a);
}
