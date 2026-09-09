library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package chimps_pkg is
    -- Dimensões globais compartilhadas por todos os circuitos do CHIMPS-V.
    constant DATA_WIDTH : natural := 32;
    constant ADDR_WIDTH : natural := 32;
    constant REG_WIDTH  : natural := 5;
    constant MEMORY_BYTES : natural := 32768;
    constant CACHE_LINE_BYTES : natural := 16;
    constant CACHE_CAPACITY_BYTES : natural := 1024;
    constant CACHE_SETS : natural := CACHE_CAPACITY_BYTES / CACHE_LINE_BYTES;
    constant CACHE_WORDS_PER_LINE : natural := CACHE_LINE_BYTES / 4;

    -- Operações da ALU selecionadas pelo decoder de instruções.
    type alu_operation_t is (
        ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR, ALU_SLT, ALU_SLTU,
        ALU_COPY_B, ALU_NONE
    );

    -- Encodings de imediatos RISC-V suportados pelo datapath atual.
    type immediate_type_t is (IMM_NONE, IMM_I, IMM_S, IMM_B, IMM_U, IMM_J);

    constant OPCODE_OP       : STD_LOGIC_VECTOR(6 downto 0) := "0110011";
    constant OPCODE_OP_IMM   : STD_LOGIC_VECTOR(6 downto 0) := "0010011";
    constant OPCODE_LOAD     : STD_LOGIC_VECTOR(6 downto 0) := "0000011";
    constant OPCODE_STORE    : STD_LOGIC_VECTOR(6 downto 0) := "0100011";
    constant OPCODE_BRANCH   : STD_LOGIC_VECTOR(6 downto 0) := "1100011";
    constant OPCODE_JALR     : STD_LOGIC_VECTOR(6 downto 0) := "1100111";
    constant OPCODE_JAL      : STD_LOGIC_VECTOR(6 downto 0) := "1101111";
    constant OPCODE_LUI      : STD_LOGIC_VECTOR(6 downto 0) := "0110111";
    constant OPCODE_AUIPC    : STD_LOGIC_VECTOR(6 downto 0) := "0010111";
    constant OPCODE_SYSTEM   : STD_LOGIC_VECTOR(6 downto 0) := "1110011";

    -- Detector combinacional de zero usado pela ALU e pela lógica de branch.
    function is_zero(value : STD_LOGIC_VECTOR) return STD_LOGIC;
end package chimps_pkg;

package body chimps_pkg is
    function is_zero(value : STD_LOGIC_VECTOR) return STD_LOGIC is
    begin
        if unsigned(value) = 0 then
            return '1';
        end if;
        return '0';
    end function;
end package body chimps_pkg;
