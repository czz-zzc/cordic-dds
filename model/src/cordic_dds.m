function [cos_out,sin_out] = cordic_dds(freq_word,phase_word,num_of_sample,K,data_width)
%%%%%%%%%%%%%%%%%% 参数说明 %%%%%%%%%%%%%%%%%%
%%%    fclk             时钟频率
%%%    freq_word        频率字
%%%    phase_word       初始相位字
%%%    num_of_sample    采样点数
%%%    K                校准因子
%%%    data_widtn       输出数据位宽
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
out_width = data_width-1;
phase_depth = 32; 
input_width =20; 
iteration = out_width+1;

% define scaling
scale_vec = 2^out_width; 
scale_ang = 2^input_width;

% create arctan table
atan_table = zeros(1,iteration);
for i=1:1:iteration
  atan_table(i) = atan(1/2^(i-1));
end
atan_table = round(atan_table*scale_ang/(2*pi));

cos_out = zeros(1,num_of_sample);
sin_out = zeros(1,num_of_sample);

M = 2^phase_depth;
acc = 0;
l = zeros(1,num_of_sample);

for i = 1:num_of_sample
    if i == 1
        acc = phase_word;
    else 
        acc = acc + freq_word;
    end
    l(i) = mod(acc,M);
    l(i) = bitshift(l(i),-(phase_depth-input_width));
end

for i = 1:1:num_of_sample
    qudrant = bitshift(l(i),(2-input_width));
    switch qudrant 
        case 0 %0 ~ pi/2
            ex = 1;
            initial_x = K*(2^4);
            initial_y = 0;
            initial_z = l(i);
        case 1 %pi/2 ~ pi
            ex = -1;
            initial_x = -K*(2^4);
            initial_y = 0;
            initial_z = l(i)-(2^(input_width-1));
        case 2 %pi ~ 3pi/2
            ex = -1;
            initial_x = -K*(2^4);
            initial_y = 0;
            initial_z = l(i)-(2^(input_width-1));
        case 3 %3pi/2 ~ 2pi
            ex = 1;
            initial_x = K*(2^4);
            initial_y = 0;
            initial_z = l(i)-(2^(input_width));
        otherwise
            fprintf('err------------')
    end

    a_out =0;
    b_out = 0;
    z_out = 0;

    for k=0:1:iteration
        if (k==0)
            a_in = initial_x;  
            b_in = initial_y;
            z_in = initial_z;
        else
            [a_out,b_out,z_out] = cordic_cell(a_in,b_in,z_in,atan_table(k),k-1);
            a_in = a_out;
            b_in = b_out;
            z_in = z_out;
        end
    end

    a_out = floor(a_out/(2^4));
    b_out = floor(b_out/(2^4));
    
    %溢出处理
    if(a_out < - scale_vec)
        a_out = -scale_vec+1;
    end
    if(a_out >= scale_vec)
        a_out = scale_vec-1;
    end
    if(b_out < - scale_vec)
        b_out = -scale_vec+1;
    end
    if(b_out >= scale_vec)
        b_out = scale_vec-1;
    end
    
    cos_out(i) = a_out;
    sin_out(i) = b_out;

end

end