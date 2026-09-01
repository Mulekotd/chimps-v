library ieee;
use ieee.std_logic_1164.all;

package chimps_pkg is
    constant DATA_WIDTH : natural := 32;
    constant ADDR_WIDTH : natural := 32;
    constant MEMORY_BYTES : natural := 98304;
    constant CACHE_LINES : natural := 16;

    constant OPCODE_OP : std_logic_vector(6 downto 0) := "0110011";
    constant OPCODE_OP_IMM : std_logic_vector(6 downto 0) := "0010011";
    constant OPCODE_LOAD : std_logic_vector(6 downto 0) := "0000011";
    constant OPCODE_STORE : std_logic_vector(6 downto 0) := "0100011";
    constant OPCODE_BRANCH : std_logic_vector(6 downto 0) := "1100011";
    constant OPCODE_SYSTEM : std_logic_vector(6 downto 0) := "1110011";
end package chimps_pkg;
