%% Events

% 1:10 marks the beginning of every minute of each run, or 1:taskParams.stimDuration
% 100 photodiode reached minimum value:   0 = black
% 150 photodiode reached maximum value: 150 = grey
% 200 start of resting period between trials
% 201 end of resting period between trials


% NA VALW DIALEIMMA GIA TO SUBJECT STO TELOS KATHE RUN

%% Important Variables

taskParams.stimDuration                =           10  ;          % STIM DURATION IN MINUTES (DURATION OF EXPERIMENT) NOT EXACT TIMING
screenRefreshRate                      =           60  ;
stim.displayParams.resolutionWidthPix  =         1280  ;
stim.displayParams.resolutionHeightPix =         1024  ;

taskParams.stimFramerate               =           10  ;          % FRAMERATE OF  BACKGROUND STIMULUS in Hz   -   THE FIRST EXPERIMENTS WHERE RUN WITH VALUE 10
percentage_squares_on                   =        0.25  ;          % Percentage of the squares on

% In theory: percentage_squares_on * taskParams.stimSizeMultiplier should
% be constant!!!!!!!!! CHECK THIS AGAIN

FP_size                                =         0.1  ;          % RADIUS OF FIXATION POINT. IN DEGREES
taskParams.minimumSize                 =          0.3  ;          % Minimum size of squares IN DEGREES (close to fovea)

taskParams.stimSizeMultiplier          =          0.3125  ;          % Multiplier for size of the squares. IT'S STILL ABSTRACT
       % THIS GIVES THE SLOPE OF THE DIAGRAM ON THE PAPER!!!!!!!!!!!!!        0.3125 IS BETWEEN V1 AND V2
       % 0.1563 GIA V1
       % 0.4688 GIA V2

%% Initiation values !!!!!

taskParams.probeColorHex          = '0xFFFFFF'        ;           % WAS '0x808080' : Grey Squares on the background. '0xFFFFFF' gives white squares
taskParams.FPColor                = '0x1000000'       ;           % Color of fixation point : Red
taskParams.backgroundColorHex     = '0x999999';%'0x000000'        ;           % Black color on the background

taskParams.stimRect               = [0 0 stim.displayParams.resolutionWidthPix stim.displayParams.resolutionHeightPix];   % Part of the screen for the squares in the background to be presented
% 1,3 are for x-axis              2,4 are for y-axis

taskParams.azimuth                =             0     ;           % Moves the fixation point on the x-axis. IN DEGREES
taskParams.elevation              =             0     ;           % Moves the fixation point on the y-axis. IN DEGREES


photodiode_size                   =            20     ;           % Size of photodiode projected on bottom-right in pixels : 20x20
photodiode_minimum                =             0     ;           % Minimum value for the photodiode 0=black, 255=white
photodiode_maximum                =           200     ;           % Maximum value for the photodiode 0=black, 255=white

taskParams.stimDuration           = taskParams.stimDuration*60 ; % Stimulus Duration in seconds
stim.displayParams.flipInterval   = 1/screenRefreshRate ;        % Period OF SCREEN refresh rate in seconds


