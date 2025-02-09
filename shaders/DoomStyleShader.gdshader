shader_type canvas_item;

uniform float new_pixel_size = 32.0;
// If you intend to read from mipmaps with `textureLod()` LOD values greater than `0.0`,
// use `filter_nearest_mipmap` instead. This shader doesn't require it.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
		vec2 conversion = new_pixel_size * SCREEN_PIXEL_SIZE;
        vec2 new_uv = floor(UV / conversion) * conversion;
        COLOR = textureLod(screen_texture, new_uv, 0.0);
}