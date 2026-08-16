#define VOXY_PATCH

layout(location = 0) out vec3 colortex7Out;
layout(location = 1) out vec4 reflectionData;
layout(location = 2) out vec4 colortex3Out;

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

vec3 ScreenToViewSpace(vec3 screenPos) {
    vec4 ndc = vec4(screenPos.xy * 2.0 - 1.0, screenPos.z * 2.0 - 1.0, 1.0);
    vec4 viewPos = vxProjInv * ndc;
    return viewPos.xyz / viewPos.w;
}

void voxy_emitFragment(VoxyFragmentParameters p) {
    vec4 albedo = p.sampledColour * p.tinting;
    if (albedo.a < 0.01) return;

    uint blockID = p.customId / 100u;
    float water = float(blockID == 200u || blockID == 204u);
    float glass = float(blockID == 201u);
    float ice   = float(blockID == 202u);

    vec2 lightmap = clamp((p.lightMap - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

    vec3 normal = vec3(0.0);
    switch (uint(p.face) >> 1u) {
        case 0u: normal = vxModelView[1].xyz; break;
        case 1u: normal = vxModelView[2].xyz; break;
        case 2u: normal = vxModelView[0].xyz; break;
    }
    if ((p.face & 1u) == 0u) normal = -normal;

    int materialID = 16;
    if (water > 0.5) {
        materialID = 17;
        albedo.rgb = mix(albedo.rgb, vec3(0.05, 0.7, 1.0) * 0.3, 0.8);
    } else if (ice > 0.5) {
        materialID = 18;
    } else if (glass > 0.5) {
        materialID = 16;
    }

    float fresnel = 0.0;
    if (water > 0.5) {
        vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
        vec3 viewPos = ScreenToViewSpace(screenPos);
        float NdotV = abs(dot(normal, normalize(viewPos)));
        fresnel = pow(1.0 - NdotV, 5.0);
        fresnel = fresnel * 0.98 + 0.02;
    }

    colortex7Out.xy = lightmap;
    colortex7Out.z = float(materialID + 0.1) / 255.0;

    colortex3Out.xy = EncodeNormal(normal);
    colortex3Out.z = PackUnorm2x8(albedo.rg);
    colortex3Out.w = PackUnorm2x8(albedo.ba);

    vec3 waterColor = vec3(0.05, 0.7, 1.0) * 0.3;
    reflectionData = vec4(waterColor * fresnel, 1.0 - fresnel);
}