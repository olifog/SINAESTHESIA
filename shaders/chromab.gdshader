shader_type canvas_item;

uniform float grainIntensity = 0.01;
// If you intend to read from mipmaps with `textureLod()` LOD values greater than `0.0`,
// use `filter_nearest_mipmap` instead. This shader doesn't require it.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

float random(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
		// Chromatic Aberration
		COLOR.r = textureLod(screen_texture, UV + sin(6.28 * TIME) * SCREEN_PIXEL_SIZE * 2.0, 0.0).r;
		COLOR.g = textureLod(screen_texture, UV + sin(6.27 * TIME + 1.5) * SCREEN_PIXEL_SIZE * 2.0, 0.0).g;
		COLOR.b = textureLod(screen_texture, UV + sin(6.29 * TIME + 3.0) * SCREEN_PIXEL_SIZE * 2.0, 0.0).b;

		float dist = length(UV - vec2(0.5)); // Distance from center
		float vignette = smoothstep(1.0, 0.1, dist); // Smooth fade
		COLOR.rgb *= vignette;

		// Generate noise and apply it to the color to simulate grain
	    //float grain = noise(UV * 10.0 + floor(sin(1.0 * TIME) * 10.0)/10.0); // Adjust noise scale and animation speed
	    //grain = (grain - 0.5) * grainIntensity; // Adjust the grain intensity

	    // Add the grain effect to the color
	    // COLOR.rgb += grain;
}