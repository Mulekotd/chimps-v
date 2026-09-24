library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

-- Programa dirigido: cada resultado RV32I é tornado observável por uma store.
entity tb_rv32i_architectural is end;
architecture test of tb_rv32i_architectural is
    signal clk, rst, iv, ir, ie, dv, dw, dr, de, retired, halted, illegal, trap : std_logic := '0';
    signal ia, id, da, dd, rd, pc, insn, cause : std_logic_vector(31 downto 0) := (others => '0');
    signal mask : std_logic_vector(3 downto 0);
    signal stores : natural := 0;
begin
    clk <= not clk after 5 ns;
    dut : entity work.core_rv32i_single port map (clk, rst, iv, ia, ir, ie, id, dv, dw, da, dd, mask,
        dr, de, rd, pc, insn, retired, halted, illegal, trap, cause, open);
    ir <= iv; ie <= '0'; dr <= dv; de <= '0'; rd <= x"00000080";
    with ia select id <=
        x"00100093" when x"00000000", -- addi x1,1
        x"00200113" when x"00000004", -- addi x2,2
        x"002081B3" when x"00000008", -- add
        x"40110533" when x"0000000C", -- sub
        x"00119233" when x"00000010", -- sll
        x"0020A2B3" when x"00000014", -- slt
        x"0020B333" when x"00000018", -- sltu
        x"0020C3B3" when x"0000001C", -- xor
        x"0020E433" when x"00000020", -- or
        x"0020F4B3" when x"00000024", -- and
        x"00302023" when x"00000028", -- sw x3,0
        x"00A02223" when x"0000002C", -- sw x10,4
        x"00402423" when x"00000030", -- sw x4,8
        x"00502623" when x"00000034", -- sw x5,12
        x"00602823" when x"00000038", -- sw x6,16
        x"00702A23" when x"0000003C", -- sw x7,20
        x"00802C23" when x"00000040", -- sw x8,24
        x"00902E23" when x"00000044", -- sw x9,28
        x"00000000" when others;
    process(clk)
        type expected_t is array (0 to 7) of std_logic_vector(31 downto 0);
        constant expected : expected_t := (x"00000003",x"00000001",x"00000006",x"00000001",x"00000001",x"00000003",x"00000003",x"00000000");
    begin
        if rising_edge(clk) and dv = '1' and dw = '1' and dr = '1' then
            assert mask = "1111" and dd = expected(stores) report "RV32I OP architectural result mismatch" severity failure;
            stores <= stores + 1;
        end if;
    end process;
    process
    begin
        rst <= '1'; wait until rising_edge(clk); rst <= '0';
        for n in 0 to 200 loop wait until rising_edge(clk); exit when halted = '1'; end loop;
        assert stores = 8 and illegal = '1' report "RV32I positive/illegal-encoding counterproof failed" severity failure;
        report "tb_rv32i_architectural completed"; finish;
    end process;
end;
