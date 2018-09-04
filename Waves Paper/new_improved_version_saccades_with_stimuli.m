%% Events

% 51 is the presentation of Target 1 - A leftwards saccade is about to happen
% 52 is the presentation of Target 1 - A rightwards saccade is about to happen

% 1:10 marks the beginning of every minute of each run, or 1:stimDuration
% 100 photodiode reached minimum value:   0=black
% 150 photodiode reached maximum value: 150=grey

Screen('Preference', 'SkipSyncTests', 1);





%% Important Variables


run = 1;


range_for_lag = [1, 1.5]; % Range of Time that each fixation will last: how often there will be a saccade
                          % In seconds. Example: Minimum 0.8 sec, maximum 1.2


stimDuration         =     12;    % STIM DURATION IN MINUTES (DURATION OF EXPERIMENT) NOT EXACT TIMING
distance_of_saccade  =      26;    % Distance between fixation points. In degrees
resolutionWidthPix   =   1280;
resolutionHeightPix  =   1024;
sparseness           = 0.0065;    % density of the squares
stimSize             =      1;    % size of the squares, in degrees

stimFramerate        =     10 ;    % FRAMERATE OF STIMULUS Hz

%% Initiation values !!!!!

stimDuration    = stimDuration*60 ; % Stimulus Duration in seconds
FP_size         = 0.25                 ;  % SIZE OF FIXATION POINT, IN DEGREES - THIS IS THE RADIUS OF THE FIXATION POINT, NOT THE DIAMETER

photodiode_size    =  20;  % Size of photodiode projected on bottom-right in pixels : 20x20
photodiode_minimum =   0;  % Minimum value for the photodiode 0=black, 255=white
photodiode_maximum = 200;  % Minimum value for the photodiode 0=black, 255=white


xPixPerDeg = 20;
yPixPerDeg = 20;

showFixationPointFlag    =  1;

%% Possible positions of the fixation point

fixPointPosition.x=[resolutionWidthPix/2 - distance_of_saccade/2*xPixPerDeg resolutionWidthPix/2 + distance_of_saccade/2*xPixPerDeg];
fixPointPosition.y=[resolutionHeightPix/2  resolutionHeightPix/2];

%% Initiate Screen and calculating the desired refresh rate

[window, screenRect]=Screen('OpenWindow',2,[0 0 0 0]);


flipInterval = Screen('GetFlipInterval', window);
frameRateHz = 1/flipInterval;
 
disp('--------------------------------')
disp(['Screen Refresh Rate: ' num2str(FrameRate) ' Hz'])
disp('--------------------------------')    

frameMultiplier  = round(frameRateHz/stimFramerate);
nominalFramerate = frameRateHz/frameMultiplier;

disp(num2str(nominalFramerate))
nframes    = ceil(nominalFramerate*stimDuration); % Total number of frames for the whole run

%% calcucate the grid (density)
probeColor       = [255,255,255];
FPColor          = [255,  0,  0];  % Fixation point color - Red=[255,0,0]
backgroundColor  = [  0,  0,  0];  % Background color
stimSize         = stimSize * (xPixPerDeg + yPixPerDeg)/2;
xvals            = 0: stimSize:resolutionWidthPix ;  % [-100: 1:-100+200] = [-100:100], 1x201
yvals            = 0: stimSize:resolutionHeightPix; % [  55:-1:  55-150] = [  55:-95], 1x151

tic

%% INITIALIZE THE LOW_LATENCY PARALLEL PORT DRIVER
% ioObj=io64;%create a parallel port handle
% status=io64(ioObj);%if this returns '0' the port driver is loaded & ready 
% address=hex2dec('D010');%'378' is the default address of LPT1 in hex



%% Initialization
frameNumber      = 1;
temp    =       [1 2];
switch1 =       [2 1];  % temp files used to detect changes in fixation position
switch2 =       [1 2];
random_change    = -1;
lastFlipTime     = 0;
photodiode_value = photodiode_minimum;
minute           = 1;
fixation1_ON     = 1;
fixation2_ON     = 0;

%% Increase priority on CPU for smooth execution

priorityLevel=MaxPriority(window);
Priority(priorityLevel);     % raise priority for stimulus presentation   


%% Start the projection

HideCursor


the_minutes = [];


tic
while frameNumber < nframes
        
        %% The photodiode will change its intensity on a sawtooth-way to
        %  monitor the lag in response to the photodiode's electronics
        %  Starts at black (0), goes above grey (150) in steps defined by the variable: increase_decrease
        %  The transition is 0:increase_decrease:150 and then switches to: 150:-increase_decrease:0
        %  This whole cycle lasts one second! 
        %  IMPORTANT FOR DEFINING WHICH FRAME IS PROJECTED IN EVERY TIME POINT
    
        if photodiode_value == photodiode_minimum
            increase_decrease =  round((photodiode_maximum-photodiode_minimum)/(floor(stimFramerate/2)));
        elseif photodiode_value == photodiode_maximum
            increase_decrease = -round((photodiode_maximum-photodiode_minimum)/(floor(stimFramerate/2)));
        end

        
        %% CHANGE POSITION OF THE DOT EVERY 0.8 TO 1.2 SECONDS

             
        
        if random_change < 0
            random_change = ((range_for_lag(2)-range_for_lag(1))*rand(1,1) + range_for_lag(1))*stimFramerate;       %%%%%% CHANGE POSITION EVERY 0.8 TO 1.2 SECONDS)
            
            if temp == switch2
                fixPoint.x=fixPointPosition.x(1);
                fixPoint.y=fixPointPosition.y(1);
                temp = [temp(2) 1];
                fixation1_ON = 1;
