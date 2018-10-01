

%% Events

% Fixation 1 ON (LEFT) : 21
% Fixation 2 ON (RIGHT): 22

%% P1 Probes - Probes appear during fixation - Elicit retinotopic responses
% P1 ON - Fixation on FP1: 41
% P1 ON - Fixation on FP2: 42

%% P2 Probes - Probes appear right before saccade - Elicit remapped responses

% P2 ON - FP1 is ON - Left  Tilt:  1
% P2 ON - FP2 is ON - Left  Tilt:  2
% P2 ON - FP1 is ON - Right Tilt: 11
% P2 ON - FP2 is ON - Right Tilt: 12

%% Saccades in the dark. No P2 probe appeared
% These will be used as a baseline (10% of the P2 trials)

% NO PROBE - FP1 is on :91
% NO PROBE - FP1 is on :92


%% Button Events
% The subjects need to press a button after every P2 probe presentation

% Correct: P2 ON - FP1 is ON - Left  Tilt: 101
% Correct: P2 ON - FP2 is ON - Left  Tilt: 102
% Correct: P2 ON - FP1 is ON - Right Tilt: 111
% Correct: P2 ON - FP2 is ON - Right Tilt: 112

% False:   P2 ON - FP1 is ON - Left  Tilt: 201
% False:   P2 ON - FP2 is ON - Left  Tilt: 202
% False:   P2 ON - FP1 is ON - Right Tilt: 211
% False:   P2 ON - FP2 is ON - Right Tilt: 212




%% Important Variables


run = 1;

tic


time_of_experiment = 1; % Time in minutes

response_latency                       = 0.05; % Response latency of the subject. IN SECONDS. This is crucial for P2 presentation. 

stim.displayParams.resolutionWidthPix  = 1920; % Resolution of the projector
stim.displayParams.resolutionHeightPix = 1080;

stim.ProbeSize                         =    4; % Size of the side of the square probe. IN DEGREES
stim.distance_between_FPs              =   10; % SACCADE DISTANCE. IN DEGREES! All the distances of the fixation points and the probes will be affected by this

%% Initiation values !!!!!

stim.FP_size         = 0.3; % RADIUS OF FIXATION POINT. IN DEGREES

tilt_angle           = 5; % Angle of the tilt inside the probe. In degrees

stim.probeColor      = [255 255 255] ; % Color of probes. White
stim.FPColor         = [255   0   0] ; % Color of fixation point : Red
stim.backgroundColor = [ 10  10  10] ; % Black color on the background

photodiode_size      = 20                     ; % Size of photodiode projected on bottom-right in pixels : 20x20
photodiode_min       = stim.backgroundColor(1); % Minimum value for the photodiode 0=black, 255=white
photodiode_max       = stim.probeColor(1)     ;  % Maximum value for the photodiode 0=black, 255=white

probes_Y_distance    = 5                     ; % Distance of the probes from the moddle line in the Y- Axis. IN DEGREES

%% Transform whatever is in degrees to pixels

