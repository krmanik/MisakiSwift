//
//  njd_bridge.cpp
//  Replays the OpenJTalk frontend pipeline (see open_jtalk.c) without the
//  jpcommon / hts_engine synthesis stages, then walks the NJD node list and
//  copies out the features the Swift JAG2P accent loop needs.
//

#include "njd_bridge.h"

#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#include "mecab.h"
#include "njd.h"
#include "text2mecab.h"
#include "mecab2njd.h"
#include "njd_set_pronunciation.h"
#include "njd_set_digit.h"
#include "njd_set_accent_phrase.h"
#include "njd_set_accent_type.h"
#include "njd_set_unvoiced_vowel.h"
#include "njd_set_long_vowel.h"

namespace {

struct OpenJTalk {
    Mecab mecab;
    NJD njd;
};

// Duplicate a C string into heap (caller frees). NULL → empty string.
char* dupstr(const char* s) {
    if (!s) s = "";
    size_t n = std::strlen(s);
    char* p = static_cast<char*>(std::malloc(n + 1));
    if (p) std::memcpy(p, s, n + 1);
    return p;
}

} // namespace

extern "C" {

OJTHandle ojt_create(const char* dic_dir) {
    if (!dic_dir) return nullptr;
    OpenJTalk* ojt = new OpenJTalk();
    Mecab_initialize(&ojt->mecab);
    NJD_initialize(&ojt->njd);
    if (Mecab_load(&ojt->mecab, dic_dir) != TRUE) {
        Mecab_clear(&ojt->mecab);
        NJD_clear(&ojt->njd);
        delete ojt;
        return nullptr;
    }
    return ojt;
}

void ojt_destroy(OJTHandle handle) {
    if (!handle) return;
    OpenJTalk* ojt = static_cast<OpenJTalk*>(handle);
    Mecab_clear(&ojt->mecab);
    NJD_clear(&ojt->njd);
    delete ojt;
}

OJTResult ojt_run_frontend(OJTHandle handle, const char* text) {
    OJTResult result = { nullptr, 0 };
    if (!handle || !text) return result;
    OpenJTalk* ojt = static_cast<OpenJTalk*>(handle);

    // text2mecab escapes/normalizes; output can grow, so size generously.
    size_t in_len = std::strlen(text);
    size_t buf_len = in_len * 4 + 1024;
    std::string buff(buf_len, '\0');
    text2mecab(&buff[0], text);

    Mecab_analysis(&ojt->mecab, buff.c_str());
    mecab2njd(&ojt->njd, Mecab_get_feature(&ojt->mecab), Mecab_get_size(&ojt->mecab));
    njd_set_pronunciation(&ojt->njd);
    njd_set_digit(&ojt->njd);
    njd_set_accent_phrase(&ojt->njd);
    njd_set_accent_type(&ojt->njd);
    njd_set_unvoiced_vowel(&ojt->njd);
    njd_set_long_vowel(&ojt->njd);

    std::vector<OJTWord> words;
    for (NJDNode* node = ojt->njd.head; node != nullptr; node = node->next) {
        OJTWord w;
        w.string     = dupstr(NJDNode_get_string(node));
        w.pron       = dupstr(NJDNode_get_pron(node));
        w.pos        = dupstr(NJDNode_get_pos(node));
        w.acc        = NJDNode_get_acc(node);
        w.mora_size  = NJDNode_get_mora_size(node);
        w.chain_flag = NJDNode_get_chain_flag(node);
        words.push_back(w);
    }

    // Reset for the next call.
    NJD_refresh(&ojt->njd);
    Mecab_refresh(&ojt->mecab);

    if (!words.empty()) {
        result.count = words.size();
        result.words = static_cast<OJTWord*>(std::malloc(sizeof(OJTWord) * words.size()));
        if (result.words) {
            std::memcpy(result.words, words.data(), sizeof(OJTWord) * words.size());
        } else {
            result.count = 0;
        }
    }
    return result;
}

void ojt_free_result(OJTResult result) {
    if (!result.words) return;
    for (size_t i = 0; i < result.count; i++) {
        std::free(const_cast<char*>(result.words[i].string));
        std::free(const_cast<char*>(result.words[i].pron));
        std::free(const_cast<char*>(result.words[i].pos));
    }
    std::free(result.words);
}

} // extern "C"
