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
-- @see:			https://cdn.opencores.org/downloads/wbspec_b4.pdf
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
--    Status/Control:
--             7      6      5      4      3      2      1      0
--          +------+------+------+------+------+------+------+------+
--    +0x1  | '0'  | '0'  | '0'  | PE   | FE   | BSY  | IRQ  | IE   |
--          +------+------+------+------+------+------+------+------+
--                                 R/W0   R/W0   R      R/W0   R/W
--                                 '0'    '0'    '0'    '0'    '0'
--
--             PE  - Parity Error, clear write zero
--             FE  - Framing error, clear write zero
--             BSY - Busy (RX and/or TX active)
--             IRQ - Interrupt Request, needs to be cleared after ISR
--             IE  - Interrupt enable
--
--    FIFO:
--             7      6      5      4      3      2      1      0
--          +------+------+------+------+------+------+------+------+
--    +0x2  |    SIZE     | TFO  | TFE  | TFF  | RFO  | RFE  | RFF  |
--          +------+------+------+------+------+------+------+------+
--                 R        R/W0   R      R      R/W0   R      R
--                "--"      '0'    '1'    '0'    '0'    '1'    '0'
--
--             SIZE - FIFO size
--                      0d :  0 Byte
--                      1d : 16 Byte
--                      2d : 32 Byte
--                      3d : 64 Byte 
--             TFO  - Transmit FIFO overflow, clear write zero
--             TFE  - Transmit FIFO empty
--             TFF  - Transmit FIFO full
--             RFO  - Receive FIFO overflow, clear write zero
--             RFE  - Receive FIFO empty
--             RFF  - Receive FIFO full
--
--    Configuration (Compile):
--             7      6      5      4      3      2      1      0
--          +------+------+------+------+------+------+------+------+
--    +0x3  | TX   | RX   |     PAR     | SBS  |        BPS         |
--          +------+------+------+------+------+------+------+------+
--             R      R          R        R             R
--            '-'    '-'        "--"     '-'          "---"
--
--             TX  - Transmit path implemented
--             RX  - Receive path implemented
--             PAR - Parity mode
--                      0d : None
--                      1d : Odd
--                      2d : Even
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
            FIFO	: integer range 0 to 3	:= 0;			--! FIFO size									[ integer ]
			SBS     : integer range 1 to 2  := 1;           --! Stop bit select, only one/two stopbit       [ integer ]
            PAR		: integer range 0 to 2  := 0;			--! Parity mode									[ integer ]
            TXIMPL  : boolean               := true;        --! implement UART TX path                      [ boolean ]
            RXIMPL  : boolean               := true         --! implement UART RX path                      [ boolean ]
        );
port    (
			-- Wishbone
			CLK_I   : in    std_logic;                      --! Clock
			RST_I   : in    std_logic;                      --! Synchronous reset (active high)
			CYC_I   : in    std_logic;                      --! Valid bus cycle indication
			STB_I   : in    std_logic;                      --! Slave selection
			ACK_O   : out 	std_logic;                      --! Acknowledge output
			WE_I    : in    std_logic;                      --! Write enable
			SEL_I	: in	std_logic_vector(3 downto 0);	--! Byteselect
			DAT_I   : in    std_logic_vector(31 downto 0);  --! Data input
			DAT_O   : out 	std_logic_vector(31 downto 0);	--! Data output
			-- Misc
			IRQ		: out	std_logic;	--! interrupt request, high active
			BRC		: in	std_logic;	--! Baud rate counter, enables UART bit engine; common clock divider usage
			-- UART
            TXD     : out   std_logic;	--! transmit register output (START bit, DATA bits, PARITY bit, and STOP bits);     LSB First
            RXD     : in    std_logic	--! receive data;   LSB first
		);
end entity tiny_uart_wb32;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of tiny_uart_wb32 is

    ----------------------------------------------
    -- Constants
    ----------------------------------------------	
		-- bit indexes
			-- Status/Control
		cPE		: integer := 4;	--! Parity error
		cFE		: integer := 3;	--! Framing error
		cBSY	: integer := 2;	--! Busy
		cIRQ	: integer := 1;	--! interrupt request
		cIE		: integer := 0;	--! interrupt enable
			-- FIFO
		cSZH	: integer := 7;	--! Size High bit
		cSZL	: integer := 6; --! Size Low bit
		cTFO	: integer := 5;	--! Transmit FIFO overflow
		cTFE	: integer := 4; --! transmit FIFO empty
		cTFF	: integer := 3;	
		cRFO	: integer := 2; --! Receive FIFO overflow
		cRFE	: integer := 1; --! Receive FIFO empty
		cRFF	: integer := 
		
		
