`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// University: SKKU
// Engineer: Youngjin Moon
// 
// Create Date: 2022/08/03 13:34:51
// Design Name: 
// Module Name: core
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


module core(
        // system
        input               clk, rstn,
        
        // param bank
        output [15:0]       pbank_addr,
        input [7:0]         pdata,
        output              pbank_en,
        
        // fmap bank read
        output [14:0]       fbank_raddr,
        input [7:0]         fdata_r,
        output              fbank_ren,
        
        // fmap bank write
        output [14:0]       fbank_waddr,
        output [7:0]        fdata_w,
        output              fbank_wen,
        
        // controller
        input               init,
        output reg          done,
        output reg [3:0]    label
    );
    
    localparam  IDLE        = 3'd0,
                CONV1_DW    = 3'd1,
                CONV1_PW    = 3'd2,
                CONV2_DW    = 3'd3,
                CONV2_PW    = 3'd4,
                CONV3_DW    = 3'd5,
                CONV3_PW    = 3'd6
                ;
    
    reg [2:0] state;
    reg [5:0] layer_init;
    wire [5:0] layer_done;
    
    // conv1_dw wire
    wire [15:0] pbank_addr_conv1_dw;
    wire [14:0] fbank_raddr_conv1_dw, fbank_waddr_conv1_dw;
    wire pbank_en_conv1_dw, fbank_ren_conv1_dw, fbank_wen_conv1_dw;
    wire [7:0] fdata_w_conv1_dw;
    
    // conv1_pw wire
    wire [15:0] pbank_addr_conv1_pw;
    wire [14:0] fbank_raddr_conv1_pw, fbank_waddr_conv1_pw;
    wire pbank_en_conv1_pw, fbank_ren_conv1_pw, fbank_wen_conv1_pw;
    wire [7:0] fdata_w_conv1_pw;
    
    // conv2_dw wire
    wire [15:0] pbank_addr_conv2_dw;
    wire [14:0] fbank_raddr_conv2_dw, fbank_waddr_conv2_dw;
    wire pbank_en_conv2_dw, fbank_ren_conv2_dw, fbank_wen_conv2_dw;
    wire [7:0] fdata_w_conv2_dw;
    
    // conv2_pw wire
    wire [15:0] pbank_addr_conv2_pw;
    wire [14:0] fbank_raddr_conv2_pw, fbank_waddr_conv2_pw;
    wire pbank_en_conv2_pw, fbank_ren_conv2_pw, fbank_wen_conv2_pw;
    wire [7:0] fdata_w_conv2_pw;
    
    // conv3_dw wire
    wire [15:0] pbank_addr_conv3_dw;
    wire [14:0] fbank_raddr_conv3_dw, fbank_waddr_conv3_dw;
    wire pbank_en_conv3_dw, fbank_ren_conv3_dw, fbank_wen_conv3_dw;
    wire [7:0] fdata_w_conv3_dw;
    
    // conv3_pw wire
    wire [15:0] pbank_addr_conv3_pw;
    wire [14:0] fbank_raddr_conv3_pw, fbank_waddr_conv3_pw;
    wire pbank_en_conv3_pw, fbank_ren_conv3_pw, fbank_wen_conv3_pw;
    wire [7:0] fdata_w_conv3_pw;
    wire [3:0] label_wire;
    
    
    assign pbank_addr   =   (state == CONV3_PW) ? pbank_addr_conv3_pw : 
                            (state == CONV3_DW) ? pbank_addr_conv3_dw : 
                            (state == CONV2_PW) ? pbank_addr_conv2_pw : 
                            (state == CONV2_DW) ? pbank_addr_conv2_dw : 
                            (state == CONV1_PW) ? pbank_addr_conv1_pw : 
                                                  pbank_addr_conv1_dw;
    assign fbank_raddr  =   (state == CONV3_PW) ? fbank_raddr_conv3_pw : 
                            (state == CONV3_DW) ? fbank_raddr_conv3_dw : 
                            (state == CONV2_PW) ? fbank_raddr_conv2_pw : 
                            (state == CONV2_DW) ? fbank_raddr_conv2_dw : 
                            (state == CONV1_PW) ? fbank_raddr_conv1_pw : 
                                                  fbank_raddr_conv1_dw;
    assign fbank_waddr  =   (state == CONV3_PW) ? fbank_waddr_conv3_pw : 
                            (state == CONV3_DW) ? fbank_waddr_conv3_dw : 
                            (state == CONV2_PW) ? fbank_waddr_conv2_pw : 
                            (state == CONV2_DW) ? fbank_waddr_conv2_dw : 
                            (state == CONV1_PW) ? fbank_waddr_conv1_pw : 
                                                  fbank_waddr_conv1_dw;
    assign pbank_en     =   (state == CONV3_PW) ? pbank_en_conv3_pw : 
                            (state == CONV3_DW) ? pbank_en_conv3_dw : 
                            (state == CONV2_PW) ? pbank_en_conv2_pw : 
                            (state == CONV2_DW) ? pbank_en_conv2_dw : 
                            (state == CONV1_PW) ? pbank_en_conv1_pw : 
                                                  pbank_en_conv1_dw;
    assign fbank_ren    =   (state == CONV3_PW) ? fbank_ren_conv3_pw : 
                            (state == CONV3_DW) ? fbank_ren_conv3_dw : 
                            (state == CONV2_PW) ? fbank_ren_conv2_pw : 
                            (state == CONV2_DW) ? fbank_ren_conv2_dw : 
                            (state == CONV1_PW) ? fbank_ren_conv1_pw : 
                                                  fbank_ren_conv1_dw;
    assign fbank_wen    =   (state == CONV3_PW) ? fbank_wen_conv3_pw : 
                            (state == CONV3_DW) ? fbank_wen_conv3_dw : 
                            (state == CONV2_PW) ? fbank_wen_conv2_pw : 
                            (state == CONV2_DW) ? fbank_wen_conv2_dw : 
                            (state == CONV1_PW) ? fbank_wen_conv1_pw : 
                                                  fbank_wen_conv1_dw;
    assign fdata_w      =   (state == CONV3_PW) ? fdata_w_conv3_pw : 
                            (state == CONV3_DW) ? fdata_w_conv3_dw : 
                            (state == CONV2_PW) ? fdata_w_conv2_pw : 
                            (state == CONV2_DW) ? fdata_w_conv2_dw : 
                            (state == CONV1_PW) ? fdata_w_conv1_pw : 
                                                  fdata_w_conv1_dw;
    
    conv1_dw uconv1_dw (.clk(clk), .rstn(rstn), .init(layer_init[0]), .done(layer_done[0]), .pbank_addr(pbank_addr_conv1_dw), .pdata(pdata), 
                    .pbank_en(pbank_en_conv1_dw), .fbank_raddr(fbank_raddr_conv1_dw), .fdata_r(fdata_r), .fbank_ren(fbank_ren_conv1_dw), 
                    .fbank_waddr(fbank_waddr_conv1_dw), .fdata_w(fdata_w_conv1_dw), .fbank_wen(fbank_wen_conv1_dw));
    conv1_pw uconv1_pw (.clk(clk), .rstn(rstn), .init(layer_init[1]), .done(layer_done[1]), .pbank_addr(pbank_addr_conv1_pw), .pdata(pdata), 
                    .pbank_en(pbank_en_conv1_pw), .fbank_raddr(fbank_raddr_conv1_pw), .fdata_r(fdata_r), .fbank_ren(fbank_ren_conv1_pw), 
                    .fbank_waddr(fbank_waddr_conv1_pw), .fdata_w(fdata_w_conv1_pw), .fbank_wen(fbank_wen_conv1_pw));
    conv2_dw uconv2_dw (.clk(clk), .rstn(rstn), .init(layer_init[2]), .done(layer_done[2]), .pbank_addr(pbank_addr_conv2_dw), .pdata(pdata), 
                    .pbank_en(pbank_en_conv2_dw), .fbank_raddr(fbank_raddr_conv2_dw), .fdata_r(fdata_r), .fbank_ren(fbank_ren_conv2_dw), 
                    .fbank_waddr(fbank_waddr_conv2_dw), .fdata_w(fdata_w_conv2_dw), .fbank_wen(fbank_wen_conv2_dw));
    conv2_pw uconv2_pw (.clk(clk), .rstn(rstn), .init(layer_init[3]), .done(layer_done[3]), .pbank_addr(pbank_addr_conv2_pw), .pdata(pdata), 
                    .pbank_en(pbank_en_conv2_pw), .fbank_raddr(fbank_raddr_conv2_pw), .fdata_r(fdata_r), .fbank_ren(fbank_ren_conv2_pw), 
                    .fbank_waddr(fbank_waddr_conv2_pw), .fdata_w(fdata_w_conv2_pw), .fbank_wen(fbank_wen_conv2_pw));
    conv3_dw uconv3_dw (.clk(clk), .rstn(rstn), .init(layer_init[4]), .done(layer_done[4]), .pbank_addr(pbank_addr_conv3_dw), .pdata(pdata), 
                    .pbank_en(pbank_en_conv3_dw), .fbank_raddr(fbank_raddr_conv3_dw), .fdata_r(fdata_r), .fbank_ren(fbank_ren_conv3_dw), 
                    .fbank_waddr(fbank_waddr_conv3_dw), .fdata_w(fdata_w_conv3_dw), .fbank_wen(fbank_wen_conv3_dw));
    conv3_pw uconv3_pw (.clk(clk), .rstn(rstn), .init(layer_init[5]), .done(layer_done[5]), .pbank_addr(pbank_addr_conv3_pw), .pdata(pdata), 
                    .pbank_en(pbank_en_conv3_pw), .fbank_raddr(fbank_raddr_conv3_pw), .fdata_r(fdata_r), .fbank_ren(fbank_ren_conv3_pw), 
                    .fbank_waddr(fbank_waddr_conv3_pw), .fdata_w(fdata_w_conv3_pw), .fbank_wen(fbank_wen_conv3_pw), .label(label_wire));
    
    always @(posedge clk) begin
        if (rstn == 1'b0) begin
            done <= 'd0;
            state <= IDLE;
            label <= 4'd0;
        end
        else begin
            // TO DO
            layer_init <= 5'd0;
            done <= 'd0;
            case(state)
                IDLE : begin
                    if (init == 1'b1) begin
                        state <= CONV1_DW;
                        layer_init[0] <= 1'b1;
                    end
                end
                CONV1_DW : begin
                    if (layer_done[0] == 1'b1) begin
                        state <= CONV1_PW;
                        layer_init[1] <= 1'b1;
                    end
                end
                CONV1_PW : begin
                    if (layer_done[1] == 1'b1) begin
                        state <= CONV2_DW;
                        layer_init[2] <= 1'b1;
                    end
                end
                CONV2_DW : begin
                    if (layer_done[2] == 1'b1) begin
                        state <= CONV2_PW;
                        layer_init[3] <= 1'b1;
                    end
                end
                CONV2_PW : begin
                    if (layer_done[3] == 1'b1) begin
                        state <= CONV3_DW;
                        layer_init[4] <= 1'b1;
                    end
                end
                CONV3_DW : begin
                    if (layer_done[4] == 1'b1) begin
                        state <= CONV3_PW;
                        layer_init[5] <= 1'b1;
                    end
                end
                CONV3_PW : begin
                    if (layer_done[5] == 1'b1) begin
                        state <= IDLE;
                        done <= 1'b1;
                        label <= label_wire;
                    end
                end               
                default: state <= IDLE;
            endcase
        end
    end
    
endmodule
