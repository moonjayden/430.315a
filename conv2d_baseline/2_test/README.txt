###########################
1. board_test.ipynb
해당 파일은 1개의 random input을 돌려서 SW 결과와 같은지 검사하는 python 코드입니다.
Debug 모드를 실행하면, Debug용 input과 output을 Debug 폴더에 저장하도록 했습니다.

이 Debug용 Data와 feature_Debug_bank_init.py를 사용하여 COE로 implement하고 testbench를 돌려보면,
전체 결과 중 어디서 틀렸는지를 확인할 수 있습니다.

만약 testbench에서 결과를 파일로 뽑도록 했다면, 텍스트 diff 확인 하는 사이트를 통해서 편안하게 확인할 수 있습니다.
############################

###########################
2. board_test_2nd_stage.ipynb
해당 파일은 NUM 개의 random input을 ITER번 돌려서 SW 결과와 같은지 검사하는 python 코드입니다.

이것을 통과하면 거의 문제 없이 돌아갈 것입니다. 가능하면 ITER를 많이 해서 오류가 없도록 하는 것이 Tip입니다.
############################

