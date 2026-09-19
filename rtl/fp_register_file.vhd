library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Banco arquitetural de 32 FPRs; diferentemente de x0, f0 é gravável.
entity fp_register_file is
    Port (
        clk           : in STD_LOGIC;
        rst           : in STD_LOGIC;
        write_enable  : in STD_LOGIC;
        write_address : in STD_LOGIC_VECTOR(4 downto 0);
        write_data    : in STD_LOGIC_VECTOR(31 downto 0);
        read_address1 : in STD_LOGIC_VECTOR(4 downto 0);
        read_address2 : in STD_LOGIC_VECTOR(4 downto 0);
        read_data1    : out STD_LOGIC_VECTOR(31 downto 0);
        read_data2    : out STD_LOGIC_VECTOR(31 downto 0)
    );
end fp_register_file;

architecture Behavioral of fp_register_file is
    type register_array_t is array (0 to 31) of STD_LOGIC_VECTOR(31 downto 0);
    signal registers : register_array_t := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                registers <= (others => (others => '0'));
            elsif write_enable = '1' then
                registers(to_integer(unsigned(write_address))) <= write_data;
            end if;
        end if;
    end process;

    read_data1 <= registers(to_integer(unsigned(read_address1)));
    read_data2 <= registers(to_integer(unsigned(read_address2)));
end Behavioral;
