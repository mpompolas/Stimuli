clear

Screen('Preference', 'SkipSyncTests', 1);

%% Important Variables

experiment_time = 0.2; % In minutes

% Projector
stim.displayParams.resolutionWidthPix  = 1680; % Resolution of the projector
stim.displayParams.resolutionHeightPix = 1050;

% Probes % THIS NUMBER IS RANDOM
ProbeSize  = 40; % Size of the side of the square probe. IN DEGREES

%% Initiation values !!!!!

stim.probeColor      = [255 255 255] ; % Color of probes. White
stim.FPColor         = [255   0   0] ; % Color of fixation point : Red
stim.backgroundColor = [0 0 0] ; % Gray color on the background

photodiode_size      = 20; % Size of photodiode projected on bottom-right in pixels : 20x20

ProbeSize  =    ProbeSize * 20; % THIS NUMBER IS RANDOM

%% Initiate Screen

[stim.displayParams.window, screenRect]=Screen('OpenWindow',0,[0 0 0 0]);

%% Increase priority on CPU for smooth execution

priorityLevel=MaxPriority(stim.displayParams.window);
Priority(priorityLevel);  % raise priority for stimulus presentation   

HideCursor


%% Get ready
numCheckers = 100; % Number of checkers per side on the probe - NOT READY YET

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
% repeat. This will project on 360 Hz
sequence_1(:,:,1) = checkerboard_tails; % R
sequence_1(:,:,2) = checkerboard_heads; % G
sequence_1(:,:,3) = checkerboard_heads; % B

sequence_2(:,:,1) = checkerboard_heads; % R
sequence_2(:,:,2) = checkerboard_tails; % G
sequence_2(:,:,3) = checkerboard_tails; % B

checker_texture         = Screen('MakeTexture',stim.displayParams.window,sequence_1);
inverse_checker_texture = Screen('MakeTexture',stim.displayParams.window,sequence_2);

% DrawFormattedText(stim.displayParams.window, 'Ready ?',stim.displayParams.resolutionWidthPix/2,stim.displayParams.resolutionHeightPix/2,255*[1 1 1]);
Screen(stim.displayParams.window, 'Flip');
pause(.5)


%% Prepare stimulus
% There are 3 probes that flicker in different frequencies
% I will use 3 different timers that have to be reset when they expire
tic
experiment_start = toc;
now = toc;

while now-experiment_start < experiment_time * 60
    now = toc;
    Screen('DrawTexture', stim.displayParams.window, checker_texture, [], [500-ProbeSize, 500-ProbeSize,500+ProbeSize, 500+ProbeSize],0, [], [], [], [], []);
    Screen('Flip',stim.displayParams.window,0);
    
    Screen('DrawTexture', stim.displayParams.window, inverse_checker_texture, [], [500-ProbeSize, 500-ProbeSize,500+ProbeSize, 500+ProbeSize],0, [], [], [], [], []);
    Screen('Flip',stim.displayParams.window,0);
end


%%
Screen('CloseAll')
Priority(0);%drop priority back to normal
ShowCursor
