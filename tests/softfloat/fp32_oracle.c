#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "softfloat.h"

static void expect_result(const char *name, float32_t value, uint32_t expected) {
    if (value.v != expected) {
        fprintf(stderr, "%s: got %08x, expected %08x\n", name, value.v, expected);
        exit(EXIT_FAILURE);
    }
}

int main(void) {
    float32_t one  = { .v = UINT32_C(0x3f800000) };
    float32_t two  = { .v = UINT32_C(0x40000000) };
    float32_t four = { .v = UINT32_C(0x40800000) };
    float32_t six  = { .v = UINT32_C(0x40c00000) };

    softfloat_roundingMode = softfloat_round_near_even;
    softfloat_exceptionFlags = 0;

    expect_result("FADD.S", f32_add(one, two), UINT32_C(0x40400000));
    expect_result("FMUL.S", f32_mul(one, two), UINT32_C(0x40000000));
    expect_result("FMADD.S", f32_mulAdd(one, two, four), UINT32_C(0x40c00000));
    expect_result("FDIV.S", f32_div(six, two), UINT32_C(0x40400000));
    expect_result("FSQRT.S", f32_sqrt(four), UINT32_C(0x40000000));

    if (softfloat_exceptionFlags != 0) {
        fprintf(stderr, "unexpected SoftFloat flags: %02x\n", softfloat_exceptionFlags);
        return EXIT_FAILURE;
    }

    puts("SoftFloat binary32 oracle vectors validated.");

    return EXIT_SUCCESS;
}
