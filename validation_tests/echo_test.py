import serial

PORT = "COM4"      
BAUD = 115200

with serial.Serial(PORT, BAUD, timeout=1) as ser:
    ser.reset_input_buffer()           # clear any old bytes clean values)

    sent = b"A"                        # the byte to send
    ser.write(sent)                    # send it to the FPGA
    received = ser.read(1)             #  receive what comes back (wait up to 1 second)

    print(f"Sent: {sent}   Received: {received}")
    if received == sent:               #  compare with what we expected
        print("PASS")                
    else:
        print("FAIL")