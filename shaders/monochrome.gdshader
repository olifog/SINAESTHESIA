shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform float brightness_threshold : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    // Calculate brightness using standard luminance weights
    float brightness = dot(texture_color.rgb, vec3(0.299, 0.587, 0.114));

    // If brightness is above threshold and pixel has opacity, make it fully tinted
    // Otherwise, make it fully transparent
    COLOR = (brightness > brightness_threshold && texture_color.a > 0.0)
        ? vec4(tint_color.rgb, 1.0)
        : vec4(0.0, 0.0, 0.0, 0.0);
}