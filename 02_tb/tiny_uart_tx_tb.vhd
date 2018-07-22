--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        tiny_uart_tx_tb.vhd
-- @note        VHDL'93
--
-- @brief       testbench
-- @details     
--
-- @date        2018-07-22
-- @version     0.1
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;
	use ieee.math_real.all;			--! for UNIFORM, TRUNC
library work;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- testbench
entity tiny_uart_tx_tb is
generic	(
			DO_ALL_TEST	: boolean	:= true		--! switch for enabling all tests
		);
end entity tiny_uart_tx_tb;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of tiny_uart_tx_tb is

	-----------------------------
    -- Constant		
		-- DUT
		constant CLKDIV		: positive				:= 1000;
		constant DWIDTH		: positive				:= 8;
		constant ENAPAR		: boolean				:= false;
		constant EVENPAR	: bit					:= '0';
		constant STOPBIT	: integer range 1 to 2	:= 1;
		
		-- Test
		constant tclk	: time	:= 1 us;	--! 1MHz clock
	-----------------------------
	
	
	-----------------------------
    -- Signals
		-- DUT
		signal R	: std_logic;
		signal C 	: std_logic;
		signal WR	: std_logic;
		signal MTY	: std_logic;
		signal BSY	: std_logic;
		signal SO	: std_logic;
		signal DI	: std_logic_vector(DWIDTH-1 downto 0);
	-----------------------------

begin

    ----------------------------------------------
    -- DUT
	DUT : entity work.tiny_uart_tx
		generic map	(
						CLKDIV  => CLKDIV,
						DWIDTH  => DWIDTH,
						ENAPAR  => ENAPAR,
						EVENPAR => EVENPAR,
						STOPBIT => STOPBIT
					)
		port map 	(
						R   => R,
						C   => C,
						WR  => WR,
						MTY => MTY,
						BSY => BSY,
						SO  => SO,
						DI  => DI
					);
	----------------------------------------------
	
	
	
	
	
	----------------------------------------------
    -- clock
    p_clk : process
		variable clk : std_logic := '0';
	begin
		while true loop
			C	<= clk;
			clk	:= not clk;
			wait for tclk/2;
			end loop;
	end process p_clk;
	----------------------------------------------	

end architecture sim;
--------------------------------------------------------------------------
