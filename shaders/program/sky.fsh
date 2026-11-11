#include "/lib/options.glsl"
#include "/lib/color.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/sky.glsl"
#include "/lib/clouds.glsl"
/* DRAWBUFFERS:0 */
void main() {
    vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    vec4 ray = gbufferProjectionInverse * vec4(uv * 2.0 - 1.0, 1.0, 1.0);
    vec3 direction = wfNormalize(mat3(gbufferModelViewInverse) * ray.xyz);
    gl_FragData[0] = vec4(wfClouds(wfCelestial(wfSky(direction), direction), direction), 1.0);
}
