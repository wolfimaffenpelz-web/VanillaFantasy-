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
/* DRAWBUFFERS:0 */
void main() {
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
        vec4 water = wfWater(wfPosition, wfNormalize(wfNormal), wfColor.rgb,
                             surfaceTexture.rgb, wfLm);
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
