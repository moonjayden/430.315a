# 430.315a

@SNU, 2022 

FPGA Verification : Nexys4 DDR Board(Artix-7 Based FPGA)
## Design UART Communication(Asynchronous) considering Metastability Issues
[Metastabitlity Issue]
- Problems with asynchronous data transfer
- Capturing a value when the data is not stable sometimes leaves a half-way value other than 0 and 1

[Common Solution]
- Perform buffering with multiple flip-flops
- Usually, the value becomes stable to 0 or 1 after a certain period of time
- Reduce the probability of metastability through buffering

![image](https://github.com/moonjayden/430.315a/assets/139466574/8778cfa1-f240-4117-b536-8eeea4bd7e67)

[UART Communication]
![image](https://github.com/moonjayden/430.315a/assets/139466574/e5f1e02b-8539-4bbf-b7c7-7839414393bb)

[Result]
![image](https://github.com/moonjayden/430.315a/assets/139466574/58030134-6b55-49d2-b9f3-da773fc23c91)


## Design Fully Connected Layer in CNN for Image Classification
[Fully Connected Layer]
- FC Layer in CNN for Image Classification
- Generally at the end of the network
- Classify images through features extracted by the convolution layer.

![image](https://github.com/moonjayden/430.315a/assets/139466574/0bdd324e-a74a-49ed-901a-fb356605bb5f)


[Architectue of the Module]
![image](https://github.com/moonjayden/430.315a/assets/139466574/5f05efdc-f0e2-4247-8821-e02d6d4ff65c)


[Result]
![image](https://github.com/moonjayden/430.315a/assets/139466574/a74e1255-0d21-4120-813d-2c320bd8546a)



## Design CNN(Conv2d Layers) Image Classifier Accerlerator

[Image Classifier Accelerator]

![image](https://github.com/moonjayden/430.315a/assets/139466574/0e1f8cc1-ca3a-4537-ba64-1ebcfe90bd50)

[Architecture of the Module]
![image](https://github.com/moonjayden/430.315a/assets/139466574/75763fdd-15ef-4804-92e3-b8b389b55040)

[Result]
![image](https://github.com/moonjayden/430.315a/assets/139466574/31151ae4-e637-4d11-a3d0-05691d756451)

![image](https://github.com/moonjayden/430.315a/assets/139466574/7804056e-9291-47ea-91d9-910d191a8a1b)

