library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.chimps_pkg.ALL;

entity tb_mul_div_unit is end tb_mul_div_unit;
architecture Behavioral of tb_mul_div_unit is
    signal clk, rst, start, busy, done : STD_LOGIC := '0';
    signal operation : mul_div_operation_t := MUL_OP;
    signal operand_a, operand_b, result : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
begin
    dut : entity work.mul_div_unit port map (clk, rst, start, operation, operand_a,
                                              operand_b, busy, done, result);
    clk <= not clk after 5 ns;
    process
    begin
        rst <= '1'; wait until rising_edge(clk); rst <= '0';
        operation <= MUL_OP; operand_a <= x"FFFFFFFE"; operand_b <= x"00000003"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert done = '1' and result = x"FFFFFFFA" report "MUL low product failed" severity error;
        operation <= MULH_OP; operand_a <= x"FFFFFFFF"; operand_b <= x"00000002"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert done = '1' and result = x"FFFFFFFF" report "MULH signed failed" severity error;
        operation <= MULHSU_OP; operand_a <= x"FFFFFFFF"; operand_b <= x"00000002"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert result = x"FFFFFFFF" report "MULHSU signed/unsigned failed" severity error;
        operation <= MULHU_OP; operand_a <= x"FFFFFFFF"; operand_b <= x"00000002"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert result = x"00000001" report "MULHU unsigned failed" severity error;
        operation <= DIV_OP; operand_a <= x"80000000"; operand_b <= x"FFFFFFFF"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert result = x"80000000" report "DIV overflow rule failed" severity error;
        operation <= DIVU_OP; operand_a <= x"00000007"; operand_b <= x"00000002"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert result = x"00000003" report "DIVU failed" severity error;
        operation <= REM_OP; operand_a <= x"FFFFFFF9"; operand_b <= x"00000002"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert result = x"FFFFFFFF" report "REM signed failed" severity error;
        operation <= REMU_OP; operand_a <= x"12345678"; operand_b <= x"00000000"; start <= '1';
        wait until rising_edge(clk); start <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert result = x"12345678" report "REMU divide-by-zero rule failed" severity error;
        assert false report "tb_mul_div_unit completed" severity note;
        wait;
    end process;
end Behavioral;
