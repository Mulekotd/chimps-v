#include "chimpsv/image.h"

#include <errno.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void usage(FILE *stream) {
    fprintf(stream, "usage: chimps-v load PROGRAM.bin [--address ADDRESS]\n");
}

int main(int argc, char **argv) {
    uint32_t address = 0;
    chimpsv_image image;

    char error[256];

    if (argc != 3 && argc != 5) { 
        usage(stderr);
        return 64;
    }
    
    if (strcmp(argv[1], "load") != 0) {
        usage(stderr);
        return 64;
    }
    
    if (argc == 5) {
        char *end;

        size_t value;

        if (strcmp(argv[3], "--address") != 0) {
            usage(stderr);
            return 64;
        }

        errno = 0;

        value = strtoul(argv[4], &end, 0);

        if (errno || *end != '\0' || value > UINT32_MAX) {
            fprintf(stderr, "invalid load address: %s\n", argv[4]);
            return 64;
        }

        address = (uint32_t)value;
    }

    if (chimpsv_image_load(argv[2], address, &image, error, sizeof(error)) != 0) {
        fprintf(stderr, "chimps-v: %s\n", error);
        return 65;
    }

    printf("loaded %zu bytes at 0x%08" PRIx32 " (little-endian words)\n", image.size, image.load_address);

    chimpsv_image_free(&image);

    return 0;
}
