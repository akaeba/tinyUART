--************************************************************************
-- @author:         Andreas Kaeberlein
-- @copyright:      Copyright 2022
-- @credits:        AKAE
--
-- @license:        BSDv3
-- @maintainer:     Andreas Kaeberlein
-- @email:          andreas.kaeberlein@web.de
--
-- @note:           VHDL'93
-- @file:           tiny_uart_wb32.vhd
-- @date:           2022-06-12
--
-- @see:            https://github.com/akaeba/tinyUART
-- @see:            https://cdn.opencores.org/downloads/wbspec_b4.pdf
-- @brief:          Wishbone UART core (toplevel)
--
--                  Wishbone (32bit) interfaced
--                  UART Transmitter and Receiver
--************************************************************************



--
-- Important Hints:
-- ================
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
--  Register Map (Base address)
--  ---------------------------
--
--    Data register:
--             7      6      5      4      3      2      1      0
--          +------+------+------+------+------+------+------+------+
--    +0x0  |                          Data                         |
--          +------+------+------+------+------+------+------+------+
--                                     R/W
--                                 "00000000"
--
--    Status:
--             7      6      5      4      3      2      1      0
--          +------+------+------+------+------+------+------+------+
--    +0x1  | PE   | FE   | TFE  | TFF  | RFO  | RFE  | RFF  | IRQ  |
--          +------+------+------+------+------+------+------+------+
--            R/W0   R/W0    R      R     R/W0    R      R     R/W0
--            '0'    '0'    '1'    '0'    '0'    '1'    '0'    '0'
--
--             PE  - Parity Error, clear write zero
--             FE  - Framing error, clear write zero
--             TFE  - Transmit FIFO empty
--             TFF  - Transmit FIFO full
--             RFO  - Receive FIFO overflow, clear write zero
--             RFE  - Receive FIFO empty
--             RFF  - Receive FIFO full
--             IRQ - Interrupt Request, needs to be cleared after ISR
--
--    Control:
--             7      6      5      4      3      2      1      0
--          +------+------+------+------+------+------+------+------+
--    +0x2  | '0'  | '0'  | '0'  |        SIZE        | BSY  | IE   |
--          +------+------+------+------+------+------+------+------+
--                                         R            R      R/W
--                                       "---"          '0'    '0'
--
--             SIZE - FIFO size = 2^(SIZE) in Bytes
--                      0d :   1 Byte
--                      1d :   2 Byte
--                      2d :   4 Byte
--                      3d :   8 Byte
--                      4d :  16 Byte
--                      5d :  32 Byte
--                      6d :  64 Byte
--                      7d : 128 Byte
--             BSY - Busy (RX and/or TX active)
--             IE  - Interrupt enable
--
--    Configuration (Compile):
--             7      6      5      4      3      2      1      0
--          +------+------+------+------+------+------+------+------+
--    +0x3  | TX   | RX   |     PAR     | SBS  |        BPS         |
--          +------+------+------+------+------+------+------+------+
--             R      R          R         R             R
--            '-'    '-'        "--"      '-'          "---"
--
--             TX  - Transmit path implemented
--             RX  - Receive path implemented
--             PAR - Parity mode
--                      0d : None
--                      1d : Even
--                      3d : Odd
--             SBS - Stopbit select
--                      0d : 1Bit
--                      1d : 2Bit
--             BPS - Transfer Speed
--                      0d : 9600
--                      1d : 19200
--                      2d : 38400
--                      3d : 57600
--                      4d : 115200
--                      5d : 230400
--                     15d : Custom
--



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- tiny UART
entity tiny_uart_wb32 is
generic (
            CLK     : positive              := 50_000_000;  --! UART clock frequency                        [ integer ]
            BPS     : positive              := 115200;      --! transceive baud rate in Bps                 [ integer ]
            FIFO    : integer range 0 to 3  := 0;           --! FIFO size                                   [ integer ]
            SBS     : integer range 1 to 2  := 1;           --! Stop bit select, only one/two stopbit       [ integer ]
            ENPA    : boolean               := false;       --! enable parity                               [ boolean ]
            ODDPA   : boolean               := false;       --! odd parity                                  [ boolean ]
            TXIMPL  : boolean               := true;        --! implement UART TX path                      [ boolean ]
            RXIMPL  : boolean               := true         --! implement UART RX path                      [ boolean ]
        );
