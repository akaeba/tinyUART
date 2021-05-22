##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           tiny_uart_inp_filter-compile-runsim.tcl
## @date:           2021-05-22
##
## @brief:          starts simulation
##
##                  Modelsim: Tools -> TCL -> Execute Macro
##************************************************************************



# start simulation, disable optimization
vsim -novopt -gDO_ALL_TEST=true -t 1ps work.tiny_uart_inp_filter_tb

# load Waveform
do "../tcl/sim/tiny_uart_inp_filter/tiny_uart_inp_filter-waveform.do"

# sim until finish
run 2.5 us
