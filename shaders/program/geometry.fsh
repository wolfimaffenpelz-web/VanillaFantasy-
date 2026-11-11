#include "/lib/options.glsl"
#include "/lib/color.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/lighting.glsl"
#include "/lib/material.glsl"
#if WF_WATER == 1
#include "/lib/water.glsl"
#endif
uniform sampler2D gtexture;
uniform sampler2D lightmap;
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
#if WF_TEXTURED == 1
    c *= texture(gtexture, wfTex);
#endif
    if (c.a < alphaTestRef) discard;
#if WF_ENTITY == 1
    c.rgb = mix(c.rgb, entityColor.rgb, entityColor.a);
#endif
    vec3 linearColor = wfLinear(c.rgb);
#if WF_WATER == 1
    if (wfMaterial == 100) {
        gl_FragData[0] = wfWater(wfPosition, wfNormalize(wfNormal), wfColor.rgb,
                               texture(gtexture, wfTex).rgb, wfLm);
        return;
    }
#endif
#if WF_LIT == 1
    vec3 normal = wfNormalize(wfNormal);
    if (dot(normal, normal) < 0.1) normal = vec3(0.0, 1.0, 0.0);
    linearColor *= wfLight(wfPosition, normal, wfLm);
    linearColor += wfEmission(wfMaterial, wfLinear(c.rgb));
#endif
    gl_FragData[0] = vec4(linearColor, c.a);
}
