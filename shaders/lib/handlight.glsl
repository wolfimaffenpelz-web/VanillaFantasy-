#ifndef WF_HANDLIGHT_LIB
#define WF_HANDLIGHT_LIB
#if HAND_LIGHT == 1
uniform float wfHeldLight;
uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
vec3 wfHandLight(vec3 position, vec3 normal) {
    float level = clamp(wfHeldLight / 15.0, 0.0, 1.0);
    float range = 9.0 * level;
    float attenuation = max(1.0 - length(position) / max(range, 0.01), 0.0);
    int item = heldBlockLightValue2 > heldBlockLightValue ? heldItemId2 : heldItemId;
    vec3 tint = item == 102 ? vec3(0.27, 0.75, 1.0) : vec3(1.0, 0.65, 0.30);
    float diffuse = 0.4 + 0.6 * max(dot(normal, wfNormalize(-position)), 0.0);
    // Camera-local approximation without occlusion: never changes world light.
    return tint * attenuation * attenuation * level * 0.65 * diffuse;
}
#else
vec3 wfHandLight(vec3 position, vec3 normal) { return vec3(0.0); }
#endif
#endif
