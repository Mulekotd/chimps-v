library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chimps_pkg.ALL;

-- Cache L1 direto e write-through.
-- O mesmo circuito pode ser instanciado como I-cache ou D-cache.
entity l1_direct_mapped_cache is
    Port (
        clk              : in  STD_LOGIC;
        rst              : in  STD_LOGIC;

        -- Interface de requisição do lado da CPU.
        cpu_valid        : in  STD_LOGIC;
        cpu_write        : in  STD_LOGIC;
        cpu_address      : in  STD_LOGIC_VECTOR(31 downto 0);
        cpu_write_data   : in  STD_LOGIC_VECTOR(31 downto 0);
        cpu_write_mask   : in  STD_LOGIC_VECTOR(3 downto 0);
        cpu_ready        : out STD_LOGIC;
        cpu_read_data    : out STD_LOGIC_VECTOR(31 downto 0);
        cpu_error        : out STD_LOGIC;

        -- Interface de requisição da memória backing.
        memory_valid    : out STD_LOGIC;
        memory_write    : out STD_LOGIC;
        memory_address  : out STD_LOGIC_VECTOR(31 downto 0);
        memory_write_data : out STD_LOGIC_VECTOR(31 downto 0);
        memory_write_mask : out STD_LOGIC_VECTOR(3 downto 0);
        memory_ready    : in  STD_LOGIC;
        memory_read_data: in  STD_LOGIC_VECTOR(31 downto 0);
        memory_error    : in  STD_LOGIC;

        -- Contadores monotônicos expostos ao simulador e à GUI.
        access_count    : out STD_LOGIC_VECTOR(31 downto 0);
        hit_count       : out STD_LOGIC_VECTOR(31 downto 0);
        miss_count      : out STD_LOGIC_VECTOR(31 downto 0)
    );
end l1_direct_mapped_cache;

architecture Behavioral of l1_direct_mapped_cache is
    type cache_line_t is array (0 to CACHE_WORDS_PER_LINE - 1) of STD_LOGIC_VECTOR(31 downto 0);
    type cache_data_t is array (0 to CACHE_SETS - 1) of cache_line_t;
    type cache_tag_t is array (0 to CACHE_SETS - 1) of STD_LOGIC_VECTOR(21 downto 0);

    type cache_state_t is (IDLE, LOOKUP, REFILL, WRITE_THROUGH, RESPONSE);

    -- Tag, valid bit e RAMs de dados formam o estado do circuito de cache.
    signal data_array  : cache_data_t := (others => (others => (others => '0')));
    signal tag_array   : cache_tag_t := (others => (others => '0'));
    signal valid_array : STD_LOGIC_VECTOR(CACHE_SETS - 1 downto 0) := (others => '0');

    -- A requisição armazenada da CPU permanece estável durante toda a transação de miss.
    signal request_write       : STD_LOGIC := '0';
    signal request_address     : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal request_write_data  : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal request_write_mask  : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal refill_word         : integer range 0 to CACHE_WORDS_PER_LINE - 1 := 0;
    signal response_data       : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal response_error      : STD_LOGIC := '0';
    signal state               : cache_state_t := IDLE;

    signal accesses : unsigned(31 downto 0) := (others => '0');
    signal hits     : unsigned(31 downto 0) := (others => '0');
    signal misses   : unsigned(31 downto 0) := (others => '0');

    function merge_bytes(
        old_value : STD_LOGIC_VECTOR(31 downto 0);
        new_value : STD_LOGIC_VECTOR(31 downto 0);
        byte_mask : STD_LOGIC_VECTOR(3 downto 0)
    ) return STD_LOGIC_VECTOR is
        variable merged : STD_LOGIC_VECTOR(31 downto 0) := old_value;
    begin
        if byte_mask(0) = '1' then merged(7 downto 0) := new_value(7 downto 0); end if;
        if byte_mask(1) = '1' then merged(15 downto 8) := new_value(15 downto 8); end if;
        if byte_mask(2) = '1' then merged(23 downto 16) := new_value(23 downto 16); end if;
        if byte_mask(3) = '1' then merged(31 downto 24) := new_value(31 downto 24); end if;
        return merged;
    end function;
