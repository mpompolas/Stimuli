clear

Screen('Preference', 'SkipSyncTests', 1);

%% Important Variables

experiment_time = 0.4; % In minutes

run = 1;


f1               = [10 10 10 10 20 20 20 20 25 25 25 25 30 30 30 30];
number_of_cycles = [ 1  2  3  4  1  2  3  4  1  2  3  4  1  2  3  4]; % This is the number of cycles on the desired frequency that will be presented on each trial


% Frequency Tagging
f1 = f1(run);

number_of_cycles = number_of_cycles(run); 


time_interval_between_stims = 1.5; % Period with just fixation between stimulations. In seconds

% Projector
resolutionWidthPix  = 1280; % Resolution of the projector
resolutionHeightPix = 720;

% POSSIBLE FREQUENCIES TO TRY: 
% 180,
% 90,
% 60,
% 45,
% 36,
% 30,
% 25.714,
% 22.5,
% 20,
% 18,
% 16.36,
% 15,
% 13.15,
% 12.85,
% 12,
% 11.25,
% 10.588,
% 10,
% 9.4736,
% 9
% 8.5,
% 8.1
% 7.8
% 7.5

%% Initiation values !!!!!

ProbeSize                 = 10; % Size of the side of the square probe. IN DEGREES
y_axis_displacement       = 10;
fixation_size             = 2; % don't know exactly what this number stands for. But controls the size of the fixation dot
time_between_stimulations = 1; % seconds +-1 sec
fixation_y_displacement   = 10;

probeColor      = [255 255 255] ; % Color of probes. White
FPColor         = [0   0   0] ; % Color of fixation point : Red
backgroundColor = [0 0 0 0] ; % Gray color on the background

photodiode_size = 1; % Size of photodiode projected on bottom-right in pixels : 20x20

min_x_background = 0;
min_y_background = 0;
max_x_background = 400;
max_y_background = 320;

back_x = 640;
back_y = 550;

frequency = f1;

%% Transform everything to degrees
PixPerDeg = 20; % THIS NUMBER IS NOT ACCURATE FOR THE DEPTHQ PROJECTOR

ProbeSize               = ProbeSize * PixPerDeg; 
y_axis_displacement     = y_axis_displacement * PixPerDeg;
photodiode_size         = photodiode_size * PixPerDeg;
fixation_y_displacement = fixation_y_displacement* PixPerDeg;
%% Probes and fixation location centers (3 probes)

Probes.x = resolutionWidthPix/2;  
Probes.y = (resolutionHeightPix/2+y_axis_displacement);    

fixations.x = resolutionWidthPix/2;
fixations.y = resolutionHeightPix/2 + fixation_y_displacement;    

photodiode.x = resolutionWidthPix/2 + 200 - photodiode_size/2;
photodiode.y = resolutionHeightPix/2+ 370 - photodiode_size/2;

%% Initiate Screen

[window, screenRect]=Screen('OpenWindow',1,backgroundColor);
ifi = Screen('GetFlipInterval', window);
FrameRate = 360 %1/ifi; % 360 is for the DepthQ. For any other projector leave 1/ifi      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

%% First Control
if f1>FrameRate/2
    disp(' ')
    disp(' ')
    disp('NYQUIST THEOREM VIOLATION')
    disp('Change the frequency of the probe')
    disp(' ')
    STOP
    HAMMER(TIME)
end

%% Check the actual frequencies that can be achieved based on that
% refresh rate and inform the user

even_numbers = 2:2:FrameRate;  % In order to have a perfect sinusoid, we need an even number of frames in the sinusoid
achievable_frequencies = zeros(length(even_numbers),1);

for i = even_numbers
    achievable_frequencies(i) = FrameRate/(i);
end

actual_frequency = 0;
number_of_frames_needed = 0;
[~, number_of_frames_needed] = min(abs(achievable_frequencies-frequency));
actual_frequency = achievable_frequencies(number_of_frames_needed);

f1 = actual_frequency;

