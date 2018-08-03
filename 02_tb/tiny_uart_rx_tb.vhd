--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        tiny_uart_rx_tb.vhd
-- @note        VHDL'93
--
-- @brief       testbench
-- @details
--
-- @date        2018-07-29
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
entity tiny_uart_rx_tb is
generic (
            DO_ALL_TEST : boolean   := false        --! switch for enabling all tests
        );
end entity tiny_uart_rx_tb;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of tiny_uart_rx_tb is

    -----------------------------
    -- Constant
        -- DUT
        constant CLKDIV     : positive              := 1000;
        constant DWIDTH     : positive              := 8;
        constant STOPBIT    : integer range 1 to 2  := 1;
        constant NUMSYNC    : integer range 2 to 3  := 2;

        -- Clock
        constant tclk   : time  := 1 us;    --! 1MHz clock
        constant tskew  : time  := 1 ns;    --! data skew

        -- Test
        constant loop_iter  : integer := 20;    --! number of test loop iteration
        constant do_test_0  : boolean := true;  --! test0: recieve single data word
        constant do_test_1  : boolean := true;  --! test1: recieve multiple random data words
        constant do_test_2  : boolean := true;  --! test2: provoke an framing error
    -----------------------------


    -----------------------------
    -- Signals
        -- DUT
        signal R        : std_logic;
        signal C        : std_logic;
        signal DNEW     : std_logic;
        signal BSY      : std_logic;
        signal FRMERO   : std_logic;
        signal SI       : std_logic;
        signal DO       : std_logic_vector(DWIDTH-1 downto 0);
    -----------------------------

begin

    ----------------------------------------------
    -- DUT
    DUT : entity work.tiny_uart_rx
        generic map (
                        CLKDIV  => CLKDIV,
                        DWIDTH  => DWIDTH,
                        STOPBIT => STOPBIT,
                        NUMSYNC => NUMSYNC
                    )
        port map    (
                        R       => R,
                        C       => C,
                        DNEW    => DNEW,
                        BSY     => BSY,
                        FRMERO  => FRMERO,
                        SI      => SI,
                        DO      => DO
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
            R   <=  '1';
            SI  <=  '1';
            wait for 5*tclk;
            wait until rising_edge(C); wait for tskew;
            R   <=  '0';
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
        -------------------------


        -------------------------
        -- Test0: Recieve Single data word
        -------------------------
        if ( DO_ALL_TEST or do_test_0 ) then
            Report "Test0: Recieve Single data word";
            buf :=  '0' & x"55" & '1';  --! start, data, stop bits
            wait until rising_edge(C); wait for tskew;
            for i in buf'high downto buf'low loop
                wait until rising_edge(C); wait for tskew;
                SI  <= buf(i);
                if ( i > 0 ) then           --! last bit no wait to allow waiting on data new edge
                    wait for CLKDIV*tclk;
                end if;
            end loop;
            wait until rising_edge(DNEW);
            assert ( DO = x"55" ) report "  Error: Dataword expected 0x55" severity warning;
            if not ( DO = x"55" ) then good := false; end if;
            assert ( FRMERO = '0' ) report "  Error: Framing" severity warning;
            if not ( FRMERO = '0' ) then good := false; end if;
            while ( BSY = '1' ) loop    -- wait for idle
                wait until rising_edge(C); wait for tskew;
            end loop;
        end if;
        -------------------------


        -------------------------
        -- Test1: Recieve multiple words
        -------------------------
        if ( DO_ALL_TEST or do_test_1 ) then
            Report "Test1: Recieve multiple words";
            wait until rising_edge(C); wait for tskew;
            UNIFORM(seed1, seed2, rand);    --! dummy read, otherwise first rand is zero
            for j in 0 to loop_iter-1 loop
                UNIFORM(seed1, seed2, rand);    --! random number
                tmp :=  std_logic_vector(to_unsigned(integer(round(rand*(2.0**tmp'length-1.0))), tmp'length));
                buf :=  '0' & tmp & '1';  --! start, data, stop bits
                wait until rising_edge(C); wait for tskew;
                for i in buf'high downto buf'low loop
                    wait until rising_edge(C); wait for tskew;
                    SI  <= buf(i);
                    if ( i > 0 ) then           --! last bit no wait to allow waiting on data new edge
                        wait for CLKDIV*tclk;
                    end if;
                end loop;
                wait until rising_edge(DNEW);
                assert ( DO = tmp ) report "  Error: loop=" & integer'image(j) & "; Dataword exp. unequal is" severity warning;
                if not ( DO = tmp ) then good := false; end if;
                assert ( FRMERO = '0' ) report "  Error: Framing" severity warning;
                if not ( FRMERO = '0' ) then good := false; end if;
                while ( BSY = '1' ) loop    -- wait for idle
                    wait until rising_edge(C); wait for tskew;
                end loop;
            end loop;
        end if;
        -------------------------


        -------------------------
        -- Test1: Framing Error
        -------------------------
        if ( DO_ALL_TEST or do_test_2 ) then
            Report "Test2: Framing Error";
            -- buad rate to slow
            Report "         Baud rate to fast";
            wait until rising_edge(C); wait for tskew;
            buf :=  '0' & x"00" & '1';  --! start, data, stop bits
            for i in buf'high downto buf'low loop
                wait until rising_edge(C); wait for tskew;
                SI  <= buf(i);
                if ( FRMERO = '1' ) then        --! exit bit send loop if error found
                    SI  <= '1';                 --! change to lines idle level
                    exit;
                end if;
                if ( i > 0 ) then               --! last bit no wait to allow waiting on data new edge
                    wait for CLKDIV*10*tclk;    --! multiply by 10 to provoke a faster baud rate
                end if;
            end loop;
            while ( BSY = '1' ) loop    -- wait for idle
                wait until rising_edge(C); wait for tskew;
            end loop;
            assert ( FRMERO = '1' ) report "  Error: Framing error expected" severity warning;
            if not ( FRMERO = '1' ) then good := false; end if;
            -- recieve succesfull to clear error bit
            wait until rising_edge(C); wait for tskew;
            buf :=  '0' & x"00" & '1';  --! start, data, stop bits
            for i in buf'high downto buf'low loop
                wait until rising_edge(C); wait for tskew;
                SI  <= buf(i);
                if ( i > 0 ) then               --! last bit no wait to allow waiting on data new edge
                    wait for CLKDIV*tclk;   --! multiply by 10 to provoke a faster baud rate
                end if;
            end loop;
            while ( BSY = '1' ) loop    -- wait for idle
                wait until rising_edge(C); wait for tskew;
            end loop;
            -- baud rate to fast
            Report "         Baud rate to slow";
            buf :=  '0' & x"00" & '1';  --! start, data, stop bits
            while ( FRMERO = '0' ) loop --! run in a loop to sample '0' at stop bit position => framming error
                for i in buf'high downto buf'low loop
                    wait until rising_edge(C); wait for tskew;
                    SI  <= buf(i);
                    if ( FRMERO = '1' ) then        --! exit bit send loop if error found
                        SI  <= '1';                 --! change to lines idle level
                        exit;
                    end if;
                    if ( i > 0 ) then               --! last bit no wait to allow waiting on data new edge
                        wait for CLKDIV/10*tclk;    --! divide by 10 to provoke a slower baud rate
                    end if;
                end loop;
            end loop;
            while ( BSY = '1' ) loop    -- wait for idle
                wait until rising_edge(C); wait for tskew;
            end loop;
            assert ( FRMERO = '1' ) report "  Error: Framing error expected" severity warning;
            if not ( FRMERO = '1' ) then good := false; end if;
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
