`timescale 1ns / 1ps

module UART(
    input clk,
    input rstn,
    input uart_rx,
    input [7:0] tdata,
    input tdata_req,
    output [7:0] rdata,
    output rdata_valid,
    output uart_tx
    );

    receiver    #(108) rcv (.clk(clk), .rstn(rstn), .uart_rx(uart_rx), .rdata(rdata), .rdata_valid(rdata_valid));
    transmitter #(108) trm (.clk(clk), .rstn(rstn), .uart_tx(uart_tx), .tdata(tdata), .tdata_req(tdata_req));

endmodule


module receiver
    # (parameter baud_rate = 108)
    (
        input               clk, rstn,
        input               uart_rx,
        output reg [7:0]    rdata,
        output reg          rdata_valid
    );
    
    localparam  IDLE = 1'b0,
                RCV  = 1'b1;
                
    reg uart_rx_buf1, uart_rx_buf2;
    reg state, next_state;
    reg [3:0] init_count;
    reg [6:0] baud_rate_count;
    reg [3:0] receive_bit;
    
    // next state
    always @(*) begin
        case(state)
           IDLE : begin
    // Task1-1. Describe the Next State transition conditions when IDLE
               if(init_count == 4'b1111) begin
                   next_state = RCV;
               end
               else begin
                   next_state = IDLE;
               end
//___________________________________________________________________//
            end
            RCV : begin
// Task1-2. Describe the Next State transition conditions when RCV
                if(baud_rate_count == baud_rate && receive_bit == 4'b1000) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = RCV;
                end
    //____________________________________________________________________//                                  
            end
            default : begin
                next_state = IDLE;
            end
        endcase
    end
    
    //processing procedure
    always @(posedge clk) begin
    
        state <= next_state;
        if (rstn == 1'b0) begin
            state <= IDLE;
            init_count <= 'd0;
            baud_rate_count <= 'd0;
            receive_bit <= 'd0;
            rdata <= 'd0;
            rdata_valid <= 'd0;
            {uart_rx_buf1, uart_rx_buf2} <= 2'b11;
        end
        else begin
            uart_rx_buf1 <= uart_rx;
            uart_rx_buf2 <= uart_rx_buf1;
            case(state)
    // Task2-1. Describe the processing procedures when IDLE
    //____________________________________________________________________//
                IDLE : begin
                    baud_rate_count <= 'd0;
                    receive_bit <= 'd0;
                    if(uart_rx_buf2 == 1'b0) begin //uart_rx_buf2 = low --> init_count ++
                        init_count <= init_count + 4'd1;
                    end
                    if(init_count == 4'b1111) begin
                        init_count <= 4'd0;
                    end
                end
    /*********************************TODO*******************************/
    // Task2-2. Describe the processing procedures when RCV
    //____________________________________________________________________//
                RCV : begin
                    baud_rate_count <= baud_rate_count +'d1; //every clock cyle --> baud_rate_count ++
                    if(baud_rate_count == baud_rate) begin
                        baud_rate_count <= 'd0;
                        rdata <= rdata >> 1;
                        rdata[7:7] <= uart_rx_buf2;
                        receive_bit <= receive_bit + 4'd1;
                        if(receive_bit == 4'd7) begin
                            rdata_valid <= 1'b1;
                        end
                    end
                    else begin
                        rdata_valid <= 1'd0;
                     end
                end
                default : ;
            endcase
        end
        
    end
    
endmodule

module transmitter
    # (parameter baud_rate = 108)  // (100,000,000 Hz / 921,000 bps) = 108
    (
        input           clk, rstn,
        output reg      uart_tx,
        input [7:0]     tdata,
        input           tdata_req
    );
    
    localparam  IDLE    = 1'b0,
                TRM     = 1'b1;
                
    reg state, next_state;
    reg [6:0] baud_rate_count;
    reg [3:0] transmit_bit;
    reg [7:0] data;
    
    // next state
    always @(*) begin
        case(state)
            IDLE : begin
                if (tdata_req == 1'b1)                                      next_state = TRM;
                else                                                        next_state = state;
            end
            TRM : begin
                if (baud_rate_count == baud_rate && transmit_bit == 4'd9)   next_state = IDLE;
                else                                                        next_state = state;
            end
            default: next_state = IDLE;
        endcase
    end
    //processing procedure
    always @(posedge clk) begin
        if (rstn == 1'b0) begin
            state <= IDLE;
            baud_rate_count <= 'd0;
            uart_tx <= 'b1;
            data <= 'd0;
            transmit_bit <= 'd0;
        end
        else begin
            baud_rate_count <= 'd0;
            state <= next_state;
            case(state)

                IDLE : begin
                    if (tdata_req == 1'b1) begin
                        data <= tdata;
                        uart_tx <= 1'b0;
                    end
                end
 
                TRM : begin
                    if (baud_rate_count == baud_rate) begin
                        if (transmit_bit == 4'd9) begin
                            //tdata_ready <= 1'b1;
                            transmit_bit <= 4'd0;
                        end
                        else transmit_bit <= transmit_bit + 1;
                        {data, uart_tx} <= {1'b1, data};
                    end
                    else baud_rate_count <= baud_rate_count + 1;
                end
            endcase
        end
    end

endmodule
