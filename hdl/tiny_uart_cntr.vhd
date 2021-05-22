--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        tiny_uart_cntr.vhd
-- @note        VHDL'93
--
-- @brief       Counter
-- @details     synchronous counter, unsigned bit encoding
--
-- @date        2018-07-15
-- @version     0.1
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- counter
entity tiny_uart_cntr is
generic (
            WIDTH  : positive  := 8     --! width of counter
        );
port    (
            -- Clock/Reset
            R       : in    std_logic;                              --! asnychon reset
            C       : in    std_logic;                              --! clock, rising edge
            -- Control
            LD      : in    std_logic;                              --! load value
            EN      : in    std_logic;                              --! enable counting
            UP      : in    std_logic;                              --! count direction;    '1' : increment; '0' : decrement
            -- Value
            SET     : in    std_logic_vector(WIDTH-1 downto 0);     --! load value
            CNT     : out   std_logic_vector(WIDTH-1 downto 0)      --! actual count value
        );
end entity tiny_uart_cntr;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of tiny_uart_cntr is

    -----------------------------
    -- signal
    -----------------------------
        signal cntr_q   : unsigned(WIDTH-1 downto 0);   --! registered counter
    -----------------------------

begin

    ----------------------------------------------
    -- counter
    p_cntr : process ( R, C )
    begin
        if ( R = '1' ) then
            cntr_q  <=  (others => '0');
        elsif ( rising_edge(C) ) then
            if ( LD = '1' ) then
                cntr_q  <=  unsigned(SET);
            elsif ( EN = '1' ) then
                if ( UP = '1' ) then
                    cntr_q  <= cntr_q + 1;
                else
                    cntr_q  <= cntr_q - 1;
                end if;
            end if;
        end if;
    end process p_cntr;
    ----------------------------------------------

    ----------------------------------------------
    -- Assignments
    CNT <=  std_logic_vector(cntr_q);
    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
