`timescale 1ns / 1ps

module UART_top(
    input clk,
    input rstn,
    input uart_rx,
    input pushBTN_in,  
    input [7:0] slideSW_in,
    output [7:0] led_out,
    output uart_tx
    );


    wire [7:0] rdata;
    wire rdata_valid;
    wire [7:0] tdata;   
    wire tdata_req;

    UART uuart (.clk(clk), .rstn(rstn), .uart_rx(uart_rx), .rdata(rdata), .rdata_valid(rdata_valid), .tdata(tdata), .tdata_req(tdata_req), .uart_tx(uart_tx));
    GPIO ugpio (.clk(clk), .rstn(rstn), .in_data(rdata), .in_valid(rdata_valid), .led_out(led_out), .pushBTN_in(pushBTN_in), .slideSW_in(slideSW_in), .out_data(tdata), .out_ready(tdata_req));

 
endmodule