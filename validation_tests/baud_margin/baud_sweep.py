import csv
import os
import serial

PORT = os.getenv("UART_PORT", "COM4")
BAUDS = range(100_000, 132_001, 2_000)    # coarse sweep: 100k to 132k in 2k steps


def count_good_echoes(baud):
    """Send all 256 byte values one at a time at this baud; return how many echoed correctly."""
    good = 0
    with serial.Serial(PORT, baud, timeout=0.1) as ser:
        for value in range(256):
            ser.reset_input_buffer()
            sent = bytes([value])
            ser.write(sent)
            if ser.read(1) == sent:
                good += 1
    return good


results = []
for baud in BAUDS:
    good = count_good_echoes(baud)
    error = (baud - 115_200) / 115_200 * 100
    results.append((baud, f"{error:+.1f}", good))
    print(f"{baud:>7} baud  ({error:+5.1f}%)  {good:3d}/256 correct")

with open("baud_sweep.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["baud", "error_percent", "correct_of_256"])
    writer.writerows(results)