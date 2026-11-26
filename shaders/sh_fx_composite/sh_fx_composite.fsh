// World composite (render_fx, docs/Design/Visuelles Leitbild & Animation.md 4.3): runs once per frame on the lit world
// layer only. Enemy warnings and hazards are drawn after this pass and are never blurred, tinted or distorted.
// Order: distortion (heat shimmer, shock rings) -> chromatic offset -> depth of field -> glow -> grading -> vignette.
// The world texture is sampled with nearest filtering, so distortion moves whole art pixels (stays on the grid);
// glow and depth of field are the soft light layer.
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform sampler2D u_bloom;   // 1/4 resolution glow
uniform sampler2D u_bloom2;  // 1/8 resolution wide glow
uniform sampler2D u_soft;    // 1/2 resolution blurred world (depth of field)
uniform sampler2D u_heat;    // 1/2 resolution heat mask (red channel)
uniform sampler2D u_keep;    // 1/2 resolution keep-sharp mask (red channel): enemies and bosses stay sharp and unvignetted

uniform vec2 u_res;          // world surface size in pixels
uniform float u_time;
uniform vec3 u_bloom_k;      // near glow, wide glow, overall
uniform vec3 u_lift;
uniform vec3 u_gamma;
uniform vec3 u_gain;
uniform vec4 u_grade;        // saturation, contrast, vignette strength, vignette start radius
uniform vec4 u_tint;         // scene colour shift (rgb, amount) for big attacks
uniform vec4 u_dof;          // focus y (uv), sharp half band (uv), ramp (uv), strength
uniform vec2 u_fx;           // heat amplitude (px), chromatic offset (px)
uniform vec4 u_shock[4];     // shock rings: centre (uv), radius (px), strength (px)
uniform float u_shock_w;     // ring width (px)

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void main() {
    vec2 uv = v_vTexcoord;
    vec2 px = uv * u_res;
    vec2 off = vec2(0.0);
    // heat shimmer: rising, wavering offset where effects marked heat (fire breath, embers fields)
    float heat = texture2D(u_heat, uv).r;
    if (heat > 0.003) {
        vec2 q = floor(px / 3.0);
        float n1 = noise(q * 0.35 + vec2(0.0, u_time * 2.6));
        float n2 = noise(q * 0.35 + vec2(19.7, u_time * 3.1));
        off += (vec2(n1, n2) - 0.5) * 2.0 * heat * u_fx.x;
    }
    // shock rings: a thin band pushes pixels outward
    for (int i = 0; i < 4; i++) {
        vec4 s = u_shock[i];
        if (s.w > 0.0) {
            vec2 d = px - s.xy * u_res;
            float r = length(d);
            float band = 1.0 - clamp(abs(r - s.z) / u_shock_w, 0.0, 1.0);
            if (band > 0.0 && r > 0.5) off += d / r * band * band * s.w;
        }
    }
    vec2 suv = (floor(px + off) + 0.5) / u_res;
    vec3 sharp;
    if (u_fx.y > 0.0) {
        vec2 dir = (uv - 0.5) * u_fx.y * 2.0 / u_res;
        sharp = vec3(texture2D(gm_BaseTexture, suv + dir).r, texture2D(gm_BaseTexture, suv).g, texture2D(gm_BaseTexture, suv - dir).b);
    } else sharp = texture2D(gm_BaseTexture, suv).rgb;
    // depth of field: sharp band around the focus height, soft towards top and bottom edges (tilt shift)
    float dy = abs(uv.y - u_dof.x);
    float keep = texture2D(u_keep, uv).r;
    float m = smoothstep(u_dof.y, u_dof.y + u_dof.z, dy) * u_dof.w * (1.0 - keep);
    vec3 c = mix(sharp, texture2D(u_soft, uv).rgb, m);
    // glow of bright cores (fire, magic, lamps)
    c += (texture2D(u_bloom, uv).rgb * u_bloom_k.x + texture2D(u_bloom2, uv).rgb * u_bloom_k.y) * u_bloom_k.z;
    vec3 pre = c;
    // grading: lift / gamma / gain, saturation, contrast
    c = u_gain * (c + u_lift * (1.0 - c));
    c = pow(max(c, vec3(0.0)), 1.0 / u_gamma);
    float l = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(l), c, u_grade.x);
    c = (c - 0.5) * u_grade.y + 0.5;
    // scene colour shift of a strong attack (reference: the whole scene briefly takes the attack colour)
    c = mix(c, vec3(l) * u_tint.rgb * 1.7, u_tint.a);
    // enemies and bosses (keep mask) keep half of their original colour values: grading never darkens a threat
    c = mix(c, pre, 0.5 * keep);
    // vignette
    vec2 v = (uv - 0.5) * vec2(u_res.x / u_res.y, 1.0);
    c *= 1.0 - u_grade.z * (1.0 - keep) * smoothstep(u_grade.w, u_grade.w + 0.55, length(v));
    gl_FragColor = vec4(clamp(c, 0.0, 1.0), 1.0);
}
