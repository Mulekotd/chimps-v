library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_cache_l1 is end;

architecture test of tb_cache_l1 is
    signal clk : std_logic := '0';
    signal rst, req, wr, ready, error, mv, mw, mr, me, flush : std_logic := '0';
    signal a, d, q, ma, md, mq : std_logic_vector(31 downto 0) := (others => '0');
    signal mask, mm : std_logic_vector(3 downto 0) := "1111";
    signal ac, h, mi, wb, cy, stalls : unsigned(31 downto 0);
    type mem_t is array(0 to 63) of std_logic_vector(31 downto 0);
    signal mem : mem_t := (others => x"00000000");
    signal gate, backing_error : std_logic := '0';
begin
    clk <= not clk after 5 ns;
    dut : entity work.cache_l1
        generic map (WAYS => 2, SETS => 1, READ_ONLY => false)
        port map (clk => clk, rst => rst, req => req, wr => wr, addr => a, wdata => d, mask => mask,
                  ready => ready, error => error, rdata => q, mv => mv, mw => mw, ma => ma, md => md,
                  mm => mm, mr => mr, me => me, mq => mq, accesses => ac, hits => h, misses => mi,
                  writebacks => wb, service_cycles => cy, stall_cycles => stalls, flush => flush);
    mr <= mv and gate;
    me <= backing_error;
    mq <= mem(to_integer(unsigned(ma(7 downto 2))));

    process(clk)
    begin
        if rising_edge(clk) then
            gate <= not gate;
            if mv = '1' and mr = '1' and mw = '1' and backing_error = '0' then
                mem(to_integer(unsigned(ma(7 downto 2)))) <= md;
            end if;
        end if;
    end process;

    process
        procedure access_word(constant address : natural; constant writing : std_logic;
                              constant value : std_logic_vector(31 downto 0);
                              constant byte_mask : std_logic_vector(3 downto 0);
                              constant expected : std_logic_vector(31 downto 0);
                              constant expect_error : std_logic := '0') is
        begin
            a <= std_logic_vector(to_unsigned(address, 32)); d <= value; wr <= writing; mask <= byte_mask; req <= '1';
            loop wait until rising_edge(clk); exit when ready = '1'; end loop;
            assert error = expect_error report "Unexpected cache error result" severity failure;
            if writing = '0' and expect_error = '0' then
                assert q = expected report "Cache returned incorrect data" severity failure;
            end if;
            req <= '0'; wait until rising_edge(clk);
        end procedure;
        procedure flush_cache is
        begin
            flush <= '1';
            loop wait until rising_edge(clk); exit when ready = '1'; end loop;
            flush <= '0'; wait until rising_edge(clk);
        end procedure;
    begin
        rst <= '1'; wait until rising_edge(clk); rst <= '0'; wait until rising_edge(clk);
        -- Miss, masked write hit, and readback prove byte merging without write-through.
        access_word(0, '1', x"11223344", "1111", x"00000000");
        access_word(0, '1', x"0000AA00", "0010", x"00000000");
        access_word(0, '0', x"00000000", "0000", x"1122AA44");
        assert mem(0) = x"00000000" report "Dirty line was written through" severity failure;

        -- The second fill and a hit on line zero make line 16 the LRU victim.
        access_word(16, '1', x"00000054", "1111", x"00000000");
        access_word(0, '0', x"00000000", "0000", x"1122AA44");
        access_word(32, '1', x"0000007E", "1111", x"00000000");
        assert mem(4) = x"00000054" report "LRU dirty eviction did not write back line 16" severity failure;

        -- Flush commits every remaining dirty line and keeps the cache usable.
        flush_cache;
        assert mem(0) = x"1122AA44" and mem(8) = x"0000007E"
            report "Flush did not persist dirty cache lines" severity failure;
        access_word(0, '0', x"00000000", "0000", x"1122AA44");

        -- A backing-store refill failure must be returned to the client.
        backing_error <= '1';
        access_word(48, '0', x"00000000", "0000", x"00000000", '1');
        backing_error <= '0';
        assert ac = 8 and h = 4 and mi = 4 and wb = 3
            report "Cache access, hit, miss, or write-back counters are incorrect" severity failure;
        assert cy > stalls and stalls /= 0
            report "Service and stall-cycle counters are not observable" severity failure;
        report "tb_cache_l1 completed"; finish;
    end process;

    process begin wait for 20 us; assert false report "Cache timeout" severity failure; end process;
end;
