shader_type canvas_item;
// A foreground silhouette: the texture's outline filled with one flat, near-void
// colour, with a one-pixel cool rim along its upper edges, as if backlit by the
// moonlight above, so the shape still reads where it stands in front of black
// rock. Unshaded, so lanterns never light what stands between them and the
// camera; hard-edged, so the pixel outline stays crisp.
render_mode unshaded;

uniform vec4 color : source_color = vec4(0.027, 0.02, 0.043, 1.0);
uniform vec4 rim : source_color = vec4(0.15, 0.13, 0.23, 1.0);

void fragment() {
	float a = step(0.5, texture(TEXTURE, UV).a);
	float above = step(0.5, texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a);
	vec3 c = above < 0.5 ? rim.rgb : color.rgb;
	COLOR = vec4(c, a * color.a);
}
