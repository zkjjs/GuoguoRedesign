#include "GTLayout.h"

GTRect GTContainerRect(double width, double height, double safeBottom) {
    const double inset = width < 360.0 ? 16.0 : 20.0;
    const double capsuleHeight = 64.0;
    const double bottomClearance = safeBottom > 0.0 ? safeBottom + 14.0 : 14.0;
    GTRect result = {
        .x = inset,
        .y = height - bottomClearance - capsuleHeight,
        .width = width - (inset * 2.0),
        .height = capsuleHeight,
    };
    return result;
}

int GTTabIndexForX(double x, double width) {
    if (width <= 0.0 || x <= 0.0) {
        return 0;
    }
    int index = (int)((x / width) * 4.0);
    if (index < 0) {
        return 0;
    }
    if (index > 3) {
        return 3;
    }
    return index;
}

