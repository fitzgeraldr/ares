function masktubes_bas(filename)

dims = cell(6,1);
for i = 1:6
    dims{i} = [25 520 10+(80*(i-1)) 50+(80*(i-1))];
end

vid = VideoReader(filename);
frame = read(vid,1); fr = im2double(frame);

imsize = [vid.Height vid.Width];

rois = makerois(dims,imsize);

for i = 1:6
    subplot(3,2,i); imshow(rois{i}.*fr);
end