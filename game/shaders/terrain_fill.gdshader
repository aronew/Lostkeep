shader_type canvas_item;
// The inside of every solid mass: the material's fill texture, fading to the
// void with distance from open air, in stepped bands like hand-placed pixels.
// `cells` holds one texel per tile: R = distance to open air (tiles / 32),
// G = material index / 8, A = 1 where the skin paints this cell.

uniform sampler2D cells : filter_linear, repeat_disable;
uniform sampler2D fill0 : filter_nearest, repeat_enable;
uniform sampler2D fill1 : filter_nearest, repeat_enable;
uniform vec2 origin_cell = vec2(0.0);
uniform vec2 size_cells = vec2(1.0);
uniform float fade0 = 3.0;
uniform float fade1 = 3.0;
uniform float steps = 5.0;
uniform vec4 void_color : source_color = vec4(0.043, 0.031, 0.071, 1.0);

varying vec2 world_px;

void vertex() {
	world_px = VERTEX;
}

void fragment() {
	vec2 cellf = world_px / 16.0 - origin_cell;
	vec4 c = texelFetch(cells, ivec2(floor(cellf)), 0);
	if (c.a < 0.5) {
		discard;
	}
	// Distance, interpolated between tile centres for a smooth falloff.
	float d = texture(cells, cellf / size_cells).r * 32.0;
	// Each step of the fade follows the masonry, not the tile rows: the distance
	// is nudged per block (8 x 4 px), so a step's edge is ragged along the
	// blocks instead of a straight line across a slab (the creative lead: "a
	// hard cut line ... doesn't look natural").
	float j = fract(sin(dot(floor(world_px / vec2(8.0, 4.0)), vec2(12.9898, 78.233))) * 43758.5453);
	d += (j - 0.5) * 0.9;
	bool stone = c.g > 0.06;
	vec3 base = stone
		? texture(fill1, world_px / vec2(textureSize(fill1, 0))).rgb
		: texture(fill0, world_px / vec2(textureSize(fill0, 0))).rgb;
	float fade = stone ? fade1 : fade0;
	// A fade of 0 paints the whole inside as the void: only the bands show.
	float k = fade > 0.0 ? clamp(1.0 - (d - 0.6) / fade, 0.0, 1.0) : 0.0;
	k = floor(k * steps + 0.5) / steps;
	COLOR = vec4(mix(void_color.rgb, base, k), 1.0);
}
