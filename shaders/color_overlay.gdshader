shader_type canvas_item;

uniform vec4 overlay_color : source_color = vec4(1.0, 0.0, 0.0, 0.02);

void fragment() {
    vec4 screen_color = texture(TEXTURE, UV);
    COLOR = mix(screen_color, overlay_color, 0.9);
} 