library ieee;
use ieee.std_logic_1164.all;

-- Árbitro de uma transação: mantém o cliente escolhido até a resposta da cache.
entity memory_bus is
    port (
        clk, rst : in std_logic;
        instruction_valid, instruction_write : in std_logic;
        instruction_address, instruction_wdata : in std_logic_vector(31 downto 0);
        instruction_wmask : in std_logic_vector(3 downto 0);
        instruction_ready : out std_logic;
        instruction_rdata : out std_logic_vector(31 downto 0);
        instruction_error : out std_logic;
        data_valid, data_write : in std_logic;
        data_address, data_wdata : in std_logic_vector(31 downto 0);
        data_wmask : in std_logic_vector(3 downto 0);
        data_ready : out std_logic;
        data_rdata : out std_logic_vector(31 downto 0);
        data_error : out std_logic;
        memory_valid, memory_write : out std_logic;
        memory_address, memory_wdata : out std_logic_vector(31 downto 0);
        memory_wmask : out std_logic_vector(3 downto 0);
        memory_ready : in std_logic;
        memory_rdata : in std_logic_vector(31 downto 0);
        memory_error : in std_logic
    );
end memory_bus;

architecture rtl of memory_bus is
    signal busy, selected_data : std_logic := '0';
begin
    process (all)
        variable select_data : std_logic;
    begin
        select_data := selected_data;

        if busy = '0' then
            if data_valid = '1' then select_data := '1'; else select_data := '0'; end if;
        end if;

        instruction_ready <= '0'; instruction_rdata <= (others => '0'); instruction_error <= '0';
        data_ready <= '0'; data_rdata <= (others => '0'); data_error <= '0';
        memory_valid <= '0'; memory_write <= '0'; memory_address <= (others => '0'); memory_wdata <= (others => '0'); memory_wmask <= (others => '0');

        if busy = '1' or data_valid = '1' or instruction_valid = '1' then
            memory_valid <= '1';

            if select_data = '1' then
                memory_write <= data_write; memory_address <= data_address; memory_wdata <= data_wdata; memory_wmask <= data_wmask;
                data_ready <= memory_ready; data_rdata <= memory_rdata; data_error <= memory_error when memory_ready = '1' else '0';
            else
                memory_write <= instruction_write; memory_address <= instruction_address; memory_wdata <= instruction_wdata; memory_wmask <= instruction_wmask;
                instruction_ready <= memory_ready; instruction_rdata <= memory_rdata; instruction_error <= memory_error when memory_ready = '1' else '0';
            end if;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                busy <= '0'; selected_data <= '0';
            elsif busy = '0' then
                if data_valid = '1' then busy <= '1'; selected_data <= '1'; elsif instruction_valid = '1' then busy <= '1'; selected_data <= '0'; end if;
            elsif memory_ready = '1' then
                busy <= '0';
            end if;
        end if;
    end process;
end rtl;
