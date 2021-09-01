--************************************************************************
-- @author:         Andreas Kaeberlein
-- @copyright:      Copyright 2021
-- @credits:        AKAE
--
-- @license:        BSDv3
-- @maintainer:     Andreas Kaeberlein
-- @email:          andreas.kaeberlein@web.de
--
-- @note:           VHDL'93
-- @file:           tiny_uart_baud_bit_gen_tb.vhd
-- @date:           2021-05-25
--
-- @see:            https://github.com/akaeba/tinyUART
-- @brief:          testbench
--
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
library work;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- testbench
entity tiny_uart_baud_bit_gen_tb is
generic (
            DO_ALL_TEST : boolean   := false        --! switch for enabling all tests
        );
end entity tiny_uart_baud_bit_gen_tb;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of tiny_uart_baud_bit_gen_tb is


    -----------------------------
    -- Constant
        -- DUT
        constant NUMBIT         : positive  := 3;
        constant CLKDIV2        : positive  := 4;
        constant SKIP_LAST_BIT2 : boolean   := false;

        -- Clock
        constant tclk   : time  := 1 us;        --! 1MHz clock
        constant tskew  : time  := tclk / 50;   --! data skew

        -- Test
        constant loop_iter  : integer := 20;    --! number of test loop iteration
        constant do_test_0  : boolean := true;  --! test0: receive single data word
    -----------------------------


    -----------------------------
    -- Signal
        -- DUT
        signal R            : std_logic;
        signal C            : std_logic;
        signal START        : std_logic;
        signal BUSY         : std_logic;
        signal SFR_LD       : std_logic;
        signal SFR_S_BEGIN  : std_logic;
        signal SFR_S_MIDLE  : std_logic;
        signal SFR_CAP      : std_logic;
        -- TB
        signal CLKENA   : std_logic := '1';     --! clock gating
    -----------------------------

begin

    ----------------------------------------------
    -- DUT
    DUT : entity work.tiny_uart_baud_bit_gen
        generic map (
                        NUMBIT          => NUMBIT,
                        CLKDIV2         => CLKDIV2,
                        SKIP_LAST_BIT2  => SKIP_LAST_BIT2
                    )
        port map    (
                        R           => R,
                        C           => C,
                        START       => START,
                        BUSY        => BUSY,
                        SFR_LD      => SFR_LD,
                        SFR_S_BEGIN => SFR_S_BEGIN,
                        SFR_S_MIDLE => SFR_S_MIDLE,
                        SFR_CAP     => SFR_CAP
                    );
    ----------------------------------------------


    ----------------------------------------------
    -- stimuli
    p_stimuli_process : process
        -- tb help variables
        variable good   : boolean   := true;

    begin

        -------------------------
        -- Init
        -------------------------
            Report "Init...";
            R       <=  '1';
            START   <=  '0';
            wait for 5*tclk;
            wait until rising_edge(C); wait for tskew;
            R       <=  '0';
            wait until rising_edge(C); wait for tskew;
        -------------------------


        -------------------------
        -- Test0: Single shoot
        -------------------------
        if ( DO_ALL_TEST or do_test_0 ) then
            Report "Test0: Single shoot";
            wait until rising_edge(C); wait for tskew;
            START   <=  '1';
            wait until rising_edge(C); wait for tskew;
            START   <=  '0';
            --
            assert ( '1' = SFR_LD ) report "  Error: Failed Load TX SFR" severity warning;
            if not ( '1' = SFR_LD ) then good := false; end if;
            assert ( '1' = SFR_S_BEGIN ) report "  Error: Failed Shift TX SFR" severity warning;
            if not ( '1' = SFR_S_BEGIN ) then good := false; end if;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            assert ( '0' = SFR_S_BEGIN ) report "  Error: Failed Shift TX SFR" severity warning;
            if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
            assert ( '1' = SFR_S_MIDLE ) report "  Error: Failed Shift RX SFR" severity warning;
            if not ( '1' = SFR_S_MIDLE ) then good := false; end if;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            --
            assert ( '1' = SFR_S_BEGIN ) report "  Error: Failed Shift TX SFR" severity warning;
            if not ( '1' = SFR_S_BEGIN ) then good := false; end if;
            assert ( '0' = SFR_S_MIDLE ) report "  Error: Failed Shift RX SFR" severity warning;
            if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            assert ( '0' = SFR_S_BEGIN ) report "  Error: Failed Shift TX SFR" severity warning;
            if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
            assert ( '1' = SFR_S_MIDLE ) report "  Error: Failed Shift RX SFR" severity warning;
            if not ( '1' = SFR_S_MIDLE ) then good := false; end if;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            --
            assert ( '1' = SFR_S_BEGIN ) report "  Error: Failed Shift TX SFR" severity warning;
            if not ( '1' = SFR_S_BEGIN ) then good := false; end if;
            assert ( '0' = SFR_S_MIDLE ) report "  Error: Failed Shift RX SFR" severity warning;
            if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            assert ( '0' = SFR_S_BEGIN ) report "  Error: Failed Shift TX SFR" severity warning;
            if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
            assert ( '1' = SFR_S_MIDLE ) report "  Error: Failed Shift RX SFR" severity warning;
            if not ( '1' = SFR_S_MIDLE ) then good := false; end if;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
            --
            assert ( '0' = SFR_S_BEGIN ) report "  Error: Failed Shift TX SFR" severity warning;
            if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
            assert ( '0' = SFR_S_MIDLE ) report "  Error: Failed Shift RX SFR" severity warning;
            if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
            --
            assert ( BUSY'stable((2*CLKDIV2-1)*tclk) ) report "  Error: Busy unexpected toggled" severity warning;
            if not ( BUSY'stable((2*CLKDIV2-1)*tclk) ) then good := false; end if;
            assert ( '1' = BUSY ) report "  Error: Needs to be busy" severity warning;
            if not ( '1' = BUSY ) then good := false; end if;
            while ( '1' = BUSY ) loop
                wait until rising_edge(C); wait for tskew;
            end loop;
        end if;
        -------------------------


        -------------------------
        -- Report TB
        -------------------------
            Report "End TB...";     -- sim finished
            if (good) then
                Report "Test SUCCESSFUL";
            else
                Report "Test FAILED" severity failure;
            end if;
            wait until falling_edge(C); wait for tskew;
            CLKENA <= '0';
            wait;                   -- stop process continuous run
        -------------------------

    end process p_stimuli_process;
    ----------------------------------------------


    ----------------------------------------------
    -- clock
    p_clk : process
        variable v_clk : std_logic := '0';
    begin
        while ( '1' = CLKENA ) loop
            C       <= v_clk;
            v_clk   := not v_clk;
            wait for tclk/2;
        end loop;
        wait;
    end process p_clk;
    ----------------------------------------------

end architecture sim;
--------------------------------------------------------------------------
