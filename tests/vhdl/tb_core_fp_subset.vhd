library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_core_fp_subset is end tb_core_fp_subset;

architecture Behavioral of tb_core_fp_subset is
    signal clk, rst : STD_LOGIC := '0';
    signal instruction_valid, instruction_ready, instruction_error : STD_LOGIC := '0';
    signal instruction_address, instruction_rdata : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal data_valid, data_write, data_ready, data_error : STD_LOGIC := '0';
    signal data_address, data_wdata, data_rdata : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal data_wmask : STD_LOGIC_VECTOR(3 downto 0);
    signal current_pc, current_instruction : STD_LOGIC_VECTOR(31 downto 0);
    signal fp_fflags : STD_LOGIC_VECTOR(4 downto 0);
    signal retired, halted, illegal_instruction : STD_LOGIC;
    signal stored_sign, stored_class, stored_equal, stored_nan_compare : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
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
            illegal_instruction => illegal_instruction, fp_fflags => fp_fflags);

    clk <= not clk after 5 ns;
    instruction_ready <= instruction_valid;
    instruction_error <= '0';
    data_ready <= data_valid;
    data_error <= '0';
    data_rdata <= (others => '0');

    with instruction_address select instruction_rdata <=
        x"3F8000B7" when x"00000000", -- LUI x1,0x3f800
        x"BF800137" when x"00000004", -- LUI x2,0xbf800
        x"F00080D3" when x"00000008", -- FMV.W.X f1,x1
        x"F0010153" when x"0000000C", -- FMV.W.X f2,x2
        x"202081D3" when x"00000010", -- FSGNJ.S f3,f1,f2
        x"E00181D3" when x"00000014", -- FMV.X.W x3,f3
        x"E0019253" when x"00000018", -- FCLASS.S x4,f3
        x"A020A2D3" when x"0000001C", -- FEQ.S x5,f1,f2
        x"04302023" when x"00000020", -- SW x3,64(x0)
        x"04402223" when x"00000024", -- SW x4,68(x0)
        x"04502423" when x"00000028", -- SW x5,72(x0)
        x"7FC00337" when x"0000002C", -- LUI x6,0x7fc00 (canonical qNaN)
        x"F0030353" when x"00000030", -- FMV.W.X f6,x6
        x"A01313D3" when x"00000034", -- FLT.S x7,f6,f1
        x"04702623" when x"00000038", -- SW x7,76(x0)
        x"00000053" when x"0000003C", -- FADD.S f0,f0,f0: not implemented
        x"00000000" when others;

    process(clk)
    begin
        if rising_edge(clk) and data_valid = '1' and data_write = '1' and data_ready = '1' then
            case data_address is
                when x"00000040" => stored_sign <= data_wdata;
                when x"00000044" => stored_class <= data_wdata;
                when x"00000048" => stored_equal <= data_wdata;
                when x"0000004C" => stored_nan_compare <= data_wdata;
                when others => null;
            end case;
        end if;
    end process;

    process
    begin
        rst <= '1'; wait until rising_edge(clk); rst <= '0';
        for cycle in 0 to 180 loop
            wait until rising_edge(clk);
            exit when halted = '1';
        end loop;
        assert halted = '1' and illegal_instruction = '1' and current_pc = x"0000003C"
            report "Unsupported FADD.S did not stop as an illegal instruction" severity error;
        assert stored_sign = x"BF800000" report "FSGNJ.S result did not return through FPR/GPR" severity error;
        assert stored_class = x"00000002" report "FCLASS.S did not write the integer destination" severity error;
        assert stored_equal = x"00000000" report "FEQ.S did not write the integer destination" severity error;
        assert stored_nan_compare = x"00000000" report "FLT.S NaN result was not written as zero" severity error;
        assert fp_fflags = "10000" report "FLT.S NaN did not accumulate NV in the core" severity error;
        assert false report "tb_core_fp_subset completed" severity note;
        wait;
    end process;
end Behavioral;
