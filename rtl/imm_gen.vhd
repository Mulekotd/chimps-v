library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chimps_pkg.ALL;

entity immediate_generator is
    Port (
        instruction : in  STD_LOGIC_VECTOR(31 downto 0);
        immediate_type : in immediate_type_t;
        immediate : out STD_LOGIC_VECTOR(31 downto 0)
    );
end immediate_generator;

architecture Behavioral of immediate_generator is
begin
    -- Reagrupa os campos dispersos do imediato e faz sign-extension até XLEN.
    process(instruction, immediate_type)
        variable encoded : STD_LOGIC_VECTOR(31 downto 0);
    begin
        encoded := (others => '0');

        case immediate_type is
            when IMM_I =>
                encoded := std_logic_vector(resize(signed(instruction(31 downto 20)), 32));
            when IMM_S =>
                encoded := std_logic_vector(resize(signed(instruction(31 downto 25) & instruction(11 downto 7)), 32));
            when IMM_B =>
                encoded := std_logic_vector(resize(signed(instruction(31) & instruction(7) &
                    instruction(30 downto 25) & instruction(11 downto 8) & '0'), 32));
            when IMM_U =>
                encoded := instruction(31 downto 12) & x"000";
            when IMM_J =>
                encoded := std_logic_vector(resize(signed(instruction(31) & instruction(19 downto 12) &
                    instruction(20) & instruction(30 downto 21) & '0'), 32));
            when IMM_NONE =>
                encoded := (others => '0');
        end case;

        immediate <= encoded;
    end process;
end Behavioral;
