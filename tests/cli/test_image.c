#include "chimpsv/image.h"

#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static void write_file(const char *path, const unsigned char *data, size_t size) {
    FILE *file = fopen(path, "wb");

    assert(file != NULL);
    assert(fwrite(data, 1, size, file) == size);
    assert(fclose(file) == 0);
}

int main(void) {
    char path[128];
    char error[160];

    chimpsv_image image = {0};

    const unsigned char program[] = {0x93, 0x00, 0x50, 0x00};

    snprintf(path, sizeof(path), "/tmp/chimpsv-image-%ld.bin", (long)getpid());
    write_file(path, program, sizeof(program));

    assert(chimpsv_image_load(path, 4, &image, error, sizeof(error)) == 0);
    assert(image.size == 4 && image.load_address == 4);
    assert(memcmp(image.bytes, program, sizeof(program)) == 0);

    chimpsv_image_free(&image);
    unlink(path);

    assert(chimpsv_image_load("program.hex", 0, &image, error, sizeof(error)) != 0);
    assert(strstr(error, ".bin") != NULL);

    snprintf(path, sizeof(path), "/tmp/chimpsv-image-%ld.bin", (long)getpid());
    write_file(path, program, 3);

    assert(chimpsv_image_load(path, 0, &image, error, sizeof(error)) != 0);
    assert(strstr(error, "multiple of 4") != NULL);
    assert(chimpsv_image_load(path, 2, &image, error, sizeof(error)) != 0);
    assert(strstr(error, "aligned") != NULL);

    unlink(path);
    puts("test_image: ok");

    return 0;
}
