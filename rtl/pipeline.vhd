library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.chimps_pkg.all;

-- Pipeline didática IF/ID/EX/MEM/WB para o subconjunto mínimo de RV32I.
entity pipeline is
    port (
        clk, rst : in std_logic;
        instruction_valid : out std_logic;
        instruction_address : out std_logic_vector(31 downto 0);
        instruction_ready, instruction_error : in std_logic;
        instruction_rdata : in std_logic_vector(31 downto 0);
        data_valid, data_write : out std_logic;
        data_address, data_wdata : out std_logic_vector(31 downto 0);
        data_wmask : out std_logic_vector(3 downto 0);
        data_ready, data_error : in std_logic;
        data_rdata : in std_logic_vector(31 downto 0);
        current_pc, current_instruction : out std_logic_vector(31 downto 0);
        retired, halted, illegal_instruction : out std_logic;
        pipeline_valid : out std_logic_vector(3 downto 0)
    );
end pipeline;

architecture rtl of pipeline is
    type registers_t is array (0 to 31) of std_logic_vector(31 downto 0);

    signal registers : registers_t := (others => (others => '0'));
    signal fetch_pc : std_logic_vector(31 downto 0) := (others => '0');
    signal fetch_pending, discard_fetch, if_id_valid : std_logic := '0';
    signal if_id_pc, if_id_instruction : std_logic_vector(31 downto 0) := (others => '0');
    signal id_ex_valid, id_ex_regwrite, id_ex_load, id_ex_store, id_ex_branch, id_ex_stop : std_logic := '0';
    signal id_ex_pc, id_ex_rs1, id_ex_rs2, id_ex_imm : std_logic_vector(31 downto 0) := (others => '0');
    signal id_ex_rd : std_logic_vector(4 downto 0) := (others => '0');
    signal id_ex_opcode, id_ex_funct7 : std_logic_vector(6 downto 0) := (others => '0');
    signal ex_mem_valid, ex_mem_regwrite, ex_mem_load, ex_mem_store, ex_mem_stop : std_logic := '0';
    signal ex_mem_rd : std_logic_vector(4 downto 0) := (others => '0');
    signal ex_mem_result, ex_mem_store_data : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_wb_valid, mem_wb_regwrite, mem_wb_stop : std_logic := '0';
    signal mem_wb_rd : std_logic_vector(4 downto 0) := (others => '0');
    signal mem_wb_value : std_logic_vector(31 downto 0) := (others => '0');
    signal halted_reg, illegal_reg, retired_reg, stop_seen : std_logic := '0';
    signal raw_hazard, branch_taken, memory_wait, fetch_allowed : std_logic;
    signal execute_result, branch_target : std_logic_vector(31 downto 0);

    function immediate_i(instruction : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return std_logic_vector(resize(signed(instruction(31 downto 20)), 32));
    end function;

    function immediate_s(instruction : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable value : std_logic_vector(11 downto 0);
    begin
        value := instruction(31 downto 25) & instruction(11 downto 7);
        return std_logic_vector(resize(signed(value), 32));
    end function;

    function immediate_b(instruction : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable value : std_logic_vector(12 downto 0);
    begin
        value := instruction(31) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8) & '0';
        return std_logic_vector(resize(signed(value), 32));
    end function;

    function supported(instruction : std_logic_vector(31 downto 0)) return boolean is
    begin
        if instruction(6 downto 0) = OPCODE_OP_IMM then
            return instruction(14 downto 12) = "000";
        elsif instruction(6 downto 0) = OPCODE_OP then
            return instruction(14 downto 12) = "000" and (instruction(31 downto 25) = "0000000" or instruction(31 downto 25) = "0100000");
        elsif instruction(6 downto 0) = OPCODE_LOAD or instruction(6 downto 0) = OPCODE_STORE then
            return instruction(14 downto 12) = "010";
        elsif instruction(6 downto 0) = OPCODE_BRANCH then
            return instruction(14 downto 12) = "000";
        else
            return instruction = x"00100073";
        end if;
    end function;

    function uses_rs1(instruction : std_logic_vector(31 downto 0)) return boolean is
    begin
        return instruction(6 downto 0) = OPCODE_OP_IMM or instruction(6 downto 0) = OPCODE_OP or instruction(6 downto 0) = OPCODE_LOAD or instruction(6 downto 0) = OPCODE_STORE or instruction(6 downto 0) = OPCODE_BRANCH;
    end function;

    function uses_rs2(instruction : std_logic_vector(31 downto 0)) return boolean is
    begin
        return instruction(6 downto 0) = OPCODE_OP or instruction(6 downto 0) = OPCODE_STORE or instruction(6 downto 0) = OPCODE_BRANCH;
    end function;
begin
    process (all)
        variable source1, source2 : std_logic_vector(4 downto 0);
    begin
        raw_hazard <= '0';
        source1 := if_id_instruction(19 downto 15);
        source2 := if_id_instruction(24 downto 20);
        if if_id_valid = '1' then
            if uses_rs1(if_id_instruction) and source1 /= "00000" and ((id_ex_valid = '1' and id_ex_regwrite = '1' and id_ex_rd = source1) or (ex_mem_valid = '1' and ex_mem_regwrite = '1' and ex_mem_rd = source1) or (mem_wb_valid = '1' and mem_wb_regwrite = '1' and mem_wb_rd = source1)) then
                raw_hazard <= '1';
            elsif uses_rs2(if_id_instruction) and source2 /= "00000" and ((id_ex_valid = '1' and id_ex_regwrite = '1' and id_ex_rd = source2) or (ex_mem_valid = '1' and ex_mem_regwrite = '1' and ex_mem_rd = source2) or (mem_wb_valid = '1' and mem_wb_regwrite = '1' and mem_wb_rd = source2)) then
                raw_hazard <= '1';
            end if;
        end if;
    end process;

    execute_result <= std_logic_vector(unsigned(id_ex_rs1) + unsigned(id_ex_imm)) when id_ex_opcode = OPCODE_OP_IMM or id_ex_load = '1' or id_ex_store = '1' else std_logic_vector(unsigned(id_ex_rs1) - unsigned(id_ex_rs2)) when id_ex_opcode = OPCODE_OP and id_ex_funct7 = "0100000" else std_logic_vector(unsigned(id_ex_rs1) + unsigned(id_ex_rs2));
    branch_taken <= '1' when id_ex_valid = '1' and id_ex_branch = '1' and id_ex_rs1 = id_ex_rs2 else '0';
    branch_target <= std_logic_vector(unsigned(id_ex_pc) + unsigned(id_ex_imm));
    memory_wait <= '1' when ex_mem_valid = '1' and (ex_mem_load = '1' or ex_mem_store = '1') and data_ready = '0' else '0';
    fetch_allowed <= '1' when halted_reg = '0' and stop_seen = '0' and fetch_pending = '0' and if_id_valid = '0' and raw_hazard = '0' and memory_wait = '0' else '0';

    instruction_valid <= '1' when halted_reg = '0' and stop_seen = '0' and (fetch_pending = '1' or fetch_allowed = '1') else '0';
    instruction_address <= fetch_pc;
    data_valid <= ex_mem_valid and (ex_mem_load or ex_mem_store);
    data_write <= ex_mem_store;
    data_address <= ex_mem_result;
    data_wdata <= ex_mem_store_data;
    data_wmask <= "1111";

    process (clk)
    begin
        if rising_edge(clk) then
            retired_reg <= '0';

            if rst = '1' then
                registers <= (others => (others => '0'));
                fetch_pc <= (others => '0'); fetch_pending <= '0'; discard_fetch <= '0'; if_id_valid <= '0'; id_ex_valid <= '0'; ex_mem_valid <= '0'; ex_mem_stop <= '0'; mem_wb_valid <= '0'; mem_wb_stop <= '0'; halted_reg <= '0'; illegal_reg <= '0'; stop_seen <= '0';
            elsif halted_reg = '0' then
                if mem_wb_valid = '1' then
                    retired_reg <= '1';

                    if mem_wb_regwrite = '1' and mem_wb_rd /= "00000" then registers(to_integer(unsigned(mem_wb_rd))) <= mem_wb_value; end if;
                    if mem_wb_stop = '1' then halted_reg <= '1'; end if;
                end if;

                registers(0) <= (others => '0');
                mem_wb_valid <= '0';

                if memory_wait = '0' then
                    if ex_mem_valid = '1' then
                        if (ex_mem_load = '1' or ex_mem_store = '1') and data_error = '1' then
                            halted_reg <= '1'; illegal_reg <= '1';
                        else
                            mem_wb_valid <= ex_mem_valid; mem_wb_regwrite <= ex_mem_regwrite; mem_wb_stop <= ex_mem_stop; mem_wb_rd <= ex_mem_rd;
                            if ex_mem_load = '1' then mem_wb_value <= data_rdata; else mem_wb_value <= ex_mem_result; end if;
                        end if;
                    end if;

                    if id_ex_valid = '1' and id_ex_stop = '1' then
                        ex_mem_valid <= '1'; ex_mem_regwrite <= '0'; ex_mem_load <= '0'; ex_mem_store <= '0'; ex_mem_stop <= '1'; ex_mem_rd <= (others => '0'); ex_mem_result <= (others => '0'); ex_mem_store_data <= (others => '0');
                        id_ex_valid <= '0'; if_id_valid <= '0'; fetch_pending <= '0'; stop_seen <= '1';
                    elsif branch_taken = '1' then
                        ex_mem_valid <= '0'; ex_mem_stop <= '0'; id_ex_valid <= '0'; if_id_valid <= '0'; fetch_pc <= branch_target;

                        if instruction_valid = '1' and instruction_ready = '0' then
                            fetch_pending <= '1'; discard_fetch <= '1';
                        else
                            fetch_pending <= '0';
                        end if;
                    else
                        ex_mem_valid <= id_ex_valid; ex_mem_regwrite <= id_ex_regwrite; ex_mem_load <= id_ex_load; ex_mem_store <= id_ex_store; ex_mem_stop <= '0'; ex_mem_rd <= id_ex_rd; ex_mem_result <= execute_result; ex_mem_store_data <= id_ex_rs2;

                        if raw_hazard = '1' then
                            id_ex_valid <= '0';
                        elsif if_id_valid = '1' then
                            if supported(if_id_instruction) then
                                id_ex_valid <= '1'; id_ex_pc <= if_id_pc; id_ex_rd <= if_id_instruction(11 downto 7); id_ex_opcode <= if_id_instruction(6 downto 0); id_ex_funct7 <= if_id_instruction(31 downto 25);
                                id_ex_rs1 <= registers(to_integer(unsigned(if_id_instruction(19 downto 15)))); id_ex_rs2 <= registers(to_integer(unsigned(if_id_instruction(24 downto 20))));
                                id_ex_regwrite <= '1' when if_id_instruction(6 downto 0) = OPCODE_OP_IMM or if_id_instruction(6 downto 0) = OPCODE_OP or if_id_instruction(6 downto 0) = OPCODE_LOAD else '0';
                                id_ex_load <= '1' when if_id_instruction(6 downto 0) = OPCODE_LOAD else '0'; id_ex_store <= '1' when if_id_instruction(6 downto 0) = OPCODE_STORE else '0'; id_ex_branch <= '1' when if_id_instruction(6 downto 0) = OPCODE_BRANCH else '0'; id_ex_stop <= '1' when if_id_instruction = x"00100073" else '0';

                                if if_id_instruction(6 downto 0) = OPCODE_STORE then id_ex_imm <= immediate_s(if_id_instruction); elsif if_id_instruction(6 downto 0) = OPCODE_BRANCH then id_ex_imm <= immediate_b(if_id_instruction); else id_ex_imm <= immediate_i(if_id_instruction); end if;

                                if_id_valid <= '0';
                            else
                                halted_reg <= '1'; illegal_reg <= '1'; if_id_valid <= '0';
                            end if;
                        else
                            id_ex_valid <= '0';
                        end if;

                        if instruction_ready = '1' and instruction_valid = '1' then
                            if instruction_error = '1' or fetch_pc(1 downto 0) /= "00" then
                                halted_reg <= '1'; illegal_reg <= '1';
                            elsif discard_fetch = '1' then
                                discard_fetch <= '0'; fetch_pending <= '0';
                            else
                                if_id_valid <= '1'; if_id_pc <= fetch_pc; if_id_instruction <= instruction_rdata; fetch_pc <= std_logic_vector(unsigned(fetch_pc) + 4); fetch_pending <= '0';
                            end if;
                        elsif fetch_allowed = '1' then
                            fetch_pending <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    current_pc <= fetch_pc;
    current_instruction <= if_id_instruction;
    retired <= retired_reg;
    halted <= halted_reg;
    illegal_instruction <= illegal_reg;
    pipeline_valid <= if_id_valid & id_ex_valid & ex_mem_valid & mem_wb_valid;
end rtl;
