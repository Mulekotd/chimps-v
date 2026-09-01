library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chimps_pkg.ALL;

-- Top-level de simulação: core, caches, árbitro e a única RAM backing.
entity chimps_v_system is
    Port (
        clk, rst : in STD_LOGIC;
        load_valid : in STD_LOGIC;
        load_address, load_data : in STD_LOGIC_VECTOR(31 downto 0);
        load_mask : in STD_LOGIC_VECTOR(3 downto 0);
        load_ready : out STD_LOGIC;
        flush_data_cache : in STD_LOGIC;
        debug_address : in STD_LOGIC_VECTOR(31 downto 0);
        debug_data : out STD_LOGIC_VECTOR(31 downto 0);
        current_pc, current_instruction : out STD_LOGIC_VECTOR(31 downto 0);
        retired, halted, illegal_instruction : out STD_LOGIC;
        fp_fflags : out STD_LOGIC_VECTOR(4 downto 0);
        instruction_accesses, instruction_misses : out STD_LOGIC_VECTOR(31 downto 0);
        data_accesses, data_misses : out STD_LOGIC_VECTOR(31 downto 0)
    );
end chimps_v_system;

architecture Structural of chimps_v_system is
    signal fetch_valid, fetch_ready, fetch_error, data_valid, data_write, data_ready, data_error : STD_LOGIC;
    signal fetch_address, fetch_rdata, data_address, data_wdata, data_rdata : STD_LOGIC_VECTOR(31 downto 0);
    signal data_wmask : STD_LOGIC_VECTOR(3 downto 0);
    signal ic_memory_valid, ic_memory_write, ic_memory_ready, ic_memory_error : STD_LOGIC;
    signal ic_memory_address, ic_memory_wdata, ic_memory_rdata : STD_LOGIC_VECTOR(31 downto 0);
    signal ic_memory_wmask : STD_LOGIC_VECTOR(3 downto 0);
    signal dc_memory_valid, dc_memory_write, dc_memory_ready, dc_memory_error : STD_LOGIC;
    signal dc_memory_address, dc_memory_wdata, dc_memory_rdata : STD_LOGIC_VECTOR(31 downto 0);
    signal dc_memory_wmask : STD_LOGIC_VECTOR(3 downto 0);
    signal memory_valid, memory_write, memory_ready, memory_error : STD_LOGIC;
    signal memory_address, memory_wdata, memory_rdata : STD_LOGIC_VECTOR(31 downto 0);
    signal memory_wmask : STD_LOGIC_VECTOR(3 downto 0);
    signal i_accesses_u, i_misses_u, i_hits, i_writebacks, i_service : unsigned(31 downto 0);
    signal d_accesses_u, d_misses_u, d_hits, d_writebacks, d_service : unsigned(31 downto 0);
begin
    core_i : entity work.core_rv32i_single
        port map (clk => clk, rst => rst, instruction_valid => fetch_valid,
                  instruction_address => fetch_address, instruction_ready => fetch_ready,
                  instruction_error => fetch_error, instruction_rdata => fetch_rdata,
                  data_valid => data_valid, data_write => data_write, data_address => data_address,
                  data_wdata => data_wdata, data_wmask => data_wmask, data_ready => data_ready,
                  data_error => data_error, data_rdata => data_rdata,
                  current_pc => current_pc, current_instruction => current_instruction,
                  retired => retired, halted => halted, illegal_instruction => illegal_instruction,
                  fp_fflags => fp_fflags);

    i_l1_i : entity work.cache_l1
        generic map (WAYS => 1, SETS => I_CACHE_SETS, READ_ONLY => true)
        port map (clk => clk, rst => rst, req => fetch_valid, wr => '0', addr => fetch_address,
                  wdata => (others => '0'), mask => "0000", ready => fetch_ready, error => fetch_error,
                  rdata => fetch_rdata, mv => ic_memory_valid, mw => ic_memory_write,
                  ma => ic_memory_address, md => ic_memory_wdata, mm => ic_memory_wmask,
                  mr => ic_memory_ready, me => ic_memory_error, mq => ic_memory_rdata,
                  accesses => i_accesses_u, hits => i_hits, misses => i_misses_u,
                  writebacks => i_writebacks, service_cycles => i_service, flush => '0');

    d_l1_i : entity work.cache_l1
        generic map (WAYS => 2, SETS => D_CACHE_SETS, READ_ONLY => false)
        port map (clk => clk, rst => rst, req => data_valid, wr => data_write, addr => data_address,
                  wdata => data_wdata, mask => data_wmask, ready => data_ready, error => data_error,
                  rdata => data_rdata, mv => dc_memory_valid, mw => dc_memory_write,
                  ma => dc_memory_address, md => dc_memory_wdata, mm => dc_memory_wmask,
                  mr => dc_memory_ready, me => dc_memory_error, mq => dc_memory_rdata,
                  accesses => d_accesses_u, hits => d_hits, misses => d_misses_u,
                  writebacks => d_writebacks, service_cycles => d_service, flush => flush_data_cache);

    bus_i : entity work.memory_bus
        port map (instruction_valid => ic_memory_valid, instruction_write => ic_memory_write,
                  instruction_address => ic_memory_address, instruction_wdata => ic_memory_wdata,
                  instruction_wmask => ic_memory_wmask, instruction_ready => ic_memory_ready,
                  instruction_rdata => ic_memory_rdata, instruction_error => ic_memory_error,
                  data_valid => dc_memory_valid, data_write => dc_memory_write,
                  data_address => dc_memory_address, data_wdata => dc_memory_wdata,
                  data_wmask => dc_memory_wmask, data_ready => dc_memory_ready,
                  data_rdata => dc_memory_rdata, data_error => dc_memory_error,
                  memory_valid => memory_valid, memory_write => memory_write,
                  memory_address => memory_address, memory_wdata => memory_wdata,
                  memory_wmask => memory_wmask, memory_ready => memory_ready,
                  memory_rdata => memory_rdata, memory_error => memory_error);

    memory_i : entity work.memory_backing_store
        port map (clk => clk, rst => rst, load_valid => load_valid, load_address => load_address,
                  load_data => load_data, load_mask => load_mask, load_ready => load_ready,
                  request_valid => memory_valid, request_write => memory_write,
                  request_address => memory_address, request_wdata => memory_wdata,
                  request_wmask => memory_wmask, request_ready => memory_ready,
                  request_rdata => memory_rdata, request_error => memory_error,
                  debug_address => debug_address, debug_data => debug_data);

    instruction_accesses <= std_logic_vector(i_accesses_u);
    instruction_misses <= std_logic_vector(i_misses_u);
    data_accesses <= std_logic_vector(d_accesses_u);
    data_misses <= std_logic_vector(d_misses_u);
end Structural;
