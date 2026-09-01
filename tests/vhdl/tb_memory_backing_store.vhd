library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_memory_backing_store is end tb_memory_backing_store;

architecture Behavioral of tb_memory_backing_store is
    signal clk, rst, load_valid, load_ready, request_valid, request_write, request_ready, request_error : STD_LOGIC := '0';
    signal load_address, load_data, request_address, request_wdata, request_rdata, debug_address, debug_data : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal load_mask, request_wmask : STD_LOGIC_VECTOR(3 downto 0) := "1111";
begin
    dut : entity work.memory_backing_store
        port map (clk => clk, rst => rst, load_valid => load_valid, load_address => load_address,
                  load_data => load_data, load_mask => load_mask, load_ready => load_ready,
                  request_valid => request_valid, request_write => request_write,
                  request_address => request_address, request_wdata => request_wdata,
                  request_wmask => request_wmask, request_ready => request_ready,
                  request_rdata => request_rdata, request_error => request_error,
                  debug_address => debug_address, debug_data => debug_data);
    clk <= not clk after 5 ns;
    process
    begin
        rst <= '1'; wait until rising_edge(clk);
        load_valid <= '1'; load_address <= x"00010000"; load_data <= x"11223344";
        wait until rising_edge(clk);
        assert load_ready = '1' report "Loader rejected valid upper RAM word" severity error;
        load_valid <= '0'; rst <= '0'; debug_address <= x"00010000"; wait for 1 ns;
        assert debug_data = x"11223344" report "Upper RAM word was not stored" severity error;
        debug_address <= x"00000000"; wait for 1 ns;
        assert debug_data = x"00000000" report "Upper RAM word aliased low RAM" severity error;
        request_valid <= '1'; request_address <= x"00018000"; wait for 1 ns;
        assert request_ready = '1' and request_error = '1' and request_rdata = x"00000000"
            report "Out-of-range backing request was not rejected" severity error;
        request_address <= x"00000002"; wait for 1 ns;
        assert request_error = '1' report "Misaligned backing request was not rejected" severity error;
        assert false report "tb_memory_backing_store completed" severity note;
        wait;
    end process;
end Behavioral;
