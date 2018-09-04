clear

Screen('Preference', 'SkipSyncTests', 0);

%% Important Variables

experiment_time = 12; % In minutes


response_latency = 0.000; % Response latency of the subject. IN SECONDS. This is crucial for P2 presentation. 

% Projector
resolutionWidthPix  = 1280; % Resolution of the projector
resolutionHeightPix = 720;

% Frequency Tagging
frequency        = 30;
number_of_cycles = 4;


%% Initiation values !!!!!

saccade_vector          = 5; % Degrees
ProbeSize               = 0.8;%1.4; % Size of the side of the square probe. IN DEGREES
y_axis_displacement     = 13;
fixation_size           = 2; % don't know exactly what this number stands for. But controls the size of the fixation dot
time_between_saccades   = 2; % seconds + rand(1) sec
fixation_y_displacement = 10;

probeColor      = [255 255 255] ; % Color of probes. White
FPColor         = [0     0   0] ; % Color of fixation point : Red
backgroundColor = [127 127 127] ; % Gray color on the background

photodiode_size = 2; % Size of photodiode projected on bottom-right in pixels : 20x20



min_x_background = 0;
min_y_background = 0;
max_x_background = 400;
max_y_background = 320;


back_x = 640;
back_y = 550;


%% Transform everything to degrees
PixPerDeg = 20; % THIS NUMBER IS NOT ACCURATE FOR THE DEPTHQ PROJECTOR

ProbeSize               = ProbeSize * PixPerDeg; 
saccade_vector          = saccade_vector * PixPerDeg;
y_axis_displacement     = y_axis_displacement * PixPerDeg;
photodiode_size         = photodiode_size * PixPerDeg;
fixation_y_displacement = fixation_y_displacement* PixPerDeg;
%% Probes and fixation location centers (3 probes)

Probes.x = resolutionWidthPix/2 + saccade_vector*[-1 0 1 100];  
Probes.y = (resolutionHeightPix/2+y_axis_displacement) * [1 1 1 100];    

fixations.x = resolutionWidthPix/2 + saccade_vector*[-1/2 1/2];
fixations.y = (resolutionHeightPix/2 + fixation_y_displacement) * [1 1];    

photodiode.x = resolutionWidthPix/2 + 200 - photodiode_size/2;
photodiode.y = resolutionHeightPix/2+ 370 - photodiode_size/2;

%% Initiate Screen

[window, screenRect]=Screen('OpenWindow',2,backgroundColor);
ifi = Screen('GetFlipInterval', window);

FrameRate = 360;%1/ifi;%360;%1/ifi % 360 is for the DepthQ


%% First Control
if frequency>FrameRate/2
    disp(' ')
    disp(' ')
    disp('NYQUIST THEOREM VIOLATION')
    disp('Change the frequency of the probes')
    disp(' ')
    STOP : HAMMERTIME
end

%% Check the actual frequencies that can be achieved based on that
% refresh rate and inform the user

even_numbers = 2:2:FrameRate;  % In order to have a perfect sinusoid, we need an even number of frames in the sinusoid
achievable_frequencies = zeros(length(even_numbers),1);

for i = even_numbers
    achievable_frequencies(i) = FrameRate/(i);
end

[~, number_of_frames_needed] = min(abs(achievable_frequencies-frequency));
actual_frequency = achievable_frequencies(number_of_frames_needed);

