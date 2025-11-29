shader_type canvas_item;

uniform int point_count = 8;
uniform vec3 points[8];  // xy = position, z = radius

// https://github.com/marklundin/glsl-sdf-primitives/blob/master/sdCapsule.glsl
float sd_capsule(vec2 p, vec2 a, vec2 b, float ra, float rb) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	float r = mix(ra, rb, h);
	return length(pa - ba * h) - r;
}

// quadratic polynomial smooth minimum https://iquilezles.org/articles/smin/
float smin(float a, float b, float k) {
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h * (1.0 - h);
}

void fragment() {
	float dist = 1.5;
	for (int i = 0; i < point_count - 1; i++) {
		float capsule_dist = sd_capsule(UV, points[i].xy, points[i + 1].xy, points[i].z, points[i + 1].z);
		dist = smin(dist, capsule_dist, 0.01);
	}

	// fuzzy tail style
	vec3 tail_color = vec3(smoothstep(0.01, -0.01, dist), 0, 0);
	COLOR = vec4(tail_color, smoothstep(0.03, -0.03, dist));

	// clear cut tail style
	//vec3 tail_color = vec3(1. - step(0.01, dist), 0, 0);
	//COLOR = vec4(tail_color, 1. - step(0.03, dist));
}