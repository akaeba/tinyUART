--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        tiny_uart.vhd
-- @note        VHDL'93
--
-- @brief       UART core (toplevel)
-- @details     UART Transmitter and Reciever
--
-- @date        2018-08-03
-- @version     0.1
--************************************************************************



--
-- Important Hints:
-- ================
--
--  Settings (adjustable at compile time)
--  -------------------------------------
--      DWIDTH:     number of data bits
--      CLK_HZ:     clock frequency in Hz
--      BAUD_BPS:   Baudrate in BPS
--      DEBOUNCE:   voter sample, avaoid false detection if sync stages latches accidentally the wrong value
--
--  Miscellanous
--  ------------
--      parity:     none
--      stop bits:  1-2
--      CLK_HZ:     > 16*BAUD_BPS
--
--  Typical Baudrates
--  -----------------
--      9600, 19200, 38400, 57600, 115200, 230400
--
--
--
--



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use IEEE.math_real.floor;
    use IEEE.math_real.round;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- tiny UART
entity tiny_uart is
generic (
            DWIDTH      : integer range 4 to 8  := 8;           --! data width                          [integer]
            CLK_HZ      : positive              := 50_000_000;  --! clock frequency                     [Hz]
            BAUD_BPS    : positive              := 115200;      --! UART baud rate                      [bps]
            STOPBIT     : integer range 1 to 2  := 1;           --! Number of Stopbits                  [integer]
            RXSYNC      : integer range 2 to 3  := 2;           --! Number of sync stages               [integer]
            DEBOUNCE    : integer range 1 to 3  := 1            --! majority decisider (2n+1 stages)    [integer]
        );
port    (
            -- Clock/Reset
            R       : in    std_logic;          --! asnychon reset
            C       : in    std_logic;          --! clock, rising edge
            -- serial UART Interface
            TXD     : out   std_logic;          --! transmit data;  LSB first
            RXD     : in    std_logic;          --! recieve data;   LSB first
            -- Parallel Interface
            FRMERO  : out   std_logic;                              --! Framing error
            RX      : out   std_logic_vector(DWIDTH-1 downto 0);    --! recieved data
            RXCE    : out   std_logic;                              --! new recieved data, only one clock cycle high
            TX      : in    std_logic_vector(DWIDTH-1 downto 0);    --! transmit data
            TXMTY   : out   std_logic;                              --! request new transmit data
            TXCE    : in    std_logic;                              --! new transmit data, only one clock cycle high
            BSY     : out   std_logic                               --! UART active
        );
