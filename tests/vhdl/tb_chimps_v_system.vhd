library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_chimps_v_system is
end tb_chimps_v_system;

architecture test of tb_chimps_v_system is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal load_valid : std_logic := '0';
    signal load_address, load_data : std_logic_vector(31 downto 0) := (others => '0');
    signal load_mask : std_logic_vector(3 downto 0) := "1111";
    signal load_ready : std_logic;
    signal debug_address, debug_data : std_logic_vector(31 downto 0) := (others => '0');
    signal current_pc, current_instruction : std_logic_vector(31 downto 0);
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
        procedure load_word(address : natural; value : std_logic_vector(31 downto 0)) is
        begin
            load_address <= std_logic_vector(to_unsigned(address, 32));
            load_data <= value;
            load_valid <= '1';
            wait until rising_edge(clk);
            assert load_ready = '1' report "loader did not accept an aligned RAM word" severity error;
        end procedure;
    begin
        load_word(0,  x"00500093"); -- addi x1,x0,5
        load_word(4,  x"00308113"); -- addi x2,x1,3: RAW dependency
        load_word(8,  x"04202023"); -- sw x2,64(x0)
        load_word(12, x"04002183"); -- lw x3,64(x0): data-cache miss
        load_word(16, x"04002203"); -- lw x4,64(x0): data-cache hit
        load_word(20, x"00000463"); -- beq x0,x0,8
        load_word(24, x"04102223"); -- sw x1,68(x0): must be flushed
        load_word(28, x"00100073"); -- ebreak
        load_word(32, x"00100073"); -- fetched while the first EBREAK drains
        load_word(36, x"00100073"); -- keeps speculative fetch inside the subset

        load_valid <= '0';
        rst <= '0';
        wait until halted = '1' for 20 us;

        assert halted = '1' report "pipeline did not drain to EBREAK" severity error;
        assert illegal_instruction = '0' report "valid simplified-RV32I program was rejected" severity error;
        debug_address <= x"00000040";
        wait for 1 ns;
        assert debug_data = x"00000008" report "RAW stall, store, load, or write-through failed" severity error;
        debug_address <= x"00000044";
        wait for 1 ns;
        assert debug_data = x"00000000" report "taken BEQ did not flush the younger store" severity error;
        assert unsigned(cache_misses) > 0 report "program must demonstrate at least one cache miss" severity error;
        assert unsigned(cache_hits) > 0 report "program must demonstrate at least one cache hit" severity error;
        assert unsigned(cache_accesses) = unsigned(cache_hits) + unsigned(cache_misses) report "cache counters are inconsistent" severity error;
        report "tb_chimps_v_system passed" severity note;
        wait;
    end process;
end test;
