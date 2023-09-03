close all;
clear all;
clc;

fclk = 600e6;                   %   时钟频率
fout = 1e6;                     %   输出频率
fout_phase = pi/4;              %   初始相位
num_of_sample = 100000;         %   采样点数
data_width = 16;                %   数据位宽
freq_word = floor(fout*(2^32)/fclk);            %频率字
phase_word = floor(fout_phase*(2^32)/(2*pi));   %相位字
                      
%计算校准因子
iteration = data_width;   
K = 1.0;
for i=1:1:iteration
	K = K*cos(atan(1/2^(i-1)));
end
K = round(K*2^(data_width-1)); % used for pre-rotation to cancel rotaion gai

%生成dds波形
[cos_out,sin_out] = cordic_dds(freq_word,phase_word,num_of_sample,K,data_width)

%计算信号sfdr
sfdr(sin_out,fclk);

fprintf('over------------');





