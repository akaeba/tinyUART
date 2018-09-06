##************************************************************************
## @copyright   LGPLv3
## @author      akae
##
## @file        tiny_uart_runsim.tcl
## @note
##
## @brief       starts simulation
## @details
##
## @date        2018-08-09
## @version     0.1
##************************************************************************



# start simulation, disable optimization
vsim -novopt -gDO_ALL_TEST=true -t 1ps work.tiny_uart_tb

# load Waveform
do "../03_tcl/sim/tiny_uart/tiny_uart_waveform.do"

# sim until finish
run 3.5 ms
