library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chimps_pkg.ALL;

-- RAM unificada para o caminho cache/barramento. O loader é aceito somente em
-- reset, portanto uma imagem nova também invalida as caches do sistema.
entity memory_backing_store is
    Port (
        clk, rst                       : in STD_LOGIC;
        load_valid                     : in STD_LOGIC;
        load_address, load_data        : in STD_LOGIC_VECTOR(31 downto 0);
        load_mask                      : in STD_LOGIC_VECTOR(3 downto 0);
        load_ready                     : out STD_LOGIC;
        request_valid, request_write   : in STD_LOGIC;
        request_address, request_wdata : in STD_LOGIC_VECTOR(31 downto 0);
        request_wmask                  : in STD_LOGIC_VECTOR(3 downto 0);
        request_ready                  : out STD_LOGIC;
        request_rdata                  : out STD_LOGIC_VECTOR(31 downto 0);
        request_error                  : out STD_LOGIC;
        debug_address                  : in STD_LOGIC_VECTOR(31 downto 0);
        debug_data                     : out STD_LOGIC_VECTOR(31 downto 0)
    );
end memory_backing_store;

architecture Behavioral of memory_backing_store is
    type memory_array_t is array (0 to (MEMORY_BYTES / 4) - 1) of STD_LOGIC_VECTOR(31 downto 0);
    signal memory : memory_array_t := (others => (others => '0'));

    function valid_word_address(address : STD_LOGIC_VECTOR(31 downto 0)) return boolean is
    begin
        return address(1 downto 0) = "00" and
               unsigned(address) < to_unsigned(MEMORY_BYTES, address'length);
    end function;

    function word_index(address : STD_LOGIC_VECTOR(31 downto 0)) return natural is
    begin
        return to_integer(unsigned(address(16 downto 2)));
    end function;

    function merge_bytes(old_word, new_word : STD_LOGIC_VECTOR(31 downto 0);
                         mask : STD_LOGIC_VECTOR(3 downto 0)) return STD_LOGIC_VECTOR is
        variable result : STD_LOGIC_VECTOR(31 downto 0) := old_word;
    begin
        for byte in 0 to 3 loop
            if mask(byte) = '1' then
                result(byte * 8 + 7 downto byte * 8) := new_word(byte * 8 + 7 downto byte * 8);
            end if;
        end loop;
        return result;
    end function;
begin
    load_ready <= '1' when rst = '1' and valid_word_address(load_address) else '0';
    request_ready <= request_valid when rst = '0' else '0';
    request_error <= '1' when request_valid = '1' and
                           (not valid_word_address(request_address)) else '0';

    request_rdata <= memory(word_index(request_address)) when valid_word_address(request_address) else (others => '0');
    debug_data <= memory(word_index(debug_address)) when valid_word_address(debug_address) else (others => '0');

    process(clk)
        variable index : natural;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                if load_valid = '1' and valid_word_address(load_address) then
                    index := word_index(load_address);
                    memory(index) <= merge_bytes(memory(index), load_data, load_mask);
                elsif load_valid = '0' then
                    memory <= (others => (others => '0'));
                end if;
            elsif request_valid = '1' and request_write = '1' and valid_word_address(request_address) then
                index := word_index(request_address);
                memory(index) <= merge_bytes(memory(index), request_wdata, request_wmask);
            end if;
        end if;
    end process;
end Behavioral;
