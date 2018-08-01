onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Ports
add wave -noupdate /tiny_uart_rx_tb/R
add wave -noupdate /tiny_uart_rx_tb/C
add wave -noupdate /tiny_uart_rx_tb/DNEW
add wave -noupdate /tiny_uart_rx_tb/BSY
add wave -noupdate /tiny_uart_rx_tb/FRMERO
add wave -noupdate /tiny_uart_rx_tb/SI
add wave -noupdate -radix hexadecimal /tiny_uart_rx_tb/DO
add wave -noupdate -divider FSM
add wave -noupdate /tiny_uart_rx_tb/DUT/current_state
add wave -noupdate /tiny_uart_rx_tb/DUT/next_state
add wave -noupdate /tiny_uart_rx_tb/DUT/sample_bit
add wave -noupdate -divider Counter
add wave -noupdate -radix unsigned /tiny_uart_rx_tb/DUT/baud_cntr_cnt
add wave -noupdate /tiny_uart_rx_tb/DUT/baud_cntr_ovl
add wave -noupdate /tiny_uart_rx_tb/DUT/baud_cntr_ld
add wave -noupdate /tiny_uart_rx_tb/DUT/baud_cntr_ena
add wave -noupdate -radix unsigned /tiny_uart_rx_tb/DUT/bit_cntr_cnt
add wave -noupdate /tiny_uart_rx_tb/DUT/bit_cntr_ld
add wave -noupdate -radix unsigned /tiny_uart_rx_tb/DUT/bit_cntr_pst
add wave -noupdate -divider Data
add wave -noupdate -radix hexadecimal /tiny_uart_rx_tb/DUT/sfr_rx
add wave -noupdate -radix hexadecimal /tiny_uart_rx_tb/DUT/data_rcv
add wave -noupdate /tiny_uart_rx_tb/DUT/framing_ero
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {9530500000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 254
configure wave -valuecolwidth 107
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
WaveRestoreZoom {0 ps} {56847829888 ps}
