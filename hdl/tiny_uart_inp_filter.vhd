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
-- @file:           tiny_uart_inp_filter.vhd
-- @date:           2021-05-22
--
-- @see:            https://github.com/akaeba/tinyUART
-- @brief:          input synchronization and hysteresis
--
--                  synchronizes data input and applies an hysteresis
--                  function to filter out false-latches caused by ESD
--                  events
--************************************************************************



--------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_misc.and_reduce;
    use ieee.std_logic_misc.nor_reduce;
    use ieee.math_real.realmax;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- Synchronizer and filter stage
entity tiny_uart_inp_filter is
generic (
            SYNC_STAGES     : integer range 0 to 3  := 2;       --! synchronizer stages;                                                                        0: not implemented
            VOTER_STAGES    : natural range 0 to 11 := 3;       --! number of ff stages for voter; if all '1' out is '1', if all '0' out '0', otherwise hold;   0: not implemented
            O_RST           : bit                   := '1';     --! output in reset
            RST_ACTIVE      : bit                   := '1'      --! Reset active level
        );
port    (
            -- Clock/Reset
            R       : in    std_logic;  --! asynchronous reset
            C       : in    std_logic;  --! clock, rising edge
            -- Data
            INP     : in    std_logic;  --! filter input
            OUTP    : out   std_logic   --! filter output
        );
end entity tiny_uart_inp_filter;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of tiny_uart_inp_filter is

    ----------------------------------------------
    -- Signals
    ----------------------------------------------
        signal rsff_set     : std_logic;                                                                --! sets RSFF
        signal rsff_reset   : std_logic;                                                                --! reset RSFF
        signal sync_ffs     : std_logic_vector(integer(realmax(real(SYNC_STAGES-1), 0.0)) downto 0);    --! synchronization flip flops
        signal synced       : std_logic;                                                                --! synchronizer stage output
        signal voter_ffs    : std_logic_vector(integer(realmax(real(VOTER_STAGES-1), 0.0)) downto 0);   --! SFR for voter input
    ----------------------------------------------

begin

    ----------------------------------------------
    -- Sync stage
    ----------------------------------------------

        --***************************
        -- Implemented
        g_sync : if SYNC_STAGES > 1 generate
            -- flip flop
            p_sync_ff : process( R, C )
            begin
                if ( R = to_stdulogic(RST_ACTIVE) ) then
                    sync_ffs <= (others => to_stdulogic(O_RST));
                elsif ( rising_edge(C) ) then
                    sync_ffs <= sync_ffs(sync_ffs'left-1 downto sync_ffs'right) & INP;
                end if;
            end process p_sync_ff;
            -- output
            synced <= sync_ffs(sync_ffs'left);
        end generate g_sync;
        --***************************

        --***************************
        -- Skipped
        g_skip_sync : if SYNC_STAGES <= 1 generate
            synced <= INP;
        end generate g_skip_sync;
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- Voter stage
    ----------------------------------------------

        --***************************
        -- Implemented
        g_voter : if VOTER_STAGES > 1 generate
            -- filter flip flop
            p_voter_ff : process( R, C )
            begin
                if ( R = to_stdulogic(RST_ACTIVE) ) then
                    voter_ffs <= (others => to_stdulogic(O_RST));
                elsif ( rising_edge(C) ) then
                    voter_ffs <= voter_ffs(voter_ffs'left-1 downto voter_ffs'right) & synced;
                end if;
            end process p_voter_ff;
            -- voter output
            rsff_set    <= and_reduce(voter_ffs);   --! no ringing on line
            rsff_reset  <= nor_reduce(voter_ffs);
            -- rs-ff
            p_rsff : process( R, C )
            begin
                if ( R = to_stdulogic(RST_ACTIVE) ) then
                    OUTP <= to_stdulogic(O_RST);
                elsif ( rising_edge(C) ) then
                    if ( ('1' = rsff_set) and ('0' = rsff_reset) ) then
                        OUTP <= '1';
                    elsif ( ('0' = rsff_set) and ('1' = rsff_reset) ) then
                        OUTP <= '0';
                    end if;
                end if;
            end process p_rsff;
        end generate g_voter;
        --***************************

        --***************************
        -- Skipped
        g_skip_voter : if VOTER_STAGES <= 1 generate
            OUTP <= synced;
        end generate g_skip_voter;
        --***************************

    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
