//!HOOK MAIN
//!BIND HOOKED
//!DESC Adjust Exposure

// Adjusts the linear code value by exposure.
vec4 color = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    const float exposure = 2.03;
    color.rgb *= exposure;
    return color;
}
