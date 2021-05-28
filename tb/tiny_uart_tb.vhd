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
-- @file:           tiny_uart_tb.vhd
-- @date:           2018-08-05
--
-- @see:            https://github.com/akaeba/tinyUART
-- @brief:          testbench
--
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
        constant WLS    : integer range 5 to 8  := 8;           --! word length select; number of data bits     [ integer ]
        constant CLK    : positive              := 1_000_000;   --! master clock frequency in Hz                [ integer ]
        constant BPS    : positive              := 38400;       --! transceive baud rate in Bps                 [ integer ]
        constant SBS    : integer range 1 to 2  := 1;           --! Stop bit select, only one/two stopbit       [ integer ]
        constant PI     : boolean               := true;        --! Parity inhibit, true: inhibit               [ boolean ]
        constant EPE    : boolean               := true;        --! Even parity enable, true: even, false: odd  [ boolean ]
        constant DEBU   : integer range 0 to 11 := 3;           --! Number of debouncer stages                  [ integer ]

        -- Clock
        constant tclk   : time  := (1 sec) / CLK;   --! 1MHz clock
        constant tskew  : time  := tclk / 50;       --! data skew
        constant tBit   : time := (1 sec) / BPS;    --! duration of one UART bit

        -- Test
        constant loop_iter  : integer := 20;    --! number of test loop iteration
        constant do_test_0  : boolean := true;  --! Test0: TX - single data word
        constant do_test_1  : boolean := true;  --! Test1: RX - single data word
        constant do_test_2  : boolean := true;  --! Test2: TX - double data word
        constant do_test_3  : boolean := true;  --! Test3: TX - random data
        constant do_test_4  : boolean := true;  --! Test4: RX - random data
        constant do_test_5  : boolean := true;  --! Test5: RX - provoke framing error

    -----------------------------


    -----------------------------
    -- Signals
        -- DUT
        signal R    : std_logic;
        signal C    : std_logic;
        signal TXD  : std_logic;
        signal RXD  : std_logic;
        signal RR   : std_logic_vector(WLS-1 downto 0);
        signal PE   : std_logic;
        signal FE   : std_logic;
        signal DR   : std_logic;
        signal TR   : std_logic_vector(WLS-1 downto 0);
        signal THRE : std_logic;
        signal THRL : std_logic;
        signal TRE  : std_logic;
    -----------------------------