--             7      6      5      4      3      2      1      0
--          +------+------+------+------+------+------+------+------+
--    +0x2  |    SIZE     | TFO  | TFE  | TFF  | RFO  | RFE  | RFF  |
--          +------+------+------+------+------+------+------+------+
--                 R        R/W0   R      R      R/W0   R      R
--                "--"      '0'    '1'    '0'    '0'    '1'    '0'		
		
		
		
		
		
		-- byte Indexes
		cDATA	: integer := 0;	--! +0x0 Data offset
		cSTS	: integer := 1;	--! +0x1 Status/control offset
		cFIFO	: integer := 2;	--! +0x2 FIFO offset
		cCFG	: integer := 3;	--! +0x3 Configuration offset
	----------------------------------------------	


    ----------------------------------------------
    -- Signals
    ----------------------------------------------	
		-- UART Core
		signal no_parity	: boolean;
		signal even_parity	: boolean;
		signal rst_sync		: std_logic;
		signal rx_data		: std_logic_vector(7 downto 0);	--! UART receive data
		-- FIFO & Flow control
		signal rx_new		: std_logic;	--! New receive data available flag
		signal rx_new_set	: std_logic;	--! set rx_new
		signal rx_new_rst	: std_logic;	--! clear rx_new
		
		-- Register
		signal reg_status_control	: std_logic_vector(7 downto 0);	--! read path Status/Control register
		signal reg_fifo				: std_logic_vector(7 downto 0);	--! read path FIFO register
		signal reg_config			: std_logic_vector(7 downto 0);	--! read path silicon configuration
		signal rd_data				: std_logic;					--! read from data register		+cDATA
		signal rd_sts				: std_logic;					--! read from status register	+cSTS
		signal rd_fifo				: std_logic;					--! read from FIFO register		+cFIFO
		signal rd_cfg				: std_logic;					--! read from CFG register		+cCFG
		
		
		
		
		
		-- wishbone ITF
		signal ack		: std_logic;	--! wishbone acknowledge
		signal wr		: std_logic;	--! write to UART
		signal rd		: std_logic;	--! read from UART
		-- register set
		signal irq_i	: std_logic;	--! interrupt request flag
		signal irq_set	: std_logic;	--! set IRQ flag
		signal irq_rst	: std_logic;	--! reset IRQ flag
		signal fe_i		: std_logic;	--! framing error flag
		signal fe_set	: std_logic;	--! set FE flag
		signal fe_rst	: std_logic;	--! reset FE flag
		signal pe_i		: std_logic;	--! parity error flag
		signal pe_set	: std_logic;	--! set PE flag
		signal pe_rst	: std_logic;	--! reset PE flag
		
	----------------------------------------------
		
	
	
