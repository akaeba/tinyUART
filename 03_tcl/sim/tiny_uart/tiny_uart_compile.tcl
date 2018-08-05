##************************************************************************
## @copyright   LGPLv3
## @author      akae
##
## @file        tiny_uart_compile.tcl
##
## @brief       compile script
## @details
##
## @date        2018-08-05
## @version     0.1
##************************************************************************



# path setting
#
set path_tb "../02_tb"
set path_src "../01_src"
#



# Compile Design
#
vcom -93 $path_src/tiny_uart_sfr.vhd
vcom -93 $path_src/tiny_uart_cntr.vhd
vcom -93 $path_src/tiny_uart_tx.vhd
vcom -93 $path_src/tiny_uart_rx.vhd
vcom -93 $path_src/tiny_uart.vhd
#


# Compile TB
#
vcom -93 $path_tb/tiny_uart_tb.vhd
#
