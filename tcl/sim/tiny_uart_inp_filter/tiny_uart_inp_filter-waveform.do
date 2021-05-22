onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Misc
add wave -noupdate /tiny_uart_inp_filter_tb/RST
add wave -noupdate /tiny_uart_inp_filter_tb/CLK
add wave -noupdate -divider Filter
add wave -noupdate /tiny_uart_inp_filter_tb/INP
add wave -noupdate /tiny_uart_inp_filter_tb/OUTP
add wave -noupdate -divider Voter
add wave -noupdate /tiny_uart_inp_filter_tb/DUT/sync_ffs
add wave -noupdate /tiny_uart_inp_filter_tb/DUT/voter_ffs
add wave -noupdate /tiny_uart_inp_filter_tb/DUT/rsff_set
add wave -noupdate /tiny_uart_inp_filter_tb/DUT/rsff_reset
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {1703366 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 361
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 ps} {2625 ns}
