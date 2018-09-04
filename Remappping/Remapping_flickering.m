Screen('Preference', 'SkipSyncTests', 1);

%% Important Variables

experiment_time = 0.1; % In minutes

response_latency                       = 0.05; % Response latency of the subject. IN SECONDS. This is crucial for P2 presentation. 


% Projector
stim.displayParams.resolutionWidthPix  = 1920; % Resolution of the projector
stim.displayParams.resolutionHeightPix = 1080;

% Probes
stim.ProbeSize                         =    6; % Size of the side of the square probe. IN DEGREES
stim.distance_between_FPs              =   10; % SACCADE DISTANCE. IN DEGREES! All the distances of the fixation points and the probes will be affected by this

% Frequency Tagging
stim.probe.f1                          =   2;
stim.probe.f2                          =   3;
stim.probe.f3                          =   4;
stim.probe.f4                          =   1;
stim.probe.f5                          =   5;

%% Initiation values !!!!!

stim.probeColor      = [255 255 255] ; % Color of probes. White
stim.FPColor         = [255   0   0] ; % Color of fixation point : Red
stim.backgroundColor = [127 127 127] ; % Gray color on the background

photodiode_size      = 20                     ; % Size of photodiode projected on bottom-right in pixels : 20x20
photodiode_min       = stim.backgroundColor(1); % Minimum value for the photodiode 0=black, 255=white

probes_Y_distance    = 0                      ; % Distance of the probes from the moddle line in the Y- Axis. IN DEGREES

stim.probe.t1        = 1/stim.probe.f1        ; % Duration of the cycle for the frequency tagged probes
stim.probe.t2        = 1/stim.probe.f2        ; % Use these values as the lag between frames
stim.probe.t3        = 1/stim.probe.f3        ;
stim.probe.t4        = 1/stim.probe.f4        ;
stim.probe.t5        = 1/stim.probe.f5        ;

%% Transform whatever is in degrees to pixels

