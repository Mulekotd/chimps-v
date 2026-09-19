library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_data_cache is end tb_data_cache;
architecture Behavioral of tb_data_cache is
    signal clk, rst, cpu_valid, cpu_write, cpu_ready, cpu_error : STD_LOGIC := '0';
    signal cpu_address, cpu_write_data, cpu_read_data : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal cpu_write_mask : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal memory_valid, memory_write, memory_ready, memory_error : STD_LOGIC := '0';
    signal memory_address, memory_write_data, memory_read_data : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal memory_write_mask : STD_LOGIC_VECTOR(3 downto 0);
    signal access_count, hit_count, miss_count : STD_LOGIC_VECTOR(31 downto 0);
    signal observed_write : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
begin
    dut : entity work.data_cache port map (clk, rst, cpu_valid, cpu_write, cpu_address,
        cpu_write_data, cpu_write_mask, cpu_ready, cpu_error, cpu_read_data, memory_valid,
        memory_write, memory_address, memory_write_data, memory_write_mask, memory_ready,
        memory_error, memory_read_data, access_count, hit_count, miss_count);
    clk <= not clk after 5 ns;
    memory_ready <= memory_valid;
    memory_error <= '0';
    memory_read_data <= x"01020304";
    process(clk)
    begin
        if rising_edge(clk) and memory_valid = '1' and memory_write = '1' then
            observed_write <= memory_write_data;
        end if;
    end process;
    process
    begin
        rst <= '1'; wait for 20 ns; rst <= '0';
        cpu_address <= x"00000000"; cpu_write_data <= x"AABBCCDD"; cpu_write_mask <= "1111";
        cpu_write <= '1'; cpu_valid <= '1';
        wait until rising_edge(clk) and cpu_ready = '1'; cpu_valid <= '0'; cpu_write <= '0';
        wait until rising_edge(clk) and cpu_ready = '1';
        assert observed_write = x"AABBCCDD" and miss_count = x"00000001"
            report "Data-cache write-through failed" severity error;
        assert false report "tb_data_cache completed" severity note;
        wait;
    end process;
end Behavioral;
