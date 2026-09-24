#ifndef CHIMPSV_STACK_H
#define CHIMPSV_STACK_H

#include <stdbool.h>
#include <stdint.h>

// LIFO sem heap
typedef struct stack {
    uint32_t capacity;
    uint32_t count;
    uint32_t *data;
} TSTACK;

typedef enum tstack_result {
    TSTACK_OK = 0,
    TSTACK_INVALID,
    TSTACK_OVERFLOW,
    TSTACK_UNDERFLOW
} TSTACK_RESULT;

TSTACK_RESULT TSTACK_initialize(TSTACK *stack, uint32_t *storage, uint32_t capacity);
bool TSTACK_isEmpty(const TSTACK *stack);
bool TSTACK_isFull(const TSTACK *stack);
TSTACK_RESULT TSTACK_push(TSTACK *stack, uint32_t value);
TSTACK_RESULT TSTACK_pop(TSTACK *stack, uint32_t *value);
TSTACK_RESULT TSTACK_top(const TSTACK *stack, uint32_t *value);

#endif
