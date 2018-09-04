clear

Screen('Preference', 'SkipSyncTests', 0);

%% Important Variables

experiment_time = 1; % In minutes

% Projector
resolutionWidthPix  = 1280; % Resolution of the projector
resolutionHeightPix = 1024;


photodiode_size     = 10; % Size of the side of the square probe. IN DEGREES
y_axis_displacement = 1;
probeColor      = [255 255 255] ; % Color of probes. White
%% Transform everything to degrees
PixPerDeg = 20; % THIS NUMBER IS NOT ACCURATE FOR THE DEPTHQ PROJECTOR

photodiode_size           = photodiode_size * PixPerDeg; 
y_axis_displacement = y_axis_displacement * PixPerDeg;

%% Probes and fixation location centers (3 probes)

photodiode.x = resolutionWidthPix - photodiode_size/2;
photodiode.y = resolutionHeightPix - photodiode_size/2;

%% Initiate Screen

[window, screenRect]=Screen('OpenWindow',1,[0 0 0 0]);
ifi = Screen('GetFlipInterval', window);
FrameRate = 360;%1/ifi; % This is for the DepthQ


%% Increase priority on CPU for smooth execution

priorityLevel=MaxPriority(window);
Priority(priorityLevel);  % raise priority for stimulus presentation   

HideCursor
          
% And for the photodiode that will indicate the different conditions 

photodiode_textures = [];
for intensity = 1:255
    photodiode_textures = [photodiode_textures Screen('MakeTexture',window,intensity)];
end

photodiode = CenterRectOnPoint([0 0 photodiode_size photodiode_size],photodiode.x,photodiode.y);


%% Project stimulus
% There are 3 probes that flicker in different frequencies
% I will use 3 different timers that have to be reset when they expire
tic
experiment_start = toc;
now = toc;

lastFlipTime = 0;
selected_texture = 1;
add_or_subtract = 1;

while now-experiment_start < experiment_time * 60
    now = toc;
    Screen('Drawtextures',window,photodiode_textures(selected_texture),[],photodiode);
    lastFlipTime = Screen('Flip',window,lastFlipTime+ifi/2);   
    selected_texture = selected_texture + add_or_subtract
    if selected_texture>254
        add_or_subtract = -1;
    elseif selected_texture==1
        add_or_subtract = 1;
    end
end

%%
Screen('CloseAll')
Priority(0);%drop priority back to normal
ShowCursor
