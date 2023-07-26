///////////////////////////////////////////////
/*
You can edit or write the code as you want, except for the marked points (Not allowed to change).
Rules you have to keep:
1. Input size and output size of this fully connected layer is fixed (Input : 8, Output: 4) 
2. The input data, weights, bias will be stored in BRAM at each start address (INPUT_START_ADDRESS, WEIGHT_ADDRESS, BIAS_ADDRESS) by STATE_DATA_RECEIVE.
3. You can get input data, weights, bias from BRAM in fixed sizes. Please check and use reg variables; input_feature, weight, weight_bf, bias.
   You cannot edit the size of these variables. Especially, you should know that you cannot get all weights from BRAM at once.
4. When the values are calculated in this module, partial summations (temperal results) must not be quantized. Only the final results (outputs) should quantize to 8-fixed bits.
5. The output of this FC model will be 4 and each of them is 1 byte. When the all calculation is done, you should put the 4 results in out_data(32-bits) and set t_valid as 1.


You can use just one FSM or more than one FSM. In other words, you can use just 'state' or you can use 'bram_state' for bram operating and 'mac_state' for calculation operating.
*/
//////////////////////////////////////////////

`timescale 1ns / 1ps

module fc_controller (
    input               clk,
    input               rstn,
    input               r_valid,
    input [31:0]        in_data,
    output reg          t_valid,
    output reg [31:0]   out_data
);

    localparam
        /////////////////////** START /////////////////////////////////////
        // FC layer parameters
        BYTE_SIZE               = 8, // 1byte = 8bits
        INPUT_SIZE              = 8, // byte
        OUTPUT_SIZE             = 4, // byte
        BIAS_SIZE               = OUTPUT_SIZE, // byte
        WEIGHT_SIZE             = INPUT_SIZE*OUTPUT_SIZE, // byte
        MEM_LATENCY             = 2'd2, // reading latency of SRAM
        
        // Address for each data in BRAM
        INPUT_START_ADDRESS     = 4'd0,
        WEIGHT_START_ADDRESS    = 4'd4,
        BIAS_START_ADDRESS      = 4'd14,
        /////////////////////** END ///////////////////////////////////////
        ///////////////////////////////////////////////////////////////////

        STATE_IDLE              = 3'd0,
        STATE_DATA_RECEIVE      = 3'd1,
        STATE_INPUT_SET         = 3'd2,
        STATE_BIAS_SET          = 3'd3,
        STATE_WEIGHT_SET        = 3'd4,
        
        STATE_ACCUMULATE        = 3'd1,
        STATE_BIAS_ADD          = 3'd2,
        STATE_DATA_SEND         = 3'd3;
        /////////////////////////////////////////////////////////////////////////////////
        // Explanation about state.
        //
        // STATE_DATA_RECEIVE: Receive data from testbench and write data to BRAM.
        // STATE_INPUT_SET: Read input from BRAM and set input
        // STATE_WEIGHT_SET: Read weight from BRAM and set weight
        // STATE_BIAS_SET: Read bias from BRAM and set bias
        // STATE_ACCUMULATE: Accumulate productions of weight and value for one output.
        // STATE_BIAS_ADD: Add bias for one output.
        // STATE_DATA_SEND: Send result data to testbench.
        /////////////////////////////////////////////////////////////////////////////////

    /////////////////////** START /////////////////////////////////////
    //for DATA
    reg [INPUT_SIZE*BYTE_SIZE-1:0]          input_feature;  // input feature size = 8 (each 8-bits)
    reg [INPUT_SIZE*BYTE_SIZE-1:0]          weight;         // weight size = 8 * 4 (each 8-bits). However just set 64-bits(8bytes) at one time.
    reg [INPUT_SIZE*BYTE_SIZE-1:0]          weight_bf;      // weight buffer for parallel running.
    reg [BIAS_SIZE*BYTE_SIZE-1:0]           bias;           // bias size = 4 (each 8-bits)
    /////////////////////** END ///////////////////////////////////////
    ///////////////////////////////////////////////////////////////////
    reg [INPUT_SIZE*BYTE_SIZE-1:0]          input_temp;  // input feature size = 8 (each 8-bits)
    // Signals for BRAM Operation
    reg [2:0]           bram_state;

    reg [3:0]           bram_addr;
    reg [31:0]          bram_din;
    wire [31:0]         bram_dout;
    reg                 bram_en;
    reg                 bram_we;

    reg [1:0]           latency;
    reg [7:0]           bram_counter;
    reg                 bram_write_done;
    reg                 input_set_done;
    reg                 bias_set_done;
    reg                 weight_set_done;
    reg [3:0]           weight_counter;
    reg [2:0] cnt;

    // Signals for MAC Operation
    reg [2:0]           mac_state;
    reg [1:0] real_mac_state;
    reg                 mac_en;
    reg                 mac_add;
    reg [7:0]          data_a;
    reg [7:0]          data_b;
    reg [18:0]         data_c;
    wire                mac_done;
    wire [19:0]         mac_result;
    wire [1:0] r_mac_state;
    
    reg [3:0]           mac_counter;
    reg [3:0]           output_counter;

    reg [19:0]          partial_sum;
    reg [19:0]         result;
    
    wire [7:0]          result_q;
    
    mac #(.A_BITWIDTH(8), .OUT_BITWIDTH(20))
      u_mac (
        .clk(clk),
        .rstn(rstn),
        .en(mac_en),
        .add(mac_add),
        .data_a(data_a), 
        .data_b(data_b),
        .data_c(data_c),
        .done(mac_done),
        .out(mac_result)
    );

    bram_32x16 u_bram(
        .clka(clk),
        .addra(bram_addr),
        .dina(bram_din),
        .douta(bram_dout),
        .ena(bram_en),
        .wea(bram_we)
    );

    // Implement FSM for for BRAM operating.
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            bram_state <= STATE_IDLE;
            
            bram_en <= 1'b0;
            bram_we <= 1'b0;
            bram_addr <= 4'b1111;   // 4'b1111 is dump address(not be used)
            bram_din <= 32'b0;

            latency <= 2'b0;
            bram_counter <= 8'b0;
            bram_write_done <= 1'b0;
            input_set_done <= 1'b0;
            bias_set_done <= 1'b0;
            weight_set_done <= 1'b0;
            weight_counter <= 4'b0;

            input_feature <= {INPUT_SIZE*BYTE_SIZE{1'b0}};
            bias <= {BIAS_SIZE*BYTE_SIZE{1'b0}};
            weight <= {INPUT_SIZE*BYTE_SIZE{1'b0}};
            weight_bf <= {INPUT_SIZE*BYTE_SIZE{1'b0}};
        end
        else begin
            case(bram_state)
                STATE_IDLE: begin
                    bram_en <= 1'b0;
                    bram_we <= 1'b0;
                    bram_counter <= 8'b0;
                    latency <= 2'b0;
                    bram_write_done <= 1'b0;
                    input_set_done <= 1'b0;
                    bias_set_done <= 1'b0;
                    weight_set_done <= 1'b0;
                    weight_counter <= 4'b0;
       
                    if (r_valid) begin
                        bram_state <= STATE_DATA_RECEIVE;
                    end
                end

                /////////////////////** START ////////////////////////////////////////////////
                // Receive data from testbench and write data to BRAM.
                STATE_DATA_RECEIVE: begin
                    if (bram_write_done) begin
                        bram_write_done <= 1'b0;
                        bram_state <= STATE_INPUT_SET;
                        bram_counter <= 8'b0;

                        bram_en <= 1'b0;
                        bram_we <= 1'b0;
                        bram_addr <= 4'b1111;
                        bram_din <= 32'b0;
                    end
                    else begin
                        if (r_valid) begin
                            bram_en <= 1'b1;
                            bram_we <= 1'b1;
                            bram_din <= in_data;

                            bram_counter <= bram_counter + 8'b1;
                            //count == 0
                            if (bram_counter == 0) begin // receive input by (input_size/4) times considering 32-bits data write. 
                                bram_addr <= INPUT_START_ADDRESS; // input size = 8 bytes -> 8*8=32*2 -> 2 times
                            end
                            //count == 2
                            else if (bram_counter == (INPUT_SIZE>>2)) begin // receive weight by (weight_size/4) times considering 32-bits data write.
                                bram_addr <= WEIGHT_START_ADDRESS; // weight size = 8*4 bytes -> 8*4*8=32*8 -> 8 times
                            end
                            //count == 10
                            else if (bram_counter == (WEIGHT_SIZE>>2)+(INPUT_SIZE>>2)) begin // receive bias by (bias_size/4) times considering 32-bits data write.
                                bram_addr <= BIAS_START_ADDRESS; // bias size = 4 bytes -> 4*8=32*1 -> 1 time
                            end
                            else begin
                            	bram_addr <= bram_addr + 4'd1;
                            end
                            //count == 
                            if (bram_counter == (BIAS_SIZE>>2)+(WEIGHT_SIZE>>2)+(INPUT_SIZE>>2)-1) begin
                            	bram_write_done <= 1'b1;
                            end
                        end
                        else begin
                            bram_en <= 1'b0;
                            bram_we <= 1'b0;
                            bram_din <= 32'b0;
                            bram_addr <= 4'b1111;
                        end
                    end
                end
                /////////////////////** END ///////////////////////////////////////
                ///////////////////////////////////////////////////////////////////
                
                // Read from BRAM and set input feature
                STATE_INPUT_SET: begin
                    bram_we <= 1'b0;
                    if (input_set_done) begin
                        input_set_done <= 1'b0;
                        bram_state <= STATE_BIAS_SET;
                        bram_counter <= 8'b0;
                        latency <= 2'b0;
                        bram_en <= 1'b0;
                        bram_addr <= 4'b1111;
                        
                    end
                    else begin
                    	bram_counter <= bram_counter + 8'b1;
                    	bram_en <= 1'b1;
                    	if (bram_counter < (INPUT_SIZE>>2)) begin //counter < 2
	                        bram_addr <= INPUT_START_ADDRESS + bram_counter; //bram_addr<=0+counter
                    	end
                        //When BRAM read, it is the latency for the blank between write address and read data
                        if (latency < MEM_LATENCY+1) begin //0~2ÀÇ latency
                            latency <= latency + 1'b1;
                        end
                        else begin //counter>=2 && latency==3
                            input_feature <= input_feature >> 32; // input_feature <= [63:32]'b0
                            input_feature[INPUT_SIZE*BYTE_SIZE-1:INPUT_SIZE*BYTE_SIZE-32] <= bram_dout; //input_feature[63:32]<=bram_dout
                            if (bram_counter == (INPUT_SIZE>>2)+MEM_LATENCY) begin //counter == 2+Mem_latency = 4
                                input_set_done <= 1'b1; //input set done -> move to next state ( STATE_BIAS_SET )
                               
                                
                            end
                        end
                    end
                end

                // Read from BRAM and set bias
                STATE_BIAS_SET: begin
                    bram_we <= 1'b0;
                    if (bias_set_done) begin
                        bias_set_done <= 1'b0;
                        bram_state <= STATE_WEIGHT_SET;
                        bram_counter <= 8'b0;
                        latency <= 2'b0;
                        bram_en <= 1'b0;
                        bram_addr <= 4'b1111;
                    end
                    else begin
                        bram_counter <= bram_counter + 8'b1;
                        bram_en <= 1'b1;
                    	if (bram_counter < (BIAS_SIZE>>2)) begin //counter < 1
	                        bram_addr <= BIAS_START_ADDRESS + bram_counter; //bram_addr<=14+counter
                    	end
                        
                        if (latency < MEM_LATENCY+1) begin //latency < 3
                            latency <= latency + 1'b1; //latency ++
                        end
                        else begin //latency==3
                            bias <= bias >> 32;  //bias<=[31:0]'b0
                            bias[BIAS_SIZE*BYTE_SIZE-1:BIAS_SIZE*BYTE_SIZE-32] <= bram_dout; //bias[31:0]<=bram_dout
                            if (bram_counter == (BIAS_SIZE>>2)+MEM_LATENCY) begin //counter ==1+MEM_LATENCY=3
                                bias_set_done <= 1'b1; //bias set done -> move to next state ( STATE_WEIGHT_SET )
                            end
                        end
                    end
                end
               
                // Read from BRAM and set weight(8-bytes)
                // When setting weight_bf(8-bytes) is done, pass weight_bf value to weight
                // and restart STATE_WEIGHT_SET for preparing next weights.
                // If weight_counter counts as output size, it means all weight value setting is done. So, move to STATE_IDLE
                STATE_WEIGHT_SET : begin
                    bram_we <= 1'b0;
                    if (weight_set_done) begin
                        if(weight_counter == OUTPUT_SIZE ) begin
                            bram_state <= STATE_IDLE;
                            weight_set_done <= 1'b0;
                            bram_counter <= 8'b0;
                            latency <= 2'b0;
                            bram_en <= 1'b0;
                            bram_addr <= 4'b1111;
                        end
                        if(mac_state == STATE_IDLE ) begin
                                weight <= weight_bf;
                                weight_set_done <= 1'b0;
                                weight_counter <= weight_counter + 1'b1;
                                bram_counter <= 8'b0;
                                cnt <= 3'b0;
                        end  
                    end
                    else begin
                        if(bram_counter < (INPUT_SIZE>>2))begin
                        bram_counter <= bram_counter + 8'b1;
                        bram_addr <= WEIGHT_START_ADDRESS + bram_counter + (weight_counter*2);
                        end
                        bram_en <= 1'b1;
                        cnt <= cnt + 1'b1;
                        if (latency < MEM_LATENCY+1) begin
                            latency <= latency + 1'b1;
                        end
                        else begin
                            weight_bf <= weight_bf >> 32;
                            weight_bf[INPUT_SIZE*BYTE_SIZE-1:INPUT_SIZE*BYTE_SIZE-32] <= bram_dout;
                            if (cnt == 3'd4) begin
                                weight_set_done <= 1'b1;
                            end
                        end
                    end
                end
                
                default: begin
                    bram_en <= 1'b0;
                    bram_we <= 1'b0;

                    bram_counter <= 8'b0;
                    latency <= 2'b0;
                    bram_write_done <= 1'b0;
                    
                    input_set_done <= 1'b0;
                    weight_set_done <= 1'b0;
                    bias_set_done <= 1'b0;

                    bram_state <= STATE_IDLE;
                end
            endcase
        end
    end
    
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin        
            mac_state <= STATE_IDLE;
            mac_en <= 1'b0;
            mac_add <= 1'b0;
            mac_counter <= 4'b0;
            output_counter <= 4'b0;
            t_valid  <= 1'b0;
            out_data <= 32'b0;
            partial_sum <= 20'b0;
        end
        else begin
            real_mac_state <= r_mac_state;
            case(mac_state)
                STATE_IDLE: begin
                    
                    mac_en <= 1'b0;
                    mac_add <= 1'b0;
                    
                    if (weight_set_done) begin
                        mac_state <= STATE_ACCUMULATE;
                    end
                    else begin
                        mac_state <= STATE_IDLE;
                    end
                    partial_sum <= 20'd0;
                end
                // Accumulate productions of weight and value for one output.
                STATE_ACCUMULATE: begin
                // TO DO
                    if(mac_counter < INPUT_SIZE-1'b1)begin
                        if(mac_done == 1'b1)begin
                            partial_sum <= mac_result;
                            mac_counter <= mac_counter+1'b1;  
                        end
                    end
                    else begin
                        if(mac_done == 1'b1)begin
                            partial_sum <= mac_result;
                            mac_state <= STATE_BIAS_ADD;                    
                            input_feature[7:0] <= bias[8*output_counter +:8];
                            input_temp <= input_feature[7:0];
                            mac_counter <= 4'b0;
                        end
                    end
                end
                
                // Add bias for one output.
                STATE_BIAS_ADD: begin
                // TO DO
                    mac_add <= 1'b1;
                    
                    result <= mac_result;
                    out_data <= out_data + result_q;                    
                    
                    if(output_counter == 0) begin
                        data_a <= bias[BIAS_SIZE*BYTE_SIZE-1:BIAS_SIZE*BYTE_SIZE-8]; //bias[31:24]
                    end                        
                    if(output_counter == 1) begin
                        data_a <= bias[BIAS_SIZE*BYTE_SIZE-9:BIAS_SIZE*BYTE_SIZE-16]; //bias[23:16]
                    end  
                    if(output_counter == 2) begin
                        data_a <= bias[BIAS_SIZE*BYTE_SIZE-17:BIAS_SIZE*BYTE_SIZE-24]; //bias[15:8]
                    end    
                    if(output_counter == 3) begin
                        data_a <= bias[BIAS_SIZE*BYTE_SIZE-25:BIAS_SIZE*BYTE_SIZE-32]; //bias[7:0]
                    end                                        
                    data_c <= partial_sum;
                    if(output_counter<OUTPUT_SIZE-1) begin //counter < 4  0~3
                        if(real_mac_state == 2)begin 
                            output_counter <= output_counter + 4'b1;
                            mac_state <= STATE_IDLE;
                        end                        
                                                           
                    end
                    else begin
                        mac_state <= STATE_DATA_SEND;
                        mac_add <= 1'b0; 
                    end
                end                
                // Send result data to testbench.
                STATE_DATA_SEND: begin
                    if (t_valid) begin
                        t_valid <= 1'b0;
                        mac_state <= STATE_IDLE;
                        out_data <= result_q;                        
                    end
                    else begin
                        t_valid <= 1'b1;
                        output_counter <= 4'b0;
                        mac_state <= STATE_DATA_SEND;
                        
                    end
                end
                default: begin
                    mac_state <= STATE_IDLE;
                    mac_en <= 1'b0;
                    mac_add <= 1'b0;
                    mac_counter <= 4'b0;
                    output_counter <= 4'b0;
                    t_valid  <= 1'b0;
                    out_data <= 32'b0;
                    partial_sum <= 20'b0;
                    
                end
            endcase
        end
    end

    // Assign data for MAC and quantization.
    assign q_7 = (mac_result[19:19] == 1'b1) ?  1 : 0;
    assign over_flow = (mac_result[18:15] == 4'b1111 || mac_result[18:15] == 4'b0000) ? 0 : 1;    
    assign q_6_0 = (over_flow == 0) ? mac_result[14:8] : (q_7 == 1) ? 7'b1111111 : 7'b0000000;    
    assign result_q = q_7 + q_6_0;
    
endmodule
