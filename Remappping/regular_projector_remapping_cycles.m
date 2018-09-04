clear
 
Screen('Preference', 'SkipSyncTests', 1);
 
%% Important Variables
 
experiment_time = 1.3; % In minutes


response_latency = 0.000; % Response latency of the subject. IN SECONDS. This is crucial for P2 presentation. 
                          % There is already a latency from number_of_cycles*(1/frequency) seconds = 4*1/30*1000 = 133.33 msec

% Projector
resolutionWidthPix  = 1280; % Resolution of the projector
resolutionHeightPix = 1024;
 
% Frequency Tagging
frequency        = 30;
number_of_cycles = 4;


%% Initiation values !!!!!
 
saccade_vector =  12; % Degrees
ProbeSize      =   1.2; % Size of the side of the small squares. IN DEGREES
numCheckers    =   8; % Number of checkers per side on the probe - NOT READY YET

if ProbeSize*numCheckers > saccade_vector
    error('The stimulus extends over the targets. Change ProbeSize')
end

y_axis_displacement     = 0;
fixation_size           = 4; % don't know exactly what this number stands for. But controls the size of the fixation dot
time_between_saccades   = 2; % seconds + rand(1) sec
fixation_y_displacement = 0;
 
probeColor      = [255 255 255] ; % Color of probes. White
FPColor         = [255   0   0] ; % Color of fixation point : Red
backgroundColor = [0 0 0] ; % Gray color on the background
 
photodiode_size = 1; % Size of photodiode projected on bottom-right in degrees
 
min_x_background = 0;
min_y_background = 0;
max_x_background = 400;
max_y_background = 320;
 
 
back_x = resolutionWidthPix;
back_y = resolutionHeightPix;
 
 
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
 
photodiode.x = resolutionWidthPix  - photodiode_size/2;
photodiode.y = resolutionHeightPix - photodiode_size/2;
 
%% Initiate Screen
 
[window, screenRect]=Screen('OpenWindow',1,backgroundColor);
ifi = Screen('GetFlipInterval', window);
 
FrameRate = 1/ifi;
 
 
%% First Control
if frequency>FrameRate/2
    disp(' ')
    disp(' ')
    warning('NYQUIST THEOREM VIOLATION')
    warning('Change the frequency of the probes')
    disp(' ')
%     STOP : HAMMERTIME
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
 
%% INITIALIZE THE LOW_LATENCY PARALLEL PORT DRIVER
% ioObj=io64;%create a parallel port handle
% status=io64(ioObj);%if this returns '0' the port driver is loaded & ready 
% address=hex2dec('D010');%'378' is the default address of LPT1 in hex
 
 
%% Increase priority on CPU for smooth execution
 
priorityLevel=MaxPriority(window);
Priority(priorityLevel);  % raise priority for stimulus presentation   
 
HideCursor
 
%% Get ready
 
multiplier = floor(ProbeSize/numCheckers);
miniboard = eye(2,'uint8') .* 255;
checkerboard_heads = repmat(miniboard, ceil(0.5 .* numCheckers))';
 
for i = 1:5
    checkerboard_heads = [checkerboard_heads; checkerboard_heads];
end
 
checkerboard_tails = 255 - checkerboard_heads;
checkerboard_heads = imresize(checkerboard_heads,ProbeSize,'box');
checkerboard_tails = imresize(checkerboard_tails,ProbeSize,'box');
 
%% Create the textures that will be projected
 
% TEST THE PHOTODIODE WITH DIFFERENT ORDER IN THE SEQUENCES
% To achieve different frequencies I should create all the different@
% sequences
 
background_texture    = Screen('MakeTexture',window, backgroundColor);
background_dimensions = CenterRectOnPoint([min_x_background min_y_background max_x_background max_y_background],back_x,back_y);
 
checkerboard_heads_texture = Screen('MakeTexture',window,checkerboard_heads);
checkerboard_tails_texture = Screen('MakeTexture',window,checkerboard_tails);
 
photodiode_heads_texture   = Screen('MakeTexture',window, [255 255 255]);
photodiode_tails_texture   = Screen('MakeTexture',window, [  0   0   0]);
photodiode_dimensions      = CenterRectOnPoint([0 0 photodiode_size photodiode_size], photodiode.x ,photodiode.y);
 
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
            for isubframe = 1:number_of_frames_needed/2
                Screen('Drawtextures',window,background_texture,[],background_dimensions); % Draw background
                Screen('gluDisk', window, FPColor, fixations.x(fix_select),fixations.y(fix_select), fixation_size); % Fixation point  
                Screen('Drawtextures',window, photodiode_heads_texture, [], photodiode_dimensions); % Photodiode
                Screen('DrawTexture', window, checkerboard_heads_texture, [], [Probes.x(iprobe)-size(checkerboard_heads,2)/2, 0 ,Probes.x(iprobe)+size(checkerboard_heads,2)/2, size(checkerboard_heads,1)],0, [], [], [], [], []); % Checkerboard
 
                lastFlipTime = Screen('Flip',window,lastFlipTime+ifi/2);  
                
                if send_fixation
