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
-- @file:           tiny_uart_inp_filter_tb.vhd
-- @date:           2021-05-22
--
-- @see:            https://github.com/akaeba/tinyUART
-- @brief:          testbench
--
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use ieee.math_real.all; --! for UNIFORM, TRUNC
library work;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- testbench
entity tiny_uart_inp_filter_tb is
generic (
            DO_ALL_TEST : boolean := false  --! switch for enabling all tests
        );
end entity tiny_uart_inp_filter_tb;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of tiny_uart_inp_filter_tb is

    -----------------------------
    -- Constant
        -- DUT
        constant SYNC_STAGES    : integer range 0 to 3      := 2;
        constant VOTER_STAGES   : natural range 0 to 11     := 5;
        constant RST_STRBO      : bit                       := '0';
        constant RST_ACTIVE     : bit                       := '1';
        -- Clock
        constant tclk   : time  := 20 ns;       --! 50MHz clock
        constant tskew  : time  := tclk / 50;   --! data skew
        -- Test
        constant loop_iter  : integer := 5;     --! number of test loop iteration
        constant do_test_0  : boolean := true;  --! test0: Switch to one/zero
        constant do_test_1  : boolean := true;  --! test1: Switch to one and apply noisy signal
        constant do_test_2  : boolean := true;  --! test2: Switch to zero and apply noisy signal
    -----------------------------


    -----------------------------
    -- Signal
        -- DUT
        signal RST  : std_logic;
        signal CLK  : std_logic;
        signal INP  : std_logic;
        signal OUTP : std_logic;
    -----------------------------

begin

    ----------------------------------------------
    -- DUT
        DUT : entity work.tiny_uart_inp_filter
            generic map (
                            SYNC_STAGES     => SYNC_STAGES,
                            VOTER_STAGES    => VOTER_STAGES,
                            O_RST           => RST_STRBO,
                            RST_ACTIVE      => RST_ACTIVE
                        )
            port map    (
                            R       => RST,
                            C       => CLK,
                            INP     => INP,
                            OUTP    => OUTP
                        );
    ----------------------------------------------


    ----------------------------------------------
    -- Performs tests
    p_stimuli_process : process
        -- tb help variables
            variable good : boolean := true;
    begin

        -------------------------
        -- Init
        -------------------------
            Report "Init...";
            RST <= '1';
            INP <= '0';
            wait for 5*tclk;
            wait until rising_edge(CLK); wait for tskew;
            RST <= '0';
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
        -------------------------


        -------------------------
        -- Test0: Switch to one/zero
        -------------------------
        if ( DO_ALL_TEST or do_test_0 ) then
            Report "Test0: Switch to one/zero";
            wait until rising_edge(CLK); wait for tskew;
            INP <= '1';
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            INP <= '0';
            wait until rising_edge(CLK); wait for tskew;    --! two stages sync chain
            wait until rising_edge(CLK); wait for tskew;    --!
            wait until rising_edge(CLK); wait for tskew;    --! RS-FF set delay
            assert ( '1' = OUTP ) report "  OUTP needs to be one" severity warning;
            if not ( '1' = OUTP  ) then good := false; end if;
            wait until rising_edge(CLK); wait for tskew;
            assert ( '1' = OUTP ) report "  OUTP needs to be one" severity warning;
            if not ( '1' = OUTP  ) then good := false; end if;
            wait until rising_edge(CLK); wait for tskew;
            assert ( '1' = OUTP ) report "  OUTP needs to be one" severity warning;
            if not ( '1' = OUTP  ) then good := false; end if;
            wait until rising_edge(CLK); wait for tskew;
            assert ( '1' = OUTP ) report "  OUTP needs to be one" severity warning;
            if not ( '1' = OUTP  ) then good := false; end if;
            wait until rising_edge(CLK); wait for tskew;
            assert ( '1' = OUTP ) report "  OUTP needs to be one" severity warning;
            if not ( '1' = OUTP  ) then good := false; end if;
            wait for 10*tclk;
        end if;
        -------------------------


        -------------------------
        -- Test1: Switch to one and apply noisy signal
        -------------------------
        if ( DO_ALL_TEST or do_test_1 ) then
            Report "Test1: Switch to one and apply noisy signal";
            wait until rising_edge(CLK); wait for tskew;
            INP <= '1';
            for INP in 0 to 4 loop
                wait until rising_edge(CLK); wait for tskew;
            end loop;
            INP <= '0';
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            assert ( '1' = OUTP ) report "  OUTP accidentally toggled" severity warning;
            if not ( '1' = OUTP  ) then good := false; end if;
            for i in 0 to loop_iter-1 loop
                INP <= '1';
                assert ( '1' = OUTP ) report "  OUTP accidentally toggled" severity warning;
                if not ( '1' = OUTP  ) then good := false; end if;
                wait until rising_edge(CLK); wait for tskew;
                INP <= '0';
                assert ( '1' = OUTP ) report "  OUTP accidentally toggled" severity warning;
                if not ( '1' = OUTP  ) then good := false; end if;
                wait until rising_edge(CLK); wait for tskew;
            end loop;
            wait for 10*tclk;
        end if;
        -------------------------


        -------------------------
        -- Test2: Switch to zero and apply noisy signal
        -------------------------
        if ( DO_ALL_TEST or do_test_2 ) then
            Report "Test2: Switch to zero and apply noisy signal";
            wait until rising_edge(CLK); wait for tskew;
            INP <= '0';
            for i in 0 to 4 loop
                wait until rising_edge(CLK); wait for tskew;
            end loop;
            INP <= '0';
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            assert ( '0' = OUTP ) report "  OUTP accidentally toggled" severity warning;
            if not ( '0' = OUTP  ) then good := false; end if;
            for i in 0 to loop_iter-1 loop
                INP <= '1';
                assert ( '0' = OUTP ) report "  OUTP accidentally toggled" severity warning;
                if not ( '0' = OUTP  ) then good := false; end if;
                wait until rising_edge(CLK); wait for tskew;
                INP <= '0';
                assert ( '0' = OUTP ) report "  OUTP accidentally toggled" severity warning;
                if not ( '0' = OUTP  ) then good := false; end if;
                wait until rising_edge(CLK); wait for tskew;
            end loop;
            wait for 10*tclk;
        end if;
        -------------------------


        -------------------------
        -- Report TB
        -------------------------
            Report "End TB...";     -- sim finished
            if (good) then
                Report "Test SUCCESSFUL";
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
        variable v_clk : std_logic := '0';
    begin
        while true loop
            CLK     <= v_clk;
            v_clk   := not v_clk;
            wait for tclk/2;
            end loop;
    end process p_clk;
    ----------------------------------------------

end architecture sim;
--------------------------------------------------------------------------
