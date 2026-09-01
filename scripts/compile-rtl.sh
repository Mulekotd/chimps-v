#!/usr/bin/env bash
set -euo pipefail

project_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_directory="${project_root}/build/ghdl"
lint_only=false

if [[ "${1:-}" == "--lint" ]]; then
    lint_only=true
    shift
fi
if [[ "$#" -ne 0 ]]; then
    echo "Uso: $0 [--lint]" >&2
    exit 64
fi

command -v ghdl >/dev/null 2>&1 || {
    echo "GHDL não foi encontrado." >&2
    exit 127
}

rtl_sources=(
    "${project_root}/rtl/chimps_pkg.vhd"
    "${project_root}/rtl/fp_pkg.vhd"
    "${project_root}/rtl/alu.vhd"
    "${project_root}/rtl/pc_reg.vhd"
    "${project_root}/rtl/imm_gen.vhd"
    "${project_root}/rtl/decoder.vhd"
    "${project_root}/rtl/register_file.vhd"
    "${project_root}/rtl/fp_register_file.vhd"
    "${project_root}/rtl/memory_backing_store.vhd"
    "${project_root}/rtl/memory_bus.vhd"
    "${project_root}/rtl/cache_l1.vhd"
    "${project_root}/rtl/fpu.vhd"
    "${project_root}/rtl/mul_div_unit.vhd"
    "${project_root}/rtl/core_rv32i_single.vhd"
    "${project_root}/rtl/chimps_v_system.vhd"
)

for source in "${rtl_sources[@]}"; do
    [[ -f "${source}" ]] || { echo "Fonte RTL ausente: ${source}" >&2; exit 66; }
done

ghdl -s --std=08 "${rtl_sources[@]}"

if "${lint_only}"; then
    echo "Lint RTL concluído."
    exit 0
fi

mkdir -p "${build_directory}"
rm -f -- "${build_directory}/work-obj08.cf"

for source in "${rtl_sources[@]}"; do
    ghdl -a --std=08 "--workdir=${build_directory}" "${source}"
done

mapfile -t test_sources < <(find "${project_root}/tests/vhdl" -maxdepth 1 -type f -name 'tb_*.vhd' | LC_ALL=C sort)
[[ "${#test_sources[@]}" -gt 0 ]] || { echo "Nenhum testbench encontrado." >&2; exit 66; }

for source in "${test_sources[@]}"; do
    ghdl -a --std=08 "--workdir=${build_directory}" "${source}"
done

for source in "${test_sources[@]}"; do
    testbench="$(basename "${source}" .vhd)"

    ghdl -e --std=08 "--workdir=${build_directory}" "${testbench}"
    ghdl -r --std=08 "--workdir=${build_directory}" "${testbench}" --assert-level=error --stop-time=1ms
done

echo "Compilação e ${#test_sources[@]} testbenches concluídos."
