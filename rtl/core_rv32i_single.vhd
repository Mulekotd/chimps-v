library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chimps_pkg.ALL;
use work.fp_pkg.ALL;

-- Referência sequencial com uma instrução em voo. As saídas valid permanecem
-- estáveis até ready; isso permite conectar diretamente caches e barramento.
entity core_rv32i_single is
    Port (
        clk, rst : in STD_LOGIC;
        instruction_valid : out STD_LOGIC;
        instruction_address : out STD_LOGIC_VECTOR(31 downto 0);
        instruction_ready, instruction_error : in STD_LOGIC;
        instruction_rdata : in STD_LOGIC_VECTOR(31 downto 0);
        data_valid, data_write : out STD_LOGIC;
        data_address, data_wdata : out STD_LOGIC_VECTOR(31 downto 0);
        data_wmask : out STD_LOGIC_VECTOR(3 downto 0);
        data_ready, data_error : in STD_LOGIC;
        data_rdata : in STD_LOGIC_VECTOR(31 downto 0);
        current_pc, current_instruction : out STD_LOGIC_VECTOR(31 downto 0);
        retired, halted, illegal_instruction : out STD_LOGIC;
        fp_fflags : out STD_LOGIC_VECTOR(4 downto 0)
    );
end core_rv32i_single;

architecture Behavioral of core_rv32i_single is
    type state_t is (FETCH, EXECUTE, MEMORY, M_LAUNCH, M_WAIT, FP_LAUNCH, FP_WAIT, FP_RETIRE, RETIRE, FAULT);

    signal state : state_t := FETCH;
    signal pc : STD_LOGIC_VECTOR(31 downto 0);
    signal instruction : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal immediate, register_data1, register_data2, alu_operand_a, alu_operand_b : STD_LOGIC_VECTOR(31 downto 0);
    signal fp_register_data1, fp_register_data2, fp_result_reg : fp32_t := (others => '0');
    signal alu_result, result_reg, memory_address_reg, memory_wdata_reg : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal alu_zero : STD_LOGIC;
    signal decode_valid, reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch, branch_ne, jump, jalr : STD_LOGIC;
    signal m_enable : STD_LOGIC;
    signal fp_enable, fp_write, fp_result_to_gpr, fp_move_from_int, fp_move_to_int : STD_LOGIC;
    signal alu_operation : alu_operation_t;
    signal immediate_type : immediate_type_t;
    signal m_operation : mul_div_operation_t;
    signal fp_operation : fp_operation_t;
    signal m_start, m_done : STD_LOGIC;
    signal m_result : STD_LOGIC_VECTOR(31 downto 0);
    signal fp_start, fp_done : STD_LOGIC;
    signal fp_result : fp32_t;
    signal fpu_fflags, fp_flags_reg : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    signal branch_condition, next_pc_is_target : STD_LOGIC;
    signal branch_target : STD_LOGIC_VECTOR(31 downto 0);
    signal pc_write, writeback_enable, fp_writeback_enable : STD_LOGIC;
    signal retired_reg, halted_reg, illegal_reg : STD_LOGIC := '0';
