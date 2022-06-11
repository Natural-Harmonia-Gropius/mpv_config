//!HOOK MAIN
//!BIND HOOKED
//!DESC linear Code Value to cd/m^2

const float L_WHITE = 203.0;
const float L_BLACK = 0.0;
// Scale linear code value to cd/m^2
vec3 linCV_2_Y(vec3 linCV, float Ymax, float Ymin) {
    return linCV * (Ymax - Ymin) + Ymin;
}

vec4 color = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    color.rgb = linCV_2_Y(color.rgb, L_WHITE, L_BLACK);
    return color;
}
