library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.chimps_pkg.ALL;
use work.fp_pkg.ALL;

entity tb_decoder is end tb_decoder;
architecture Behavioral of tb_decoder is
    signal instruction : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal valid, reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch, branch_ne, jump, jalr : STD_LOGIC;
    signal m_enable, fp_enable, fp_write, fp_result_to_gpr, fp_move_from_int, fp_move_to_int, fp_mem_read, fp_mem_write, fp_operand_from_gpr : STD_LOGIC;
    signal operation : alu_operation_t;
    signal immediate_type : immediate_type_t;
    signal m_operation : mul_div_operation_t;
    signal fp_operation : fp_operation_t;
    signal fp_rounding_mode : STD_LOGIC_VECTOR(2 downto 0);
begin
    dut : entity work.decoder
        port map (
            instruction => instruction, valid => valid, reg_write => reg_write,
            alu_src => alu_src, alu_operation => operation, mem_read => mem_read,
            mem_write => mem_write, mem_to_reg => mem_to_reg, branch => branch,
            branch_ne => branch_ne, jump => jump, jalr => jalr,
            immediate_type => immediate_type, m_enable => m_enable,
            m_operation => m_operation, fp_enable => fp_enable,
            fp_operation => fp_operation, fp_write => fp_write,
            fp_result_to_gpr => fp_result_to_gpr,
            fp_move_from_int => fp_move_from_int, fp_move_to_int => fp_move_to_int,
            fp_mem_read => fp_mem_read, fp_mem_write => fp_mem_write,
            fp_operand_from_gpr => fp_operand_from_gpr, fp_rounding_mode => fp_rounding_mode);
    process
    begin
        instruction <= x"00500093"; wait for 1 ns; -- addi x1,x0,5
        assert valid = '1' and reg_write = '1' and alu_src = '1' and operation = ALU_ADD and immediate_type = IMM_I
            report "ADDI decode failed" severity error;
        instruction <= x"00202023"; wait for 1 ns; -- sw x2,0(x0)
        assert valid = '1' and mem_write = '1' and immediate_type = IMM_S report "SW decode failed" severity error;
        instruction <= x"402081B3"; wait for 1 ns; -- sub x3,x1,x2
        assert valid = '1' and reg_write = '1' and operation = ALU_SUB
            report "SUB decode failed" severity error;
        instruction <= x"022081B3"; wait for 1 ns; -- mul x3,x1,x2
        assert valid = '1' and m_enable = '1' and m_operation = MUL_OP
            report "M extension decode failed" severity error;
        instruction <= x"00000063"; wait for 1 ns; -- beq x0,x0,0
        assert valid = '1' and branch = '1' and branch_ne = '0' and immediate_type = IMM_B
            report "BEQ decode failed" severity error;
        instruction <= x"00301093"; wait for 1 ns; -- slli x1,x0,3
        assert valid = '1' and reg_write = '1' and operation = ALU_SLL
            report "SLLI decode failed" severity error;
        instruction <= x"FFF02093"; wait for 1 ns; -- slti x1,x0,-1
        assert valid = '1' and operation = ALU_SLT report "SLTI decode failed" severity error;
        instruction <= x"FFF03093"; wait for 1 ns; -- sltiu x1,x0,-1
        assert valid = '1' and operation = ALU_SLTU report "SLTIU decode failed" severity error;
        instruction <= x"00000083"; wait for 1 ns; -- lb x1,0(x0)
        assert valid = '1' and mem_read = '1' report "LB decode failed" severity error;
        instruction <= x"00005083"; wait for 1 ns; -- lhu x1,0(x0)
        assert valid = '1' and mem_read = '1' report "LHU decode failed" severity error;
        instruction <= x"00200023"; wait for 1 ns; -- sb x2,0(x0)
        assert valid = '1' and mem_write = '1' report "SB decode failed" severity error;
        instruction <= x"00201023"; wait for 1 ns; -- sh x2,0(x0)
        assert valid = '1' and mem_write = '1' report "SH decode failed" severity error;
        instruction <= x"00004063"; wait for 1 ns; -- blt x0,x0,0
        assert valid = '1' and branch = '1' report "BLT decode failed" severity error;
        instruction <= x"00007063"; wait for 1 ns; -- bgeu x0,x0,0
        assert valid = '1' and branch = '1' report "BGEU decode failed" severity error;
        instruction <= x"0000000F"; wait for 1 ns; -- fence
        assert valid = '1' and reg_write = '0' report "FENCE decode failed" severity error;
        instruction <= x"00000073"; wait for 1 ns; -- ecall is recognized; the core raises cause 11
        assert valid = '1' report "ECALL decode failed" severity error;
        instruction <= x"40301093"; wait for 1 ns; -- reserved SLLI funct7
        assert valid = '0' report "Reserved shift encoding was accepted" severity error;
        instruction <= x"202081D3"; wait for 1 ns; -- fsgnj.s f3,f1,f2
        assert valid = '1' and reg_write = '0' and fp_enable = '1' and fp_write = '1' and fp_operation = FP_SGNJ
            report "FSGNJ.S decode failed" severity error;
        instruction <= x"00000053"; wait for 1 ns; -- fadd.s f0,f0,f0
        assert valid = '1' and fp_enable = '1' and fp_write = '1' and fp_operation = FP_ADD
            report "FADD.S decode failed" severity error;
        instruction <= x"18208043"; wait for 1 ns; -- fmadd.s f0,f1,f2,f3
        assert valid = '1' and fp_enable = '1' and fp_write = '1' and fp_operation = FP_MADD
            report "FMADD.S decode failed" severity error;
        instruction <= x"05402487"; wait for 1 ns; -- flw f9,84(x0)
        assert valid = '1' and fp_mem_read = '1' and fp_write = '1' and immediate_type = IMM_I
            report "FLW decode failed" severity error;
        instruction <= x"00000000"; wait for 1 ns;
        assert valid = '0' and reg_write = '0' report "Illegal instruction decode failed" severity error;
        assert false report "tb_decoder completed" severity note;
        wait;
    end process;
end Behavioral;