% How many pixels per degree for x and y axis
stim.displayParams.xPixPerDeg = 20; % This is calculated from the screen distance (actually it's 1 degree_x = 19.45pixels)
stim.displayParams.yPixPerDeg = 20; % 1 degree_y = 20.5 pixels


saccade_vector        = stim.distance_between_FPs*(stim.displayParams.xPixPerDeg+stim.displayParams.yPixPerDeg)/2; % Saccade distance. IN PIXELS
stim.ProbeSize        = stim.ProbeSize*(stim.displayParams.xPixPerDeg+stim.displayParams.yPixPerDeg)/2;
stim.fixPoint.sizePix = stim.FP_size*(stim.displayParams.xPixPerDeg+stim.displayParams.yPixPerDeg)/2;  % SIZE OF FIXATION POINT. In pixels
probes_Y_distance     = probes_Y_distance*(stim.displayParams.xPixPerDeg+stim.displayParams.yPixPerDeg)/2;

%% Fixation Points - This has only 2, on the same height

stim.fixPoint.x = [stim.displayParams.resolutionWidthPix/2-saccade_vector/2 ...
                   stim.displayParams.resolutionWidthPix/2+saccade_vector/2];

stim.fixPoint.y = [stim.displayParams.resolutionHeightPix/2 stim.displayParams.resolutionHeightPix/2];


%% Probes location centers

stim.Probes.x = stim.displayParams.resolutionWidthPix/2 + saccade_vector*[-1 0];
   
stim.Probes.y = (stim.displayParams.resolutionHeightPix/2 + probes_Y_distance) * [1];    
stim.Probes.y = [stim.Probes.y stim.displayParams.resolutionHeightPix/2 - 10*probes_Y_distance]; % Probe 7 will be out of the screen (empty trial)

%% Initiate Screen

[stim.displayParams.window, screenRect]=Screen('OpenWindow',2,[0 0 0 0]);

ifi = Screen('GetFlipInterval', stim.displayParams.window);

%% INITIALIZE THE LOW_LATENCY PARALLEL PORT DRIVER
% ioObj=io64;%create a parallel port handle
% status=io64(ioObj);%if this returns '0' the port driver is loaded & ready 
% address=hex2dec('D010');%'378' is the default address of LPT1 in hex


%% Increase priority on CPU for smooth execution

priorityLevel=MaxPriority(stim.displayParams.window);
Priority(priorityLevel);  % raise priority for stimulus presentation   

HideCursor


%% Get ready
lastFlipTime =0;

stim.probetexture       = Screen('MakeTexture',stim.displayParams.window,stim.probeColor);
stim.photodiode_texture = Screen('MakeTexture',stim.displayParams.window,stim.probeColor);

stim.rectprobe = zeros(length(stim.Probes.x),4); % 2 probes with 2x2 coordinates
for iprobe = 1:length(stim.Probes.x)
    stim.rectprobe(iprobe,:)  = CenterRectOnPoint([0 0 stim.ProbeSize stim.ProbeSize],stim.Probes.x(iprobe) ,stim.Probes.y(iprobe));
end

stim.photodiode = CenterRectOnPoint([0 0 photodiode_size photodiode_size],stim.displayParams.resolutionWidthPix-photodiode_size/2 ,stim.displayParams.resolutionHeightPix-photodiode_size/2);
stim.propixx_events = [0 0 1 1];


%% Create two matrices that will be the probes. Each of them will have some
% lines within them and the subject have to report if they're tilted right
% or left

big_matrix = ones(500,500)*255;

big_matrix(:,2:5:size(big_matrix,1)) = 0;
big_matrix(:,3:5:size(big_matrix,1)) = 0;

left_tilted_probe  = imrotate(big_matrix,tilt_angle,'crop','bilinear');
right_tilted_probe = imrotate(big_matrix,-tilt_angle,'crop','bilinear');


selection = 60;

left_tilted_probe  = left_tilted_probe (100:100+selection,100:100+selection);
right_tilted_probe = right_tilted_probe(100:100+selection,100:100+selection);

left_tilted_probe_texture  = Screen('MakeTexture', stim.displayParams.window, left_tilted_probe);
right_tilted_probe_texture = Screen('MakeTexture', stim.displayParams.window, right_tilted_probe);

probe_textures = [left_tilted_probe_texture right_tilted_probe_texture];


%% Magic happens here

trial = 1;
s = RandStream.setGlobalStream(RandStream('mt19937ar','seed',run));  % This sets specific stream for the creation of random numbers

%% Create a biased selection of probes
biased_selection = [1 1 1 1 1 1 1 1 1 2]; % selection of 1 90% and 2 10%

% DrawFormattedText(stim.displayParams.window, 'Ready ?',stim.displayParams.resolutionWidthPix/2,stim.displayParams.resolutionHeightPix/2,255*[1 0 0]);
% Screen(stim.displayParams.window, 'Flip');
% disp('Press a key to continue');
% KbWait;
% pause(.5)
% DrawFormattedText(stim.displayParams.window, 'Experiment Starting',stim.displayParams.resolutionWidthPix/2,stim.displayParams.resolutionHeightPix/2,255*[1 0 0]);
% Screen(stim.displayParams.window, 'Flip');
% disp('Press a key to continue');
% KbWait;
% pause(.5)


KbName('UnifyKeyNames');
% activeKeys = [KbName('LeftArrow') KbName('RightArrow')];
activeKeys = [55 56];
RestrictKeysForKbCheck(activeKeys);

Screen('FillRect', stim.displayParams.window, stim.backgroundColor);

succesful_trials = 0;
nButtonPresses = 0;
reactionTimes = [];
ButtonsPressedNames = [];
ButtonsPressedCodes = [];


a1 = [];
a2 = [];
start_time = clock; 
current_time = clock;
while etime(current_time, start_time) <60*time_of_experiment


    for fixation = 1:2
        
        
        % Present Fixation point
        Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
        lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime+rand(1)*1+0.8 -ifi/2);     %500-1500msec
        
