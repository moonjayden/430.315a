`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// University: SKKU
// Engineer: Youngjin Moon
// 
// Create Date: 2022/08/01 13:11:21
// Design Name: 
// Module Name: conv2_dw
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
// input channel : 64
// output channel : 64
// kernel : 3
// stride : 2
// padding : 1
// groups : 64
// ReLu : No
//////////////////////////////////////////////////////////


module conv2_dw(
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
    
    // layer info
    localparam  fmap_size = 14,
                filter_size = 3,
                channel = 64,
                out_channel = 64,
                stride = 2,
                padding = 1,
                groups = 64,
                filter_group_num = channel / groups, //1
                out_size = (fmap_size + 2*padding - 2*(filter_size>>1))/ stride; //7

                
    // addr info
    localparam  // param_bank (ROM)
                CONV2_DW_START_ADDR = 16'h1240,
                CONV2_DW_END_ADDR = 16'h147F,
                // fmap_bank (RAM)
                INPUT_BASE_ADDR = 15'h0000,
                OUTPUT_BASE_ADDR = 15'h4000;
                
     /*w_base_addr = 16'h0000,
     b_base_addr = 16'h0200,
     Conv1 dw weight	: 16'h0000
     Conv1 pw weight	: 16'h0240
     Conv2 dw weight	: 16'h1240
     Conv2 pw weight	: 16'h1480
     Conv3 dw weight	: 16'h2480
     Conv3 pw weight	: 16'h30C0*/
                
                
    // state
    localparam  IDLE = 3'd0,
                COMPUTE = 3'd1,
                SAVE = 3'd2,
                CHECK = 3'd3;
               
    integer i;
    //latency
    localparam MEM_LATENCY = 2;
    
    ////////////////////////////////////////////////////////////////////
    //state
    reg [1:0] state;
    reg [1:0] next_state;
    
    reg compute_start, compute_done;
    reg check_end, check_start;
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
    reg [3:0] param_h, param_w;               // (param) Weight height_index & width_index
    reg [5:0] param_c;                          // (param) Weight channel_index
     //output_bank(RAM)
    reg [3:0] out_h, out_w;                 //Output Feature height_index & width_index
    reg [6:0] out_c ;                       //Output Feature channel_index
    
    //for computing
    reg [3:0] mac_counter; //for check accumulate(compute) 9 --> save 1 word (8 bit)
    reg [7:0] acc_counter;    //for count 14x14=196 --> 14x14x64
    reg [6:0] ch_counter; //for feature(input) channel counter
    
    reg [7:0] mac_result_temp;
    wire [7:0] mac_result;// 1 word(8 bit) each mac result
    
    ////////////////////////////////////////////////////////////////////
    // MAC instantiation
    mac conv2_dw_mac (.clk(clk), .rstn(m_rstn), .din_a(pdata), .din_b(fdata_r), .only_add(mac_only_add), .enable(mac_en), .dout(mac_result));
    
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
            i=0;
            check_end = 1'b0;
            check_start = 1'b0;
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
            param_h <= 'b0;
            param_w <= 'b0;        
            param_c <= 'b0;                          
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
            
        fbank_raddr_bf <= (feature_w - padding) + ((fmap_size) * (feature_h - padding)) + ((fmap_size * fmap_size) * feature_c) + INPUT_BASE_ADDR; 
        pbank_addr_bf <= param_w + (filter_size * param_h) + ((filter_size * filter_size) * param_c) + CONV2_DW_START_ADDR; 
    //output feature write
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
                    param_h <= 'd0;
                    param_w <= 'd0;        
                    param_c <= 'd0;                          
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
                    check_end <= 1'b0;
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
                        //param_bank --> conv1_weight (3x3x64) (filter_size x filter_size x out_channel)
                        //pbank_addr = param_w + 3*param_h + 9*param_c <= 16'h023F
                        if( param_w + (filter_size * param_h) + ((filter_size * filter_size) * param_c) + CONV2_DW_START_ADDR <= CONV2_DW_END_ADDR) begin
                            //param_w = 2  
                            if(param_w == (filter_size - 1)) begin
                                param_w <= param_w - (filter_size - 1);
                                param_h <= param_h + 1'b1;
                                //param_h = 0~2 repeat 
                                if(param_h == (filter_size - 1)) param_h <= param_h - (filter_size - 1);
                            end
                            else param_w <= param_w + 1'b1;
                        end
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                     
                        //fmap_bank --> input feature (28x28xx1) (fmap_size x fmap_size x channel)
                        //padding = 1
                        //fbank_raddr = feature_w + 28 * feature_h + 784 * feature_c <= 15'h0000 + 15'h030F
                        if( feature_w + (fmap_size * feature_h)  <= (fmap_size + 2 * padding) * (fmap_size + 2 * padding) + INPUT_BASE_ADDR) begin
                            //first column&row --> padding
                        //padding = 1 -> out_w = 0
                            if(out_h < padding) begin
                                if(out_w < padding) begin// compute first element
                                    //padding
                                    if(feature_h < padding || feature_w < padding ) ;
                                    else mac_en <= 1'b1;
                                end
                                else begin //compute 4,5,6,7,8,9 element
                                    if(feature_h < padding );
                                    else mac_en <= 1'b1;
                                end
                            end
                            else if (out_w < padding) begin
                                if(feature_w < padding ) ;
                                else mac_en <= 1'b1;
                            end
                            else mac_en <= 1'b1;
                        end
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
                        //counter                              
                        if(mac_counter < (filter_size * filter_size) - 1)  begin //mac_counter < 8
                            mac_counter <= mac_counter + 1'b1;
                            if(mac_counter % filter_size == filter_size - 1) begin //mac_counter % 3 =2
                                feature_h <= feature_h + 1'b1;
                                feature_w <= feature_w - (filter_size - 1);
                            end
                            else    feature_w <= feature_w + 1'b1;
                        end
                        else begin //mac_counter = 8 --> Compute 1 word!
                            //mac_result_temp <= mac_result;                          
                            compute_done <= 1'b1;
                            mac_counter <= 'b0;
                            acc_counter <= acc_counter + 1'b1;
                            feature_h <= feature_h - (filter_size - 1);
                            out_w <= out_w + 1'b1;   
                            if(feature_w == fmap_size - 1) feature_w <= 'd0;   
                            if(feature_w == fmap_size + 2*padding - 2*(filter_size>>1)) begin
                                feature_w <= 'd0; 
                                feature_h <= feature_h + stride - (filter_size - 1);
                                if(feature_h ==  fmap_size + 2*padding - 2*(filter_size>>1)) feature_h <= 'd0;
                            end
                            if(acc_counter % out_size == out_size - 1) begin //acc_counter % 14 = 13
                                out_w <= out_w - (out_size - 1);
                                out_h <= out_h + 1'b1;
                            end
                            
                            if(acc_counter == (out_size * out_size) - 1) begin //acc_counter = 195
                                //input_channel
                                if(param_c == out_channel - 1)     begin
                                    feature_c <= 'd0;
                                    //ch_counter <= ch_counter + 1'b1;
                                end
                                //output channel
                                if(ch_counter < out_channel)    begin
                                    if(out_h == out_size - 1) begin
                                        if(feature_c < channel-1) feature_c <= feature_c + 1'b1;
                                        out_h <= 'd0;
                                        out_c <= out_c + 1'b1;
                                        ch_counter <= ch_counter + 1'b1;
                                        param_c <= param_c + 1'b1;

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
                        
                        check_end <= 1'b0;
                    end
                    else begin 
                        if(fbank_wen == 1'b1) begin
                            if (acc_counter == (out_size * out_size)) begin // 14x14 = 1 channel finish
                                acc_counter <= 'b0;
                            end
                        end
                    end
                end        
                /*CHECK: begin
                        fbank_wen <= 'b0;
                        fbank_ren <= 1'b1; //Read fbank (input feature)
                        
                        if (latency < MEM_LATENCY + 1) begin //latency_count = 0 
                            latency <= latency + 1'b1;
                        end
                        else begin //latency_count = 2                      
                            latency <= 1'b0;
                            i <= i+1'b1;
                            feature_w <= feature_w + 1'b1;
                        end
                        if(i == 29000 )  begin
                            check_end = 1'b1;
                            i <= 'd0;
                            feature_w <= 'd0;
                        end
                    end*/
                    
                
              
                
                default : ; 
                   
            endcase
            
        end
    end
    assign fdata_w = mac_result_temp;
    
endmodule
