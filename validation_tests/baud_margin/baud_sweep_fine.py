import os
import serial

PORT = os.getenv("UART_PORT", "COM4")
BAUDS = list(range(107_000, 111_001, 500)) + list(range(119_000, 123_001, 500))


def test_baud(baud):
    """Return a list of (sent, received) pairs that failed at this baud."""
    failures = []
    with serial.Serial(PORT, baud, timeout=0.1) as ser:
        for value in range(256):
            ser.reset_input_buffer()
            sent = bytes([value])
            ser.write(sent)
            got = ser.read(1)
            if got != sent:
                failures.append((value, got.hex() or "--"))
    return failures


for baud in BAUDS:
    failures = test_baud(baud)
    error = (baud - 115_200) / 115_200 * 100
    good = 256 - len(failures)
    print(f"{baud:>7} baud ({error:+5.1f}%)  {good:3d}/256 correct")
    for value, got in failures[:6]:                  # show the first few failures
        print(f"        sent {value:02X} ({value:08b})  got {got}")