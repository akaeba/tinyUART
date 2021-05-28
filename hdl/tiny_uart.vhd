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
-- @file:           tiny_uart_cntr.vhd
-- @date:           2018-08-03
--
-- @see:            https://github.com/akaeba/tinyUART
-- @brief:          UART core (toplevel)
--
--                  UART Transmitter and Receiver
--************************************************************************



--
-- Important Hints:
-- ================
--
--  Settings (adjustable at compile time)
--  -------------------------------------
--      DWIDTH:     number of data bits
--      CLK_HZ:     clock frequency in Hz
--      BAUD_BPS:   Baud rate in BPS
--      DEBOUNCE:   voter sample, avoid false detection if sync stages latches accidentally the wrong value
--
--  Miscellaneous
--  -------------
--      parity:     none, even, odd
--      stop bits:  1-2
--      CLK:        > 16*BAUD_BPS
--
--  Typical Baud-rates
--  ------------------
--      9600, 19200, 38400, 57600, 115200, 230400
--
--
--
--



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use IEEE.math_real.round;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- tiny UART
entity tiny_uart is
generic (
            WLS     : integer range 5 to 8  := 8;           --! word length select; number of data bits     [ integer ]
            CLK     : positive              := 50_000_000;  --! master clock frequency in Hz                [ integer ]
            BPS     : positive              := 115200;      --! transceive baud rate in Bps                 [ integer ]
            SBS     : integer range 1 to 2  := 1;           --! Stop bit select, only one/two stopbit       [ integer ]
            PI      : boolean               := true;        --! Parity inhibit, true: inhibit               [ boolean ]
            EPE     : boolean               := true;        --! Even parity enable, true: even, false: odd  [ boolean ]
            DEBU    : integer range 0 to 11 := 3;           --! Number of debouncer stages                  [ integer ]
            TXIMPL  : boolean               := true;        --! implement UART TX path                      [ boolean ]
            RXIMPL  : boolean               := true         --! implement UART RX path                      [ boolean ]
        );
port    (
            -- Clock/Reset
            R       : in    std_logic;          --! asynchrony reset
            C       : in    std_logic;          --! clock, rising edge
            -- serial UART Interface
            TXD     : out   std_logic;          --! transmit register output (START bit, DATA bits, PARITY bit, and STOP bits);     LSB First
            RXD     : in    std_logic;          --! receive data;   LSB first
            -- Parallel Interface
            RR      : out   std_logic_vector(WLS-1 downto 0);   --! Receiver Holding Register Data Output
            PE      : out   std_logic;                          --! Parity error
            FE      : out   std_logic;                          --! Framing error
            DR      : out   std_logic;                          --! Data Received, one clock cycle high
            TR      : in    std_logic_vector(WLS-1 downto 0);   --! Transmit Holding Register Data Input
            THRE    : out   std_logic;                          --! Transmitter Holding Register Empty
            THRL    : in    std_logic;                          --! Transmitter Holding Register Load, one clock cycle high
            TRE     : out   std_logic                           --! Transmitter Register Empty
        );
