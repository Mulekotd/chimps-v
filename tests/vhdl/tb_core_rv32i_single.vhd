library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_core_rv32i_single is end tb_core_rv32i_single;

architecture Behavioral of tb_core_rv32i_single is
    signal clk, rst : STD_LOGIC := '0';
    signal instruction_valid, instruction_ready, instruction_error : STD_LOGIC := '0';
    signal instruction_address, instruction_rdata : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal data_valid, data_write, data_ready, data_error : STD_LOGIC := '0';
    signal data_address, data_wdata, data_rdata : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal data_wmask : STD_LOGIC_VECTOR(3 downto 0);
    signal current_pc, current_instruction : STD_LOGIC_VECTOR(31 downto 0);
    signal retired, halted, illegal_instruction, trap : STD_LOGIC;
    signal trap_cause : STD_LOGIC_VECTOR(31 downto 0);
begin
    dut : entity work.core_rv32i_single
        port map (
            clk => clk, rst => rst, instruction_valid => instruction_valid,
            instruction_address => instruction_address, instruction_ready => instruction_ready,
            instruction_error => instruction_error, instruction_rdata => instruction_rdata,
            data_valid => data_valid, data_write => data_write, data_address => data_address,
            data_wdata => data_wdata, data_wmask => data_wmask, data_ready => data_ready,
            data_error => data_error, data_rdata => data_rdata, current_pc => current_pc,
            current_instruction => current_instruction, retired => retired, halted => halted,
            illegal_instruction => illegal_instruction, trap => trap, trap_cause => trap_cause, fp_fflags => open);

    clk <= not clk after 5 ns;
    instruction_ready <= instruction_valid;
    instruction_error <= '0';
    data_error <= '0';
    data_rdata <= (others => '0');
    with instruction_address select instruction_rdata <=
        x"00600093" when x"00000000", -- ADDI x1,x0,6
        x"00700113" when x"00000004", -- ADDI x2,x0,7
        x"022081B3" when x"00000008", -- MUL x3,x1,x2
        x"00302023" when x"0000000C", -- SW x3,0(x0)
        x"00000000" when others;

    process
    begin
        rst <= '1'; wait until rising_edge(clk); rst <= '0';
        wait until data_valid = '1';
        assert data_write = '1' and data_address = x"00000000" and data_wdata = x"0000002A" and data_wmask = "1111"
            report "RV32M result did not reach the retained store request" severity error;
        wait until rising_edge(clk); wait until rising_edge(clk);
        assert data_valid = '1' and data_address = x"00000000" and data_wdata = x"0000002A"
            report "Store request changed while the memory side was stalled" severity error;
        data_ready <= '1'; wait until rising_edge(clk); data_ready <= '0';
        for cycle in 0 to 20 loop
            wait until rising_edge(clk);
            exit when halted = '1';
        end loop;
        assert halted = '1' and illegal_instruction = '1' and current_pc = x"00000010"
            report "Core did not stop at the invalid instruction after the stalled store" severity error;
        assert false report "tb_core_rv32i_single completed" severity note;
        wait;
    end process;
end Behavioral;
