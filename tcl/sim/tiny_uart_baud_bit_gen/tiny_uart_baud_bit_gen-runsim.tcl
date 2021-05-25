##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           tiny_uart_baud_bit_gen-runsim.tcl
## @date:           2021-05-25
##
## @brief:          starts simulation
##
##                  Modelsim: Tools -> TCL -> Execute Macro
##************************************************************************


# start simulation, disable optimization
vsim -novopt -gDO_ALL_TEST=true -t 1ps work.tiny_uart_baud_bit_gen_tb

# load Waveform
do "../tcl/sim/tiny_uart_baud_bit_gen/tiny_uart_baud_bit_gen-waveform.do"

# sim until finish
run 40 us
