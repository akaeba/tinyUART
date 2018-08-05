onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Ports
add wave -noupdate /tiny_uart_tb/DUT/R
add wave -noupdate /tiny_uart_tb/DUT/C
add wave -noupdate /tiny_uart_tb/DUT/TXD
add wave -noupdate /tiny_uart_tb/DUT/RXD
add wave -noupdate /tiny_uart_tb/DUT/FRMERO
add wave -noupdate -radix hexadecimal /tiny_uart_tb/DUT/RX
add wave -noupdate /tiny_uart_tb/DUT/RXCE
add wave -noupdate -radix hexadecimal /tiny_uart_tb/DUT/TX
add wave -noupdate /tiny_uart_tb/DUT/TXMTY
add wave -noupdate /tiny_uart_tb/DUT/TXCE
add wave -noupdate /tiny_uart_tb/DUT/BSY
add wave -noupdate -divider Internal
add wave -noupdate -radix hexadecimal /tiny_uart_tb/DUT/swp_tx
add wave -noupdate /tiny_uart_tb/DUT/bsy_tx
add wave -noupdate /tiny_uart_tb/DUT/sync_debounce
add wave -noupdate /tiny_uart_tb/DUT/sync_debounce_sq
add wave -noupdate /tiny_uart_tb/DUT/sync_debounce_q
add wave -noupdate /tiny_uart_tb/DUT/rx_bit
add wave -noupdate /tiny_uart_tb/DUT/bsy_rx
add wave -noupdate -radix hexadecimal /tiny_uart_tb/DUT/swp_rx
add wave -noupdate /tiny_uart_tb/DUT/c_baudrate_generator
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {193590 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 240
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
WaveRestoreZoom {0 ps} {7318656 ps}