begin

    ----------------------------------------------
    -- Reset Synchronizer
    ----------------------------------------------
	p_rst : process( CLK_I )
	begin
		if ( rising_edge(CLK_I) ) then 
			rst_sync <= RST_I;	--! tiny UART uses FFs with asynchrony reset input
		end if;
	end process p_rst;
	----------------------------------------------


    ----------------------------------------------
    -- Wishbone ITF
    ----------------------------------------------

        --***************************
        -- Glue
		ACK_O	<= ack;										--! internal/external required
		-- @see Illustration 3-5: Classic standard SINGLE READ cycle, wbspec_b4.pdf
		wr		<= STB_I and CYC_I and ack and WE_I;		--! internal write signal
		rd		<= STB_I and CYC_I and ack and (not WE_I);	--! read from UART
		rd_data	<= rd and SEL_I(cDATA);	--! read from data register		+0x0
		rd_sts	<= rd and SEL_I(cSTS);	--! read from status register	+0x1
		rd_fifo	<= rd and SEL_I(cFIFO);	--! read from FIFO register		+0x2
		rd_cfg	<= rd and SEL_I(cCFG);	--! read from configuration		+0x3
		-- IRQ
		IRQ	<= irq_i and irq_ena;	--! signal IRQ only when interrupt is enabled
		--***************************
	
        --***************************
        -- Data output
		DAT_O(cDATA*8+7 downto cDATA*8)	<= rx_data				when ( '1' = rd_data )	else (others => '0');	--! enable byte on bus
		DAT_O(cSTS*8+7 downto cSTS*8)	<= reg_status_control	when ( '1' = rd_sts ) 	else (others => '0');	--!
		DAT_O(cFIFO*8+7 downto cFIFO*8)	<= reg_fifo				when ( '1' = rd_fifo ) 	else (others => '0');	--!
		DAT_O(cCFG*8+7 downto cCFG*8)	<= 
		--***************************
		
        --***************************
        -- ACK
		-- @see Illustration 3-3: Standard wishbone handshaking protocol, synchronous slave., wbspec_b4.pdf
		p_ack : process( CLK_I )
		begin
			if ( rising_edge(CLK_I) ) then 
				if ( '1' = RST_I ) then
					ack	<= '0';
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
					irq_i	<= '0';
					fe_i	<= '0';
					pe_i	<= '0';
					rx_new	<= '0';
					irq_ena	<= '0';
				else
					-- RSFF: IRQ
					if ( '1' = irq_set ) then
						irq_i <= '1';
					elsif ( '1' = irq_rst ) then
						irq_i <= '0';
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
					-- DFF: IRQ enable
					if ( ('1' = wr) and ('1' = SEL_I(cSTS)) ) then
						irq_ena <= DAT_I(cSTS*8+cIE);
					end if;
					
					
				end if;
			end if;
		end process p_reg;
		--***************************
		
		
		--***************************
		-- RSFF combinatoric
			-- IRQ
		irq_set	<= rx_new_set;
			-- FE
		fe_rst	<= wr and SEL_I(cSTS) and (not DAT_I(cSTS*8+cFE));	--! W0 for clear
			-- PE
		pe_rst	<= wr and SEL_I(cSTS) and (not DAT_I(cSTS*8+cPE));	--! W0 for clear
			-- rx_new
		rx_new_rst <= rd_data;	--! read from UART core
		--***************************
		
		
        --***************************
        -- Bit packing
		--   Status Control
		reg_status_control(7 downto 5)	<= "000";	--! RFU
		reg_status_control(cPE)			<= pe_i;	--! parity error flag
		reg_status_control(cFE)			<= fe_i;	--! framing error flag
		reg_status_control(cBSY)		<= '0';		--! TODO
		reg_status_control(cIRQ)		<= irq_i;	--! IRQ, R/W0
		reg_status_control(cIE)			<= irq_ena;	--! interrupt enable
		--  FIFO // Dataflow
		reg_fifo
		
		--***************************
	
		--***************************
        -- PE / FE / IRQ

	
	
	
	
	
	

		

    ----------------------------------------------
    -- UART Core
    ----------------------------------------------
	i_tiny_uart : entity work.tiny_uart
		generic map	(
						WLS    => 8,			--! word length select; number of data bits
						CLK    => CLK,			--! master clock frequency in Hz
						BPS    => BPS,			--! transceiver baud rate in Bps
						SBS    => SBS,			--! Stop bit select, only one/two stopbit
						PI     => no_parity,	--! Parity inhibit, true: inhibit
						EPE    => even_parity,	--! Even parity enable, true: even, false: odd
						DEBU   => 3,			--! Number of debouncer stages
						TXIMPL => TXIMPL,		--! implement UART TX path
						RXIMPL => RXIMPL		--! implement UART RX path
					)
		port map	(
						R    => rst_sync,	--! FF's with asynchrony reset
						C    => CLK_I,		--! clock, rising edge
						TXD  => TXD,		--! serial transmit register output (START bit, DATA bits, PARITY bit, and STOP bits);     LSB First
						RXD  => RXD,		--! serial receive data;   LSB first
						RR   => rx_data,	--! Receiver Holding Register Data Output
						PE   => pe_set,		--! Parity error
						FE   => fe_set,		--! Framing error
						DR   => rx_new_set,	--! Data Received, one clock cycle high
						TR   => TR,
						THRE => THRE,
						THRL => tx_new,		--! Transmitter Holding Register Load, one clock cycle high
						TRE  => TRE
					);	
		-- Parity
		no_parity	<= true	when ( 0 = PAR ) else false;
		even_parity	<= true when ( 2 = PAR ) else false;
	----------------------------------------------



					
entity tiny_uart is
generic (
            WLS     : integer range 5 to 8  := 8;           --! word length select; number of data bits     [ integer ]
            CLK     : positive              := 50_000_000;  --! master clock frequency in Hz                [ integer ]
            BPS     : positive              := 115200;      --! transceiver baud rate in Bps                 [ integer ]
            SBS     : integer range 1 to 2  := 1;           --! Stop bit select, only one/two stopbit       [ integer ]
            PI      : boolean               := true;        --! Parity inhibit, true: inhibit               [ boolean ]
            EPE     : boolean               := true;        --! Even parity enable, true: even, false: odd  [ boolean ]
            DEBU    : integer range 0 to 11 := 3;           --! Number of debouncer stages                  [ integer ]
            TXIMPL  : boolean               := true;        --! implement UART TX path                      [ boolean ]
            RXIMPL  : boolean               := true                               [ boolean ]
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
            TR      : in    std_logic_vector(WLS-1 downto 0);   --! Transmitter Holding Register Data Input
            THRE    : out   std_logic;                          --! Transmitter Holding Register Empty
            THRL    : in    std_logic;                          --! Transmitter Holding Register Load, one clock cycle high
            TRE     : out   std_logic                           --! Transmitter Register Empty
        );
end entity tiny_uart;
					
					
					
					




end architecture rtl;
--------------------------------------------------------------------------
