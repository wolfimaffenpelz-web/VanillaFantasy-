#include "/lib/options.glsl"
#include "/lib/color.glsl"
uniform sampler2D colortex0;
const int colortex0Format = RGBA16F;
in vec2 wfTex;
void main() {
    gl_FragColor = vec4(wfDisplay(texture(colortex0, wfTex).rgb), 1.0);
}
