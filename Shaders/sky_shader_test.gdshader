shader_type sky;
render_mode use_half_res_pass;
uniform sampler2D noise;



vec4 generate_clouds(vec3 eyedir, vec2 coords) {
	float angle = coords.y;
	float noisepos = pow(angle, 2);
	float noisestat = pow(texture(noise, coords*3.0).x, 2.0);
	float noisemob = pow(texture(noise, coords*0.5 + vec2(TIME/200.0)).x, 0.5)/2.5;
	float skynoise = (noisestat + noisemob - 0.3) / 1.0;
	return vec4(1.0+noisemob, 0.8, 1, pow(skynoise, 1.0));
}

vec3 generate_sky(vec3 eyedir, vec2 coords) {
	vec3 grad = vec3(0.2 - coords.y/5.0);
	return vec3(0, 0, 0.01) - grad/15.0;
}

void sky() {
    if (AT_HALF_RES_PASS) {
        // Run cloud calculation for 1/4 of the pixels
        vec4 color = generate_clouds(EYEDIR, SKY_COORDS);
        COLOR = color.rgb;
        ALPHA = color.a;
    } else {
        // At full resolution pass, blend sky and clouds together
        vec3 color = generate_sky(EYEDIR, SKY_COORDS);
        COLOR = color + HALF_RES_COLOR.rgb * HALF_RES_COLOR.a;
    }
}