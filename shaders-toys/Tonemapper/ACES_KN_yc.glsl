//!HOOK MAIN
//!BIND HOOKED
//!DESC Krzysztof Narkowicz's ACES Tone Mapping (Luminance proxy)

// ACES Filmic Tone Mapping Curve fit by Krzysztof Narkowicz.
// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
float curve(float x) {
    const float A = 2.51;
    const float B = 0.03;
    const float C = 2.43;
    const float D = 0.59;
    const float E = 0.14;
    return (x * (A * x + B)) / (x * (C * x + D) + E);
}

float yc(vec3 rgb) {
    // Converts RGB to a luminance proxy, here called YC
    // YC is ~ Y + K * Chroma
    // Constant YC is a cone-shaped surface in RGB space, with the tip on the
    // neutral axis, towards white.
    // YC is normalized: RGB 1 1 1 maps to YC = 1
    //
    // ycRadiusWeight defaults to 1.75, although can be overridden.
    // ycRadiusWeight = 1 -> YC for pure cyan, magenta, yellow == YC for neutral
    // of same value
    // ycRadiusWeight = 2 -> YC for pure red, green, blue == YC for neutral of
    // same value.

    const float r = rgb.r;
    const float g = rgb.g;
    const float b = rgb.b;
    const float ycRadiusWeight = 1.75;
    const float chroma = sqrt(b * (b - g) + g * (g - r) + r * (r - b));
    return (b + g + r + ycRadiusWeight * chroma) / 3;
}


vec3 mode_yc(vec3 x) {
    const float YC = yc(x);
    return x * curve(YC) / YC;
}

vec4 p = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    p.rgb = mode_yc(p.rgb * 0.6);
    return p;
}
