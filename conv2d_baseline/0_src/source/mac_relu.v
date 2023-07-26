`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// University: SKKU
// Engineer: Youngjin Moon
// 
// Create Date: 2022/07/25 12:30:21
// Design Name: 
// Module Name: mac_relu
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
module mac_relu(
        input clk, rstn,
        input signed [7:0] din_a, din_b,
        input only_add,
        input enable,
        output [7:0] dout
    );
    
    reg signed [21:0] acc;

    wire q_7;
    wire over_flow;
    wire [6:0] q_6_0;
   
    //quantization
    assign q_7 = (acc[21:21] == 1'b1) ?  1 : 0;
    assign over_flow = (acc[20:15] == 6'b111111 || acc[20:15] == 6'b000000) ? 0 : 1;    
    assign q_6_0 = (over_flow == 0) ? acc[14:8] : (q_7 == 1) ? 7'b0000000 : 7'b1111111; 
    /////////////////////////////////////////////////
    //output
    assign dout =  (acc[21:21] == 1) ? 8'b00000000 :{q_7 ,q_6_0};
    /////////////////////////////////////////////////

    always @(posedge clk) begin
        if (rstn == 1'b0) acc <= 'd0;
        
        else if (enable == 1'b1) begin
                if (only_add == 1'b1)  acc <= acc + (din_a <<< 8);
                else                   acc <= acc + (din_a * din_b); 
        end
    end
    
endmodule
