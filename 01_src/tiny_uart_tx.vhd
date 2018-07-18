--************************************************************************
-- @copyright   LGPLv3
-- @author      Kaeberlein
--
-- @file        tiny_uart_tx.vhd
-- @note        VHDL'93
--
-- @brief       TX
-- @details     uart transmitter with single state buffer register
--
-- @date        2018-07-18
-- @version     0.1
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use IEEE.math_real.ceil;
    use IEEE.math_real.log2;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- Parity calculation
entity tiny_uart_tx is
generic (
            CLKDIV  : positive  := 20;      --! builds baud rate
            DWIDTH  : positive  := 8;       --! data width
            ENAPAR	: boolean   := false;	--! parity check		    true : enable;	false : disable
            EVENPAR : bit       := '1'      --! selects parity mode;    '1' : Even Parity; '0' : Odd Parity
        );
port    (
            -- Clock/Reset
            R       : in    std_logic;                          --! asnychon reset
            C       : in    std_logic;                          --! master clock
            -- Control
            WR      : in    std_logic;                          --! Write new data  
            MTY     : out   std_logic;                          --! buffer register empty
            BSY     : out   std_logic;                          --! shift register active
            -- Data
            SO      : out   std_logic;                          --! serial data out
            DI      : in    std_logic_vector(DWIDTH-1 downto 0) --! Parallel data input
        );
end entity tiny_uart_tx;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of tiny_uart_tx is

    -----------------------------
    -- Constants
        constant C_BAUD_CNTR_W  : integer := integer(ceil(log2(real(CLKDIV)))); --! counter bit width
    -----------------------------
    
    
    -----------------------------
    -- Signals
        signal baud_rate_cnt    : unsigned(C_BAUD_CNTR_W-1 downto 0);   --! baud rate count
        signal baud_rate_ovl    : std_logic;                            --! reload baud rate counter
        
    -----------------------------



begin

    ----------------------------------------------
    -- baud rate generation
	i_baud_rate : entity work.tiny_uart_cntr
		generic map (
						WIDTH   => C_BAUD_CNTR_W    --! width of counter
                    )
		port map    (
						R   => R,               --! asnychon reset
						C   => C,               --! clock
						LD  => baud_rate_ovl,   --! load value
						EN  => ,
						UP  => '1',             --! count direction;    '1' : upcounting; '0' downcounting
						SET => (others => '0'), --! load value
						CNT => baud_rate_cnt    --! actual count value
					);
		-- help logic
		baud_rate_ovl <= '1' when ( baud_rate_cnt > CLKDIV-1 ) else '0';    --! counter overflow
	----------------------------------------------



    ----------------------------------------------
    -- registers
    p_register : process ( R, C )
    begin
    
    
    
    
    end process p_registers;
    ----------------------------------------------




end architecture rtl;
--------------------------------------------------------------------------
