import numpy as np

def convert_to_2s_complement(input, point=8, bit=8):
    output = np.multiply(input, pow(2,point))
    output = np.where(output < 0, output+pow(2,bit), output)
    output = output.astype(np.int)
    return output

#########################TODO################################################################
# base code 그대로 사용할 것이라면 바꿀 필요 없음
# data axis를 변경하고자 한다면, axis_list의 값을 변경하면 됨. 
# 예를 들면 conv1_weight는 (output channel, input channel, height, width) 순으로 구성되어 있음
# output channel이 제일 먼저 변하도록 (input channel, height, width, output channel) 순으로 변경하고 싶다면
# (1,2,3,0) 으로 코드 수정 ( 현재 코드의 (0,1,2,3)은 axis 변경 없는 상태 )
# 만일 data width를 변경하고 싶다면, Data_pack 변경.
# data가 8bit 이므로 data width는 8의 배수. Data_pack은 한 data line에 몇 개의 data가 들어갈지 결정
# 따라서 Data_pack = 2 라면, data width는 16bit
# 이 때 필요한 ROM의 depth 또한 줄어들기 때문에 ROM_len과 start_addr_list 또한 적절히 변경 (안해도 되지만 resource 낭비)
# data line 안에 data 순서는 MSB 부터 LSB 순임. 이를 고려하여 verilog 작성
#############################################################################################

param_list = ['conv1_dw_weight', 'conv1_pw_weight', 'conv2_dw_weight', 'conv2_pw_weight', 'conv3_dw_weight', 'conv3_pw_weight']  # param bank에 넣을 param list
axis_list = [(0,1,2,3), (0,1,2,3), (0,1,2,3), (0,1,2,3), (0,1,2,3), (0,1,2,3)]							# 해당 parameter의 axis 순서 지정
start_addr_list = [0x0000, 0x0240, 0x1240, 0x1480, 0x2480, 0x30C0]					# 각 parameter의 start addr 지정
ROM_len = 0x4000											# ROM의 전체 depth 지정
Data_pack = 1												# data width 지정 (8bit * data_pack)

count = 0

with open('ROM_init.coe', 'w') as f:
    f.write('; ******************************************************************'+'\n')
    f.write('; ********************** Network Parameter ROM *********************'+'\n')
    f.write('; ******************************************************************'+'\n')
    f.write('; Memory initialization file for Single Port Block Memory'+'\n')
    f.write('; '+'\n')
    f.write('; This .COE file specifies the contents for a block memory of depth=65536, and width=8.'+'\n')
    f.write('; All values are specified in binary format.'+'\n')
    f.write('; '+'\n')
    f.write('; Start address of Parameters'+'\n')
    f.write('; Conv1 dw weight\t: 16\'h0000'+'\n')
    f.write('; Conv1 pw weight\t: 16\'h0240'+'\n')
    f.write('; Conv2 dw weight\t: 16\'h1240'+'\n')
    f.write('; Conv2 pw weight\t: 16\'h1480'+'\n')
    f.write('; Conv3 dw weight\t: 16\'h2480'+'\n')
    f.write('; Conv3 pw weight\t: 16\'h30C0'+'\n')
    f.write('; '+'\n')
    f.write('memory_initialization_radix=2;'+'\n')
    f.write('memory_initialization_vector='+'\n')
    for i in range(len(param_list)):
        while(count < start_addr_list[i]):
            f.write('00000000'*Data_pack+','+'\n')
            count += 1
        with open('parameter/'+param_list[i]+'.npy', 'rb') as rf:
            data = convert_to_2s_complement(np.load(rf).transpose(axis_list[i]).reshape(-1))
            for j in range(len(data)):
                f.write("{0:b}".format(data[j]).zfill(8))
                if (j % Data_pack == Data_pack - 1):
                    f.write(','+'\n')
                    count += 1
            if (j%Data_pack != Data_pack-1):
                f.write('00000000'*(Data_pack-1-j%Data_pack)+',\n')
                count += 1
    while(count < ROM_len-1):
        f.write('00000000'*Data_pack+','+'\n')
        count += 1
    f.write('00000000'*Data_pack+';')
        