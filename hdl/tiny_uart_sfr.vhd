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
-- @file:           tiny_uart_sfr.vhd
-- @date:           2018-07-15
--
-- @see:            https://github.com/akaeba/tinyUART
-- @brief:          SFR
--
--                  Shift forward register
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- shift forward register
entity tiny_uart_sfr is
generic (
            DWIDTH  : positive  := 8;   --! data width of shift register
            RST_SFR : bit       := '1'  --! reset value of shift register
        );
port    (
            -- Clock/Reset
            R       : in    std_logic;                              --! asnychon reset
            C       : in    std_logic;                              --! clock, rising edge
            -- Control
            LD      : in    std_logic;                              --! load parallel data input in shift register
            EN      : in    std_logic;                              --! enable shift registers forward shift
            -- Data
            SD      : in    std_logic;                              --! serial data input
            SQ      : out   std_logic;                              --! serial data output
            D       : in    std_logic_vector(DWIDTH-1 downto 0);    --! parallel data input
            Q       : out   std_logic_vector(DWIDTH-1 downto 0)     --! parallel data output
        );
end entity tiny_uart_sfr;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of tiny_uart_sfr is

    -----------------------------
    -- signal
    -----------------------------
        signal sfr_q    : std_logic_vector(DWIDTH-1 downto 0);  --! registered sfr signal
    -----------------------------

begin

    ----------------------------------------------
    -- shift register
    p_sfr : process ( R, C )
    begin
        if ( R = '1' ) then
            sfr_q   <=  (others => to_stdulogic(RST_SFR));  --! reset register, all zero or one
        elsif ( rising_edge(C) ) then
            if ( LD = '1' ) then
                sfr_q   <=  D;  --! load parallel input
            elsif ( EN = '1' ) then
                sfr_q   <=  sfr_q(sfr_q'left-1 downto 0) & SD;  --! shift and latch new input
            end if;
        end if;
    end process p_sfr;
    ----------------------------------------------

    ----------------------------------------------
    -- Assignments
    Q   <=  sfr_q;              --! assign parallel to world
    SQ  <=  sfr_q(sfr_q'left);  --! assign serial to world
    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
