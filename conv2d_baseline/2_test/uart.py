import sys

import serial

import glob
import platform

class Scale_UART:
    def __init__(self, device):
        self.ser = serial.Serial(device, 921600)
        self.ser.reset_input_buffer()
        self.ser.reset_output_buffer()
    
    def su_flush_buffer(self):
        self.ser.reset_input_buffer()
        self.ser.reset_output_buffer()
        
    def snd_packet(self, packet):
        for slice in packet:
            self.ser.write(bytearray([int(slice)]))
        return None
    
    def rcv_packet(self, size):
        packet = []
        for i in range(size):
            temp = self.ser.read(1)
            packet.append(ord(temp))
        return packet

def port_list():
    os_name = platform.system()
    if "Windows" in os_name:
        print("Current OS: Windows")
        ports = ['COM%s' %(i+1) for i in range(256)]
    elif "Linux"in os_name:
        print("Current OS: Linux")
        ports = glob.glob('/dev/tty[A-Za-z]*')
    elif "Darwin" in os_name:
        print("Current OS: Mac")
        ports = glob.glob('/dev/tty.*')
    result = []
    for p in ports:
        try:
            s = serial.Serial(p)
            s.close()
            result.append(p)
        except (OSError, serial.SerialException):
            pass
    print(result)
    return result

def get_info(data):
    label = data[0]
    cycle = 0
    for i in range(4):
        cycle *= 0x100
        cycle += data[4-i]
    return label, cycle