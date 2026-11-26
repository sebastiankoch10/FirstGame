// Separable 9-tap Gaussian (5 bilinear taps) for the glow and depth-of-field layers (render_fx).
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 u_dir;   // texel step along the blur axis (1/size on one axis, 0 on the other), times spread

void main() {
    vec3 c = texture2D(gm_BaseTexture, v_vTexcoord).rgb * 0.2270270;
    c += texture2D(gm_BaseTexture, v_vTexcoord + u_dir * 1.3846154).rgb * 0.3162162;
    c += texture2D(gm_BaseTexture, v_vTexcoord - u_dir * 1.3846154).rgb * 0.3162162;
    c += texture2D(gm_BaseTexture, v_vTexcoord + u_dir * 3.2307692).rgb * 0.0702703;
    c += texture2D(gm_BaseTexture, v_vTexcoord - u_dir * 3.2307692).rgb * 0.0702703;
    gl_FragColor = vec4(c, 1.0);
}
