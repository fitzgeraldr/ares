function masktubes_fleacam(filename)

dims = cell(6,1);
for i = 1:6
    dims{i} = [170 1165 83+(150*(i-1)) 196+(150*(i-1))];
end

header = ufmf_read_header(filename);
frame = ufmf_read_frame(header,1); fr = im2double(frame);

imsize = [header.nc header.nr];

rois = makerois(dims,imsize);

for i = 1:6
    subplot(3,2,i); imshow(rois{i}.*fr);
end
end