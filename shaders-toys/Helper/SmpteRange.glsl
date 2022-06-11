//!HOOK OUTPUT
//!BIND HOOKED
//!DESC signal range scaling

// SMPTE "legal" signal range
vec4 color = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    const float REFBLACK =   64.0 / 1023.0;
    const float REFWHITE =  940.0 / 1023.0;

    color.rgb *= REFWHITE - REFBLACK;
    color.rgb += REFBLACK;
    return color;
}
