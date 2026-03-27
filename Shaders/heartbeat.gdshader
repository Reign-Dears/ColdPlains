shader_type canvas_item;

uniform float amount = 0.66;
uniform float value = 1.0;
uniform float rate = 4.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

vec2 fisheye(vec2 uv, float strength) {
    // Shift UV so center is (0,0)
    vec2 centered = uv * 2.0 - vec2(1.0, 1.0);

    // Radius from center
    float r = length(centered) / 2.0;

    // Apply distortion (strength > 0 exaggerates the fisheye)
    float distortedR = pow(r, 1.0 - strength);

    // Normalize direction
    vec2 direction = normalize(centered);

    // New coordinates
    vec2 distorted = direction * distortedR;

    // Shift back to 0..1 UV space
    //return (distorted + 1.0) * 0.5;
	return distorted;
}

void fragment() {
	vec3 col = texture(screen_texture, vec2(UV)).rgb;
	col.r = length(fisheye(UV, (pow(sin(TIME * rate), 8.0) + pow(sin((TIME + 0.25) * rate), 8.0)) * amount - 1.5)) / value + col.r;
	COLOR.rgb = col;
}
