#ifndef WF_VEGETATION_LIB
#define WF_VEGETATION_LIB
vec3 wfPlantMotion(vec3 position, int material, float top) {
#if VEGETATION == 1
    // Only explicitly mapped small plants. UV upper vertices move, bases anchor.
    if (material == 201) {
        vec3 absolutePosition = position + cameraPosition;
        float phase = dot(absolutePosition.xz, vec2(0.61, 0.43)) + frameTimeCounter * 1.25;
        position.xz += vec2(sin(phase), cos(phase * 0.8)) * 0.025 * top;
    }
#endif
    return position;
}
#endif
