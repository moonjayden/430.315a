`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// University: SKKU
// Engineer: Youngjin Moon
// 
// Create Date: 2022/08/01 13:11:21
// Design Name: 
// Module Name: conv1_pw
// Project Name: Final project
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
// input channel : 1
// output channel : 64
// kernel : 3
// stride : 2
// padding : 1
// groups : 1
// ReLu : No
//////////////////////////////////////////////////////////


module conv1_pw(
        // system
        input clk, rstn,

        // control
        input init,
        output reg done,

        // param bank
        output reg [15:0]   pbank_addr,
        input [7:0]         pdata,
        output reg          pbank_en,
        
        // fmap bank read
        output reg [14:0]   fbank_raddr,
        input [7:0]         fdata_r,
        output reg          fbank_ren,
        
        // fmap bank write
        output reg [14:0]   fbank_waddr,
        output [7:0]        fdata_w,
        output reg          fbank_wen
    );
    ////////////////////////////////////////////////////////////////////
    //parameter
    
    // layer info
    localparam  fmap_size = 14,
                filter_size = 1,
                channel = 64,
                out_channel = 64,
                stride = 1,
                padding = 0,
                groups = 1,
                filter_group_num = channel / groups, //64
                out_size = (fmap_size + 2*padding - 2*(filter_size>>1))/ stride; //14

                
    // addr info
    localparam  // param_bank (ROM)
                CONV1_PW_START_ADDR = 16'h0240,
                CONV1_PW_END_ADDR = 16'h123F,
                // fmap_bank (RAM)
                INPUT_BASE_ADDR = 15'h4000,
                OUTPUT_BASE_ADDR = 15'h0000,
                FMAP_NUM = 15'h30FF; //14x14x64 = 196x64 =12544
                
     /*w_base_addr = 16'h0000,
     b_base_addr = 16'h0200,
     Conv1 dw weight	: 16'h0000
     Conv1 pw weight	: 16'h0240
     Conv2 dw weight	: 16'h1240
     Conv2 pw weight	: 16'h1480
     Conv3 dw weight	: 16'h2480
     Conv3 pw weight	: 16'h30C0*/
                
                
    // state
    localparam  IDLE = 2'd0,
                COMPUTE = 2'd1,
                SAVE = 2'd2;
               
    
    //latency
    localparam MEM_LATENCY = 2;
    
    ////////////////////////////////////////////////////////////////////
    //state
    reg [1:0] state;
    reg [1:0] next_state;
    
    reg compute_start, compute_done;
    // mac control
    reg m_rstn;         // For Initialize the mac
    reg [1:0] latency;    // For Read Latency
    reg mac_only_add;
    reg mac_en;     // For start mac
    //address control
    
    reg [15:0]  pbank_addr_bf;
    reg [14:0]  fbank_raddr_bf;
    reg [14:0]  fbank_waddr_bf;
     //fmap_bank (RAM)
    reg [4:0] feature_h, feature_w;                 // Feature height_index & width_index
    reg [5:0] feature_c;                      // Feature channel_index
     //param_bank (ROM)
    //reg [3:0] param_h, param_w;               // (param) Weight height_index & width_index
    reg [5:0] param_c;                          // (param) Weight channel_index
    reg [5:0] param_num;                    // (param) Weight number_index
     //output_bank(RAM)
    reg [3:0] out_h, out_w;                 //Output Feature height_index & width_index
    reg [6:0] out_c ;                       //Output Feature channel_index
    
    //for computing
    reg [6:0] mac_counter; //for check accumulate(compute) 9 --> save 1 word (8 bit)
    reg [7:0] acc_counter;    //for count 14x14=196 --> 14x14x64
    reg [6:0] ch_counter; //for feature(input) channel counter
    
    reg [7:0] mac_result_temp;
    wire [7:0] mac_result;// 1 word(8 bit) each mac result
    
    ////////////////////////////////////////////////////////////////////
    // MAC instantiation
    mac_relu conv1_pw_mac (.clk(clk), .rstn(m_rstn), .din_a(pdata), .din_b(fdata_r), .only_add(mac_only_add), .enable(mac_en), .dout(mac_result));
    ////////////////////////////////////////////////////////////////////
    //next state
    always @(*) begin
        if (rstn == 1'b0) begin
            next_state = IDLE;
        end
        else begin
            case (state) 
                IDLE : begin
                    if(compute_start) next_state = COMPUTE;
                    else next_state = state;
                end                
                COMPUTE : begin
                    if(compute_done) next_state = SAVE;
                    else next_state = state;
                end
                SAVE : begin
                    if(done == 1) next_state = IDLE;
                    else if (fbank_wen) next_state = COMPUTE;
                    else next_state = state;
                end                           
                default: next_state = IDLE;
            endcase
        end
    end
    
    //processing procedure
    always @(posedge clk) begin
        state <= next_state;
        if (rstn == 1'b0) begin
            //output
            done <= 'b0;
            pbank_en <= 'b0;
            fbank_ren <= 'b0;
            
            //reg
            compute_start <= 'b0;
            compute_done <= 'b0;
             //mac control
            m_rstn <= 'b0;  
            latency <= 'b0;    
            mac_only_add <= 'b0;
            mac_en <= 'b0;     //stop mac
            
            //address control
             //fmap_bank (RAM)
            feature_h <= 'b0;
            feature_w <= 'b0;              
            feature_c <= 'b0;                 
             //param_bank (ROM)
            //param_h <= 'b0;
            //param_w <= 'b0;        
            param_c <= 'd0;    
            param_num <= 'd0;                      
             //output_bank(RAM)
            out_h <= 'b0;
            out_w <= 'b0;
            out_c <= 'b0;
            //for computing
            mac_counter <= 'b0;
            acc_counter <= 'b0;
            ch_counter <= 'b0; 
            mac_result_temp <= 'b0;
        end
        
        else begin
        fbank_raddr <= fbank_raddr_bf;
        pbank_addr <= pbank_addr_bf;
        fbank_waddr <= fbank_waddr_bf;
        
        fbank_raddr_bf <= feature_w + ((fmap_size) * feature_h ) + ((fmap_size * fmap_size) * feature_c) + INPUT_BASE_ADDR; 
        pbank_addr_bf <= ((filter_size * filter_size) * param_c) + (channel * param_num) + CONV1_PW_START_ADDR; 
        fbank_waddr_bf <= out_w + (out_size * out_h) + ((out_size * out_size) * out_c) + OUTPUT_BASE_ADDR - 1'b1;
            case (state)
                IDLE : begin
                    done <= 'b0; //output
                    pbank_en <= 'b0; //pbank
                    fbank_ren <= 'b0; //fbank_read
                    fbank_wen <= 'b0; //fbank_write
                    //reg
                    compute_done <= 'b0;
                    if(init) compute_start <= 1'b1;
                     //mac control
                    m_rstn <= 'b0;  
                    latency <= 'b0;    
                    mac_only_add <= 'b0;
                    mac_en <= 'b0;     //stop mac
                    //address control
                     //fmap_bank (RAM)
                    feature_h <= 'd0;
                    feature_w <= 'd0;              
                    feature_c <= 'd0;                 
                     //param_bank (ROM)
                    //param_h <= 'b0;
                    //param_w <= 'b0;        
                    param_c <= 'd0;    
                    param_num <= 'd0;                      
                     //output_bank(RAM)
                    out_h <= 'd0;
                    out_w <= 'd0;
                    out_c <= 'd0;
                    
                     //for computing
                    mac_counter <= 'b0;
                    acc_counter <= 'b0;
                    ch_counter <= 'b0; 
                    mac_result_temp <= 'b0;
                    
                end
                
                COMPUTE : begin
                    m_rstn <= 1'b1; // mac start!
                    pbank_en <= 1'b1; // Read pbank (conv1 weight)
                    fbank_ren <= 1'b1; //Read fbank (input feature)
                    fbank_wen <= 1'b0; // No write
                    if(latency < MEM_LATENCY + 1) begin
                        latency <= latency + 1'b1;
                        mac_en <= 1'b0;
                    end
                    else  begin // latency == 3 -> read & compute(1 cycle)!!
                        latency <= 1'b0;
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                  
                        //param_bank --> conv1_pw_weight (1x1x64x64) (filter_size x filter_size x out_size x out_channel)
                        //pbank_addr = 1x1xparam_c + 64xparam_num + 16'h240 <= 16'h123F
                        if( ((filter_size * filter_size) * param_c) + (out_channel * param_num) + CONV1_PW_START_ADDR <= CONV1_PW_END_ADDR) begin
                            //param_c<63 
                            if(param_c < channel - 1)   param_c <= param_c + 1'b1;
                            else begin 
                                param_c <= 'd0;
                                
                            end
                        end
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                     
                        //param_bank --> conv1_pw_weight (1x1x64x64) (filter_size x filter_size x out_size x out_channel)         
                        
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
                        //fmap_bank --> input feature (28x28xx1) (fmap_size x fmap_size x channel)
                        //output
                        // Using counter                             
                        if(mac_counter < channel - 1)  begin //mac_counter < 63
                            mac_counter <= mac_counter + 1'b1;
                            mac_en <= 1'b1;
                            if(feature_c < filter_group_num) begin 
                                feature_c <= feature_c + 1'b1;
                            end
                        end
                        else begin //mac_counter = 63 --> Compute 1 word!
                            //mac_result_temp <= mac_result;                          
                            compute_done <= 1'b1;
                            mac_en <= 1'b1;
                            mac_counter <= 'b0;
                            acc_counter <= acc_counter + 1'b1;
                            feature_w <= feature_w + 1'b1;
                            feature_c <= 'd0;
                            if(acc_counter % out_size == out_size - 1) begin
                                feature_h <= feature_h + 1'b1;
                                feature_w <= 'd0;
                            end
                            
                            out_w <= out_w + 1'b1;   
                            
                            if(acc_counter % out_size == out_size - 1) begin //acc_counter % 14 = 13
                                out_w <= out_w - (out_size - 1);
                                out_h <= out_h + 1'b1;
                            end
                            
                            if(acc_counter == (out_size * out_size) - 1) begin //acc_counter = 0
                                //input_channel
                                if(param_c == channel - 1)     begin // param_c = 63
                                    feature_c <= 'd0;
                                    ch_counter <= ch_counter + 1'b1;
                                end
                                //output channel
                                if(ch_counter < channel)    begin
                                    if(out_h == out_size - 1) begin
                                        out_h <= 'd0;
                                        feature_h <='d0;
                                        param_num <= param_num + 1'b1;
                                        out_c <= out_c + 1'b1;
                                    end
                                end
                            end
                        end
                    end
                end
                
                SAVE : begin
                    // 64 channel finish, Compute and Save 14x14x64 & Go to IDLE
                    mac_result_temp <= mac_result;       
                    fbank_wen <= 1'b1; // Write 1 word(8 bit) for 1 cycle
                    compute_done <= 1'b0; 
                    m_rstn <= 'b0;  
                    if (ch_counter == out_channel) begin
                        //out_c <= out_channel;
                        done <= 1'b1; //Go to IDLE
                        compute_start <= 1'b0; // STAY IDLE state 
                    end
                    else begin 
                        if(fbank_wen == 1'b1) begin
                            if (acc_counter == (out_size * out_size)) begin // 1X1 = 1 channel finish
                                acc_counter <= 'b0;
                            end
                        end
                    end
                end        
                
                default : ; 
                   
            endcase
            
        end
    end
    assign fdata_w = mac_result_temp;
    
endmodule
