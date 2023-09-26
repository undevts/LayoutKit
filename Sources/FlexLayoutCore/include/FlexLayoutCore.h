#ifndef VIEW_GALLERY_CORE_FLEX_STORAGE_H
#define VIEW_GALLERY_CORE_FLEX_STORAGE_H

#if __has_include(<CoreSwift/Language.h>)
#include <CoreSwift/Language.h>
#else
#include <Language.h>
#endif

#if CS_LANG_CXX
#include <cstdbool>
#include <cstdint>
#else
#include <stdbool.h>
#include <stdint.h>
#endif

CS_C_FILE_BEGIN

typedef struct FlexNodeStorage {
    bool hasNewLayout: 1;
    uint8_t nodeType: 1;
    bool isReferenceBaseline: 1;
    bool isDirty: 1;
} FlexNodeStorage;

typedef struct FlexLayoutStorage {
    uint8_t direction: 2;
    bool hasOverflow: 1;
} FlexLayoutStorage;

typedef struct FlexStyleStorage {
    uint8_t direction: 2;
    uint8_t flexDirection: 2;
    uint8_t justifyContent: 3;
    uint8_t alignContent: 3;
    uint8_t alignItems: 3;
    uint8_t alignSelf: 3;
    uint8_t positionType: 2;
    uint8_t flexWrap: 2;
    uint8_t overflow: 2;
    uint8_t display: 2;
} FlexStyleStorage;

const void* FLEX_LAYOUT_KEY = &FLEX_LAYOUT_KEY;

CS_C_FILE_END

#endif // VIEW_GALLERY_CORE_FLEX_STORAGE_H
