# tinyUART
UART core written in VHDL


## Interface

### Table of generics

| Name     | Type     | Default | Description                                          |
| -------- | -------- | ------- | ---------------------------------------------------- |
| DWIDTH   | integer  | 8       | data width                                           |
| CLK_HZ   | positive | 50e6    | core clock frequency in Hz                           |
| BAUD_BPS | positive | 115200  | UART tranmission speed in baud per second            |
| STOPBIT  | integer  | 1       | number of stopbits, fracs not allowed                |
| RXSYNC   | integer  | 2       | data input to clock synchronisation flip-flop stages |
| DEBOUNCE | integer  | 1       | majority voter for input debouncing; stages: 2n+1    |


### Table of ports

| Port     | Direction | Width  | Description                                        |
| -------- | --------- | ------ | -------------------------------------------------- |
| R        | input     | 1b     | asynchronous reset                                 |
| C        | input     | 1b     | clock, rising-edge only used                       |
| TXD      | output    | 1b     | serial UART output                                 |
| RXD      | input     | 1b     | serial UART input                                  |
| FRMERO   | output    | 1b     | framing error; start and stopbit not as expected   |
| RX       | output    | 4b..8b | recieved data value; highest bit is MSB            |
| RXCE     | output    | 1b     | new data value available, one clock cycle high     |
| TX       | input     | 4b..8b | transmit data value; highest bit is MSB            |
| TXMTY    | output    | 1b     | tx buffer register empty; ready to write new value |
| TXCE     | input     | 1b     | write data value to transmit; one clock cycle high |
| BSY      | output    | 1b     | RX and/or TX path is active                        |


## Architecture

<br/>
<center><img src=" /99_md/tiny_uart_arch.svg" height="100%" width="100%" alt="block level diagram" title="tiny uart simplified system architeture" /></center>
<br/>


## References

* [Wikipedia: UART](https://en.wikipedia.org/wiki/Universal_asynchronous_receiver-transmitter)
* [Wikipedia: Parity](https://en.wikipedia.org/wiki/Parity_bit)
