library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_core_rv32i_single is end tb_core_rv32i_single;
architecture Behavioral of tb_core_rv32i_single is
    signal clk, rst, load_enable, retired, illegal_instruction : STD_LOGIC := '0';
    signal load_address, load_data, current_pc, current_instruction, current_alu_result : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal memory_address, memory_write_data : STD_LOGIC_VECTOR(31 downto 0);
    signal memory_write_enable : STD_LOGIC;
begin
    dut : entity work.core_rv32i_single
        port map (clk, rst, current_pc, current_instruction, current_alu_result,
                  memory_address, memory_write_data, memory_write_enable,
                  load_enable, load_address, load_data, retired, illegal_instruction);
    clk <= not clk after 5 ns;
    process
    begin
        -- Carrega ADDI x1,x0,5 e SW x1,0(x0) mantendo o PC em reset.
        rst <= '1'; load_enable <= '1'; load_address <= x"00000000"; load_data <= x"00500093";
        wait until rising_edge(clk);
        load_address <= x"00000004"; load_data <= x"00102023";
        wait until rising_edge(clk);
        load_enable <= '0'; rst <= '0';
        wait until rising_edge(clk); wait for 1 ns;
        assert current_pc = x"00000004" and current_instruction = x"00102023" and retired = '1'
            report "Core did not retire ADDI" severity error;
        assert memory_write_enable = '1' and memory_address = x"00000000" and memory_write_data = x"00000005"
            report "Core store path failed" severity error;
        wait until rising_edge(clk); wait for 1 ns;
        assert illegal_instruction = '1' report "Illegal instruction status failed" severity error;
        assert false report "tb_core_rv32i_single completed" severity note;
        wait;
    end process;
end Behavioral;
