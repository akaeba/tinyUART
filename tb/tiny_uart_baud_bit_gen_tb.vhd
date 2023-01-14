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
            DO_ALL_TEST : boolean   := false;   --! switch for enabling all tests
            CLKENA_DIV  : positive  := 1        --! every clock cycles is the clock enabled
        );
end entity tiny_uart_baud_bit_gen_tb;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of tiny_uart_baud_bit_gen_tb is

    ----------------------------------------------
    -- Constant
    ----------------------------------------------
        -- DUT
        constant NUMBIT         : positive  := 3;
        constant CLKDIV2        : positive  := 4;       --! every number of clocks next action
        constant SKIP_LAST_BIT2 : boolean   := false;

        -- Clock
        constant tclk   : time  := 1 us;        --! 1MHz clock
        constant tHold  : time  := tclk / 50;   --! data skew

        -- Test
        constant loop_iter  : integer := 20;    --! number of test loop iteration
        constant do_test_0  : boolean := true;  --! test0: receive single data word

        -- Help
        constant tHalfBit   : time := (CLKDIV2)*(CLKENA_DIV)*tclk;  --! duration of a half bit
    ----------------------------------------------


    ----------------------------------------------
    -- Signal
    ----------------------------------------------
        -- DUT
        signal R            : std_logic;
        signal C            : std_logic;
        signal CENA         : std_logic;
        signal START        : std_logic;
        signal BUSY         : std_logic;
        signal SFR_LD       : std_logic;
        signal SFR_S_BEGIN  : std_logic;
        signal SFR_S_MIDLE  : std_logic;
        signal SFR_CAP      : std_logic;
        -- TB
        signal CLKENA   : std_logic := '1';     --! clock gating
    ----------------------------------------------