% How many pixels per degree for x and y axis
stim.displayParams.xPixPerDeg = 20; % This is calculated from the screen distance (actually it's 1 degree_x = 19.45pixels)
stim.displayParams.yPixPerDeg = 20; % 1 degree_y = 20.5 pixels


stim.fixPoint.sizePix   =  FP_size*(stim.displayParams.xPixPerDeg+stim.displayParams.yPixPerDeg)/2;  % SIZE OF FIXATION POINT
taskParams.sparseness   =  percentage_squares_on/100;        % density of the squares

%% calculating the desired refresh rate

            stim.displayParams.frameRateHz = 1 / stim.displayParams.flipInterval;            

            %% calcucate the grid (density)

           stim.frameMultiplier   = round(stim.displayParams.frameRateHz/taskParams.stimFramerate);   % 60/10 =6
           stim.nominalFramerate  = stim.displayParams.frameRateHz/stim.frameMultiplier;  % 60/6 =10
           stim.nframes           = ceil(stim.nominalFramerate*taskParams.stimDuration); % Total number of frames for the whole run   10*600 = 6000 frames
           stim.probeColor        = hex2array(taskParams.probeColorHex);
           stim.FPColor           = hex2array(taskParams.FPColor);             % Fixation point color - Red=[256,0,0]
           stim.backgroundColor   = hex2array(taskParams.backgroundColorHex);  % Background color
           stim.stimRect          = taskParams.stimRect;                       % [vector of 4 values]
           stim.SizeMultiplier    = taskParams.stimSizeMultiplier;
           stim.azimuth           = taskParams.azimuth;
           stim.elevation         = taskParams.elevation;
           
           stim.eccentricity      = linspace(0,22,60);                         % 60 DIFFERENT ECCENTRICITIES
           stim.angle             = linspace(-pi,pi,60);                       % 60 DIFFERENT ANGLES           
                                                                               % THE PRODUCT OF THESE 2 GIVES THE TOTAL NUMBER OF POSSIBLE POSITIONS FOR THE SQUARES
           
           
           stim.minimumSize       = taskParams.minimumSize;
           
           stim.taskParams        = taskParams;
           
           stim.fixPoint.x        = stim.displayParams.resolutionWidthPix/2+ ...
                                   stim.azimuth* stim.displayParams.xPixPerDeg;   % 960
           stim.fixPoint.y        = stim.displayParams.resolutionHeightPix/2- ...
                                   stim.elevation* stim.displayParams.yPixPerDeg; % 540
            
           
 

%% Initiate Screen

[stim.displayParams.window, screenRect]=Screen('OpenWindow',1,[0 0 0 0]);


%% INITIALIZE THE LOW_LATENCY PARALLEL PORT DRIVER
% ioObj=io64;%create a parallel port handle
% status=io64(ioObj);%if this returns '0' the port driver is loaded & ready 
% address=hex2dec('D010');%'378' is the default address of LPT1 in hex

%% Initialization

lastFlipTime     = 0;
photodiode_value = photodiode_minimum;
minute           = 1;
stim.frameNumber = 1;
irun             = 1;

%% Increase priority on CPU for smooth execution

priorityLevel=MaxPriority(stim.displayParams.window);
Priority(priorityLevel);     % raise priority for stimulus presentation   

% HideCursor



%% Just an initialization screen for the subject to get ready - A key is pressed and the experiment begins

DrawFormattedText(stim.displayParams.window, 'Ready ?',stim.displayParams.resolutionWidthPix/2,stim.displayParams.resolutionHeightPix/2,255*[1 1 1]);
Screen(stim.displayParams.window, 'Flip');
disp('Press a key to continue');
KbWait;

%% Create resting period - ONLY FIXATION POINT IS PROJECTED - PHOTODIODE GOES TO BLACK

stim.fixPoint.color = stim.FPColor;


Screen('FillRect', stim.displayParams.window, [30 30 30 ]);                  % GREY PATCH


%io64(ioObj,address,200);
200
WaitSecs(0.001);
%io64(ioObj,address,0);

Screen('gluDisk', stim.displayParams.window, stim.fixPoint.color, stim.fixPoint.x , stim.fixPoint.y ,stim.fixPoint.sizePix );
lastFlipTime = Screen('Flip',stim.displayParams.window,lastFlipTime + (stim.frameMultiplier-1/2)*stim.displayParams.flipInterval);          
                
% pause(5)

%io64(ioObj,address,201);
201
WaitSecs(0.001);
%io64(ioObj,address,0);


%% Start the projection





% movie = Screen('CreateMovie', stim.displayParams.window, 'MyTestMovie.mp4', 1920, 1080 , 10);



all_frames = cell(36000,1);

while stim.frameNumber+(irun-1)*stim.nframes < 36001%stim.nframes+1
        
        if stim.frameNumber == stim.nframes
    
%             DrawFormattedText(stim.displayParams.window, 'Break',stim.displayParams.resolutionWidthPix/2,stim.displayParams.resolutionHeightPix/2,255*[0.7 0.7 0.7]);
%             Screen(stim.displayParams.window, 'Flip');
%             disp('Press a key to continue');
%             KbWait;
%             pause(0.5)
            
%             DrawFormattedText(stim.displayParams.window, 'Ready ?',stim.displayParams.resolutionWidthPix/2,stim.displayParams.resolutionHeightPix/2,255*[0.7 0.7 0.7]);
%             Screen(stim.displayParams.window, 'Flip');
%             disp('Press a key to continue');
%             KbWait;
%             pause(0.5)
            
            stim.frameNumber = 1;
            irun             = irun+1;
            minute           = 1;
            photodiode_value = photodiode_minimum;    %%%%%%% THIS WAS ADDED FOR MAT'S EXPERIMENT - PROBABLY WILL TAKE CARE OF THE LAG OF THE PHOTODIODE  %%%%%%%%%%%%%

        end
    
    
    
    
        %% The photodiode will change its intensity on a sawtooth-way to
        %  avoid the lag in response of the photodiode's electronics
        %  Starts at black (0), goes to white (200) in steps defined by the variable: increase_decrease
        %  The transition is 0:increase_decrease:200 and then switches to: 200:-increase_decrease:0
        %  This whole cycle lasts ONE SECOND!
        %  IMPORTANT FOR DEFINING WHICH FRAME IS PROJECTED IN EVERY TIME POINT
        
        if photodiode_value == photodiode_minimum
            increase_decrease =  round((photodiode_maximum-photodiode_minimum)/(floor(taskParams.stimFramerate/2)));
        elseif photodiode_value == photodiode_maximum
            increase_decrease = -round((photodiode_maximum-photodiode_minimum)/(floor(taskParams.stimFramerate/2)));
        end
        
        
        
        %% Events for minute change
        
        if stim.frameNumber==1  % This is just for the first frame to mark the start of the first minute
%         io64(ioObj,address,minute);
            minute
              WaitSecs(0.001);
%         io64(ioObj,address,0);
        end
        
        
        
        
        
        if mod(stim.frameNumber-1,taskParams.stimFramerate*60)==0 && stim.frameNumber>2 % PROSOXH NA ELEGXW PWS ONTWS TO VGAZEI SWSTO

            Screen('gluDisk', stim.displayParams.window, stim.fixPoint.color, stim.fixPoint.x , stim.fixPoint.y ,stim.fixPoint.sizePix );
            lastFlipTime     = Screen('Flip',stim.displayParams.window,lastFlipTime); %+ (stim.frameMultiplier-1/2)*stim.displayParams.flipInterval);          

            % 5 seconds pause every minute to use as baseline
            
            %io64(ioObj,address,200);
            200
            WaitSecs(0.001);
            %io64(ioObj,address,0);
                        