port    (
            -- Wishbone
            CLK_I   : in    std_logic;                      --! Clock
            RST_I   : in    std_logic;                      --! Synchronous reset (active high)
            CYC_I   : in    std_logic;                      --! Valid bus cycle indication
            STB_I   : in    std_logic;                      --! Slave selection
            ACK_O   : out   std_logic;                      --! Acknowledge output
            WE_I    : in    std_logic;                      --! Write enable
            SEL_I   : in    std_logic_vector(3 downto 0);   --! Byteselect
            DAT_I   : in    std_logic_vector(31 downto 0);  --! Data input
            DAT_O   : out   std_logic_vector(31 downto 0);  --! Data output
            -- Misc
            IRQ     : out   std_logic;  --! interrupt request, high active
            BRC     : in    std_logic;  --! Baud rate counter, enables UART bit engine; common clock divider usage
            -- UART
            TXD     : out   std_logic;  --! transmit register output (START bit, DATA bits, PARITY bit, and STOP bits);     LSB First
            RXD     : in    std_logic   --! receive data;   LSB first
        );
end entity tiny_uart_wb32;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of tiny_uart_wb32 is

    ----------------------------------------------
    -- Constants
    ----------------------------------------------
        -- bit indexes
            -- Status
        constant cPE    : integer := 7; --! Parity error
        constant cFE    : integer := 6; --! Framing error
        constant cTFE   : integer := 5; --! transmit FIFO empty
        constant cTFF   : integer := 4; --! transmit FIFO full
        constant cRFO   : integer := 3; --! Receive FIFO overflow
        constant cRFE   : integer := 2; --! Receive FIFO empty
        constant cRFF   : integer := 1; --! receive FIFO full
        constant cIRQ   : integer := 0; --! interrupt request
            -- Control
        constant cSZH   : integer := 4; --! Size High bit
        constant cSZL   : integer := 2; --! Size Low bit
        constant cBSY   : integer := 1; --! Busy
        constant cIE    : integer := 0; --! interrupt enable
            -- Config
        constant cTX    : integer := 7; --! Transmit path implemented
        constant cRX    : integer := 6; --! Receive path implemented
        constant cPARH  : integer := 5; --! Parity mode (High Bit)
        constant cPARL  : integer := 4; --! Parity mode (Low Bit)
        constant cSBS   : integer := 3; --! Stopbit select
        constant cBPSH  : integer := 2; --! Transfer Speed (High Bit)
        constant cBPSL  : integer := 0; --! Transfer Speed (Low Bit)
        -- byte Indexes
        constant cDATA  : integer := 0; --! +0x0 Data offset
        constant cSTS   : integer := 1; --! +0x1 Status/control offset
        constant cCTRL  : integer := 2; --! +0x2 FIFO offset
        constant cCFG   : integer := 3; --! +0x3 Configuration offset
    ----------------------------------------------


    ----------------------------------------------
    -- Signals
    ----------------------------------------------
        -- UART Core
        signal rst_sync     : std_logic;
        signal rx_data      : std_logic_vector(7 downto 0); --! UART receive data
        signal tx_new       : std_logic;                    --! new data from wishbone ITF
        signal tx_empty     : std_logic;                    --! uart core is ready for new data
        -- FIFO & Flow control
        signal rx_new           : std_logic;    --! New receive data available flag
        signal rx_new_set       : std_logic;    --! set rx_new
        signal rx_new_rst       : std_logic;    --! clear rx_new
        signal rfo              : std_logic;    --! Receive FIFO overflow
        signal rfo_set          : std_logic;    --! set
        signal rfo_rst          : std_logic;    --! clear
        signal irq_ena          : std_logic;    --! IRQ signaling enabled
        signal tx_empty_dly1    : std_logic;    --! set IRQ only one time
        -- Register
        signal reg_status   : std_logic_vector(7 downto 0); --! read path Status/Control register
        signal reg_ctrl     : std_logic_vector(7 downto 0); --! read path FIFO register
        signal reg_cfg      : std_logic_vector(7 downto 0); --! read path silicon configuration
        signal rd_data      : std_logic;                    --! read from data register     +cDATA
        signal rd_sts       : std_logic;                    --! read from status register   +cSTS
        signal rd_ctrl      : std_logic;                    --! read from FIFO register     +cCTRL
        signal rd_cfg       : std_logic;                    --! read from CFG register      +cCFG
        -- wishbone ITF
        signal ack      : std_logic;    --! wishbone acknowledge
        signal wr       : std_logic;    --! write to UART
        signal rd       : std_logic;    --! read from UART
        -- register set
        signal irq_i    : std_logic;    --! interrupt request flag
        signal irq_set  : std_logic;    --! set IRQ flag
        signal irq_rst  : std_logic;    --! reset IRQ flag
        signal fe_i     : std_logic;    --! framing error flag
        signal fe_set   : std_logic;    --! set FE flag
        signal fe_rst   : std_logic;    --! reset FE flag
        signal pe_i     : std_logic;    --! parity error flag
        signal pe_set   : std_logic;    --! set PE flag
        signal pe_rst   : std_logic;    --! reset PE flag
    ----------------------------------------------

