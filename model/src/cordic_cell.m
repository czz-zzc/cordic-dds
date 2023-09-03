function [a_out,b_out,z_out] = cordic_cell(a_in,b_in,z_in,theta,n)
        if (z_in < 0)
            a_out = a_in + floor(b_in/2^n);
            b_out = b_in - floor(a_in/2^n);
            z_out = z_in + theta;
        else
            a_out = a_in - floor(b_in/2^n);
            b_out = b_in + floor(a_in/2^n);
            z_out = z_in - theta;
        end
end