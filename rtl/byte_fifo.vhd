library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- FIFO síncrona de bytes com handshakes independentes de entrada e saída.
entity byte_fifo is
    generic (DEPTH : positive := 16);
    port (
        clk, rst   : in std_logic;
        push_valid : in std_logic;
        push_ready : out std_logic;
        push_data  : in std_logic_vector(7 downto 0);
        pop_valid  : out std_logic;
        pop_ready  : in std_logic;
        pop_data   : out std_logic_vector(7 downto 0)
    );
end byte_fifo;

architecture rtl of byte_fifo is
    type storage_t is array (0 to DEPTH - 1) of std_logic_vector(7 downto 0);
    signal storage : storage_t := (others => (others => '0'));
    signal head, tail : natural range 0 to DEPTH - 1 := 0;
    signal count : natural range 0 to DEPTH := 0;
begin
    push_ready <= '1' when count < DEPTH else '0';
    pop_valid <= '1' when count > 0 else '0';
    pop_data <= storage(head);

    process(clk)
        variable push, pop : boolean;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                head <= 0; tail <= 0; count <= 0;
            else
                push := push_valid = '1' and count < DEPTH;
                pop := pop_ready = '1' and count > 0;
                if push then
                    storage(tail) <= push_data;
                    if tail = DEPTH - 1 then tail <= 0; else tail <= tail + 1; end if;
                end if;
                if pop then
                    if head = DEPTH - 1 then head <= 0; else head <= head + 1; end if;
                end if;
                if push and not pop then count <= count + 1;
                elsif pop and not push then count <= count - 1;
                end if;
            end if;
        end if;
    end process;
end rtl;
