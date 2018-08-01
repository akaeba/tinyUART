##************************************************************************
## @copyright   LGPLv3
## @author      akae
##
## @file        tiny_uart_rx_runsim.tcl
## @note
##
## @brief       starts simulation
## @details
##
## @date        2018-08-01
## @version     0.1
##************************************************************************



# start simulation, disable optimization
vsim -novopt -gDO_ALL_TEST=true work.tiny_uart_rx_tb

# load Waveform
do "../03_tcl/sim/tiny_uart_rx/tiny_uart_rx_waveform.do"

# sim until finish
run 250 ms
