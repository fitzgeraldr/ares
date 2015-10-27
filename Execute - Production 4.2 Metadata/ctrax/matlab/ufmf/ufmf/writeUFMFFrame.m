% loc = writeUFMFFrame(fid,im,timestamp,mu,params)
%
% Write a compressed version of the frame 'im' to the file 'fid'. 
%
% Background subtraction is performed using the function backsub. The
% foreground pixels are then written to file using box-based sparse matrix
% format.
%
% Note: Video is written sideways because Matlab is row-major, everything
% else is column-major, so we swap x and y when writing. 
%
% Inputs:
% fid: File identifier to which to write the frame
% im: Current frame.
% timestamp: Current timestamp.
% mu: Background model.
% params: Background subtraction parameters
%
% Outputs:
% loc: Location in file of the start of this frame.
%
% Frame format written to file
% 
% 1 (chunk type)                       uchar
% timestamp                            double
% number of boxes/points               ushort
% 
% for box-based compression:
%
% bounding box 1:
%   xmin_1                             ushort
%   ymin_1                             ushort
%   width_1                            ushort
%   height_1                           ushort
% pixel values 1                       dtype x width_1 x height_1 x ncolors
%
% ...
% bounding box n:
%   xmin_n                             ushort
%   ymin_n                             ushort
%   width_n                            ushort
%   height_n                           ushort
% pixel values n                       dtype x width_n x height_n x ncolors
% (iterate over columns in sideways im,
%  followed by rows,
%  followed by colors)
%
% for sparse-matrix compression:
% 
% xmin_1                               ushort
% ...
% xmin_n                               ushort
% ymin_1                               ushort
% ...
% ymin_n                               ushort
%
% pixel 1, color 1                     dtype
% ...
% pixel 1, color ncolors               dtype
%...
% pixel n, color 1                     dtype
% ...
% pixel n, color ncolors               dtype

function [loc,bb,isfore] = writeUFMFFrame(fid,im,timestamp,mu,params)

FRAME_CHUNK = 1;

% perform background subtraction
[bb,isfore] = backsub(im,mu,params);
ncc = size(bb,1);

% get location of this frame
loc = ftell(fid);

% write chunk type: 1
fwrite(fid,FRAME_CHUNK,'uchar');
% write timestamp: 8
fwrite(fid,timestamp,'double');
% write number of points: 2
fwrite(fid,ncc,'uint32');

dtype = class(im);
for j = 1:ncc,
  % images are sideways: swap x and y, width and height
  % bb(j,1) = xmin
  % bb(j,2) = ymin
  % bb(j,3) = width
  % bb(j,4) = height
  fwrite(fid,[bb(j,[2,1])-.5,bb(j,[4,3])],'ushort');
  tmp = im(bb(j,2)+.5:bb(j,2)+bb(j,4)-.5,bb(j,1)+.5:bb(j,1)+bb(j,3)-.5,:);
  fwrite(fid,permute(tmp,[3,1,2]),dtype);
end
