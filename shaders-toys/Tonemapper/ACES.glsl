//!HOOK MAIN
//!BIND HOOKED
//!DESC WIP: ACES Filmic Tone Mapping (RRTODT)

vec3 RGB_to_XYZ(vec3 RGB) {
    const mat3 M = mat3(
        0.6370, 0.1446, 0.1689,
        0.2627, 0.6780, 0.0593,
        0.0000, 0.0281, 1.0610);
    return M * RGB;
}

vec3 XYZ_to_RGB(vec3 XYZ) {
    const mat3 M = mat3(
         1.7167, -0.3557, -0.2534,
        -0.6667,  1.6165,  0.0158,
         0.0176, -0.0428,  0.9421);
    return M * XYZ;
}

// Transformations between CIE XYZ tristimulus values and CIE x,y
// chromaticity coordinates
vec3 XYZ_to_xyY(vec3 XYZ) {
    float divisor = (XYZ.x + XYZ.y + XYZ.z);
    if (divisor == 0) divisor = 1e-10;

    const float x = XYZ.x / divisor;
    const float y = XYZ.y / divisor;
    const float Y = XYZ.y;

    return vec3(x, y, Y);
}

vec3 xyY_to_XYZ(vec3 xyY) {
    const float x = xyY[0];
    const float y = xyY[1];
    const float Y = xyY[2];

    const float X = x * Y / max(y, 1e-10);
    const float Z = (1.0 - x - y) * Y / max(y, 1e-10);

    return vec3(X, Y, Z);
}

float aces(float x) {
    const float A = 2.51;
    const float B = 0.03;
    const float C = 2.43;
    const float D = 0.59;
    const float E = 0.14;
    return (x * (A * x + B)) / (x * (C * x + D) + E);
}

vec4 color = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    color.xyz = RGB_to_XYZ(color.rgb);
    color.xyz = XYZ_to_xyY(color.xyz);
    color.z   = aces(color.z);
    color.xyz = xyY_to_XYZ(color.xyz);
    color.rgb = XYZ_to_RGB(color.xyz);
    return color;
}

const mat3 REC2020_PRI = mat3(
    0.70800,  0.29200,
    0.17000,  0.79700,
    0.13100,  0.04600
);

const mat3 REC709_PRI = mat3(
    0.64000,  0.33000,
    0.30000,  0.60000,
    0.15000,  0.06000
);


vec4 color = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    vec3 linearCV = color.rgb;


    const Chromaticities DISPLAY_PRI = REC709_PRI;
    const float XYZ_2_DISPLAY_PRI_MAT[4][4] = XYZtoRGB(DISPLAY_PRI,1.0);

    const mat4 DISPLAY_PRI_2_XYZ_MAT = RGBtoXYZ(DISPLAY_PRI, 1.0);

    // Convert from display primary encoding
    // Display primaries to CIE XYZ
    vec3 XYZ = mult_f3_f44( linearCV, DISPLAY_PRI_2_XYZ_MAT);

    // CIE XYZ to rendering space RGB
    linearCV = mult_f3_f44( XYZ, XYZ_2_AP1_MAT);

    // Undo desaturation to compensate for luminance difference
    linearCV = mult_f3_f33( linearCV, invert_f33( ODT_SAT_MAT));




    // Apply desaturation to compensate for luminance difference
    linearCV = mult_f3_f33( linearCV, ODT_SAT_MAT);

    // Convert to display primary encoding
    // Rendering space RGB to XYZ
    vec3 XYZ = mult_f3_f44( linearCV, AP1_2_XYZ_MAT);

    // CIE XYZ to display primaries
    linearCV = mult_f3_f44( XYZ, XYZ_2_DISPLAY_PRI_MAT);

    // Handle out-of-gamut values
    // Clip values < 0 or > 1 (i.e. projecting outside the display primaries)
    linearCV = clamp_f3( linearCV, 0., 1.);

    color.rgb = linearCV;
    return color;
}
