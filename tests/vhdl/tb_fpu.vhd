library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.fp_pkg.ALL;

entity tb_fpu is end tb_fpu;
architecture Behavioral of tb_fpu is
    signal clk, rst, start, busy, done : STD_LOGIC := '0';
    signal operation : fp_operation_t := FP_CLASS;
    signal operand_a, operand_b, operand_c, result : fp32_t := (others => '0');
    signal fflags : STD_LOGIC_VECTOR(4 downto 0);
begin
    dut : entity work.fpu
        port map (clk => clk, rst => rst, start => start, operation => operation,
                  operand_a => operand_a, operand_b => operand_b, operand_c => operand_c,
                  busy => busy, done => done, result => result, fflags => fflags);
    clk <= not clk after 5 ns;
    process
    begin
        rst <= '1'; wait until rising_edge(clk); rst <= '0';
        operation <= FP_SGNJ; operand_a <= x"3F800000"; operand_b <= x"80000000"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert done = '1' and result = x"BF800000" and fflags = "00000" report "FSGNJ failed" severity error;
        operation <= FP_MIN; operand_a <= x"80000000"; operand_b <= x"00000000"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert result = x"80000000" report "FMIN signed zero failed" severity error;
        operation <= FP_LT; operand_a <= x"7FC00000"; operand_b <= x"3F800000"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert result = x"00000000" and fflags = FFLAG_NV report "FLT NaN handling failed" severity error;
        operation <= FP_CLASS; operand_a <= x"7F800001"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert result = x"00000100" report "FCLASS signaling NaN failed" severity error;
        operation <= FP_ADD; operand_a <= x"3F800000"; operand_b <= x"40000000"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert result = x"40400000" and fflags = "00000" report "FADD.S failed" severity error;
        operation <= FP_DIV; operand_a <= x"40C00000"; operand_b <= x"40000000"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert result = x"40400000" and fflags = "00000" report "FDIV.S failed" severity error;
        operation <= FP_SQRT; operand_a <= x"40800000"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert result = x"40000000" and fflags = "00000" report "FSQRT.S failed" severity error;
        operation <= FP_CVT_S_W; operand_a <= x"FFFFFFFE"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert result = x"C0000000" report "FCVT.S.W failed" severity error;
        operation <= FP_MADD; operand_a <= x"3F800000"; operand_b <= x"40000000"; operand_c <= x"40800000"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert result = x"40C00000" report "FMADD.S failed" severity error;
        assert false report "tb_fpu completed" severity note;
        wait;
    end process;
end Behavioral;
