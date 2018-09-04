
% This gives the T/2 in subframes l=4 >>---->  ON ON ON ON OFF OFF OFF OFF = 180/4 = 45 Hz
l = 10;



%% 8 different combinations =  2^3 subframes 
a1 = [1 1 1];
a2 = [1 1 0];
a3 = [1 0 0];
a4 = [1 0 1];
a5 = [0 0 0];
a6 = [0 0 1];
a7 = [0 1 1];
a8 = [0 1 0];
a = [a1;a2;a3;a4;a5;a6;a7;a8];


%% The frequency is achieved with a combination of frames
template = [ones(1,l) zeros(1,l)];
template_temp = [];
while mod(length(template_temp),3)~=0 || isempty(template_temp)
    template_temp = [template template_temp];
end
template = template_temp; clear template_temp

%% Check which frames are needed to achieve that frequency
sequence = [];
frames_needed = [];
while length(sequence) ~= length(template)
    for iframe = 1:8
        temp_sequence = sequence;
        temp_sequence = [temp_sequence [a(iframe,3) a(iframe,1) a(iframe,2)]];
        
        if sum(template(1:length(temp_sequence))==temp_sequence)~=length(temp_sequence)
            continue
        else
            sequence = temp_sequence;
            frames_needed = [frames_needed iframe];
            break
        end
    end
end











