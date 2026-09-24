#include <assert.h>
#include <stdint.h>
#include "software/include/stack.h"

int main(void) {
    TSTACK stack;
    uint32_t storage[2], value = 0;

    assert(TSTACK_initialize(0, storage, 2) == TSTACK_INVALID);
    assert(TSTACK_initialize(&stack, storage, 0) == TSTACK_INVALID);
    assert(TSTACK_initialize(&stack, storage, 2) == TSTACK_OK);
    assert(TSTACK_isEmpty(&stack) && !TSTACK_isFull(&stack));
    assert(TSTACK_pop(&stack, &value) == TSTACK_UNDERFLOW && TSTACK_top(&stack, &value) == TSTACK_UNDERFLOW);
    assert(TSTACK_push(&stack, 0x11) == TSTACK_OK && TSTACK_push(&stack, 0x22) == TSTACK_OK);
    assert(TSTACK_isFull(&stack) && TSTACK_push(&stack, 0x33) == TSTACK_OVERFLOW);
    assert(TSTACK_top(&stack, &value) == TSTACK_OK && value == 0x22);
    assert(TSTACK_pop(&stack, &value) == TSTACK_OK && value == 0x22);
    assert(TSTACK_pop(&stack, &value) == TSTACK_OK && value == 0x11);
    assert(TSTACK_isEmpty(&stack));

    return 0;
}
