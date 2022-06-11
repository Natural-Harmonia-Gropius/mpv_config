//!HOOK MAIN
//!BIND HOOKED
//!DESC Clip Code Value

// Handle out-of-gamut values
// Clip values < 0 or > 1 (i.e. projecting outside the display primaries)
vec4 color = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    return clamp(color, 0.0, 1.0);
}
