//!HOOK MAIN
//!BIND HOOKED
//!DESC Clip Code Value (Black Only)

vec4 color = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    return max(color, 0.0);
}
