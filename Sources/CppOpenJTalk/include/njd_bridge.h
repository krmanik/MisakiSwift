//
//  njd_bridge.h
//  CppOpenJTalk — C bridge over the OpenJTalk frontend (text2mecab → mecab →
//  mecab2njd → njd_set_* chain). Exposes per-word NJD features for Swift.
//

#ifndef NJD_BRIDGE_H
#define NJD_BRIDGE_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque handle for an initialized OpenJTalk frontend (Mecab + NJD).
typedef void* OJTHandle;

// One analyzed word (mirrors the NJD features ja.py reads).
typedef struct {
    const char* string;     // surface form
    const char* pron;       // katakana pronunciation
    const char* pos;        // part of speech
    int acc;                // accent nucleus position
    int mora_size;          // mora count
    int chain_flag;         // accent-phrase chaining (-1/0/1)
} OJTWord;

typedef struct {
    OJTWord* words;
    size_t count;
} OJTResult;

// Create a frontend. `dic_dir` = path to the naist-jdic UTF-8 dictionary directory.
// Returns NULL on failure (e.g. dictionary not found).
OJTHandle ojt_create(const char* dic_dir);

// Destroy a frontend.
void ojt_destroy(OJTHandle handle);

// Run the frontend on `text`; returns per-word NJD features.
// Strings in the result are owned by the result; free with ojt_free_result.
OJTResult ojt_run_frontend(OJTHandle handle, const char* text);

void ojt_free_result(OJTResult result);

#ifdef __cplusplus
}
#endif

#endif // NJD_BRIDGE_H
