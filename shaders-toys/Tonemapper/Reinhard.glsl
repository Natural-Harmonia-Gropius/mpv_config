//!HOOK MAIN
//!BIND HOOKED
//!DESC Reinhard Tone Mapping

// "Extended Reinhard" described by Reinhard et al.
float reinhard(float x) {
    const float L_w = 4.0;
    return (x * (1.0 + x / (L_w * L_w))) / (1.0 + x);
}

vec4 p = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    const float L = dot(p.rgb, vec3(0.2627, 0.6780, 0.0593));
    p.rgb = p.rgb * reinhard(L) / L;
    return p;
}
