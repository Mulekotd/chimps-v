#include "software/include/stack.h"

TSTACK_RESULT TSTACK_initialize(TSTACK *stack, uint32_t *storage, uint32_t capacity) {
    if (stack == 0 || storage == 0 || capacity == 0)
        return TSTACK_INVALID;

    stack->capacity = capacity;
    stack->count = 0;
    stack->data = storage;

    return TSTACK_OK;
}

bool TSTACK_isEmpty(const TSTACK *stack) {
    return stack == 0 || stack->count == 0;
}

bool TSTACK_isFull(const TSTACK *stack) {
    return stack != 0 && stack->count == stack->capacity;
}

TSTACK_RESULT TSTACK_push(TSTACK *stack, uint32_t value) {
    if (stack == 0 || stack->data == 0)
        return TSTACK_INVALID;
    
    if (TSTACK_isFull(stack))
        return TSTACK_OVERFLOW;

    stack->data[stack->count++] = value;

    return TSTACK_OK;
}

TSTACK_RESULT TSTACK_pop(TSTACK *stack, uint32_t *value) {
    if (stack == 0 || value == 0)
        return TSTACK_INVALID;

    if (TSTACK_isEmpty(stack))
        return TSTACK_UNDERFLOW;

    *value = stack->data[--stack->count];

    return TSTACK_OK;
}

TSTACK_RESULT TSTACK_top(const TSTACK *stack, uint32_t *value) {
    if (stack == 0 || value == 0)
        return TSTACK_INVALID;

    if (TSTACK_isEmpty(stack))
        return TSTACK_UNDERFLOW;

    *value = stack->data[stack->count - 1];

    return TSTACK_OK;
}
