library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_chimps_v_system is end tb_chimps_v_system;

architecture Behavioral of tb_chimps_v_system is
    signal clk, rst, load_valid, load_ready, flush_data_cache : STD_LOGIC := '0';
    signal load_address, load_data : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal load_mask : STD_LOGIC_VECTOR(3 downto 0) := "1111";
    signal debug_address, debug_data, current_pc, current_instruction : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal retired, halted, illegal_instruction, trap : STD_LOGIC;
    signal trap_cause : STD_LOGIC_VECTOR(31 downto 0);
    signal fp_fflags : STD_LOGIC_VECTOR(4 downto 0);
    signal i_accesses, i_hits, i_misses, i_writebacks, i_service, i_stalls, i_amat : STD_LOGIC_VECTOR(31 downto 0);
    signal d_accesses, d_hits, d_misses, d_writebacks, d_service, d_stalls, d_amat : STD_LOGIC_VECTOR(31 downto 0);
begin
    dut : entity work.chimps_v_system
        port map (
            clk => clk, rst => rst,
            load_valid => load_valid, load_address => load_address,
            load_data => load_data, load_mask => load_mask, load_ready => load_ready,
            flush_data_cache => flush_data_cache,
            uart_rx_ready => open, uart_tx_valid => open, uart_tx_data => open,
            debug_address => debug_address, debug_data => debug_data,
            current_pc => current_pc, current_instruction => current_instruction,
            retired => retired, halted => halted, illegal_instruction => illegal_instruction,
            trap => trap, trap_cause => trap_cause,
            fp_fflags => fp_fflags,
            instruction_accesses => i_accesses, instruction_hits => i_hits, instruction_misses => i_misses,
            instruction_writebacks => i_writebacks, instruction_service_cycles => i_service,
            instruction_stalls => i_stalls, instruction_amat => i_amat,
            data_accesses => d_accesses, data_hits => d_hits, data_misses => d_misses,
            data_writebacks => d_writebacks, data_service_cycles => d_service,
            data_stalls => d_stalls, data_amat => d_amat
        );

    clk <= not clk after 5 ns;

    process
        procedure load_word(constant address : STD_LOGIC_VECTOR(31 downto 0);
                            constant value : STD_LOGIC_VECTOR(31 downto 0)) is
        begin
            load_address <= address;
            load_data <= value;
            load_valid <= '1';
            wait until rising_edge(clk);
            assert load_ready = '1' report "System loader did not accept word during reset" severity error;
        end procedure;
    begin
        -- x1=6; x2=7; x3=x1*x2; RAM[64]=x3; x4=RAM[64]; x5=x4+1; RAM[68]=x5.
        rst <= '1';
        wait until rising_edge(clk);
        load_word(x"00000000", x"00600093"); -- ADDI x1,x0,6
        load_word(x"00000004", x"00700113"); -- ADDI x2,x0,7
        load_word(x"00000008", x"022081B3"); -- MUL x3,x1,x2
        load_word(x"0000000C", x"04302023"); -- SW x3,64(x0)
        load_word(x"00000010", x"04002203"); -- LW x4,64(x0)
        load_word(x"00000014", x"00120293"); -- ADDI x5,x4,1
        load_word(x"00000018", x"04502223"); -- SW x5,68(x0)
        load_word(x"0000001C", x"00000000"); -- invalid encoding ends the program
        load_valid <= '0';
        rst <= '0';

        for cycle in 0 to 300 loop
            wait until rising_edge(clk);
            exit when halted = '1';
        end loop;
        wait for 1 ns;

        assert halted = '1' and illegal_instruction = '1'
            report "System did not stop on the intentionally invalid instruction" severity error;
        assert current_pc = x"0000001C" and current_instruction = x"00000000"
            report "Core did not retain the faulting fetch" severity error;
        flush_data_cache <= '1';
        for cycle in 0 to 100 loop wait until rising_edge(clk); end loop;
        flush_data_cache <= '0';
        debug_address <= x"00000040"; wait for 1 ns;
        assert debug_data = x"0000002A" report "MUL/store path did not reach backing RAM" severity error;
        debug_address <= x"00000044"; wait for 1 ns;
        assert debug_data = x"0000002B" report "Load/use/store path did not reach backing RAM" severity error;
        assert i_accesses /= x"00000000" and i_misses /= x"00000000" and
               d_accesses /= x"00000000" and d_misses /= x"00000000"
            report "Integrated caches were not used by the core" severity error;
        assert i_hits /= x"00000000" and i_service /= x"00000000" and i_stalls /= x"00000000" and
               d_hits /= x"00000000" and d_writebacks /= x"00000000" and d_service /= x"00000000" and
               d_stalls /= x"00000000" and d_amat /= x"00000000"
            report "Integrated cache metrics were not exposed" severity error;
        assert false report "tb_chimps_v_system completed" severity note;
        wait;
    end process;
end Behavioral;
