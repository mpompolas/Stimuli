clear

Screen('Preference', 'SkipSyncTests', 0);

%% Important Variables

experiment_time = 1; % In minutes

% Projector
resolutionWidthPix  = 1280; % Resolution of the projector
resolutionHeightPix = 1024;

% Probes % THIS NUMBER IS RANDOM
probes_to_present = 1:5 % Select which probes of the 5 to present


% Frequency Tagging
f1 = 45;
f2 = 36;
f3 = 90;
f4 = 25;
f5 = 180;

frequencies = [f1;f2;f3;f4;f5];

%% Initiation values !!!!!

saccade_vector    = 2; % Degrees
ProbeSize         = 0.5; % Size of the side of the square probe. IN DEGREES
y_axis_displacement = 1;
fixation_size     = 2; % don't know exactly what this number stands for. But controls the size of the fixation dot

probeColor      = [255 255 255] ; % Color of probes. White
FPColor         = [255   0   0] ; % Color of fixation point : Red
backgroundColor = [127 127 127 127] ; % Gray color on the background

photodiode_size = 1; % Size of photodiode projected on bottom-right in pixels : 20x20


%% Transform everything to degrees
PixPerDeg = 20; % THIS NUMBER IS NOT ACCURATE FOR THE DEPTHQ PROJECTOR

ProbeSize           = ProbeSize * PixPerDeg; 
saccade_vector      = saccade_vector * PixPerDeg;
y_axis_displacement = y_axis_displacement * PixPerDeg;
photodiode_size     = photodiode_size * PixPerDeg;

%% Probes and fixation location centers (3 probes)

Probes.x = resolutionWidthPix/2 + saccade_vector*[-2 -1 0 1 2];  
Probes.y = (resolutionHeightPix/2+y_axis_displacement) * [1 1 1 1 1];    

fixations.x = resolutionWidthPix/2 + saccade_vector*[-1/2 1/2];
fixations.y = resolutionHeightPix/2 * [1 1];    

photodiode.x = resolutionWidthPix - photodiode_size/2;
photodiode.y = resolutionHeightPix - photodiode_size/2;

%% Initiate Screen

[window, screenRect]=Screen('OpenWindow',1,backgroundColor);
ifi = Screen('GetFlipInterval', window);
FrameRate = 360;%1/ifi; % This is for the DepthQ

%% First Control
if f1>FrameRate/2 || f2>FrameRate/2 || f3>FrameRate/2 || f4>FrameRate/2 || f5>FrameRate/2
    disp(' ')
    disp(' ')
    disp('NYQUIST THEOREM VIOLATION')
    disp('Change the frequency of the probes')
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

actual_frequencies = zeros(5,1);
number_of_frames_needed = zeros(5,1);
for iprobe = 1:5
    [~, number_of_frames_needed(iprobe)] = min(abs(achievable_frequencies-frequencies(iprobe)));
    actual_frequencies(iprobe) = achievable_frequencies(number_of_frames_needed(iprobe));
end

f1 = actual_frequencies(1);
f2 = actual_frequencies(2);
f3 = actual_frequencies(3);
f4 = actual_frequencies(4);
f5 = actual_frequencies(5);