begin

    ----------------------------------------------
    -- Reset Synchronizer
    ----------------------------------------------
    p_rst : process( CLK_I )
    begin
        if ( rising_edge(CLK_I) ) then
            rst_sync <= RST_I;  --! tiny UART uses FFs with asynchrony reset input
        end if;
    end process p_rst;
    ----------------------------------------------


    ----------------------------------------------
    -- Wishbone ITF
    ----------------------------------------------

        --***************************
        -- Glue
        ACK_O   <= ack;                                     --! internal/external required
        -- @see Illustration 3-5: Classic standard SINGLE READ cycle, wbspec_b4.pdf
        wr      <= STB_I and CYC_I and ack and WE_I;        --! internal write signal
        rd      <= STB_I and CYC_I and ack and (not WE_I);  --! read from UART
        rd_data <= rd and SEL_I(cDATA); --! data register     +0x0
        rd_sts  <= rd and SEL_I(cSTS);  --! status register   +0x1
        rd_ctrl <= rd and SEL_I(cCTRL); --! control register  +0x2
        rd_cfg  <= rd and SEL_I(cCFG);  --! configuration     +0x3
        -- IRQ
        IRQ <= irq_i and irq_ena;   --! signal IRQ only when interrupt is enabled
        --***************************

        --***************************
        -- Data output
        DAT_O(cDATA*8+7 downto cDATA*8) <= rx_data      when ( '1' = rd_data )  else (others => '0');   --! enable byte on bus
        DAT_O(cSTS*8+7 downto cSTS*8)   <= reg_status   when ( '1' = rd_sts )   else (others => '0');   --!
        DAT_O(cCTRL*8+7 downto cCTRL*8) <= reg_ctrl     when ( '1' = rd_ctrl )  else (others => '0');   --!
        DAT_O(cCFG*8+7 downto cCFG*8)   <= reg_cfg      when ( '1' = rd_cfg )   else (others => '0');   --!
        --***************************

        --***************************
        -- Data Input
        tx_new  <= wr and SEL_I(cDATA); --! write to Data
        --***************************

        --***************************
        -- ACK
        -- @see Illustration 3-3: Standard wishbone handshaking protocol, synchronous slave., wbspec_b4.pdf
        p_ack : process( CLK_I )
        begin
            if ( rising_edge(CLK_I) ) then
                if ( '1' = RST_I ) then
                    ack <= '0';
                else
                    if ( '0' = ack ) then
                      ack <= STB_I and CYC_I;
                    else
                      ack <= '0';
                    end if;
                end if;
            end if;
        end process p_ack;
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- Register Set
    ----------------------------------------------
        --***************************
        -- Register
        p_reg : process( CLK_I )
        begin
            if ( rising_edge(CLK_I) ) then
                if ( '1' = RST_I ) then
                    -- RSFF
                    irq_i           <= '0';
                    fe_i            <= '0';
                    pe_i            <= '0';
                    rx_new          <= '0';
                    irq_ena         <= '0';
                    rfo             <= '0';
                    tx_empty_dly1   <= '1'; -- out of reset is UART tx empty
                else
                    -- RSFF: IRQ
                    if ( '1' = irq_rst ) then   --! reset dominant, in IRQ controller is PEDGE used, if reset source isn't serviced, reset is after clear asserted again
                        irq_i <= '0';
                    elsif ( '1' = irq_set ) then
                        irq_i <= '1';
                    end if;
                    -- RSFF: FE
                    if ( '1' = fe_set ) then
                        fe_i <= '1';
                    elsif ( '1' = fe_rst ) then
                        fe_i <= '0';
                    end if;
                    -- RSFF: PE
                    if ( '1' = pe_set ) then
                        pe_i <= '1';
                    elsif ( '1' = pe_rst ) then
                        pe_i <= '0';
                    end if;
                    -- RSFF: rx_new
                    if ( '1' = rx_new_set ) then
                        rx_new <= '1';
                    elsif ( '1' = rx_new_rst ) then
                        rx_new <= '0';
                    end if;
                    -- RSFF: RFO
                    if ( '1' = rfo_set ) then
                        rfo <= '1';
                    elsif ( '1' = rfo_rst ) then
                        rfo <= '0';
                    end if;
                    -- DFF: IRQ enable
                    if ( ('1' = wr) and ('1' = SEL_I(cSTS)) ) then
                        irq_ena <= DAT_I(cSTS*8+cIE);
                    end if;
                    -- DFF: tx empty
                    tx_empty_dly1 <= tx_empty;
                end if;
            end if;
        end process p_reg;
        --***************************


        --***************************
        -- RSFF combinatoric
            -- IRQ
        irq_set <= rx_new_set or (tx_empty and (not tx_empty_dly1));    --! new rx value or rising edge of tx empty
            -- FE
        fe_rst  <= wr and SEL_I(cSTS) and (not DAT_I(cSTS*8+cFE));  --! W0 for clear
            -- PE
        pe_rst  <= wr and SEL_I(cSTS) and (not DAT_I(cSTS*8+cPE));  --! W0 for clear
            -- rx_new
        rx_new_rst <= rd_data;  --! read from UART core
            -- RFO
        rfo_set <= rx_new and rx_new_set;
        rfo_rst <= wr and SEL_I(cCTRL) and (not DAT_I(cCTRL*8+cRFO));   --! W0 for clear
        --***************************


        --***************************
        -- Bit packing
        --   Status
        reg_status(cPE)     <= pe_i             when ( true = RXIMPL ) else '0';    --! parity error flag
        reg_status(cFE)     <= fe_i             when ( true = RXIMPL ) else '0';    --! framing error flag
        reg_status(cTFE)    <= tx_empty         when ( true = TXIMPL ) else '1';    --! transmit FIFO empty
        reg_status(cTFF)    <= not (tx_empty)   when ( true = TXIMPL ) else '0';    --! transmit FIFO full
        reg_status(cRFO)    <= rfo              when ( true = RXIMPL ) else '0';    --! Receive FIFO overflow
        reg_status(cRFE)    <= not (rx_new)     when ( true = RXIMPL ) else '1';    --! Receive FIFO empty
        reg_status(cRFF)    <= rx_new           when ( true = RXIMPL ) else '0';    --! receive FIFO full
        reg_status(cIRQ)    <= irq_i;                                               --! IRQ, R/W0
        --  Control
        reg_ctrl(7 downto 5)        <= "000";   --! RFU
        reg_ctrl(cSZH downto cSZL)  <= std_logic_vector(to_unsigned(FIFO, cSZH-cSZL+1));    --! selected FIFO size
        reg_ctrl(cBSY)              <= '0';     --! TODO
        reg_ctrl(cIE)               <= irq_ena; --! interrupt enable
        -- Silicon Configuration
        reg_cfg(cTX)    <= '1'  when ( true = TXIMPL )  else '0';   --! Transmit path implemented
        reg_cfg(cRX)    <= '1'  when ( true = RXIMPL )  else '0';   --! Receive path implemented
        reg_cfg(cPARH)  <= '1'  when ( true = ODDPA )   else '0';   --! Parity mode
        reg_cfg(cPARL)  <= '1'  when ( true = ENPA )    else '0';   --! Parity enable
        reg_cfg(cSBS)   <= '1'  when ( 2 = SBS )        else '0';   --! Stopbit select
        with BPS select reg_cfg(cBPSH downto cBPSL) <=
            std_logic_vector(to_unsigned(00, cBPSH-cBPSL+1))    when 9600,
            std_logic_vector(to_unsigned(01, cBPSH-cBPSL+1))    when 19200,
            std_logic_vector(to_unsigned(02, cBPSH-cBPSL+1))    when 38400,
            std_logic_vector(to_unsigned(03, cBPSH-cBPSL+1))    when 57600,
            std_logic_vector(to_unsigned(04, cBPSH-cBPSL+1))    when 115200,
            std_logic_vector(to_unsigned(05, cBPSH-cBPSL+1))    when 230400,
            (others => '1')                                     when others;
        --***************************
    ----------------------------------------------


    ----------------------------------------------
    -- UART Core
    ----------------------------------------------
    i_tiny_uart : entity work.tiny_uart
        generic map (
                        WLS    => 8,            --! word length select; number of data bits
                        CLK    => CLK,          --! master clock frequency in Hz
                        BPS    => BPS,          --! transceiver baud rate in Bps
                        SBS    => SBS,          --! Stop bit select, only one/two stopbit
                        PI     => not ENPA,     --! Parity inhibit, true: inhibit
                        EPE    => not ODDPA,    --! Even parity enable, true: even, false: odd
                        DEBU   => 3,            --! Number of debouncer stages
                        TXIMPL => TXIMPL,       --! implement UART TX path
                        RXIMPL => RXIMPL        --! implement UART RX path
                    )
        port map    (
                        R    => rst_sync,                           --! FF's with asynchrony reset
                        C    => CLK_I,                              --! clock, rising edge
                        TXD  => TXD,                                --! serial transmit register output (START bit, DATA bits, PARITY bit, and STOP bits);     LSB First
                        RXD  => RXD,                                --! serial receive data;   LSB first
                        RR   => rx_data,                            --! Receiver Holding Register Data Output
                        PE   => pe_set,                             --! Parity error
                        FE   => fe_set,                             --! Framing error
                        DR   => rx_new_set,                         --! Data Received, one clock cycle high
                        TR   => DAT_I(cDATA*8+7 downto cDATA*8),    --! Transmitter Holding Register Data Input
                        THRE => tx_empty,                           --! Transmitter Holding Register Empty
                        THRL => tx_new,                             --! Transmitter Holding Register Load, one clock cycle high
                        TRE  => open                                --! Transmitter Register Empty
                    );
    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
