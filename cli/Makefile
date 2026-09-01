CC ?= cc
CPPFLAGS += -Iinclude
CFLAGS ?= -std=c11 -O2 -Wall -Wextra -Wpedantic -Werror

BUILD := build
CLI := $(BUILD)/chimps-v
TEST := $(BUILD)/test_image

.PHONY: all test clean
all: $(CLI)

$(BUILD):
	mkdir -p $@

$(CLI): src/main.c src/image.c include/chimpsv/image.h | $(BUILD)
	$(CC) $(CPPFLAGS) $(CFLAGS) src/main.c src/image.c -o $@

$(TEST): tests/test_image.c src/image.c include/chimpsv/image.h | $(BUILD)
	$(CC) $(CPPFLAGS) $(CFLAGS) tests/test_image.c src/image.c -o $@

test: $(CLI) $(TEST)
	$(TEST)
	! $(CLI) load missing.bin

clean:
	rm -f $(CLI) $(TEST)
