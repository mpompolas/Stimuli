% Screen('Preference', 'SkipSyncTests', 1);

%% Important Variables

experiment_time = 0.1; % In minutes

% Projector
resolutionWidthPix  = 1280; % Resolution of the projector
resolutionHeightPix = 720;

% Probes
ProbeSize             =  6; % Size of the side of the square probe. IN DEGREES
distance_between_FPs  = 10; % SACCADE DISTANCE. IN DEGREES! All the distances of the fixation points and the probes will be affected by this

% Frequency Tagging
f1 = 6;
f2 = 10;
f3 = 30; 
f4 = 60;
f5 = 7.5;

frequencies = [f1;f2;f3;f4;f5];


%% Initiation values !!!!!

probeColor      = [255 255 255] ; % Color of probes. White
FPColor         = [255   0   0] ; % Color of fixation point : Red
backgroundColor = [127 127 127] ; % Gray color on the background

photodiode_size      = 20                     ; % Size of photodiode projected on bottom-right in pixels : 20x20
photodiode_min       = backgroundColor(1); % Minimum value for the photodiode 0=black, 255=white
photodiode_max       = probeColor(1)     ; % Maximum value for the photodiode 0=black, 255=white

probes_Y_distance    = 0     ; % Distance of the probes from the moddle line in the Y- Axis. IN DEGREES

%% Transform whatever is in degrees to pixels

