clear 
close all; 
clc;

%% vars
dirName = '/Users/stevenbobyn/Documents/MATLAB/MDM/CAP_raw';
outFileNameBase = 'post_processing/cog_assess_post_'; 

% reference parameters
referenceChannels = {'TP9', 'TP10'};
referenceTo = {'ALL'};

% filter parameters
filterLow = 0.1;
filterHigh = 30;
filterOrder = 2;
filterNotch = 60;

% ICA parameters
computeICAActivations = 1;

% epoch markers
% 5: oddball
% 6: oddball control
% 11: Win when got correct 
% 12: Win when got incorrect
% 13: Loss when got incorrect 
% 14: Loss when got correct
markers = {'S 5', 'S 6', 'S 11','S 12','S 13','S 14'};
epochWindow = [-200 800];

% baseline correction
baselineWindow = [-200 0];

% artifact rejection
artifactType = 'Difference';
artifactCriteria = 100;
individualChannelMode = 0;

%% analysis

% get eeg header files
files = dir(fullfile(dirName,'*.vhdr'));

% analyze each file
for k = 1:length(files)
    % file name
    baseFileName = files(k).name;
    % absolute path to file
    fullFileName = fullfile(dirName, baseFileName); 
    
    %% analysis on kth file
    
    % load data
    EEG = doLoadBVData(pathName,fullFileName);
    
    % rereference
    EEG = doRereference(EEG,referenceChannels,referenceTo,channelLocations);
    
    % filter
    EEG = doFilter(EEG,filterLow,filterHigh,filterOrder,filterNotch,EEG.srate);
    
    % ICA
    EEG = doICA(EEG,computeICAActivations);
    
    % remove blinks
    EEG = doRemoveOcularICAComponents(EEG);
    
    % epoch data
    EEG = doSegmentData(EEG,markers,epochWindow);
    
    % baseline correction
    EEG = doBaseline(EEG,baselineWindow);
    
    % find artifacts
    EEG = doArtifactRejection(EEG,artifactType,artifactCriteria);
    
    % remove artifacts from data
    EEG = doRemoveEpochs(EEG,EEG.artifact.badSegments,individualChannelMode);
    

    %% save data

    % get file id
    expr = '[0-9]{1,3}b?';
    id = regexp(baseFileName,expr,'match','once');

    % add id to end of outFileNameBase
    outFileName = strcat(outFileNameBase,id);

    DATA.EEG = EEG;
    save(outFileName,'DATA');
end