% Set framerate so we know when 100 seconds have passed in movie
framerate = 25;
params = ReadParams('C:\Users\labadmin\Desktop\ares\Execute - Production 4.2 Metadata\ctrax\matlab\ufmf\ufmf\ufmfCompressionParamsRoian20141204.txt','=');
% tubestruct.keylocs = []; tubestruct.framelocs = []; % Calc final size and preallocate?

%%
% index = struct;
% index.frame = struct;
% index.frame.loc = [];
% index.frame.timestamp = [];
% index.keyframe = struct;
% index.keyframe.mean = struct;
% index.keyframe.mean.loc = [];
% index.keyframe.mean.timestamp = [];

%% Preallocate array of tubes
load('ROI_coords.mat');
t = zeros(tubestruct.height,tubestruct.width,6);
mu = zeros(tubestruct.height,tubestruct.width);

% Open input video (header)
headerin = ufmf_read_header(ufmfin);

%% Open 6 .ufmf files for tube movies
tubestruct.fids = zeros(6,1); tubestruct.indexloclocs = zeros(6,1);
for a = 1:length(tubestruct.fids)
    tubestruct.fids(a) = fopen(strcat('tube',num2str(a),'.ufmf'),'w');
    % Write template header in each
    tubestruct.indexloclocs(a) = writeUFMFHeader(tubestruct.fids(a),headerin.nr,headerin.nc);
end


%% Loop through frames of input movie
for i = 1:headerin.nframes
% Load frame
    frame = ufmf_read_frame(headerin,i);
    tubestruct.numFrames = tubestruct.numFrames + 1;
% Break into 6 tubes by cropping frame
    for tube = 1:6
        t(:,:,tube) = imcrop(frame,[xmin ymins(tube) tubestruct.width-1 tubestruct.height-1]);
        if (mod(i,100/(1/framerate))==0) || i == 1  % Write "frame" as keyframe
            tubestruct.numKeys = tubestruct.numKeys +1;
            mu = t(:,:,tube); % Set as current keyframe
            tubestruct.keylocs(tube,end+1) = writeUFMFKeyFrame(tubestruct.fids...
                (tube),mu,headerin.timestamps(i));
        else  % Write as normal frame
            tubestruct.framelocs(tube,end+1) = writeUFMFFrame(tubestruct.fids...
                (tube),t(:,:,tube),headerin.timestamps(i),mu,params);
        end
    end
    if (mod(i,50)==0)
        fprintf('Completed frame %.f/%.f\n',i,headerin.nframes)
    end
end

% Write index to file

% Rewrite header