begin
    pc_i : entity work.program_counter
        port map (clk => clk, rst => rst, pc_write => pc_write, pc_src => next_pc_is_target,
                  branch_pc => branch_target, current_pc => pc);

    decoder_i : entity work.decoder
        port map (instruction => instruction, valid => decode_valid, reg_write => reg_write,
                  alu_src => alu_src, alu_operation => alu_operation, mem_read => mem_read,
                  mem_write => mem_write, mem_to_reg => mem_to_reg, branch => branch,
                  branch_ne => branch_ne, jump => jump, jalr => jalr,
                  immediate_type => immediate_type, m_enable => m_enable, m_operation => m_operation,
                  fp_enable => fp_enable, fp_operation => fp_operation, fp_write => fp_write,
                  fp_result_to_gpr => fp_result_to_gpr, fp_move_from_int => fp_move_from_int,
                  fp_move_to_int => fp_move_to_int);

    immediate_i : entity work.immediate_generator
        port map (instruction => instruction, immediate_type => immediate_type, immediate => immediate);

    register_file_i : entity work.register_file
        port map (clk => clk, rst => rst, write_enable => writeback_enable,
                  write_address => instruction(11 downto 7), write_data => result_reg,
                  read_address1 => instruction(19 downto 15), read_address2 => instruction(24 downto 20),
                  read_data1 => register_data1, read_data2 => register_data2);

    fp_register_file_i : entity work.fp_register_file
        port map (clk => clk, rst => rst, write_enable => fp_writeback_enable,
                  write_address => instruction(11 downto 7), write_data => fp_result_reg,
                  read_address1 => instruction(19 downto 15), read_address2 => instruction(24 downto 20),
                  read_data1 => fp_register_data1, read_data2 => fp_register_data2);

    alu_i : entity work.alu
        port map (a => alu_operand_a, b => alu_operand_b, operation => alu_operation,
                  result => alu_result, zero => alu_zero, less_than => open);

    mul_div_i : entity work.mul_div_unit
        port map (clk => clk, rst => rst, start => m_start, operation => m_operation,
                  operand_a => register_data1, operand_b => register_data2,
                  busy => open, done => m_done, result => m_result);

    fpu_i : entity work.fpu
        port map (clk => clk, rst => rst, start => fp_start, operation => fp_operation,
                  operand_a => fp_register_data1, operand_b => fp_register_data2,
                  busy => open, done => fp_done, result => fp_result, fflags => fpu_fflags);

    alu_operand_a <= pc when instruction(6 downto 0) = OPCODE_AUIPC else register_data1;
    alu_operand_b <= immediate when alu_src = '1' else register_data2;
    branch_condition <= (alu_zero and not branch_ne) or ((not alu_zero) and branch_ne);
    next_pc_is_target <= jump or (branch and branch_condition and decode_valid);
    branch_target <= (std_logic_vector(unsigned(register_data1) + unsigned(immediate)) and x"FFFFFFFE")
                     when jalr = '1' else std_logic_vector(unsigned(pc) + unsigned(immediate));

    instruction_valid <= '1' when state = FETCH else '0';
    instruction_address <= pc;
    data_valid <= '1' when state = MEMORY else '0';
    data_write <= mem_write;
    data_address <= memory_address_reg;
    data_wdata <= memory_wdata_reg;
    data_wmask <= "1111";
    m_start <= '1' when state = M_LAUNCH else '0';
    fp_start <= '1' when state = FP_LAUNCH else '0';
    pc_write <= '1' when state = RETIRE or state = FP_RETIRE else '0';
    writeback_enable <= '1' when state = RETIRE and reg_write = '1' else '0';
    fp_writeback_enable <= '1' when state = FP_RETIRE and fp_write = '1' else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            retired_reg <= '0';
            if rst = '1' then
                state <= FETCH;
                instruction <= (others => '0');
                result_reg <= (others => '0');
                memory_address_reg <= (others => '0');
                memory_wdata_reg <= (others => '0');
                fp_result_reg <= (others => '0');
                fp_flags_reg <= (others => '0');
                halted_reg <= '0';
                illegal_reg <= '0';
            else
                case state is
                    when FETCH =>
                        if instruction_ready = '1' then
                            instruction <= instruction_rdata;

                            if instruction_error = '1' then
                                halted_reg <= '1';
                                state <= FAULT;
                            else
                                state <= EXECUTE;
                            end if;
                        end if;
                    when EXECUTE =>
                        if decode_valid = '0' or instruction(6 downto 0) = OPCODE_SYSTEM then
                            halted_reg <= '1';
                            illegal_reg <= '1';
                            state <= FAULT;
                        elsif m_enable = '1' then
                            state <= M_LAUNCH;
                        elsif fp_enable = '1' then
                            state <= FP_LAUNCH;
                        elsif fp_move_from_int = '1' then
                            fp_result_reg <= register_data1;
                            state <= FP_RETIRE;
                        elsif fp_move_to_int = '1' then
                            result_reg <= fp_register_data1;
                            state <= RETIRE;
                        elsif mem_read = '1' or mem_write = '1' then
                            memory_address_reg <= alu_result;
                            memory_wdata_reg <= register_data2;
                            state <= MEMORY;
                        else
                            if jump = '1' then result_reg <= std_logic_vector(unsigned(pc) + 4);
                            else result_reg <= alu_result; end if;
                            state <= RETIRE;
                        end if;
                    when MEMORY =>
                        if data_ready = '1' then
                            if data_error = '1' then
                                halted_reg <= '1';
                                state <= FAULT;
                            else
                                if mem_read = '1' then result_reg <= data_rdata; end if;
                                state <= RETIRE;
                            end if;
                        end if;
                    when M_LAUNCH => state <= M_WAIT;
                    when M_WAIT =>
                        if m_done = '1' then
                            result_reg <= m_result;
                            state <= RETIRE;
                        end if;
                    when FP_LAUNCH => state <= FP_WAIT;
                    when FP_WAIT =>
                        if fp_done = '1' then
                            fp_flags_reg <= fp_flags_reg or fpu_fflags;
                            if fp_result_to_gpr = '1' then
                                result_reg <= fp_result;
                                state <= RETIRE;
                            else
                                fp_result_reg <= fp_result;
                                state <= FP_RETIRE;
                            end if;
                        end if;
                    when FP_RETIRE =>
                        retired_reg <= '1';
                        state <= FETCH;
                    when RETIRE =>
                        retired_reg <= '1';
                        state <= FETCH;
                    when FAULT => null;
                end case;
            end if;
        end if;
    end process;

    current_pc <= pc;
    current_instruction <= instruction;
    retired <= retired_reg;
    halted <= halted_reg;
    illegal_instruction <= illegal_reg;
    fp_fflags <= fp_flags_reg;
end Behavioral;
