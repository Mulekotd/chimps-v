library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.chimps_pkg.all;

-- Cache unificada: 16 linhas diretamente mapeadas, uma word por linha.
entity cache_l1 is
    port (
        clk, rst, req, wr : in std_logic;
        addr, wdata : in std_logic_vector(31 downto 0);
        mask : in std_logic_vector(3 downto 0);
        ready, error : out std_logic;
        rdata : out std_logic_vector(31 downto 0);
        memory_valid, memory_write : out std_logic;
        memory_address, memory_wdata : out std_logic_vector(31 downto 0);
        memory_wmask : out std_logic_vector(3 downto 0);
        memory_ready, memory_error : in std_logic;
        memory_rdata : in std_logic_vector(31 downto 0);
        accesses, hits, misses : out unsigned(31 downto 0)
    );
end cache_l1;

architecture rtl of cache_l1 is
    type words_t is array (0 to CACHE_LINES - 1) of std_logic_vector(31 downto 0);
    type tags_t is array (0 to CACHE_LINES - 1) of std_logic_vector(31 downto 0);
    type state_t is (idle, lookup, memory_access, respond);

    signal data : words_t := (others => (others => '0'));
    signal tag : tags_t := (others => (others => '0'));
    signal valid : std_logic_vector(CACHE_LINES - 1 downto 0) := (others => '0');
    signal state : state_t := idle;
    signal request_address, request_wdata, response_data : std_logic_vector(31 downto 0) := (others => '0');
    signal request_mask : std_logic_vector(3 downto 0) := (others => '0');
    signal request_write, response_error : std_logic := '0';
    signal access_count, hit_count, miss_count : unsigned(31 downto 0) := (others => '0');

    function index_of(address : std_logic_vector(31 downto 0)) return natural is
    begin
        return to_integer(unsigned(address(5 downto 2)));
    end function;

    function word_tag(address : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable result : std_logic_vector(31 downto 0) := address;
    begin
        result(5 downto 0) := (others => '0');
        return result;
    end function;

    function merge_bytes(old_word, new_word : std_logic_vector(31 downto 0); byte_mask : std_logic_vector(3 downto 0)) return std_logic_vector is
        variable result : std_logic_vector(31 downto 0) := old_word;
    begin
        for byte_index in 0 to 3 loop
            if byte_mask(byte_index) = '1' then
                result(byte_index * 8 + 7 downto byte_index * 8) := new_word(byte_index * 8 + 7 downto byte_index * 8);
            end if;
        end loop;
        return result;
    end function;
begin
    ready <= '1' when state = respond else '0';

    error <= response_error;

    rdata <= response_data;
    accesses <= access_count;
    hits <= hit_count;
    misses <= miss_count;

    -- Um miss de leitura busca a word; todo store é write-through e não aloca em miss.
    memory_valid <= '1' when state = memory_access else '0';
    memory_write <= request_write;
    memory_address <= request_address;
    memory_wdata <= request_wdata;
    memory_wmask <= request_mask;

    process (clk)
        variable line_index : natural;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                valid <= (others => '0');
                state <= idle;
                response_error <= '0';
                response_data <= (others => '0');
                access_count <= (others => '0');
                hit_count <= (others => '0');
                miss_count <= (others => '0');
            else
                case state is
                    when idle =>
                        response_error <= '0';
                        if req = '1' then
                            request_address <= addr;
                            request_wdata <= wdata;
                            request_mask <= mask;
                            request_write <= wr;
                            access_count <= access_count + 1;
                            state <= lookup;
                        end if;
                    when lookup =>
                        line_index := index_of(request_address);
                        if valid(line_index) = '1' and tag(line_index) = word_tag(request_address) then
                            hit_count <= hit_count + 1;
                            response_data <= data(line_index);
                            if request_write = '1' then
                                data(line_index) <= merge_bytes(data(line_index), request_wdata, request_mask);
                                state <= memory_access;
                            else
                                state <= respond;
                            end if;
                        else
                            miss_count <= miss_count + 1;
                            state <= memory_access;
                        end if;
                    when memory_access =>
                        if memory_ready = '1' then
                            if memory_error = '1' then
                                response_error <= '1';
                                response_data <= (others => '0');
                            elsif request_write = '0' then
                                line_index := index_of(request_address);
                                data(line_index) <= memory_rdata;
                                tag(line_index) <= word_tag(request_address);
                                valid(line_index) <= '1';
                                response_data <= memory_rdata;
                            end if;

                            state <= respond;
                        end if;
                    when respond =>
                        state <= idle;
                end case;
            end if;
        end if;
    end process;
end rtl;
