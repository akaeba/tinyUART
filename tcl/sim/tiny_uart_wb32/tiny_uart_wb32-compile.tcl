##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2022
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           tiny_uart_wb32-compile.tcl
## @date:           2022-07-02
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
vcom -93 $path_src/tiny_uart_inp_filter.vhd
vcom -93 $path_src/tiny_uart_baud_bit_gen.vhd
vcom -93 $path_src/tiny_uart.vhd
vcom -93 $path_src/tiny_uart_wb32.vhd
#


# Compile TB
#
vcom -93 $path_tb/wishbone_bfm/rtl/io_package.vhd;	# Wishbone BFM
vcom -93 $path_tb/tiny_uart_wb32_tb.vhd
#