%                 disp('HERE')

            elseif temp == switch1
                fixPoint.x=fixPointPosition.x(2);
                fixPoint.y=fixPointPosition.y(2);
                temp = [temp(2) 2];
                fixation2_ON = 1;

%                 disp('NOW HERE')

            end
             
        end
        
        
        %% Create squares in random places
        
        %- The values on variable frame, will be the same every time based on the framNumber input on RandStream
        
        s = RandStream.setGlobalStream(RandStream('mt19937ar','seed',frameNumber + (run-1)*nframes));  % This sets specific stream for the creation of random numbers
        frame   = rand(length(yvals),length(xvals)); % 151x201 values (0,1) 
        
        grid2   = (frame<sparseness); % 151x201 logical
        [rr,cc] = find(grid2~=0);
        xx      = xvals(cc); % Coordinates of the squares projected
        yy      = yvals(rr);
        
        %% Remove squares that might interfere with the photodiode's stimulus
        %  Have to make the squares to project exactly at the screen size
        %  to work. Either way when the second texture (the one of the photodiode)
        %  is projected, it overwrites the square if it was projected
        %  there, making these lines of code redundant
        
        photodiode_x = xx>resolutionWidthPix - 2*photodiode_size; % example: 1x102 logical
        photodiode_y = yy<2*photodiode_size;                                         % example: 1x102 logical

        outside_photodiode_square  = ~(photodiode_x & photodiode_y); % example: 1x102 logical
        xx = xx(outside_photodiode_square);
        yy = yy(outside_photodiode_square);
        
        
        %% Project squares randomly at the background
        
        probetexture   = Screen('MakeTexture',window,probeColor);
        rectprobe      = CenterRectOnPoint([0 0 stimSize stimSize],xx',yy');
        rectprobe      = rectprobe';
        
%         %% To plot on a figure the frame that will be displayed run this:
%         
%         plot(rectprobe(1,:),rectprobe(2,:),'.')
%         hold on
%         plot(rectprobe(3,:),rectprobe(4,:),'r.')
%         grid minor
%         set(gca,'YDir','Reverse')
%         axis([0 resolutionWidthPix 0 resolutionHeightPix])
        
        
        %% Project a square with varying intensity on the bottom right for the photodiode
        
        probetexture_photodiode   = Screen('MakeTexture',window,photodiode_value);
        rectprobe_photodiode      = CenterRectOnPoint([0 0 photodiode_size photodiode_size],resolutionWidthPix-10,resolutionHeightPix-10);
        rectprobe_photodiode      = rectprobe_photodiode'; 
        
        %% Draw the textures. First the Background, then the photodiode (so no square might interfere with the photodiode stimulus)
        
        % 0,0 is at the top
        %left of the screen and increases towards the right (x-axis) and
        %DOWN (y-axis)
        
        Screen('Drawtextures',window,probetexture,           [],rectprobe           );
        Screen('Drawtextures',window,probetexture_photodiode,[],rectprobe_photodiode);
        
        Screen('BlendFunction',window,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
        fixPoint.color = FPColor;
      
        %% Draw fixation point
        
        Screen('gluDisk', window, fixPoint.color, fixPoint.x , fixPoint.y ,FP_size*(xPixPerDeg+yPixPerDeg)/2 );
      
        %% Flip the screen to project things on the screen
        
        lastFlipTime = Screen('Flip',window,lastFlipTime + (frameMultiplier-1/2)*flipInterval);
        
     
        
        %% Create events (After flip). Previous experiments had it before!!!
        
        %% For fixation point change
        

        if fixation1_ON       % fixation 1 on
%             io64(ioObj,address,51);  %was io64(ioObj,address,1) on previous experiments
%       disp(num2str(51))
            c = clock;
%             disp(['Fixation 1 ON: ' num2str(c(4)) ':' num2str(c(5)) ':' num2str(round(c(6)))])
            WaitSecs(0.001);
%             io64(ioObj,address,0);
            fixation1_ON = 0;
        end
        
        if fixation2_ON   % fixation 2 on
%             io64(ioObj,address,52); %was io64(ioObj,address,2) on previous experiments
%       disp(num2str(52))
            c = clock;
%             disp(['Fixation 2 ON: ' num2str(c(4)) ':' num2str(c(5)) ':' num2str(round(c(6)))])
            WaitSecs(0.001);
%             io64(ioObj,address,0);
            fixation2_ON = 0;
        end
        
        
        %% For minute change
        
        if frameNumber==1  % This is just for the first frame to mark the start of the first minute
%             io64(ioObj,address,minute);
            tic
            the_minutes = toc
          WaitSecs(0.001);
%             io64(ioObj,address,0);
        end
        
        if mod(frameNumber,round(nominalFramerate)*60)==0
          minute = minute+1
          the_minutes = [the_minutes toc]
%             io64(ioObj,address,minute);
          WaitSecs(0.001);
%             io64(ioObj,address,0);
        end
        
        %% For troughs and peaks of the photodiode stimulus
        
        if photodiode_value == photodiode_minimum    % Black, trough
%             io64(ioObj,address,100);
%           100
          WaitSecs(0.001);
          
%             io64(ioObj,address,0);
        end
        
        if photodiode_value == photodiode_maximum  % Grey, peak
%             io64(ioObj,address,150);
%           150
          WaitSecs(0.001);
%             io64(ioObj,address,0);
        end
        
        
        %%
        
        frameNumber = frameNumber + 1;
       
        Screen('Close', probetexture           );    % get rid of unneeded textures
        Screen('Close', probetexture_photodiode);    % get rid of unneeded textures
        
        random_change = random_change-1;
        photodiode_value = photodiode_value + increase_decrease;
        
end


toc


KbWait;

Priority(0);%drop priority back to normal
ShowCursor

Screen('Flip',window);
Screen('CloseAll')
clear mex