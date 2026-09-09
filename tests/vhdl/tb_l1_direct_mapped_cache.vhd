library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chimps_pkg.ALL;

entity tb_l1_direct_mapped_cache is
end tb_l1_direct_mapped_cache;

architecture Behavioral of tb_l1_direct_mapped_cache is
    signal clk, rst : STD_LOGIC := '0';
    signal cpu_valid, cpu_write, cpu_ready, cpu_error : STD_LOGIC := '0';
    signal cpu_address, cpu_write_data, cpu_read_data : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal cpu_write_mask : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal memory_valid, memory_write, memory_ready, memory_error : STD_LOGIC := '0';
    signal memory_address, memory_write_data, memory_read_data : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal memory_write_mask : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal access_count, hit_count, miss_count : STD_LOGIC_VECTOR(31 downto 0);

    type backing_memory_t is array (0 to 8191) of STD_LOGIC_VECTOR(31 downto 0);

    signal backing_memory : backing_memory_t := (others => (others => '0'));
begin
    dut : entity work.l1_direct_mapped_cache
        port map (
            clk => clk, rst => rst,
            cpu_valid => cpu_valid, cpu_write => cpu_write, cpu_address => cpu_address,
            cpu_write_data => cpu_write_data, cpu_write_mask => cpu_write_mask,
            cpu_ready => cpu_ready, cpu_read_data => cpu_read_data, cpu_error => cpu_error,
            memory_valid => memory_valid, memory_write => memory_write,
            memory_address => memory_address, memory_write_data => memory_write_data,
            memory_write_mask => memory_write_mask, memory_ready => memory_ready,
            memory_read_data => memory_read_data, memory_error => memory_error,
            access_count => access_count, hit_count => hit_count, miss_count => miss_count
        );

    clk <= not clk after 5 ns;
    memory_ready <= memory_valid;
    memory_error <= '0';
    memory_read_data <= backing_memory(to_integer(unsigned(memory_address(14 downto 2))));

    -- Memória de suporte simples, sem espera, usada para verificar refill e write-through.
    process(clk)
    begin
        if rising_edge(clk) and memory_valid = '1' and memory_write = '1' then
            backing_memory(to_integer(unsigned(memory_address(14 downto 2)))) <= memory_write_data;
        end if;
    end process;

    process
    begin
        backing_memory(0) <= x"11223344";
        backing_memory(1) <= x"55667788";
        backing_memory(2) <= x"99AABBCC";
        backing_memory(3) <= x"DDEEFF00";

        rst <= '1';
        wait for 20 ns;
        rst <= '0';

        -- A primeira leitura gera miss e preenche a linha completa de 16 bytes.
        cpu_address <= x"00000000"; cpu_write <= '0'; cpu_valid <= '1';
        wait until rising_edge(clk) and cpu_ready = '1';
        cpu_valid <= '0';
        wait until rising_edge(clk) and cpu_ready = '1';

        assert cpu_read_data = x"11223344" report "L1 refill read failed" severity error;
        assert miss_count = x"00000001" report "L1 miss counter failed" severity error;

        -- A segunda leitura acerta a linha sem outro refill da memória de suporte.
        cpu_address <= x"00000004"; cpu_valid <= '1';
        wait until rising_edge(clk) and cpu_ready = '1';
        cpu_valid <= '0';
        wait until rising_edge(clk) and cpu_ready = '1';

        assert cpu_read_data = x"55667788" report "L1 hit read failed" severity error;
        assert hit_count = x"00000001" report "L1 hit counter failed" severity error;
        assert false report "tb_l1_direct_mapped_cache completed" severity note;

        wait;
    end process;
end Behavioral;
