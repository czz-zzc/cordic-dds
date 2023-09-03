
clc;
clear;
close all;
fclose('all');
fs = 600e6;

%load cordic_dds_data
fid1 = fopen('F:\workfile2023\soc\fpga\ip_select\ip_select.sim\sim_1\behav\xsim\xilinx_dds.txt','r');
trans_data1 = trans_fpga_data(fid1);
fclose(fid1);


%load xilinx_dds_data_mode_1
fid3 = fopen('F:\workfile2023\soc\fpga\ip_select\ip_select.sim\sim_1\behav\xsim\my_dds.txt','r');
trans_data3 = trans_fpga_data(fid3);
fclose(fid3);

subplot(2,1,1);
sfdr(trans_data1,fs);
axis([0,300,-60,100]);
text(100,95,'xilinx dds have noise shape');
subplot(2,1,2);
sfdr(trans_data3,fs);
axis([0,300,-60,100]);
text(100,95,'cordic dds');

fclose('all');


fclk = 600e6;                   %   ʱ��Ƶ��
fout = 1e6;                     %   ���Ƶ��
fout_phase = pi/4;                 %   ��ʼ��λ
num_of_sample = 100000;         %   ��������
data_width = 16;                %   ����λ��
freq_word = floor(fout*(2^32)/fclk);            %Ƶ����
phase_word = floor(fout_phase*(2^32)/(2*pi));   %��λ��
                      
%����У׼����
iteration = data_width;   
K = 1.0;
for i=1:1:iteration
	K = K*cos(atan(1/2^(i-1)));
end
K = round(K*2^(data_width-1)); % used for pre-rotation to cancel rotaion gai

%����dds����
[cos_out,sin_out] = cordic_dds(freq_word,phase_word,num_of_sample,K,data_width);
sfdr(sin_out,fclk);
for hh = 1:length(trans_data3)
    diff_data(hh) = trans_data3(hh) - sin_out(hh);
end

sfdr(sin_out,fclk);


