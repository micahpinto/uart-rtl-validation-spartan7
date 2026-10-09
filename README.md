# RTL Design and Validation of UART using Spartan-7

UART transmitter and receiver in Verilog (8N1, 115200 baud), running on a
Spartan-7 FPGA (Digilent Arty S7-25) and validated with automated Python tests.

The hardware design is an echo: bytes sent from the PC are received by the FPGA,
shown on the LEDs, and transmitted back.

## Files
- `design/uart_tx.v`: transmitter
- `design/uart_rx.v`: receiver (two-flop synchronizer, mid-bit sampling)
- `design/uart_top.v`: echo wrapper for the Arty S7-25 (12 MHz clock, CLKS_PER_BIT = 104)
- `constraints/uart_top.xdc`: pin assignments
- `validation_tests/echo_test.py`: sends one byte and checks the echo
- `validation_tests/echo_all_bytes.py`: sends all 256 byte values and checks every echo

## Results
- Hardware: all 256 byte values echoed correctly (`echo_all_bytes.py`).

## Running the validation tests
Requires Python with `pyserial` (`pip install pyserial`). Program the board,
set the COM port in the script, then run:

    python validation_tests/echo_all_bytes.py

Serial settings: 115200 8N1, no flow control.

## What broke and how I found it
- **Bug:** Echo didn't appear in the terminal, although the LEDs showed the
  received byte correctly.
- **Diagnosis:** LEDs proved the RX path worked. The terminal showed TXD activity
  but no RXD, so data wasn't returning to the PC. Pins were verified against the
  Digilent master XDC.
- **Cause:** The terminal had RTS/CTS hardware flow control enabled; the design
  has no handshake lines.
- **Fix:** Flow control set to None.
