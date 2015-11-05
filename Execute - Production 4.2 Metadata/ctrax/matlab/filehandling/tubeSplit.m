function tubeSplit(movieDir)
profile on
if nargin < 1
    movieDir = uigetdir('C:\Users\labadmin\Documents\bias_fc2_win64-v0.54','Select directory for .ufmf movies');
end

clc

addpath(genpath('C:\Users\labadmin\Desktop\ares\Execute - Production 4.2 Metadata\'));
cd(movieDir); movieList = dir('*.ufmf');
%% Check if dir contains .ufmf movies


%%
for movie = 1:1%size(movieList,1)
    fprintf('\nBeginning movie %d\n',movie);
    cd(movieDir); % Return to main directory
    fclose all; % Ensure previous files are closed
    load('C:\Users\labadmin\Desktop\ares\Execute - Production 4.2 Metadata\FlyTracking\src\ROI_coords_full.mat');
    ufmfin = movieList(movie).name;
    
    % Make new folder for each tube movie
    curr_dir = ['split_' ufmfin];
    mkdir(curr_dir);
    
    % Set framerate so we know when 100 seconds have passed in movie
    framerate = 25;
    params = ReadParams('C:\Users\labadmin\Desktop\ares\Execute - Production 4.2 Metadata\ctrax\matlab\ufmf\ufmf\ufmfCompressionParamsRoian20141204.txt','=');

    %% Preallocate array of tubes
    tube_holder = zeros(tubestruct.height,tubestruct.width,6);

    % Open input video
    [readframe,nframes] = get_readframe_fcn(ufmfin);
    % switch to new directory to contain tube movies
    cd(curr_dir);
    
    nbgupdates = 0; keyi = 1;

    %% Initialize index struct of index structs
    for tube_index = 1:6
        indexes.(['tube', num2str(tube_index)]).frame = struct;
        indexes.(['tube', num2str(tube_index)]).frame.loc = [];
        indexes.(['tube', num2str(tube_index)]).frame.timestamp = [];
        indexes.(['tube', num2str(tube_index)]).keyframe = struct;
        indexes.(['tube', num2str(tube_index)]).keyframe.mean = struct;
        indexes.(['tube', num2str(tube_index)]).keyframe.mean.loc = [];
        indexes.(['tube', num2str(tube_index)]).keyframe.mean.timestamp = [];
    end

    fprintf('Initialization completed\n');
    %% Open 6 .ufmf files for tube movies
    tubestruct.fids = zeros(6,1); tubestruct.indexloclocs = zeros(6,1);
    for a = 1:length(tubestruct.fids)
        tubestruct.fids(a) = fopen(strcat('tube',num2str(a),'.ufmf'),'w');
        % Write template header in each
        tubestruct.indexloclocs(a) = writeUFMFHeader(tubestruct.fids(a),tubestruct.width,tubestruct.height);
    end

    % initialize background
    bghist = zeros([tubestruct.height,tubestruct.width,256],'single');
    [xgrid,ygrid] = meshgrid(1:tubestruct.width,1:tubestruct.height);

    params.UFMFBGKeyFramePeriods = [params.UFMFBGKeyFramePeriodInit,params.UFMFBGKeyFramePeriod];
%     endframe = min(inf,nframes);

    fprintf('Movie files created\nLoading frames\n');
    %% Loop through frames of input movie
    for i = 1:50%nframes
    % Load frame
        [frame,t] = readframe(i);

    % Break into 6 tubes by cropping frame
        for tube = 1:6
            tube_holder(:,:,tube) = imcrop(frame,[xmin ymins(tube) tubestruct.width-1 tubestruct.height-1]);

            if (mod(i,100/(1/framerate))==0) || i == 1  % Write "frame" as keyframe
                if tube==1
                    k_row = length(indexes.(['tube',num2str(tube)]).keyframe.mean.loc)+1;
                end
                % update background?
                    idx = sub2ind([tubestruct.height,tubestruct.width,256],ygrid(:),xgrid(:),reshape(tube_holder(:,:,1),size(ygrid(:),1),1));
                    bghist(idx) = bghist(idx) + 1;
                    nbgupdates = nbgupdates+1;

                    mu = zeros([tubestruct.height,tubestruct.width],'uint8');
                    z = zeros([tubestruct.height,tubestruct.width],'double');
                    thresh = nbgupdates/2;
                    isdone = false([tubestruct.height,tubestruct.width]);
                    for g = 1:256,
                        z = z + bghist(:,:,g);
                        idx = ~isdone & z >= thresh;
                        mu(idx) = g-1;
                        isdone(idx) = true;
                        if all(isdone(:)),
                            break;
                        end
                    end
                    indexes.(['tube',num2str(tube)]).keyframe.mean.timestamp(k_row) = t; 
                    indexes.(['tube',num2str(tube)]).keyframe.mean.loc(k_row) = writeUFMFKeyFrame(tubestruct.fids(tube),mu,t);

%                     lastkeyt = t;
                    keyi = min(keyi+1,numel(params.UFMFBGKeyFramePeriods));
                    if keyi==numel(params.UFMFBGKeyFramePeriods),
                      bghist(:) = 0;
                      nbgupdates = 0;
                    end

            else  % Write as normal frame
                if tube==1
                    f_row = length(indexes.(['tube',num2str(tube)]).frame.loc)+1;
                end
                indexes.(['tube',num2str(tube)]).frame.loc(f_row) = writeUFMFFrame(tubestruct.fids...
                    (tube),uint8(tube_holder(:,:,tube)),t,mu,params);
                indexes.(['tube',num2str(tube)]).frame.timestamp(f_row) = t;
            end
        end
        if (mod(i,50)==0)
            fprintf('Completed frame %.f/%.f\n',i,nframes)
        end
    end
%%
    % Write index to file
    for file = 1:6
        wrapupUFMF(tubestruct.fids(file),indexes.(['tube',num2str(file)]),tubestruct.indexloclocs(file));
        fclose(tubestruct.fids(file));
    end

    fprintf('\nMovie %d completed\n',movie);
end
profile off
profile viewer