end entity tiny_uart;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of tiny_uart is

    ----------------------------------------------
    -- Functions
    ----------------------------------------------

        --***************************
        -- reverse
        --   @see: https://www.thecodingforums.com/threads/swapping-bits-in-a-byte.496443/
        function reverse (arg: std_logic_vector) return std_logic_vector is
            variable result: std_logic_vector(arg'reverse_range);
        begin
            for i in arg'range loop
                result(i) := arg(i);
            end loop;
            return result;
        end reverse;
        --***************************

        --***************************
        -- parity
        --   creates an string with a fixed length, padded with pad
        function parity
            (
                constant val    : in std_logic_vector;  --! calculate parity
                constant even   : in boolean            --! true : Even Parity; false : Odd Parity
            )
        return std_logic is
            variable par : std_logic;
        begin
            -- select parity type
            if ( even ) then
                par := '0';
            else
                par := '1';
            end if;
            -- calculate
            for i in val'range loop
                par := par xor val(i);
            end loop;
            return par;
        end function parity;
        --***************************

        --***************************
        -- numParBit
        --   returns number of used parity bits
        function numParBit
            (
                constant parity_inhibit : boolean := true
            )
        return integer is
        begin
            if ( parity_inhibit ) then
                return 0;
            end if;
            return 1;
        end function numParBit;
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- Constants
    ----------------------------------------------
        constant c_baud_clkdiv2 : integer := integer(round(real(CLK)/real(2*BPS))); --! TBIT/2 clock divider
    ----------------------------------------------


    ----------------------------------------------
    -- Signals
    ----------------------------------------------
        -- TX
        signal tx_hold_empty    : std_logic;                                        --! signals empty of TX hold register
        signal tx_hold_new      : std_logic;                                        --! new data to transmit flag
        signal tx_hold          : std_logic_vector(TR'range);                       --! TX hold register
        signal tx_sfr           : std_logic_vector(WLS+1+numParBit(PI)-1 downto 0); --! +1: start bit; stop bits skipped, '1' is idle
        signal tx_sfr_ld        : std_logic;                                        --! preload serial shift out register
        signal tx_sfr_shift     : std_logic;                                        --! shift forward
        signal bsy_tx           : std_logic;                                        --! transmission active
        -- RX
        signal rx_sfr           : std_logic_vector(WLS+1+numParBit(PI)-1 downto 0); --! +1: start bit; stop bit skipped, direct evaluated (framing error)
        signal rx_sfr_shift     : std_logic;                                        --! shift forward
        signal rx_sfr_cap       : std_logic;                                        --! load RR reg
        signal rx_bit           : std_logic;                                        --! voted rx-bit
        signal rx_bit_dly1      : std_logic;                                        --! one clock cycle delayed rx, start bit detection
        signal rx_nedge         : std_logic;                                        --! in rxd stream negative edge detected
        signal bsy_rx           : std_logic;                                        --! receive active
        signal fe_comb          : std_logic;                                        --! calculated framing error
        signal pe_comb          : std_logic;                                        --! calculated parity

    -----------------------------

begin

    ----------------------------------------------
    -- Synthesis/Simulator Messages
    -- core settings
    assert not true
    report                                                                                                        character(LF) &
        "tiny_uart configuration:"                                                                              & character(LF) &
        "  Clock rate       : " & integer'image(CLK)                                                & " Hz"     & character(LF) &
        "  Baud rate [set]  : " & integer'image(BPS)                                                & " Bps"    & character(LF) &
        "  Baud rate [is]   : " & integer'image(integer(round(real(CLK)/real(2*c_baud_clkdiv2))))   & " Bps"    & character(LF) &
        "  Data width       : " & integer'image(WLS)                                                            & character(LF) &
        "  Stop bit         : " & integer'image(SBS)                                                            & character(LF) &
        "  Parity enable    : " & boolean'image(not PI)                                                         & character(LF) &
        "  Parity even      : " & boolean'image(EPE)                                                            & character(LF) &
        "  Debounce stages  : " & integer'image(DEBU)                                                           & character(LF) &
        "  TBIT/2 clock div : " & integer'image(c_baud_clkdiv2)
    severity note;
    -- oversampling rate check
    assert ( 2*c_baud_clkdiv2 > 15 )    --! rate too low
    report                                                                    character(LF) &
        "Oversampling Rate too low"                                         & character(LF) &
        "  Oversampling [is]        : " & integer'image(2*c_baud_clkdiv2)   & character(LF) &
        "  Oversampling [recommend] : " & integer'image(16)
    severity warning;
    ----------------------------------------------


    ----------------------------------------------
    -- UART Tx Path
    ----------------------------------------------
    g_tx : if ( true = TXIMPL ) generate

        --***************************
        -- baud/bit sequencing generator
        --
        i_tx_baud_bit_gen : entity work.tiny_uart_baud_bit_gen
            generic map (
                            NUMBIT          => tx_sfr'length+SBS,   --! number of bits to handle
                            CLKDIV2         => c_baud_clkdiv2,      --! half bit period clock divider, TBIT = 2*CLKDIV2
                            SKIP_LAST_BIT2  => false                --! true: skips in last bit second half period wait, increases SNR in RX
                        )
            port map    (
                            R           => R,               --! asynchronous reset
                            C           => C,               --! clock, rising edge
                            START       => tx_hold_new,     --! start interaction
                            BUSY        => bsy_tx,          --! transfer active
                            SFR_LD      => tx_sfr_ld,       --! load parallel input of shift register
                            SFR_S_BEGIN => tx_sfr_shift,    --! shift pulse Tbit begin
                            SFR_S_MIDLE => open,            --! shift pulse Tbit middle
                            SFR_CAP     => open             --! all bits in shift register transfered
                        );
        --***************************

        --***************************
        -- Register
        p_tx_reg : process( R, C )
        begin
            if ( '1' = R ) then
                tx_hold         <= (others => '0'); --! data hold register
                tx_hold_empty   <= '1';             --! waiting for data
                tx_hold_new     <= '0';             --! new data to send
                tx_sfr          <= (others => '1'); --! idle level

            elsif ( rising_edge(C) ) then
                -- RSFF to handle new data input and request
                if ( '1' = THRL ) then
                    tx_hold         <= TR;  --! capture parallel input
                    tx_hold_empty   <= '0';
                    tx_hold_new     <= '1';
                elsif ( '1' = tx_sfr_ld ) then
                    tx_hold_empty   <= '1';
                    tx_hold_new     <= '0';
                end if;
                -- TX Shift register
                if ( '1' = tx_sfr_ld ) then
                    if ( PI ) then  --! skip parity
                        tx_sfr  <= '0' & reverse(tx_hold);  --! Start bit, Data bits, Stop bits shift in '1'
                    else            --! implement parity
                        tx_sfr  <= '0' & reverse(tx_hold) & parity(tx_hold, EPE);
                    end if;
                elsif ( '1' = tx_sfr_shift ) then
                    tx_sfr <= tx_sfr(tx_sfr'left-1 downto tx_sfr'right) & '1';  --! shift left, '1' UART idle
                end if;

            end if;
        end process p_tx_reg;
        --***************************

        --***************************
        -- Output Assignment
        THRE    <= tx_hold_empty;       --! hold register empty
        TRE     <= not bsy_tx;          --! transmitter register empty
        TXD     <= tx_sfr(tx_sfr'left); --! serial uart data
        --***************************

    end generate g_tx;
    ----------------------------------------------


    ----------------------------------------------
    -- Skip Tx
    ----------------------------------------------
    g_skip_tx : if ( false = TXIMPL ) generate

        THRE    <= '0';
        TXD     <= '1';
        TRE     <= '0';

    end generate g_skip_tx;
    ----------------------------------------------


    ----------------------------------------------
    -- UART Rx Path
    ----------------------------------------------
    g_rx : if ( true = RXIMPL ) generate

        --***************************
        -- Sync & Debounce
        --
        i_tiny_uart_inp_filter : entity work.tiny_uart_inp_filter
            generic map (
                            SYNC_STAGES  => 2,      --! synchronizer stages;                                                                        0: not implemented
                            VOTER_STAGES => DEBU,   --! number of ff stages for voter; if all '1' out is '1', if all '0' out '0', otherwise hold;   0: not implemented
                            OUTP_RST     => '1',    --! output in reset
                            RST_ACTIVE   => '1'     --! Reset active level
                        )
            port map    (
                            R    => R,      --! asynchronous reset
                            C    => C,      --! clock, rising edge
                            INP  => RXD,    --! serial in
                            OUTP => rx_bit  --! synced & voted input bit
                        );
        --***************************

        --***************************
        -- baud/bit sequencing generator
        --
        i_rx_baud_bit_gen : entity work.tiny_uart_baud_bit_gen
            generic map (
                            NUMBIT          => rx_sfr'length+SBS,   --! number of bits to handle
                            CLKDIV2         => c_baud_clkdiv2,      --! half bit period clock divider, TBIT = 2*CLKDIV2
                            SKIP_LAST_BIT2  => true                 --! true: skips in last bit second half period wait, increases SNR in RX
                        )
            port map    (
                            R           => R,               --! asynchronous reset
                            C           => C,               --! clock, rising edge
                            START       => rx_nedge,        --! start interaction
                            BUSY        => bsy_rx,          --! transfer active
                            SFR_LD      => open,            --! load parallel input of shift register
                            SFR_S_BEGIN => open,            --! shift pulse Tbit begin
                            SFR_S_MIDLE => rx_sfr_shift,    --! shift pulse Tbit middle
                            SFR_CAP     => rx_sfr_cap       --! all bits in shift register transfered
                        );
        --***************************

        --***************************
        -- Register
        p_rx_reg : process( R, C )
        begin
            if ( '1' = R ) then
                RR          <= (others => '0');
                FE          <= '0';
                DR          <= '0';
                rx_bit_dly1 <= '1';
                rx_sfr      <= (others => '0');

            elsif ( rising_edge(C) ) then
                -- DFF
                rx_bit_dly1 <= rx_bit;
                DR          <= rx_sfr_cap;
                -- SFR
                if ( '1' = rx_sfr_shift ) then  --! last captured bit (stop) is direct evaluated w/o feeding sfr
                    rx_sfr <= rx_sfr(rx_sfr'left-1 downto rx_sfr'right) & rx_bit;
                end if;
                -- data hold reg
                if ( '1' = rx_sfr_cap ) then
                    RR  <= reverse(rx_sfr(rx_sfr'left-1 downto rx_sfr'left-1-WLS+1));
                    FE  <= fe_comb;
                end if;

            end if;
        end process p_rx_reg;
        --***************************

        --***************************
        -- Glue Logic
            -- misc
            rx_nedge    <= (not rx_bit) and rx_bit_dly1 and (not bsy_rx);   --! falling edge detection, only active if not busy
            fe_comb     <= not ((not rx_sfr(rx_sfr'left)) and rx_bit);      --! start bit: left, stop bit sfr input

            -- parity calc & check
            g_pe : if ( false = PI ) generate
                pe_comb <=  parity(rx_sfr(rx_sfr'left-1 downto rx_sfr'left-1-WLS+1), EPE) xor rx_sfr(rx_sfr'right);
            end generate g_pe;

            -- parity always zero
            g_pe_0 : if ( true = PI ) generate
                PE <= '0';
            end generate g_pe_0;
        --***************************

    end generate g_rx;
    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
