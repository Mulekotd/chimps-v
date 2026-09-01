library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Topo de simulação: pipeline, cache unificada, árbitro e RAM única.
entity chimps_v_system is
    port (
        clk, rst : in std_logic;
        load_valid : in std_logic;
        load_address, load_data : in std_logic_vector(31 downto 0);
        load_mask : in std_logic_vector(3 downto 0);
        load_ready : out std_logic;
        debug_address : in std_logic_vector(31 downto 0);
        debug_data : out std_logic_vector(31 downto 0);
        current_pc, current_instruction : out std_logic_vector(31 downto 0);
        retired, halted, illegal_instruction : out std_logic;
        pipeline_valid : out std_logic_vector(3 downto 0);
        cache_accesses, cache_hits, cache_misses : out std_logic_vector(31 downto 0)
    );
end chimps_v_system;

architecture structural of chimps_v_system is
    signal instruction_valid, instruction_ready, instruction_error, data_valid, data_write, data_ready, data_error : std_logic;
    signal instruction_address, instruction_rdata, data_address, data_wdata, data_rdata, cache_rdata : std_logic_vector(31 downto 0);
    signal data_wmask : std_logic_vector(3 downto 0);
    signal cache_valid, cache_write, cache_ready, cache_error, ram_valid, ram_write, ram_ready, ram_error : std_logic;
    signal cache_address, cache_wdata, ram_address, ram_wdata, ram_rdata : std_logic_vector(31 downto 0);
    signal cache_wmask, ram_wmask : std_logic_vector(3 downto 0);
    signal accesses, hits, misses : unsigned(31 downto 0);
begin
    pipeline_i : entity work.pipeline
        port map (
            clk => clk, rst => rst, instruction_valid => instruction_valid, instruction_address => instruction_address,
            instruction_ready => instruction_ready, instruction_error => instruction_error, instruction_rdata => instruction_rdata,
            data_valid => data_valid, data_write => data_write, data_address => data_address, data_wdata => data_wdata,
            data_wmask => data_wmask, data_ready => data_ready, data_error => data_error, data_rdata => data_rdata,
            current_pc => current_pc, current_instruction => current_instruction, retired => retired, halted => halted,
            illegal_instruction => illegal_instruction, pipeline_valid => pipeline_valid);

    bus_i : entity work.memory_bus
        port map (
            clk => clk, rst => rst, instruction_valid => instruction_valid, instruction_write => '0', instruction_address => instruction_address,
            instruction_wdata => (others => '0'), instruction_wmask => "0000", instruction_ready => instruction_ready,
            instruction_rdata => instruction_rdata, instruction_error => instruction_error, data_valid => data_valid,
            data_write => data_write, data_address => data_address, data_wdata => data_wdata, data_wmask => data_wmask,
            data_ready => data_ready, data_rdata => data_rdata, data_error => data_error, memory_valid => cache_valid,
            memory_write => cache_write, memory_address => cache_address, memory_wdata => cache_wdata, memory_wmask => cache_wmask,
            memory_ready => cache_ready, memory_rdata => cache_rdata, memory_error => cache_error);

    cache_i : entity work.cache_l1
        port map (
            clk => clk, rst => rst, req => cache_valid, wr => cache_write, addr => cache_address, wdata => cache_wdata,
            mask => cache_wmask, ready => cache_ready, error => cache_error, rdata => cache_rdata, memory_valid => ram_valid,
            memory_write => ram_write, memory_address => ram_address, memory_wdata => ram_wdata, memory_wmask => ram_wmask,
            memory_ready => ram_ready, memory_error => ram_error, memory_rdata => ram_rdata, accesses => accesses, hits => hits, misses => misses);

    memory_i : entity work.memory_backing_store
        port map (
            clk => clk, rst => rst, load_valid => load_valid, load_address => load_address, load_data => load_data,
            load_mask => load_mask, load_ready => load_ready, request_valid => ram_valid, request_write => ram_write,
            request_address => ram_address, request_wdata => ram_wdata, request_wmask => ram_wmask, request_ready => ram_ready,
            request_rdata => ram_rdata, request_error => ram_error, debug_address => debug_address, debug_data => debug_data);

    cache_accesses <= std_logic_vector(accesses);
    cache_hits <= std_logic_vector(hits);
    cache_misses <= std_logic_vector(misses);
end structural;
