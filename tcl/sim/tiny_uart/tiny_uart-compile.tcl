##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           tiny_uart-compile.tcl
## @date:           2018-08-05
##
## @brief:          compile script
##
##                  Modelsim: Tools -> TCL -> Execute Macro
##************************************************************************



# path setting
#
set path_tb "../tb"
set path_src "../hdl"
#



# Compile Design
#
vcom -93 $path_src/tiny_uart_sfr.vhd
vcom -93 $path_src/tiny_uart_cntr.vhd
vcom -93 $path_src/tiny_uart_inp_filter.vhd
vcom -93 $path_src/tiny_uart_baud_bit_gen.vhd
vcom -93 $path_src/tiny_uart_tx.vhd
vcom -93 $path_src/tiny_uart_rx.vhd
vcom -93 $path_src/tiny_uart.vhd
#


# Compile TB
#
vcom -93 $path_tb/tiny_uart_tb.vhd
#
