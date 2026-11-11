#include "/lib/options.glsl"
#include "/lib/color.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/lighting.glsl"
#include "/lib/material.glsl"
#include "/lib/fog.glsl"
#include "/lib/wet.glsl"
#if WF_WATER == 1
#include "/lib/water.glsl"
#endif
uniform sampler2D gtexture;
uniform float alphaTestRef;
#if WF_ENTITY == 1
uniform vec4 entityColor;
#endif
in vec2 wfTex;
in vec2 wfLm;
in vec4 wfColor;
in vec3 wfPosition;
in vec3 wfNormal;
flat in int wfMaterial;
#if WATER_BIOME_BLEND > 0
/* DRAWBUFFERS:012 */
#else
/* DRAWBUFFERS:0 */
#endif
void main() {
#if WATER_BIOME_BLEND > 0
    // Opaque or nearer non-water surfaces erase stale water metadata.
    gl_FragData[1] = vec4(0.0);
    gl_FragData[2] = vec4(0.0);
#endif
    vec4 c = wfColor;
    vec4 surfaceTexture = vec4(1.0);
#if WF_TEXTURED == 1
    surfaceTexture = texture(gtexture, wfTex);
    c *= surfaceTexture;
#endif
    if (c.a < alphaTestRef) discard;
#if WF_ENTITY == 1
    c.rgb = mix(c.rgb, entityColor.rgb, entityColor.a);
#endif
    vec3 linearColor = wfLinear(c.rgb);
#if WF_WATER == 1
    if (wfMaterial == 100) {
        vec3 tintLinear, tintResponse;
        vec3 faceNormal = wfNormalize(wfNormal);
        vec4 water = wfWaterSurface(wfPosition, faceNormal, wfColor.rgb,
                                    surfaceTexture.rgb, wfLm, tintLinear, tintResponse);
#if WATER_BIOME_BLEND > 0
        float face = abs(faceNormal.y) > 0.5 ? 1.0 : (abs(faceNormal.x) > 0.5 ? 2.0 : 3.0);
        // Linear view depth retains useful precision in half float and does
        // not depend on a translucent draw writing Minecraft's depth buffer.
        float viewDepth = max(-(gbufferModelView * vec4(wfPosition, 1.0)).z, 0.0001);
        gl_FragData[1] = vec4(tintLinear, viewDepth);
        gl_FragData[2] = vec4(tintResponse * water.a * (1.0 - wfFogAmount(wfPosition)), face);
#endif
        water.rgb = wfFog(water.rgb, wfPosition);
        gl_FragData[0] = water;
        return;
    }
#endif
#if WF_LIT == 1
    vec3 normal = wfNormalize(wfNormal);
    if (dot(normal, normal) < 0.1) normal = vec3(0.0, 1.0, 0.0);
    linearColor *= wfLight(wfPosition, normal, wfLm);
    linearColor += wfEmission(wfMaterial, wfLinear(c.rgb));
    linearColor = wfWet(linearColor, wfPosition, normal, wfBlockLevel(wfLm.y));
#endif
    gl_FragData[0] = vec4(wfFog(linearColor, wfPosition), c.a);
}
