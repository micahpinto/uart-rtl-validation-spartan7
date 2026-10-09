import serial

PORT = "COM4"      
BAUD = 115200

errors = 0         

with serial.Serial(PORT, BAUD, timeout=1) as ser:
    ser.reset_input_buffer()

    for value in range(256):               # value = 0, 1, 2 ... 255
        sent = bytes([value])              
        ser.write(sent)                    # send it
        received = ser.read(1)             # get the echo

        if received != sent:               
            print(f"FAIL: sent 0x{value:02X}, received {received}")
            errors += 1

print("----------------------------------")
if errors == 0:
    print("ALL 256 BYTES PASSED")
else:
    print(f"{errors} BYTES FAILED")
print("----------------------------------")