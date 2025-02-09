shader_type spatial;

uniform sampler2D TEXTURE;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	float SCREEN_PIXEL_SIZE = fwidth(VERTEX.x);
	ALBEDO = (texture(TEXTURE, UV).rgb + texture(TEXTURE, UV + SCREEN_PIXEL_SIZE).rgb + texture(TEXTURE, UV - SCREEN_PIXEL_SIZE).rgb) / 3.0;
	vec4 diff =  texture(TEXTURE, UV + SCREEN_PIXEL_SIZE) - texture(TEXTURE, UV - SCREEN_PIXEL_SIZE);
	float THRESHOLD = 0.01f;
	if ((diff.x) * (diff.x) + (diff.y) * (diff.y) > THRESHOLD) {
		ALBEDO += vec3(0.5f, 0.5f, 0.5f);
	}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
