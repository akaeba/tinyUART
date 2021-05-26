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
-- @file:           tiny_uart_baud_bit_gen.vhd
-- @date:           2021-05-23
--
-- @see:            https://github.com/akaeba/tinyUART
-- @brief:          Baudrate and bit generator
--
--                  Generates shift clock for SFR as well
--                  data flow control signals
--************************************************************************



--------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.log2;
    use ieee.math_real.ceil;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- baudrate und bit generator
entity tiny_uart_baud_bit_gen is
generic (
            NUMBIT          : positive  := 10;      --! number of bits to handle
            CLKDIV2         : positive  := 8;       --! half bit period clock divider, TBIT = 2*CLKDIV2
            SKIP_LAST_BIT2  : boolean   := false    --! true: skips in last bit second half periode wait, increases SNR in RX
        );
port    (
            -- Clock/Reset
            R           : in    std_logic;  --! asynchronous reset
            C           : in    std_logic;  --! clock, rising edge
            -- Control
            START       : in    std_logic;  --! transfer started
            BUSY        : out   std_logic;  --! transfer active
            -- SFR
            SFR_LD      : out   std_logic;  --! load parallel input of shift register
            SFR_S_BEGIN : out   std_logic;  --! shift pulse Tbit begin
            SFR_S_MIDLE : out   std_logic;  --! shift pulse Tbit middle
            SFR_CAP     : out   std_logic   --! all bits in shift register transfered
        );
end entity tiny_uart_baud_bit_gen;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of tiny_uart_baud_bit_gen is

    ----------------------------------------------
    -- Constant
    ----------------------------------------------
        constant c_bit_cntr_width   : integer := integer(ceil(log2(real(NUMBIT+1))));   --! bit counter for SFR
        constant c_baud_cntr_width  : integer := integer(ceil(log2(real(CLKDIV2+1))));  --! half clock counter width
    ----------------------------------------------


    ----------------------------------------------
    -- SPI state machine
    ----------------------------------------------
        type t_tiny_uart_baud_bit is
            (
                IDLE,       --! Wait for transfer start
                TRANSFER,   --! Transmission active
                TFEND       --! end transfer
            );
    ----------------------------------------------


    ----------------------------------------------
    -- Signals
    ----------------------------------------------
        -- Baud counter
        signal baud_cntr_cnt        : unsigned(c_baud_cntr_width-1 downto 0);   --! double baud rate counter count
        signal baud_cntr_reset      : std_logic;                                --! clear baud counter value
        signal baud_cntr_preset     : std_logic;                                --! preload with half clock divider value
        signal baud_cntr_en         : std_logic;                                --! enable baut counter
        signal baud_half_per        : std_logic;                                --! distinguish first/second half period
        signal baud_half_per_en     : std_logic;                                --! enable toggle Flip-Flop
        signal baud_cntr_is_zero    : std_logic;                                --! zero count

        -- Bit counter
        signal bit_cntr_cnt     : unsigned(c_bit_cntr_width-1 downto 0);    --! bit counter, needed for FSMs end of shift
        signal bit_cntr_preset  : std_logic;                                --! preload bit counter
        signal bit_cntr_is_zero : std_logic;                                --! has zero count
        signal bit_cntr_en      : std_logic;                                --! enable counters decrement

        -- FSM
        signal current_state    : t_tiny_uart_baud_bit; --! FSM state
        signal next_state       : t_tiny_uart_baud_bit; --! next state
    ----------------------------------------------