begin

    ----------------------------------------------
    -- TB Parameter
    assert not true
    report                                              character(LF) &
        "tiny_uart_baud_bit_gen_tb configuration:"    & character(LF) &
        "  CLKENA_DIV : " & integer'image(CLKENA_DIV) & character(LF) &
        "  NUMBIT     : " & integer'image(NUMBIT)     & character(LF) &
        "  CLKDIV2    : " & integer'image(CLKDIV2)    & character(LF) &
        "  TCLK       : " & time'image(tclk)          & character(LF) &
        "  THALFBIT   : " & time'image(tHalfBit)
    severity note;
    ----------------------------------------------


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
                        CENA        => CENA,
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
            wait until rising_edge(C); wait for tHold;
            R       <=  '0';
            wait until rising_edge(C); wait for tHold;
        -------------------------


        -------------------------
        -- Test0: Single shoot
        -------------------------
        if ( DO_ALL_TEST or do_test_0 ) then
            Report "Test0: Single shoot";
            wait until rising_edge(C); wait for tHold;
            -- start transfer
            START   <=  '1';
            wait until rising_edge(C); wait for tHold;
            START   <=  '0';
            -- sync with core
            while ( '0' = BUSY ) loop
                wait until rising_edge(C); wait for tHold;
            end loop;
            while ( '0' = CENA ) loop
                wait until rising_edge(C); wait for tHold;
            end loop;
            --
            -- first bit
            --   first half bit period, clock cycle 0
            Report "  Info:Bit" & integer'image(NUMBIT-1) & ": First half bit period, clock cycle 0" ;
            assert ( '1' = SFR_LD ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_LD" severity warning;
            if not ( '1' = SFR_LD ) then good := false; end if;
            assert ( '1' = SFR_S_BEGIN ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_S_BEGIN" severity warning;
            if not ( '1' = SFR_S_BEGIN ) then good := false; end if;
            assert ( '0' = SFR_S_MIDLE ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_S_MIDLE" severity warning;
            if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
            assert ( '0' = SFR_CAP ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_CAP" severity warning;
            if not ( '0' = SFR_CAP ) then good := false; end if;
            wait until rising_edge(C);
            assert ( SFR_LD'stable(tclk-tHold) ) report "  Error: SFR_LD unexpected toggled" severity warning;
            if not ( SFR_LD'stable(tclk-tHold) ) then good := false; end if;
            assert ( SFR_S_BEGIN'stable(tclk-tHold) ) report "  Error: SFR_S_BEGIN unexpected toggled" severity warning;
            if not ( SFR_S_BEGIN'stable(tclk-tHold) ) then good := false; end if;
            assert ( SFR_S_MIDLE'stable(tclk-tHold) ) report "  Error: SFR_S_MIDLE unexpected toggled" severity warning;
            if not ( SFR_S_MIDLE'stable(tclk-tHold) ) then good := false; end if;
            assert ( SFR_CAP'stable(tclk-tHold) ) report "  Error: SFR_CAP unexpected toggled" severity warning;
            if not ( SFR_CAP'stable(tclk-tHold) ) then good := false; end if;
            --   first half bit period, clock cycle 1..n
            wait for tHalfBit - tclk;
            Report "  Info:Bit" & integer'image(NUMBIT-1) & ": First half bit period, clock cycle 1..n" ;
            wait until rising_edge(C);
            assert ( '0' = SFR_LD ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_LD" severity warning;
            if not ( '0' = SFR_LD ) then good := false; end if;
            assert ( '0' = SFR_S_BEGIN ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_S_BEGIN" severity warning;
            if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
            assert ( '0' = SFR_S_MIDLE ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_S_MIDLE" severity warning;
            if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
            assert ( '0' = SFR_CAP ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_CAP" severity warning;
            if not ( '0' = SFR_CAP ) then good := false; end if;
            assert ( SFR_LD'stable(tHalfBit-tclk) ) report "  Error: SFR_LD unexpected toggled" severity warning;
            if not ( SFR_LD'stable(tHalfBit-tclk) ) then good := false; end if;
            assert ( SFR_S_BEGIN'stable(tHalfBit-tclk) ) report "  Error: SFR_S_BEGIN unexpected toggled" severity warning;
            if not ( SFR_S_BEGIN'stable(tHalfBit-tclk) ) then good := false; end if;
            assert ( SFR_S_MIDLE'stable(tHalfBit-tclk) ) report "  Error: SFR_S_MIDLE unexpected toggled" severity warning;
            if not ( SFR_S_MIDLE'stable(tHalfBit-tclk) ) then good := false; end if;
            assert ( SFR_CAP'stable(tHalfBit-tclk) ) report "  Error: SFR_CAP unexpected toggled" severity warning;
            if not ( SFR_CAP'stable(tHalfBit-tclk) ) then good := false; end if;
            --   second half bit period, clock cycle 0
            wait until rising_edge(C);
            Report "  Info:Bit" & integer'image(NUMBIT-1) & ": Second half bit period, clock cycle 0" ;
            assert ( '0' = SFR_LD ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_LD" severity warning;
            if not ( '0' = SFR_LD ) then good := false; end if;
            assert ( '0' = SFR_S_BEGIN ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_S_BEGIN" severity warning;
            if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
            assert ( '1' = SFR_S_MIDLE ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_S_MIDLE" severity warning;
            if not ( '1' = SFR_S_MIDLE ) then good := false; end if;
            assert ( '0' = SFR_CAP ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_CAP" severity warning;
            if not ( '0' = SFR_CAP ) then good := false; end if;
            assert ( SFR_LD'stable(tclk-tHold) ) report "  Error: SFR_LD unexpected toggled" severity warning;
            if not ( SFR_LD'stable(tclk-tHold) ) then good := false; end if;
            assert ( SFR_S_BEGIN'stable(tclk-tHold) ) report "  Error: SFR_S_BEGIN unexpected toggled" severity warning;
            if not ( SFR_S_BEGIN'stable(tclk-tHold) ) then good := false; end if;
            assert ( SFR_S_MIDLE'stable(tclk-tHold) ) report "  Error: SFR_S_MIDLE unexpected toggled" severity warning;
            if not ( SFR_S_MIDLE'stable(tclk-tHold) ) then good := false; end if;
            assert ( SFR_CAP'stable(tclk-tHold) ) report "  Error: SFR_CAP unexpected toggled" severity warning;
            if not ( SFR_CAP'stable(tclk-tHold) ) then good := false; end if;
            --   second half bit period, clock cycle 1..n
            wait for tHalfBit - tclk;
            Report "  Info:Bit" & integer'image(NUMBIT-1) & ": Second half bit period, clock cycle 1..n" ;
            assert ( '0' = SFR_LD ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_LD" severity warning;
            if not ( '0' = SFR_LD ) then good := false; end if;
            assert ( '0' = SFR_S_BEGIN ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_S_BEGIN" severity warning;
            if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
            assert ( '0' = SFR_S_MIDLE ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_S_MIDLE" severity warning;
            if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
            assert ( '0' = SFR_CAP ) report "  Error:Bit" & integer'image(NUMBIT-1) & ": SFR_CAP" severity warning;
            if not ( '0' = SFR_CAP ) then good := false; end if;
            assert ( SFR_LD'stable(tHalfBit-tclk) ) report "  Error: SFR_LD unexpected toggled" severity warning;
            if not ( SFR_LD'stable(tHalfBit-tclk) ) then good := false; end if;
            assert ( SFR_S_BEGIN'stable(tHalfBit-tclk) ) report "  Error: SFR_S_BEGIN unexpected toggled" severity warning;
            if not ( SFR_S_BEGIN'stable(tHalfBit-tclk) ) then good := false; end if;
            assert ( SFR_S_MIDLE'stable(tHalfBit-tclk) ) report "  Error: SFR_S_MIDLE unexpected toggled" severity warning;
            if not ( SFR_S_MIDLE'stable(tHalfBit-tclk) ) then good := false; end if;
            assert ( SFR_CAP'stable(tHalfBit-tclk) ) report "  Error: SFR_CAP unexpected toggled" severity warning;
            if not ( SFR_CAP'stable(tHalfBit-tclk) ) then good := false; end if;
            wait until rising_edge(C); wait for tHold;
            --
            -- middle bits,
            --   first half bit period, clock cycle 0
            for i in 1 to NUMBIT-2 loop
                Report "  Info:Bit" & integer'image(NUMBIT-1-i) & ": First half bit period, clock cycle 0" ;
                assert ( '0' = SFR_LD ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_LD" severity warning;
                if not ( '0' = SFR_LD ) then good := false; end if;
                assert ( '1' = SFR_S_BEGIN ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_S_BEGIN" severity warning;
                if not ( '1' = SFR_S_BEGIN ) then good := false; end if;
                assert ( '0' = SFR_S_MIDLE ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_S_MIDLE" severity warning;
                if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
                assert ( '0' = SFR_CAP ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_CAP" severity warning;
                if not ( '0' = SFR_CAP ) then good := false; end if;
                wait until rising_edge(C);
                assert ( SFR_LD'stable(tclk-tHold) ) report "  Error: SFR_LD unexpected toggled" severity warning;
                if not ( SFR_LD'stable(tclk-tHold) ) then good := false; end if;
                assert ( SFR_S_BEGIN'stable(tclk-tHold) ) report "  Error: SFR_S_BEGIN unexpected toggled" severity warning;
                if not ( SFR_S_BEGIN'stable(tclk-tHold) ) then good := false; end if;
                assert ( SFR_S_MIDLE'stable(tclk-tHold) ) report "  Error: SFR_S_MIDLE unexpected toggled" severity warning;
                if not ( SFR_S_MIDLE'stable(tclk-tHold) ) then good := false; end if;
                assert ( SFR_CAP'stable(tclk-tHold) ) report "  Error: SFR_CAP unexpected toggled" severity warning;
                if not ( SFR_CAP'stable(tclk-tHold) ) then good := false; end if;
                --   first half bit period, clock cycle 1..n
                wait for tHalfBit - tclk;
                Report "  Info:Bit" & integer'image(NUMBIT-1-i) & ": First half bit period, clock cycle 1..n" ;
                wait until rising_edge(C);
                assert ( '0' = SFR_LD ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_LD" severity warning;
                if not ( '0' = SFR_LD ) then good := false; end if;
                assert ( '0' = SFR_S_BEGIN ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_S_BEGIN" severity warning;
                if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
                assert ( '0' = SFR_S_MIDLE ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_S_MIDLE" severity warning;
                if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
                assert ( '0' = SFR_CAP ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_CAP" severity warning;
                if not ( '0' = SFR_CAP ) then good := false; end if;
                assert ( SFR_LD'stable(tHalfBit-tclk) ) report "  Error: SFR_LD unexpected toggled" severity warning;
                if not ( SFR_LD'stable(tHalfBit-tclk) ) then good := false; end if;
                assert ( SFR_S_BEGIN'stable(tHalfBit-tclk) ) report "  Error: SFR_S_BEGIN unexpected toggled" severity warning;
                if not ( SFR_S_BEGIN'stable(tHalfBit-tclk) ) then good := false; end if;
                assert ( SFR_S_MIDLE'stable(tHalfBit-tclk) ) report "  Error: SFR_S_MIDLE unexpected toggled" severity warning;
                if not ( SFR_S_MIDLE'stable(tHalfBit-tclk) ) then good := false; end if;
                assert ( SFR_CAP'stable(tHalfBit-tclk) ) report "  Error: SFR_CAP unexpected toggled" severity warning;
                if not ( SFR_CAP'stable(tHalfBit-tclk) ) then good := false; end if;
                --   second half bit period, clock cycle 0
                wait until rising_edge(C);
                Report "  Info:Bit" & integer'image(NUMBIT-1-i) & ": Second half bit period, clock cycle 0" ;
                assert ( '0' = SFR_LD ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_LD" severity warning;
                if not ( '0' = SFR_LD ) then good := false; end if;
                assert ( '0' = SFR_S_BEGIN ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_S_BEGIN" severity warning;
                if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
                assert ( '1' = SFR_S_MIDLE ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_S_MIDLE" severity warning;
                if not ( '1' = SFR_S_MIDLE ) then good := false; end if;
                assert ( '0' = SFR_CAP ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_CAP" severity warning;
                if not ( '0' = SFR_CAP ) then good := false; end if;
                assert ( SFR_LD'stable(tclk-tHold) ) report "  Error: SFR_LD unexpected toggled" severity warning;
                if not ( SFR_LD'stable(tclk-tHold) ) then good := false; end if;
                assert ( SFR_S_BEGIN'stable(tclk-tHold) ) report "  Error: SFR_S_BEGIN unexpected toggled" severity warning;
                if not ( SFR_S_BEGIN'stable(tclk-tHold) ) then good := false; end if;
                assert ( SFR_S_MIDLE'stable(tclk-tHold) ) report "  Error: SFR_S_MIDLE unexpected toggled" severity warning;
                if not ( SFR_S_MIDLE'stable(tclk-tHold) ) then good := false; end if;
                assert ( SFR_CAP'stable(tclk-tHold) ) report "  Error: SFR_CAP unexpected toggled" severity warning;
                if not ( SFR_CAP'stable(tclk-tHold) ) then good := false; end if;
                --   second half bit period, clock cycle 1..n
                wait for tHalfBit - tclk;
                Report "  Info:Bit" & integer'image(NUMBIT-1-i) & ": Second half bit period, clock cycle 1..n" ;
                assert ( '0' = SFR_LD ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_LD" severity warning;
                if not ( '0' = SFR_LD ) then good := false; end if;
                assert ( '0' = SFR_S_BEGIN ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_S_BEGIN" severity warning;
                if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
                assert ( '0' = SFR_S_MIDLE ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_S_MIDLE" severity warning;
                if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
                assert ( '0' = SFR_CAP ) report "  Error:Bit" & integer'image(NUMBIT-1-i) & ": SFR_CAP" severity warning;
                if not ( '0' = SFR_CAP ) then good := false; end if;
                assert ( SFR_LD'stable(tHalfBit-tclk) ) report "  Error: SFR_LD unexpected toggled" severity warning;
                if not ( SFR_LD'stable(tHalfBit-tclk) ) then good := false; end if;
                assert ( SFR_S_BEGIN'stable(tHalfBit-tclk) ) report "  Error: SFR_S_BEGIN unexpected toggled" severity warning;
                if not ( SFR_S_BEGIN'stable(tHalfBit-tclk) ) then good := false; end if;
                assert ( SFR_S_MIDLE'stable(tHalfBit-tclk) ) report "  Error: SFR_S_MIDLE unexpected toggled" severity warning;
                if not ( SFR_S_MIDLE'stable(tHalfBit-tclk) ) then good := false; end if;
                assert ( SFR_CAP'stable(tHalfBit-tclk) ) report "  Error: SFR_CAP unexpected toggled" severity warning;
                if not ( SFR_CAP'stable(tHalfBit-tclk) ) then good := false; end if;
                wait until rising_edge(C); wait for tHold;
            end loop;
            --
            -- last bit
            Report "  Info:Bit" & integer'image(0) & ": First half bit period, clock cycle 0" ;
            assert ( '0' = SFR_LD ) report "  Error:Bit" & integer'image(0) & ": SFR_LD" severity warning;
            if not ( '0' = SFR_LD ) then good := false; end if;
            assert ( '1' = SFR_S_BEGIN ) report "  Error:Bit" & integer'image(0) & ": SFR_S_BEGIN" severity warning;
            if not ( '1' = SFR_S_BEGIN ) then good := false; end if;
            assert ( '0' = SFR_S_MIDLE ) report "  Error:Bit" & integer'image(0) & ": SFR_S_MIDLE" severity warning;
            if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
            assert ( '0' = SFR_CAP ) report "  Error:Bit" & integer'image(0) & ": SFR_CAP" severity warning;
            if not ( '0' = SFR_CAP ) then good := false; end if;
            wait until rising_edge(C);
            assert ( SFR_LD'stable(tclk-tHold) ) report "  Error: SFR_LD unexpected toggled" severity warning;
            if not ( SFR_LD'stable(tclk-tHold) ) then good := false; end if;
            assert ( SFR_S_BEGIN'stable(tclk-tHold) ) report "  Error: SFR_S_BEGIN unexpected toggled" severity warning;
            if not ( SFR_S_BEGIN'stable(tclk-tHold) ) then good := false; end if;
            assert ( SFR_S_MIDLE'stable(tclk-tHold) ) report "  Error: SFR_S_MIDLE unexpected toggled" severity warning;
            if not ( SFR_S_MIDLE'stable(tclk-tHold) ) then good := false; end if;
            assert ( SFR_CAP'stable(tclk-tHold) ) report "  Error: SFR_CAP unexpected toggled" severity warning;
            if not ( SFR_CAP'stable(tclk-tHold) ) then good := false; end if;
            --   first half bit period, clock cycle 1..n
            wait for tHalfBit - tclk;
            Report "  Info:Bit" & integer'image(0) & ": First half bit period, clock cycle 1..n" ;
            wait until rising_edge(C);
            assert ( '0' = SFR_LD ) report "  Error:Bit" & integer'image(0) & ": SFR_LD" severity warning;
            if not ( '0' = SFR_LD ) then good := false; end if;
            assert ( '0' = SFR_S_BEGIN ) report "  Error:Bit" & integer'image(0) & ": SFR_S_BEGIN" severity warning;
            if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
            assert ( '0' = SFR_S_MIDLE ) report "  Error:Bit" & integer'image(0) & ": SFR_S_MIDLE" severity warning;
            if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
            assert ( '0' = SFR_CAP ) report "  Error:Bit" & integer'image(0) & ": SFR_CAP" severity warning;
            if not ( '0' = SFR_CAP ) then good := false; end if;
            assert ( SFR_LD'stable(tHalfBit-tclk) ) report "  Error: SFR_LD unexpected toggled" severity warning;
            if not ( SFR_LD'stable(tHalfBit-tclk) ) then good := false; end if;
            assert ( SFR_S_BEGIN'stable(tHalfBit-tclk) ) report "  Error: SFR_S_BEGIN unexpected toggled" severity warning;
            if not ( SFR_S_BEGIN'stable(tHalfBit-tclk) ) then good := false; end if;
            assert ( SFR_S_MIDLE'stable(tHalfBit-tclk) ) report "  Error: SFR_S_MIDLE unexpected toggled" severity warning;
            if not ( SFR_S_MIDLE'stable(tHalfBit-tclk) ) then good := false; end if;
            assert ( SFR_CAP'stable(tHalfBit-tclk) ) report "  Error: SFR_CAP unexpected toggled" severity warning;
            if not ( SFR_CAP'stable(tHalfBit-tclk) ) then good := false; end if;
            --   second half bit period, clock cycle 0
            wait until rising_edge(C);
            Report "  Info:Bit" & integer'image(0) & ": Second half bit period, clock cycle 0" ;
            assert ( '0' = SFR_LD ) report "  Error:Bit" & integer'image(0) & ": SFR_LD" severity warning;
            if not ( '0' = SFR_LD ) then good := false; end if;
            assert ( '0' = SFR_S_BEGIN ) report "  Error:Bit" & integer'image(0) & ": SFR_S_BEGIN" severity warning;
            if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
            assert ( '1' = SFR_S_MIDLE ) report "  Error:Bit" & integer'image(0) & ": SFR_S_MIDLE" severity warning;
            if not ( '1' = SFR_S_MIDLE ) then good := false; end if;
            assert ( '1' = SFR_CAP ) report "  Error:Bit" & integer'image(0) & ": SFR_CAP" severity warning;
            if not ( '1' = SFR_CAP ) then good := false; end if;
            assert ( SFR_LD'stable(tclk-tHold) ) report "  Error: SFR_LD unexpected toggled" severity warning;
            if not ( SFR_LD'stable(tclk-tHold) ) then good := false; end if;
            assert ( SFR_S_BEGIN'stable(tclk-tHold) ) report "  Error: SFR_S_BEGIN unexpected toggled" severity warning;
            if not ( SFR_S_BEGIN'stable(tclk-tHold) ) then good := false; end if;
            assert ( SFR_S_MIDLE'stable(tclk-tHold) ) report "  Error: SFR_S_MIDLE unexpected toggled" severity warning;
            if not ( SFR_S_MIDLE'stable(tclk-tHold) ) then good := false; end if;
            assert ( SFR_CAP'stable(tclk-tHold) ) report "  Error: SFR_CAP unexpected toggled" severity warning;
            if not ( SFR_CAP'stable(tclk-tHold) ) then good := false; end if;
        end if;
        -------------------------





        -------------------------
        -- Test0: Single shoot
        -------------------------
--        if ( DO_ALL_TEST or do_test_0 ) then
--            Report "Test0: Single shoot";
--            wait until rising_edge(C); wait for tHold;
--            -- sync with CEA
--            while ( '0' = CENA ) loop
--                wait until rising_edge(C); wait for tHold;
--            end loop;
--            -- start transfer
--            START   <=  '1';
--            wait until rising_edge(C); wait for tHold;
--            START   <=  '0';
--            while ( '0' = CENA ) loop
--                wait until rising_edge(C); wait for tHold;
--            end loop;
--            -- Bit2
--            assert ( '1' = SFR_LD ) report "  Error:Bit2: SFR_LD=1 expected" severity warning;
--            if not ( '1' = SFR_LD ) then good := false; end if;
--            assert ( '1' = SFR_S_BEGIN ) report "  Error:Bit2: SFR_S_BEGIN=1 expected" severity warning;
--            if not ( '1' = SFR_S_BEGIN ) then good := false; end if;
--            -- wait
--            for i in 0 to (CLKDIV2*(CLKENA_DIV+1)-1) loop
--                wait until rising_edge(C); wait for tHold;
--            end loop;
--            -- middle of bit
--            assert ( '0' = SFR_S_BEGIN ) report "  Error:Bit2: SFR_S_BEGIN=0 expected" severity warning;
--            if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
--            assert ( '1' = SFR_S_MIDLE ) report "  Error:Bit2: SFR_S_MIDLE=1 expected" severity warning;
--            if not ( '1' = SFR_S_MIDLE ) then good := false; end if;
--            -- wait
--            for i in 0 to (CLKDIV2*(CLKENA_DIV+1)-1) loop
--                wait until rising_edge(C); wait for tHold;
--            end loop;
--            -- Bit1
--            assert ( '1' = SFR_S_BEGIN ) report "  Error:Bit1: SFR_S_BEGIN=1 expected" severity warning;
--            if not ( '1' = SFR_S_BEGIN ) then good := false; end if;
--            assert ( '0' = SFR_S_MIDLE ) report "  Error:Bit1: SFR_S_BEGIN=1 expected" severity warning;
--            if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
--            for i in 0 to (CLKDIV2*(CLKENA_DIV+1)-1) loop
--                wait until rising_edge(C); wait for tHold;
--            end loop;
--            assert ( '0' = SFR_S_BEGIN ) report "  Error:Bit1: SFR_S_BEGIN=0 expected" severity warning;
--            if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
--            assert ( '1' = SFR_S_MIDLE ) report "  Error:Bit1: SFR_S_MIDLE=1 expected" severity warning;
--            if not ( '1' = SFR_S_MIDLE ) then good := false; end if;
--            for i in 0 to (CLKDIV2*(CLKENA_DIV+1)-1) loop
--                wait until rising_edge(C); wait for tHold;
--            end loop;
--            -- Bit0
--            assert ( '1' = SFR_S_BEGIN ) report "  Error:Bit0: SFR_S_BEGIN=1 expected" severity warning;
--            if not ( '1' = SFR_S_BEGIN ) then good := false; end if;
--            assert ( '0' = SFR_S_MIDLE ) report "  Error:Bit0: SFR_S_BEGIN=1 expected" severity warning;
--            if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
--          for i in 0 to (CLKDIV2*(CLKENA_DIV+1)-2) loop
--              wait until rising_edge(C); wait for tHold;
--              assert ( '0' = SFR_S_BEGIN ) report "  Error:Bit0: SFR_S_BEGIN=0 expected" severity warning;
--              if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
--              assert ( '0' = SFR_S_MIDLE ) report "  Error:Bit0: SFR_S_MIDLE=0 expected" severity warning;
--              if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
--              assert ( '0' = SFR_CAP ) report "  Error:Bit0: SFR_CAP=0 expected" severity warning;
--              if not ( '0' = SFR_CAP ) then good := false; end if;
--          end loop;
--            assert ( SFR_S_BEGIN'stable( (2*CLKDIV2-1)*((CLKENA_DIV+1)-2)*tclk) ) report "  Error:Bit0: SFR_S_BEGIN unexpected toggled" severity warning;
--            if not ( SFR_S_BEGIN'stable( (2*CLKDIV2-1)*((CLKENA_DIV+1)-2)*tclk) ) then good := false; end if;
--            assert ( SFR_S_MIDLE'stable( (2*CLKDIV2-1)*((CLKENA_DIV+1)-2)*tclk) ) report "  Error:Bit0: SFR_S_MIDLE unexpected toggled" severity warning;
--            if not ( SFR_S_MIDLE'stable( (2*CLKDIV2-1)*((CLKENA_DIV+1)-2)*tclk) ) then good := false; end if;
--            assert ( SFR_CAP'stable( (2*CLKDIV2-1)*((CLKENA_DIV+1)-2)*NUMBIT*tclk) ) report "  Error:Bit0: SFR_CAP unexpected toggled" severity warning;
--            if not ( SFR_CAP'stable( (2*CLKDIV2-1)*((CLKENA_DIV+1)-2)*NUMBIT*tclk) ) then good := false; end if;
--          wait until rising_edge(C); wait for tHold;  -- belongs to loop
--            assert ( '0' = SFR_S_BEGIN ) report "  Error:Bit0: SFR_S_BEGIN=0 expected" severity warning;
--            if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
--            assert ( '1' = SFR_S_MIDLE ) report "  Error:Bit0: SFR_S_MIDLE=1 expected" severity warning;
--            if not ( '1' = SFR_S_MIDLE ) then good := false; end if;
--            assert ( '1' = SFR_CAP ) report "  Error:Bit0: SFR_CAP=1 expected" severity warning;
--            if not ( '1' = SFR_CAP ) then good := false; end if;
--              -- middle of baud rate phase
--          for i in 0 to (CLKDIV2*(CLKENA_DIV+1)-1) loop
--                wait until rising_edge(C); wait for tHold;
--              assert ( '0' = SFR_S_BEGIN ) report "  Error: Failed Shift TX SFR" severity warning;
--              if not ( '0' = SFR_S_BEGIN ) then good := false; end if;
--              assert ( '0' = SFR_S_MIDLE ) report "  Error: Failed Shift RX SFR" severity warning;
--              if not ( '0' = SFR_S_MIDLE ) then good := false; end if;
--              assert ( '0' = SFR_CAP ) report "  Error:Bit0: SFR_CAP=0 expected" severity warning;
--              if not ( '0' = SFR_CAP ) then good := false; end if;
--          end loop;
--            --
--            assert ( BUSY'stable((2*CLKDIV2-1)*(CLKENA_DIV+1)*tclk) ) report "  Error: Busy unexpected toggled" severity warning;
--            if not ( BUSY'stable((2*CLKDIV2-1)*(CLKENA_DIV+1)*tclk) ) then good := false; end if;
--            assert ( '1' = BUSY ) report "  Error: Needs to be busy" severity warning;
--            if not ( '1' = BUSY ) then good := false; end if;
--            while ( '1' = BUSY ) loop
--                wait until rising_edge(C); wait for tHold;
--            end loop;
--        end if;
--        -------------------------


        -------------------------
        -- Report TB
        -------------------------
            Report "End TB...";     -- sim finished
            if (good) then
                Report "Test SUCCESSFUL";
            else
                Report "Test FAILED" severity error;
            end if;
            wait until falling_edge(C); wait for tHold;
            CLKENA <= '0';
            wait;                   -- stop process continuous run
        -------------------------

    end process p_stimuli_process;
    ----------------------------------------------

    ----------------------------------------------
    -- clock divider
    p_div : process ( C, R )
        variable v_clkdiv : integer;
    begin
        if ( '1' = R ) then
            CENA        <= '0';
            v_clkdiv    := CLKENA_DIV-1;
        elsif ( rising_edge(C) ) then
            if ( 0 = v_clkdiv ) then
                v_clkdiv    := CLKENA_DIV-1;
                CENA        <= '1';
            else
                v_clkdiv    := v_clkdiv - 1;
                CENA        <= '0';
            end if;
        end if;
    end process p_div;
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
