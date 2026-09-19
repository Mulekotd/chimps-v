library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Primitivas IEEE binary32 usadas pelo subconjunto FP já integrado ao RTL.
package fp_pkg is
    subtype fp32_t is STD_LOGIC_VECTOR(31 downto 0);
    type fp_operation_t is (FP_SGNJ, FP_SGNJN, FP_SGNJX, FP_MIN, FP_MAX,
                            FP_EQ, FP_LT, FP_LE, FP_CLASS);

    constant FFLAG_NV : STD_LOGIC_VECTOR(4 downto 0) := "10000";
    constant FP_CANONICAL_NAN : fp32_t := x"7FC00000";

    function fp_is_nan(value : fp32_t) return boolean;
    function fp_is_snan(value : fp32_t) return boolean;
    function fp_is_zero(value : fp32_t) return boolean;
    function fp_less(left_value, right_value : fp32_t) return boolean;
    function fp_class(value : fp32_t) return fp32_t;
end package fp_pkg;

package body fp_pkg is
    function fp_is_nan(value : fp32_t) return boolean is
    begin
        return value(30 downto 23) = x"FF" and value(22 downto 0) /= (22 downto 0 => '0');
    end function;

    function fp_is_snan(value : fp32_t) return boolean is
    begin
        return fp_is_nan(value) and value(22) = '0';
    end function;

    function fp_is_zero(value : fp32_t) return boolean is
    begin
        return value(30 downto 0) = (30 downto 0 => '0');
    end function;

    function fp_less(left_value, right_value : fp32_t) return boolean is
        variable left_magnitude : unsigned(30 downto 0);
        variable right_magnitude : unsigned(30 downto 0);
    begin
        if fp_is_nan(left_value) or fp_is_nan(right_value) or
           (fp_is_zero(left_value) and fp_is_zero(right_value)) then
            return false;
        end if;

        if left_value(31) /= right_value(31) then
            return left_value(31) = '1';
        end if;

        left_magnitude := unsigned(left_value(30 downto 0));
        right_magnitude := unsigned(right_value(30 downto 0));

        if left_value(31) = '1' then
            return left_magnitude > right_magnitude;
        end if;

        return left_magnitude < right_magnitude;
    end function;

    function fp_class(value : fp32_t) return fp32_t is
        variable result : fp32_t := (others => '0');
        variable exponent : STD_LOGIC_VECTOR(7 downto 0);
        variable fraction : STD_LOGIC_VECTOR(22 downto 0);
    begin
        exponent := value(30 downto 23);
        fraction := value(22 downto 0);

        if exponent = x"FF" then
            if fraction = (22 downto 0 => '0') then
                if value(31) = '1' then result(0) := '1'; else result(7) := '1'; end if;
            elsif value(22) = '0' then
                result(8) := '1';
            else
                result(9) := '1';
            end if;
        elsif exponent = x"00" then
            if fraction = (22 downto 0 => '0') then
                if value(31) = '1' then result(3) := '1'; else result(4) := '1'; end if;
            elsif value(31) = '1' then
                result(2) := '1';
            else
                result(5) := '1';
            end if;
        elsif value(31) = '1' then
            result(1) := '1';
        else
            result(6) := '1';
        end if;

        return result;
    end function;
end package body fp_pkg;
