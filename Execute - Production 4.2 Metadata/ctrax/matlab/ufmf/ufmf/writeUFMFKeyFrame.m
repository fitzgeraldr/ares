% writeUFMFKeyFrame(fid,mu,timestamp)
%
% Write the current background model mu to the file 'fid'. The
% location of this keyframe is written. 
%
% Note: Video is written sideways because Matlab is row-major, everything
% else is column-major, so we swap x and y when writing. 
%
% Inputs:
% fid: File identifier to which to write the frame
% mu: Current background image.
% timestamp: Current timestamp.
%
% Outputs:
% loc: Location of keyframe in file fid.
%
% Frame format written to file:
%
% 0 (chunk type)                       uchar
% 4 (length of keyframe type)          uchar
% 'mean' (keyframe type)               char x 4
% timestamp                            double
% number of boxes/points               ushort
% dtype ('f' for float, 'B' for uint8) char
% width                                ushort
% height                               ushort
% timestamp                            double
% background mean                      dtype x ncolors x width x height
% (iterate over colors,
%  followed by columns in sideways im,
%  followed by rows)

function loc = writeUFMFKeyFrame(fid,mu,timestamp)

KEYFRAME_CHUNK = 0;
keyframe_type = 'mean';

loc = ftell(fid);

% write the chunk type
fwrite(fid,KEYFRAME_CHUNK,'uchar');
% write the keyframe type
fwrite(fid,length(keyframe_type),'uchar');
fwrite(fid,keyframe_type,'char');

% write the data type
dtype = matlabclass2dtypechar(class(mu));
fwrite(fid,dtype,'char');

% images are sideways: swap width and height
% width, height
fwrite(fid,[size(mu,1),size(mu,2)],'ushort');

% timestamp
fwrite(fid,timestamp,'double');

% write the frame
fwrite(fid,mu,class(mu));
