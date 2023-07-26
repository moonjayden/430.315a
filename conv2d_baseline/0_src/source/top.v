`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// This file for Borad Test.
// Do not use this for Testbench simulation
//////////////////////////////////////////////////////////////////////////////////

module top(
    // system
    input       clk,
    input       rstn,
    
    // uart
    input       uart_rx,
    output      uart_tx,

    output      led_out
    );
    
    // uart - top_controller wire
    wire [7:0]  rdata;
    wire        rdata_valid;
    wire [7:0]  tdata;
    wire        tdata_req;
    wire        tdata_ready;
    
    // param_bank - core wire
    wire [15:0] pbank_addr;
    wire [7:0]  pdata;
    wire        pbank_en;
    
    // fmap_bank read wire
    wire [14:0] fbank_raddr;
    wire [7:0]  fdata_r;
    wire        fbank_ren;
    
    // fmap_bank write wire
    wire [14:0] fbank_waddr;
    wire [7:0]  fdata_w;
    wire        fbank_wen;
    
    // fmap_bank core side write wire
    wire [14:0] fbank_waddr_c;
    wire [7:0]  fdata_w_c;
    wire        fbank_wen_c;
    
    // fmap_bank top_controller side write wire
    wire [14:0] fbank_waddr_t;
    wire [7:0]  fdata_w_t;
    wire        fbank_wen_t;
    
    // fmap_bank selecter
    reg         fbank_sel;

    // top_controller - core wire
    wire        init;
    wire        done;
    wire [3:0]  label;

    reg led;
    
    assign led_out = led;
    
    assign fbank_waddr =    (fbank_sel == 1'b0) ? fbank_waddr_t : fbank_waddr_c;
    assign fdata_w =        (fbank_sel == 1'b0) ? fdata_w_t     : fdata_w_c;
    assign fbank_wen =      (fbank_sel == 1'b0) ? fbank_wen_t   : fbank_wen_c;
    
    uart_0          myuart          (.clk(clk), .rstn(rstn), .uart_rx(uart_rx), .rdata(rdata), .rdata_valid(rdata_valid), .uart_tx(uart_tx), .tdata(tdata), .tdata_req(tdata_req), .tdata_ready(tdata_ready));
    blk_mem_gen_0   param_bank      (.addra(pbank_addr), .clka(clk), .douta(pdata), .ena(pbank_en));
    blk_mem_gen_1   fmap_bank       (.addra(fbank_waddr), .clka(clk), .dina(fdata_w), .wea(fbank_wen), .addrb(fbank_raddr), .clkb(clk), .doutb(fdata_r), .enb(fbank_ren));
    top_controller_0
                    t_ctrl          (.clk(clk), .rstn(rstn), .rdata(rdata), .rdata_valid(rdata_valid), .tdata(tdata), .tdata_req(tdata_req), .tdata_ready(tdata_ready),
                                    .fbank_waddr(fbank_waddr_t), .fdata_w(fdata_w_t), .fbank_wen(fbank_wen_t), .init(init), .done(done), .label(label));
    core            student_module  (.clk(clk), .rstn(rstn), .pbank_addr(pbank_addr), .pdata(pdata), .pbank_en(pbank_en), .fbank_raddr(fbank_raddr), .fdata_r(fdata_r), .fbank_ren(fbank_ren),
                                    .fbank_waddr(fbank_waddr_c), .fdata_w(fdata_w_c), .fbank_wen(fbank_wen_c), .init(init), .done(done), .label(label));
    
    always @(posedge clk) begin
        if (rstn == 1'b0)  begin
            fbank_sel <= 1'b0;
            led <= 1'b0;
        end
        else begin
            if (init == 1'b1) begin
                fbank_sel <= 1'b1;
                led <= 1'b1;
            end       
            else if (done == 1'b1)  begin
                fbank_sel <= 1'b0;
                led <= 1'b0;                
            end
        end
    end
    
endmodule

