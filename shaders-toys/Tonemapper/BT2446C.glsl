//!HOOK MAIN
//!BIND HOOKED
//!DESC ITU-R BT.2446 Conversion Method C

vec3 RGB_to_XYZ(float R, float G, float B) {
    mat3 M = mat3(
        0.6370, 0.1446, 0.1689,
        0.2627, 0.6780, 0.0593,
        0.0000, 0.0281, 1.0610);
    return M * vec3(R, G, B);
}

vec3 XYZ_to_RGB(float X, float Y, float Z) {
    mat3 M = mat3(
         1.7167, -0.3557, -0.2534,
        -0.6667,  1.6165,  0.0158,
         0.0176, -0.0428,  0.9421);
    return M * vec3(X, Y, Z);
}

vec3 XYZ_to_xyY(float X, float Y, float Z) {
    float divisor = X + Y + Z;
    if (divisor == 0.0) divisor = 1e-10;

    float x = X / divisor;
    float y = Y / divisor;

    return vec3(x, y, Y);
}

vec3 xyY_to_XYZ(float x, float y, float Y) {
    float X = x * Y / max(y, 1e-10);
    float Z = (1.0 - x - y) * Y / max(y, 1e-10);

    return vec3(X, Y, Z);
}

float Xn = 192.93;
float Yn = 203.0;
float Zn = 221.05;
float delta = 6.0 / 29.0;
float deltac = delta * 2.0 / 3.0;

// float f1(float x, float delta) { return x > pow(delta, 3.0) ? pow(x, 1.0 / 3.0) : pow(1.0 / delta, 3.0) * x; }
float f1(float x, float delta) { return x > pow(delta, 3.0) ? pow(x, 1.0 / 3.0) : deltac + x / (3.0 * pow(delta, 2.0)); }
float f2(float x, float delta) { return x > delta ? pow(x, 3.0) : (x - deltac) * (3.0 * pow(delta, 2.0)); }

vec3 XYZ_to_Lab(float X, float Y, float Z) {
    X = f1(X / Xn, delta);
    Y = f1(Y / Yn, delta);
    Z = f1(Z / Zn, delta);

    float L = 116.0 * Y - 16.0;
    float a = 500.0 * (X - Y);
    float b = 200.0 * (Y - Z);

    L = max(L, 0.0);

    return vec3(L, a, b);
}

vec3 Lab_to_XYZ(float L, float a, float b) {
    float Y = (L + 16.0) / 116.0;
    float X = Y + a / 500.0;
    float Z = Y - b / 200.0;

    X = f2(X, delta) * Xn;
    Y = f2(Y, delta) * Yn;
    Z = f2(Z, delta) * Zn;

    return vec3(X, Y, Z);
}

vec3 Lab_to_LCHab(float L, float a, float b) {
    float C = sqrt(pow(a, 2.0) + pow(b, 2.0));
    float H = atan(b, a);

    return vec3(L, C, H);
}

vec3 LCHab_to_Lab(float L, float C, float H) {
    float a = C * cos(H);
    float b = C * sin(H);

    return vec3(L, a, b);
}

vec3 crosstalk(vec3 x, float a) {
    float b = 1.0 - 2.0 * a;
    mat3  M = mat3(
        b, a, a,
        a, b, a,
        a, a, b);
    return M * x;
}

vec3 crosstalk_inv(vec3 x, float a) {
    float b = 1.0 - a;
    float c = 1.0 - 3.0 * a;
    mat3  M = mat3(
         b, -a, -a,
        -a,  b, -a,
        -a, -a,  b) / c;
    return M * x;
}

vec3 chroma_correction(float L, float C, float H, float Lref, float Lmax, float sigma) {
    if (L > Lref)
        C *= 1.0 - sigma * (L - Lref) / (Lmax - Lref);
        C = max(C, 0.0);

    return vec3(L, C, H);
}

float tone_mapping(float Y, float k1, float k3, float ip) {
    ip /= k1;
    float k2 = (k1 * ip) * (1.0 - k3);
    float k4 = (k1 * ip) - (k2 * log(1.0 - k3));
    return Y < ip ? Y * k1 : log((Y / ip) - k3) * k2 + k4;
}

vec4 p = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    p.rgb = crosstalk(p.rgb, 0.05);
    p.rgb = RGB_to_XYZ(p.r, p.g, p.b);
    p.rgb = XYZ_to_Lab(p.r, p.g, p.b);
    p.rgb = Lab_to_LCHab(p.r, p.g, p.b);
    // p.rgb = chroma_correction(p.r, p.g, p.b, 69.46953, 100.0, 0.1);  // greenish
    p.rgb = LCHab_to_Lab(p.r, p.g, p.b);
    p.rgb = Lab_to_XYZ(p.r, p.g, p.b);
    p.rgb = XYZ_to_xyY(p.r, p.g, p.b);
    p.z   = tone_mapping(p.z, 0.83802, 0.74204, 58.5);
    p.rgb = xyY_to_XYZ(p.r, p.g, p.b);
    p.rgb = XYZ_to_RGB(p.r, p.g, p.b);
    p.rgb = crosstalk_inv(p.rgb, 0.05);
    return p;
}
