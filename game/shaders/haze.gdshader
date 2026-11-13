shader_type canvas_item;
// A band of haze laid along a parallax layer's crown line, so the distant trees
// rise into mist instead of ending at an edge. Thickest at `peak` (0 = the band's
// top, 1 = its bottom), thinning to nothing at both edges, broken up by slow
// drifting noise and quantised into a few levels so it reads as painted.
// Keep `scale.x` a whole number when the layer repeats, so the noise tiles.
render_mode unshaded;

uniform sampler2D noise : repeat_enable, filter_linear;
uniform vec4 tint : source_color = vec4(0.29, 0.25, 0.4, 1.0);
uniform float density = 0.85;
uniform float peak = 0.4;
uniform vec2 drift = vec2(0.003, 0.0);
uniform vec2 scale = vec2(2.0, 0.5);
uniform float levels = 6.0;

void fragment() {
	vec2 uv = UV * scale + drift * TIME;
	float n = texture(noise, uv).r * 0.6 + texture(noise, uv * 2.0 + vec2(0.31, 0.67) - drift * TIME * 0.5).r * 0.4;
	float body = smoothstep(0.0, peak, UV.y) * (1.0 - smoothstep(peak, 1.0, UV.y));
	float a = clamp(body * mix(0.6, 1.25, n) * density, 0.0, 1.0);
	a = floor(a * levels + 0.5) / levels;
	COLOR = vec4(tint.rgb, a);
}
