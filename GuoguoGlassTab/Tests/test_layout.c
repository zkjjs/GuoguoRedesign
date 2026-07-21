#include <assert.h>
#include <math.h>
#include <stdio.h>

#include "../Layout/GTLayout.h"

static int close_enough(double a, double b) {
    return fabs(a - b) < 0.01;
}

int main(void) {
    GTRect phone = GTContainerRect(428.0, 926.0, 34.0);
    assert(close_enough(phone.x, 20.0));
    assert(close_enough(phone.width, 388.0));
    assert(close_enough(phone.height, 64.0));
    assert(close_enough(phone.y, 814.0));

    GTRect compact = GTContainerRect(320.0, 568.0, 0.0);
    assert(close_enough(compact.x, 16.0));
    assert(close_enough(compact.width, 288.0));
    assert(close_enough(compact.y, 490.0));

    assert(GTTabIndexForX(-1.0, 428.0) == 0);
    assert(GTTabIndexForX(0.0, 428.0) == 0);
    assert(GTTabIndexForX(106.9, 428.0) == 0);
    assert(GTTabIndexForX(107.0, 428.0) == 1);
    assert(GTTabIndexForX(214.0, 428.0) == 2);
    assert(GTTabIndexForX(427.0, 428.0) == 3);
    assert(GTTabIndexForX(500.0, 428.0) == 3);

    puts("layout tests passed");
    return 0;
}

