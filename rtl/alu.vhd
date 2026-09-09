library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chimps_pkg.ALL;

entity alu is
    Port (
        a          : in  STD_LOGIC_VECTOR(31 downto 0);
        b          : in  STD_LOGIC_VECTOR(31 downto 0);
        operation  : in  alu_operation_t;
        result     : out STD_LOGIC_VECTOR(31 downto 0);
        zero       : out STD_LOGIC;
        less_than  : out STD_LOGIC
    );
end alu;

architecture Behavioral of alu is
    -- Não é registrado: este sinal representa a lógica puramente combinacional da ALU.
    signal alu_result : STD_LOGIC_VECTOR(31 downto 0);
begin
    -- Seleciona a operação aritmética ou lógica solicitada pelo decoder.
    process(a, b, operation)
    begin
        alu_result <= (others => '0');
        case operation is
            when ALU_ADD    => alu_result <= std_logic_vector(unsigned(a) + unsigned(b));
            when ALU_SUB    => alu_result <= std_logic_vector(unsigned(a) - unsigned(b));
            when ALU_AND    => alu_result <= a and b;
            when ALU_OR     => alu_result <= a or b;
            when ALU_XOR    => alu_result <= a xor b;
            when ALU_SLT    =>
                if signed(a) < signed(b) then alu_result(0) <= '1'; end if;
            when ALU_SLTU   =>
                if unsigned(a) < unsigned(b) then alu_result(0) <= '1'; end if;
            when ALU_COPY_B => alu_result <= b;
            when ALU_NONE   => alu_result <= (others => '0');
        end case;
    end process;

    -- Disponibiliza o resultado e as flags para o datapath de execute/branch.
    result <= alu_result;
    zero <= is_zero(alu_result);
    less_than <= alu_result(0) when operation = ALU_SLT or operation = ALU_SLTU else '0';
end Behavioral;
