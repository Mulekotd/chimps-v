library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_memory_bus is end tb_memory_bus;

architecture Behavioral of tb_memory_bus is
    signal instruction_valid, instruction_write, instruction_ready, instruction_error : STD_LOGIC := '0';
    signal instruction_address, instruction_wdata, instruction_rdata : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal instruction_wmask : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal data_valid, data_write, data_ready, data_error : STD_LOGIC := '0';
    signal data_address, data_wdata, data_rdata : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal data_wmask : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal memory_valid, memory_write, memory_ready, memory_error : STD_LOGIC := '0';
    signal memory_address, memory_wdata, memory_rdata : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal memory_wmask : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
begin
    dut : entity work.memory_bus
        port map (
            instruction_valid => instruction_valid, instruction_write => instruction_write,
            instruction_address => instruction_address, instruction_wdata => instruction_wdata,
            instruction_wmask => instruction_wmask, instruction_ready => instruction_ready,
            instruction_rdata => instruction_rdata, instruction_error => instruction_error,
            data_valid => data_valid, data_write => data_write, data_address => data_address,
            data_wdata => data_wdata, data_wmask => data_wmask, data_ready => data_ready,
            data_rdata => data_rdata, data_error => data_error,
            memory_valid => memory_valid, memory_write => memory_write, memory_address => memory_address,
            memory_wdata => memory_wdata, memory_wmask => memory_wmask, memory_ready => memory_ready,
            memory_rdata => memory_rdata, memory_error => memory_error
        );

    process
    begin
        instruction_valid <= '1'; instruction_address <= x"00000020";
        memory_ready <= '1'; memory_rdata <= x"11223344"; wait for 1 ns;
        assert memory_valid = '1' and memory_write = '0' and memory_address = x"00000020"
            report "Instruction request was not routed" severity error;
        assert instruction_ready = '1' and instruction_rdata = x"11223344" and instruction_error = '0'
            report "Instruction response was not routed" severity error;

        data_valid <= '1'; data_write <= '1'; data_address <= x"00000024";
        data_wdata <= x"AABBCCDD"; data_wmask <= "0011"; memory_error <= '1'; wait for 1 ns;
        assert memory_valid = '1' and memory_write = '1' and memory_address = x"00000024" and
               memory_wdata = x"AABBCCDD" and memory_wmask = "0011"
            report "Data request did not win fixed priority arbitration" severity error;
        assert data_ready = '1' and data_error = '1' and data_rdata = x"11223344"
            report "Data error response was not routed" severity error;
        assert instruction_ready = '0' and instruction_error = '0'
            report "Unselected instruction client observed a response" severity error;

        data_valid <= '0'; instruction_valid <= '0'; memory_ready <= '0'; memory_error <= '0'; wait for 1 ns;
        assert memory_valid = '0' and instruction_ready = '0' and data_ready = '0'
            report "Idle bus drove a transaction" severity error;
        assert false report "tb_memory_bus completed" severity note;
        wait;
    end process;
end Behavioral;
