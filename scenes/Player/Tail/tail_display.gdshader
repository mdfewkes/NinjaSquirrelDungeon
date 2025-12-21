shader_type canvas_item;

const int TAIL_POINTS_COUNT = 8;
const int TAIL_SEGMENT_COUNT = TAIL_POINTS_COUNT - 1;

uniform float tail_color_threshold : hint_range(-0.1, 0.25) = 0.01;
uniform float tail_color2_threshold : hint_range(-0.1, 0.25) = 0.01;
uniform float tail_outline_threshold : hint_range(0.0, 0.25) = 0.03;
uniform bool smooth_tail = false;
uniform sampler2D tail_color_lookup; // Color lookup, but can also be used to animate later
uniform sampler2D cloaked_color_lookup; // Color lookup, but can also be used to animate later
uniform float cloaked_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 points[TAIL_POINTS_COUNT];  // xy = position, z = radius

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
	float distance_to_point[TAIL_POINTS_COUNT] = float[TAIL_POINTS_COUNT](100., 100., 100., 100., 100., 100., 100., 100.); // distances to the two closest segments
	for (int i = 0; i < TAIL_SEGMENT_COUNT; i++) {
		float capsule_distance = sd_capsule(UV, points[i].xy, points[i + 1].xy, points[i].z, points[i + 1].z);
		dist = smin(dist, capsule_distance, 0.01);

		// Calculate the distance from each point in the capsule
		distance_to_point[i] = length(points[i].xy - UV);
	}
	distance_to_point[TAIL_POINTS_COUNT - 1] = length(points[TAIL_POINTS_COUNT - 1].xy - UV);

	// Calculate the current points position in the tail_color_lookup texture
	// Map the segment index values to 0..1
	float sum_all_distances = 0.;
	for (int i = 0; i < TAIL_POINTS_COUNT; i++) {
		sum_all_distances += distance_to_point[i];
	}
	for (int i = 0; i < TAIL_POINTS_COUNT; i++) {
		distance_to_point[i] = distance_to_point[i] / sum_all_distances;
	}
	float x_position_in_lookup = 0.;
	for (int i = 0; i < TAIL_POINTS_COUNT; i++) {
		x_position_in_lookup += float(i)/float(TAIL_POINTS_COUNT) * distance_to_point[i];
	}

	// tail color
	vec3 tail_color;
	if(smooth_tail) {
		tail_color = texture(tail_color_lookup, vec2(x_position_in_lookup, 0.5)).rgb * smoothstep(tail_color_threshold, -tail_color_threshold, dist);
	} else {
		// tail_color = texture(tail_color_lookup, vec2(x_position_in_lookup, 0.5)).rgb * step(tail_color_threshold, dist);
		tail_color = texture(tail_color_lookup, vec2(x_position_in_lookup, 0.5)).rgb;
		vec3 tail_color2 = texture(tail_color_lookup, vec2(0.0, 0.5)).rgb;

		if (cloaked_amount > 0.0) {
			vec3 tail_color3 = texture(cloaked_color_lookup, vec2(x_position_in_lookup, 0.5)).rgb;
			vec3 tail_color4 = texture(cloaked_color_lookup, vec2(0.0, 0.5)).rgb;
			tail_color = mix(tail_color, tail_color3, cloaked_amount);
			tail_color2 = mix(tail_color2, tail_color4, cloaked_amount);
		}

		vec3 outline_color = vec3(0., 0., 0.);
		if (tail_color2_threshold > 0. && dist < tail_color2_threshold) {
			// this is some bs math but it ended up being pretty...
			tail_color = mix(tail_color2, tail_color, (tail_outline_threshold - dist) / (tail_color2_threshold - tail_outline_threshold));
		}
		if (-dist < tail_outline_threshold) {
			tail_color = outline_color;
		}
	}
	COLOR = vec4(tail_color, smoothstep(tail_outline_threshold, -tail_outline_threshold, dist));
}