begin
    -- Geração combinacional do handshake e das requisições à memória de suporte.
    cpu_ready <= '1' when state = IDLE else '0';
    cpu_read_data <= response_data;
    cpu_error <= response_error when state = RESPONSE else '0';

    process(state, request_address, request_write_data, request_write_mask, refill_word)
        variable refill_address : unsigned(31 downto 0);
    begin
        memory_valid <= '0';
        memory_write <= '0';
        memory_address <= (others => '0');
        memory_write_data <= (others => '0');
        memory_write_mask <= (others => '0');

        if state = REFILL then
            -- Uma linha de 16 bytes contém quatro words de 32 bits.
            refill_address := unsigned(request_address(31 downto 4) & "0000") +
                              to_unsigned(refill_word * 4, 32);
            memory_valid <= '1';
            memory_address <= std_logic_vector(refill_address);
        elsif state = WRITE_THROUGH then
            -- Esta versão da D-cache é write-through e não possui dirty bit.
            memory_valid <= '1';
            memory_write <= '1';
            memory_address <= request_address;
            memory_write_data <= request_write_data;
            memory_write_mask <= request_write_mask;
        end if;
    end process;

    -- Controlador sequencial da cache: lookup, refill de linha, write-through e resposta.
    process(clk)
        variable set_index : natural range 0 to CACHE_SETS - 1;
        variable word_index : natural range 0 to CACHE_WORDS_PER_LINE - 1;
        variable request_tag : STD_LOGIC_VECTOR(21 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                valid_array <= (others => '0');
                tag_array <= (others => (others => '0'));
                data_array <= (others => (others => (others => '0')));
                request_write <= '0';
                request_address <= (others => '0');
                request_write_data <= (others => '0');
                request_write_mask <= (others => '0');
                refill_word <= 0;
                response_data <= (others => '0');
                response_error <= '0';
                accesses <= (others => '0');
                hits <= (others => '0');
                misses <= (others => '0');
                state <= IDLE;
            else
                case state is
                    when IDLE =>
                        if cpu_valid = '1' then
                            request_write <= cpu_write;
                            request_address <= cpu_address;
                            request_write_data <= cpu_write_data;
                            request_write_mask <= cpu_write_mask;
                            accesses <= accesses + 1;
                            state <= LOOKUP;
                        end if;

                    when LOOKUP =>
                        set_index := to_integer(unsigned(request_address(9 downto 4)));
                        word_index := to_integer(unsigned(request_address(3 downto 2)));
                        request_tag := request_address(31 downto 10);

                        if valid_array(set_index) = '1' and tag_array(set_index) = request_tag then
                            hits <= hits + 1;
                            if request_write = '1' then
                                data_array(set_index)(word_index) <= merge_bytes(
                                    data_array(set_index)(word_index), request_write_data, request_write_mask);
                                state <= WRITE_THROUGH;
                            else
                                response_data <= data_array(set_index)(word_index);
                                response_error <= '0';
                                state <= RESPONSE;
                            end if;
                        else
                            misses <= misses + 1;
                            valid_array(set_index) <= '0';
                            refill_word <= 0;
                            state <= REFILL;
                        end if;

                    when REFILL =>
                        if memory_ready = '1' then
                            set_index := to_integer(unsigned(request_address(9 downto 4)));
                            word_index := to_integer(unsigned(request_address(3 downto 2)));
                            request_tag := request_address(31 downto 10);

                            if memory_error = '1' then
                                response_error <= '1';
                                response_data <= (others => '0');
                                state <= RESPONSE;
                            else
                                data_array(set_index)(refill_word) <= memory_read_data;
                                tag_array(set_index) <= request_tag;
                                if refill_word = CACHE_WORDS_PER_LINE - 1 then
                                    valid_array(set_index) <= '1';
                                    if request_write = '1' then
                                        data_array(set_index)(word_index) <= merge_bytes(
                                            data_array(set_index)(word_index), request_write_data, request_write_mask);
                                        state <= WRITE_THROUGH;
                                    elsif word_index = refill_word then
                                        response_data <= memory_read_data;
                                        response_error <= '0';
                                        state <= RESPONSE;
                                    else
                                        response_data <= data_array(set_index)(word_index);
                                        response_error <= '0';
                                        state <= RESPONSE;
                                    end if;
                                else
                                    refill_word <= refill_word + 1;
                                end if;
                            end if;
                        end if;

                    when WRITE_THROUGH =>
                        if memory_ready = '1' then
                            response_error <= memory_error;
                            response_data <= (others => '0');
                            state <= RESPONSE;
                        end if;

                    when RESPONSE =>
                        -- Mantém a resposta por um ciclo e depois aceita nova requisição.
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

    access_count <= std_logic_vector(accesses);
    hit_count <= std_logic_vector(hits);
    miss_count <= std_logic_vector(misses);
end Behavioral;
