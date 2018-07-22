onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Ports
add wave -noupdate /tiny_uart_tx_tb/R
add wave -noupdate /tiny_uart_tx_tb/C
add wave -noupdate /tiny_uart_tx_tb/LD
add wave -noupdate /tiny_uart_tx_tb/MTY
add wave -noupdate /tiny_uart_tx_tb/BSY
add wave -noupdate /tiny_uart_tx_tb/SO
add wave -noupdate -radix hexadecimal /tiny_uart_tx_tb/DI
add wave -noupdate -divider FSM
add wave -noupdate /tiny_uart_tx_tb/DUT/current_state
add wave -noupdate /tiny_uart_tx_tb/DUT/next_state
add wave -noupdate -divider Counter
add wave -noupdate -radix unsigned /tiny_uart_tx_tb/DUT/baud_cntr_cnt
add wave -noupdate /tiny_uart_tx_tb/DUT/baud_cntr_ovl
add wave -noupdate /tiny_uart_tx_tb/DUT/baud_cntr_ena
add wave -noupdate -radix unsigned /tiny_uart_tx_tb/DUT/bit_cntr_cnt
add wave -noupdate -radix unsigned /tiny_uart_tx_tb/DUT/bit_cntr_pst
add wave -noupdate -divider Data
add wave -noupdate -radix hexadecimal /tiny_uart_tx_tb/DUT/data_reg
add wave -noupdate /tiny_uart_tx_tb/DUT/data_reg_new
add wave -noupdate -radix hexadecimal -childformat {{/tiny_uart_tx_tb/DUT/i_sfr/Q(9) -radix hexadecimal} {/tiny_uart_tx_tb/DUT/i_sfr/Q(8) -radix hexadecimal} {/tiny_uart_tx_tb/DUT/i_sfr/Q(7) -radix hexadecimal} {/tiny_uart_tx_tb/DUT/i_sfr/Q(6) -radix hexadecimal} {/tiny_uart_tx_tb/DUT/i_sfr/Q(5) -radix hexadecimal} {/tiny_uart_tx_tb/DUT/i_sfr/Q(4) -radix hexadecimal} {/tiny_uart_tx_tb/DUT/i_sfr/Q(3) -radix hexadecimal} {/tiny_uart_tx_tb/DUT/i_sfr/Q(2) -radix hexadecimal} {/tiny_uart_tx_tb/DUT/i_sfr/Q(1) -radix hexadecimal} {/tiny_uart_tx_tb/DUT/i_sfr/Q(0) -radix hexadecimal}} -subitemconfig {/tiny_uart_tx_tb/DUT/i_sfr/Q(9) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/DUT/i_sfr/Q(8) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/DUT/i_sfr/Q(7) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/DUT/i_sfr/Q(6) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/DUT/i_sfr/Q(5) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/DUT/i_sfr/Q(4) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/DUT/i_sfr/Q(3) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/DUT/i_sfr/Q(2) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/DUT/i_sfr/Q(1) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/DUT/i_sfr/Q(0) {-height 15 -radix hexadecimal}} /tiny_uart_tx_tb/DUT/i_sfr/Q
add wave -noupdate -divider Testbench
add wave -noupdate -radix hexadecimal -childformat {{/tiny_uart_tx_tb/p_stimuli_process/buf(9) -radix hexadecimal} {/tiny_uart_tx_tb/p_stimuli_process/buf(8) -radix hexadecimal} {/tiny_uart_tx_tb/p_stimuli_process/buf(7) -radix hexadecimal} {/tiny_uart_tx_tb/p_stimuli_process/buf(6) -radix hexadecimal} {/tiny_uart_tx_tb/p_stimuli_process/buf(5) -radix hexadecimal} {/tiny_uart_tx_tb/p_stimuli_process/buf(4) -radix hexadecimal} {/tiny_uart_tx_tb/p_stimuli_process/buf(3) -radix hexadecimal} {/tiny_uart_tx_tb/p_stimuli_process/buf(2) -radix hexadecimal} {/tiny_uart_tx_tb/p_stimuli_process/buf(1) -radix hexadecimal} {/tiny_uart_tx_tb/p_stimuli_process/buf(0) -radix hexadecimal}} -subitemconfig {/tiny_uart_tx_tb/p_stimuli_process/buf(9) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/p_stimuli_process/buf(8) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/p_stimuli_process/buf(7) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/p_stimuli_process/buf(6) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/p_stimuli_process/buf(5) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/p_stimuli_process/buf(4) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/p_stimuli_process/buf(3) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/p_stimuli_process/buf(2) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/p_stimuli_process/buf(1) {-height 15 -radix hexadecimal} /tiny_uart_tx_tb/p_stimuli_process/buf(0) {-height 15 -radix hexadecimal}} /tiny_uart_tx_tb/p_stimuli_process/buf
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10021500000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 270
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
WaveRestoreZoom {0 ps} {29546563584 ps}
