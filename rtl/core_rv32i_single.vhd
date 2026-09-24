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
        retired, halted, illegal_instruction, trap : out STD_LOGIC;
        trap_cause : out STD_LOGIC_VECTOR(31 downto 0);
        fp_fflags : out STD_LOGIC_VECTOR(4 downto 0)
    );
end core_rv32i_single;

architecture Behavioral of core_rv32i_single is
    -- Cada estado representa uma etapa observável de uma única instrução.
    type state_t is (
        FETCH,      -- espera a instrução no PC atual
        EXECUTE,    -- decodifica e calcula ALU/endereço/alvo
        MEMORY,     -- mantém o pedido de dados até ready
        M_LAUNCH, M_WAIT,              -- inicia e espera a unidade de multiplicação/divisão
        FP_LAUNCH, FP_WAIT, FP_RETIRE, -- inicia, espera e grava o resultado FP
        RETIRE,     -- grava o resultado inteiro e avança o PC
        FAULT       -- para em erro de barramento ou instrução inválida
    );

    -- Estado arquitetural e registradores de resultados que precisam sobreviver a stalls.
    signal state : state_t := FETCH;
    signal pc : STD_LOGIC_VECTOR(31 downto 0);
    signal instruction : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

    -- Dados combinacionais vindos do decode, dos bancos de registradores e da ALU.
    signal immediate, register_data1, register_data2, alu_operand_a, alu_operand_b : STD_LOGIC_VECTOR(31 downto 0);
    signal fp_register_data1, fp_register_data2, fp_register_data3, fp_result_reg, fpu_operand_a : fp32_t := (others => '0');
    signal alu_result, result_reg, memory_address_reg, memory_effective_address_reg, memory_wdata_reg : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal memory_wmask_reg : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal alu_zero : STD_LOGIC;
    signal decode_valid, reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch, branch_ne, jump, jalr : STD_LOGIC;
    signal m_enable : STD_LOGIC;
    signal fp_enable, fp_write, fp_result_to_gpr, fp_move_from_int, fp_move_to_int : STD_LOGIC;
    signal fp_mem_read, fp_mem_write, fp_operand_from_gpr : STD_LOGIC;
    signal alu_operation : alu_operation_t;
    signal immediate_type : immediate_type_t;
    signal m_operation : mul_div_operation_t;
    signal fp_operation : fp_operation_t;
    signal fp_rounding_mode, effective_fp_rounding_mode : STD_LOGIC_VECTOR(2 downto 0);
    signal m_start, m_done : STD_LOGIC;
    signal m_result : STD_LOGIC_VECTOR(31 downto 0);
    signal fp_start, fp_done : STD_LOGIC;
    signal fp_result : fp32_t;
    signal fpu_fflags, fp_flags_reg : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    signal fp_round_reg : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal branch_condition, next_pc_is_target : STD_LOGIC;
    signal branch_target : STD_LOGIC_VECTOR(31 downto 0);
    signal pc_write, writeback_enable, fp_writeback_enable : STD_LOGIC;
    signal retired_reg, halted_reg, illegal_reg, trap_reg : STD_LOGIC := '0';
    signal trap_cause_reg : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

    function aligned(address : STD_LOGIC_VECTOR(31 downto 0); width : STD_LOGIC_VECTOR(2 downto 0)) return boolean is
    begin
        if width = "001" or width = "101" then return address(0) = '0'; end if;
        if width = "010" then return address(1 downto 0) = "00"; end if;
        return true;
    end function;

    function load_value(data : STD_LOGIC_VECTOR(31 downto 0); address : STD_LOGIC_VECTOR(31 downto 0);
                        width : STD_LOGIC_VECTOR(2 downto 0)) return STD_LOGIC_VECTOR is
        variable byte_value : STD_LOGIC_VECTOR(7 downto 0);
        variable half_value : STD_LOGIC_VECTOR(15 downto 0);
    begin
        case address(1 downto 0) is
            when "00" => byte_value := data(7 downto 0);
            when "01" => byte_value := data(15 downto 8);
            when "10" => byte_value := data(23 downto 16);
            when others => byte_value := data(31 downto 24);
        end case;
        if address(1) = '0' then half_value := data(15 downto 0); else half_value := data(31 downto 16); end if;
        case width is
            when "000" => return std_logic_vector(resize(signed(byte_value), 32));
            when "001" => return std_logic_vector(resize(signed(half_value), 32));
            when "100" => return std_logic_vector(resize(unsigned(byte_value), 32));
            when "101" => return std_logic_vector(resize(unsigned(half_value), 32));
            when others => return data;
        end case;
    end function;

    function valid_fcsr_address(address : STD_LOGIC_VECTOR(11 downto 0)) return boolean is
    begin
        return address = x"001" or address = x"002" or address = x"003";
    end function;

    function read_fcsr(address : STD_LOGIC_VECTOR(11 downto 0);
                       flags : STD_LOGIC_VECTOR(4 downto 0);
                       rounding : STD_LOGIC_VECTOR(2 downto 0)) return STD_LOGIC_VECTOR is
        variable result : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    begin
        case address is
            when x"001" => result(4 downto 0) := flags;
            when x"002" => result(2 downto 0) := rounding;
            when others => result(7 downto 5) := rounding; result(4 downto 0) := flags;
        end case;
        return result;
    end function;
