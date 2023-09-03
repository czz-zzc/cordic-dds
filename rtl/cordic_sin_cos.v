`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: czz
// 
// Create Date: 2023/07/24 11:07:30
// Design Name: 
// Module Name: cordic_sin_cos
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// this module generate cos/sin sigal by cordic arithmetic.
// the OUT_WIDTH can be 12 14 16
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// the delay = OUT_WIDTH + OUT_REGISTER_EN + 1
//////////////////////////////////////////////////////////////////////////////////


module cordic_sin_cos#(
 parameter OUT_WIDTH = 16,
 parameter OUT_REGISTER_EN = 1,
 parameter K = 16'h4DBA
)(
 input                       clk,
 input                       rst_n,
 input  [19:0]               angle,
 output [OUT_WIDTH-1:0]      cos_o,
 output [OUT_WIDTH-1:0]      sin_o
    );

    localparam OUT_WIDTH_EXP = 4;
    localparam K_EXP = {K,{OUT_WIDTH_EXP{1'b0}}};
    localparam ITERATION_NUM = OUT_WIDTH;
    localparam [16*21-1:0] actan_table =  { 21'h20000,21'h12E40,21'h09FB4,21'h05111,
                                            21'h028B1,21'h0145D,21'h00A2F,21'h00518,
                                            21'h0028C,21'h00146,21'h000A3,21'h00051,
                                            21'h00029,21'h00014,21'h0000A,21'h00005};

    reg  signed [OUT_WIDTH+OUT_WIDTH_EXP:0]   real_x[0:ITERATION_NUM];
    reg  signed [OUT_WIDTH+OUT_WIDTH_EXP:0]   imag_y[0:ITERATION_NUM];
    reg  signed [20:0]                        angl_z[0:ITERATION_NUM];
    wire        [1:0]                         quadrant;
    reg  signed [OUT_WIDTH+OUT_WIDTH_EXP:0]   init_x;
    reg  signed [OUT_WIDTH+OUT_WIDTH_EXP:0]   init_y;
    reg  signed [20:0]                        init_z;
   
    assign quadrant = angle[19:18];
   
    //quadrant map
    always @(quadrant,angle) begin
        case (quadrant)
            2'b00:begin
                init_x = K_EXP;
                init_y = 0;
                init_z = {1'b0,angle};
            end
            2'b01:begin
                init_x = -K_EXP;
                init_y = 0;
                init_z = {3'b111,angle[17:0]};
            end
            2'b10: begin
                init_x = -K_EXP;
                init_y = 0;
                init_z = {3'b000,angle[17:0]};
            end
            2'b11:begin
                init_x = K_EXP;
                init_y = 0;
                init_z = {1'b1,angle};
            end
            default:begin
                init_x = 0;
                init_y = 0;
                init_z = 0;
            end
        endcase
    end
   
    //init reg
    always@(posedge clk or negedge rst_n)  
    begin
        if(rst_n == 1'b0)begin
            real_x[0] <= 'h0;
            imag_y[0] <= 'h0;
            angl_z[0] <= 'h0;
        end else begin
            real_x[0] <= init_x;
            imag_y[0] <= init_y;
            angl_z[0] <= init_z;
        end
    end
   
    //cordic iteration
    genvar i;
    generate
        for (i = 1 ; i <= ITERATION_NUM; i= i + 1)
        begin: iter
                always@(posedge clk or negedge rst_n)  
                    begin
                        if(rst_n == 1'b0)begin
                            real_x[i] <= 'h0;
                            imag_y[i] <= 'h0;
                            angl_z[i] <= 'h0;
                        end else if(angl_z[i-1][20]==1'b1)begin //polarity judge
                            real_x[i] <= real_x[i-1] + ( imag_y[i-1]>>>(i-1) );
                            imag_y[i] <= imag_y[i-1] - ( real_x[i-1]>>>(i-1) );
                            angl_z[i] <= angl_z[i-1] + $signed(actan_table[(21*(16-i+1)-1)-:21]);
                        end else begin
                            real_x[i] <= real_x[i-1] - ( imag_y[i-1]>>>(i-1) );
                            imag_y[i] <= imag_y[i-1] + ( real_x[i-1]>>>(i-1) );
                            angl_z[i] <= angl_z[i-1] - $signed(actan_table[(21*(16-i+1)-1)-:21]);
                        end
                    end
        end
    endgenerate
   
    //overflow process
    wire [OUT_WIDTH:0]   real_x_cut;
    wire [OUT_WIDTH:0]   imag_y_cut;
    reg  [OUT_WIDTH-1:0] cos_over_pro;
    reg  [OUT_WIDTH-1:0] sin_over_pro;
    assign real_x_cut = real_x[ITERATION_NUM][OUT_WIDTH+OUT_WIDTH_EXP:OUT_WIDTH_EXP];
    assign imag_y_cut = imag_y[ITERATION_NUM][OUT_WIDTH+OUT_WIDTH_EXP:OUT_WIDTH_EXP];
    always@(*)begin
            case(real_x_cut[OUT_WIDTH:OUT_WIDTH-1])
                2'b00:cos_over_pro = real_x_cut[OUT_WIDTH-1:0];
                2'b01:cos_over_pro = {1'b0,{(OUT_WIDTH-1){1'b1}}};
                2'b10:cos_over_pro = {1'b1,{(OUT_WIDTH-2){1'b0}},1'b1};
                2'b11:cos_over_pro = real_x_cut[OUT_WIDTH-1:0];
                default:cos_over_pro = real_x_cut[OUT_WIDTH-1:0];
            endcase
    end
    
    always@(*)begin
            case(imag_y_cut[OUT_WIDTH:OUT_WIDTH-1])
                2'b00:sin_over_pro = imag_y_cut[OUT_WIDTH-1:0];
                2'b01:sin_over_pro = {1'b0,{(OUT_WIDTH-1){1'b1}}};
                2'b10:sin_over_pro = {1'b1,{(OUT_WIDTH-2){1'b0}},1'b1};
                2'b11:sin_over_pro = imag_y_cut[OUT_WIDTH-1:0];
                default:sin_over_pro = imag_y_cut[OUT_WIDTH-1:0];
            endcase
    end
    

    //out
    generate if (OUT_REGISTER_EN == 1'b1) begin:reg_out
        reg [OUT_WIDTH-1:0] cos_r;
        reg [OUT_WIDTH-1:0] sin_r;
        always@(posedge clk or negedge rst_n) begin
            if(rst_n == 1'b0)begin
                cos_r <= 'h0;
                sin_r <= 'h0;
            end else begin
                cos_r <= cos_over_pro;
                sin_r <= sin_over_pro;
            end
        end
        assign cos_o = cos_r;
        assign sin_o = sin_r;
    end else begin:no_reg_out
        assign cos_o = cos_over_pro;
        assign sin_o = sin_over_pro;
    end
    endgenerate
   
endmodule
