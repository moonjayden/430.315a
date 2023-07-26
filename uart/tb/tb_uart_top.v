`timescale 1ns / 1ps

module tb_UART_top;

reg 	      clk;
reg 	      rstn;
reg 	      uart_rx;
reg         pushBTN_in;
reg [7:0]   slideSW_in; 
wire[7:0]   led_out;		
wire 	      uart_tx;

//reg [63:0]  uart_in_data;
//reg [63:0]  led_out_data;
//reg [63:0]  slide_in_data;
//reg [63:0]  uart_out_data;

reg [15:0]  uart_in_data;
reg [15:0]  led_out_data;
reg [15:0]  slide_in_data;
reg [15:0]  uart_out_data;

UART_top uUART_top
(
    .clk(clk),
    .rstn(rstn),
    .uart_rx(uart_rx),
    .pushBTN_in(pushBTN_in),
    .slideSW_in(slideSW_in),
    .led_out(led_out),
    .uart_tx(uart_tx)
);    

always #5 clk = ~clk;

initial begin
    clk = 1'b0;
    rstn = 1'b1;
    uart_rx = 1'b1;
    pushBTN_in = 1'b0;
    slideSW_in = 8'b0;

    uart_in_data = 16'b0;
    led_out_data = 16'b0;
    slide_in_data = 16'b0;
    uart_out_data = 16'b0; 

    
//------------------//
//-- UART-Rx Test --//
//------------------//    
    
    repeat (5)
    @ (negedge clk);
    rstn = 0; 
    uart_in_data = 16'h0123; //64'h0123_4567_89ab_cdef; 
    
    repeat (5)
    @ (negedge clk);
    rstn = 1;
  
    //uart_rx_8bit(uart_in_data[63:56]);
    //led_out_data[63:56] = led_out;

    //uart_rx_8bit(uart_in_data[55:48]);
    //led_out_data[55:48] = led_out;
 
    //uart_rx_8bit(uart_in_data[47:40]);
    //led_out_data[47:40] = led_out;


    //uart_rx_8bit(uart_in_data[39:32]);
    //led_out_data[39:32] = led_out;

    //uart_rx_8bit(uart_in_data[31:24]);
   // led_out_data[31:24] = led_out;

    //uart_rx_8bit(uart_in_data[23:16]);
    //led_out_data[23:16] = led_out;

    uart_rx_8bit(uart_in_data[15:8]);
    led_out_data[15:8] = led_out;

    uart_rx_8bit(uart_in_data[7:0]);
    led_out_data[7:0] = led_out;

    repeat (150)
    @ (negedge clk);
 
    if (uart_in_data == led_out_data) begin
        $display ("***********************");
        $display (" UART_Rx is correct !! ");
        $display ("***********************");
    end
    else begin
        $display ("***********************");
        $display ("UART_Rx is incorrect !!");
        $display ("***********************");
    end
        

    repeat (1000)
    @ (negedge clk);
    
    
//------------------//
//-- UART-Tx Test --//
//------------------//

    repeat (5)
    @ (negedge clk);
    //rstn = 0; 
    slide_in_data = 16'hef01; // 64'hef01_2345_6789_abcd;
          
    //repeat (5)
    //@ (negedge clk);
    //rstn = 1;
    
   // pushBTN_in = 1;
   // repeat (150)
   // @ (negedge clk);
   // pushBTN_in = 0;
    /*
    slideSW_in = slide_in_data[63:56];
    
    repeat(5)
    @ (negedge clk);
    pushBTN_in = 1;
    repeat(20000)
    @ (negedge clk);
    uart_tx_8bit(uart_out_data[63:56]);
    repeat(5000)
    @ (negedge clk);
    pushBTN_in = 0;
     repeat(10000000)
    @ (negedge clk);
   

    slideSW_in = slide_in_data[55:48];
    repeat(5)
    @ (negedge clk);
    pushBTN_in = 1;
    repeat(20000)
    @ (negedge clk);
    uart_tx_8bit(uart_out_data[55:48]);
    repeat(5000)
    @ (negedge clk);
    pushBTN_in = 0;
     repeat(10000000)
    @ (negedge clk);

    slideSW_in = slide_in_data[47:40];
    repeat(5)
    @ (negedge clk);
    pushBTN_in = 1;
    repeat(20000)
    @ (negedge clk);
    uart_tx_8bit(uart_out_data[47:40]);
    repeat(5000)
    @ (negedge clk);
    pushBTN_in = 0;
     repeat(10000000)
    @ (negedge clk);

    slideSW_in = slide_in_data[39:32];
    repeat(5)
    @ (negedge clk);
    pushBTN_in = 1;
    repeat(20000)
    @ (negedge clk);
    uart_tx_8bit(uart_out_data[39:32]);
    repeat(5000)
    @ (negedge clk);
    pushBTN_in = 0;
     repeat(10000000)
    @ (negedge clk);

    slideSW_in = slide_in_data[31:24];
    repeat(5)
    @ (negedge clk);
    pushBTN_in = 1;
    repeat(20000)
    @ (negedge clk);
    uart_tx_8bit(uart_out_data[31:24]);
    repeat(5000)
    @ (negedge clk);
    pushBTN_in = 0;
     repeat(10000000)
    @ (negedge clk);

    slideSW_in = slide_in_data[23:16];
    repeat(5)
    @ (negedge clk);
    pushBTN_in = 1;
    repeat(20000)
    @ (negedge clk);
    uart_tx_8bit(uart_out_data[23:16]);
    repeat(5000)
    @ (negedge clk);
    pushBTN_in = 0;
     repeat(10000000)
    @ (negedge clk);
    */
    slideSW_in = slide_in_data[15:8];
    repeat(5)
    @ (negedge clk);
    pushBTN_in = 1;
    repeat(20000)
    @ (negedge clk);
    uart_tx_8bit(uart_out_data[15:8]);
    repeat(5000)
    @ (negedge clk);
    pushBTN_in = 0;
     repeat(10000000)
    @ (negedge clk);


    slideSW_in = slide_in_data[7:0];
    repeat(5)
    @ (negedge clk);
    pushBTN_in = 1;
    repeat(20000)
    @ (negedge clk);
    uart_tx_8bit(uart_out_data[7:0]);
    repeat(5000)
    @ (negedge clk);
    pushBTN_in = 0;
     repeat(10000000)
    @ (negedge clk);
  

    if (slide_in_data == uart_out_data) begin
        $display ("***********************");
        $display (" UART-Tx is correct !! ");
        $display ("***********************");
    end
    else begin
        $display ("***********************");
        $display ("UART-Tx is Incorrect !!");
        $display ("***********************");
    end
     
    $finish;
end


task uart_rx_8bit (input [7:0] data);
    begin
         //  1byte UART data transmission in Pyserial is from LSB to MSB
         //  Data packet = (LSB) Start bit + Data frame[0:7] + Stop bit (MSB)

         // The UART data transmission line is normally held at a high voltage level when it?????s not transmitting data
         #1  uart_rx = 1;

         // Start bit is 0
         repeat (108)
           @ (negedge clk);
         #($random%1)  uart_rx  = 0;

         //  Send the data frame - 8bit
         repeat (108)
           @ (negedge clk);
         #($random%1)  uart_rx  = data[0];

         repeat (108)
           @ (negedge clk);
         #($random%1)  uart_rx  = data[1];

         repeat (108)
           @ (negedge clk);
         #($random%1)  uart_rx  = data[2];

         repeat (108)
           @ (negedge clk);
         #($random%1)  uart_rx  = data[3];

         repeat (108)
           @ (negedge clk);
         #($random%1)  uart_rx  = data[4];

         repeat (108)
           @ (negedge clk);
         #($random%1)  uart_rx  = data[5];

         repeat (108)
           @ (negedge clk);
         #($random%1)  uart_rx = data[6];

         repeat (108)
           @ (negedge clk);
         #($random%1)  uart_rx = data[7];

         // Stop bit is 1
         repeat (108)
           @ (negedge clk);
         #($random%1)   uart_rx = 1;
  end
endtask

task uart_tx_8bit (output reg [7:0] dataout );
      begin
         wait ( uart_tx == 0)    // Start bit
           repeat (20)
           //repeat (108)
             @ (negedge clk);
         //  Send the data frame - 8bit
         repeat (108)
           @ (negedge clk);
         #($random%1)  dataout[0] = uart_tx;

         repeat (108)
           @ (negedge clk);
         #($random%1)  dataout[1] = uart_tx;

         repeat (108)
           @ (negedge clk);
         #($random%1)  dataout[2] = uart_tx;

         repeat (108)
           @ (negedge clk);
         #($random%1)  dataout[3] = uart_tx;

         repeat (108)
           @ (negedge clk);
         #($random%1)  dataout[4] = uart_tx ;

         repeat (108)
           @ (negedge clk);
         #($random%1)  dataout[5] = uart_tx;

         repeat (108)
           @ (negedge clk);
         #($random%1)  dataout[6] = uart_tx;

         repeat (108)
           @ (negedge clk);
         #($random%1)  dataout[7] = uart_tx;

         // Stop bit is 1
         wait (uart_tx);

    end
endtask
 
endmodule