begin

    ----------------------------------------------
    -- DUT
        DUT : entity work.tiny_uart
            generic map (
                            WLS     => WLS,
                            CLK     => CLK,
                            BPS     => BPS,
                            SBS     => SBS,
                            PI      => PI,
                            EPE     => EPE,
                            DEBU    => DEBU
                        )
            port map    (
                            R       => R,
                            C       => C,
                            TXD     => TXD,
                            RXD     => RXD,
                            RR      => RR,
                            PE      => PE,
                            FE      => FE,
                            DR      => DR,
                            TR      => TR,
                            THRE    => THRE,
                            THRL    => THRL,
                            TRE     => TRE
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
            TR      <=  (others => 'X');
            THRL    <=  '0';
            wait for 5*tclk;
            wait until rising_edge(C); wait for tskew;
            R       <=  '0';
            wait until rising_edge(C); wait for tskew;
            wait until rising_edge(C); wait for tskew;
        -------------------------


        -------------------------
        -- Test0: Check TX (Single Dataword)
        -------------------------
        if ( DO_ALL_TEST or do_test_0 ) then
            Report "Test0: TX - single data word";
            wait until rising_edge(C); wait for tskew;
            -- idle settings
            assert ( '1' = TXD ) report "  Error: TXD not idle" severity warning;
            if not ( '1' = TXD ) then good := false; end if;
            assert ( '1' = THRE ) report "  Error: Transmit Holding Register Empty" severity warning;
            if not ( '1' = THRE ) then good := false; end if;
            assert ( '1' = TRE ) report "  Error: TX not empty" severity warning;
            if not ( '1' = TRE ) then good := false; end if;
            -- start transfer
            TR      <= x"55";
            THRL    <= '1';
            wait until rising_edge(C); wait for tskew;
            TR      <= (others => 'X');
            THRL    <= '0';
            -- wait for start
            wait until falling_edge(TXD);
            -- start sampling
            wait for ( tBit / 2 );
            for i in buf'low to buf'high loop
                buf(i) := TXD;
                if ( i /= buf'high) then    --! allows triggering on next start bit
                    wait for tBit;          --! next bit
                end if;
            end loop;
            assert ( ('1' = buf(buf'left)) and ('0' = buf(buf'right)) ) report "  Error: Data Frame" severity warning;
            if not ( ('1' = buf(buf'left)) and ('0' = buf(buf'right)) ) then good := false; end if;
            assert ( x"55" = buf(buf'left-1 downto buf'right+1) ) report "  Error: data value" severity warning;
            if not ( x"55" = buf(buf'left-1 downto buf'right+1) ) then good := false; end if;
            while ( '0' = TRE ) loop
                wait until rising_edge(C); wait for tskew;
            end loop;
            wait for 10*tclk;
        end if;
        -------------------------


        -------------------------
        -- Test1: Check RX Path
        -------------------------
        if ( DO_ALL_TEST or do_test_1 ) then
            Report "Test1: RX - single data word";
            wait until rising_edge(C); wait for tskew;
            -- idle settings
            assert ( x"00" = RR ) report "  Error: Receive Hold Register" severity warning;
            if not ( x"00" = RR ) then good := false; end if;
            assert ( '0' = PE ) report "  Error: Parity Error" severity warning;
            if not ( '0' = PE ) then good := false; end if;
            assert ( '0' = FE ) report "  Error: Framing Error" severity warning;
            if not ( '0' = FE ) then good := false; end if;
            assert ( '0' = DR ) report "  Error: Data Received" severity warning;
            if not ( '0' = DR ) then good := false; end if;
            -- create test data
            buf := '1' & x"AA" & '0';  --! reverse order cause in UART is LSB send as first
            for i in buf'low to buf'high loop
                RXD <= buf(i);  --! set bit
                wait for tBit;  --! next bit
            end loop;
            assert ( '0' = FE ) report "  Error: Framing Error" severity warning;
            if not ( '0' = FE ) then good := false; end if;
            assert ( x"AA" = RR ) report "  Error: Receive Hold Register" severity warning;
            if not ( x"AA" = RR ) then good := false; end if;
            wait for 10*tclk;
        end if;
        -------------------------


        -------------------------
        -- Test2: Send double data word
        -------------------------
        if ( DO_ALL_TEST or do_test_2 ) then
            Report "Test2: TX - double data word";
            wait until rising_edge(C); wait for tskew;
            -- fill in first data word
            TR      <= x"47";
            THRL    <= '1';
            wait until rising_edge(C); wait for tskew;
            TR      <= (others => 'X');
            THRL    <= '0';
            wait until ( THRE = '1' );
            wait until rising_edge(C); wait for tskew;
            -- second data word
            TR      <= x"11";
            THRL    <= '1';
            wait until rising_edge(C); wait for tskew;
            TR      <= (others => 'X');
            THRL    <= '0';
            wait until rising_edge(C); wait for tskew;
            -- wait for startbit
            if ( '1' = TXD ) then
                while ( '1' = TXD ) loop
                    wait until rising_edge(C); wait for tskew;
                end loop;
            end if;
            wait for tBit/2;
            -- record first data word and check
            for i in buf'low to buf'high loop
                buf(i) := TXD;
                if ( i /= buf'high) then    --! allows triggering on next start bit
                    wait for tBit;          --! next bit
                end if;
            end loop;
            assert ( ('1' = buf(buf'left)) and ('0' = buf(buf'right)) ) report "  Error: Data Frame Val1" severity warning;
            if not ( ('1' = buf(buf'left)) and ('0' = buf(buf'right)) ) then good := false; end if;
            assert ( x"47" = buf(buf'left-1 downto buf'right+1) ) report "  Error: data value Val1" severity warning;
            if not ( x"47" = buf(buf'left-1 downto buf'right+1) ) then good := false; end if;
            -- record second data word and check
            wait until falling_edge(TXD);   -- wait for startbit
            wait for tBit/2;
            for i in buf'low to buf'high loop
                buf(i) := TXD;
                if ( i /= buf'high) then    --! allows triggering on next start bit
                    wait for tBit;          --! next bit
                end if;
            end loop;
            assert ( ('1' = buf(buf'left)) and ('0' = buf(buf'right)) ) report "  Error: Data Frame Val2" severity warning;
            if not ( ('1' = buf(buf'left)) and ('0' = buf(buf'right)) ) then good := false; end if;
            assert ( x"11" = buf(buf'left-1 downto buf'right+1) ) report "  Error: data value Val2" severity warning;
            if not ( x"11" = buf(buf'left-1 downto buf'right+1) ) then good := false; end if;
            while ( '0' = TRE ) loop
                wait until rising_edge(C); wait for tskew;
            end loop;
            wait for 10*tclk;
        end if;
        -------------------------


        -------------------------
        -- Test3: TX - random data
        -------------------------
        if ( DO_ALL_TEST or do_test_3 ) then
            Report "Test3: TX - random data";
            wait until rising_edge(C); wait for tskew;
            UNIFORM(seed1, seed2, rand);    --! dummy read, otherwise first rand is zero
            -- performs multi word send
            for j in 0 to loop_iter-1 loop
                -- rand data
                UNIFORM(seed1, seed2, rand);    --! random number
                tmp :=  std_logic_vector(to_unsigned(integer(round(rand*(2.0**tmp'length-1.0))), tmp'length));
                -- fill in first data word
                TR      <= tmp;
                THRL    <= '1';
                wait until rising_edge(C); wait for tskew;
                TR      <= (others => 'X');
                THRL    <= '0';
                -- wait for startbit
                wait until ( '0' = TXD );
                wait for Tbit/2;
                -- record and check
                for i in buf'low to buf'high loop
                    buf(i) := TXD;
                    if ( i /= buf'high) then    --! allows triggering on next start bit
                        wait for tBit;          --! next bit
                    end if;
                end loop;
                assert ( ('1' = buf(buf'left)) and ('0' = buf(buf'right)) ) report "  Error: Data Frame " & integer'image(j) severity warning;
                if not ( ('1' = buf(buf'left)) and ('0' = buf(buf'right)) ) then good := false; end if;
                assert ( tmp = buf(buf'left-1 downto buf'right+1) ) report "  Error: data value " & integer'image(j) severity warning;
                if not ( tmp = buf(buf'left-1 downto buf'right+1) ) then good := false; end if;
                while ( '0' = TRE ) loop
                    wait until rising_edge(C); wait for tskew;
                end loop;
                wait for 10*tclk;
            end loop;
        end if;
        -------------------------


        -------------------------
        -- Test4: RX - random data
        -------------------------
        if ( DO_ALL_TEST or do_test_4 ) then
            Report "Test4: RX - random data";
            wait until rising_edge(C); wait for tskew;
            UNIFORM(seed1, seed2, rand);    --! dummy read, otherwise first rand is zero
            for j in 0 to loop_iter-1 loop
                UNIFORM(seed1, seed2, rand);    --! random number
                tmp :=  std_logic_vector(to_unsigned(integer(round(rand*(2.0**tmp'length-1.0))), tmp'length));
                buf := '1' & tmp & '0';  --! reverse order cause in UART is LSB send as first
                for i in buf'low to buf'high loop
                    RXD <= buf(i);  --! set bit
                    if ( i /= buf'high) then    --! allows triggering on data new
                        wait for tBit;          --! next bit
                    end if;
                end loop;
                wait until rising_edge(DR);
                assert ( tmp = RR ) report "  Error: data value " & integer'image(j) severity warning;
                if not ( tmp = RR ) then good := false; end if;
                assert ( '0' = FE ) report "  Error: Framing error frame " & integer'image(j) severity warning;
                if not ( '0' = FE ) then good := false; end if;
            end loop;
            wait for 10*tclk;
        end if;
        -------------------------


        -------------------------
        -- Test5: RX - provoke framing error
        -------------------------
        if ( DO_ALL_TEST or do_test_4 ) then
            Report "Test5: RX - provoke framing error";
            wait until rising_edge(C); wait for tskew;
            for i in 0 to 10 loop
                RXD <= '0';
                wait for tBit;
            end loop;
            RXD <= '1';
            assert ( x"00" = RR ) report "  Error: data value" severity warning;
            if not ( x"00" = RR ) then good := false; end if;
            assert ( '1' = FE ) report "  Error: Framing error expected" severity warning;
            if not ( '1' = FE ) then good := false; end if;
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
