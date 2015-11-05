function frames_per_movie = get_frames_in_dir(avipath,ufmfpath)
% Takes the directories of avi movies and ufmf movies in
% Returns the number of frames in each movie in those directories

if nargin < 1
    avipath = uigetdir(pwd,'Select directory for .avi movies');
    ufmfpath = uigetdir(pwd,'Select directory for .ufmf movies');
elseif nargin < 2
    
end

startpath = pwd;
addpath(startpath)
cd(avipath);
avimovies = dir('*.avi');

frames_per_movie = cell(numel(avimovies)+1,4);
frames_per_movie{1,1}='avi movie name';
frames_per_movie{1,2}='frames';
frames_per_movie{1,3}='ufmf movie name';
frames_per_movie{1,4}='frames';
%%
% aviframes = cell(numel(avimovies),1);
% avimovienames = cell(numel(avimovies),1);
for i = 1:numel(avimovies)
    frames_per_movie{i+1,1} = avimovies(i).name;
    header = VideoReader(frames_per_movie{i+1,1});
    frames_per_movie{i+1,2} = header.NumberOfFrames;
    fclose all;
end

%%
cd(ufmfpath);
ufmfmovies = dir('*.ufmf');

% ufmfframes = cell(numel(ufmfmovies),1);
% ufmfmovienames = cell(numel(ufmfmovies),1);
for j = 1:numel(ufmfmovies)
    frames_per_movie{j+1,3} = ufmfmovies(j).name;
    header = ufmf_read_header(frames_per_movie{j+1,3});
    frames_per_movie{j+1,4} = header.nframes;
    fclose all;
end

%% get difference in frames between avi & ufmf
for k = 1:numel(avimovies)
    frame_diff{k,1} = frames_per_movie{k+1,2}-frames_per_movie{k+1,4};
end
frame_diff_mat = cell2mat(frame_diff);

%% get inter-frame interval (IFI)
% figure;
% for p = 1:length(ufmfmovies) % for each movie
%     temp = [];
%     temp_header = ufmf_read_header(ufmfmovies(p).name);
%     for f = 2:frames_per_movie{p+1,4} % for each frame in the movie
%         temp(f,1) = abs(temp_header.timestamps(f)-temp_header.timestamps(f-1));
%     end
%     subplot(numel(ufmfmovies),1,p); plot(1:frames_per_movie{p+1,4},temp);
%     axis([-inf inf 0.0398 0.04011])
% end
% subplot(6,1,1);title('1013test1')

%% frames_per_movie = [{avimovienames;aviframes};{ufmfmovienames;ufmfframes}];
% plot(1:i,frame_diff_mat); title('Difference in frame numbers (.avi-.ufmf)');
% xlabel('Movie Number');ylabel('Difference in frames');
% set(gca,'XTick',1:1:numel(avimovies));set(gca,'YTick',min(frame_diff_mat):1:max(frame_diff_mat));

cd(startpath);
end