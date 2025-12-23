shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture;
uniform sampler2D noise_texture: filter_nearest, repeat_enable;
uniform sampler2D noise2_texture: filter_nearest, repeat_enable;
uniform float distortion_amount = 0.06;
uniform float edge_distortion_amount = 0.06;
uniform float speed = 0.03;
uniform float opacity = 0.6;
uniform float lightness = 0.9;

// The size of each square cell normalized
// So if your cell is 8px by 8px the value should be 1.0 / 8.0
// if your cell is 16px by 16px the value should be 1.0 / 16.0
const float tile_size = 1.0 / 64.0;

vec2 get_cell_uv(vec2 uv, vec2 pixel_size) {
	vec2 ut = uv;
	ut.x = mod(1.0 - uv.x, pixel_size.x / tile_size) / pixel_size.x * tile_size;
	ut.y = mod(1.0 - uv.y, pixel_size.y / tile_size) / pixel_size.y * tile_size;
	return ut;
}

void fragment() {
	vec2 cell_uv = get_cell_uv(UV, TEXTURE_PIXEL_SIZE);
	//COLOR = vec4(cell_uv.x, cell_uv.y, 0.0, 1.0);
	vec2 noise_uv = UV + TIME * speed;
	vec2 noise_uv2 = SCREEN_UV - TIME * speed;
	vec2 noise = 2.0 * texture(noise2_texture, noise_uv).rg - 1.0;
	vec2 noise2 = 2.0 * texture(noise2_texture, noise_uv2).rg - 1.0;
	//vec2 noise2_uv = SCREEN_UV - TIME * speed;
	vec4 water_color = texture(noise_texture, cell_uv + noise * distortion_amount - noise2 * distortion_amount / 2.0);
	COLOR = water_color * opacity + texture(screen_texture, SCREEN_UV - noise * distortion_amount / 2.0) * (1.0 - opacity);
	COLOR *= lightness;
	COLOR.a = texture(TEXTURE, UV + noise2 * edge_distortion_amount).a;
	//COLOR = texture(TEXTURE, UV);
	//COLOR = texture(TEXTURE, mod(UV * 1.02 - 0.015 + noise * distortion_amount, 1.0));
	//COLOR *= texture(screen_texture, SCREEN_UV + noise * distortion_amount);
	//COLOR = texture(screen_texture, SCREEN_UV);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
