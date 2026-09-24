#!/usr/bin/env bash
set -euo pipefail

project_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
oracle_directory="$(mktemp -d /tmp/chimps-v-softfloat.XXXXXX)"
archive_path="${oracle_directory}/SoftFloat-3e.zip"

cleanup() {
    rm -rf -- "${oracle_directory}"
}

trap cleanup EXIT

curl --fail --location --silent --show-error \
    --output "${archive_path}" \
    "https://www.jhauser.us/arithmetic/SoftFloat-3e.zip"
unzip -q "${archive_path}" -d "${oracle_directory}"

softfloat_root="${oracle_directory}/SoftFloat-3e"
make -s -C "${softfloat_root}/build/Linux-x86_64-GCC"

cc -std=c11 -Wall -Wextra -Werror \
    -I"${softfloat_root}/source/include" \
    "${project_root}/tests/softfloat/fp32_oracle.c" \
    "${softfloat_root}/build/Linux-x86_64-GCC/softfloat.a" \
    -o "${oracle_directory}/fp32_oracle"
"${oracle_directory}/fp32_oracle"