disp(' ')
disp(' ')
disp('Achievable frequencies with this framerate:')
disp(num2str(achievable_frequencies(achievable_frequencies~=0)'))
disp(' ')
disp(' ')
disp(' ')
disp('        Actual frequencies that will be projected       ')
disp('--------------------------------------------------------')
a=sprintf('Probe 1\t\tProbe 2\t\tProbe 3\t\tProbe 4\t\tProbe 5');
aa=sprintf('%.3f Hz\t%.3f Hz\t%.3f Hz\t%.3f Hz\t%.3f Hz',f1,f2,f3,f4,f5);
disp(a)
disp(aa); clear a aa


needed_on_off_for_sequence = FrameRate/2 ./ actual_frequencies;

%% INITIALIZE THE LOW_LATENCY PARALLEL PORT DRIVER
% ioObj=io64;%create a parallel port handle
% status=io64(ioObj);%if this returns '0' the port driver is loaded & ready 
% address=hex2dec('D010');%'378' is the default address of LPT1 in hex


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
sequence_1(:,:,1) = checkerboard_heads(1,1); % R
sequence_1(:,:,2) = checkerboard_heads(1,1); % G
sequence_1(:,:,3) = checkerboard_heads(1,1); % B

sequence_2(:,:,1) = checkerboard_heads(1,1); % R
sequence_2(:,:,2) = checkerboard_heads(1,1); % G
sequence_2(:,:,3) = checkerboard_tails(1,1); % B

sequence_3(:,:,1) = checkerboard_heads(1,1); % R
sequence_3(:,:,2) = checkerboard_tails(1,1); % G
sequence_3(:,:,3) = checkerboard_tails(1,1); % B

sequence_4(:,:,1) = checkerboard_heads(1,1); % R
sequence_4(:,:,2) = checkerboard_tails(1,1); % G
sequence_4(:,:,3) = checkerboard_heads(1,1); % B

sequence_5(:,:,1) = checkerboard_tails(1,1); % R
sequence_5(:,:,2) = checkerboard_tails(1,1); % G
sequence_5(:,:,3) = checkerboard_tails(1,1); % B

sequence_6(:,:,1) = checkerboard_tails(1,1); % R
sequence_6(:,:,2) = checkerboard_tails(1,1); % G
sequence_6(:,:,3) = checkerboard_heads(1,1); % B

sequence_7(:,:,1) = checkerboard_tails(1,1); % R
sequence_7(:,:,2) = checkerboard_heads(1,1); % G
sequence_7(:,:,3) = checkerboard_heads(1,1); % B

sequence_8(:,:,1) = checkerboard_tails(1,1); % R
sequence_8(:,:,2) = checkerboard_heads(1,1); % G
sequence_8(:,:,3) = checkerboard_tails(1,1); % B

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

photodiode_texture1 = Screen('MakeTexture',window,round(probeColor/1));
photodiode_texture2 = Screen('MakeTexture',window,round(probeColor/10));

photodiode_textures = [photodiode_texture1 photodiode_texture2];
photodiode = CenterRectOnPoint([0 0 photodiode_size photodiode_size],photodiode.x,photodiode.y);


%% The stimulation frequency is achieved with a combination of frames with specific subframes
% The number of ONs and OFFs define the frequency
k = needed_on_off_for_sequence; % The number k (5x1) gives the number of frames needed to be ON (k on) and then OFF (k off) to find the sequence that achieves the frequency

frames_sequence = cell(5,1);
probes_sequences = cell(5,1); 

for iprobe = 1:5
    template = [ones(1,k(iprobe)) zeros(1,k(iprobe))];
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
    probes_sequences{iprobe} = sequence;
    frames_sequence{iprobe} = frames_needed; % This cell array collected the combinations of templates that achieve the wanted frequency for each probe

end

%% Project stimulus
% There are 3 probes that flicker in different frequencies
% I will use 3 different timers that have to be reset when they expire
tic
experiment_start = toc;
now = toc;
saccade_timer = toc;
lastFlipTime = 0;
fix_select = 1;

subframes_per_probe = ones(5,1);
max_subframe_per_probe = [length(frames_sequence{1});length(frames_sequence{2});length(frames_sequence{3});length(frames_sequence{4});length(frames_sequence{5})];
while now-experiment_start < experiment_time * 60
    now = toc;
    if now-saccade_timer>1+rand(1)*2
        if fix_select ==1
            fix_select=2;
        elseif fix_select==2
            fix_select = 1;
        end
        saccade_timer = toc;
    end
    for iprobe=probes_to_present
        
        Screen('DrawTexture', window, checker_textures(frames_sequence{iprobe}(subframes_per_probe(iprobe))), [], [Probes.x(iprobe)-ProbeSize, Probes.y(iprobe)-ProbeSize,Probes.x(iprobe)+ProbeSize, Probes.y(iprobe)+ProbeSize],0, [], [], [], [], []);
        subframes_per_probe(iprobe) = subframes_per_probe(iprobe) + 1;
        if subframes_per_probe(iprobe)>max_subframe_per_probe(iprobe)
            subframes_per_probe(iprobe)=1;
        end
    end 
    
    Screen('gluDisk', window, [255 0 0], fixations.x(fix_select),fixations.y(fix_select), fixation_size); 
    Screen('Drawtextures',window,photodiode_textures(fix_select),[],photodiode);
    lastFlipTime = Screen('Flip',window,lastFlipTime+ifi/2);     
end

%%
Screen('CloseAll')
Priority(0);%drop priority back to normal
ShowCursor
