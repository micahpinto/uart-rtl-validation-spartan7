# RTL Design and Validation of UART using Spartan-7

A complete UART transmitter and receiver in Verilog, running on a Spartan-7 FPGA
(Digilent Arty S7-25). The design was first verified in simulation with a
self-checking testbench, then validated on hardware with automated Python tests.

The hardware design is an echo: bytes sent from the PC are received by the FPGA,
shown on the LEDs, and transmitted straight back.

## Specification
- **Board:** Digilent Arty S7-25 (AMD Spartan-7 XC7S25)
- **Clock:** 12 MHz (onboard oscillator)
- **Baud rate:** 115200 bps (configurable through the `CLKS_PER_BIT` parameter)
- **Bit period:** 12 MHz / 115200 ≈ 104 clock cycles
- **Frame:** 8N1 (1 start bit, 8 data bits LSB first, 1 stop bit, no parity)

---

## UART theory

UART sends bytes over a single wire with **no shared clock**. Both sides agree on
a baud rate in advance, and the receiver reconstructs the bit timing from the
data line itself.

### Frame format

    [START(0)] [D0 D1 D2 D3 D4 D5 D6 D7] [STOP(1)]

- **Idle:** the line rests high (1).
- **Start bit:** the line goes low (0) for one bit period. This falling edge tells
  the receiver a byte is beginning.
- **Data bits:** 8 bits, least significant bit (D0) first.
- **Stop bit:** the line returns high (1) for one bit period, marking the end of
  the byte.

Each byte therefore takes 10 bit periods on the wire.

### Baud rate and bit timing

The FPGA measures time by counting clock cycles. The number of cycles per bit is:

    CLKS_PER_BIT = clock frequency / baud rate = 12,000,000 / 115,200 ≈ 104

Both the transmitter and receiver count `CLKS_PER_BIT` cycles for each bit.

### Receiving without a shared clock

- **Synchronization:** the RX input comes from outside the FPGA's clock domain,
  so it passes through two flip-flops before use. This prevents metastability,
  at the cost of 2 clock cycles of latency.
- **Start-bit detection:** when the line goes low, the receiver waits half a bit
  period and checks the line is still low. If it isn't, it was a glitch and is
  ignored.
- **Mid-bit sampling:** from the middle of the start bit, the receiver waits one
  full bit period between samples, so every data bit is sampled in its middle,
  where the signal is most stable. This gives the link tolerance to small
  differences between the two sides' clocks.

---

## Design

### Transmitter (`design/uart_tx.v`)
A finite state machine with five states:
1. **IDLE:** TX line held high, waiting for a one-cycle "data valid" pulse; the
   input byte is captured into an internal register
2. **START_BIT:** TX low for one bit period
3. **DATA_BITS:** 8 data bits, one per bit period, LSB first
4. **STOP_BIT:** TX high for one bit period, then signals "done"
5. **CLEANUP:** one clock cycle, then back to IDLE

The serial output comes directly from a flip-flop, so it can't glitch.

### Receiver (`design/uart_rx.v`)
Two-flop synchronizer, then a state machine (IDLE, START_BIT, DATA_BITS,
STOP_BIT, CLEANUP) that detects the start bit, samples each data bit in its
middle, and outputs the byte with a one-cycle "data valid" pulse.

### Echo wrapper (`design/uart_top.v`)
Connects the board's clock and USB-UART pins to the receiver and transmitter.
The receiver's "data valid" pulse directly triggers the transmitter with the
received byte, and the lower 4 bits of each received byte are shown on LEDs
LD2–LD5.

### Constraints (`constraints/uart_top.xdc`)
Pin assignments taken from the Digilent Arty S7-25 master XDC: 12 MHz clock
(F14), USB-UART (R12 out to PC, V12 in from PC) and four LEDs.

---

## Simulation

The entire design was first verified in simulation before going to hardware,
using a self-checking loopback testbench (TX output connected to RX input):

- Sends three consecutive frames of `0xCC` (`11001100`)
- Prints each bit to the console at the moment the receiver samples it (bit-by-bit)
- Compares each received byte with the byte sent and prints PASS/FAIL
- Prints a final summary

**Result:** all 3 frames sent and received correctly.


---

## Hardware validation

### Manual test
Programmed on the Arty S7-25 and tested with RealTerm (115200 8N1, no flow
control): each character typed was echoed back, and the LEDs showed its lower
4 bits (for example `A` = `0x41` → `0001`).

### Automated tests
- `validation_tests/echo_test.py`: sends one byte and checks the echo
- `validation_tests/echo_all_bytes.py`: sends all 256 byte values and checks every echo

**Result:** all 256 byte values echoed correctly.

Requires Python with `pyserial` (`pip install pyserial`). Program the board, set
the COM port in the script, then run:

    python validation_tests/echo_all_bytes.py

### What broke and how I found it
- **Bug:** Echo didn't appear in the terminal, although the LEDs showed the
  received byte correctly.
- **Diagnosis:** LEDs proved the RX path worked. The terminal showed TXD activity
  but no RXD, so data wasn't returning to the PC. Pins were verified against the
  Digilent master XDC.
- **Cause:** The terminal had RTS/CTS hardware flow control enabled; the design
  has no handshake lines.
- **Fix:** Flow control set to None.

---
