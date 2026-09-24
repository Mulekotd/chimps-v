library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- UART MMIO: TX/RX assíncronos ao software, ambos protegidos por FIFO.
entity mmio_uart is
    port (
        clk, rst       : in std_logic;
        valid, write   : in std_logic;
        address, wdata : in std_logic_vector(31 downto 0);
        wmask          : in std_logic_vector(3 downto 0);
        ready, error   : out std_logic;
        rdata          : out std_logic_vector(31 downto 0);
        uart_rx_valid  : in std_logic;
        uart_rx_data   : in std_logic_vector(7 downto 0);
        uart_rx_ready  : out std_logic;
        uart_tx_valid  : out std_logic;
        uart_tx_data   : out std_logic_vector(7 downto 0);
        uart_tx_ready  : in std_logic;
        sim_halt       : out std_logic
    );
end mmio_uart;

architecture rtl of mmio_uart is
    constant TX_DATA_ADDR : std_logic_vector(31 downto 0) := x"FFFF0000";
    constant TX_STATUS_ADDR : std_logic_vector(31 downto 0) := x"FFFF0004";
    constant RX_DATA_ADDR : std_logic_vector(31 downto 0) := x"FFFF0008";
    constant RX_STATUS_ADDR : std_logic_vector(31 downto 0) := x"FFFF000C";
    constant SIM_CONTROL_ADDR : std_logic_vector(31 downto 0) := x"FFFF0010";
    signal tx_push_ready, tx_pop_valid, rx_push_ready, rx_pop_valid : std_logic;
    signal tx_push, rx_pop : std_logic;
    signal rx_pop_data : std_logic_vector(7 downto 0);
begin
    tx_fifo : entity work.byte_fifo port map (clk => clk, rst => rst, push_valid => tx_push,
        push_ready => tx_push_ready, push_data => wdata(7 downto 0), pop_valid => tx_pop_valid,
        pop_ready => uart_tx_ready, pop_data => uart_tx_data);

    rx_fifo : entity work.byte_fifo port map (clk => clk, rst => rst, push_valid => uart_rx_valid,
        push_ready => rx_push_ready, push_data => uart_rx_data, pop_valid => rx_pop_valid,
        pop_ready => rx_pop, pop_data => rx_pop_data);

    uart_rx_ready <= rx_push_ready;
    uart_tx_valid <= tx_pop_valid;

    tx_push <= valid and write and wmask(0) when address = TX_DATA_ADDR else '0';
    rx_pop <= valid and not write when address = RX_DATA_ADDR else '0';

    error <= '1' when valid = '1' and address /= TX_DATA_ADDR and address /= TX_STATUS_ADDR and
                        address /= RX_DATA_ADDR and address /= RX_STATUS_ADDR and address /= SIM_CONTROL_ADDR else '0';
    
    ready <= '0' when valid = '0' else
            tx_push_ready when address = TX_DATA_ADDR and write = '1' else
            rx_pop_valid when address = RX_DATA_ADDR and write = '0' else '1';

    process(all)
    begin
        rdata <= (others => '0');

        if address = RX_DATA_ADDR then rdata(7 downto 0) <= rx_pop_data;
        elsif address = TX_STATUS_ADDR then rdata(0) <= tx_push_ready; rdata(1) <= not tx_pop_valid;
        elsif address = RX_STATUS_ADDR then rdata(0) <= rx_pop_valid; rdata(1) <= rx_push_ready;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then sim_halt <= '0';
            elsif valid = '1' and write = '1' and address = SIM_CONTROL_ADDR and wmask(0) = '1' and wdata(0) = '1' then
                sim_halt <= '1';
            else sim_halt <= '0';
            end if;
        end if;
    end process;
end rtl;
