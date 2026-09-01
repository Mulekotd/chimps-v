#include <assert.h>
#include <stdint.h>

#include "software/include/stack.h"

static void test_rejects_invalid_initialization(void) {
    TSTACK stack = {0};

    uint32_t storage[2] = {0};

    assert(TSTACK_initialize(0, storage, 2) == TSTACK_INVALID);
    assert(TSTACK_initialize(&stack, 0, 2) == TSTACK_INVALID);
    assert(TSTACK_initialize(&stack, storage, 0) == TSTACK_INVALID);
    assert(TSTACK_push(&stack, 1) == TSTACK_INVALID);
}

static void test_lifo_bounds_and_errors(void) {
    TSTACK stack = {0};

    uint32_t storage[2] = {0};
    uint32_t value = 99;

    assert(TSTACK_initialize(&stack, storage, 2) == TSTACK_OK);
    assert(TSTACK_isEmpty(&stack));
    assert(!TSTACK_isFull(&stack));
    assert(TSTACK_pop(&stack, &value) == TSTACK_UNDERFLOW);
    assert(value == 99);
    assert(TSTACK_top(&stack, &value) == TSTACK_UNDERFLOW);
    assert(value == 99);

    assert(TSTACK_push(&stack, 7) == TSTACK_OK);
    assert(TSTACK_push(&stack, 11) == TSTACK_OK);
    assert(TSTACK_isFull(&stack));
    assert(TSTACK_push(&stack, 13) == TSTACK_OVERFLOW);
    assert(TSTACK_top(&stack, &value) == TSTACK_OK);
    assert(value == 11);
    assert(TSTACK_pop(&stack, &value) == TSTACK_OK);
    assert(value == 11);
    assert(TSTACK_pop(&stack, &value) == TSTACK_OK);
    assert(value == 7);
    assert(TSTACK_isEmpty(&stack));
    assert(TSTACK_pop(&stack, 0) == TSTACK_INVALID);
}

int main(void) {
    test_rejects_invalid_initialization();
    test_lifo_bounds_and_errors();
    return 0;
}
