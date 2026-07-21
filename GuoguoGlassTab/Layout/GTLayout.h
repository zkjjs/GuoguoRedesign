#ifndef GT_LAYOUT_H
#define GT_LAYOUT_H

typedef struct {
    double x;
    double y;
    double width;
    double height;
} GTRect;

GTRect GTContainerRect(double width, double height, double safeBottom);
int GTTabIndexForX(double x, double width);

#endif

