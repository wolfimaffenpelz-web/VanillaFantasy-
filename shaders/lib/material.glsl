#ifndef WF_MATERIAL_LIB
#define WF_MATERIAL_LIB
vec3 wfEmission(int id, vec3 albedo) {
    // Self-emission of this surface only, never propagated colored world light.
    float amount = 0.0;
    if (id == 101) amount = 0.8; // torch/fire
    if (id == 102) amount = 0.9; // soul fire/torch/lantern: texture supplies cyan
    if (id == 103) amount = 1.0; // lava
    if (id == 104) amount = 0.65; // lantern/glowstone/shroomlight
    return albedo * amount;
}
#endif
