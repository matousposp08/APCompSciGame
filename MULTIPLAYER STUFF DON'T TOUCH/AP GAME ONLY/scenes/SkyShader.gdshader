shader_type sky;

uniform vec3 skyColor : source_color;

void sky() {
	// Called for every visible pixel in the sky background, as well as all pixels
	// in the radiance cubemap.
	COLOR = skyColor;
}