%             pause(5)

            %io64(ioObj,address,201);
            201
            WaitSecs(0.001);
            %io64(ioObj,address,0);

            minute = minute+1;
            disp(['Run: ' num2str(irun) ' Minute: ' num2str(minute)])
    %         io64(ioObj,address,minute);
            WaitSecs(0.001);
    %         io64(ioObj,address,0);


        end
        
        
        %% Create squares in random places
        
        %- The values on variable frame, will be the same every time based on the stim.framNumber input on RandStream
        
        s = RandStream.setGlobalStream(RandStream('mt19937ar','seed',stim.frameNumber + (irun-1)*stim.nframes));  % This sets specific stream for the creation of random numbers
        
        frame   = rand(length(stim.angle),length(stim.eccentricity));
        
        grid2   = (frame<taskParams.sparseness);
        [rr,cc] = find(grid2~=0);
        
        [xx,yy] = pol2cart (stim.angle(rr),stim.eccentricity(cc));  % Holds the coordinates of the squares
        
        randomness_x = ((1-(-1)).*rand([1,length(xx)])+(-1)); % Adds some offset on the positions of the squares
        randomness_y = ((1-(-1)).*rand([1,length(yy)])+(-1)); % It's needed so the squares don't have specific positions

        xx = (xx + randomness_x) * stim.displayParams.xPixPerDeg + stim.displayParams.resolutionWidthPix /2 ;
        yy = (yy + randomness_y) * stim.displayParams.yPixPerDeg + stim.displayParams.resolutionHeightPix/2 ;
        
        
        
        % The code below is done in case no squares are on. This would
        % give an error message. It actually creates a "square" out of the
        % screen
        if isempty(xx) && isempty(yy)
            xx = 3000;
            yy = 3000;
            disp('now')
        end
        
        
        %% Project squares randomly at the background
        
        stim.probetexture   = Screen('MakeTexture',stim.displayParams.window,stim.probeColor);
        
        square_size =  sqrt((xx-stim.displayParams.resolutionWidthPix/2).^2+(yy-stim.displayParams.resolutionHeightPix/2).^2)*stim.SizeMultiplier;
        
        stim.rectprobe = [];
        
        square_size(square_size<stim.minimumSize*stim.displayParams.xPixPerDeg) = stim.minimumSize*stim.displayParams.xPixPerDeg; % This line makes the squares close to the fixation point to have a minimum size
        
        
        for square = 1:length(square_size)
            
            temp = CenterRectOnPoint([0 0 square_size(square) square_size(square)],xx(square),yy(square));
            stim.rectprobe = [stim.rectprobe ; temp];
            
        end
        
        stim.rectprobe      = round(stim.rectprobe)';
