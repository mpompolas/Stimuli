

a = load() % Morlet TF
photodiode = load() % Imported signals


%%
figure(1);




for isource = 1:139

    min_freq = 30;
    max_freq = 70;

    [~,bin]=histc([min_freq, max_freq],a.Freqs);

    subplot(2,1,1);
    imagesc(a.Time, a.Freqs(bin(1):bin(2)), squeeze(a.TF(isource,:,bin(1):bin(2)))'); set(gca,'YDir','normal'); colormap jet; 
    set(gca, 'CLim', [min(min(squeeze(a.TF(isource,:,bin(1):bin(2))))), max(max(squeeze(a.TF(isource,:,bin(1):bin(2)))))]);
    title({['Stimulation at 25 Hz' ]; ['V1 Source: ' num2str(isource)]})
    xlabel 'Time (sec)'
    ylabel 'Frequency (Hz)'

    subplot(2,1,2);
    plot(photodiode.Time, photodiode.F(309,:));
    title 'Photodiode stimulation'
    xlabel 'Time (sec)'
    ylabel 'Amplitude (V)'
    
    pause

end

% Left V1 sources (Retinotopy scout) that show frequency tagging at 36 Hz.

% 3 4 6 8 16 18 19 20 21 24 31 35 37 44 50 54 55 57 62 79 83 93 94 97 104
% 108 113 120 123 139


% Left V1 sources (Retinotopy scout) that show frequency tagging at 25.7 Hz.

% 1!! 2 4 5 6 8 9 10 11 13 15 16:22 24 27:29 31:34 45 50 56 68 79 80 83
% 93:94 96 104 108 113 120 123 125 133
% 38, 39 44 46 47 57 62 63 64  69:71 78 90 92 95 97 109 shows BOTH 25 AND 50









%% 
figure(2);
plot(depthq.Freqs, squeeze(depthq.TF(309,:,:)))
xlabel 'Frequency (Hz)'
ylabel 'Spectral Density'
title 'Photodiode Power - Flickering at 25.7 Hz'
grid on








%%


signal = a.TF(1,:,26);
figure(3); subplot(2,1,1);plot(a.Time, signal);
subplot(2,1,2); plot(a.Time, -photodiode.F(309,:),'r')



envelope = abs(hilbert(signal));
figure(4);
subplot(2,1,1);plot(a.Time, envelope);
subplot(2,1,2); plot(a.Time, -photodiode.F(309,:),'r')










%% average photodiode signals
photodiode_avg = load('D:/brainstorm_db/Frequency_Tagging/data/Me_3_Probes_DepthQ/bestsubject_saccades_20170216_07/data_1_average_170221_1601.mat');
tf_avg = load('D:/brainstorm_db/Frequency_Tagging/data/Me_3_Probes_DepthQ/bestsubject_saccades_20170216_07/timefreq_average_170221_1539.mat');

nsources = 139;

r = zeros(nsources, length(tf_avg.Time)*2 - 1);
lags = zeros(nsources, length(tf_avg.Time)*2 - 1);

for isource = 1:nsources
    figure(10);
    plot(photodiode_avg.Time, (photodiode_avg.F(309,:)- mean(photodiode_avg.F(309,:)))./max(photodiode_avg.F(309,:)))
    hold on
    plot(tf_avg.Time, (squeeze(tf_avg.TF(isource,:,12)) - mean(squeeze(tf_avg.TF(isource,:,12))))./max(squeeze(tf_avg.TF(isource,:,12))),'r')
    hold off
    title(['Source: ' num2str(isource)])
    [r(isource,:), lags(isource,:)] = xcorr(-((photodiode_avg.F(309,:)- mean(photodiode_avg.F(309,:)))./max(photodiode_avg.F(309,:))), (squeeze(tf_avg.TF(isource,:,12)) - mean(squeeze(tf_avg.TF(isource,:,12))))./max(squeeze(tf_avg.TF(isource,:,12))));
end





figure(11);
imagesc(tf_avg.Time,1:size(r,1),r)
title ({'Cross correlation of double stimulation frequency V1 TF';'with stimulus'});

[b,c] = max(r,[],2);
figure(12); hist(tf_avg.Time(c-(size(tf_avg.Time,2)-1)/2),250)
title 'Histogram of the peak xcorr lag between the stimulus onset and all the V1 responses in the 2*Fst'
xticks([-1:0.1:1])
xlabel 'Time (sec)'





%% Plot photodiode, eye signal, and the zscore Morlet signals on specific frequencies and remove 

if sum(strfind(a.Comment, 'onset1'))~=0
    photodiode = load('E:/brainstorm_db/Frequency_Tagging/data/Me_3_Probes_20_25_30/bestsubject_saccades_20170306_08/data_saccade_onset1_trial015.mat');
elseif sum(strfind(a.Comment, 'onset2'))~=0
    photodiode = load('E:/brainstorm_db/Frequency_Tagging/data/Me_3_Probes_20_25_30/bestsubject_saccades_20170306_08/data_saccade_onset2_trial015.mat');
else
    disp('The loaded file is not for saccade onset')
    stop
end




h_fig = figure(10);

baseline_start =   -2.5; % seconds
baseline_stop  = -0.5; % seconds

plot_time_min = -1.5; % seconds
plot_time_max = 1.5;
[~, time_plot] = histc([plot_time_min, plot_time_max], a.Time);



frequencies = a.Freqs;

for isource = 1:size(a.TF,1) % Number of total sources in this scout

    [~,bin]=histc(frequencies,a.Freqs);
    [~,baseline] = histc([baseline_start baseline_stop], photodiode.Time);
    
    

    for i = 1:5
        y_max(i) = max((squeeze(a.TF(isource,time_plot(1):time_plot(2),bin(i))) - mean(squeeze(a.TF(isource,baseline(1):baseline(2),bin(i)))))./std(squeeze(a.TF(isource,baseline(1):baseline(2),bin(i)))));
        y_min(i) = min((squeeze(a.TF(isource,time_plot(1):time_plot(2),bin(i))) - mean(squeeze(a.TF(isource,baseline(1):baseline(2),bin(i)))))./std(squeeze(a.TF(isource,baseline(1):baseline(2),bin(i)))));
    end
    
    for i = 1:5
        subplot(4,3,i);
        plot(a.Time(time_plot(1):time_plot(2)), (squeeze(a.TF(isource,time_plot(1):time_plot(2),bin(i))) - mean(squeeze(a.TF(isource,baseline(1):baseline(2),bin(i)))))./std(squeeze(a.TF(isource,baseline(1):baseline(2),bin(i))))); 
        axis([a.Time(time_plot(1)), a.Time(time_plot(2)), y_min(i), y_max(i)])
        xticks([a.Time(time_plot(1)):0.5:a.Time(time_plot(2))])
        grid on
        title({['Morlet at '  num2str(frequencies(i)) ' Hz' ]; char(a.RowNames(isource))})
        xlabel 'Time (sec)'
        ylabel 'Power z-scored'
    end

    subplot(4,3,[7 8 9]);  % PHOTODIODE
    plot(photodiode.Time(time_plot(1):time_plot(2)), photodiode.F(309,time_plot(1):time_plot(2)),'r'); grid on
    title (['Saccade Target Position: ' photodiode.Comment])
    xticks([a.Time(time_plot(1)):0.25:a.Time(time_plot(2))])
    xlabel 'Time (sec)'
    ylabel 'Amplitude (V)'
    
    
    subplot(4,3,[10 11 12]); % EYE
    plot(photodiode.Time(time_plot(1):time_plot(2)), photodiode.F(302,time_plot(1):time_plot(2)),'g'); grid on
    title 'Eye signal'
    xticks([a.Time(time_plot(1)):0.25:a.Time(time_plot(2))])
    xlabel 'Time (sec)'
    ylabel 'Amplitude (V)'
    pause;
        
%     evt.Key=[];
%     while strfind('leftarrowrightarrowuparrowdownarrow' , evt.Key)
%         set(h_fig,'KeyPressFcn',@(h_obj,evt) disp(evt.Key));
%         k = evt.Key;
%         if ~isempty(evt.Key)
%             if evt.Key == 'leftarrow' | evt.Key == 'uparrow'
%                 isource = isource-1;
%             elseif evt.Key == 'rightarrow' | evt.Key == 'downarrow'
%                 isource = isource+1;
%             end
%         end
%     end
%     drawnow;

    
end












