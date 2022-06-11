//!HOOK MAIN
//!BIND HOOKED
//!DESC Hable Tone Mapping

// Uncharted 2 devised by John Hable.
// sometimes known as 'Hable Tone Mapping' or 'Hable Filmic' etc.
// http://filmicgames.com/archives/75
float hablef(float x) {
    const float A = 0.15;   // Shoulder Strength
    const float B = 0.50;   // Linear Strength
    const float C = 0.10;   // Linear Angle
    const float D = 0.20;   // Toe Strength
    const float E = 0.02;   // Toe Numerator
    const float F = 0.30;   // Toe Denominator
    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

float hable(float x) {
    const float W = 11.2;
    return hablef(x) / hablef(W);
}

vec4 p = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    const float L = dot(p.rgb, vec3(0.2627, 0.6780, 0.0593));
    p.rgb = p.rgb * hable(L) / L;
    return p;
}