end entity tiny_uart;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of tiny_uart is

    -----------------------------
    -- Constants
    constant c_num_debounce         : integer := 2*DEBOUNCE + 1;                                --! only odd number of stages to have always majority
    constant c_num_debounce_sync    : integer := RXSYNC + c_num_debounce;                       --! generate only odd number of stages to have always majority
    constant c_baudrate_generator   : integer := integer(round(real(CLK_HZ)/real(BAUD_BPS)));   --! calulate required clock divider
    -----------------------------


    -----------------------------
    -- Signals
    signal swp_tx           : std_logic_vector(TX'range);                       --! swap bits to meet uart spec
    signal bsy_tx           : std_logic;                                        --! transmission active
    signal sync_debounce    : std_logic_vector(c_num_debounce_sync-1 downto 0); --! sync and debounce input
    signal rx_bit           : std_logic;                                        --! voted rx-bit
    signal bsy_rx           : std_logic;                                        --! recieve active
    signal swp_rx           : std_logic_vector(RX'range);                       --! help signal to swap bits
    signal rx_voter         : std_logic_vector(c_num_debounce-1 downto 0);      --! help signal to relax bit selection
    -----------------------------


    -----------------------------
    -- Functions
        --
        -- swap bits
        -- src: https://www.thecodingforums.com/threads/swapping-bits-in-a-byte.496443/
    function swap_bits (arg: std_logic_vector) return std_logic_vector is
        variable result: std_logic_vector(arg'reverse_range);
    begin
        for i in arg'range loop
            result(i) := arg(i);
        end loop;
        return result;
    end swap_bits;
        --
        -- major voter
    function major_voter (arg: std_logic_vector) return std_logic is
        variable num_once   : integer range 0 to arg'length;
        variable treshold   : integer := integer(floor(real(arg'length)/2.0));
        variable result     : std_logic;
        variable arg_01     : unsigned(arg'range);
    begin
        num_once    := 0;
        arg_01      := to_01(unsigned(arg));
        for i in arg'low to arg'high loop
            if ( arg_01(i) = '1' ) then
                num_once := num_once + 1;
            end if;
        end loop;
        if ( num_once > treshold ) then
            result := '1';
        else
            result := '0';
        end if;
        return result;
    end function major_voter;
    -----------------------------

begin

    ----------------------------------------------
    -- Warning: Baudrate misssetting
    p_chk_baudrate : process
        constant total_bits_per_frame   : integer   := DWIDTH + STOPBIT + 1;                                                                --! +1 Startbit
        constant ideal_bit_duration     : real      := real(CLK_HZ)/real(BAUD_BPS);                                                         --! calculate ideal divider
        constant error_per_bit_rel      : real      := (real(c_baudrate_generator) - real(ideal_bit_duration)) / real(ideal_bit_duration);  --! calc deviation per bit
        constant error_total_rel        : real      := real(error_per_bit_rel) * real(total_bits_per_frame);                                --! caclulate total relative error
    begin
        if ( abs(error_total_rel) >= 0.0 and abs(error_total_rel) <= 0.1 ) then
            null;                                                       --! all is perfect
        elsif ( abs(error_total_rel) > 0.1 and abs(error_total_rel) <= 0.25 ) then
            Report "Relative bit error exceeds 10%" severity warning;   --! can work
        elsif ( abs(error_total_rel) > 0.25 and abs(error_total_rel) <= 0.5 ) then
            Report "Relative bit error exceeds 25%" severity error;     --! high probability that it will not work
        else
            Report "Relative bit error exceeds 50%" severity failure;   --! will never work
        end if;
        wait;
    end process p_chk_baudrate;
    ----------------------------------------------


    ----------------------------------------------
    -- UART Tx Path
    i_uart_tx : entity work.tiny_uart_tx
        generic map (
                        CLKDIV  => c_baudrate_generator,    --! divider to get baud rate
                        DWIDTH  => DWIDTH,                  --! data width
                        STOPBIT => STOPBIT                  --! stopbits
                    )
        port map    (
                        R   => R,       --! asnychon reset
                        C   => C,       --! master clock
                        LD  => TXCE,    --! load buffer with new data word, only one clock high
                        MTY => TXMTY,   --! buffer register empty, ready for next data word
                        BSY => bsy_tx,  --! shift register active
                        SO  => TXD,     --! serial data out
                        DI  => swp_tx   --! parallel data input
                    );
        -- help
        swp_tx  <= swap_bits(TX);   --! bit swapping
    ----------------------------------------------


    ----------------------------------------------
    -- Sync & Debounce
    i_rx_sync_debounce : entity work.tiny_uart_sfr
        generic map (
                        DWIDTH  => sync_debounce'length,    --! data width of shift register
                        RST_SFR => '1'                      --! reset value of shift register
                    )
        port map    (
                        R   => R,                   --! asnychon reset
                        C   => C,                   --! clock, rising edge
                        LD  => '0',                 --! load parallel data input in shift register
                        EN  => '1',                 --! enable shift registers forward shift
                        SD  => RXD,                 --! serial in
                        SQ  => open,                --! in Qs MSB also
                        D   => (others => '1'),     --! parallel data input
                        Q   => sync_debounce        --! capture rest of input
                    );
        -- help
        rx_voter    <= sync_debounce(sync_debounce'left downto sync_debounce'left-(c_num_debounce-1));  --! extract for voter input
        rx_bit      <= major_voter(rx_voter);                                                           --! extract bits after sync stage for voter input
    ----------------------------------------------


    ----------------------------------------------
    -- UART Rx Path
    i_uart_rx : entity work.tiny_uart_rx
        generic map (
                        CLKDIV  => c_baudrate_generator,    --! divider to get baud rate
                        DWIDTH  => DWIDTH,                  --! data width
                        STOPBIT => STOPBIT                  --! number of stopbit
                    )
        port map    (
                        R      => R,        --! asnychon reset, high-active
                        C      => C,        --! master clock, rising-edge
                        DNEW   => RXCE,     --! new data available, one clock cyle high
                        BSY    => bsy_rx,   --! shift register active
                        FRMERO => FRMERO,   --! framing error
                        SI     => rx_bit,   --! serial data in
                        DO     => swp_rx    --! Parallel data output
                    );
        -- help
        RX  <= swap_bits(swp_rx);   --! swap bits to meet UART
    ----------------------------------------------


    ----------------------------------------------
    -- assignments
        -- busy
    BSY <= bsy_rx or bsy_tx;    --! signal rx/tx activity
    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
