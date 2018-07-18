--************************************************************************
-- @copyright   LGPLv3
-- @author      Kaeberlein
--
-- @file        tiny_uart_parity.vhd
-- @note        VHDL'93
--
-- @brief       parity
-- @details     combinatoric modul for even/odd parity calculation
--
-- @date        2018-07-17
-- @version     0.1
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- Parity calculation
entity tiny_uart_parity is
generic (
            EVEN_PARITY : bit  := '1';      --! selects parity mode;    '1' : Even Parity; '0' : Odd Parity
            DWIDTH      : positive := 8     --! width of data input
        );
port    (
            D   : in    std_logic_vector(DWIDTH-1 downto 0);    --! input data for parity calculation
            P   : out   std_logic                               --! calculated parity
        );
end entity tiny_uart_parity;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of tiny_uart_parity is
begin

    ----------------------------------------------
    -- combinatoric parity calculation
    p_parity : process ( D )
        variable parity : std_logic;    --! stores actual parity
    begin
        parity := to_stdulogic(EVEN_PARITY);   --! init based on selected parity
        for i in D'low to D'high loop
            parity := parity xor D(i);
        end loop;
        P <= parity;
    end process p_parity;
    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
