#include "/lib/options.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/clouds.glsl"
out vec2 wfTex;
flat out float wfSunVisibility;
#if SUN_GLARE == 1 && WF_DIMENSION == 0
uniform sampler2D depthtex0;
#endif
void main() {
    gl_Position = ftransform();
    wfTex = gl_MultiTexCoord0.xy;
    wfSunVisibility = 0.0;
#if SUN_GLARE == 1 && WF_DIMENSION == 0
    vec4 clip = gbufferProjection * vec4(wfNormalize(sunPosition), 0.0);
    if (clip.w > 0.001 && isEyeInWater == 0) {
        vec2 uv = clip.xy / clip.w * 0.5 + 0.5;
        if (all(greaterThan(uv, vec2(0.0))) && all(lessThan(uv, vec2(1.0)))) {
            vec2 radius = vec2(abs(gbufferProjection[0][0]), abs(gbufferProjection[1][1]))
                        * tan(0.030 * SUN_SIZE) * 0.25;
            // Five depth taps per fullscreen vertex, not per screen pixel.
            float visible = 0.0;
            for (int i = 0; i < 5; ++i) {
                vec2 offset = vec2(0.0);
                if (i == 1) offset.x = radius.x;
                if (i == 2) offset.x = -radius.x;
                if (i == 3) offset.y = radius.y;
                if (i == 4) offset.y = -radius.y;
                vec2 sampleUV = uv + offset;
                if (all(greaterThanEqual(sampleUV, vec2(0.0))) && all(lessThanEqual(sampleUV, vec2(1.0)))) {
                    visible += step(0.999999, textureLod(depthtex0, sampleUV, 0.0).r) * 0.2;
                }
            }
            wfSunVisibility = visible * smoothstep(-0.02, 0.08, wfSunDir().y)
                            * (1.0 - rainStrength) * (1.0 - rainStrength)
                            * (1.0 - wfCloudOpacity(wfSunDir()) * 0.9);
        }
    }
#endif
}
