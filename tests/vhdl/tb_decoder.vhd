library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.chimps_pkg.ALL;

entity tb_decoder is end tb_decoder;
architecture Behavioral of tb_decoder is
    signal instruction : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal valid, reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch, branch_ne, jump, jalr : STD_LOGIC;
    signal operation : alu_operation_t;
    signal immediate_type : immediate_type_t;
begin
    dut : entity work.decoder port map (instruction, valid, reg_write, alu_src, operation,
        mem_read, mem_write, mem_to_reg, branch, branch_ne, jump, jalr, immediate_type);
    process
    begin
        instruction <= x"00500093"; wait for 1 ns; -- addi x1,x0,5
        assert valid = '1' and reg_write = '1' and alu_src = '1' and operation = ALU_ADD and immediate_type = IMM_I
            report "ADDI decode failed" severity error;
        instruction <= x"00202023"; wait for 1 ns; -- sw x2,0(x0)
        assert valid = '1' and mem_write = '1' and immediate_type = IMM_S report "SW decode failed" severity error;
        instruction <= x"202081D3"; wait for 1 ns; -- fsgnj.s f3,f1,f2
        assert valid = '1' and reg_write = '0' report "FSGNJ.S decode failed" severity error;
        instruction <= x"00000053"; wait for 1 ns; -- fadd.s f0,f0,f0
        assert valid = '0' and reg_write = '0' report "Unsupported FADD.S decode failed" severity error;
        instruction <= x"00000000"; wait for 1 ns;
        assert valid = '0' and reg_write = '0' report "Illegal instruction decode failed" severity error;
        assert false report "tb_decoder completed" severity note;
        wait;
    end process;
end Behavioral;
