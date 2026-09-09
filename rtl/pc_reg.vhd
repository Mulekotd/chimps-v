library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chimps_pkg.ALL;

entity program_counter is
    Port (
        clk        : in  STD_LOGIC;                    -- Clock do sistema
        rst        : in  STD_LOGIC;                    -- Reset síncrono (limpa o PC para 0x0000)
        pc_write   : in  STD_LOGIC;                    -- Habilitação (stall: '1' atualiza, '0' mantém o valor)
        pc_src     : in  STD_LOGIC;                    -- Controle do mux ('0' = incremento, '1' = branch/jump)
        branch_pc  : in  STD_LOGIC_VECTOR(31 downto 0);-- Endereço alvo de branches ou jumps
        current_pc : out STD_LOGIC_VECTOR(31 downto 0) -- Saída do program counter
    );
end program_counter;

architecture Behavioral of program_counter is
    -- Sinal interno que armazena o estado numérico atual do registrador.
    signal pc_reg : unsigned(31 downto 0) := (others => '0');
begin

    -- Processo sequencial que modela o registrador na borda de subida do clock.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Vetor de reset apontando para a posição de memória 0x0000.
                pc_reg <= (others => '0');
            elsif pc_write = '1' then
                -- Quando habilitado, seleciona entre incremento sequencial e branch.
                if pc_src = '1' then
                    pc_reg <= unsigned(branch_pc);
                else
                    -- As instruções RV32I têm 32 bits e, portanto, avançam 4 bytes.
                    pc_reg <= pc_reg + 4;
                end if;
            -- else (pc_write = '0'): pc_reg mantém implicitamente seu valor (stall).
            end if;
        end if;
    end process;

    -- Atribuição contínua convertendo o tipo numérico para standard logic vector.
    current_pc <= std_logic_vector(pc_reg);

end Behavioral;
