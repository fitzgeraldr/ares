%

% Open 6 .ufmf files for tube movies
tubes.fids = zeros(6,1); tubes.indexloclocs = zeros(6,1);
for a = 1:length(tubes.fids)
    tubes.fids(a) = fopen(strcat('tube',num2str(a),'.ufmf'),'w');
    % Write template header
    tubes.indexloclocs(a) = writeUFMFHeader(tubes.fids(a),1280,1020);
end

% Open input video (header)
headerin = ufmf_read_header(ufmfin);

% Loop
% Load frame
% Break into 6 tubes with indexing into frame          % start with
                                                       % keyframe writing?
% Write 1st tube "frame" as keyframe to 1st file
% Write 2nd tube "frame" as keyframe to 2nd file
% Etc.
% Load in 2nd frame from input video
% Break down, write tubes to respective files as frames
% If current frame is 100/200/etc. seconds into movie, write as keyframe

% Write index to file

% Rewrite header