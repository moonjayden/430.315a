import serial

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
    def snd_byte(self, data):
        self.ser.write(bytearray([int(data)]))
        return None
    
    def rcv_packet(self, size):
        packet = []
        for i in range(size):
            temp = self.ser.read(1)
            print(ord(temp))
            packet.append(ord(temp))
        return packet
    
    def rcv_byte(self):
        temp = self.ser.read(1)
        return ord(temp)
    
def check_validity(lhs, rhs):
    if lhs == rhs:
        print("Correct!!! GO HOME!!!")
    else:
        print("Incorrect... S...T...A...Y...")