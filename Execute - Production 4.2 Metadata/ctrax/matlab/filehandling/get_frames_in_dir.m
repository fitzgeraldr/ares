function frames_per_movie = get_frames_in_dir(avipath,ufmfpath)
% Takes the directories of avi movies and ufmf movies in
% Returns the number of frames in each movie in those directories

startpath = pwd;
addpath(startpath)
cd(avipath);
avimovies = dir('*.avi');

%%
aviframes = cell(numel(avimovies),1);
avimovienames = cell(numel(avimovies),1);
for i = 1:numel(avimovies)
    avimovienames{i} = avimovies(i).name;
    header = VideoReader(avimovienames{i});
    aviframes{i} = header.NumberOfFrames;
    fclose all;
end

%%
cd(ufmfpath);
ufmfmovies = dir('*.ufmf');

ufmfframes = cell(numel(ufmfmovies),1);
ufmfmovienames = cell(numel(ufmfmovies),1);
for j = 1:numel(ufmfmovies)
    ufmfmovienames{j} = ufmfmovies(j).name;
    header = ufmf_read_header(ufmfmovienames{j});
    ufmfframes{j} = header.nframes;
    fclose all;
end

%%
frames_per_movie = {avimovienames;aviframes;ufmfmovienames;ufmfframes};
cd(startpath);

end