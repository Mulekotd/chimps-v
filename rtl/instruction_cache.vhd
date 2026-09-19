library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Especialização read-only da L1 direta para o caminho de busca.
entity instruction_cache is
    Port (
        clk, rst : in STD_LOGIC;
        cpu_valid : in STD_LOGIC;
        cpu_address : in STD_LOGIC_VECTOR(31 downto 0);
        cpu_ready, cpu_error : out STD_LOGIC;
        cpu_read_data : out STD_LOGIC_VECTOR(31 downto 0);
        memory_valid, memory_write : out STD_LOGIC;
        memory_address, memory_write_data : out STD_LOGIC_VECTOR(31 downto 0);
        memory_write_mask : out STD_LOGIC_VECTOR(3 downto 0);
        memory_ready, memory_error : in STD_LOGIC;
        memory_read_data : in STD_LOGIC_VECTOR(31 downto 0);
        access_count, hit_count, miss_count : out STD_LOGIC_VECTOR(31 downto 0)
    );
end instruction_cache;

architecture Structural of instruction_cache is

begin
    cache_i : entity work.l1_direct_mapped_cache
        port map (clk => clk, rst => rst, cpu_valid => cpu_valid, cpu_write => '0',
                  cpu_address => cpu_address, cpu_write_data => (others => '0'),
                  cpu_write_mask => (others => '0'), cpu_ready => cpu_ready,
                  cpu_read_data => cpu_read_data, cpu_error => cpu_error,
                  memory_valid => memory_valid, memory_write => memory_write,
                  memory_address => memory_address, memory_write_data => memory_write_data,
                  memory_write_mask => memory_write_mask, memory_ready => memory_ready,
                  memory_read_data => memory_read_data, memory_error => memory_error,
                  access_count => access_count, hit_count => hit_count, miss_count => miss_count);
end Structural;
