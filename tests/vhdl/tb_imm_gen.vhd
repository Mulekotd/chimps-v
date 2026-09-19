library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.chimps_pkg.ALL;

entity tb_imm_gen is end tb_imm_gen;
architecture Behavioral of tb_imm_gen is
    signal instruction, immediate : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal immediate_type : immediate_type_t := IMM_NONE;
begin
    dut : entity work.immediate_generator port map (instruction, immediate_type, immediate);
    process
    begin
        instruction <= x"FFF00093"; immediate_type <= IMM_I; wait for 1 ns;
        assert immediate = x"FFFFFFFF" report "I immediate sign extension failed" severity error;
        instruction <= x"FE208EE3"; immediate_type <= IMM_B; wait for 1 ns;
        assert immediate = x"FFFFFFFC" report "B immediate reconstruction failed" severity error;
        instruction <= x"12345037"; immediate_type <= IMM_U; wait for 1 ns;
        assert immediate = x"12345000" report "U immediate reconstruction failed" severity error;
        assert false report "tb_imm_gen completed" severity note;
        wait;
    end process;
end Behavioral;
