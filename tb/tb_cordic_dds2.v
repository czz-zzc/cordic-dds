`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/24 15:20:35
// Design Name: 
// Module Name: tb_cordic_dds2
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


module tb_cordic_dds2(

    );
    
parameter period=1.667;
reg clk=1'b1;
reg rst=1'b1;
reg [7:0]cnt=1'b0;
integer fp_mydds_w;
integer fp_xilinxdds_w;
always #(period/2)
clk=~clk;
initial
begin
   rst = 1'b1;
   #(100*period)
   rst = 1'b0;
end

wire       sin_vld;
wire [15:0]sin;
wire [15:0]cos;

 parameter OUT_WIDTH = 16;  
 parameter OUT_REGISTER_EN = 1;
// parameter FREQ_WORD_INIITIAL = 32'h6D3A06; //1M dds @ clk=600Mhz
 parameter FREQ_WORD_INIITIAL = 3579139;
 parameter PHASE_WORD_INIITIAL = 0;
 parameter K = (OUT_WIDTH == 12) ? 12'h4DB:((OUT_WIDTH == 14) ? 14'h136E:16'h4DBA);

cordic_dds #(
.OUT_WIDTH(OUT_WIDTH),  
.OUT_REGISTER_EN(OUT_REGISTER_EN),
.FREQ_WORD_INIITIAL(FREQ_WORD_INIITIAL),
.PHASE_WORD_INIITIAL(PHASE_WORD_INIITIAL),
.K(K)
) my_dds_inst(
.clk            (clk),
.rst_n          (!rst),
.cfg_vld        (0),
.cfg_freq_word  (0),
.cfg_phase_word (0),
.sig_vld_o      (sin_vld),
.sin_o          (sin),
.cos_o          (cos)
    );
    
wire m_axis_data_tvalid;
wire [31 : 0] m_axis_data_tdata;
wire [15:0] xilinx_sin;
wire [15:0] xilinx_cos;
assign xilinx_sin = m_axis_data_tdata[31:16];
assign xilinx_cos = m_axis_data_tdata[15:0];
 dds_compiler_0_1 xilinx_dds_inst (
  .aclk(clk),                                  // input wire aclk
  .s_axis_config_tvalid(0),  // input wire s_axis_config_tvalid
  .s_axis_config_tdata(0),    // input wire [63 : 0] s_axis_config_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid),      // output wire m_axis_data_tvalid
  .m_axis_data_tdata(m_axis_data_tdata)        // output wire [31 : 0] m_axis_data_tdata
);   

//write data
initial
begin
   fp_mydds_w = $fopen("my_dds.txt","w"); 
   fp_xilinxdds_w = $fopen("xilinx_dds.txt","w"); 
end
reg [31:0]  record1_cnt;
reg [31:0]  record2_cnt;
parameter SAMPLE_NUM = 100000;

 always@(posedge clk)  
 begin
     if(sin_vld == 1'b1 )begin
        if(record1_cnt < SAMPLE_NUM)begin
             record1_cnt <= record1_cnt +1;
             $fwrite(fp_mydds_w,"%d\n",sin);
        end else begin
             $fclose(fp_mydds_w);
        end 
     end else begin
        record1_cnt <= 'h0;
     end
 end
 
  always@(posedge clk)  
 begin
     if(m_axis_data_tvalid == 1'b1 )begin
        if(record2_cnt < SAMPLE_NUM)begin
             record2_cnt <= record2_cnt +1;
             $fwrite(fp_xilinxdds_w,"%d\n",xilinx_sin);
        end else begin
             $fclose(fp_xilinxdds_w);
        end 
     end else begin
        record2_cnt <= 'h0;
     end
 end
endmodule
