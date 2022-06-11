//!HOOK MAIN
//!BIND HOOKED
//!DESC Linear Tone Mapping

float curve(float x) {
    const float WHITE = 203;
    const float PEAK  = 10000;
	return x * WHITE / PEAK;
}

vec3 mode_rgb(vec3 x) {
    return vec3(curve(x.r), curve(x.g), curve(x.b));
}

vec4 p = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    p.rgb = mode_rgb(p.rgb);
    return p;
}
