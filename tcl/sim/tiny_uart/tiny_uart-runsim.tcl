##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           tiny_uart-runsim.tcl
## @date:           2018-08-09
##
## @brief:          starts simulation
##
##                  Modelsim: Tools -> TCL -> Execute Macro
##************************************************************************


# start simulation, disable optimization
vsim -novopt -gDO_ALL_TEST=true -t 1ps work.tiny_uart_tb

# load Waveform
do "../tcl/sim/tiny_uart/tiny_uart-waveform.do"

# sim until finish
run 3.5 ms