disp(' ')
disp(' ')
disp('Achievable frequencies with this framerate:')
disp(num2str(achievable_frequencies(achievable_frequencies~=0)'))
disp(' ')
disp(' ')
disp(' ')
disp('        Actual frequencies that will be projected       ')
disp('--------------------------------------------------------')
a=sprintf('Probe');
aa=sprintf('%.3f Hz',frequency);
disp(a)
disp(aa); clear a aa

needed_on_off_for_sequence = FrameRate/2 ./ actual_frequency;


if FrameRate~=360
    warning('If using DepthQ, make sure you use 360Hz as refresh rate')
end


%% INITIALIZE THE LOW_LATENCY PARALLEL PORT DRIVER
ioObj=io64;%create a parallel port handle
status=io64(ioObj);%if this returns '0' the port driver is loaded & ready 
address=hex2dec('D010');%'378' is the default address of LPT1 in hex


%% Increase priority on CPU for smooth execution

priorityLevel=MaxPriority(window);
Priority(priorityLevel);  % raise priority for stimulus presentation   

HideCursor

%% Get ready
numCheckers = 6; % Number of checkers per side on the probe - NOT READY YET

multiplier = floor(ProbeSize/numCheckers);
miniboard = eye(2,'uint8') .* 255;
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

checker_texture_1 = Screen('MakeTexture',window,sequence_1);
checker_texture_2 = Screen('MakeTexture',window,sequence_2);
checker_texture_3 = Screen('MakeTexture',window,sequence_3);
checker_texture_4 = Screen('MakeTexture',window,sequence_4);
checker_texture_5 = Screen('MakeTexture',window,sequence_5);
checker_texture_6 = Screen('MakeTexture',window,sequence_6);
checker_texture_7 = Screen('MakeTexture',window,sequence_7);
checker_texture_8 = Screen('MakeTexture',window,sequence_8);

checker_textures = [checker_texture_1 checker_texture_2 checker_texture_3 checker_texture_4 checker_texture_5 checker_texture_6 checker_texture_7 checker_texture_8];


collection = [sequence_1(1,1,1) sequence_1(1,1,2) sequence_1(1,1,3);
              sequence_2(1,1,1) sequence_2(1,1,2) sequence_2(1,1,3);
              sequence_3(1,1,1) sequence_3(1,1,2) sequence_3(1,1,3);
              sequence_4(1,1,1) sequence_4(1,1,2) sequence_4(1,1,3);
              sequence_5(1,1,1) sequence_5(1,1,2) sequence_5(1,1,3);
              sequence_6(1,1,1) sequence_6(1,1,2) sequence_6(1,1,3);
              sequence_7(1,1,1) sequence_7(1,1,2) sequence_7(1,1,3);
              sequence_8(1,1,1) sequence_8(1,1,2) sequence_8(1,1,3) ]./255; % This gives a 8x3 matrix which shows the order (ON-OFF) of each sequence

          
% And for the photodiode that will indicate the different conditions 

photodiode = CenterRectOnPoint([0 0 photodiode_size photodiode_size],photodiode.x,photodiode.y);

background_texture = Screen('MakeTexture',window,backgroundColor);
background_dimensions = CenterRectOnPoint([min_x_background min_y_background max_x_background max_y_background],back_x,back_y);



%% The stimulation frequency is achieved with a combination of frames with specific subframes
% The number of ONs and OFFs define the frequency
k = needed_on_off_for_sequence; % The number k (5x1) gives the number of frames needed to be ON (k on) and then OFF (k off) to find the sequence that achieves the frequency

frames_sequence = cell(1,1);
probe_sequence = cell(1,1); 

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
probe_sequence{1} = sequence;
frames_sequence{1} = frames_needed; % This cell array collected the combinations of templates that achieve the wanted frequency for each probe

%% Project stimulus
% There are 3 probes that can appear to flicker and a 4th that is out
tic
experiment_start = toc;
now = toc;
saccade_timer = toc;
lastFlipTime = 0;
fix_select = 1;

send_fixation = false;

iprobe = 1;
probe_P1 = false;
probe_P2 = false;

isubframe = 1;
max_subframe_per_probe = length(frames_sequence{1});
while now-experiment_start < experiment_time * 60
    now = toc;
    if now-saccade_timer>time_between_saccades+rand(1)
        if fix_select ==1
            fix_select=2;
            send_fixation = true;
        elseif fix_select==2
            fix_select = 1;
            send_fixation = true;
        end
        saccade_timer = toc;
        probe_P2 = true;
    end
    
    Screen('Drawtextures',window,background_texture,[],background_dimensions); % Draw background
    Screen('gluDisk', window, FPColor, fixations.x(fix_select),fixations.y(fix_select), fixation_size); % Fixation point  
    
    
    %% P2 timing
    now = toc;
    if now - saccade_timer > response_latency && probe_P2
        iprobe = randi(4);
        send_P2 = true;
        for icycle = 1:number_of_cycles
            for isubframe = 1:max_subframe_per_probe
                Screen('Drawtextures',window,background_texture,[],background_dimensions); % Draw background
                Screen('gluDisk', window, FPColor, fixations.x(fix_select),fixations.y(fix_select), fixation_size); % Fixation point  
                Screen('Drawtextures',window,checker_textures(frames_sequence{1}(isubframe)),[],photodiode); % Photodiode
                Screen('DrawTexture', window, checker_textures(frames_sequence{1}(isubframe)), [], [Probes.x(iprobe)-ProbeSize, Probes.y(iprobe)-ProbeSize,Probes.x(iprobe)+ProbeSize, Probes.y(iprobe)+ProbeSize],0, [], [], [], [], []); % Checkerboard

                lastFlipTime = Screen('Flip',window,lastFlipTime+ifi/2);  

                if send_P2
                    io64(ioObj,address,(fix_select-1)*10 + iprobe);
                    disp(['P2 '  num2str((fix_select-1)*10 + iprobe) ' - Target: ' num2str(fix_select)])
                    WaitSecs(0.001);
                    io64(ioObj,address,0);
                    send_P2 = false;
                end
                if send_fixation
                    io64(ioObj,address,100 + fix_select);
                    fix_select
                    WaitSecs(0.001);
                    io64(ioObj,address,0);
                    send_fixation = false;
                end
            end
        end
        probe_P2 = false;
        probe_P1 = true;
        io64(ioObj,address,20 + (fix_select-1)*10 + iprobe);
        disp(['P2 '  num2str(20 + (fix_select-1)*10 + iprobe) ' - Target OFF: ' num2str(fix_select)])
        WaitSecs(0.001);
        io64(ioObj,address,0);
    end
    
    %% P1 timing
    now = toc;
    if now - saccade_timer > 1 && probe_P1
        iprobe = randi(4);
        send_P1 = true;
        for icycle = 1:number_of_cycles
            for isubframe = 1:max_subframe_per_probe

                Screen('Drawtextures',window,background_texture,[],background_dimensions); % Draw background
                Screen('gluDisk', window, FPColor, fixations.x(fix_select),fixations.y(fix_select), fixation_size); % Fixation point  
                Screen('Drawtextures',window,checker_textures(frames_sequence{1}(isubframe)),[],photodiode); % Photodiode
                Screen('DrawTexture', window, checker_textures(frames_sequence{1}(isubframe)), [], [Probes.x(iprobe)-ProbeSize, Probes.y(iprobe)-ProbeSize,Probes.x(iprobe)+ProbeSize, Probes.y(iprobe)+ProbeSize],0, [], [], [], [], []); % Checkerboard

                lastFlipTime = Screen('Flip',window,lastFlipTime+ifi/2);  
   
                if send_P1
                    io64(ioObj,address,40 + (fix_select-1)*10 + iprobe);
                    disp(['P1 '  num2str(40 + (fix_select-1)*10 + iprobe) ' - Target: ' num2str(fix_select)])
                    WaitSecs(0.001);
                    io64(ioObj,address,0);
                    send_P1 = false;
                end
            end
        end
        probe_P1 = false;
        io64(ioObj,address,60 + (fix_select-1)*10 + iprobe);
        disp(['P1 '  num2str(60 + (fix_select-1)*10 + iprobe) ' - Target OFF: ' num2str(fix_select)])
        WaitSecs(0.001);
        io64(ioObj,address,0);

    end
    Screen('Drawtextures',window,background_texture,[],background_dimensions); % Draw background
    Screen('gluDisk', window, FPColor, fixations.x(fix_select),fixations.y(fix_select), fixation_size); % Fixation point  
    lastFlipTime = Screen('Flip',window,lastFlipTime+ifi/2);
    if send_fixation
        io64(ioObj,address,100 + fix_select);
        fix_select
        WaitSecs(0.001);
        io64(ioObj,address,0);
        send_fixation = false;
    end


end

%%
Screen('CloseAll')
Priority(0);%drop priority back to normal
ShowCursor
