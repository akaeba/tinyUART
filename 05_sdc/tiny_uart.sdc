##************************************************************************
## @copyright   LGPLv3
## @author      akae
##
## @file        tiny_uart.sdc
##
## @brief       Design constraints
## @details
##
## @date        2018-08-13
## @version     0.1
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
set_input_delay -clock {clk50} 5.0 [get_ports {TX[*] TXCE RXD}];
#


# Output Delay
#
set_output_delay -add_delay -clock {clk50} 5.0 [get_ports {TXD FRMERO RX[*] RXCE TXMTY BSY}];
#


# False pathes
#
set_false_path -from *                  -to {tiny_uart_sfr:i_rx_sync_debounce|sfr_q[0]};    # UART is always asynchron, therefore false path
set_false_path -from [get_ports {R}]    -to *;                                              # Reset, cause at the moment no RST sync
#