disp(' ')
disp(' ')
disp('Achievable frequencies with this framerate:')
disp(num2str(achievable_frequencies(achievable_frequencies~=0)'))
disp(' ')
disp(' ')
disp(' ')
disp('        Actual frequencies that will be projected       ')
disp('--------------------------------------------------------')
a=sprintf('Probe 1');
aa=sprintf('%.3f Hz',f1);
disp(a)
disp(aa); clear a aa


needed_on_off_for_sequence = FrameRate/2 ./ actual_frequency;

%% INITIALIZE THE LOW_LATENCY PARALLEL PORT DRIVER
% ioObj=io64;%create a parallel port handle
% status=io64(ioObj);%if this returns '0' the port driver is loaded & ready 
% address=hex2dec('D010');%'378' is the default address of LPT1 in hex


%% Increase priority on CPU for smooth execution

priorityLevel=MaxPriority(window);
Priority(priorityLevel);  % raise priority for stimulus presentation   

HideCursor

%% Get ready
numCheckers = 6*7; % Number of checkers per side on the probe - NOT READY YET

multiplier = floor(ProbeSize/numCheckers);
miniboard  = eye(2,'uint8') .* 255;
checkerboard_heads = repmat(miniboard, ceil(0.5 .* numCheckers))';
checkerboard_tails = 255 - checkerboard_heads;
checkerboard_heads = imresize(checkerboard_heads,round(sqrt(numCheckers*multiplier)),'box');
checkerboard_tails = imresize(checkerboard_tails,round(sqrt(numCheckers*multiplier)),'box');

%% Create the textures that will be projected

% TEST THE PHOTODIODE WITH DIFFERENT ORDER IN THE SEQUENCES
% To achieve different frequencies I should create all the different
% sequences

% DepthQ Projects with the order: B R G
% I use a sequence of ON-OFF-ON, followed by one: OFF-ON-OFF, and then
% repeat. This will project on 360 Hz >>---> 180 Hz effective flickering
sequence_1(:,:,1) = checkerboard_heads; % R
sequence_1(:,:,2) = checkerboard_heads; % G
sequence_1(:,:,3) = checkerboard_heads; % B

sequence_2(:,:,1) = checkerboard_heads; % R
sequence_2(:,:,2) = checkerboard_heads; % G
sequence_2(:,:,3) = checkerboard_tails; % B

sequence_3(:,:,1) = checkerboard_heads; % R
sequence_3(:,:,2) = checkerboard_tails; % G
sequence_3(:,:,3) = checkerboard_tails; % B

sequence_4(:,:,1) = checkerboard_heads; % R
sequence_4(:,:,2) = checkerboard_tails; % G
sequence_4(:,:,3) = checkerboard_heads; % B

sequence_5(:,:,1) = checkerboard_tails; % R
sequence_5(:,:,2) = checkerboard_tails; % G
sequence_5(:,:,3) = checkerboard_tails; % B

sequence_6(:,:,1) = checkerboard_tails; % R
sequence_6(:,:,2) = checkerboard_tails; % G
sequence_6(:,:,3) = checkerboard_heads; % B

sequence_7(:,:,1) = checkerboard_tails; % R
sequence_7(:,:,2) = checkerboard_heads; % G
sequence_7(:,:,3) = checkerboard_heads; % B

sequence_8(:,:,1) = checkerboard_tails; % R
sequence_8(:,:,2) = checkerboard_heads; % G
sequence_8(:,:,3) = checkerboard_tails; % B

collection = [sequence_1(1,1,1) sequence_1(1,1,2) sequence_1(1,1,3);
              sequence_2(1,1,1) sequence_2(1,1,2) sequence_2(1,1,3);
              sequence_3(1,1,1) sequence_3(1,1,2) sequence_3(1,1,3);
              sequence_4(1,1,1) sequence_4(1,1,2) sequence_4(1,1,3);
              sequence_5(1,1,1) sequence_5(1,1,2) sequence_5(1,1,3);
              sequence_6(1,1,1) sequence_6(1,1,2) sequence_6(1,1,3);
              sequence_7(1,1,1) sequence_7(1,1,2) sequence_7(1,1,3);
              sequence_8(1,1,1) sequence_8(1,1,2) sequence_8(1,1,3) ]./255; % This gives a 8x3 matrix which shows the order (ON-OFF) of each sequence

background_texture    = Screen('MakeTexture',window,[0,0,0]);
background_dimensions = CenterRectOnPoint([min_x_background min_y_background max_x_background max_y_background],back_x,back_y);


checker_texture_1 = Screen('MakeTexture',window,sequence_1);
checker_texture_2 = Screen('MakeTexture',window,sequence_2);
checker_texture_3 = Screen('MakeTexture',window,sequence_3);
checker_texture_4 = Screen('MakeTexture',window,sequence_4);
checker_texture_5 = Screen('MakeTexture',window,sequence_5);
checker_texture_6 = Screen('MakeTexture',window,sequence_6);
checker_texture_7 = Screen('MakeTexture',window,sequence_7);
checker_texture_8 = Screen('MakeTexture',window,sequence_8);

checker_textures = [checker_texture_1 checker_texture_2 checker_texture_3 checker_texture_4 checker_texture_5 checker_texture_6 checker_texture_7 checker_texture_8];



%% The stimulation frequency is achieved with a combination of frames with specific subframes
% The number of ONs and OFFs define the frequency
k = needed_on_off_for_sequence; % The number k gives the number of frames needed to be ON (k on) and then OFF (k off) to find the sequence that achieves the frequency

frames_sequence = cell(1,1);
probes_sequences = cell(1,1); 

template = [ones(1,k) zeros(1,k)];
template_temp = [];
while mod(length(template_temp),3)~=0 || isempty(template_temp)
    template_temp = [template template_temp];
end
template = template_temp; clear template_temp

% Check which frames are needed to achieve that frequency
sequence = [];
frames_needed = [];
while length(sequence) ~= length(template)
    for iframe = 1:8 % 8 Different possible subframe sequences (2 bits ^ 3 subframes)
        temp_sequence = sequence;
        temp_sequence = [temp_sequence [collection(iframe,3) collection(iframe,1) collection(iframe,2)]];

        if sum(template(1:length(temp_sequence))==temp_sequence)~=length(temp_sequence)
            continue
        else
            sequence = temp_sequence;
            frames_needed = [frames_needed iframe];
            break
        end
    end
end
probes_sequences{1} = sequence;
frames_sequence{1} = frames_needed; % This cell array collected the combinations of templates that achieve the wanted frequency for each probe



temp = [];
for icycle = 1:number_of_cycles
    temp = [temp frames_sequence{1}];
end
frames_sequence{1} = temp; clear temp



%% Project stimulus

tic
experiment_start = toc;
now = toc;
just_fixation_timer = toc;
lastFlipTime = 0;

send_event = false;
present_stimulus = false;
subframes_per_probe = 1;
max_subframe_per_probe = length(frames_sequence{1});
while now-experiment_start < experiment_time * 60
    Screen('Drawtextures',window,background_texture,[],background_dimensions);
    now = toc;
    if now - just_fixation_timer> time_interval_between_stims + rand(1)
        send_event          = true;
        present_stimulus    = true;
        just_fixation_timer = inf;
    end
    
    
    if present_stimulus
        Screen('DrawTexture', window, checker_textures(frames_sequence{1}(subframes_per_probe)), [], [Probes.x-ProbeSize, Probes.y-ProbeSize,Probes.x+ProbeSize, Probes.y+ProbeSize],0, [], [], [], [], []);
        subframes_per_probe = subframes_per_probe + 1;
        if subframes_per_probe>max_subframe_per_probe
            subframes_per_probe = 1;
            present_stimulus    = false;
            just_fixation_timer = toc;
        end
    end
    
    Screen('gluDisk', window, [255 0 0], fixations.x,fixations.y, fixation_size); 
    lastFlipTime = Screen('Flip',window,lastFlipTime+ifi/2);     
    
    if send_event
%         io64(ioObj,address,number_of_cycles + f1); % The event will be number of cycles used + the frequency of stimulation
        WaitSecs(0.001);
%         io64(ioObj,address,0);
        send_event = false;
    end
end

%%
Screen('CloseAll')
Priority(0);%drop priority back to normal
ShowCursor
