--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        tiny_uart_tb.vhd
-- @note        VHDL'93
--
-- @brief       testbench
-- @details
--
-- @date        2018-08-05
-- @version     0.1
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use ieee.math_real.all;         --! for UNIFORM, TRUNC
library work;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- testbench
entity tiny_uart_tb is
generic (
            DO_ALL_TEST : boolean   := false        --! switch for enabling all tests
        );
end entity tiny_uart_tb;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of tiny_uart_tb is

    -----------------------------
    -- Constant
        -- DUT
        constant DWIDTH     : integer range 4 to 8  := 8;
        constant CLK_HZ     : positive              := 50_000_000;
        constant BAUD_BPS   : positive              := 115200;
        constant STOPBIT    : integer range 1 to 2  := 1;
        constant RXSYNC     : integer range 2 to 3  := 2;
        constant DEBOUNCE   : integer range 1 to 3  := 1;

        -- Clock
        constant tclk   : time  := (1 sec) / CLK_HZ;    --! 1MHz clock
        constant tskew  : time  := 1 ns;                --! data skew

        -- Test
        constant loop_iter  : integer := 20;    --! number of test loop iteration
        constant do_test_0  : boolean := true;  --! test0: check debouncing logic
        constant do_test_1  : boolean := true;  --! test1: check RX Path
        constant do_test_2  : boolean := true;  --! test2: check TX Path
    -----------------------------


    -----------------------------
    -- Signals
        -- DUT
        signal R        : std_logic;
        signal C        : std_logic;
        signal TXD      : std_logic;
        signal RXD      : std_logic;
        signal FRMERO   : std_logic;
        signal RX       : std_logic_vector(DWIDTH-1 downto 0);
        signal RXCE     : std_logic;
        signal TX       : std_logic_vector(DWIDTH-1 downto 0);
        signal TXMTY    : std_logic;
        signal TXCE     : std_logic;
        signal BSY      : std_logic;
    -----------------------------

