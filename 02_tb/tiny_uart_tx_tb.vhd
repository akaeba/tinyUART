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
			DO_ALL_TEST	: boolean	:= false		--! switch for enabling all tests
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
		
		-- Clock
		constant tclk	: time	:= 1 us;	--! 1MHz clock
		constant tskew	: time	:= 1 ns;	--! data skew
		
		-- Test
		constant do_test_0	: boolean := true;	--! test0: send single data word and check
		constant do_test_1	: boolean := false;	--! test0: send double data word and check
		
	-----------------------------
	
	
	-----------------------------
    -- Signals
		-- DUT
		signal R	: std_logic;
		signal C 	: std_logic;
		signal LD	: std_logic;
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
						LD  => LD,
						MTY => MTY,
						BSY => BSY,
						SO  => SO,
						DI  => DI
					);
	----------------------------------------------
	
	
    ----------------------------------------------
    -- registers
    p_stimuli_process : process
		-- tb help variables
			variable good	: boolean						:= true;
			variable buf	: std_logic_vector(9 downto 0)	:= (others => '0');
	
	begin
	
		-------------------------
		-- Init
		------------------------- 
			Report "Init...";
			R	<=	'1';
			LD	<=	'0';
			DI	<=	(others => '0');
			wait for 5*tclk;
			wait until rising_edge(C); wait for tskew;
			R	<=	'0';
			wait until rising_edge(C); wait for tskew;
			wait until rising_edge(C); wait for tskew;
		-------------------------
		
		
		-------------------------
		-- Test0: Send single data
		------------------------- 
		if ( DO_ALL_TEST or do_test_0 ) then
			Report "Test0: Send single data word";
			wait until rising_edge(C); wait for tskew;
			DI	<=	x"55";
			LD	<=	'1';
			wait until rising_edge(C); wait for tskew;
			DI	<=	(others => '0');
			LD	<=	'0';
			wait until rising_edge(C); wait for tskew;
			wait until rising_edge(C); wait for tskew;
			buf := (others => '0');
			wait for (CLKDIV/2)*tclk;
			for i in buf'high downto buf'low loop
				wait until rising_edge(C); wait for tskew;
				buf(i)	:= SO;				--! capture serial output
				wait for (CLKDIV)*tclk;
				assert ( MTY'STABLE(CLKDIV*tclk) and MTY = '1' ) report "  Empty flag not stable and/or active" severity warning;
				if not ( MTY'STABLE(CLKDIV*tclk) and MTY = '1' ) then good := false; end if;
				if ( i > 0 ) then
					assert ( BSY'STABLE(CLKDIV*tclk) and BSY = '1' ) report "  Busy flag not stable and/or not busy" severity warning;
					if not ( BSY'STABLE(CLKDIV*tclk) and BSY = '1' ) then good := false; end if;
				end if;
			end loop;
			assert ( buf(9) = '0' ) report "  Error: Startbit expected" severity warning;
			if not ( buf(9) = '0' ) then good := false; end if;
			assert ( buf(0) = '1' ) report "  Error: Stopbit expected" severity warning;
			if not ( buf(0) = '1' ) then good := false; end if;
			assert ( buf(8 downto 1) = x"55" ) report "  Error: Dataword expected 0x55" severity warning;
			if not ( buf(8 downto 1) = x"55" ) then good := false; end if;
		end if;
		-------------------------
		
		
		-------------------------
		-- Test0: Send single data
		------------------------- 
		if ( DO_ALL_TEST or do_test_1 ) then
			Report "Test1: Send double data word";
			wait until rising_edge(C); wait for tskew;
			wait until rising_edge(C); wait for tskew;
			-- fill in first data word
			DI	<=	x"47";
			LD	<=	'1';
			wait until rising_edge(C); wait for tskew;
			DI	<=	(others => '0');
			LD	<=	'0';
			wait until ( MTY = '1' );
			wait until rising_edge(C); wait for tskew;
			-- second data word
			DI	<=	x"11";
			LD	<=	'1';
			wait until rising_edge(C); wait for tskew;
			DI	<=	(others => '0');
			LD	<=	'0';
			wait until rising_edge(C); wait for tskew;
			-- wait for startbit
			wait until ( SO = '0' );
			wait for (CLKDIV/2)*tclk;
			-- record first data word and check
			for i in buf'high downto buf'low loop
				wait until rising_edge(C); wait for tskew;
				buf(i)	:= SO;				--! capture serial output
				wait for (CLKDIV)*tclk;
				assert ( MTY'STABLE(CLKDIV*tclk) and MTY = '0' ) report "  Empty flag not stable and/or not empty" severity warning;
				if not ( MTY'STABLE(CLKDIV*tclk) and MTY = '0' ) then good := false; end if;
				assert ( BSY'STABLE(CLKDIV*tclk) and BSY = '1' ) report "  Busy flag not stable and/or not busy" severity warning;
				if not ( BSY'STABLE(CLKDIV*tclk) and BSY = '1' ) then good := false; end if;
			end loop;
			assert ( buf(9) = '0' ) report "  Error: Startbit expected" severity warning;
			if not ( buf(9) = '0' ) then good := false; end if;
			assert ( buf(0) = '1' ) report "  Error: Stopbit expected" severity warning;
			if not ( buf(0) = '1' ) then good := false; end if;
			assert ( buf(8 downto 1) = x"47" ) report "  Error: Dataword expected 0x47" severity warning;
			if not ( buf(8 downto 1) = x"47" ) then good := false; end if;			
			
			
		end if;
		-------------------------
	
	
	
	
	
		-------------------------
		-- Report TB
		------------------------- 	
			Report "End TB...";		-- sim finished
			if (good) then
				Report "Test SUCCESSFULL";
			else
				Report "Test FAILED" severity error;
			end if;
			wait;                 	-- stop process continuous run
		-------------------------
	
	end process p_stimuli_process;
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
