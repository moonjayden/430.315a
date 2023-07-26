import numpy as np
# These layer functions are implemented in very very naive ways.
import numpy as np
# These layer functions are implemented in very very naive ways.

def conv(x, w, conv_param):
    # print(x.shape)
    # Input
    N, C, W, H = x.shape
    
    # Filter
    # print(w.shape)
    F, C, WW, HH = w.shape
    # Parameter
    stride = conv_param['stride']
    pad = conv_param['pad']
    groups = conv_param['groups']

    # Calculate for output size
    H_out = 1 + int((H+2*pad-HH)/stride)
    W_out = 1 + int((W+2*pad-WW)/stride)
    # Padding using numpy.pad function
    x_pad = np.pad(x, pad_width=((0, 0), (0, 0), (pad, pad), (pad, pad)), mode='constant', constant_values=0)
    out = np.zeros((N, F, H_out, W_out))
    
    if groups == 1:
        # just loop-method
        for i in range(N):
            for j in range(F):
                for k in range(H_out):
                    for l in range(W_out):
                        out[i, j, k, l] = np.sum(x_pad[i, :, k*stride:k*stride+HH, l*stride:l*stride+WW] * w[j,:,:,:])
    else:
        for i in range(N):
            for j in range(F):
                for k in range(H_out):
                    for l in range(W_out):
                        out[i, j, k, l] = np.sum(x_pad[i, j, k*stride:k*stride+HH, l*stride:l*stride+WW] * w[j,:,:,:])
    return out

def avgpool(x):
    out = np.sum(x, axis=(2,3), keepdims=True) / 8
    return out

def relu(x):
    out = np.maximum(0, x)
    return out

def fully_connected(x, w, b):
    out = np.dot(x, w.T) + b
    return out

def q8bit_func(x):
    max = pow(2,-1) - pow(2, -8)
    min = -pow(2, -1)
    x = np.where(x > max, max, x)
    x = np.where(x < min, min, x)
    x = x * pow(2,8)
    x = x.astype(int).astype(float)
    x = x / pow(2,8)
    return x
    
# 8-bit quantization network param
conv1_dw_w_ = np.load("./parameter/conv1_dw_weight.npy")
conv1_pw_w_ = np.load("./parameter/conv1_pw_weight.npy")
conv2_dw_w_ = np.load("./parameter/conv2_dw_weight.npy")
conv2_pw_w_ = np.load("./parameter/conv2_pw_weight.npy")
conv3_dw_w_ = np.load("./parameter/conv3_dw_weight.npy")
conv3_pw_w_ = np.load("./parameter/conv3_pw_weight.npy")


conv1_dw_param = {'stride': 2, 'pad': 1, 'groups':1}
conv1_pw_param = {'stride': 1, 'pad': 0, 'groups':1}
conv2_dw_param = {'stride': 2, 'pad': 1, 'groups':64}
conv2_pw_param = {'stride': 1, 'pad': 0, 'groups':1}
conv3_dw_param = {'stride': 1, 'pad': 0, 'groups':64}
conv3_pw_param = {'stride': 1, 'pad': 0, 'groups':1}

def inference_quan(data):
    # CONV1_DW
    conv1_dw_out = conv(data, conv1_dw_w_, conv1_dw_param)
    conv1_dw_out = q8bit_func(conv1_dw_out)

    # CONV1_PW
    conv1_pw_out = conv(conv1_dw_out, conv1_pw_w_, conv1_pw_param)
    relu1_out = relu(conv1_pw_out)
    relu1_out = q8bit_func(relu1_out)
    
    # CONV2_DW
    conv2_dw_out = conv(relu1_out, conv2_dw_w_, conv2_dw_param)
    conv2_dw_out = q8bit_func(conv2_dw_out)

    # CONV2_PW
    conv2_pw_out = conv(conv2_dw_out, conv2_pw_w_, conv2_pw_param)
    relu2_out = relu(conv2_pw_out)
    relu2_out = q8bit_func(relu2_out)
    
    # CONV3_DW
    conv3_dw_out = conv(relu2_out, conv3_dw_w_, conv3_dw_param)
    conv3_dw_out = q8bit_func(conv3_dw_out)

    # CONV3_PW
    conv3_pw_out = conv(conv3_dw_out, conv3_pw_w_, conv3_pw_param)
    
    return conv3_pw_out

