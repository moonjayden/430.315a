
module mac #(
    parameter integer A_BITWIDTH = 8,
    parameter integer B_BITWIDTH = A_BITWIDTH,
    parameter integer OUT_BITWIDTH = 20,
    parameter integer C_BITWIDTH = OUT_BITWIDTH - 1
)
(
    input                                   clk,
    input                                   rstn,
    input                                   en,
    input                                   add,
    input  [A_BITWIDTH-1:0]                 data_a, 
    input  [B_BITWIDTH-1:0]                 data_b,
    input  [C_BITWIDTH-1:0]                 data_c,
    output reg                              done,
    output [OUT_BITWIDTH-1:0]               out
    );

    localparam 
        STATE_IDLE = 2'b00, 
        STATE_MULT = 2'b01, 
        STATE_ACCM = 2'b10;
        
    reg [1:0]                               state;

    reg signed [OUT_BITWIDTH-1:0]           out_temp;

    reg signed [A_BITWIDTH-1:0]             data_a_bf;
    reg signed [B_BITWIDTH-1:0]             data_b_bf;
    reg signed [C_BITWIDTH-1:0]             data_c_bf;

    assign out = out_temp;

    always @ (posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= STATE_IDLE;
            
            data_a_bf <= {A_BITWIDTH{1'b0}};
            data_b_bf <= {B_BITWIDTH{1'b0}};
            data_c_bf <= {C_BITWIDTH{1'b0}};

            done <= 1'b0;
            out_temp <={OUT_BITWIDTH{1'b0}};
        end
        else begin
            case(state)
                STATE_IDLE: begin
                // TO DO
                // Done flag reset!
                done <= 1'b0;
                    if(en && !done) begin
                    // If en == 1 and done != 1, then running state.
                    // And capture data_a, data_b, data_c to buffer
                        state <= STATE_MULT;
                        data_a_bf <= data_a;
                        data_b_bf <= data_b;
                        data_c_bf <= data_c;
                    end
                    else begin
                    // If not, just waiting for condition.
                    end
                end
                STATE_MULT: begin
                // TO DO
                    if (!add) begin
                    // If add signal is low, do muliply with data_a_bf and data_b_bf.
                        state <= STATE_ACCM;
                        out_temp <= data_a_bf * data_b_bf;
                    end
                    else begin
                    // If add signal is high, shift data_a_bf to match bit representation.     
                        state <= STATE_ACCM;
                        out_temp <= data_a_bf<<<8;                        
                    end
                end
                STATE_ACCM: begin
                // TO DO
                // Do add and make output 'done' flag high.( done = 1)
                    state <= STATE_IDLE;
                    out_temp <= out_temp + data_c_bf;
                    done <= 1;                    
                end
                default:;
           endcase
       end
    end
endmodule