% How many pixels per degree for x and y axis
PixPerDeg = 20; % This is calculated from the screen distance (actually it's 1 degree_x = 19.45 pixels and degree_y = 20.5 pixels)

saccade_vector    = distance_between_FPs*PixPerDeg; % Saccade distance. IN PIXELS
ProbeSize         = ProbeSize*PixPerDeg;
probes_Y_distance = probes_Y_distance*PixPerDeg;

%% Probes location centers (5 probes)

Probes.x = resolutionWidthPix/2 + saccade_vector*[-2 -1 0 1 2];  
Probes.y = (resolutionHeightPix/2 + probes_Y_distance) * [1 1 1 1 1];    

%% Initiate Screen

[window, screenRect]=Screen('OpenWindow',2,[127 127 127 127]);
ifi = Screen('GetFlipInterval', window);
FrameRate = 1/ifi;


%% INITIALIZE THE LOW_LATENCY PARALLEL PORT DRIVER
% ioObj=io64;%create a parallel port handle
% status=io64(ioObj);%if this returns '0' the port driver is loaded & ready 
% address=hex2dec('D010');%'378' is the default address of LPT1 in hex


%% Increase priority on CPU for smooth execution

priorityLevel=MaxPriority(window);
Priority(priorityLevel);  % raise priority for stimulus presentation   


HideCursor

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

%% Create the checkers
numCheckers = 12; % Number of checkers per side on the probe - NOT READY YET

multiplier = floor(ProbeSize/numCheckers);
multiplier = floor(120/12);
miniboard = eye(2) .* 255;
checkerboard_heads = repmat(miniboard, ceil(0.5 .* numCheckers))';
checkerboard_heads = imresize(checkerboard_heads,round(sqrt(numCheckers*multiplier)),'box');
checkerboard_tails = 255-checkerboard_heads;

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




%% Create the different textures for each probe

textures = cell(5,1);

for iprobe = 1:5
    new_square = checkerboard_heads;
    intensity_difference = floor(256/(number_of_frames_needed(iprobe)/2));

    for ilevels = 0:number_of_frames_needed(iprobe)/2
        new_square = checkerboard_heads - (ilevels/(number_of_frames_needed(iprobe)/2)).*(checkerboard_heads - checkerboard_tails);
%         probe_texture = Screen('MakeTexture',window,new_square(1:ProbeSize,1:ProbeSize));
        probe_texture = Screen('MakeTexture',window,new_square);
        textures{iprobe} = [textures{iprobe};probe_texture]; % The different textures will be: number_of_frames_needed(iprobe)/2  +  1
        
%         figure;imagesc(new_square);colorbar
%         pixels{iprobe,ilevels+1} = new_square;
        
    end
end

% And for the photodiode that will indicate the different conditions

photodiode_texture1      = Screen('MakeTexture',window,round(probeColor/1));
photodiode_texture2      = Screen('MakeTexture',window,round(probeColor/2));
photodiode_texture3      = Screen('MakeTexture',window,round(probeColor/3));
photodiode_texture4      = Screen('MakeTexture',window,round(probeColor/4));
photodiode_texture5      = Screen('MakeTexture',window,round(probeColor/5));
photodiode_texture6      = Screen('MakeTexture',window,round(probeColor/6));


photodiode = CenterRectOnPoint([0 0 photodiode_size photodiode_size],resolutionWidthPix -photodiode_size/2,...
                                                                     resolutionHeightPix-photodiode_size/2);

Screen(window, 'Flip');
disp('Press a key to continue');
KbWait;
pause(.5)

%% Prepare stimulus
% There are 5 probes that flicker in different frequencies
% The different textures based on the intensity have already been computed
% previously

tic
experiment_start = toc;
saccade_timer = toc;

selected_probe = 2;
next_rounds_lag  = rand(1);
display_right_arrow = true;
display_left_arrow = false;
display_double_right_arrow =false;
display_double_left_arrow =false;

now = toc;
on = false;
off = true;

intensity_probes = ones(5,1);
iframe = 0;
lastFlipTime = 0;
transition = ones(5,1);
while iframe<experiment_time*60*FrameRate
    now = toc;
    iframe = iframe + 1;
    
    % Create the 5 probes
    for iprobe = 1:5
        Screen('DrawTexture', window, textures{iprobe}(intensity_probes(iprobe)), [], [Probes.x(iprobe)-ProbeSize/2, Probes.y(iprobe)-ProbeSize/2,...
                                                                                Probes.x(iprobe)+ProbeSize/2, Probes.y(iprobe)+ProbeSize/2],...
                                                                                   0, [], [], [], [], []);
         
        % Go up and down on a staircase with the number of each of the different textures
        if intensity_probes(iprobe)==1
            transition(iprobe) = 1;        
        elseif intensity_probes(iprobe)==number_of_frames_needed(iprobe)/2+1
            transition(iprobe) = -1;
        end
        intensity_probes(iprobe) = intensity_probes(iprobe) + transition(iprobe);
    end
    
    
    
    % Create sequentially a que for the saccade
    
    if now-saccade_timer>0.5+next_rounds_lag && now-saccade_timer<2
        on = true;
%         Screen('FrameRect', window, [255 0 0], [Probes.x(selected_probe)-ProbeSize/2, Probes.y(selected_probe)-ProbeSize/2,...
%                                                                         Probes.x(selected_probe)+ProbeSize/2, Probes.y(selected_probe)+ProbeSize/2],5)
    
        if display_right_arrow
            %Right Arrow
            Screen('DrawLines',window,[Probes.x(selected_probe)-floor(ProbeSize*0.3) Probes.x(selected_probe)+floor(ProbeSize*0.3);...
                                       Probes.y(selected_probe) Probes.y(selected_probe)],4, [0 255 0]);
            Screen('DrawLines',window,[Probes.x(selected_probe)+floor(ProbeSize*0.3) Probes.x(selected_probe)+floor(ProbeSize*0.1);...
                                       Probes.y(selected_probe) Probes.y(selected_probe)+floor(ProbeSize*0.08)],4, [0 255 0]) ;                    
            Screen('DrawLines',window,[Probes.x(selected_probe)+floor(ProbeSize*0.3) Probes.x(selected_probe)+floor(ProbeSize*0.1);...
                                       Probes.y(selected_probe) Probes.y(selected_probe)-floor(ProbeSize*0.08)],4, [0 255 0]) ; 
              
            if selected_probe == 2
                Screen('Drawtextures',window,photodiode_texture1,[],photodiode);
                if off
                    1
                    %io64(ioObj,address,1);
                    WaitSecs(0.001);
                    %io64(ioObj,address,0);
                end
            elseif selected_probe == 3
                Screen('Drawtextures',window,photodiode_texture2,[],photodiode);
                if off
                    2
                    %io64(ioObj,address,2);
                    WaitSecs(0.001);
                    %io64(ioObj,address,0);
                end
            end

        elseif display_left_arrow
            %Left Arrow
            Screen('DrawLines',window,[Probes.x(selected_probe)-floor(ProbeSize*0.3) Probes.x(selected_probe)+floor(ProbeSize*0.3);...
                                       Probes.y(selected_probe) Probes.y(selected_probe)],4, [0 255 0]);
            Screen('DrawLines',window,[Probes.x(selected_probe)-floor(ProbeSize*0.3) Probes.x(selected_probe)-floor(ProbeSize*0.1);...
                                       Probes.y(selected_probe) Probes.y(selected_probe)+floor(ProbeSize*0.08)],4, [0 255 0])  ;                   
            Screen('DrawLines',window,[Probes.x(selected_probe)-floor(ProbeSize*0.3) Probes.x(selected_probe)-floor(ProbeSize*0.1);...
                                       Probes.y(selected_probe) Probes.y(selected_probe)-floor(ProbeSize*0.08)],4, [0 255 0]) ;                      
            if selected_probe == 4
                Screen('Drawtextures',window,photodiode_texture3,[],photodiode);
                if off
                    3
                    %io64(ioObj,address,3);
                    WaitSecs(0.001);
                    %io64(ioObj,address,0);
                end
            elseif selected_probe == 3
                Screen('Drawtextures',window,photodiode_texture4,[],photodiode);
                if off
                    4
                    %io64(ioObj,address,4);
                    WaitSecs(0.001);
                    %io64(ioObj,address,0);
                end
            end
           
        elseif display_double_right_arrow
            %Right Arrow - Big jump 2 probes 
            if selected_probe == 2
                Screen('DrawLines',window,[Probes.x(selected_probe)-floor(ProbeSize*0.3) Probes.x(selected_probe)+floor(ProbeSize*0.3);...
                                           Probes.y(selected_probe) Probes.y(selected_probe)],4, [50 200 255]);
                Screen('DrawLines',window,[Probes.x(selected_probe)+floor(ProbeSize*0.3) Probes.x(selected_probe)+floor(ProbeSize*0.1);...
                                           Probes.y(selected_probe) Probes.y(selected_probe)+floor(ProbeSize*0.08)],4, [50 200 255]) ;                    
                Screen('DrawLines',window,[Probes.x(selected_probe)+floor(ProbeSize*0.3) Probes.x(selected_probe)+floor(ProbeSize*0.1);...
                                           Probes.y(selected_probe) Probes.y(selected_probe)-floor(ProbeSize*0.08)],4, [50 200 255]) ; 
                Screen('Drawtextures',window,photodiode_texture5,[],photodiode);
                if off
                    5
                    %io64(ioObj,address,5);
                    WaitSecs(0.001);
                    %io64(ioObj,address,0);
                end
            end
          
        elseif display_double_left_arrow
            %Left Arrow - Big jump 2 probes
            if selected_probe == 4
                Screen('DrawLines',window,[Probes.x(selected_probe)-floor(ProbeSize*0.3) Probes.x(selected_probe)+floor(ProbeSize*0.3);...
                                           Probes.y(selected_probe) Probes.y(selected_probe)],4, [50 200 255]);
                Screen('DrawLines',window,[Probes.x(selected_probe)-floor(ProbeSize*0.3) Probes.x(selected_probe)-floor(ProbeSize*0.1);...
                                           Probes.y(selected_probe) Probes.y(selected_probe)+floor(ProbeSize*0.08)],4, [50 200 255])  ;                   
                Screen('DrawLines',window,[Probes.x(selected_probe)-floor(ProbeSize*0.3) Probes.x(selected_probe)-floor(ProbeSize*0.1);...
                                           Probes.y(selected_probe) Probes.y(selected_probe)-floor(ProbeSize*0.08)],4, [50 200 255]) ;                      
                Screen('Drawtextures',window,photodiode_texture6,[],photodiode);
                if off
                    6
                    %io64(ioObj,address,6);
                    WaitSecs(0.001);
                    %io64(ioObj,address,0);
                end
            end
        end
        off = false;
     
    elseif now-saccade_timer>2 && now-saccade_timer<3 && on
        
        if selected_probe ==2
            if display_right_arrow
                %io64(ioObj,address,11);
                11
                WaitSecs(0.001);
                %io64(ioObj,address,0);
            elseif display_double_right_arrow
                %io64(ioObj,address,15);
                15
                WaitSecs(0.001);
                %io64(ioObj,address,0);
            end
            
            
        elseif selected_probe ==4
            if display_left_arrow
                %io64(ioObj,address,13);
                13
                WaitSecs(0.001);
                %io64(ioObj,address,0);
            elseif display_double_left_arrow
                %io64(ioObj,address,16);
                16
                WaitSecs(0.001);
                %io64(ioObj,address,0);
            end
            
        elseif selected_probe ==3
            if display_right_arrow
                %io64(ioObj,address,12);
                12
                WaitSecs(0.001);
                %io64(ioObj,address,0);
            elseif display_left_arrow
                %io64(ioObj,address,14);
                14
                WaitSecs(0.001);
                %io64(ioObj,address,0);
            end
        end
        on = false;  
        off = true;
            
    elseif now-saccade_timer>3
        if selected_probe ==2
            if display_right_arrow
                selected_probe = 3;
            elseif display_double_right_arrow
                selected_probe = 4;
            end
            if selected_probe == 3
                temp = randi(2);
                temp1 = [true,false];
                display_right_arrow = temp1(temp);
                display_left_arrow =~display_right_arrow;
                display_double_left_arrow = false;
                display_double_right_arrow = false;
            elseif selected_probe == 4
                display_right_arrow = false;
                display_double_right_arrow = false;
                temp = randi(2);
                temp1 = [true,false];
                display_double_left_arrow = temp1(temp);
                display_left_arrow =~display_double_left_arrow;
            end

        elseif selected_probe ==4
            if display_left_arrow
                selected_probe = 3;
            elseif display_double_left_arrow
                selected_probe = 2;
            end
            if selected_probe == 2
                temp = randi(2);
                temp1 = [true,false];
                display_right_arrow = temp1(temp);
                display_double_right_arrow =~display_right_arrow;
                display_left_arrow = false;
                display_double_left_arrow = false;
            elseif selected_probe == 3
                temp = randi(2);
                temp1 = [true,false];
                display_right_arrow = temp1(temp);
                display_left_arrow =~display_right_arrow;
                display_double_right_arrow = false;
                display_double_left_arrow = false;
            end
           
        elseif selected_probe ==3
            if display_right_arrow
                selected_probe = 4;
                display_right_arrow = false;
                display_double_right_arrow = false;
                temp = randi(2);
                temp1 = [true,false];  
                display_left_arrow  = temp1(temp);
                display_double_left_arrow = ~display_left_arrow;
                
            elseif display_left_arrow
                selected_probe = 2;
                display_left_arrow  = false;
                display_double_left_arrow = false;
                temp = randi(2);
                temp1 = [true,false];  
                display_right_arrow = temp1(temp);
                display_double_right_arrow = ~display_right_arrow;
            end
        end
        saccade_timer = toc;
        next_rounds_lag  = rand(1)*1;
    end
    
%     Screen('gluDisk', window, FPColor, fixPoint.x(fixation), fixPoint.y(fixation), fixPoint.sizePix ); 
    Screen('gluDisk', window, [255 0 0], Probes.x(2),Probes.y(2), 6); 
    Screen('gluDisk', window, [255 0 0], Probes.x(3),Probes.y(3), 6); 
    Screen('gluDisk', window, [255 0 0], Probes.x(4),Probes.y(4), 6); 
  
%     Screen('Flip',window,0);
    lastFlipTime = Screen('Flip',window,lastFlipTime+ifi/2);     
end


%%
% DrawFormattedText(window, 'You re free!!!',resolutionWidthPix/2,resolutionHeightPix/2,255*[1 0 0]);
% Screen(window, 'Flip');
% disp('Press a key to continue');
% KbWait;
Screen('CloseAll');
Priority(0);%drop priority back to normal
ShowCursor
