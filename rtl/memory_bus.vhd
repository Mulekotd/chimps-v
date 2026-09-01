library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Árbitro combinacional de duas portas para a memória backing compartilhada.
-- A porta de dados tem prioridade fixa sobre a porta de instruções; a resposta
-- retorna somente ao cliente selecionado no ciclo do handshake.
entity memory_bus is
    Port (
        instruction_valid, instruction_write : in STD_LOGIC;
        instruction_address, instruction_wdata : in STD_LOGIC_VECTOR(31 downto 0);
        instruction_wmask : in STD_LOGIC_VECTOR(3 downto 0);
        instruction_ready : out STD_LOGIC;
        instruction_rdata : out STD_LOGIC_VECTOR(31 downto 0);
        instruction_error : out STD_LOGIC;

        data_valid, data_write : in STD_LOGIC;
        data_address, data_wdata : in STD_LOGIC_VECTOR(31 downto 0);
        data_wmask : in STD_LOGIC_VECTOR(3 downto 0);
        data_ready : out STD_LOGIC;
        data_rdata : out STD_LOGIC_VECTOR(31 downto 0);
        data_error : out STD_LOGIC;

        memory_valid, memory_write : out STD_LOGIC;
        memory_address, memory_wdata : out STD_LOGIC_VECTOR(31 downto 0);
        memory_wmask : out STD_LOGIC_VECTOR(3 downto 0);
        memory_ready : in STD_LOGIC;
        memory_rdata : in STD_LOGIC_VECTOR(31 downto 0);
        memory_error : in STD_LOGIC
    );
end memory_bus;

architecture Behavioral of memory_bus is
begin
    process(all)
    begin
        instruction_ready <= '0'; instruction_rdata <= (others => '0'); instruction_error <= '0';
        data_ready <= '0'; data_rdata <= (others => '0'); data_error <= '0';
        memory_valid <= '0'; memory_write <= '0'; memory_address <= (others => '0');
        memory_wdata <= (others => '0'); memory_wmask <= (others => '0');

        if data_valid = '1' then
            memory_valid <= '1'; memory_write <= data_write; memory_address <= data_address;
            memory_wdata <= data_wdata; memory_wmask <= data_wmask;
            data_ready <= memory_ready; data_rdata <= memory_rdata; data_error <= memory_error when memory_ready = '1' else '0';
        elsif instruction_valid = '1' then
            memory_valid <= '1'; memory_write <= instruction_write; memory_address <= instruction_address;
            memory_wdata <= instruction_wdata; memory_wmask <= instruction_wmask;
            instruction_ready <= memory_ready; instruction_rdata <= memory_rdata;
            instruction_error <= memory_error when memory_ready = '1' else '0';
        end if;
    end process;
end Behavioral;
