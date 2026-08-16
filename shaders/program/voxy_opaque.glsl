#define VOXY_PATCH

layout(location = 0) out vec3 albedoData;
layout(location = 2) out vec4 colortex3Out;
layout(location = 1) out vec3 colortex7Out;

#define rcp(x) (1.0 / (x))
float PackUnorm2x8(vec2 xy) { return dot(floor(255.0 * xy + 0.5), vec2(1.0 / 65535.0, 256.0 / 65535.0)); }
vec2 EncodeNormal(in vec3 n) {
    n.xy /= abs(n.x) + abs(n.y) + abs(n.z);
    if (n.z <= 0.0) n.xy = (vec2(1.0) - abs(n.yx)) * (step(0.0, n.xy) * 2.0 - 1.0);
    return n.xy * 0.5 + 0.5;
}

mat4 gbufferModelView = vxModelView;
mat4 gbufferModelViewInverse = vxModelViewInv;
mat4 gbufferProjection = vxProj;
mat4 gbufferProjectionInverse = vxProjInv;

void voxy_emitFragment(VoxyFragmentParameters p) {
    vec4 albedo = p.sampledColour * p.tinting;
    if (albedo.a < 0.1) return;

    vec2 lightmap = clamp((p.lightMap - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));
    float dither = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453);

    vec3 normal = vec3(0.0);
    switch (uint(p.face) >> 1u) {
        case 0u: normal = vxModelView[1].xyz; break;
        case 1u: normal = vxModelView[2].xyz; break;
        case 2u: normal = vxModelView[0].xyz; break;
    }
    if ((p.face & 1u) == 0u) normal = -normal;

    vec4 specularData = vec4(0.0);

    albedoData = albedo.rgb;
    colortex7Out.xy = lightmap + (dither - 0.5) * rcp(255.0);
    colortex7Out.z = 0.1 * rcp(255.0);
    colortex3Out.xy = EncodeNormal(normal);
    colortex3Out.z = PackUnorm2x8(specularData.rg);
    colortex3Out.w = PackUnorm2x8(specularData.ba);
}