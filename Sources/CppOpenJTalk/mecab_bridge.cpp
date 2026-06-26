//
//  mecab_bridge.cpp
//

#include "mecab_bridge.h"

#include <cstdlib>
#include <cstring>

#include "mecab.h"

extern "C" {

MecabHandle mecab_bridge_create(const char* dic_dir) {
    if (!dic_dir) return nullptr;
    Mecab* m = new Mecab();
    Mecab_initialize(m);
    if (Mecab_load(m, dic_dir) != TRUE) {
        Mecab_clear(m);
        delete m;
        return nullptr;
    }
    return m;
}

void mecab_bridge_destroy(MecabHandle handle) {
    if (!handle) return;
    Mecab* m = static_cast<Mecab*>(handle);
    Mecab_clear(m);
    delete m;
}

MecabResult mecab_bridge_analyze(MecabHandle handle, const char* text) {
    MecabResult result = { nullptr, 0 };
    if (!handle || !text) return result;
    Mecab* m = static_cast<Mecab*>(handle);

    Mecab_analysis(m, text);
    int size = Mecab_get_size(m);
    char** feats = Mecab_get_feature(m);
    if (size > 0 && feats) {
        result.count = static_cast<size_t>(size);
        result.features = static_cast<char**>(std::malloc(sizeof(char*) * size));
        for (int i = 0; i < size; i++) {
            const char* f = feats[i] ? feats[i] : "";
            size_t n = std::strlen(f);
            char* p = static_cast<char*>(std::malloc(n + 1));
            std::memcpy(p, f, n + 1);
            result.features[i] = p;
        }
    }
    Mecab_refresh(m);
    return result;
}

void mecab_bridge_free_result(MecabResult result) {
    if (!result.features) return;
    for (size_t i = 0; i < result.count; i++) std::free(result.features[i]);
    std::free(result.features);
}

} // extern "C"
