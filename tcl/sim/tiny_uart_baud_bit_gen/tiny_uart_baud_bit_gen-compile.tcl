##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           tiny_uart_baud_bit_gen-compile.tcl
## @date:           2021-05-28
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
vcom -93 $path_src/tiny_uart_baud_bit_gen.vhd
#


# Compile TB
#
vcom -93 $path_tb/tiny_uart_baud_bit_gen_tb.vhd
#