begin

    ----------------------------------------------
    -- DUT
    DUT : entity work.tiny_uart
        generic map (
                        DWIDTH   => DWIDTH,
                        CLK_HZ   => CLK_HZ,
                        BAUD_BPS => BAUD_BPS,
                        STOPBIT  => STOPBIT,
                        RXSYNC   => RXSYNC,
                        DEBOUNCE => DEBOUNCE
                    )
        port map    (
                        R      => R,
                        C      => C,
                        TXD    => TXD,
                        RXD    => RXD,
                        FRMERO => FRMERO,
                        RX     => RX,
                        RXCE   => RXCE,
                        TX     => TX,
                        TXMTY  => TXMTY,
                        TXCE   => TXCE,
                        BSY    => BSY
                    );
    ----------------------------------------------


    ----------------------------------------------
    -- registers
    p_stimuli_process : process
        -- tb help variables
            variable good   : boolean                       := true;
            variable buf    : std_logic_vector(9 downto 0)  := (others => '0');
            variable tmp    : std_logic_vector(7 downto 0)  := (others => '0');
        -- variables for random number generator
            variable seed1, seed2   : positive;
            variable rand           : real;

    begin

        -------------------------
        -- Init
        -------------------------
            Report "Init...";
            R       <=  '1';
            RXD     <=  '1';
            TX      <=  (others => '0');
            TXCE    <=  '0';
            wait for 5*tclk;
            wait until rising_edge(C); wait for tskew;
            R       <=  '0';
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
        -------------------------


        -------------------------
        -- Test0: Check Debouncing Mimic
        -------------------------
        if ( DO_ALL_TEST or do_test_0 ) then
            Report "Test0: Check Debouncing Mimic";
            wait until rising_edge(C); wait for tskew;
            for i in 0 to loop_iter - 1 loop
                RXD <=  '0';                                --! one zero
                wait until rising_edge(C); wait for tskew;
                RXD <=  '1';                                --! two once
                wait until rising_edge(C); wait for tskew;
                wait until rising_edge(C); wait for tskew;
            end loop;
            assert ( BSY = '0' ) report "  Error: Debouncer not work" severity warning;
            if not ( BSY = '0' ) then good := false; end if;
        end if;
        -------------------------


        -------------------------
        -- Test1: Check RX Path
        -------------------------
        if ( DO_ALL_TEST or do_test_1 ) then
            Report "Test1: Check RX-Path";
            wait until rising_edge(C); wait for tskew;
            seed1 := abs(now / 1.0 ps);		--! get RNG offset from simulation time
			UNIFORM(seed1, seed2, rand);    --! dummy read, otherwise first rand is zero
            for j in 0 to loop_iter-1 loop
                UNIFORM(seed1, seed2, rand);    --! random number
                tmp :=  std_logic_vector(to_unsigned(integer(round(rand*(2.0**tmp'length-1.0))), tmp'length));
                buf :=  '1' & tmp & '0';  --! reverse order cause in UART is LSB send as first
                wait until rising_edge(C); wait for tskew;
                for i in buf'low to buf'high loop
                    RXD  <= buf(i);
                    wait for integer(round(1.0/real(BAUD_BPS)*1.0e12))*1 ps;
                end loop;
                assert ( RX = tmp ) report "  Error: loop=" & integer'image(j) & "; isVal and expVal are unequal" severity warning;
                if not ( RX = tmp ) then good := false; end if;
                assert ( FRMERO = '0' ) report "  Error: Framing" severity warning;
                if not ( FRMERO = '0' ) then good := false; end if;
            end loop;
        end if;
        -------------------------


        -------------------------
        -- Test1: Check TX Path
        -------------------------
        if ( DO_ALL_TEST or do_test_2 ) then
            Report "Test2: Check TX-Path";
            wait until rising_edge(C); wait for tskew;
            seed1 := abs(now / 1.0 ps);		--! get RNG offset from simulation time	
			UNIFORM(seed1, seed2, rand);    --! dummy read, otherwise first rand is zero
			for j in 0 to loop_iter-1 loop
				UNIFORM(seed1, seed2, rand);    --! random number
				tmp 	:=  std_logic_vector(to_unsigned(integer(round(rand*(2.0**tmp'length-1.0))), tmp'length));
				TX		<=	tmp;
				TXCE	<=	'1';
				wait until rising_edge(C); wait for tskew;
				TX		<=	(others => 'X');
				TXCE	<=	'0';
				wait until falling_edge(TXD);
				for i in buf'low to buf'high loop
					wait for integer(round(1.0/(2.0*real(BAUD_BPS))*1.0e12))*1 ps;	--! wait half bit clock, to sample in the middle
					buf(i)	:= TXD;													--! capture
					wait for integer(round(1.0/(2.0*real(BAUD_BPS))*1.0e12))*1 ps;	--! wait half bit clock
				end loop;
				assert ( buf(buf'high-1 downto buf'low+1) = tmp ) report "  Error: loop=" & integer'image(j) & "; isVal and expVal are unequal" severity warning;
				if not ( buf(buf'high-1 downto buf'low+1) = tmp ) then good := false; end if;
				assert ( buf(buf'high) = '1' ) report "  Error: loop=" & integer'image(j) & "; Stop bit" severity warning;
				if not ( buf(buf'high) = '1' ) then good := false; end if;
				assert ( buf(buf'low) = '0' ) report "  Error: loop=" & integer'image(j) & "; Start bit" severity warning;
				if not ( buf(buf'low) = '0' ) then good := false; end if;
			end loop;
		end if;
		-------------------------


        -------------------------
        -- Report TB
        -------------------------
            Report "End TB...";     -- sim finished
            if (good) then
                Report "Test SUCCESSFULL";
            else
                Report "Test FAILED" severity error;
            end if;
            wait;                   -- stop process continuous run
        -------------------------

    end process p_stimuli_process;
    ----------------------------------------------


    ----------------------------------------------
    -- clock
    p_clk : process
        variable clk : std_logic := '0';
    begin
        while true loop
            C   <= clk;
            clk := not clk;
            wait for tclk/2;
            end loop;
    end process p_clk;
    ----------------------------------------------

end architecture sim;
--------------------------------------------------------------------------
