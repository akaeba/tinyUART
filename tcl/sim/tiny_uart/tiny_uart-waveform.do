onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Main
add wave -noupdate /tiny_uart_tb/DUT/c_baud_clkdiv2
add wave -noupdate /tiny_uart_tb/DUT/R
add wave -noupdate /tiny_uart_tb/DUT/C
add wave -noupdate /tiny_uart_tb/DUT/BSY
add wave -noupdate -radix hexadecimal /tiny_uart_tb/p_stimuli_process/buf
add wave -noupdate -divider Serial
add wave -noupdate /tiny_uart_tb/DUT/TXD
add wave -noupdate /tiny_uart_tb/DUT/RXD
add wave -noupdate -divider Parallel
add wave -noupdate -radix hexadecimal /tiny_uart_tb/TR
add wave -noupdate /tiny_uart_tb/THRE
add wave -noupdate /tiny_uart_tb/THRL
add wave -noupdate -radix hexadecimal /tiny_uart_tb/RR
add wave -noupdate /tiny_uart_tb/PE
add wave -noupdate /tiny_uart_tb/FE
add wave -noupdate /tiny_uart_tb/DR
add wave -noupdate -divider TX
add wave -noupdate /tiny_uart_tb/DUT/tx_sfr_ld
add wave -noupdate /tiny_uart_tb/DUT/tx_sfr_shift
add wave -noupdate -radix hexadecimal /tiny_uart_tb/DUT/tx_sfr
add wave -noupdate -radix hexadecimal /tiny_uart_tb/DUT/tx_hold
add wave -noupdate /tiny_uart_tb/DUT/tx_hold_empty
add wave -noupdate /tiny_uart_tb/DUT/tx_hold_new
add wave -noupdate /tiny_uart_tb/DUT/g_tx/i_tx_baud_bit_gen/current_state
add wave -noupdate /tiny_uart_tb/DUT/g_tx/i_tx_baud_bit_gen/next_state
add wave -noupdate -divider RX
add wave -noupdate /tiny_uart_tb/DUT/rx_nedge
add wave -noupdate -radix hexadecimal /tiny_uart_tb/DUT/rx_sfr
add wave -noupdate /tiny_uart_tb/DUT/rx_sfr_shift
add wave -noupdate /tiny_uart_tb/DUT/rx_sfr_cap
add wave -noupdate -radix hexadecimal /tiny_uart_tb/DUT/rx_hold
add wave -noupdate /tiny_uart_tb/DUT/fe_comb
add wave -noupdate /tiny_uart_tb/DUT/pe_comb
add wave -noupdate /tiny_uart_tb/DUT/g_rx/i_rx_baud_bit_gen/current_state
add wave -noupdate /tiny_uart_tb/DUT/g_rx/i_rx_baud_bit_gen/next_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {178441011 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 394
configure wave -valuecolwidth 82
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1026404494 ps}
