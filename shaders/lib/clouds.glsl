#ifndef WF_CLOUDS_LIB
#define WF_CLOUDS_LIB
float wfHash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float wfNoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(wfHash(i), wfHash(i + vec2(1.0, 0.0)), f.x),
               mix(wfHash(i + vec2(0.0, 1.0)), wfHash(i + vec2(1.0)), f.x), f.y);
}
vec3 wfClouds(vec3 color, vec3 direction) {
#if CLOUDS == 1 && WF_DIMENSION == 0
    if (abs(direction.y) < 0.025) return color;
    float distanceToLayer = (192.0 - cameraPosition.y) / direction.y;
    if (distanceToLayer < 0.0 || distanceToLayer > 18000.0) return color;
    vec2 p = (cameraPosition.xz + direction.xz * distanceToLayer) * 0.002;
    p += vec2(frameTimeCounter * 0.006, frameTimeCounter * 0.002);
    float noise = wfNoise(p) * 0.65 + wfNoise(p * 2.1) * 0.25 + wfNoise(p * 4.3) * 0.10;
    float threshold = 0.76 - CLOUD_DENSITY * 0.46 - rainStrength * 0.07;
    float cloud = smoothstep(threshold, threshold + 0.18, noise);
    cloud *= smoothstep(0.025, 0.12, abs(direction.y)) * (1.0 - smoothstep(9000.0, 18000.0, distanceToLayer));
    vec3 cloudColor = mix(vec3(0.10, 0.14, 0.22), vec3(0.87, 0.86, 0.82), wfDay());
    cloudColor *= 1.0 - rainStrength * 0.36;
    return mix(color, cloudColor, cloud * 0.83);
#else
    return color;
#endif
}
#endif