%         io64(ioObj,address,20+fixation); % 21,22 indicate the fixation Onset
        WaitSecs(0.001);
%         io64(ioObj,address,0);
        
        iprobes = [1 biased_selection(randi(10,1,1))]; % One for P1 and the second for P2. P1 will always present the probe inside the screen (condition 1)
        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Present P2 and fixation point
        
        % Select which direction the probe will be tilted
        probe_direction = [1,2];
        probe_direction = probe_direction(randi(2,1,1)); % 1 left, 2 right
        
         
        
        Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
        Screen('Drawtextures',stim.displayParams.window,probe_textures(probe_direction),[],stim.rectprobe(iprobes(2),:)+[(fixation-1)*2*saccade_vector 0 (fixation-1)*2*saccade_vector 0]);
        Screen('Drawtextures',stim.displayParams.window,stim.photodiode_texture,[],stim.photodiode);
        Screen('Drawtextures',stim.displayParams.window,stim.photodiode_texture,[],stim.propixx_events);
        
        lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime+response_latency -ifi/2);  % Response latency of the subject - approximated  
        
        if iprobes(2) == 2
    %         io64(ioObj,address,90+fixation);
        elseif iprobes(2) == 1
%             io64(ioObj,address,(probe_direction-1)*10 + fixation);
        end
        WaitSecs(0.001);
%         io64(ioObj,address,0);
        tic
        % Remove P2 and triangle but keep fixation point
        Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
        lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime+0.05 -ifi/2);     
        a2 = [a2; toc];
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        
        % WAIT FOR BUTTON PRESS
        definedKeyPressed = false;
        tStart = GetSecs;
        while ~definedKeyPressed 
           
            [keyIsDown, keyTime, KeyCode ] = KbCheck; 
            WaitSecs(0.002);
%             definedKeyPressed = KeyCode(KbName('LeftArrow')) || KeyCode(KbName('RightArrow'));
            definedKeyPressed = KeyCode(55) || KeyCode(56);
            
            % After 5 seconds of waiting for Button Press, Timeout
            if keyTime - tStart > 5
                definedKeyPressed = 1;
            end
            
            reactionTimes       = [reactionTimes keyTime-tStart];
            ButtonsPressedNames = [ButtonsPressedNames KbName(KeyCode)];
            ButtonsPressedCodes = [ButtonsPressedCodes KeyCode];
                        
            
            % Left arrow pressed
%             if KeyCode(KbName('LeftArrow')) 
            if KeyCode(55) 
                nButtonPresses = nButtonPresses + 1;
                
                if probe_direction == 1 % Correct trial
