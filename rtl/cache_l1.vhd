library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Completion handshake: hold req and payload until ready at a rising edge.
entity cache_l1 is
    generic (WAYS : positive := 2; SETS : positive := 32; READ_ONLY : boolean := false);
    port (
        clk, rst, req, wr : in std_logic;
        addr, wdata : in std_logic_vector(31 downto 0);
        mask : in std_logic_vector(3 downto 0);
        ready, error : out std_logic;
        rdata : out std_logic_vector(31 downto 0);
        mv, mw : out std_logic;
        ma, md : out std_logic_vector(31 downto 0);
        mm : out std_logic_vector(3 downto 0);
        mr, me : in std_logic;
        mq : in std_logic_vector(31 downto 0);
        accesses, hits, misses, writebacks, service_cycles : out unsigned(31 downto 0);
        flush : in std_logic := '0'
    );
end;
architecture rtl of cache_l1 is
    subtype word is std_logic_vector(31 downto 0);
    type words is array(0 to 3) of word;
    type line is record
        valid, dirty : boolean;
        base : word;
        data : words;
    end record;
    type store is array(0 to SETS-1, 0 to WAYS-1) of line;
    signal lines : store;
    type victims is array(0 to SETS-1) of natural range 0 to WAYS-1;
    signal lru : victims := (others => 0);
    type states is (idle, lookup, evict, refill, respond, scan);
    signal state : states := idle;
    signal a, d, q : word := (others => '0');
    signal m : std_logic_vector(3 downto 0);
    signal write_req, err, flushing : std_logic := '0';
    signal si : natural range 0 to SETS-1 := 0;
    signal way : natural range 0 to WAYS-1 := 0;
    signal wi : natural range 0 to 3 := 0;
    signal count_a, count_h, count_m, count_w, count_c : unsigned(31 downto 0) := (others => '0');
    function index_of(v : word) return natural is
    begin return to_integer(unsigned(v(30 downto 4))) mod SETS; end;
begin
    assert WAYS <= 2 report "Only direct and two-way LRU supported" severity failure;
    ready <= '1' when state = respond else '0'; error <= err; rdata <= q;
    accesses <= count_a; hits <= count_h; misses <= count_m;
    writebacks <= count_w; service_cycles <= count_c;
    mv <= '1' when state = evict or state = refill else '0';
    mw <= '1' when state = evict else '0';
    ma <= std_logic_vector(unsigned(lines(si,way).base) + wi*4) when state = evict else
          std_logic_vector(unsigned(a(31 downto 4) & "0000") + wi*4);
    md <= lines(si,way).data(wi); mm <= "1111";
    process(clk)
        variable hit, victim, wordno : integer;
        variable merged : word;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= idle; err <= '0'; q <= (others => '0'); flushing <= '0';
                count_a <= (others => '0'); count_h <= (others => '0'); count_m <= (others => '0');
                count_w <= (others => '0'); count_c <= (others => '0'); lru <= (others => 0);
                for s in 0 to SETS-1 loop
                    for w in 0 to WAYS-1 loop
                        lines(s,w) <= (false, false, (others => '0'), (others => (others => '0')));
                    end loop;
                end loop;
            else
                if state /= idle and flushing = '0' then count_c <= count_c + 1; end if;
                case state is
                    when idle =>
                        err <= '0';
                        if flush = '1' then
                            flushing <= '1'; si <= 0; way <= 0; state <= scan;
                        elsif req = '1' then
                            a <= addr; d <= wdata; m <= mask; write_req <= wr;
                            si <= index_of(addr); count_a <= count_a + 1; state <= lookup;
                        end if;
                    when lookup =>
                        hit := -1; victim := lru(si); wordno := to_integer(unsigned(a(3 downto 2)));
                        for w in 0 to WAYS-1 loop
                            if lines(si,w).valid and lines(si,w).base = (a(31 downto 4) & "0000") then hit := w; end if;
                            if not lines(si,w).valid then victim := w; end if;
                        end loop;
                        if READ_ONLY and write_req = '1' then err <= '1'; state <= respond;
                        elsif hit >= 0 then
                            count_h <= count_h + 1; lru(si) <= (hit+1) mod WAYS;
                            q <= lines(si,hit).data(wordno);
                            if write_req = '1' then
                                merged := lines(si,hit).data(wordno);
                                for b in 0 to 3 loop
                                    if m(b) = '1' then merged(b*8+7 downto b*8) := d(b*8+7 downto b*8); end if;
                                end loop;
                                lines(si,hit).data(wordno) <= merged; lines(si,hit).dirty <= true;
                            end if;
                            state <= respond;
                        else
                            count_m <= count_m + 1; way <= victim; wi <= 0;
                            if lines(si,victim).valid and lines(si,victim).dirty then state <= evict;
                            else lines(si,victim).valid <= false; state <= refill; end if;
                        end if;
                    when evict =>
                        if mr = '1' then
                            if me = '1' then err <= '1'; state <= respond;
                            elsif wi = 3 then
                                count_w <= count_w + 1; lines(si,way).dirty <= false;
                                if flushing = '1' then state <= scan;
                                else lines(si,way).valid <= false; wi <= 0; state <= refill; end if;
                            else wi <= wi+1; end if;
                        end if;
                    when refill =>
                        if mr = '1' then
                            if me = '1' then err <= '1'; q <= (others => '0'); state <= respond;
                            else
                                merged := mq;
                                if write_req = '1' and wi = to_integer(unsigned(a(3 downto 2))) then
                                    for b in 0 to 3 loop
                                        if m(b) = '1' then merged(b*8+7 downto b*8) := d(b*8+7 downto b*8); end if;
                                    end loop;
                                end if;
                                lines(si,way).data(wi) <= merged;
                                if wi = to_integer(unsigned(a(3 downto 2))) then q <= merged; end if;
                                if wi = 3 then
                                    lines(si,way).valid <= true; lines(si,way).dirty <= write_req = '1';
                                    lines(si,way).base <= a(31 downto 4) & "0000";
                                    lru(si) <= (way+1) mod WAYS; state <= respond;
                                else wi <= wi+1; end if;
                            end if;
                        end if;
                    when scan =>
                        if lines(si,way).valid and lines(si,way).dirty then wi <= 0; state <= evict;
                        elsif way < WAYS-1 then way <= way+1;
                        elsif si < SETS-1 then si <= si+1; way <= 0;
                        else state <= respond; end if;
                    when respond => state <= idle; flushing <= '0';
                end case;
            end if;
        end if;
    end process;
end;
