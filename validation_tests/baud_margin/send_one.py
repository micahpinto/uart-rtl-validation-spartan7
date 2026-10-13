import sys
import serial

PORT = "COM4"                      
baud = int(sys.argv[1])            # speed, typed after the script name
value = int(sys.argv[2], 16)       # byte in hex, typed after the speed, example : py send_one.py 108500 40

with serial.Serial(PORT, baud, timeout=0.5) as ser:
    ser.reset_input_buffer()
    ser.write(bytes([value]))
    got = ser.read(1)

print(f"{baud} baud: sent {value:02X}, PC received {got.hex() or 'nothing'}")