library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_pc_reg is
end tb_pc_reg;

architecture Behavioral of tb_pc_reg is
    signal clk, rst, pc_write, pc_src : STD_LOGIC := '0';
    signal branch_pc, current_pc : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
begin
    dut : entity work.program_counter
        port map (clk => clk, rst => rst, pc_write => pc_write, pc_src => pc_src,
                  branch_pc => branch_pc, current_pc => current_pc);

    clk <= not clk after 5 ns;

    process
    begin
        rst <= '1'; pc_write <= '1';
        wait for 10 ns;
        assert current_pc = x"00000000" report "PC reset failed" severity error;

        rst <= '0'; pc_src <= '0';
        wait for 10 ns;
        assert current_pc = x"00000004" report "PC increment failed" severity error;

        pc_write <= '0';
        wait for 10 ns;
        assert current_pc = x"00000004" report "PC stall failed" severity error;

        pc_write <= '1'; pc_src <= '1'; branch_pc <= x"00000040";
        wait for 10 ns;
        assert current_pc = x"00000040" report "PC branch target failed" severity error;

        assert false report "tb_pc_reg completed" severity note;
        wait;
    end process;
end Behavioral;
