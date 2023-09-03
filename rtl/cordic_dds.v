`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: czz
// 
// Create Date: 2023/07/24 14:38:30
// Design Name: 
// Module Name: cordic_dds
// Project Name: 
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


module cordic_dds #(
 parameter OUT_WIDTH = 16,
 parameter OUT_REGISTER_EN = 1,
 parameter FREQ_WORD_INIITIAL = 32'h6D3A06, //1M dds @ clk=600Mhz
 parameter PHASE_WORD_INIITIAL = 0,
 parameter K = 16'h4DBA
)(
 input                      clk,
 input                      rst_n,
 input                      cfg_vld,
 input      [31:0]          cfg_freq_word,
 input      [31:0]          cfg_phase_word,
 output reg                 sig_vld_o,
 output     [OUT_WIDTH-1:0] sin_o,
 output     [OUT_WIDTH-1:0] cos_o
    );
    

 localparam PRO_DELAY = OUT_WIDTH + OUT_REGISTER_EN;


 reg [31:0] phase_accum;  
 reg [31:0] add_freq_wd;
 reg [4:0]  pro_cnt;
 
 always@(posedge clk or negedge rst_n)  
 begin
     if(rst_n == 1'b0)begin
         phase_accum <= PHASE_WORD_INIITIAL;
         add_freq_wd <= FREQ_WORD_INIITIAL;
     end else if(cfg_vld == 1'b1)begin//load phase and freq word
         phase_accum <= cfg_phase_word;
         add_freq_wd <= cfg_freq_word;
     end else begin
         phase_accum <=  phase_accum + add_freq_wd;
     end
 end
 
 always@(posedge clk or negedge rst_n)  
 begin
     if(rst_n == 1'b0)begin
         pro_cnt <= 'h0;
         sig_vld_o <= 1'b0;
     end else if(pro_cnt == PRO_DELAY) begin
         pro_cnt <=  pro_cnt;
         sig_vld_o <= 1'b1;
     end else begin
         pro_cnt <=  pro_cnt + 1'b1;
         sig_vld_o <= 1'b0;
     end
 end
 
 cordic_sin_cos #(
 .OUT_WIDTH (OUT_WIDTH),
 .OUT_REGISTER_EN(OUT_REGISTER_EN),
 .K(K)
 )cordic_sin_cos_inst(
 .clk    (clk),
 .rst_n  (rst_n),
 .angle  (phase_accum[31:12]),
 .cos_o  (cos_o),
 .sin_o  (sin_o)
  );
  
endmodule
