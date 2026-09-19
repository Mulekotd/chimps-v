library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_instruction_cache is end tb_instruction_cache;
architecture Behavioral of tb_instruction_cache is
    signal clk, rst, cpu_valid, cpu_ready, cpu_error : STD_LOGIC := '0';
    signal cpu_address, cpu_read_data : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal memory_valid, memory_write, memory_ready, memory_error : STD_LOGIC := '0';
    signal memory_address, memory_write_data, memory_read_data : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal memory_write_mask : STD_LOGIC_VECTOR(3 downto 0);
    signal access_count, hit_count, miss_count : STD_LOGIC_VECTOR(31 downto 0);
begin
    dut : entity work.instruction_cache port map (clk, rst, cpu_valid, cpu_address,
        cpu_ready, cpu_error, cpu_read_data, memory_valid, memory_write, memory_address,
        memory_write_data, memory_write_mask, memory_ready, memory_error, memory_read_data,
        access_count, hit_count, miss_count);
    clk <= not clk after 5 ns;
    memory_ready <= memory_valid;
    memory_error <= '0';
    memory_read_data <= x"CAFEBABE" when memory_address(5 downto 2) = "0000" else x"00000000";
    process
    begin
        rst <= '1'; wait for 20 ns; rst <= '0';
        cpu_address <= x"00000000"; cpu_valid <= '1';
        wait until rising_edge(clk) and cpu_ready = '1'; cpu_valid <= '0';
        wait until rising_edge(clk) and cpu_ready = '1';
        assert cpu_read_data = x"CAFEBABE" and memory_write = '0' and miss_count = x"00000001"
            report "Instruction-cache read-only refill failed" severity error;
        assert false report "tb_instruction_cache completed" severity note;
        wait;
    end process;
end Behavioral;
