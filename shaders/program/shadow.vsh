#include "/lib/options.glsl"
out vec2 wfTex;
out vec4 wfColor;
void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    wfTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    wfColor = gl_Color;
}
