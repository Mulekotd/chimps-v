library ieee;
use ieee.std_logic_1164.all;

entity tb_chimps_v_invalid is
end tb_chimps_v_invalid;

architecture test of tb_chimps_v_invalid is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal load_valid : std_logic := '1';
    signal load_address : std_logic_vector(31 downto 0) := (others => '0');
    signal load_data : std_logic_vector(31 downto 0) := x"020000B3"; -- mul x1,x0,x0
    signal load_mask : std_logic_vector(3 downto 0) := "1111";
    signal load_ready : std_logic;
    signal debug_address, debug_data, current_pc, current_instruction : std_logic_vector(31 downto 0) := (others => '0');
    signal retired, halted, illegal_instruction : std_logic;
    signal pipeline_valid : std_logic_vector(3 downto 0);
    signal cache_accesses, cache_hits, cache_misses : std_logic_vector(31 downto 0);
begin
    clk <= not clk after 5 ns;

    dut : entity work.chimps_v_system
        port map (
            clk => clk, rst => rst, load_valid => load_valid, load_address => load_address, load_data => load_data,
            load_mask => load_mask, load_ready => load_ready, debug_address => debug_address, debug_data => debug_data,
            current_pc => current_pc, current_instruction => current_instruction, retired => retired, halted => halted,
            illegal_instruction => illegal_instruction, pipeline_valid => pipeline_valid, cache_accesses => cache_accesses,
            cache_hits => cache_hits, cache_misses => cache_misses);

    stimulus : process
    begin
        wait until rising_edge(clk);
        assert load_ready = '1' report "loader did not accept MUL encoding" severity error;

        load_valid <= '0';
        rst <= '0';

        wait until halted = '1' for 2 us;
        assert halted = '1' and illegal_instruction = '1' report "unsupported RV32M encoding was not rejected" severity error;
        assert retired = '0' report "unsupported instruction retired" severity error;
        report "tb_chimps_v_invalid passed" severity note;

        wait;
    end process;
end test;
