library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.chimps_pkg.ALL;

entity decoder is
    Port (
        instruction  : in  STD_LOGIC_VECTOR(31 downto 0);
        valid        : out STD_LOGIC;
        reg_write    : out STD_LOGIC;
        alu_src      : out STD_LOGIC;
        alu_operation: out alu_operation_t;
        mem_read     : out STD_LOGIC;
        mem_write    : out STD_LOGIC;
        mem_to_reg   : out STD_LOGIC;
        branch       : out STD_LOGIC;
        branch_ne    : out STD_LOGIC;
        jump         : out STD_LOGIC;
        jalr         : out STD_LOGIC;
        immediate_type : out immediate_type_t
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

        case opcode is
            when OPCODE_OP =>
                reg_write <= '1';
                case funct3 is
                    when "000" => if funct7 = "0100000" then alu_operation <= ALU_SUB; else alu_operation <= ALU_ADD; end if;
                    when "111" => alu_operation <= ALU_AND;
                    when "110" => alu_operation <= ALU_OR;
                    when "100" => alu_operation <= ALU_XOR;
                    when "010" => alu_operation <= ALU_SLT;
                    when "011" => alu_operation <= ALU_SLTU;
                    when others => valid <= '0';
                end case;
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
                    when others => valid <= '0';
                end case;
            when OPCODE_LOAD =>
                if funct3 = "010" then
                    reg_write <= '1'; alu_src <= '1'; alu_operation <= ALU_ADD;
                    mem_read <= '1'; mem_to_reg <= '1'; immediate_type <= IMM_I;
                else
                    valid <= '0';
                end if;
            when OPCODE_STORE =>
                if funct3 = "010" then
                    alu_src <= '1'; alu_operation <= ALU_ADD;
                    mem_write <= '1'; immediate_type <= IMM_S;
                else
                    valid <= '0';
                end if;
            when OPCODE_BRANCH =>
                if funct3 = "000" or funct3 = "001" then
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
            when others =>
                valid <= '0';
        end case;
    end process;
end Behavioral;
