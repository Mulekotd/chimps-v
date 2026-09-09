library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chimps_pkg.ALL;

entity core_rv32i_single is
    Port (
        clk                 : in  STD_LOGIC;
        rst                 : in  STD_LOGIC;
        current_pc          : out STD_LOGIC_VECTOR(31 downto 0);
        current_instruction : out STD_LOGIC_VECTOR(31 downto 0);
        current_alu_result  : out STD_LOGIC_VECTOR(31 downto 0);
        memory_address      : out STD_LOGIC_VECTOR(31 downto 0);
        memory_write_data   : out STD_LOGIC_VECTOR(31 downto 0);
        memory_write_enable : out STD_LOGIC;
        load_enable         : in  STD_LOGIC;
        load_address        : in  STD_LOGIC_VECTOR(31 downto 0);
        load_data           : in  STD_LOGIC_VECTOR(31 downto 0);
        retired             : out STD_LOGIC;
        illegal_instruction : out STD_LOGIC
    );
end core_rv32i_single;

architecture Behavioral of core_rv32i_single is
    -- Sinais que conectam os blocos arquiteturais no datapath de referência.
    signal pc                 : STD_LOGIC_VECTOR(31 downto 0);
    signal instruction        : STD_LOGIC_VECTOR(31 downto 0);
    signal immediate          : STD_LOGIC_VECTOR(31 downto 0);
    signal register_data1     : STD_LOGIC_VECTOR(31 downto 0);
    signal register_data2     : STD_LOGIC_VECTOR(31 downto 0);
    signal alu_operand_a      : STD_LOGIC_VECTOR(31 downto 0);
    signal alu_operand_b      : STD_LOGIC_VECTOR(31 downto 0);
    signal alu_result         : STD_LOGIC_VECTOR(31 downto 0);
    signal alu_zero           : STD_LOGIC;
    signal alu_less_than      : STD_LOGIC;
    signal memory_read_data   : STD_LOGIC_VECTOR(31 downto 0);
    signal writeback_data     : STD_LOGIC_VECTOR(31 downto 0);
    signal branch_target      : STD_LOGIC_VECTOR(31 downto 0);
    signal next_pc_is_target  : STD_LOGIC;
    signal branch_condition   : STD_LOGIC;

    signal decode_valid       : STD_LOGIC;
    signal reg_write          : STD_LOGIC;
    signal alu_src            : STD_LOGIC;
    signal alu_operation      : alu_operation_t;
    signal mem_read           : STD_LOGIC;
    signal mem_write          : STD_LOGIC;
    signal mem_to_reg         : STD_LOGIC;
    signal branch             : STD_LOGIC;
    signal branch_ne          : STD_LOGIC;
    signal jump               : STD_LOGIC;
    signal jalr               : STD_LOGIC;
    signal immediate_type     : immediate_type_t;
    signal writeback_enable   : STD_LOGIC;
begin
    -- O core de referência avança uma instrução completa por clock.
    program_counter_i : entity work.program_counter
        port map (
            clk => clk,
            rst => rst,
            pc_write => '1',
            pc_src => next_pc_is_target,
            branch_pc => branch_target,
            current_pc => pc
        );

    memory_i : entity work.main_memory
        port map (
            clk => clk,
            rst => rst,
            instruction_address => pc,
            instruction_data => instruction,
            data_address => alu_result,
            data_read_data => memory_read_data,
            data_write_enable => mem_write and decode_valid,
            data_write_data => register_data2,
            data_byte_enable => "1111",
            load_enable => load_enable,
            load_address => load_address,
            load_data => load_data,
            load_byte_enable => "1111"
        );

    decoder_i : entity work.decoder
        port map (
            instruction => instruction,
            valid => decode_valid,
            reg_write => reg_write,
            alu_src => alu_src,
            alu_operation => alu_operation,
            mem_read => mem_read,
            mem_write => mem_write,
            mem_to_reg => mem_to_reg,
            branch => branch,
            branch_ne => branch_ne,
            jump => jump,
            jalr => jalr,
            immediate_type => immediate_type
        );

    immediate_i : entity work.immediate_generator
        port map (
            instruction => instruction,
            immediate_type => immediate_type,
            immediate => immediate
        );

    register_file_i : entity work.register_file
        port map (
            clk => clk,
            rst => rst,
            write_enable => writeback_enable,
            write_address => instruction(11 downto 7),
            write_data => writeback_data,
            read_address1 => instruction(19 downto 15),
            read_address2 => instruction(24 downto 20),
            read_data1 => register_data1,
            read_data2 => register_data2
        );

    alu_i : entity work.alu
        port map (
            a => alu_operand_a,
            b => alu_operand_b,
            operation => alu_operation,
            result => alu_result,
            zero => alu_zero,
            less_than => alu_less_than
        );

    -- AUIPC usa o PC como primeiro operando da ALU; as demais instruções usam rs1.
    alu_operand_a <= pc when instruction(6 downto 0) = OPCODE_AUIPC else register_data1;
    alu_operand_b <= immediate when alu_src = '1' else register_data2;

    branch_condition <= (alu_zero and not branch_ne) or ((not alu_zero) and branch_ne);
    next_pc_is_target <= jump or (branch and branch_condition and decode_valid);

    branch_target <= (std_logic_vector(unsigned(register_data1) + unsigned(immediate)) and x"FFFFFFFE")
                     when jalr = '1' else std_logic_vector(unsigned(pc) + unsigned(immediate));

    writeback_data <= memory_read_data when mem_to_reg = '1' else
                      std_logic_vector(unsigned(pc) + 4) when jump = '1' else
                      alu_result;
    writeback_enable <= reg_write and decode_valid;

    begin
        if rising_edge(clk) then
            if rst = '1' then
                retired <= '0';
            else
                retired <= decode_valid;
            end if;
        end if;
    end process;

    current_pc <= pc;
    current_instruction <= instruction;
    current_alu_result <= alu_result;
    memory_address <= alu_result;
    memory_write_data <= register_data2;
    memory_write_enable <= mem_write and decode_valid;
    illegal_instruction <= not decode_valid;
end Behavioral;
