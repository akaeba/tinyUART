##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           tiny_uart_inp_filter-compile.tcl
## @date:           2021-05-22
##
## @brief:          compile script
##
##                  Modelsim: Tools -> TCL -> Execute Macro
##************************************************************************



# path setting
#
set proj_dir "../"
#



# Compile Design
#
vcom -93 ${proj_dir}/hdl/tiny_uart_inp_filter.vhd
#



# Compile TB
#
vcom -93 ${proj_dir}/tb/tiny_uart_inp_filter_tb.vhd;
#
