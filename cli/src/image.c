#include "chimpsv/image.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int fail(char *error, size_t size, const char *message) {
    if (size > 0)
        snprintf(error, size, "%s", message);

    return -1;
}

static int has_bin_suffix(const char *path) {
    size_t length = strlen(path);
    return length >= 4 && strcmp(path + length - 4, ".bin") == 0;
}

int chimpsv_image_load(const char *path, uint32_t address, chimpsv_image *image,
                       char *error, size_t error_size) {
    FILE *file;
    long length;

    uint8_t *bytes;

    if (!path || !image)
        return fail(error, error_size, "invalid argument");
    
    *image = (chimpsv_image){0};
    
    if (!has_bin_suffix(path))
        return fail(error, error_size, "program image must use the .bin extension");
    
    if ((address & 3u) != 0)
        return fail(error, error_size, "load address must be 4-byte aligned");

    file = fopen(path, "rb");
    
    if (!file) {
        if (error_size > 0) snprintf(error, error_size, "cannot open %s: %s", path, strerror(errno));
        return -1;
    }
    
    if (fseek(file, 0, SEEK_END) != 0 || (length = ftell(file)) <= 0 ||
        fseek(file, 0, SEEK_SET) != 0) {
        fclose(file);
        return fail(error, error_size, "program image must be a non-empty regular file");
    }
    
    if ((length & 3L) != 0) {
        fclose(file);
        return fail(error, error_size, "program image size must be a multiple of 4 bytes");
    }
    
    if ((uint64_t)address + (uint64_t)length > CHIMPSV_RAM_BYTES) {
        fclose(file);
        return fail(error, error_size, "program image does not fit in RAM");
    }
    
    bytes = malloc((size_t)length);
    
    if (!bytes) {
        fclose(file); return fail(error, error_size, "out of memory");
    }
    
    if (fread(bytes, 1, (size_t)length, file) != (size_t)length || fclose(file) != 0) {
        free(bytes);
        return fail(error, error_size, "failed to read program image");
    }
    
    image->bytes = bytes;
    image->size = (size_t)length;
    image->load_address = address;
    
    return 0;
}

void chimpsv_image_free(chimpsv_image *image) {
    if (!image) return;
    free(image->bytes);
    *image = (chimpsv_image){0};
}
