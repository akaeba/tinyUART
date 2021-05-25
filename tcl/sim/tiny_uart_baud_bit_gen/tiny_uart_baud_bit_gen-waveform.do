onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Main
add wave -noupdate /tiny_uart_baud_bit_gen_tb/R
add wave -noupdate /tiny_uart_baud_bit_gen_tb/C
add wave -noupdate /tiny_uart_baud_bit_gen_tb/START
add wave -noupdate /tiny_uart_baud_bit_gen_tb/BUSY
add wave -noupdate -divider {SFR Control}
add wave -noupdate /tiny_uart_baud_bit_gen_tb/SFR_LD
add wave -noupdate /tiny_uart_baud_bit_gen_tb/SFR_CAP
add wave -noupdate /tiny_uart_baud_bit_gen_tb/SFR_S_BEGIN
add wave -noupdate /tiny_uart_baud_bit_gen_tb/SFR_S_MIDLE
add wave -noupdate -divider FSM
add wave -noupdate /tiny_uart_baud_bit_gen_tb/DUT/current_state
add wave -noupdate /tiny_uart_baud_bit_gen_tb/DUT/next_state
add wave -noupdate -divider {Baud Counter}
add wave -noupdate -radix unsigned /tiny_uart_baud_bit_gen_tb/DUT/baud_cntr_cnt
add wave -noupdate /tiny_uart_baud_bit_gen_tb/DUT/baud_cntr_reset
add wave -noupdate /tiny_uart_baud_bit_gen_tb/DUT/baud_cntr_preset
add wave -noupdate /tiny_uart_baud_bit_gen_tb/DUT/baud_cntr_en
add wave -noupdate /tiny_uart_baud_bit_gen_tb/DUT/baud_half_per
add wave -noupdate /tiny_uart_baud_bit_gen_tb/DUT/baud_half_per_en
add wave -noupdate /tiny_uart_baud_bit_gen_tb/DUT/baud_cntr_is_zero
add wave -noupdate -divider {Bit Counter}
add wave -noupdate -radix unsigned /tiny_uart_baud_bit_gen_tb/DUT/bit_cntr_cnt
add wave -noupdate /tiny_uart_baud_bit_gen_tb/DUT/bit_cntr_preset
add wave -noupdate /tiny_uart_baud_bit_gen_tb/DUT/bit_cntr_is_zero
add wave -noupdate /tiny_uart_baud_bit_gen_tb/DUT/bit_cntr_en
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {15024298 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 378
configure wave -valuecolwidth 101
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
WaveRestoreZoom {0 ps} {39970302 ps}
