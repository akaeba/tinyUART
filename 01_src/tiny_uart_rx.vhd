--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        tiny_uart_rx.vhd
-- @note        VHDL'93
--
-- @brief       RX
-- @details     uart treciever with single stage buffer register
--
-- @date        2018-07-26
-- @version     0.1
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use IEEE.math_real.ceil;
    use IEEE.math_real.log2;
    use IEEE.std_logic_misc.and_reduce;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- RX path
entity tiny_uart_rx is
generic (
            CLKDIV  : positive              := 20;      --! builds baud rate
            DWIDTH  : positive              := 8;       --! data width
            STOPBIT : integer range 1 to 2  := 1;       --! number of stopbit
            NUMSYNC : integer range 2 to 3  := 2        --! number of sync stages at data input
        );
port    (
            -- Clock/Reset
            R       : in    std_logic;                          --! asnychon reset
            C       : in    std_logic;                          --! master clock
            -- Control
            DNEW    : out   std_logic;                          --! new data available, one clock cyle high
            BSY     : out   std_logic;                          --! shift register active
            FRMERO  : out   std_logic;                          --! framing error
            -- Data
            SI      : in    std_logic;                          --! serial data in
            DO      : out   std_logic_vector(DWIDTH-1 downto 0) --! Parallel data output
        );
