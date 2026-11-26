// Character light (fx_character, Grafik-Overhaul): a 1-px rim on the sprite edge that faces the strongest light, in
// that light's colour, plus a white hit flash. Works on every layer of the figure (body, weapon) and on the rig mesh;
// the offset is whole texels, so the rim is a crisp pixel line, not a soft glow.
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 u_step;     // texel offset towards the light (whole texels, already scaled by the texel size)
uniform vec4 u_rim;      // rim colour (rgb) and strength
uniform vec4 u_flash;    // flash colour (rgb) and amount

void main() {
    vec4 c = v_vColour * texture2D(gm_BaseTexture, v_vTexcoord);
    if (c.a > 0.5 && u_rim.a > 0.0) {
        float a1 = texture2D(gm_BaseTexture, v_vTexcoord + u_step).a;
        float a2 = texture2D(gm_BaseTexture, v_vTexcoord + u_step * 2.0).a;
        float edge = max(1.0 - step(0.5, a1), 0.45 * (1.0 - step(0.5, a2)));
        c.rgb += u_rim.rgb * edge * u_rim.a;
    }
    c.rgb = mix(c.rgb, u_flash.rgb, u_flash.a);
    gl_FragColor = c;
}
