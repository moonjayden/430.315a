import numpy as np

def convert_to_2s_complement(input, point=8, bit=8):
    output = np.multiply(input, pow(2,point))
    output = np.where(output < 0, output+pow(2,bit), output)
    output = output.astype(np.int)
    return output

def save_to_text(input, txt_name, zfill=8, concat_num=8):
    with open(txt_name+'.txt', 'w') as f:
        txt = ''
        for i in range(len(input)):
            txt = txt + "{0:b}".format(input[i]).zfill(zfill)
            if (i+1) % concat_num == 0 or i == len(input) - 1:
                if (i+1) % concat_num != 0 and i == len(input) - 1:
                    txt = txt + "{0:b}".format(0).zfill(zfill * (concat_num - (i+1) % concat_num))
                f.write(txt+'\n')
                txt = ''

param_list = ['conv1_dw_weight', 'conv1_pw_weight', 'conv2_dw_weight', 'conv2_pw_weight', 'conv3_dw_weight', 'conv3_pw_weight']
input_list = ['input_1000', 'input_1']
label_list = ['label_1000', 'label_1']
activ_list = ['input_1_conv1_dw_output', 'input_1_conv1_pw_output', 'input_1_conv2_dw_output', 'input_1_conv2_pw_output', 'input_1_conv3_dw_output']
output_list = ['input_1_conv3_pw_output']

for i in range(len(param_list)):
    with open(param_list[i]+'.npy', 'rb') as f:
        param = convert_to_2s_complement(np.load(f).reshape(-1))
        save_to_text(param, param_list[i], zfill=8, concat_num=8)

for i in range(len(input_list)):
    with open(input_list[i]+'.npy', 'rb') as f:
        input = convert_to_2s_complement(np.load(f).reshape(-1))
        save_to_text(input, input_list[i], zfill=8, concat_num=8)

for i in range(len(label_list)):
    with open(label_list[i]+'.npy', 'rb') as f:
        label = convert_to_2s_complement(np.load(f).reshape(-1), point=0)
        save_to_text(label, label_list[i], zfill=4, concat_num=16)

for i in range(len(activ_list)):
    with open(activ_list[i]+'.npy', 'rb') as f:
        activ = convert_to_2s_complement(np.load(f).reshape(-1))
        save_to_text(activ, activ_list[i], zfill=8, concat_num=8)

for i in range(len(output_list)):
    with open(output_list[i]+'.npy', 'rb') as f:
        output = convert_to_2s_complement(np.load(f).reshape(-1), point=16, bit=22)
        save_to_text(output, output_list[i], zfill=22, concat_num=1)