%                     io64(ioObj,address,100+fixation);
%                     WaitSecs(0.001);
%                     io64(ioObj,address,0);
                    succesful_trials = succesful_trials + 1;
                    Screen('gluDisk', stim.displayParams.window, [0,255,0], stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
                    lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime -ifi/2);
                    Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
                    lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime+0.15 -ifi/2);  
                elseif probe_direction == 2 % Incorrect trial
%                     io64(ioObj,address,210+fixation);
%                     WaitSecs(0.001);
%                     io64(ioObj,address,0);
                    Screen('gluDisk', stim.displayParams.window, [127,127,127], stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
                    lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime -ifi/2);  
                    Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
                    lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime+0.15 -ifi/2);  
                end

            % Right arrow pressed
%             elseif KeyCode(KbName('RightArrow'))
            elseif KeyCode(56)
                nButtonPresses = nButtonPresses + 1;

                if probe_direction == 2 % Correct trial
%                     io64(ioObj,address,110+fixation);
%                     WaitSecs(0.001);
%                     io64(ioObj,address,0);
                    succesful_trials = succesful_trials + 1;
                    Screen('gluDisk', stim.displayParams.window, [0,255,0], stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
                    lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime -ifi/2);  
                    Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
                    lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime+0.15 -ifi/2);  
                elseif probe_direction == 1 % Incorrect trial
%                     io64(ioObj,address,200+fixation);
%                     WaitSecs(0.001);
%                     io64(ioObj,address,0);
                    Screen('gluDisk', stim.displayParams.window, [127,127,127], stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
                    lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime -ifi/2);  
                    Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
                    lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime+0.15 -ifi/2);  
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Present P1 and fixation point
        
        Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
        Screen('Drawtextures',stim.displayParams.window,stim.probetexture,[],stim.rectprobe(iprobes(1),:)+[(2-fixation)*(2)*saccade_vector 0 (2-fixation)*(2)*saccade_vector 0]);
        Screen('Drawtextures',stim.displayParams.window,stim.photodiode_texture,[],stim.photodiode);
        Screen('Drawtextures',stim.displayParams.window,stim.photodiode_texture,[],stim.propixx_events);

        lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime+rand(1)*1+0.5 -ifi/2);     %500-1500msec   
%         io64(ioObj,address, fixation+40);
        WaitSecs(0.001);
%         io64(ioObj,address,0);
        tic
        % Remove P1 but keep fixation point
        Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
        lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime+0.05 -ifi/2);    
        a1 = [a1; toc];
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%         Screen('Close', stim.probetexture);
%         Screen('Close', stim.photodiode_texture);
        

    end

    current_time = clock;
    
    
    
% % %     if ~mod(current_time - start-time,10)
% % %         disp(['Percentage Correct trials: ' num2str(succesful_trials/nButtonPresses*100) '%'])
% % %         disp(['Total Trials: ' num2str(nButtonPresses)]) 
% % %         disp(['Avg Reaction Time: ' num2str(round(mean(reactionTimes*10000))/10) ' ms'])
% % %         disp(' ')
% % %         disp(' ')
% % %         disp(' ')
% % %     end
    
    
end
  
if run == 6
    DrawFormattedText(stim.displayParams.window, 'You re free!!!',stim.displayParams.resolutionWidthPix/2,stim.displayParams.resolutionHeightPix/2,255*[1 0 0]);
else
    DrawFormattedText(stim.displayParams.window, 'Break!',stim.displayParams.resolutionWidthPix/2,stim.displayParams.resolutionHeightPix/2,255*[1 0 0]);
end

Screen(stim.displayParams.window, 'Flip');
disp('Press a key to continue');
KbWait;



Screen('CloseAll');
Priority(0);%drop priority back to normal
ShowCursor;
clear mex




disp(['Percentage Correct trials: ' num2str(succesful_trials/nButtonPresses*100) '%'])
disp(['Total Trials: ' num2str(nButtonPresses)]) 
disp(['Avg Reaction Time: ' num2str(round(mean(reactionTimes*10000))/10) ' ms'])
disp(' ')
disp(' ')
disp(' ')



toc



