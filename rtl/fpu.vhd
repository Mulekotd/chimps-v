library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.fp_pkg.ALL;

-- Unidade FP de uma borda para operações binary32 sem arredondamento.
entity fpu is
    Port (
        clk       : in STD_LOGIC;
        rst       : in STD_LOGIC;
        start     : in STD_LOGIC;
        operation : in fp_operation_t;
        operand_a : in fp32_t;
        operand_b : in fp32_t;
        busy      : out STD_LOGIC;
        done      : out STD_LOGIC;
        result    : out fp32_t;
        fflags    : out STD_LOGIC_VECTOR(4 downto 0)
    );
end fpu;

architecture Behavioral of fpu is
    signal busy_reg, done_reg : STD_LOGIC := '0';
    signal result_reg : fp32_t := (others => '0');
    signal flags_reg : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
begin
    process(clk)
        variable next_result : fp32_t;
        variable next_flags : STD_LOGIC_VECTOR(4 downto 0);
        variable less, equal_value : boolean;
    begin
        if rising_edge(clk) then
            done_reg <= '0';
            if rst = '1' then
                busy_reg <= '0'; result_reg <= (others => '0'); flags_reg <= (others => '0');
            elsif busy_reg = '1' then
                busy_reg <= '0'; done_reg <= '1';
            elsif start = '1' then
                next_result := (others => '0');
                next_flags := (others => '0');

                less := fp_less(operand_a, operand_b);
                equal_value := not fp_is_nan(operand_a) and not fp_is_nan(operand_b) and
                               ((operand_a = operand_b) or (fp_is_zero(operand_a) and fp_is_zero(operand_b)));

               case operation is
                    when FP_SGNJ  => next_result := operand_b(31) & operand_a(30 downto 0);
                    when FP_SGNJN => next_result := (not operand_b(31)) & operand_a(30 downto 0);
                    when FP_SGNJX => next_result := (operand_a(31) xor operand_b(31)) & operand_a(30 downto 0);
                    when FP_MIN | FP_MAX =>
                        if fp_is_nan(operand_a) and fp_is_nan(operand_b) then
                            next_result := FP_CANONICAL_NAN;
                        elsif fp_is_nan(operand_a) then
                            next_result := operand_b;
                        elsif fp_is_nan(operand_b) then
                            next_result := operand_a;
                        elsif fp_is_zero(operand_a) and fp_is_zero(operand_b) then
                            if operation = FP_MIN then next_result := x"80000000"; else next_result := x"00000000"; end if;
                        elsif (operation = FP_MIN and less) or (operation = FP_MAX and not less) then
                            next_result := operand_a;
                        else
                            next_result := operand_b;
                        end if;
                        if fp_is_snan(operand_a) or fp_is_snan(operand_b) then next_flags := FFLAG_NV; end if;
                    when FP_EQ | FP_LT | FP_LE =>
                        if fp_is_nan(operand_a) or fp_is_nan(operand_b) then
                            if operation /= FP_EQ or fp_is_snan(operand_a) or fp_is_snan(operand_b) then next_flags := FFLAG_NV; end if;
                        elsif (operation = FP_EQ and equal_value) or
                              (operation = FP_LT and less) or
                              (operation = FP_LE and (less or equal_value)) then
                            next_result(0) := '1';
                        end if;
                    when FP_CLASS => next_result := fp_class(operand_a);
                end case;

                result_reg <= next_result;
                flags_reg <= next_flags;
                busy_reg <= '1';
            end if;
        end if;
    end process;

    busy <= busy_reg;
    done <= done_reg;
    result <= result_reg;
    fflags <= flags_reg;
end Behavioral;
