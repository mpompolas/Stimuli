%% Duration of the experiment and dataset to load

Screen('Preference', 'SkipSyncTests', 1);







duration = 1   ;  % duration in minutes 

dataset = {'img_noPhotodiode.mat' 'img_low_contrast.mat' 'img_fovea.mat' 'img_periphery.mat'};

iexperiment = 1; % Choose which of the above datasets is going to be used

% Events will be based on the number of iexperiment: 
% 1st:  1  2  3 
% 2nd: 11 12 13
% 3rd: 21 22 23
% 4th: 31 32 33
 
%%
[window, screenRect] = Screen('OpenWindow',2,[0 0 0 0]); %Screen('OpenWindow',testscreen, [0 0 0]);% [0 0 500 500]);%open a window for stimulus display

%% INITIALIZE THE LOW_LATENCY PARALLEL PORT DRIVER

% ioObj   = io64;%create a parallel port handle
% status  = io64(ioObj);%if this returns '0' the port driver is loaded & ready
% address = hex2dec('D010');%'378' is the default address of LPT1 in hex

%% Load necessary files



dot_radius = 6; % In pixels


squares_resolution = [1280,1024]; % DONT CHANGE THIS - IT WILL AFFECT THE STRETCH OF THE SQUAREBOARD






load(dataset{iexperiment});
im_checker      = img;
im_checker_inv  = img_inv;
grey_background = ones(squares_resolution(1),squares_resolution(2),'uint8')*127;
photo_square_left  = ones(20,20)*255;
photo_square_right = zeros(20,20);


%% Make the variables needed for the files loaded

checkRect       = CenterRect(SetRect(0,0,squares_resolution(1),squares_resolution(2)),screenRect); % defines the size and position of the image: 1,2 inputs are for position relative to the center of the screen
checkRect_inv   = CenterRect(SetRect(0,0,squares_resolution(1),squares_resolution(2)),screenRect); % 3,4 are how big in each axis the image will expand
grey_size_left  = SetRect(0,0,screenRect(3)/2,screenRect(4));  
grey_size_right = SetRect(screenRect(3)/2,0,screenRect(3),screenRect(4));  
grey_size       = SetRect(0,0,screenRect(3),screenRect(4));  
photodiode      = SetRect(screenRect(3)-size(photo_square_left,1),screenRect(4)-size(photo_square_left,2),screenRect(3),screenRect(4));


texture_check            = Screen('MakeTexture', window, im_checker     ); 
texture_check_inv        = Screen('MakeTexture', window, im_checker_inv ); 
texture_grey             = Screen('MakeTexture', window, grey_background);
texture_photodiode_left  = Screen('MakeTexture', window, photo_square_left);
texture_photodiode_right = Screen('MakeTexture', window, photo_square_right);


%% Increase priority on CPU for smooth execution

priorityLevel=MaxPriority(window);
Priority(priorityLevel);     % raise priority for stimulus presentation   

%% Start the stimulus


% movie = Screen('CreateMovie', stim.displayParams.window, 'MyTestMovie.mp4', 1920, 1080 , 10);



HideCursor
time = clock;
i=2;
while etime(clock,time) < duration*60
    i=i+1; % will be used for separation of odd-even trials
    
    % Draw fixation point on grey background
    Screen('DrawTexture',window,texture_grey,[],grey_size);
    Screen('gluDisk', window, [255,0,0], screenRect(3)/2 , screenRect(4)/2 ,dot_radius);
    Screen(window,'Flip');
    
%     for i = 1:10
%       Screen('AddFrameToMovie', stim.displayParams.window , CenterRect([0 0 1920 1080], Screen('Rect',stim.displayParams.window)))
%     end
    %         io64(ioObj,address,10*(iexperiment-1)+1);
    WaitSecs(1);
    %         io64(ioObj,address,0);


    % Draw checker and checker_inv in turns
    if mod(i,2)==0
        Screen('DrawTexture',window,texture_grey,[],grey_size);
        Screen('DrawTexture',window,texture_check,[],checkRect);
        Screen('DrawTexture',window,texture_grey,[],grey_size_left);
        Screen('gluDisk', window, [255,0,0], screenRect(3)/2 , screenRect(4)/2 ,dot_radius);
        Screen('DrawTexture',window,texture_photodiode_left,[],photodiode);

        
        
        %         io64(ioObj,address,10*(iexperiment-1)+2);
        Screen(window,'Flip');
        %         io64(ioObj,address,0);
%                   Screen('AddFrameToMovie', stim.displayParams.window , CenterRect([0 0 1920 1080], Screen('Rect',stim.displayParams.window)))

    else 
        Screen('DrawTexture',window,texture_grey,[],grey_size);
        Screen('DrawTexture',window,texture_check_inv,[],checkRect_inv);
        Screen('DrawTexture',window,texture_grey,[],grey_size_right);
        Screen('gluDisk', window, [255,0,0], screenRect(3)/2 , screenRect(4)/2 ,dot_radius);
        Screen('DrawTexture',window,texture_photodiode_right,[],photodiode);

        %         io64(ioObj,address,10*(iexperiment-1)+3);
        Screen(window,'Flip');
        %         io64(ioObj,address,0);
%           Screen('AddFrameToMovie', stim.displayParams.window , CenterRect([0 0 1920 1080], Screen('Rect',stim.displayParams.window)))

    end
    
    
    
    WaitSecs(.1); 
    



end
%     Screen('Close' , texture_check);
%     Screen('Close' , texture_check_inv);
%     Screen('Close' , texture_grey);
%     Screen('Close' , texture_photodiode_left);
%     Screen('Close' , texture_photodiode_right);
%    Screen('FinalizeMovie', movie);
   
Screen('CloseAll');

Priority(0);%drop priority back to normal

ShowCursor
