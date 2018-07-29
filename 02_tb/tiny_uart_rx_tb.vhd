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
        constant do_test_0  : boolean := true;  --! test0: send single data word and check
        constant do_test_1  : boolean := true;  --! test1: send double data word and check
        constant do_test_2  : boolean := true;  --! test2: random number test
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
        -- Test0: Send single data
        -------------------------
        if ( DO_ALL_TEST or do_test_0 ) then
            Report "Test0: Recieve Single data word";
            buf :=  '0' & x"55" & '1';  --! start, data, stop bits
            wait until rising_edge(C); wait for tskew;
            for i in buf'high downto buf'low loop
                wait until rising_edge(C); wait for tskew;
                SI  <= buf(i);
                wait for CLKDIV*tclk;
            end loop;
            while ( BSY = '1' ) loop    -- wait for idle
                wait until rising_edge(C); wait for tskew;
            end loop;
            assert ( buf(8 downto 1) = x"55" ) report "  Error: Dataword expected 0x55" severity warning;
            if not ( buf(8 downto 1) = x"55" ) then good := false; end if;
            assert ( FRMERO = '0' ) report "  Error: Framing" severity warning;
            if not ( FRMERO = '0' ) then good := false; end if;
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
