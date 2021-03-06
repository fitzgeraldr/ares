function trackDir(movieDir,paramFile)
% profile on

%% Setup
if nargin < 2
    paramFile = 'C:\Users\labadmin\Desktop\ares\Execute - Production 4.2 Metadata\FlyTracking\src\params_Olympiad.txt';
end
if nargin < 1
    movieDir = uigetdir('C:\Users\labadmin\Documents\bias_fc2_win64-v0.54','Select directory for .ufmf movies');
end

% make this dynamic
addpath(genpath('C:\Users\labadmin\Desktop\ares\Execute - Production 4.2 Metadata\'));
cd(movieDir); movieList = dir('*.ufmf');

%% Check if dir contains .ufmf movies
if isempty(movieList)
    fprintf('\n\nThis directory has no .ufmf movies\n\nSplitting aborted\n\n');
    return
end

%% Track
for tube = 1:size(movieList,1)
    fprintf('\nBeginning tracking of tube %d\n',tube);
    outputDir = [movieDir filesep sprintf('tube%d_analysis_out',tube)];
    cd(movieDir); % back up to main dir
    mkdir(outputDir); addpath(outputDir);

    fclose all;
    inputFile = movieList(tube).name;
    olympiadTrak(paramFile,inputFile,outputDir);
end

% profile off
% profile viewer
end