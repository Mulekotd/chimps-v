library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.chimps_pkg.ALL;

entity tb_alu is
end tb_alu;

architecture Behavioral of tb_alu is
    signal a, b, result : STD_LOGIC_VECTOR(31 downto 0);
    signal zero, less_than : STD_LOGIC;
    signal operation : alu_operation_t;
begin
    dut : entity work.alu
        port map (a => a, b => b, operation => operation, result => result,
                  zero => zero, less_than => less_than);

    process
    begin
        a <= x"00000002"; b <= x"00000003"; operation <= ALU_ADD;
        wait for 1 ns;

        assert result = x"00000005" report "ALU_ADD failed" severity error;

        a <= x"00000007"; b <= x"00000003"; operation <= ALU_SUB;
        wait for 1 ns;

        assert result = x"00000004" report "ALU_SUB failed" severity error;
        assert zero = '0' report "ALU zero flag failed" severity error;

        a <= x"FFFFFFFF"; b <= x"00000001"; operation <= ALU_ADD;
        wait for 1 ns;

        assert result = x"00000000" report "ALU overflow wrap failed" severity error;
        assert zero = '1' report "ALU zero flag on zero result failed" severity error;

        a <= x"FFFFFFFF"; b <= x"00000001"; operation <= ALU_SLT;
        wait for 1 ns;

        assert result = x"00000001" report "ALU signed less-than failed" severity error;
        assert false report "tb_alu completed" severity note;

        wait;
    end process;
end Behavioral;
