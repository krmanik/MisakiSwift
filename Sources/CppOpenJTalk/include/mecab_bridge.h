//
//  mecab_bridge.h
//  CppMecab — generic C bridge over the (open_jtalk-patched) mecab tagger.
//  Loads any compiled mecab dictionary directory and returns, per token, a
//  feature string of the form "surface,field0,field1,..." (the patched mecab
//  prepends the surface + comma to node->feature).
//

#ifndef MECAB_BRIDGE_H
#define MECAB_BRIDGE_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* MecabHandle;

typedef struct {
    char** features;   // each: "surface,POS,...". Owned by result.
    size_t count;
} MecabResult;

// Create a tagger from a compiled dictionary directory. NULL on failure.
MecabHandle mecab_bridge_create(const char* dic_dir);
void mecab_bridge_destroy(MecabHandle handle);

// Analyze text → per-token feature strings.
MecabResult mecab_bridge_analyze(MecabHandle handle, const char* text);
void mecab_bridge_free_result(MecabResult result);

#ifdef __cplusplus
}
#endif

#endif // MECAB_BRIDGE_H
