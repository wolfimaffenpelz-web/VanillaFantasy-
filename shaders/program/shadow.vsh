#include "/lib/options.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/vegetation.glsl"
in vec4 mc_Entity;
in vec2 mc_midTexCoord;
out vec2 wfTex;
out vec4 wfColor;
void main() {
    vec4 shadowView = gl_ModelViewMatrix * gl_Vertex;
    vec3 position = (shadowModelViewInverse * shadowView).xyz;
    position = wfPlantMotion(position, int(mc_Entity.x + 0.5), float(gl_MultiTexCoord0.t < mc_midTexCoord.t));
    gl_Position = gl_ProjectionMatrix * shadowModelView * vec4(position, 1.0);
    wfTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    wfColor = gl_Color;
}
