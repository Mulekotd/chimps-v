library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chimps_pkg.ALL;

-- Unidade M com handshake explícito; o resultado fica disponível uma borda após start.
entity mul_div_unit is
    Port (
        clk       : in STD_LOGIC;
        rst       : in STD_LOGIC;
        start     : in STD_LOGIC;
        operation : in mul_div_operation_t;
        operand_a : in STD_LOGIC_VECTOR(31 downto 0);
        operand_b : in STD_LOGIC_VECTOR(31 downto 0);
        busy      : out STD_LOGIC;
        done      : out STD_LOGIC;
        result    : out STD_LOGIC_VECTOR(31 downto 0)
    );
end mul_div_unit;

architecture Behavioral of mul_div_unit is
    signal busy_reg, done_reg : STD_LOGIC := '0';
    signal result_reg : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
begin
    process(clk)
        variable product_ss : signed(63 downto 0);
        variable product_uu : unsigned(63 downto 0);
        variable product_su : signed(64 downto 0);
        variable computed : STD_LOGIC_VECTOR(31 downto 0);
    begin
        if rising_edge(clk) then
            done_reg <= '0';
            if rst = '1' then
                busy_reg <= '0';
                result_reg <= (others => '0');
            elsif busy_reg = '1' then
                busy_reg <= '0';
                done_reg <= '1';
            elsif start = '1' then
                computed := (others => '0');
                product_ss := signed(operand_a) * signed(operand_b);
                product_uu := unsigned(operand_a) * unsigned(operand_b);
                product_su := signed(operand_a) * signed('0' & operand_b);
                case operation is
                    when MUL_OP   => computed := std_logic_vector(product_uu(31 downto 0));
                    when MULH_OP  => computed := std_logic_vector(product_ss(63 downto 32));
                    when MULHSU_OP => computed := std_logic_vector(product_su(63 downto 32));
                    when MULHU_OP => computed := std_logic_vector(product_uu(63 downto 32));
                    when DIV_OP =>
                        if operand_b = x"00000000" then
                            computed := x"FFFFFFFF";
                        elsif operand_a = x"80000000" and operand_b = x"FFFFFFFF" then
                            computed := x"80000000";
                        else
                            computed := std_logic_vector(signed(operand_a) / signed(operand_b));
                        end if;
                    when DIVU_OP =>
                        if operand_b = x"00000000" then
                            computed := x"FFFFFFFF";
                        else
                            computed := std_logic_vector(unsigned(operand_a) / unsigned(operand_b));
                        end if;
                    when REM_OP =>
                        if operand_b = x"00000000" then
                            computed := operand_a;
                        elsif operand_a = x"80000000" and operand_b = x"FFFFFFFF" then
                            computed := (others => '0');
                        else
                            computed := std_logic_vector(signed(operand_a) rem signed(operand_b));
                        end if;
                    when REMU_OP =>
                        if operand_b = x"00000000" then
                            computed := operand_a;
                        else
                            computed := std_logic_vector(unsigned(operand_a) rem unsigned(operand_b));
                        end if;
                end case;
                result_reg <= computed;
                busy_reg <= '1';
            end if;
        end if;
    end process;
    busy <= busy_reg;
    done <= done_reg;
    result <= result_reg;
end Behavioral;
