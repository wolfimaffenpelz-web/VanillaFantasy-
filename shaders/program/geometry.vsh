#include "/lib/options.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#if WF_MATERIAL == 1
in vec4 mc_Entity;
#endif
out vec2 wfTex;
out vec2 wfLm;
out vec4 wfColor;
out vec3 wfPosition;
out vec3 wfNormal;
flat out int wfMaterial;
void main() {
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
    wfPosition = (gbufferModelViewInverse * view).xyz;
    wfNormal = wfNormalize(mat3(gbufferModelViewInverse) * gl_NormalMatrix * gl_Normal);
    wfMaterial = 0;
#if WF_MATERIAL == 1
    wfMaterial = int(mc_Entity.x + 0.5);
#endif
    gl_Position = gl_ProjectionMatrix * view;
    wfTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    wfLm = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    wfColor = gl_Color;
}
