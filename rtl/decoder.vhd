library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.chimps_pkg.ALL;
use work.fp_pkg.ALL;

entity decoder is
    Port (
        instruction    : in  STD_LOGIC_VECTOR(31 downto 0);
        valid          : out STD_LOGIC;
        reg_write      : out STD_LOGIC;
        alu_src        : out STD_LOGIC;
        alu_operation  : out alu_operation_t;
        mem_read       : out STD_LOGIC;
        mem_write      : out STD_LOGIC;
        mem_to_reg     : out STD_LOGIC;
        branch         : out STD_LOGIC;
        branch_ne      : out STD_LOGIC;
        jump           : out STD_LOGIC;
        jalr           : out STD_LOGIC;
        immediate_type : out immediate_type_t;
        m_enable       : out STD_LOGIC := '0';
        m_operation    : out mul_div_operation_t := MUL_OP;
        fp_enable      : out STD_LOGIC := '0';
        fp_operation   : out fp_operation_t := FP_SGNJ;
        fp_write       : out STD_LOGIC := '0';
        fp_result_to_gpr : out STD_LOGIC := '0';
        fp_move_from_int : out STD_LOGIC := '0';
        fp_move_to_int : out STD_LOGIC := '0'
    );
end decoder;

architecture Behavioral of decoder is
begin
    -- Decodifica opcode e campos de função em sinais de controle do datapath.
    process(instruction)
        variable opcode : STD_LOGIC_VECTOR(6 downto 0);
        variable funct3 : STD_LOGIC_VECTOR(2 downto 0);
        variable funct7 : STD_LOGIC_VECTOR(6 downto 0);
    begin
        opcode := instruction(6 downto 0);
        funct3 := instruction(14 downto 12);
        funct7 := instruction(31 downto 25);

        -- Valores padrão seguros descrevem uma operação sem escrita antes da especialização.
        valid <= '1';
        reg_write <= '0';
        alu_src <= '0';
        alu_operation <= ALU_NONE;
        mem_read <= '0';
        mem_write <= '0';
        mem_to_reg <= '0';
        branch <= '0';
        branch_ne <= '0';
        jump <= '0';
        jalr <= '0';
        immediate_type <= IMM_NONE;
        m_enable <= '0'; m_operation <= MUL_OP;
        fp_enable <= '0'; fp_operation <= FP_SGNJ; fp_write <= '0';
        fp_result_to_gpr <= '0'; fp_move_from_int <= '0'; fp_move_to_int <= '0';

        case opcode is
            when OPCODE_OP =>
                reg_write <= '1';
                if funct7 = "0000001" then
                    m_enable <= '1';
                    case funct3 is
                        when "000" => m_operation <= MUL_OP;
                        when "001" => m_operation <= MULH_OP;
                        when "010" => m_operation <= MULHSU_OP;
                        when "011" => m_operation <= MULHU_OP;
                        when "100" => m_operation <= DIV_OP;
                        when "101" => m_operation <= DIVU_OP;
                        when "110" => m_operation <= REM_OP;
                        when others => m_operation <= REMU_OP;
                    end case;
                else
                case funct3 is
                    when "000" => if funct7 = "0100000" then alu_operation <= ALU_SUB; else alu_operation <= ALU_ADD; end if;
                    when "111" => alu_operation <= ALU_AND;
                    when "110" => alu_operation <= ALU_OR;
                    when "100" => alu_operation <= ALU_XOR;
                    when "010" => alu_operation <= ALU_SLT;
                    when "011" => alu_operation <= ALU_SLTU;
                    when "001" => alu_operation <= ALU_SLL;
                    when "101" =>
                        if funct7 = "0100000" then alu_operation <= ALU_SRA;
                        else alu_operation <= ALU_SRL; end if;
                    when others => valid <= '0';
                end case;
                if funct7 /= "0000000" and not (funct7 = "0100000" and
                    (funct3 = "000" or funct3 = "101")) then valid <= '0'; end if;
                end if;
            when OPCODE_OP_IMM =>
                reg_write <= '1';
                alu_src <= '1';
                immediate_type <= IMM_I;

                case funct3 is
                    when "000" => alu_operation <= ALU_ADD;
                    when "111" => alu_operation <= ALU_AND;
                    when "110" => alu_operation <= ALU_OR;
                    when "100" => alu_operation <= ALU_XOR;
                    when "010" => alu_operation <= ALU_SLT;
                    when "011" => alu_operation <= ALU_SLTU;
                    when "001" =>
                        alu_operation <= ALU_SLL;
                        if funct7 /= "0000000" then valid <= '0'; end if;
                    when "101" =>
                        if funct7 = "0000000" then alu_operation <= ALU_SRL;
                        elsif funct7 = "0100000" then alu_operation <= ALU_SRA;
                        else valid <= '0'; end if;
                    when others => valid <= '0';
                end case;
            when OPCODE_LOAD =>
                if funct3 = "000" or funct3 = "001" or funct3 = "010" or funct3 = "100" or funct3 = "101" then
                    reg_write <= '1'; alu_src <= '1'; alu_operation <= ALU_ADD;
                    mem_read <= '1'; mem_to_reg <= '1'; immediate_type <= IMM_I;
                else
                    valid <= '0';
                end if;
            when OPCODE_STORE =>
                if funct3 = "000" or funct3 = "001" or funct3 = "010" then
                    alu_src <= '1'; alu_operation <= ALU_ADD;
                    mem_write <= '1'; immediate_type <= IMM_S;
                else
                    valid <= '0';
                end if;
            when OPCODE_BRANCH =>
                if funct3 = "000" or funct3 = "001" or funct3 = "100" or funct3 = "101" or funct3 = "110" or funct3 = "111" then
                    branch <= '1';
                    if funct3 = "001" then branch_ne <= '1'; end if;
                    alu_operation <= ALU_SUB; immediate_type <= IMM_B;
                else
                    valid <= '0';
                end if;
            when OPCODE_JAL =>
                reg_write <= '1'; jump <= '1'; immediate_type <= IMM_J;
            when OPCODE_JALR =>
                if funct3 = "000" then
                    reg_write <= '1'; jump <= '1'; jalr <= '1'; alu_src <= '1';
                    alu_operation <= ALU_ADD; immediate_type <= IMM_I;
                else
                    valid <= '0';
                end if;
            when OPCODE_LUI =>
                reg_write <= '1'; alu_src <= '1'; alu_operation <= ALU_COPY_B; immediate_type <= IMM_U;
            when OPCODE_AUIPC =>
                reg_write <= '1'; alu_src <= '1'; alu_operation <= ALU_ADD; immediate_type <= IMM_U;
            when OPCODE_OP_FP =>
                valid <= '0';
                case funct7 is
                    when "0010000" =>
                        case funct3 is
                            when "000" => fp_operation <= FP_SGNJ;
                            when "001" => fp_operation <= FP_SGNJN;
                            when "010" => fp_operation <= FP_SGNJX;
                            when others => null;
                        end case;
                        if funct3 = "000" or funct3 = "001" or funct3 = "010" then
                            valid <= '1'; fp_enable <= '1'; fp_write <= '1';
                        end if;
                    when "0010100" =>
                        if funct3 = "000" then fp_operation <= FP_MIN;
                        elsif funct3 = "001" then fp_operation <= FP_MAX;
                        end if;
                        if funct3 = "000" or funct3 = "001" then
                            valid <= '1'; fp_enable <= '1'; fp_write <= '1';
                        end if;
                    when "1010000" =>
                        case funct3 is
                            when "000" => fp_operation <= FP_LE;
                            when "001" => fp_operation <= FP_LT;
                            when "010" => fp_operation <= FP_EQ;
                            when others => null;
                        end case;
                        if funct3 = "000" or funct3 = "001" or funct3 = "010" then
                            valid <= '1'; fp_enable <= '1'; fp_result_to_gpr <= '1'; reg_write <= '1';
                        end if;
                    when "1110000" =>
                        if instruction(24 downto 20) = "00000" then
                            if funct3 = "001" then
                                valid <= '1'; fp_enable <= '1'; fp_operation <= FP_CLASS;
                                fp_result_to_gpr <= '1'; reg_write <= '1';
                            elsif funct3 = "000" then
                                valid <= '1'; fp_move_to_int <= '1'; reg_write <= '1';
                            end if;
                        end if;
                    when "1111000" =>
                        if instruction(24 downto 20) = "00000" and funct3 = "000" then
                            valid <= '1'; fp_move_from_int <= '1'; fp_write <= '1';
                        end if;
                    when others => null;
                end case;
            when "0001111" =>
                if funct3 /= "000" then valid <= '0'; end if;
            when OPCODE_SYSTEM =>
                if funct3 = "000" then
                    if instruction /= x"00000073" and instruction /= x"00100073" and instruction /= x"30200073" then valid <= '0'; end if;
                elsif funct3 = "100" then valid <= '0';
                else reg_write <= '1'; end if;
            when others =>
                valid <= '0';
        end case;
    end process;
end Behavioral;