begin
    -- Blocos combinacionais e bancos de estado que formam o datapath.
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
                    fp_move_to_int => fp_move_to_int, fp_mem_read => fp_mem_read,
                    fp_mem_write => fp_mem_write, fp_operand_from_gpr => fp_operand_from_gpr,
                    fp_rounding_mode => fp_rounding_mode);

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
                    read_data1 => fp_register_data1, read_data2 => fp_register_data2,
                    read_address3 => instruction(31 downto 27), read_data3 => fp_register_data3);

    alu_i : entity work.alu
        port map (a => alu_operand_a, b => alu_operand_b, operation => alu_operation,
                  result => alu_result, zero => alu_zero, less_than => open);

    mul_div_i : entity work.mul_div_unit
        port map (clk => clk, rst => rst, start => m_start, operation => m_operation,
                    operand_a => register_data1, operand_b => register_data2,
                    busy => open, done => m_done, result => m_result);

    fpu_i : entity work.fpu
        port map (clk => clk, rst => rst, start => fp_start, operation => fp_operation,
                    operand_a => fpu_operand_a, operand_b => fp_register_data2, busy => open, done => fp_done,
                    result => fp_result, fflags => fpu_fflags,
                    rounding_mode => effective_fp_rounding_mode, operand_c => fp_register_data3);

    -- AUIPC usa o PC como primeiro operando; as demais instruções usam rs1.
    alu_operand_a <= pc when instruction(6 downto 0) = OPCODE_AUIPC else register_data1;
    alu_operand_b <= immediate when alu_src = '1' else register_data2;
    fpu_operand_a <= register_data1 when fp_operand_from_gpr = '1' else fp_register_data1;
    branch_condition <= '1' when instruction(14 downto 12) = "000" and register_data1 = register_data2 else
                        '1' when instruction(14 downto 12) = "001" and register_data1 /= register_data2 else
                        '1' when instruction(14 downto 12) = "100" and signed(register_data1) < signed(register_data2) else
                        '1' when instruction(14 downto 12) = "101" and signed(register_data1) >= signed(register_data2) else
                        '1' when instruction(14 downto 12) = "110" and unsigned(register_data1) < unsigned(register_data2) else
                        '1' when instruction(14 downto 12) = "111" and unsigned(register_data1) >= unsigned(register_data2) else '0';
    next_pc_is_target <= jump or (branch and branch_condition and decode_valid);
    branch_target <= (std_logic_vector(unsigned(register_data1) + unsigned(immediate)) and x"FFFFFFFE")
                     when jalr = '1' else std_logic_vector(unsigned(pc) + unsigned(immediate));
    effective_fp_rounding_mode <= fp_round_reg when fp_rounding_mode = "111" else fp_rounding_mode;

    -- Cada pedido permanece ativo durante todo o estado que o consome.
    instruction_valid <= '1' when state = FETCH else '0';
    instruction_address <= pc;
    data_valid <= '1' when state = MEMORY else '0';
    data_write <= mem_write or fp_mem_write;
    data_address <= memory_address_reg;
    data_wdata <= memory_wdata_reg;
    data_wmask <= memory_wmask_reg;
    m_start <= '1' when state = M_LAUNCH else '0';
    fp_start <= '1' when state = FP_LAUNCH else '0';
    pc_write <= '1' when state = RETIRE or state = FP_RETIRE else '0';
    writeback_enable <= '1' when state = RETIRE and reg_write = '1' else '0';
    fp_writeback_enable <= '1' when state = FP_RETIRE and fp_write = '1' else '0';

    -- Máquina de estados: guarda dados antes de esperar interfaces externas.
    process(clk)
        variable csr_old, csr_operand : STD_LOGIC_VECTOR(31 downto 0);
        variable csr_write : boolean;
    begin
        if rising_edge(clk) then
            retired_reg <= '0';
            trap_reg <= '0';
            if rst = '1' then
                state <= FETCH;
                instruction <= (others => '0');
                result_reg <= (others => '0');
                memory_address_reg <= (others => '0');
                memory_effective_address_reg <= (others => '0');
                memory_wdata_reg <= (others => '0');
                memory_wmask_reg <= (others => '0');
                fp_result_reg <= (others => '0');
                fp_flags_reg <= (others => '0');
                fp_round_reg <= "000";
                halted_reg <= '0';
                illegal_reg <= '0';
                trap_cause_reg <= (others => '0');
            else
                case state is
                    when FETCH =>
                        -- A instrução só é capturada no handshake de busca.
                        if instruction_ready = '1' then
                            instruction <= instruction_rdata;

                            if instruction_error = '1' then
                                halted_reg <= '1';
                                trap_reg <= '1'; trap_cause_reg <= x"00000001";
                                state <= FAULT;
                            else
                                state <= EXECUTE;
                            end if;
                        end if;
                    when EXECUTE =>
                        -- Decide se a instrução segue para memória, unidade M, FP ou retire.
                        if decode_valid = '0' then
                            halted_reg <= '1';
                            illegal_reg <= '1';
                            trap_reg <= '1'; trap_cause_reg <= x"00000002";
                            state <= FAULT;
                        elsif (jump = '1' or (branch = '1' and branch_condition = '1')) and branch_target(1 downto 0) /= "00" then
                            halted_reg <= '1'; trap_reg <= '1'; trap_cause_reg <= x"00000000";
                            state <= FAULT;
                        elsif instruction(6 downto 0) = OPCODE_SYSTEM then
                            -- Implementa somente os CSRs arquiteturais do estado F.
                            if instruction = x"00000073" then
                                halted_reg <= '1'; trap_reg <= '1'; trap_cause_reg <= x"0000000B"; state <= FAULT;
                            elsif instruction = x"00100073" then
                                halted_reg <= '1'; trap_reg <= '1'; trap_cause_reg <= x"00000003"; state <= FAULT;
                            elsif not valid_fcsr_address(instruction(31 downto 20)) or
                               instruction(14 downto 12) = "000" or instruction(14 downto 12) = "100" then
                                halted_reg <= '1';
                                illegal_reg <= '1';
                                trap_reg <= '1'; trap_cause_reg <= x"00000002";
                                state <= FAULT;
                            else
                                csr_old := read_fcsr(instruction(31 downto 20), fp_flags_reg, fp_round_reg);
                                csr_operand := (others => '0');
                                csr_write := true;
                                case instruction(14 downto 12) is
                                    when "001" => csr_operand := register_data1; -- CSRRW
                                    when "010" => -- CSRRS
                                        csr_operand := csr_old or register_data1;
                                        csr_write := instruction(19 downto 15) /= "00000";
                                    when "011" => -- CSRRC
                                        csr_operand := csr_old and not register_data1;
                                        csr_write := instruction(19 downto 15) /= "00000";
                                    when "101" => csr_operand(4 downto 0) := instruction(19 downto 15); -- CSRRWI
                                    when "110" => -- CSRRSI
                                        csr_operand := csr_old;
                                        csr_operand(4 downto 0) := csr_old(4 downto 0) or instruction(19 downto 15);
                                        csr_write := instruction(19 downto 15) /= "00000";
                                    when others => -- CSRRCI
                                        csr_operand := csr_old;
                                        csr_operand(4 downto 0) := csr_old(4 downto 0) and not instruction(19 downto 15);
                                        csr_write := instruction(19 downto 15) /= "00000";
                                end case;
                                if csr_write then
                                    case instruction(31 downto 20) is
                                        when x"001" => fp_flags_reg <= csr_operand(4 downto 0);
                                        when x"002" => fp_round_reg <= csr_operand(2 downto 0);
                                        when others =>
                                            fp_flags_reg <= csr_operand(4 downto 0);
                                            fp_round_reg <= csr_operand(7 downto 5);
                                    end case;
                                end if;
                                result_reg <= csr_old;
                                state <= RETIRE;
                            end if;
                        elsif m_enable = '1' then
                            state <= M_LAUNCH;
                        elsif fp_enable = '1' and (effective_fp_rounding_mode = "101" or
                                                     effective_fp_rounding_mode = "110" or
                                                     effective_fp_rounding_mode = "111") then
                            halted_reg <= '1';
                            illegal_reg <= '1';
                            trap_reg <= '1'; trap_cause_reg <= x"00000002";
                            state <= FAULT;
                        elsif fp_enable = '1' then
                            state <= FP_LAUNCH;
                        elsif fp_move_from_int = '1' then
                            fp_result_reg <= register_data1;
                            state <= FP_RETIRE;
                        elsif fp_move_to_int = '1' then
                            result_reg <= fp_register_data1;
                            state <= RETIRE;
                        elsif mem_read = '1' or mem_write = '1' or fp_mem_read = '1' or fp_mem_write = '1' then
                            if not aligned(alu_result, instruction(14 downto 12)) then
                                halted_reg <= '1'; trap_reg <= '1';
                                if mem_read = '1' or fp_mem_read = '1' then trap_cause_reg <= x"00000004";
                                else trap_cause_reg <= x"00000006"; end if;
                                state <= FAULT;
                            else
                                memory_address_reg <= alu_result and x"FFFFFFFC";
                                memory_effective_address_reg <= alu_result;
                                if fp_mem_write = '1' then memory_wdata_reg <= fp_register_data2; memory_wmask_reg <= "1111";
                                elsif mem_write = '1' then
                                    case instruction(14 downto 12) is
                                        when "000" =>
                                            memory_wmask_reg <= std_logic_vector(shift_left(to_unsigned(1, 4), to_integer(unsigned(alu_result(1 downto 0)))));
                                            memory_wdata_reg <= std_logic_vector(shift_left(unsigned(register_data2), 8 * to_integer(unsigned(alu_result(1 downto 0)))));
                                        when "001" =>
                                            if alu_result(1) = '0' then memory_wmask_reg <= "0011"; memory_wdata_reg <= register_data2;
                                            else memory_wmask_reg <= "1100"; memory_wdata_reg <= std_logic_vector(shift_left(unsigned(register_data2), 16)); end if;
                                        when others => memory_wmask_reg <= "1111"; memory_wdata_reg <= register_data2;
                                    end case;
                                else memory_wdata_reg <= register_data2; memory_wmask_reg <= "1111"; end if;
                                state <= MEMORY;
                            end if;
                        else
                            if jump = '1' then result_reg <= std_logic_vector(unsigned(pc) + 4);
                            else result_reg <= alu_result; end if;
                            state <= RETIRE;
                        end if;
                    when MEMORY =>
                        -- Endereço e dados já estão registrados, portanto o stall é seguro.
                        if data_ready = '1' then
                            if data_error = '1' then
                                halted_reg <= '1';
                                trap_reg <= '1';
                                if mem_read = '1' or fp_mem_read = '1' then trap_cause_reg <= x"00000005";
                                else trap_cause_reg <= x"00000007"; end if;
                                state <= FAULT;
                            else
                                if fp_mem_read = '1' then
                                    fp_result_reg <= data_rdata;
                                    state <= FP_RETIRE;
                                else
                                    if mem_read = '1' then result_reg <= load_value(data_rdata, memory_effective_address_reg, instruction(14 downto 12)); end if;
                                    state <= RETIRE;
                                end if;
                            end if;
                        end if;
                    when M_LAUNCH => state <= M_WAIT;
                    when M_WAIT =>
                        -- A unidade M entrega o resultado com um sinal done separado.
                        if m_done = '1' then
                            result_reg <= m_result;
                            state <= RETIRE;
                        end if;
                    when FP_LAUNCH => state <= FP_WAIT;
                    when FP_WAIT =>
                        -- Flags FP são acumuladas até o próximo reset.
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
                        -- A escrita no banco FP acontece neste ciclo por fp_writeback_enable.
                        retired_reg <= '1';
                        state <= FETCH;
                    when RETIRE =>
                        -- A escrita no banco inteiro acontece neste ciclo por writeback_enable.
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
    trap <= trap_reg;
    trap_cause <= trap_cause_reg;
    fp_fflags <= fp_flags_reg;
end Behavioral;
