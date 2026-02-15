shader_type spatial;

uniform sampler2D noise;

void vertex() {
	// Called for every vertex the material is visible on
	float wobble = 0.4 * sin(VERTEX.x * 1.0 + TIME) * sin(VERTEX.z * 0.7 - 0.7 * TIME);
	wobble += 0.5 * sin(VERTEX.x * 0.3 + 0.6 * TIME) * sin(VERTEX.z * 0.5 + 0.5 * TIME);
	wobble += 0.1 * sin(VERTEX.x * 1.7 - 2.0 * TIME) * sin(VERTEX.z * 1.8 + 2.7 * TIME);
	wobble += 0.05 * sin(VERTEX.x * 3.1 - 2.2 * TIME) * sin(VERTEX.z * 2.8 - 2.7 * TIME);
	
	//VERTEX.y += 0.4 * sin(VERTEX.x * 1.0 + TIME) * sin(VERTEX.z * 0.7 - 0.7 * TIME);
	//VERTEX.y += 0.5 * sin(VERTEX.x * 0.3 + 0.6 * TIME) * sin(VERTEX.z * 0.5 + 0.5 * TIME);
	//VERTEX.y += 0.1 * sin(VERTEX.x * 1.7 - 2.0 * TIME) * sin(VERTEX.z * 1.8 + 2.7 * TIME);
	//VERTEX.y += 0.05 * sin(VERTEX.x * 3.1 - 2.2 * TIME) * sin(VERTEX.z * 2.8 - 2.7 * TIME);
	
	VERTEX.y += wobble * 1.0;
}

void fragment() {
	// Called for every pixel the material is visible on.
	NORMAL_MAP = texture(noise, VERTEX.xz).xyz;
	
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