%         %% Plot the frame that will be displayed, run this:
%         
%         plot(stim.rectprobe(1,:),stim.rectprobe(2,:),'.')
%         hold on
%         plot(stim.rectprobe(3,:),stim.rectprobe(4,:),'r.')
%         grid minor
%         set(gca,'YDir','Reverse')
%         axis([0 stim.displayParams.resolutionWidthPix 0 stim.displayParams.resolutionHeightPix])

        %% Project a square with varying intensity on the bottom right for the photodiode
        
        stim.probetexture_photodiode   = Screen('MakeTexture',stim.displayParams.window,photodiode_value);
        stim.rectprobe_photodiode      = CenterRectOnPoint([0 0 photodiode_size photodiode_size],stim.displayParams.resolutionWidthPix-photodiode_size/2 ,stim.displayParams.resolutionHeightPix-photodiode_size/2);
        stim.rectprobe_photodiode      = stim.rectprobe_photodiode';

        %% Draw the textures. First the Background, then the photodiode (so no square might interfere with the photodiode stimulus)
        
        % 0,0 is at the top left of the screen and increases
        % towards the right (x-axis) and down (y-axis)
        
        Screen('Drawtextures',stim.displayParams.window,stim.probetexture,           [],stim.rectprobe           );
        Screen('Drawtextures',stim.displayParams.window,stim.probetexture_photodiode,[],stim.rectprobe_photodiode);
        
        Screen('BlendFunction',stim.displayParams.window,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
        stim.fixPoint.color = stim.FPColor;
        
        
        %% Draw fixation point
        
        Screen('gluDisk', stim.displayParams.window, stim.fixPoint.color, stim.fixPoint.x , stim.fixPoint.y ,stim.fixPoint.sizePix );
      
        %% Flip the screen to project things on the screen
        
        lastFlipTime     = Screen('Flip',stim.displayParams.window,lastFlipTime);% + (stim.frameMultiplier-1/2)*stim.displayParams.flipInterval);
  
        
%       Screen('AddFrameToMovie', stim.displayParams.window , CenterRect([0 0 1920 1080], Screen('Rect',stim.displayParams.window)))
        
        
        %% Events after flip: For troughs and peaks of the photodiode stimulus
        
        if photodiode_value == photodiode_minimum    % Black, trough
%         io64(ioObj,address,100);

              WaitSecs(0.001);
%         io64(ioObj,address,0);
        end
        
        if photodiode_value == photodiode_maximum  % White, peak
%         io64(ioObj,address,150);

              WaitSecs(0.001);
%         io64(ioObj,address,0);
        end
        

        %%
        
        test(stim.frameNumber+(irun-1)*stim.nframes) = stim.frameNumber+(irun-1)*stim.nframes;
        all_frames{stim.frameNumber+(irun-1)*stim.nframes} = stim.rectprobe;
        

        stim.frameNumber = stim.frameNumber + 1;
       
       
        Screen('Close', [stim.probetexture           ]);    % get rid of unneeded textures
        Screen('Close', [stim.probetexture_photodiode]);    % get rid of unneeded textures
        
        photodiode_value = photodiode_value + increase_decrease;
        
        
        
        
        
        

end



Priority(0);%drop priority back to normal
ShowCursor


% Screen('FinalizeMovie', movie);





Screen('CloseAll')
clear mex