library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
entity tb_cache_l1 is end;
architecture test of tb_cache_l1 is
    signal clk : std_logic := '0';
    signal rst, req, wr, ready, error, mv, mw, mr : std_logic := '0';
    signal a,d,q,ma,md,mq : std_logic_vector(31 downto 0) := (others=>'0');
    signal mask,mm : std_logic_vector(3 downto 0) := "1111";
    signal ac,h,mi,wb,cy : unsigned(31 downto 0);
    type mem_t is array(0 to 63) of std_logic_vector(31 downto 0);
    signal mem : mem_t := (others=>x"00000000");
    signal gate : std_logic := '0';
begin
    clk <= not clk after 5 ns;
    dut: entity work.cache_l1 generic map(2,1,false)
        port map(clk,rst,req,wr,a,d,mask,ready,error,q,mv,mw,ma,md,mm,mr,'0',mq,ac,h,mi,wb,cy);
    mr <= mv and gate;
    mq <= mem(to_integer(unsigned(ma(7 downto 2))));
    process(clk) begin if rising_edge(clk) then
        gate <= not gate;
        if mv='1' and mr='1' and mw='1' then mem(to_integer(unsigned(ma(7 downto 2)))) <= md; end if;
    end if; end process;
    process
        procedure access_word(address : natural; writing : std_logic; value : natural) is
        begin
            a<=std_logic_vector(to_unsigned(address,32)); d<=std_logic_vector(to_unsigned(value,32)); wr<=writing; req<='1';
            loop wait until rising_edge(clk); exit when ready='1'; end loop;
            assert error='0' severity failure;
            if writing='0' then assert unsigned(q)=value report "Cache data mismatch" severity failure; end if;
            req<='0'; wait until rising_edge(clk);
        end;
    begin
        rst<='1'; wait until rising_edge(clk); rst<='0'; wait until rising_edge(clk);
        access_word(0,'1',42); access_word(16,'1',84);
        assert mem(0)=x"00000000" report "Store must remain dirty in cache" severity failure;
        access_word(0,'0',42); access_word(32,'1',126);
        assert mem(4)=x"00000054" report "LRU dirty eviction missing" severity failure;
        access_word(16,'0',84); access_word(0,'0',42);
        assert wb>=2 and ac=6 and h=1 and mi=5 severity failure;
        report "tb_cache_l1 completed"; finish;
    end process;
    process begin wait for 20 us; assert false report "Cache timeout" severity failure; end process;
end;
