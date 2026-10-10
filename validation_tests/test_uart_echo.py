import os
import pytest
import serial

PORT = os.getenv("UART_PORT", "COM4")
BAUD = 115200


@pytest.fixture(scope="module")
def ser():
    connection = serial.Serial(PORT, BAUD, timeout=1)
    yield connection
    connection.close()


def echo(ser, data):
    ser.write(data)
    return ser.read(len(data))


@pytest.mark.parametrize("value", range(256))
def test_every_byte(ser, value):
    sent = bytes([value])
    ser.reset_input_buffer()
    received = echo(ser, sent)
    assert received == sent, f"sent 0x{value:02X}, got {received}"


def test_burst(ser):
    sent = bytes(range(256))
    ser.reset_input_buffer()
    received = echo(ser, sent)
    assert received == sent, f"sent {len(sent)} bytes, got {len(received)} back"