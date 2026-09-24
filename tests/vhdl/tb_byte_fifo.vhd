library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_byte_fifo is end;
architecture test of tb_byte_fifo is
    signal clk, rst, push_valid, push_ready, pop_valid, pop_ready : std_logic := '0';
    signal push_data, pop_data : std_logic_vector(7 downto 0) := (others => '0');
begin
    clk <= not clk after 5 ns;
    dut : entity work.byte_fifo generic map (DEPTH => 2)
        port map (clk, rst, push_valid, push_ready, push_data, pop_valid, pop_ready, pop_data);
    process
        procedure push(constant value : std_logic_vector(7 downto 0)) is
        begin
            assert push_ready = '1' report "FIFO did not accept available input" severity failure;
            push_data <= value; push_valid <= '1'; wait until rising_edge(clk); push_valid <= '0'; wait for 1 ns;
        end procedure;
        procedure pop(constant expected : std_logic_vector(7 downto 0)) is
        begin
            assert pop_valid = '1' and pop_data = expected report "FIFO order/data mismatch" severity failure;
            pop_ready <= '1'; wait until rising_edge(clk); pop_ready <= '0'; wait for 1 ns;
        end procedure;
    begin
        rst <= '1'; wait until rising_edge(clk); rst <= '0'; wait for 1 ns;
        push(x"11"); push(x"22"); wait for 1 ns;
        assert push_ready = '0' and pop_valid = '1' report "FIFO full backpressure failed" severity failure;
        pop(x"11"); wait for 1 ns;
        assert push_ready = '1' report "FIFO did not release backpressure after pop" severity failure;
        push(x"33"); pop(x"22"); pop(x"33"); wait for 1 ns;
        assert pop_valid = '0' report "FIFO empty state failed" severity failure;
        report "tb_byte_fifo completed"; finish;
    end process;
end;
