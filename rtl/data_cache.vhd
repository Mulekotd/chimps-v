library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Especialização de leitura/escrita da L1 direta para o caminho de dados.
entity data_cache is
    Port (
        clk, rst : in STD_LOGIC;
        cpu_valid, cpu_write : in STD_LOGIC;
        cpu_address, cpu_write_data : in STD_LOGIC_VECTOR(31 downto 0);
        cpu_write_mask : in STD_LOGIC_VECTOR(3 downto 0);
        cpu_ready, cpu_error : out STD_LOGIC;
        cpu_read_data : out STD_LOGIC_VECTOR(31 downto 0);
        memory_valid, memory_write : out STD_LOGIC;
        memory_address, memory_write_data : out STD_LOGIC_VECTOR(31 downto 0);
        memory_write_mask : out STD_LOGIC_VECTOR(3 downto 0);
        memory_ready, memory_error : in STD_LOGIC;
        memory_read_data : in STD_LOGIC_VECTOR(31 downto 0);
        access_count, hit_count, miss_count : out STD_LOGIC_VECTOR(31 downto 0)
    );
end data_cache;

architecture Structural of data_cache is
begin
    cache_d : entity work.l1_direct_mapped_cache
        port map (clk => clk, rst => rst, cpu_valid => cpu_valid, cpu_write => cpu_write,
                  cpu_address => cpu_address, cpu_write_data => cpu_write_data,
                  cpu_write_mask => cpu_write_mask, cpu_ready => cpu_ready,
                  cpu_read_data => cpu_read_data, cpu_error => cpu_error,
                  memory_valid => memory_valid, memory_write => memory_write,
                  memory_address => memory_address, memory_write_data => memory_write_data,
                  memory_write_mask => memory_write_mask, memory_ready => memory_ready,
                  memory_read_data => memory_read_data, memory_error => memory_error,
                  access_count => access_count, hit_count => hit_count, miss_count => miss_count);
end Structural;
