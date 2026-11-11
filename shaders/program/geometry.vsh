out vec2 wfTex;
out vec2 wfLm;
out vec4 wfColor;
void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    wfTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    wfLm = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    wfColor = gl_Color;
}
