function rois = makerois(dims,imsize)

rois = cell(6,1);

for tubenum = 1:6
    rois{tubenum}=makemask(dims{tubenum},imsize);
end

