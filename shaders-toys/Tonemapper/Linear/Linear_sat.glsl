//!HOOK MAIN
//!BIND HOOKED
//!DESC Linear Tone Mapping (Saturate)

float curve(float x) {
    const float WHITE = 203;
    const float PEAK  = 10000;
	return x * WHITE / PEAK;
}

float y(vec3 x) {
    // https://en.wikipedia.org/wiki/Relative_luminance
    return dot(x, vec3(0.2627, 0.6780, 0.0593));
}

vec3 mode_sat(vec3 x) {
    const float S = 1.25;  // Saturation
    const float Y = y(x);
    return max((x - Y) * S + Y, 0.0);
}

vec4 p = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    p.rgb = mode_sat(p.rgb);
    return p;
}
