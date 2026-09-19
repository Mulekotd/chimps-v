library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_ram is end tb_ram;
architecture Behavioral of tb_ram is
    signal clk, rst, data_write_enable, load_enable : STD_LOGIC := '0';
    signal instruction_address, instruction_data, data_address, data_read_data, data_write_data, load_address, load_data : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal data_byte_enable, load_byte_enable : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
begin
    dut : entity work.main_memory port map (clk, rst, instruction_address, instruction_data,
        data_address, data_read_data, data_write_enable, data_write_data, data_byte_enable,
        load_enable, load_address, load_data, load_byte_enable);
    clk <= not clk after 5 ns;
    process
    begin
        rst <= '1'; wait until rising_edge(clk); rst <= '0';
        load_address <= x"00000000"; load_data <= x"11223344"; load_byte_enable <= "1111"; load_enable <= '1';
        wait until rising_edge(clk); load_enable <= '0'; instruction_address <= x"00000000"; wait for 1 ns;
        assert instruction_data = x"11223344" report "Program image load failed" severity error;
        data_address <= x"00000000"; data_write_data <= x"AAAABBBB"; data_byte_enable <= "0011"; data_write_enable <= '1';
        wait until rising_edge(clk); data_write_enable <= '0'; wait for 1 ns;
        assert data_read_data = x"1122BBBB" report "RAM byte mask failed" severity error;
        assert false report "tb_ram completed" severity note;
        wait;
    end process;
end Behavioral;