end entity tiny_uart_rx;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of tiny_uart_rx is

    -----------------------------
    -- Typs
        type t_tiny_uart_rx is  (
                                    IDLE_S, --! IDLE state
                                    SMPL_S, --! databit middle
                                    WTRX_S, --! wait data edge
                                    NEW_S   --! release data
                                );
    -----------------------------


    -----------------------------
    -- Constants
        constant C_BAUD_CNTR_W  : integer   := integer(ceil(log2((real(CLKDIV)/2.0)+1.0))); --! counter bit width; divided by two, casue sampling point needs to be in the middle of data bit
        constant C_SFR_W        : integer   := integer(DWIDTH+STOPBIT+1);                   --! +1 for start
        constant C_BIT_CNTR_W   : integer   := integer(ceil(log2(real(C_SFR_W+1))));        --! calc counter width; +1 to avoid overflows
    -----------------------------


    -----------------------------
    -- Signals
        signal si_sync          : std_logic_vector(NUMSYNC downto 0);           --! baud rate counter count, +1 for edge detection
        signal start_bit        : std_logic;                                    --! start bit detected
        signal si_01            : std_logic;                                    --! help signal
        signal baud_cntr_cnt    : std_logic_vector(C_BAUD_CNTR_W-1 downto 0);   --! baud rate counter count
        signal baud_cntr_ovl    : std_logic;                                    --! baud rate counter overflows
        signal baud_cntr_ld     : std_logic;                                    --! preset counter
        signal baud_cntr_ena    : std_logic;                                    --! enable counter
        signal current_state    : t_tiny_uart_rx;                               --! fsm states
        signal next_state       : t_tiny_uart_rx;                               --!
        signal sfr_rx           : std_logic_vector(C_SFR_W-1 downto 0);         --! shift register output
        signal bit_cntr_cnt     : std_logic_vector(C_BIT_CNTR_W-1 downto 0);    --! bit counter count
        signal bit_cntr_ld      : std_logic;                                    --! load bit counter
        signal bit_cntr_pst     : std_logic_vector(bit_cntr_cnt'range);         --! preset
        signal sample_bit       : std_logic;                                    --! samples bit and decrements bit counter
        signal data_rcv         : std_logic_vector(DWIDTH-1 downto 0);          --! recieved data
        signal framing_ero      : std_logic;                                    --! framing error
    -----------------------------

begin

    ----------------------------------------------
    -- shift forward register
    i_sync : entity work.tiny_uart_sfr
        generic map (
                        DWIDTH  => si_sync'length,  --! data width of shift register
                        RST_SFR => '1'              --! reset value of shift register
                    )
        port map    (
                        R   => R,               --! asnychon reset
                        C   => C,               --! clock, rising edge
                        LD  => '0',             --! load parallel data input in shift register
                        EN  => '1',             --! enable shift registers forward shift
                        SD  => si_01,           --! serial data input, idle is one
                        SQ  => open,            --! serial data output
                        D   => (others => '0'), --! parallel data input
                        Q   => si_sync          --! parallel data output
                    );
        -- help
        si_01       <=  to_stdulogic(to_bit(SI));                                   --! reduce 7 stage logic to zero/one, avoids warning
        start_bit   <=  si_sync(si_sync'left) and (not (si_sync(si_sync'left-1)));  --! detect falling edge
    ----------------------------------------------


    ----------------------------------------------
    -- baud rate generation
    i_baud_cntr : entity work.tiny_uart_cntr
        generic map (
                        WIDTH   => baud_cntr_cnt'length --! width of counter
                    )
        port map    (
                        R   => R,               --! asnychon reset
                        C   => C,               --! clock
                        LD  => baud_cntr_ld,    --! load value
                        EN  => baud_cntr_ena,   --! enable counting
                        UP  => '1',             --! count direction;    '1' : upcounting; '0' downcounting
                        SET => (others => '0'), --! load value
                        CNT => baud_cntr_cnt    --! actual count value
                    );
        -- help logic
            -- overflow
        baud_cntr_ovl   <= '1' when ( to_01(unsigned(baud_cntr_cnt)) > CLKDIV/2-1 ) else '0';

            -- preset counter
        with current_state select baud_cntr_ld <=
            baud_cntr_ovl   when SMPL_S,
            baud_cntr_ovl   when WTRX_S,
            '1'             when IDLE_S,
            '0'             when others;

            -- enable counting
        with current_state select baud_cntr_ena <=
            '1' when SMPL_S,
            '1' when WTRX_S,
            '0' when others;
    ----------------------------------------------


    ----------------------------------------------
    -- bit cntr
    i_bit_cntr : entity work.tiny_uart_cntr
        generic map (
                        WIDTH   => bit_cntr_cnt'length  --! width of counter
                    )
        port map    (
                        R   => R,               --! asnychon reset
                        C   => C,               --! clock
                        LD  => bit_cntr_ld,     --! load value
                        EN  => sample_bit,      --! new bit released
                        UP  => '0',             --! count direction;    '1' : upcounting; '0' downcounting
                        SET => bit_cntr_pst,    --! load value
                        CNT => bit_cntr_cnt     --! actual count value
                    );
        -- glue
        bit_cntr_ld     <= '1' when ( current_state = IDLE_S ) else '0';
        bit_cntr_pst    <= std_logic_vector(to_unsigned(C_SFR_W-1, bit_cntr_pst'length));
    ----------------------------------------------


    ----------------------------------------------
    -- shift forward register
    i_sfr : entity work.tiny_uart_sfr
        generic map (
                        DWIDTH  => sfr_rx'length,   --! data width of shift register
                        RST_SFR => '0'              --! reset value of shift register
                    )
        port map    (
                        R   => R,                       --! asnychon reset
                        C   => C,                       --! clock, rising edge
                        LD  => '0',                     --! load parallel data input in shift register
                        EN  => sample_bit,              --! enable shift registers forward shift
                        SD  => si_sync(si_sync'left),   --! serial data input, idle is one
                        SQ  => open,                    --! serial data output
                        D   => (others => '0'),         --! parallel data input
                        Q   => sfr_rx                   --! parallel data output
                    );
        -- glue logic
        sample_bit  <= baud_cntr_ovl when ( current_state = SMPL_S ) else '0';  --! capture data
    ----------------------------------------------


    ----------------------------------------------
    -- registers
    p_register : process ( R, C )
    begin
        if ( R = '1' ) then
            DO              <= (others => '0'); --! data hold reg
            FRMERO          <= '0';             --! signal framing error
            current_state   <= IDLE_S;          --! reset state
            DNEW            <= '0';             --! new data

        elsif ( rising_edge(C) ) then
            -- output data
            if ( current_state = NEW_S ) then
                DO      <= data_rcv;    --! assign data to world
                FRMERO  <= framing_ero; --! framing error
            end if;

            -- set flag
            if ( current_state = NEW_S ) then
                DNEW    <= '1';
            else
                DNEW    <= '0';
            end if;

            -- FSM
            current_state   <= next_state;  --! state update

        end if;
    end process p_register;
    ----------------------------------------------


    ----------------------------------------------
    -- next state calculation
    p_nxt_state : process   (
                                current_state,  --! actual state
                                start_bit,      --! new data fram detected
                                baud_cntr_ovl,  --! counter overflow
                                bit_cntr_cnt    --! pending bits
                            )
    begin
        next_state  <= current_state;   --! default assignment

        -- next state calculation
        case current_state is

            -- wait for request
            when IDLE_S =>
                if ( start_bit = '1' ) then
                    next_state  <= SMPL_S;
                else
                    next_state  <= IDLE_S;
                end if;

            -- sample phase, middle of bit
            when SMPL_S =>
                if ( baud_cntr_ovl = '1' ) then
                    if ( to_01(unsigned(bit_cntr_cnt)) = 0 ) then
                        next_state  <= NEW_S;
                    else
                        next_state  <= WTRX_S;
                    end if;
                else
                    next_state  <= SMPL_S;
                end if;

            -- wait, half periode to set sample point in middle
            when WTRX_S =>
                if ( baud_cntr_ovl = '1' ) then
                    next_state  <= SMPL_S;
                else
                    next_state  <= WTRX_S;
                end if;

            -- release new data
            when NEW_S =>
                next_state  <= IDLE_S;

            -- default path
            when others =>
                next_state  <= IDLE_S;

        end case;

    end process p_nxt_state;
    ----------------------------------------------


    ----------------------------------------------
    -- assignments
		-- busy
    with current_state select BSY <=
        '0' when IDLE_S,
        '1' when others;

        -- recieved data
    data_rcv    <= sfr_rx(sfr_rx'left-1 downto sfr_rx'left-1-DWIDTH+1);                             --! extract data bits
    framing_ero <= not ((not sfr_rx(sfr_rx'left)) and (and_reduce(sfr_rx(STOPBIT-1 downto 0))));    --! expects startbit zero, stopbits one, otherwise error flag
    ----------------------------------------------




end architecture rtl;
--------------------------------------------------------------------------
