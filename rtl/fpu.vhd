library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.float_pkg.ALL;
use IEEE.fixed_float_types.ALL;
use work.fp_pkg.ALL;

-- Unidade FP binary32. O resultado é registrado e fica pronto uma borda após start.
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
        fflags    : out STD_LOGIC_VECTOR(4 downto 0);
        rounding_mode : in STD_LOGIC_VECTOR(2 downto 0) := "000";
        operand_c : in fp32_t := (others => '0')
    );
end fpu;

architecture Behavioral of fpu is
    signal busy_reg, done_reg : STD_LOGIC := '0';
    signal result_reg : fp32_t := (others => '0');
    signal flags_reg : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');

    -- IEEE.float_pkg implementa RNE, RTZ, RDN e RUP. RMM usa RNE neste modelo
    -- temporário de simulação até a co-simulação SoftFloat cobrir o empate RMM.
    function round_style_for(mode : STD_LOGIC_VECTOR(2 downto 0)) return round_type is
    begin
        case mode is
            when "001" => return round_zero;
            when "010" => return round_neginf;
            when "011" => return round_inf;
            when others => return round_nearest;
        end case;
    end function;

    function to_float32(value : fp32_t) return float32 is
    begin
        return to_float(value, 8, 23);
    end function;

    function to_fp32(value : float32) return fp32_t is
    begin
        return to_slv(value);
    end function;
begin
    process(clk)
        variable next_result : fp32_t;
        variable next_flags : STD_LOGIC_VECTOR(4 downto 0);
        variable less, equal_value : boolean;
        variable float_a, float_b, float_c, float_result : float32;
        variable round_style : round_type;
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

                round_style := round_style_for(rounding_mode);

                float_a := to_float32(operand_a);
                float_b := to_float32(operand_b);
                float_c := to_float32(operand_c);

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
                    when FP_ADD | FP_SUB | FP_MUL | FP_DIV | FP_SQRT =>
                        if (operation = FP_ADD and fp_is_inf(operand_a) and fp_is_inf(operand_b) and
                            operand_a(31) /= operand_b(31)) or
                           (operation = FP_SUB and fp_is_inf(operand_a) and fp_is_inf(operand_b) and
                            operand_a(31) = operand_b(31)) or
                           (operation = FP_MUL and ((fp_is_inf(operand_a) and fp_is_zero(operand_b)) or
                                                     (fp_is_zero(operand_a) and fp_is_inf(operand_b)))) or
                           (operation = FP_DIV and ((fp_is_zero(operand_a) and fp_is_zero(operand_b)) or
                                                     (fp_is_inf(operand_a) and fp_is_inf(operand_b)))) or
                           (operation = FP_SQRT and fp_is_negative(operand_a)) then
                            next_result := FP_CANONICAL_NAN;
                            next_flags := next_flags or FFLAG_NV;
                        elsif operation = FP_DIV and fp_is_zero(operand_b) and not fp_is_zero(operand_a) and not fp_is_nan(operand_a) then
                            next_result := x"7F800000";
                            next_result(31) := operand_a(31) xor operand_b(31);
                            next_flags := next_flags or FFLAG_DZ;
                        else
                            case operation is
                                when FP_ADD  => float_result := add(float_a, float_b, round_style);
                                when FP_SUB  => float_result := subtract(float_a, float_b, round_style);
                                when FP_MUL  => float_result := multiply(float_a, float_b, round_style);
                                when FP_DIV  => float_result := divide(float_a, float_b, round_style);
                                when others  => float_result := sqrt(float_a, round_style);
                            end case;
                            next_result := to_fp32(float_result);

                            if fp_is_nan(next_result) then next_result := FP_CANONICAL_NAN; end if;
                            if fp_is_inf(next_result) and not fp_is_inf(operand_a) and
                               (operation = FP_SQRT or not fp_is_inf(operand_b)) then
                                next_flags := next_flags or FFLAG_OF or FFLAG_NX;
                            elsif next_result(30 downto 23) = x"00" and next_result(22 downto 0) /= (22 downto 0 => '0') then
                                next_flags := next_flags or FFLAG_UF;
                            end if;
                        end if;
                    when FP_MADD | FP_MSUB | FP_NMSUB | FP_NMADD =>
                        if (fp_is_inf(operand_a) and fp_is_zero(operand_b)) or
                           (fp_is_zero(operand_a) and fp_is_inf(operand_b)) then
                            next_result := FP_CANONICAL_NAN;
                            next_flags := next_flags or FFLAG_NV;
                        else
                            case operation is
                                when FP_MADD  => float_result := mac(float_a, float_b, float_c, round_style);
                                when FP_MSUB  => float_result := mac(float_a, float_b, -float_c, round_style);
                                when FP_NMSUB => float_result := mac(-float_a, float_b, float_c, round_style);
                                when others   => float_result := mac(-float_a, float_b, -float_c, round_style);
                            end case;

                            next_result := to_fp32(float_result);

                            if fp_is_nan(next_result) then next_result := FP_CANONICAL_NAN; end if;
                        end if;
                    when FP_CVT_S_W =>
                        float_result := to_float(signed(operand_a), 8, 23, round_style);
                        next_result := to_fp32(float_result);
                    when FP_CVT_S_WU =>
                        float_result := to_float(unsigned(operand_a), 8, 23, round_style);
                        next_result := to_fp32(float_result);
                    when FP_CVT_W_S =>
                        if fp_is_nan(operand_a) or fp_is_inf(operand_a) then
                            next_result := x"7FFFFFFF";
                            next_flags := next_flags or FFLAG_NV;
                        else
                            next_result := std_logic_vector(to_signed(to_integer(float_a, round_style), 32));
                        end if;
                    when FP_CVT_WU_S =>
                        if fp_is_nan(operand_a) or fp_is_inf(operand_a) or fp_is_negative(operand_a) then
                            next_result := (others => '1');
                            if fp_is_negative(operand_a) then next_result := (others => '0'); end if;
                            next_flags := next_flags or FFLAG_NV;
                        else
                            next_result := std_logic_vector(to_unsigned(to_integer(float_a, round_style), 32));
                        end if;
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
