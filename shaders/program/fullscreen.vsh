out vec2 wfTex;
void main() {
    gl_Position = ftransform();
    wfTex = gl_MultiTexCoord0.xy;
}