%                     io64(ioObj,address,100 + fix_select);
                    fix_select
                    WaitSecs(0.001);
%                     io64(ioObj,address,0);
                    send_fixation = false;
                end
                if send_P2
%                     io64(ioObj,address,(fix_select-1)*10 + iprobe);
                    disp(['P2 '  num2str((fix_select-1)*10 + iprobe) ' - Target: ' num2str(fix_select)])
                    WaitSecs(0.001);
%                     io64(ioObj,address,0);
                    send_P2 = false;
                end

            end
            
            for isubframe = 1:number_of_frames_needed/2
                Screen('Drawtextures',window,background_texture,[],background_dimensions); % Draw background
                Screen('gluDisk', window, FPColor, fixations.x(fix_select),fixations.y(fix_select), fixation_size); % Fixation point  
                Screen('Drawtextures',window, photodiode_tails_texture, [], photodiode_dimensions); % Photodiode
                Screen('DrawTexture', window, checkerboard_tails_texture, [], [Probes.x(iprobe)-size(checkerboard_heads,2)/2, 0 ,Probes.x(iprobe)+size(checkerboard_heads,2)/2, size(checkerboard_heads,1)],0, [], [], [], [], []); % Checkerboard

                
                lastFlipTime = Screen('Flip',window,lastFlipTime+ifi/2);  
            end
        end
        probe_P2 = false;
        probe_P1 = true;
%         io64(ioObj,address,20 + (fix_select-1)*10 + iprobe);
        disp(['P2 '  num2str(20 + (fix_select-1)*10 + iprobe) ' - Target OFF: ' num2str(fix_select)])
        WaitSecs(0.001);
%         io64(ioObj,address,0);
    end
    
    %% P1 timing
    now = toc;
    if now - saccade_timer > 1 && probe_P1
        iprobe = randi(4);
        send_P1 = true;
        for icycle = 1:number_of_cycles
            for isubframe = 1:number_of_frames_needed/2
 
                Screen('Drawtextures',window,background_texture,[],background_dimensions); % Draw background
                Screen('gluDisk', window, FPColor, fixations.x(fix_select),fixations.y(fix_select), fixation_size); % Fixation point  
                Screen('Drawtextures',window, photodiode_heads_texture, [],photodiode_dimensions); % Photodiode
                Screen('DrawTexture', window, checkerboard_heads_texture, [], [Probes.x(iprobe)-size(checkerboard_heads,2)/2, 0 ,Probes.x(iprobe)+size(checkerboard_heads,2)/2, size(checkerboard_heads,1)],0, [], [], [], [], []); % Checkerboard

                lastFlipTime = Screen('Flip',window,lastFlipTime+ifi/2);  
   
                if send_P1
%                     io64(ioObj,address,40 + (fix_select-1)*10 + iprobe);
                    disp(['P1 '  num2str(40 + (fix_select-1)*10 + iprobe) ' - Target: ' num2str(fix_select)])
                    WaitSecs(0.001);
%                     io64(ioObj,address,0);
                    send_P1 = false;
                end
            end
            
            for isubframe = 1:number_of_frames_needed/2
                Screen('Drawtextures',window,background_texture,[],background_dimensions); % Draw background
                Screen('gluDisk', window, FPColor, fixations.x(fix_select),fixations.y(fix_select), fixation_size); % Fixation point  
                Screen('Drawtextures',window, photodiode_tails_texture, [],photodiode_dimensions); % Photodiode
                Screen('DrawTexture', window, checkerboard_tails_texture, [], [Probes.x(iprobe)-size(checkerboard_heads,2)/2, 0 ,Probes.x(iprobe)+size(checkerboard_heads,2)/2, size(checkerboard_heads,1)],0, [], [], [], [], []); % Checkerboard

                lastFlipTime = Screen('Flip',window,lastFlipTime+ifi/2);  
            end
            
        end
        probe_P1 = false;
%         io64(ioObj,address,60 + (fix_select-1)*10 + iprobe);
        disp(['P1 '  num2str(60 + (fix_select-1)*10 + iprobe) ' - Target OFF: ' num2str(fix_select)])
        WaitSecs(0.001);
%         io64(ioObj,address,0);
 
    end
    Screen('Drawtextures',window,background_texture,[],background_dimensions); % Draw background
    Screen('gluDisk', window, FPColor, fixations.x(fix_select),fixations.y(fix_select), fixation_size); % Fixation point  
    lastFlipTime = Screen('Flip',window,lastFlipTime+ifi/2);

    
end
 
%%
Screen('CloseAll')
Priority(0);%drop priority back to normal
ShowCursor

