library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_fp_register_file is end tb_fp_register_file;
architecture Behavioral of tb_fp_register_file is
    signal clk, rst, write_enable : STD_LOGIC := '0';
    signal write_address, read_address1, read_address2 : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    signal write_data, read_data1, read_data2 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
begin
    dut : entity work.fp_register_file port map (clk, rst, write_enable, write_address, write_data,
                                                   read_address1, read_address2, read_data1, read_data2);
    clk <= not clk after 5 ns;
    process
    begin
        rst <= '1'; wait until rising_edge(clk); rst <= '0';
        write_enable <= '1'; write_address <= "00000"; write_data <= x"3F800000";
        wait until rising_edge(clk); wait for 1 ns; read_address1 <= "00000"; wait for 1 ns;
        assert read_data1 = x"3F800000" report "f0 must be writable" severity error;
        assert false report "tb_fp_register_file completed" severity note;
        wait;
    end process;
end Behavioral;
