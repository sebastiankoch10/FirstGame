// Bloom source (render_fx): 4x downsample of the lit world with a soft-knee brightness threshold.
// Four bilinear taps at +-1 source texel average a 4x4 block, so single bright art pixels (sparks, embers) are never
// skipped by the downsample and do not flicker in the glow.
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 u_src_texel;   // 1 / source size
uniform vec3 u_thresh;      // threshold, knee, gain

void main() {
    vec2 o = u_src_texel;
    vec3 c = texture2D(gm_BaseTexture, v_vTexcoord + vec2(-o.x, -o.y)).rgb
           + texture2D(gm_BaseTexture, v_vTexcoord + vec2( o.x, -o.y)).rgb
           + texture2D(gm_BaseTexture, v_vTexcoord + vec2(-o.x,  o.y)).rgb
           + texture2D(gm_BaseTexture, v_vTexcoord + vec2( o.x,  o.y)).rgb;
    c *= 0.25;
    float l = max(c.r, max(c.g, c.b));
    float knee = max(u_thresh.y, 0.0001);
    float soft = clamp(l - u_thresh.x + knee, 0.0, 2.0 * knee);
    soft = soft * soft / (4.0 * knee);
    float w = max(soft, l - u_thresh.x) / max(l, 0.0001);
    gl_FragColor = vec4(c * w * u_thresh.z, 1.0);
}
