#ifndef CHIMPSV_IMAGE_H
#define CHIMPSV_IMAGE_H

#include <stddef.h>
#include <stdint.h>

enum { CHIMPSV_RAM_BYTES = 96 * 1024 };

typedef struct {
    uint8_t *bytes;
    size_t size;
    uint32_t load_address;
} chimpsv_image;

int chimpsv_image_load(const char *path, uint32_t load_address, chimpsv_image *image, char *error, size_t error_size);
void chimpsv_image_free(chimpsv_image *image);

#endif
