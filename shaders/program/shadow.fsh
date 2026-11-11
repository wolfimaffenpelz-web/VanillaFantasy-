#include "/lib/options.glsl"
uniform sampler2D gtexture;
in vec2 wfTex;
in vec4 wfColor;
/* DRAWBUFFERS:0 */
void main() {
    if (texture(gtexture, wfTex).a * wfColor.a < 0.1) discard;
    gl_FragData[0] = vec4(1.0);
}
