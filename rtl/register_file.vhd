library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity register_file is
    Port (
        clk          : in  STD_LOGIC;
        rst          : in  STD_LOGIC;
        write_enable : in  STD_LOGIC;
        write_address: in  STD_LOGIC_VECTOR(4 downto 0);
        write_data   : in  STD_LOGIC_VECTOR(31 downto 0);
        read_address1: in  STD_LOGIC_VECTOR(4 downto 0);
        read_address2: in  STD_LOGIC_VECTOR(4 downto 0);
        read_data1   : out STD_LOGIC_VECTOR(31 downto 0);
        read_data2   : out STD_LOGIC_VECTOR(31 downto 0)
    );
end register_file;

architecture Behavioral of register_file is
    -- 32 registradores inteiros arquiteturais; x0 é imposto nas portas.
    type register_array_t is array (0 to 31) of STD_LOGIC_VECTOR(31 downto 0);
    signal registers : register_array_t := (others => (others => '0'));
begin
    -- Escritas ocorrem somente na borda de subida e nunca modificam x0.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                registers <= (others => (others => '0'));
            elsif write_enable = '1' and write_address /= "00000" then
                registers(to_integer(unsigned(write_address))) <= write_data;
            end if;
        end if;
    end process;

    -- Leituras são combinacionais para que decode consuma ambos os operandos em um ciclo.
    read_data1 <= (others => '0') when read_address1 = "00000" else registers(to_integer(unsigned(read_address1)));
    read_data2 <= (others => '0') when read_address2 = "00000" else registers(to_integer(unsigned(read_address2)));
end Behavioral;