def sw_inference(data):
    num_img = data.shape[0]
    pred_label = list()
    scores = list()
    for idx in range(num_img):
        score = inference_quan(data[idx].reshape((1, 1, 28, 28)))
        scores.append(score)
        print("Progress: {:05.2f}%".format(100*idx/num_img), end = "\r", flush=True)
        pred_label.append(np.argmax(score, axis=1))
    return scores, pred_label

def convert_to_hw_input(input, point=8, bit=8):
    output = np.multiply(input.reshape(-1), pow(2,point))
    output = np.where(output < 0, output+pow(2,bit), output)
    output = output.astype(np.int)
    list = []
    for i in range(len(output)):
        list.append("{0:b}".format(output[i]).zfill(8))
    return list

def inference_quan_for_debug(data):
    data = data.reshape(1, 1, 28, 28)
    # CONV1_DW
    conv1_dw_out = conv(data, conv1_dw_w_, conv1_dw_param)
    conv1_dw_out = q8bit_func(conv1_dw_out)

    # CONV1_PW
    conv1_pw_out = conv(conv1_dw_out, conv1_pw_w_, conv1_pw_param)
    relu1_out = relu(conv1_pw_out)
    relu1_out = q8bit_func(relu1_out)
    
    # CONV2_DW
    conv2_dw_out = conv(relu1_out, conv2_dw_w_, conv2_dw_param)
    conv2_dw_out = q8bit_func(conv2_dw_out)

    # CONV2_PW
    conv2_pw_out = conv(conv2_dw_out, conv2_pw_w_, conv2_pw_param)
    relu2_out = relu(conv2_pw_out)
    relu2_out = q8bit_func(relu2_out)
    
    # CONV3_DW
    conv3_dw_out = conv(relu2_out, conv3_dw_w_, conv3_dw_param)
    conv3_dw_out = q8bit_func(conv3_dw_out)

    # CONV3_PW
    conv3_pw_out = conv(conv3_dw_out, conv3_pw_w_, conv3_pw_param)

    return conv1_dw_out, relu1_out, conv2_dw_out, relu2_out, conv3_dw_out, conv3_pw_out

def save_data(input, txt_name, zfill=8, point=8, bit=8):
    input = np.multiply(input.reshape(-1), pow(2,point))
    input = np.where(input < 0, input+pow(2,bit), input)
    input = input.astype(np.int)
    with open('./Debug/'+txt_name+'.txt', 'w') as f:
        for i in range(len(input)):
            # f.write("{0:b}".format(input[i]).zfill(zfill)+'\n')
            f.write("{0:b}".format(input[i]).zfill(zfill))
            if (i%8 == 7):
                f.write("\n");
            
def save_debugging_data(input, label):
    outputs = inference_quan_for_debug(input)
    x = input.copy()
    x = x.reshape(1,1,28,28)
    np.save('./Debug/debug_input',x)
    save_data(input, "debug_input")
    save_data(outputs[0], "debug_conv1_dw_output")
    save_data(outputs[1], "debug_conv1_pw_output")
    save_data(outputs[2], "debug_conv2_dw_output")
    save_data(outputs[3], "debug_conv2_pw_output")
    save_data(outputs[4], "debug_conv3_dw_output")
    # save_data(outputs[5], "debug_conv3_pw_output", 22, 16, 22)
    save_data(outputs[5], "debug_conv3_pw_output", 8, 8, 22)
    save_data(label, "debug_label", 4, 0)