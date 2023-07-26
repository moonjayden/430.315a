`timescale 1ns / 1ps

module GPIO(
    input clk,
    input rstn,
    input [7:0] in_data,
    input in_valid,
    input pushBTN_in,
    input [7:0] slideSW_in,
    output [7:0] led_out,
    output [7:0] out_data,
    output out_ready
    );

    LEDindicator uLEDindicator(.clk(clk), .rstn(rstn), .in_data(in_data), .in_valid(in_valid), .led_out(led_out));
    get_BTNinfo uget_BTNinfo(.clk(clk), .rstn(rstn), .pushBTN_in(pushBTN_in), .slideSW_in(slideSW_in), .out_data(out_data), .out_ready(out_ready));

endmodule


module LEDindicator
    (
        input               clk, rstn,
        input [7:0]         in_data,
        input               in_valid,
        output reg [7:0]    led_out
    );

    always @(posedge clk) begin
        if (!rstn) begin
            led_out <= 8'b0;

        end
        else begin
            if(in_valid) begin
                led_out <= in_data;
            end
            else begin
                led_out <= led_out;
            end
        end
    end
    
endmodule

module get_BTNinfo
    (
        input               clk, rstn,
        input               pushBTN_in,
        input [7:0]         slideSW_in,
        output reg [7:0]    out_data,
        output reg          out_ready
    );

    reg transmit;
    reg [7:0] temp;
    reg button_ff1; 
    reg button_ff2; 
    reg [14:0]debounce_count;
    reg [23:0]outputInterval_count; 

    //buffering for preventing metastability problem
    always @(posedge clk) begin
        if (!rstn) begin
            button_ff1 <= 1'b0;
            button_ff2 <= 1'b0;
        end
        else begin
            button_ff1 <= pushBTN_in;
            button_ff2 <= button_ff1;
        end
    end

    //debouncing
    always @(posedge clk) begin
        if (!rstn) begin
            transmit <= 1'b0; //transmit Request
            debounce_count <= 15'd0; //Counter for Push button debouncing
            outputInterval_count <= 24'd0; //Counter for Ignoring repeated Input
        end
        else begin
            //outputInterval_count = 0
            if (outputInterval_count == 24'd0) begin  
                if (debounce_count != 15'd0) begin  
                    if (debounce_count == 15'd20000) begin   //deboune_counter = 20,000
                        debounce_count <= 15'd0;  
                        if ((button_ff2 == 1'b1) && (transmit == 1'b0)) begin     
                            transmit <= 1'b1;  // Request transmit
                            outputInterval_count <= 24'd1;  
                        end
                        else begin
                            transmit <= 1'b0; 
                            outputInterval_count <= 24'd0;
                        end
                    end     
                    else begin  //debounce_counter < 20,000  
                        transmit <= 1'b0;  
                        debounce_count <= debounce_count + 1;
                    end
                end
                else begin //debounce_counter = 0
                    if ((button_ff2 == 1'b0) && (button_ff1 == 1'b1)) begin   
                        debounce_count <= 15'd1;
                    end
                    else begin
                        debounce_count <= 15'd0;  //Otherwise Stay 
                    end
                end
            end 
            //outputInterval_count != 0
            else begin
                if (outputInterval_count == 24'd10000000) begin  
                    outputInterval_count <= 24'd0; 
                end
                else if (outputInterval_count == 24'd2) begin
                    transmit = 1'b0;
                    outputInterval_count <= outputInterval_count + 1;
                end
                else begin
                    outputInterval_count <= outputInterval_count + 1;  
                end
            end        
        end
    end    

    //out data 
    always @(posedge clk) begin
        if (!rstn) begin
            out_data <= 8'b0;
            out_ready <= 1'b0;
        end
        else begin
            temp <= slideSW_in;
            if (transmit == 1'b1) begin 
                out_ready <= 1'b1;
                out_data <= temp;  
            end
            else begin
                out_ready <= 1'b0;   
                out_data <= out_data;
            end       
        end
    end

endmodule
