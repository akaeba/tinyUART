--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        tiny_uart_rx.vhd
-- @note        VHDL'93
--
-- @brief       RX
-- @details     uart treciever with single stage buffer register
--
-- @date        2018-07-26
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
-- RX path
entity tiny_uart_rx is
generic (
            CLKDIV  : positive              := 20;      --! builds baud rate
            DWIDTH  : positive              := 8;       --! data width
            ENAPAR  : boolean               := false;   --! parity check            true : enable;  false : disable
            EVENPAR : bit                   := '1';     --! selects parity mode;    '1' : Even Parity; '0' : Odd Parity
            STOPBIT : integer range 1 to 2  := 1;       --! number of stopbit
			NUMSYNC	: integer range 2 to 3	:= 2		--! number of sync stages at data input
        );
port    (
            -- Clock/Reset
            R       : in    std_logic;                          --! asnychon reset
            C       : in    std_logic;                          --! master clock
            -- Control
            DNEW    : out   std_logic;                          --! new data available, one clock cyle high
            BSY     : out   std_logic;                          --! shift register active
			FRMERO	: out	std_logic;							--! framing error
			PARERO	: out	std_logic;							--! parity error
            -- Data
            SI      : in    std_logic;                          --! serial data in
            DO      : out   std_logic_vector(DWIDTH-1 downto 0) --! Parallel data output
        );
end entity tiny_uart_rx;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of tiny_uart_rx is

    -----------------------------
    -- Signals
		signal si_sync		: std_logic_vector(NUMSYNC downto 0);	--! baud rate counter count, +1 for edge detection
		signal start_bit	: std_logic;							--! start bit detected





begin

    ----------------------------------------------
    -- shift forward register
    i_sync : entity work.tiny_uart_sfr
        generic map (
                        DWIDTH  => si_sync'length,	--! data width of shift register
                        RST_SFR => '1'       		--! reset value of shift register
                    )
        port map    (
                        R   => R,               --! asnychon reset
                        C   => C,               --! clock, rising edge
                        LD  => '0',             --! load parallel data input in shift register
                        EN  => '1',   			--! enable shift registers forward shift
                        SD  => to_01(SI),       --! serial data input, idle is one
                        SQ  => open,	        --! serial data output
                        D   => (others => '0'), --! parallel data input
                        Q   => si_sync          --! parallel data output
                    );
		-- glue
		start_bit	<=	si_sync(si_sync'left) and (not (si_sync(si_sync'left-1)));	--! detect falling edge
	----------------------------------------------






end architecture rtl;
--------------------------------------------------------------------------
