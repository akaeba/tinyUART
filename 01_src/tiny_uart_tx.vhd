--************************************************************************
-- @copyright   LGPLv3
-- @author      akae
--
-- @file        tiny_uart_tx.vhd
-- @note        VHDL'93
--
-- @brief       TX
-- @details     uart transmitter with single stage buffer register
--
-- @date        2018-07-18
-- @version     0.1
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use IEEE.math_real.ceil;
    use IEEE.math_real.log2;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- Parity calculation
entity tiny_uart_tx is
generic (
            CLKDIV  : positive              := 20;      --! builds baud rate
            DWIDTH  : positive              := 8;       --! data width
            ENAPAR  : boolean               := false;   --! parity check            true : enable;  false : disable
            EVENPAR : bit                   := '1';     --! selects parity mode;    '1' : Even Parity; '0' : Odd Parity
            STOPBIT : integer range 1 to 2  := 1        --! number of stopbit
        );
port    (
            -- Clock/Reset
            R       : in    std_logic;                          --! asnychon reset
            C       : in    std_logic;                          --! master clock
            -- Control
            WR      : in    std_logic;                          --! Write new data
            MTY     : out   std_logic;                          --! buffer register empty
            BSY     : out   std_logic;                          --! shift register active
            -- Data
            SO      : out   std_logic;                          --! serial data out
            DI      : in    std_logic_vector(DWIDTH-1 downto 0) --! Parallel data input
        );
end entity tiny_uart_tx;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of tiny_uart_tx is

    -----------------------------
    -- Typs
        type t_tiny_uart_tx is  (
                                    IDLE_S, --! IDLE state
                                    LD_S,   --! load new data
                                    TX_S    --! transmit data
                                );
    -----------------------------


    -----------------------------
    -- Constants
        constant C_BAUD_CNTR_W  : integer                                   := integer(ceil(log2(real(CLKDIV+1))));                             --! counter bit width
        constant C_BIT_CNTR_NUM : integer                                   := DWIDTH+STOPBIT+1+1+1;                                            --! +1 for start, +1 for parity, +1 to avoid overflows
        constant C_BIT_CNTR_W   : integer                                   := integer(ceil(log2(real(C_BIT_CNTR_NUM))));                       --! calculate counter bit width
        constant C_BIT_CNTR_PST : std_logic_vector(C_BIT_CNTR_W-1 downto 0) := std_logic_vector(to_unsigned(C_BIT_CNTR_NUM-1, C_BIT_CNTR_W));   --! bit counter preset
        constant C_SFR_W        : integer                                   := integer(DWIDTH+1+1);                                             --! +1 for start, +1 for parity
    -----------------------------


    -----------------------------
    -- Signals
        signal baud_cntr_cnt    : std_logic_vector(C_BAUD_CNTR_W-1 downto 0);   --! baud rate counter count
        signal baud_cntr_ovl    : std_logic;                                    --! reload baud rate counter
        signal baud_cntr_ena    : std_logic;                                    --! enable counter
        signal bit_cntr_cnt     : std_logic_vector(C_BIT_CNTR_W-1 downto 0);    --! bit counter count
        signal data_reg         : std_logic_vector(DWIDTH-1 downto 0);          --! data hold reg
        signal data_reg_new     : std_logic;                                    --! flag for new data available
        signal current_state    : t_tiny_uart_tx;                               --! fsm states
        signal next_state       : t_tiny_uart_tx;                               --!
        signal ld_tx            : std_logic;                                    --! load for next tranmission cycle
        signal dat_tx           : std_logic_vector(C_SFR_W-1 downto 0);         --! sfr load
        signal parity           : std_logic;                                    --! parity of input data
    -----------------------------

