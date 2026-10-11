import serial

ser = serial.Serial(
    port='/dev/ttyUSB1',
    baudrate=4_000_000,
    bytesize=serial.EIGHTBITS,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    timeout=5,
    xonxoff=False,
    rtscts=False,
    write_timeout=None,
    dsrdtr=False,
    inter_byte_timeout=None,
    exclusive=None,
)

#ser.write(b"h e l l o t h e r e , h o w a r e y o u d o i n g ?")
ser.write(b"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
#ser.write(b"UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU");
print(ser.readline().strip())
ser.close()
