library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_mmio_uart is end;
architecture test of tb_mmio_uart is
    signal clk, rst, valid, write, ready, error, rx_valid, rx_ready, tx_valid, tx_ready, sim_halt : std_logic := '0';
    signal address, wdata, rdata : std_logic_vector(31 downto 0) := (others => '0');
    signal wmask : std_logic_vector(3 downto 0) := "1111";
    signal rx_data, tx_data : std_logic_vector(7 downto 0) := (others => '0');
begin
    clk <= not clk after 5 ns;
    dut : entity work.mmio_uart port map (clk, rst, valid, write, address, wdata, wmask, ready, error, rdata,
        rx_valid, rx_data, rx_ready, tx_valid, tx_data, tx_ready, sim_halt);
    process
        procedure transact(constant a : std_logic_vector(31 downto 0); constant is_write : std_logic;
                         constant value : std_logic_vector(31 downto 0)) is
        begin
            address <= a; write <= is_write; wdata <= value; valid <= '1';
            loop wait until rising_edge(clk); exit when ready = '1'; end loop;
            valid <= '0'; wait until rising_edge(clk);
        end procedure;
    begin
        rst <= '1'; wait until rising_edge(clk); rst <= '0'; wait for 1 ns;
        transact(x"FFFF0000", '1', x"00000041"); wait for 1 ns;
        assert tx_valid = '1' and tx_data = x"41" report "TX FIFO did not retain byte" severity failure;
        tx_ready <= '1'; wait until rising_edge(clk); tx_ready <= '0'; wait for 1 ns;
        assert tx_valid = '0' report "TX FIFO did not dequeue byte" severity failure;
        rx_data <= x"52"; rx_valid <= '1'; wait until rising_edge(clk); rx_valid <= '0';
        transact(x"FFFF000C", '0', x"00000000");
        assert rdata(0) = '1' report "RX status did not report available byte" severity failure;
        address <= x"FFFF0008"; write <= '0'; valid <= '1'; wait for 1 ns;
        assert ready = '1' and rdata(7 downto 0) = x"52" report "RX data read failed" severity failure;
        wait until rising_edge(clk); valid <= '0'; wait until rising_edge(clk);
        transact(x"FFFF0010", '1', x"00000001");
        assert sim_halt = '1' report "SIM_CONTROL did not pulse halt" severity failure;
        address <= x"FFFF0020"; valid <= '1'; wait for 1 ns;
        assert ready = '1' and error = '1' report "Invalid MMIO address was accepted" severity failure;
        valid <= '0'; report "tb_mmio_uart completed"; finish;
    end process;
end;