begin

    ----------------------------------------------
    -- SCK counter & control
    ----------------------------------------------

        --***************************
        -- Register
        p_baud_cntr : process( R, C )
        begin
            if ( '1' = R ) then
                -- Reset
                baud_cntr_cnt <= (others => '0');   --! double baud rate counter
                baud_half_per <= '1';               --! toggle FF

            elsif ( rising_edge(C) ) then
                -- Baud generator
                if ( '1' = baud_cntr_reset ) then
                    baud_cntr_cnt <= (others => '0');
                elsif ( '1' =  baud_cntr_preset ) then
                    baud_cntr_cnt <= to_unsigned(CLKDIV2-1, baud_cntr_cnt'length);
                elsif ( '1' = baud_cntr_en ) then
                    baud_cntr_cnt <= baud_cntr_cnt-1;
                end if;
                -- Baud half period
                if ( '1' = baud_cntr_reset ) then
                    baud_half_per <= '1';   --! marks first half period of TBIT
                elsif ( '1' = baud_half_per_en ) then
                    baud_half_per <= not baud_half_per;
                end if;

            end if;
        end process p_baud_cntr;
        --***************************

        --***************************
        -- control
        with current_state select                   --! clear counter
            baud_cntr_reset <=  '1' when IDLE,      --! nothing todo
                                '0' when others;    --! counter runs

        with current_state select                                       --! clear counter
            baud_cntr_preset    <=  baud_cntr_is_zero   when TRANSFER,  --! next half period cycle
                                    '0'                 when others;

        with current_state select                   --! enable
            baud_cntr_en    <=  '1' when TRANSFER,  --! count to achieve target baud rate
                                '1' when TFEND,     --! last half baud cycle
                                '0' when others;    --! no count

        with current_state select                                           --! toggle
            baud_half_per_en    <=  baud_cntr_is_zero   when TRANSFER,  --! marks first/second half periode
                                    '0'                 when others;    --! hold

        -- Flags
        baud_cntr_is_zero <= '1' when ( 0 = to_01(baud_cntr_cnt) ) else '0';
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- Bit counter (Regs & Control)
    ----------------------------------------------

        --***************************
        -- Register
        p_bit_cntr : process( R, C )
        begin
            if ( '1' = R ) then
                bit_cntr_cnt    <= (others => '0'); --! Reset

            elsif ( rising_edge(C) ) then
                -- Control
                if ( '1' = bit_cntr_preset ) then   --! next cycle
                    bit_cntr_cnt <= to_unsigned(NUMBIT-1, bit_cntr_cnt'length);
                elsif ( '1' = bit_cntr_en ) then    --! decrement
                    bit_cntr_cnt <= bit_cntr_cnt-1;
                end if;

            end if;
        end process p_bit_cntr;
        --***************************

        --***************************
        -- Control
        with current_state select                                                                           --! reload
            bit_cntr_preset <=  bit_cntr_is_zero and baud_cntr_is_zero and baud_half_per    when TRANSFER,  --! start of cycle, reload output SFR
                                '0'                                                         when others;    --! transfer ongoing or idle

        with current_state select                                               --! enable
            bit_cntr_en <=  baud_cntr_is_zero and baud_half_per when TRANSFER,  --! baud cycle complete generated, next bit
                            '0'                                 when others;    --! hold

        -- Flags
        bit_cntr_is_zero <= '1' when ( 0 = to_01(bit_cntr_cnt) ) else '0';
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- FSM
    ----------------------------------------------

        --***************************
        -- FSM state registers
        p_fsm_reg : process( R, C )
        begin
            if ( '1' = R ) then
                current_state <= IDLE;
            elsif ( rising_edge(C) ) then
                current_state <= next_state;
            end if;
        end process p_fsm_reg;
        --***************************

        --***************************
        -- next state calculation
        p_next_state : process  (
                                    current_state,      --! current FSM state
                                    START,              --! start new transfer
                                    baud_cntr_is_zero,  --! baud counter has reached target value
                                    bit_cntr_is_zero,   --! bit counter is zero
                                    baud_half_per       --! 1: second half of periode
                                )
        begin
            -- default assignment
            next_state  <= current_state;   --! default assignment

            -- state transitions
            case current_state is

                --***************************
                -- wait for start
                when IDLE =>
                    if ( '1' = START ) then
                        next_state <= TRANSFER;
                    else
                        next_state <= IDLE;
                    end if;
                --***************************

                --***************************
                -- transmission
                when TRANSFER =>
                    if ( ('1' = bit_cntr_is_zero) and ('1' = baud_cntr_is_zero) and ('0' = baud_half_per) ) then
                        if ( '1' = START ) then         --! New data is available, run in next cycle
                            next_state <= TRANSFER;
                        else                            --! no new data, go in force wait
                            if ( SKIP_LAST_BIT2 ) then  --! RX Mode
                                next_state <= IDLE;
                            else                        --! TX MOde
                                next_state <= TFEND;
                            end if;
                        end if;
                    else
                        next_state <= TRANSFER;
                    end if;
                --***************************

                --***************************
                -- wait for transmission
                when TFEND =>
                    if ( '1' = baud_cntr_is_zero ) then
                        next_state <= IDLE;
                    else
                        next_state <= TFEND;
                    end if;
                --***************************

                --***************************
                -- Recovering from illegal state transitions
                when others =>
                    next_state <= IDLE;
                --***************************

            end case;
        end process p_next_state;
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- Output
    ----------------------------------------------
        SFR_LD      <= bit_cntr_preset;                                                 --! parallel load of TXD shift register
        SFR_CAP     <= baud_cntr_preset and (not baud_half_per) and bit_cntr_is_zero;   --! capture RX SFR in parallel register
        SFR_S_BEGIN <= baud_cntr_preset and baud_half_per;                              --! TX SFR: shift forward, begin of baud period
        SFR_S_MIDLE <= baud_cntr_preset and (not baud_half_per);                        --! RX SFR: shift forward, middle of baud period

        BUSY <= '0' when ( IDLE = current_state ) else '1'; --! signal activity
    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
