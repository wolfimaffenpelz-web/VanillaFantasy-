#include "/lib/options.glsl"
#include "/lib/color.glsl"
uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform float alphaTestRef;
in vec2 wfTex;
in vec2 wfLm;
in vec4 wfColor;
/* DRAWBUFFERS:0 */
void main() {
    vec4 c = wfColor;
#if WF_TEXTURED == 1
    c *= texture(gtexture, wfTex);
#endif
    if (c.a < alphaTestRef) discard;
#if WF_LIT == 1
    c.rgb *= texture(lightmap, wfLm).rgb;
#endif
    gl_FragData[0] = vec4(wfLinear(c.rgb), c.a);
}
