library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chimps_pkg.ALL;

entity main_memory is
    Port (
        clk                 : in  STD_LOGIC;
        rst                 : in  STD_LOGIC;
        instruction_address : in  STD_LOGIC_VECTOR(31 downto 0);
        instruction_data    : out STD_LOGIC_VECTOR(31 downto 0);
        data_address        : in  STD_LOGIC_VECTOR(31 downto 0);
        data_read_data      : out STD_LOGIC_VECTOR(31 downto 0);
        data_write_enable   : in  STD_LOGIC;
        data_write_data     : in  STD_LOGIC_VECTOR(31 downto 0);
        data_byte_enable    : in  STD_LOGIC_VECTOR(3 downto 0);
        load_enable         : in  STD_LOGIC;
        load_address        : in  STD_LOGIC_VECTOR(31 downto 0);
        load_data           : in  STD_LOGIC_VECTOR(31 downto 0);
        load_byte_enable    : in  STD_LOGIC_VECTOR(3 downto 0)
    );
end main_memory;

architecture Behavioral of main_memory is
    -- Memória backing Von Neumann unificada, representada como words de 32 bits.
    type memory_array_t is array (0 to (MEMORY_BYTES / 4) - 1) of STD_LOGIC_VECTOR(31 downto 0);
    signal memory : memory_array_t := (others => (others => '0'));

    function word_index(address : STD_LOGIC_VECTOR(31 downto 0)) return natural is
    begin
        return to_integer(unsigned(address(14 downto 2)));
    end function;
begin
    -- Escritas síncronas suportam tanto o carregamento do programa quanto stores de dados.
    process(clk)
        variable index : natural;
        variable updated_word : STD_LOGIC_VECTOR(31 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' and load_enable = '0' then
                memory <= (others => (others => '0'));
            elsif load_enable = '1' or data_write_enable = '1' then
                if load_enable = '1' then
                    index := word_index(load_address);
                    updated_word := memory(index);

                if load_byte_enable(0) = '1' then updated_word(7 downto 0) := load_data(7 downto 0); end if;
                    if load_byte_enable(1) = '1' then updated_word(15 downto 8) := load_data(15 downto 8); end if;
                    if load_byte_enable(2) = '1' then updated_word(23 downto 16) := load_data(23 downto 16); end if;
                    if load_byte_enable(3) = '1' then updated_word(31 downto 24) := load_data(31 downto 24); end if;
                else
                    index := word_index(data_address);
                    updated_word := memory(index);

                    if data_byte_enable(0) = '1' then updated_word(7 downto 0) := data_write_data(7 downto 0); end if;
                    if data_byte_enable(1) = '1' then updated_word(15 downto 8) := data_write_data(15 downto 8); end if;
                    if data_byte_enable(2) = '1' then updated_word(23 downto 16) := data_write_data(23 downto 16); end if;
                    if data_byte_enable(3) = '1' then updated_word(31 downto 24) := data_write_data(31 downto 24); end if;
                end if;

                memory(index) <= updated_word;
            end if;
        end if;
    end process;

    -- Leituras de instrução e dados são combinacionais neste modelo de referência.
    instruction_data <= memory(word_index(instruction_address));
    data_read_data <= memory(word_index(data_address));
end Behavioral;
