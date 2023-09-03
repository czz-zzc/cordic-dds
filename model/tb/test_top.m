close all;
clear all;
clc;

fclk = 600e6;                   %   ʱ��Ƶ��
fout = 1e6;                     %   ���Ƶ��
fout_phase = pi/4;              %   ��ʼ��λ
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
[cos_out,sin_out] = cordic_dds(freq_word,phase_word,num_of_sample,K,data_width)

%�����ź�sfdr
sfdr(sin_out,fclk);

fprintf('over------------');





