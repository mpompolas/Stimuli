

%% Events

% 1,2,3,4,5,6,7       : No. of P2 probe ON  - Fixation on FP1
% 11,12,13,14,15,16,17: No. of P2 probe ON  - Fixation on FP2
% 21,22,23,24,25,26,27: No. of P2 probe OFF - Fixation on FP1
% 31,32,33,34,35,36,37: No. of P2 probe OFF - Fixation on FP2

% 41,42,43,44,45,46,47: No. of P1 probe ON  - Fixation on FP1
% 51,52,53,54,55,56,57: No. of P1 probe ON  - Fixation on FP2
% 61,62,63,64,65,66,67: No. of P1 probe OFF - Fixation on FP1
% 71,72,73,74,75,76,77: No. of P1 probe OFF - Fixation on FP2

% 101,102             : Fixation points FP1 and FP2 ON.

%% Important Variables


run = 1;




number_of_trials = 20; % Each trial is ~4.5 sec. 150 trials ~=11 minutes

response_latency                       = 0.05; % Response latency of the subject. IN SECONDS. This is crucial for P2 presentation. 

stim.displayParams.resolutionWidthPix  = 1920; % Resolution of the projector
stim.displayParams.resolutionHeightPix = 1080;

stim.ProbeSize                         =    4; % Size of the side of the square probe. IN DEGREES
stim.distance_between_FPs              =   10; % SACCADE DISTANCE. IN DEGREES! All the distances of the fixation points and the probes will be affected by this

%% Initiation values !!!!!

stim.FP_size         = 0.3; % RADIUS OF FIXATION POINT. IN DEGREES
triangle_size        = 8;  % Size of Triangle for P2 projection on the target. IN PIXELS 






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

stim.Probes.x = stim.displayParams.resolutionWidthPix/2 + saccade_vector*[0 0];
            
stim.Probes.y = (stim.displayParams.resolutionHeightPix/2 + probes_Y_distance) * [1];    
stim.Probes.y = [stim.Probes.y stim.displayParams.resolutionHeightPix/2 - 10*probes_Y_distance]; % Probe 7 will be out of the screen (empty trial)

%% Initiate Screen

[stim.displayParams.window, screenRect]=Screen('OpenWindow',2,[0 0 0 0]);

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


%% Add two triangles that will be displayed within the targets
%  Each triangle point to the left or the right and subjects need to report
%  the orientation

% Number of sides for our polygon
numSides = 3;

% Angles at which our polygon vertices endpoints will be. We start at zero
% and then equally space vertex endpoints around the edge of a circle. The
% polygon is then defined by sequentially joining these end points.
anglesDeg = linspace(0, 360, numSides + 1)';
anglesRad = anglesDeg * (pi / 180);

% X and Y coordinates of the points defining out polygon, centered on each
% fixation point

% Set the color of the triangle
rectColor = [0 1 1];

% Cue to tell PTB that the polygon is convex (concave polygons require much
% more processing)
isConvex = 1;



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
% 
Screen('FillRect', stim.displayParams.window, stim.backgroundColor);

while trial <number_of_trials+1

    % DELETE ME %%%%%%%%%%%%%%%%%%%%%
    if KbCheck(-1)
        break;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    for fixation = 1:2
        
        
        % Present Fixation point
        Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
        lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime+rand(1)*1+0.5);     %500-1500msec
        

        %io64(ioObj,address,100+fixation); % 101,102 indicate the fixation
        WaitSecs(0.001);
        %io64(ioObj,address,0);

% % % % %         % Proof that the biased result is the appropriate one
% % % % %         a = zeros(1000000,1);
% % % % %         for i = 1:1000000
% % % % %             a(i) = biased_selection(randi(10,1,1));
% % % % %         end
% % % % %         
% % % % %         [aa,bb]=hist(a,unique(a));
        
        iprobes = [biased_selection(randi(10,1,1)) biased_selection(randi(10,1,1))]; % One for P1 and 1 for P2


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Present P2 and fixation point
        Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
        Screen('Drawtextures',stim.displayParams.window,stim.probetexture,[],stim.rectprobe(iprobes(2),:));
        Screen('Drawtextures',stim.displayParams.window,stim.photodiode_texture,[],stim.photodiode);
        
        % Create triangle within the PROJECTED FIXATION POINT 
        triangle_direction = [-1,1];
        xTriangles = triangle_direction(randi(2,1,1))*cos(anglesRad) .* triangle_size + stim.fixPoint.x(fixation);
        yTriangles =                                  sin(anglesRad) .* triangle_size + stim.fixPoint.y(fixation);
        Screen('FillPoly', stim.displayParams.window, [], [xTriangles yTriangles], isConvex);
        
        lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime+response_latency);  % Response latency of the subject  
        %io64(ioObj,address,iprobes(2)+(fixation-1)*10);
        WaitSecs(0.001);
        %io64(ioObj,address,0);

        % Remove P2 and triangle but keep fixation point
        Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
        lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime+0.05);          
        %io64(ioObj,address,iprobes(2)+(fixation-1)*10+20);
        WaitSecs(0.001);
        %io64(ioObj,address,0);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Present P1 and fixation point
        Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
        Screen('Drawtextures',stim.displayParams.window,stim.probetexture,[],stim.rectprobe(iprobes(1),:));
        Screen('Drawtextures',stim.displayParams.window,stim.photodiode_texture,[],stim.photodiode);
        lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime+rand(1)*1+0.5);     %500-1500msec   
        %io64(ioObj,address,iprobes(1)+(fixation-1)*10+40);
        WaitSecs(0.001);
        %io64(ioObj,address,0);

        % Remove P1 but keep fixation point
        Screen('gluDisk', stim.displayParams.window, stim.FPColor, stim.fixPoint.x(fixation), stim.fixPoint.y(fixation), stim.fixPoint.sizePix ); 
        lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime+0.05);          
        %io64(ioObj,address,iprobes(1)+(fixation-1)*10+60);
        WaitSecs(0.001);
        %io64(ioObj,address,0);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    end

    trial = trial+1;

end
  
if run == 6
    DrawFormattedText(stim.displayParams.window, 'You re free!!!',stim.displayParams.resolutionWidthPix/2,stim.displayParams.resolutionHeightPix/2,255*[1 0 0]);
else
    DrawFormattedText(stim.displayParams.window, 'Break!',stim.displayParams.resolutionWidthPix/2,stim.displayParams.resolutionHeightPix/2,255*[1 0 0]);
end

Screen(stim.displayParams.window, 'Flip');
disp('Press a key to continue');
KbWait;




Screen('CloseAll')
Priority(0);%drop priority back to normal
ShowCursor
clear mex
