//!HOOK MAIN
//!BIND HOOKED
//!DESC Clip Code Value (White Only)

vec4 color = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    return min(color, 1.0);
}
