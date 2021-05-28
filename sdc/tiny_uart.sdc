##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           tiny_uart.sdc
## @date:           2018-08-13
##
## @see:            https://github.com/akaeba/tinyUART
## @brief:          Design constraints
##
##************************************************************************


# Primary Clocks
#
create_clock -name clk50 -period 20.000 [get_ports {C}]
#


# Calculate Clock Uncertainty
# SRC: http://quartushelp.altera.com/14.1/mergedProjects/tafs/tafs/tcl_pkg_sdc_ext_ver_1.0_cmd_derive_clock_uncertainty.htm
#
derive_clock_uncertainty
#


# Input Delay
#
set_input_delay -clock {clk50} 5.0 [get_ports {TR[*] THRL RXD}];
#


# Output Delay
#
set_output_delay -add_delay -clock {clk50} 5.0 [get_ports {TXD RR[*] PE FE DR THRE TRE}];
#


# False paths
#
set_false_path -from *                  -to [get_pins -compatibility_mode *i_tiny_uart_inp_filter|sync_ffs[0]|d];   # UART is always asynchron, therefore false path
set_false_path -from [get_ports {R}]    -to *;                                                                      # Reset, cause at the moment no RST sync
#
