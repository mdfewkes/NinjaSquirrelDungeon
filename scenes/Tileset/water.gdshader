shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture;
uniform sampler2D noise_texture: filter_nearest, repeat_enable;
uniform sampler2D noise2_texture: filter_nearest, repeat_enable;
uniform float distortion_amount = 0.06;
uniform float edge_distortion_amount = 0.06;
uniform float speed = 0.03;
uniform float opacity = 0.6;
uniform float lightness = 0.9;
uniform float outline_width = 2.0;
uniform vec4 outline_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);

// The size of each square cell normalized for uv
const float tile_size = 1.0 / 64.0;

const vec2[] outline_points = {
	vec2(-1.0, 0.0),
	vec2(1.0, 0.0),
	vec2(0.0, -1.0),
	vec2(0.0, 1.0)
};

vec2 get_cell_uv(vec2 uv, vec2 pixel_size) {
	vec2 ut = uv;
	ut.x = mod(1.0 - uv.x, pixel_size.x / tile_size) / pixel_size.x * tile_size;
	ut.y = mod(1.0 - uv.y, pixel_size.y / tile_size) / pixel_size.y * tile_size;
	return ut;
}

bool is_edge_point(vec2 uv, vec2 pixel_size) {
	return false;
}

bool is_edge(vec2 uv, vec2 pixel_size) {
	vec2 outline_w2 = outline_width * pixel_size;
	return true;
}

void fragment() {
	// The raw UV is within the whole tileset, not within a single tile
	vec2 cell_uv = get_cell_uv(UV, TEXTURE_PIXEL_SIZE);
	
	// create two secondary noise values to simulate the shifting currents
	vec2 noise_uv = cell_uv + sin(TIME * speed) * 2.0;
	vec2 noise_uv2 = cell_uv - sin(TIME * 1.5 * speed) * 8.0;
	vec2 noise = 2.0 * texture(noise2_texture, noise_uv).rg - 1.0;
	vec2 noise2 = 2.0 * texture(noise2_texture, noise_uv2).rg - 1.0;

	// pull the water color from the primary noise texture, altered by the secondary noise
	vec4 water_color = texture(noise_texture, cell_uv + noise * distortion_amount - noise2 * distortion_amount / 2.0);
	
	// the actual color is a blend of the underlying screen color (the tileset under the water) and the water, with the underwater portion also being distorted by the secondary noise
	COLOR = water_color * opacity + texture(screen_texture, SCREEN_UV - noise * distortion_amount / 2.0) * (1.0 - opacity);
	// we usually need to darken the blended color a little bit to make it look right
	COLOR *= lightness;

	// take the alpha value from the tile texture, so we can give firm edges to the water
	vec2 texture_uv = UV + noise2 * edge_distortion_amount;
	COLOR.a = texture(TEXTURE, texture_uv).a;
	
	// finally, if there's an outline, we check if the next pixel over would be transparent and use the outline color if so
	if (COLOR.a > 0.0 && outline_width > 0.0) {
		vec2 outline_w2 = outline_width * TEXTURE_PIXEL_SIZE;
		for (int i = 0; i < outline_points.length(); i++) {
			vec2 check_uv = texture_uv + outline_points[i] * outline_w2;
			if (
				check_uv.x >= 0.0 
				&& check_uv.x <= 1.0 
				&& check_uv.y >= 0.0 
				&& check_uv.y <= 1.0
				&& texture(TEXTURE, check_uv).a == 0.0
			) {
				COLOR = outline_color;
			}
		}
	}

	// add a normal so the lights interact with the water too
	NORMAL = 2.0 * texture(noise_texture, noise_uv).rgb - 1.0;
}