% How many pixels per degree for x and y axis
stim.displayParams.PixPerDeg = 20; % This is calculated from the screen distance (actually it's 1 degree_x = 19.45 pixels and degree_y = 20.5 pixels)

saccade_vector    = stim.distance_between_FPs*stim.displayParams.PixPerDeg; % Saccade distance. IN PIXELS
stim.ProbeSize    = stim.ProbeSize*stim.displayParams.PixPerDeg;
probes_Y_distance = probes_Y_distance*stim.displayParams.PixPerDeg;

%% Probes location centers (3 probes)

stim.Probes.x = stim.displayParams.resolutionWidthPix/2 + saccade_vector*[-1 0 1 -2 2];  
stim.Probes.y = (stim.displayParams.resolutionHeightPix/2 + probes_Y_distance) * [1 1 1 1 1];    

%% Initiate Screen

[stim.displayParams.window, screenRect]=Screen('OpenWindow',1,[0 0 0 0]);


%% INITIALIZE THE LOW_LATENCY PARALLEL PORT DRIVER
% ioObj=io64;%create a parallel port handle
% status=io64(ioObj);%if this returns '0' the port driver is loaded & ready 
% address=hex2dec('D010');%'378' is the default address of LPT1 in hex


%% Increase priority on CPU for smooth execution

priorityLevel=MaxPriority(stim.displayParams.window);
Priority(priorityLevel);  % raise priority for stimulus presentation   

HideCursor


%% Get ready
numCheckers = 12; % Number of checkers per side on the probe - NOT READY YET

multiplier = floor(stim.ProbeSize/numCheckers);
miniboard = eye(2,'uint8') .* 255;
checkerboard_heads = repmat(miniboard, ceil(0.5 .* numCheckers))';
checkerboard_tails = 255 - checkerboard_heads;
checkerboard_heads = imresize(checkerboard_heads,round(sqrt(numCheckers*multiplier)),'box');
checkerboard_tails = imresize(checkerboard_tails,round(sqrt(numCheckers*multiplier)),'box');

round(sqrt(numCheckers*multiplier))

checker_texture          = Screen('MakeTexture',stim.displayParams.window,checkerboard_heads(1:stim.ProbeSize,1:stim.ProbeSize));
inverse_checker_texture  = Screen('MakeTexture',stim.displayParams.window,checkerboard_tails(1:stim.ProbeSize,1:stim.ProbeSize));

photodiode_texture1      = Screen('MakeTexture',stim.displayParams.window,round(stim.probeColor/1));
photodiode_texture2      = Screen('MakeTexture',stim.displayParams.window,round(stim.probeColor/2));
photodiode_texture3      = Screen('MakeTexture',stim.displayParams.window,round(stim.probeColor/3));
photodiode_texture4      = Screen('MakeTexture',stim.displayParams.window,round(stim.probeColor/4));
photodiode_texture5      = Screen('MakeTexture',stim.displayParams.window,round(stim.probeColor/5));


% noisetex = CreateProceduralNoise(stim.displayParams.window, 30, 30, 'Perlin', [0.5 0.5 0.5 0.0]);

stim.photodiode = CenterRectOnPoint([0 0 photodiode_size photodiode_size],stim.displayParams.resolutionWidthPix -photodiode_size/2,...
                                                                          stim.displayParams.resolutionHeightPix-photodiode_size/2);

% DrawFormattedText(stim.displayParams.window, 'Ready ?',stim.displayParams.resolutionWidthPix/2,stim.displayParams.resolutionHeightPix/2,255*[1 1 1]);
Screen(stim.displayParams.window, 'Flip');
disp('Press a key to continue');
KbWait;
pause(.5)


%% Prepare stimulus
% There are 3 probes that flicker in different frequencies
% I will use 3 different timers that have to be reset when they expire
tic
experiment_start = toc;

timer1 = toc;
timer2 = toc;
timer3 = toc;
timer4 = toc;
timer5 = toc;
saccade_timer = toc;


selected_probe = 1;
next_rounds_lag  = rand(1);
display_right_arrow = true;
display_left_arrow = false;

now = toc;
on = false;
off = true;
while now-experiment_start < experiment_time * 60
    now = toc;
    
    % Create square 1 with f1
    if now-timer1<stim.probe.t1/2
        Screen('DrawTexture', stim.displayParams.window, checker_texture, [], [stim.Probes.x(1)-stim.ProbeSize/2, stim.Probes.y(1)-stim.ProbeSize/2,...
                                                                               stim.Probes.x(1)+stim.ProbeSize/2, stim.Probes.y(1)+stim.ProbeSize/2],...
                                                                               0, [], [], [], [], []);
        
    elseif now-timer1>stim.probe.t1/2 && now-timer1<stim.probe.t1
        Screen('DrawTexture', stim.displayParams.window, inverse_checker_texture, [], [stim.Probes.x(1)-stim.ProbeSize/2, stim.Probes.y(1)-stim.ProbeSize/2,...
                                                                                       stim.Probes.x(1)+stim.ProbeSize/2, stim.Probes.y(1)+stim.ProbeSize/2],...
                                                                                       0, [], [], [], [], []);
    elseif now-timer1>stim.probe.t1
        Screen('DrawTexture', stim.displayParams.window, checker_texture, [], [stim.Probes.x(1)-stim.ProbeSize/2, stim.Probes.y(1)-stim.ProbeSize/2,...
                                                                               stim.Probes.x(1)+stim.ProbeSize/2, stim.Probes.y(1)+stim.ProbeSize/2],...
                                                                               0, [], [], [], [], []);
        timer1 = toc;
    end
    
    % Create square 2 with f2
    if now-timer2<stim.probe.t2/2
        Screen('DrawTexture', stim.displayParams.window, checker_texture, [], [stim.Probes.x(2)-stim.ProbeSize/2, stim.Probes.y(2)-stim.ProbeSize/2,...
                                                                               stim.Probes.x(2)+stim.ProbeSize/2, stim.Probes.y(2)+stim.ProbeSize/2],...
                                                                               0, [], [], [], [], []);
    elseif now-timer2>stim.probe.t2/2 && now-timer2<stim.probe.t2
        Screen('DrawTexture', stim.displayParams.window, inverse_checker_texture, [], [stim.Probes.x(2)-stim.ProbeSize/2, stim.Probes.y(2)-stim.ProbeSize/2,...
                                                                                       stim.Probes.x(2)+stim.ProbeSize/2, stim.Probes.y(2)+stim.ProbeSize/2],...
                                                                                       0, [], [], [], [], []);
    elseif now-timer2>stim.probe.t2
        timer2 = toc;
    end
    % Create square 3 with f3
    if now-timer3<stim.probe.t3/2
        Screen('DrawTexture', stim.displayParams.window, checker_texture, [], [stim.Probes.x(3)-stim.ProbeSize/2, stim.Probes.y(3)-stim.ProbeSize/2,...
                                                                               stim.Probes.x(3)+stim.ProbeSize/2, stim.Probes.y(3)+stim.ProbeSize/2],...
                                                                               0, [], [], [], [], []);
    elseif now-timer3>stim.probe.t3/2 && now-timer3<stim.probe.t3
        Screen('DrawTexture', stim.displayParams.window, inverse_checker_texture, [], [stim.Probes.x(3)-stim.ProbeSize/2, stim.Probes.y(3)-stim.ProbeSize/2,...
                                                                                       stim.Probes.x(3)+stim.ProbeSize/2, stim.Probes.y(3)+stim.ProbeSize/2],...
                                                                                       0, [], [], [], [], []);
    elseif now-timer3>stim.probe.t3
        Screen('DrawTexture', stim.displayParams.window, checker_texture, [], [stim.Probes.x(3)-stim.ProbeSize/2, stim.Probes.y(3)-stim.ProbeSize/2,...
                                                                               stim.Probes.x(3)+stim.ProbeSize/2, stim.Probes.y(3)+stim.ProbeSize/2],...
                                                                               0, [], [], [], [], []);
        timer3 = toc;
    end
    

    % Create square 4 with f4
    if now-timer4<stim.probe.t4/2
        Screen('DrawTexture', stim.displayParams.window, checker_texture, [], [stim.Probes.x(4)-stim.ProbeSize/2, stim.Probes.y(4)-stim.ProbeSize/2,...
                                                                               stim.Probes.x(4)+stim.ProbeSize/2, stim.Probes.y(4)+stim.ProbeSize/2],...
                                                                               0, [], [], [], [], []);
    elseif now-timer4>stim.probe.t4/2 && now-timer4<stim.probe.t4
        Screen('DrawTexture', stim.displayParams.window, inverse_checker_texture, [], [stim.Probes.x(4)-stim.ProbeSize/2, stim.Probes.y(4)-stim.ProbeSize/2,...
                                                                                       stim.Probes.x(4)+stim.ProbeSize/2, stim.Probes.y(4)+stim.ProbeSize/2],...
                                                                                       0, [], [], [], [], []);
    elseif now-timer4>stim.probe.t4
        Screen('DrawTexture', stim.displayParams.window, checker_texture, [], [stim.Probes.x(4)-stim.ProbeSize/2, stim.Probes.y(4)-stim.ProbeSize/2,...
                                                                               stim.Probes.x(4)+stim.ProbeSize/2, stim.Probes.y(4)+stim.ProbeSize/2],...
                                                                               0, [], [], [], [], []);
        timer4 = toc;
    end    
    

    
    % Create square 5 with f5
    if now-timer5<stim.probe.t5/2
        Screen('DrawTexture', stim.displayParams.window, checker_texture, [], [stim.Probes.x(5)-stim.ProbeSize/2, stim.Probes.y(5)-stim.ProbeSize/2,...
                                                                               stim.Probes.x(5)+stim.ProbeSize/2, stim.Probes.y(5)+stim.ProbeSize/2],...
                                                                               0, [], [], [], [], []);
    elseif now-timer5>stim.probe.t5/2 && now-timer5<stim.probe.t5
        Screen('DrawTexture', stim.displayParams.window, inverse_checker_texture, [], [stim.Probes.x(5)-stim.ProbeSize/2, stim.Probes.y(5)-stim.ProbeSize/2,...
                                                                                       stim.Probes.x(5)+stim.ProbeSize/2, stim.Probes.y(5)+stim.ProbeSize/2],...
                                                                                       0, [], [], [], [], []);
    elseif now-timer5>stim.probe.t5
        Screen('DrawTexture', stim.displayParams.window, checker_texture, [], [stim.Probes.x(5)-stim.ProbeSize/2, stim.Probes.y(5)-stim.ProbeSize/2,...
                                                                               stim.Probes.x(5)+stim.ProbeSize/2, stim.Probes.y(5)+stim.ProbeSize/2],...
                                                                               0, [], [], [], [], []);
        timer5 = toc;
    end    
    
    % Create sequentially a que for the saccade
    
    if now-saccade_timer>0.5+next_rounds_lag && now-saccade_timer<2
        on = true;
%         Screen('FrameRect', stim.displayParams.window, [255 0 0], [stim.Probes.x(selected_probe)-stim.ProbeSize/2, stim.Probes.y(selected_probe)-stim.ProbeSize/2,...
%                                                                         stim.Probes.x(selected_probe)+stim.ProbeSize/2, stim.Probes.y(selected_probe)+stim.ProbeSize/2],5)
    
        if display_right_arrow
            %Right Arrow
            Screen('DrawLines',stim.displayParams.window,[stim.Probes.x(selected_probe)-floor(stim.ProbeSize*0.3) stim.Probes.x(selected_probe)+floor(stim.ProbeSize*0.3);...
                                       stim.Probes.y(selected_probe) stim.Probes.y(selected_probe)],4, [0 255 0])
            Screen('DrawLines',stim.displayParams.window,[stim.Probes.x(selected_probe)+floor(stim.ProbeSize*0.3) stim.Probes.x(selected_probe)+floor(stim.ProbeSize*0.1);...
                                       stim.Probes.y(selected_probe) stim.Probes.y(selected_probe)+floor(stim.ProbeSize*0.08)],4, [0 255 0])                     
            Screen('DrawLines',stim.displayParams.window,[stim.Probes.x(selected_probe)+floor(stim.ProbeSize*0.3) stim.Probes.x(selected_probe)+floor(stim.ProbeSize*0.1);...
                                       stim.Probes.y(selected_probe) stim.Probes.y(selected_probe)-floor(stim.ProbeSize*0.08)],4, [0 255 0])  
              
            if selected_probe == 1
                Screen('Drawtextures',stim.displayParams.window,photodiode_texture1,[],stim.photodiode);
                if off
                    1
                    %io64(ioObj,address,1);
                    WaitSecs(0.001);
                    %io64(ioObj,address,0);
                end
            elseif selected_probe == 2
                Screen('Drawtextures',stim.displayParams.window,photodiode_texture2,[],stim.photodiode);
                if off
                    2
                    %io64(ioObj,address,2);
                    WaitSecs(0.001);
                    %io64(ioObj,address,0);
                end
            end

        elseif display_left_arrow
            %Left Arrow
            Screen('DrawLines',stim.displayParams.window,[stim.Probes.x(selected_probe)-floor(stim.ProbeSize*0.3) stim.Probes.x(selected_probe)+floor(stim.ProbeSize*0.3);...
                                       stim.Probes.y(selected_probe) stim.Probes.y(selected_probe)],4, [0 255 0])
            Screen('DrawLines',stim.displayParams.window,[stim.Probes.x(selected_probe)-floor(stim.ProbeSize*0.3) stim.Probes.x(selected_probe)-floor(stim.ProbeSize*0.1);...
                                       stim.Probes.y(selected_probe) stim.Probes.y(selected_probe)+floor(stim.ProbeSize*0.08)],4, [0 255 0])                     
            Screen('DrawLines',stim.displayParams.window,[stim.Probes.x(selected_probe)-floor(stim.ProbeSize*0.3) stim.Probes.x(selected_probe)-floor(stim.ProbeSize*0.1);...
                                       stim.Probes.y(selected_probe) stim.Probes.y(selected_probe)-floor(stim.ProbeSize*0.08)],4, [0 255 0])                       
            if selected_probe == 3
                Screen('Drawtextures',stim.displayParams.window,photodiode_texture3,[],stim.photodiode);
                if off
                    3
                    %io64(ioObj,address,3);
                    WaitSecs(0.001);
                    %io64(ioObj,address,0);
                end
            elseif selected_probe == 2
                Screen('Drawtextures',stim.displayParams.window,photodiode_texture4,[],stim.photodiode);
                if off
                    4
                    %io64(ioObj,address,4);
                    WaitSecs(0.001);
                    %io64(ioObj,address,0);
                end
            end
        end
        off = false;
     
    elseif now-saccade_timer>2 && now-saccade_timer<3 && on
        
        if selected_probe ==1
            %io64(ioObj,address,11);
            11
            WaitSecs(0.001);
            %io64(ioObj,address,0);
        elseif selected_probe ==3
            %io64(ioObj,address,13);
            13
            WaitSecs(0.001);
            %io64(ioObj,address,0);
        elseif selected_probe ==2
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
        if selected_probe ==1
            selected_probe = 2;
            temp = randi(2);
            temp1 = [true,false];
            display_right_arrow = temp1(temp);
            display_left_arrow =~display_right_arrow;

        elseif selected_probe ==3
            selected_probe = 2;
            temp = randi(2);
            temp1 = [true,false];
            display_right_arrow = temp1(temp);
            display_left_arrow =~display_right_arrow;
        elseif selected_probe ==2
            if display_right_arrow
                selected_probe = 3;
                display_right_arrow = false;
                display_left_arrow  = true ;
                
            elseif display_left_arrow
                selected_probe = 1;
                display_right_arrow = true ;
                display_left_arrow  = false;
            end
        end
        saccade_timer = toc;
        next_rounds_lag  = rand(1)*1;
    end
    
%     Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
    Screen('gluDisk', stim.displayParams.window, [255 0 0], stim.Probes.x(1),stim.Probes.y(1), 6); 
    Screen('gluDisk', stim.displayParams.window, [255 0 0], stim.Probes.x(2),stim.Probes.y(2), 6); 
    Screen('gluDisk', stim.displayParams.window, [255 0 0], stim.Probes.x(3),stim.Probes.y(3), 6); 
  
    Screen('Flip',stim.displayParams.window,0);
    
end


%%
% DrawFormattedText(stim.displayParams.window, 'You re free!!!',stim.displayParams.resolutionWidthPix/2,stim.displayParams.resolutionHeightPix/2,255*[1 0 0]);
% Screen(stim.displayParams.window, 'Flip');
% disp('Press a key to continue');
% KbWait;

Screen('CloseAll')
Priority(0);%drop priority back to normal
ShowCursor
