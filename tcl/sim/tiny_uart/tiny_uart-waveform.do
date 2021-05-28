onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Main
add wave -noupdate /tiny_uart_tb/DUT/c_baud_clkdiv2
add wave -noupdate /tiny_uart_tb/DUT/R
add wave -noupdate /tiny_uart_tb/DUT/C
add wave -noupdate -radix hexadecimal -childformat {{/tiny_uart_tb/p_stimuli_process/buf(9) -radix hexadecimal} {/tiny_uart_tb/p_stimuli_process/buf(8) -radix hexadecimal} {/tiny_uart_tb/p_stimuli_process/buf(7) -radix hexadecimal} {/tiny_uart_tb/p_stimuli_process/buf(6) -radix hexadecimal} {/tiny_uart_tb/p_stimuli_process/buf(5) -radix hexadecimal} {/tiny_uart_tb/p_stimuli_process/buf(4) -radix hexadecimal} {/tiny_uart_tb/p_stimuli_process/buf(3) -radix hexadecimal} {/tiny_uart_tb/p_stimuli_process/buf(2) -radix hexadecimal} {/tiny_uart_tb/p_stimuli_process/buf(1) -radix hexadecimal} {/tiny_uart_tb/p_stimuli_process/buf(0) -radix hexadecimal}} -subitemconfig {/tiny_uart_tb/p_stimuli_process/buf(9) {-height 18 -radix hexadecimal} /tiny_uart_tb/p_stimuli_process/buf(8) {-height 18 -radix hexadecimal} /tiny_uart_tb/p_stimuli_process/buf(7) {-height 18 -radix hexadecimal} /tiny_uart_tb/p_stimuli_process/buf(6) {-height 18 -radix hexadecimal} /tiny_uart_tb/p_stimuli_process/buf(5) {-height 18 -radix hexadecimal} /tiny_uart_tb/p_stimuli_process/buf(4) {-height 18 -radix hexadecimal} /tiny_uart_tb/p_stimuli_process/buf(3) {-height 18 -radix hexadecimal} /tiny_uart_tb/p_stimuli_process/buf(2) {-height 18 -radix hexadecimal} /tiny_uart_tb/p_stimuli_process/buf(1) {-height 18 -radix hexadecimal} /tiny_uart_tb/p_stimuli_process/buf(0) {-height 18 -radix hexadecimal}} /tiny_uart_tb/p_stimuli_process/buf
add wave -noupdate -divider Serial
add wave -noupdate /tiny_uart_tb/DUT/TXD
add wave -noupdate /tiny_uart_tb/DUT/RXD
add wave -noupdate -divider Parallel
add wave -noupdate -radix hexadecimal /tiny_uart_tb/TR
add wave -noupdate /tiny_uart_tb/THRE
add wave -noupdate /tiny_uart_tb/THRL
add wave -noupdate /tiny_uart_tb/TRE
add wave -noupdate -radix hexadecimal /tiny_uart_tb/RR
add wave -noupdate /tiny_uart_tb/PE
add wave -noupdate /tiny_uart_tb/FE
add wave -noupdate /tiny_uart_tb/DR
add wave -noupdate -divider TX
add wave -noupdate /tiny_uart_tb/DUT/tx_sfr_ld
add wave -noupdate /tiny_uart_tb/DUT/tx_sfr_shift
add wave -noupdate -radix hexadecimal -childformat {{/tiny_uart_tb/DUT/tx_sfr(8) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_sfr(7) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_sfr(6) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_sfr(5) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_sfr(4) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_sfr(3) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_sfr(2) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_sfr(1) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_sfr(0) -radix hexadecimal}} -subitemconfig {/tiny_uart_tb/DUT/tx_sfr(8) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_sfr(7) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_sfr(6) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_sfr(5) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_sfr(4) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_sfr(3) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_sfr(2) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_sfr(1) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_sfr(0) {-height 18 -radix hexadecimal}} /tiny_uart_tb/DUT/tx_sfr
add wave -noupdate -radix hexadecimal -childformat {{/tiny_uart_tb/DUT/tx_hold(7) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_hold(6) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_hold(5) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_hold(4) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_hold(3) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_hold(2) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_hold(1) -radix hexadecimal} {/tiny_uart_tb/DUT/tx_hold(0) -radix hexadecimal}} -subitemconfig {/tiny_uart_tb/DUT/tx_hold(7) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_hold(6) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_hold(5) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_hold(4) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_hold(3) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_hold(2) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_hold(1) {-height 18 -radix hexadecimal} /tiny_uart_tb/DUT/tx_hold(0) {-height 18 -radix hexadecimal}} /tiny_uart_tb/DUT/tx_hold
add wave -noupdate /tiny_uart_tb/DUT/tx_hold_empty
add wave -noupdate /tiny_uart_tb/DUT/tx_hold_new
add wave -noupdate /tiny_uart_tb/DUT/g_tx/i_tx_baud_bit_gen/current_state
add wave -noupdate /tiny_uart_tb/DUT/g_tx/i_tx_baud_bit_gen/next_state
add wave -noupdate -divider RX
add wave -noupdate /tiny_uart_tb/DUT/rx_nedge
add wave -noupdate -radix hexadecimal /tiny_uart_tb/DUT/rx_sfr
add wave -noupdate /tiny_uart_tb/DUT/rx_sfr_shift
add wave -noupdate /tiny_uart_tb/DUT/rx_sfr_cap
add wave -noupdate /tiny_uart_tb/DUT/fe_comb
add wave -noupdate /tiny_uart_tb/DUT/pe_comb
add wave -noupdate /tiny_uart_tb/DUT/g_rx/i_rx_baud_bit_gen/current_state
add wave -noupdate /tiny_uart_tb/DUT/g_rx/i_rx_baud_bit_gen/next_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {11914367026 ps} 0}
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
WaveRestoreZoom {0 ps} {12600 us}
