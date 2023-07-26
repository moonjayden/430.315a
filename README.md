# 430.315a

@SNU, 2022 

FPGA Verification : Nexys4 DDR Board(Artix-7 Based FPGA)
### Design UART Communication(Asynchronous) considering Metastability Issues
[Metastabitlity Issue]
- Problems with asynchronous data transfer
- Capturing a value when the data is not stable sometimes leaves a half-way value other than 0 and 1

[Common Solution]
- Perform buffering with multiple flip-flops
- Usually, the value becomes stable to 0 or 1 after a certain period of time
- Reduce the probability of metastability through buffering

![image](https://github.com/moonjayden/430.315A/assets/139466574/7e163531-15ee-48f4-a68b-f0d9e1840c68)

[UART Communication]
![image](https://github.com/moonjayden/430.315A/assets/139466574/1aea4732-7482-4888-8367-0eb69aab45e5)

[Result]
![image](https://github.com/moonjayden/430.315A/assets/139466574/5753c897-d650-4423-ad1f-6050a9c48250)


### Design Fully Connected Layer in CNN for Image Classification
[Fully Connected Layer]
- FC Layer in CNN for Image Classification
- Generally at the end of the network
- Classify images through features extracted by the convolution layer.

![image](https://github.com/moonjayden/430.315A/assets/139466574/77e15489-12d1-4a97-a7c0-5740cb97e990)

[Architectue of the Module]
![image](https://github.com/moonjayden/430.315A/assets/139466574/67a7336b-61e0-48d5-b4dc-fcbf430c1888)

[Result]
![image](https://github.com/moonjayden/430.315A/assets/139466574/a7cc4ae3-4385-43e9-8931-e74a2978f481)



### Design CNN(Conv2d Layers) Image Classifier Accerlerator

[Image Classifier Accelerator]

![image](https://github.com/moonjayden/430.315A/assets/139466574/268dd934-6ed3-461b-807b-bbbe6aceb5fb)

[Architecture of the Module]
![image](https://github.com/moonjayden/430.315A/assets/139466574/925ece25-b164-4b6c-b55f-0e2f57cf2ec4)

[Result]
![image](https://github.com/moonjayden/430.315A/assets/139466574/d960f6ba-fe88-4090-8b8a-864eadcefa89)

![image](https://github.com/moonjayden/430.315A/assets/139466574/f6786165-5597-4cd1-9b17-133b8a1c011e)