begin

    ----------------------------------------------
    -- baud rate generation
    i_baud_cntr : entity work.tiny_uart_cntr
        generic map (
                        WIDTH   => baud_cntr_cnt'length --! width of counter
                    )
        port map    (
                        R   => R,               --! asnychon reset
                        C   => C,               --! clock
                        LD  => baud_cntr_ovl,   --! load value
                        EN  => baud_cntr_ena,
                        UP  => '1',             --! count direction;    '1' : upcounting; '0' downcounting
                        SET => (others => '0'), --! load value
                        CNT => baud_cntr_cnt    --! actual count value
                    );
        -- help logic
        baud_cntr_ovl <= '1' when ( to_01(unsigned(baud_cntr_cnt)) > CLKDIV-1 ) else '0';   --! counter overflow
        baud_cntr_ena <= '1' when ( current_state = TX_S) else '0';                             --! transmission active
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
                        LD  => ld_tx,           --! load value
                        EN  => baud_cntr_ovl,   --! new bit released
                        UP  => '0',             --! count direction;    '1' : upcounting; '0' downcounting
                        SET => C_BIT_CNTR_PST,  --! load value
                        CNT => bit_cntr_cnt     --! actual count value
                    );
    ----------------------------------------------


    ----------------------------------------------
    -- shift forward register
    i_sfr : entity work.tiny_uart_sfr
        generic map (
                        DWIDTH  => dat_tx'length,   --! data width of shift register
                        RST_SFR => '1'              --! reset value of shift register
                    )
        port map    (
                        R   => R,               --! asnychon reset
                        C   => C,               --! clock, rising edge
                        LD  => ld_tx,           --! load parallel data input in shift register
                        EN  => baud_cntr_ovl,   --! enable shift registers forward shift
                        SD  => '1',             --! serial data input, idle is one
                        SQ  => SO,              --! serial data output
                        D   => dat_tx,          --! parallel data input
                        Q   => open             --! parallel data output
                    );
        -- glue logic
        dat_tx  <=  '0' & data_reg & parity;                    --! build data vector to load
        ld_tx   <=  '1' when ( current_state = LD_S ) else '0'; --! load bit counter and sfr
    ----------------------------------------------


    ----------------------------------------------
    -- parity caclculation
    g_with_parity : if ( ENAPAR = true ) generate
        i_parity : entity work.tiny_uart_parity
            generic map (
                            EVEN_PARITY => EVENPAR, --! selects parity mode;    '1' : Even Parity; '0' : Odd Parity
                            DWIDTH      => DWIDTH   --! width of data input
                        )
            port map    (
                            D => DI,        --! input data for parity calculation
                            P => parity     --! calculated parity
                        );
    end generate g_with_parity;

    g_wo_parity : if ( ENAPAR = false ) generate
        parity  <=  '1';    -- stuck to idle level
    end generate g_wo_parity;
    ----------------------------------------------


    ----------------------------------------------
    -- registers
    p_register : process ( R, C )
    begin
        if ( R = '1' ) then
            data_reg        <= (others => '0'); --! data hold reg
            data_reg_new    <= '0';             --! mark new data available
            current_state   <= IDLE_S;          --! reset state

        elsif ( rising_edge(C) ) then
            -- data input handler
            if ( (WR = '1') and (data_reg_new = '0') ) then
                data_reg        <= DI;      --! capture input data
                data_reg_new    <= '1';     --! set new data marker
            elsif ( ld_tx = '1' ) then
                data_reg_new    <= '0';     --! clear data new flag
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
                                data_reg_new,   --! new data available
                                bit_cntr_cnt,   --! pending bits
                                baud_cntr_ovl   --! baud rate counter overflows
                            )
    begin
        next_state  <= current_state;   --! default assignment

        -- next state calculation
        case current_state is

            -- wait for request
            when IDLE_S =>
                if ( data_reg_new = '1' ) then
                    next_state  <= LD_S;
                else
                    next_state  <= IDLE_S;
                end if;

            -- load data value
            when LD_S =>
                next_state <= TX_S;

            -- send data
            when TX_S =>
                if ( (to_01(unsigned(bit_cntr_cnt)) = 0) and (baud_cntr_ovl = '1') ) then
                    if ( data_reg_new = '1' ) then
                        next_state  <= LD_S;
                    else
                        next_state  <= IDLE_S;
                    end if;
                else
                    next_state <= TX_S;
                end if;

            -- default path
            when others =>
                next_state  <= IDLE_S;

        end case;
    end process p_nxt_state;
    ----------------------------------------------


    ----------------------------------------------
    -- assignements
    MTY <= not data_reg_new;    --! signalling empty buffer register
    BSY <= '0' when ( current_state = IDLE_S ) else '0';
    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
