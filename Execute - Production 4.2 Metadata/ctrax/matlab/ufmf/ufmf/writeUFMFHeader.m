% indexlocloc = writeUFMFHeader(fid,nr,nc)
% 
% Writes header info at the start of the UFMF file. 
% Inputs:
% fid: File identifier to which to write header.
% nr, nc: Image size.
%

function indexlocloc = writeUFMFHeader(fid,nr,nc)

version = 4;

% grayscale as MONO8
coding = 'MONO8';

% ufmf: 4
fwrite(fid,'ufmf','schar');
% version: 4
fwrite(fid,version,'uint');
% index location: 0 for now: 8
indexlocloc = ftell(fid);
fwrite(fid,0,'uint64');

% images are sideways: swap width and height
% max width: 2
fwrite(fid,nr,'ushort');
% max height: 2
fwrite(fid,nc,'ushort');
% whether it is fixed size patches: 1
fwrite(fid,0,'uchar');
% raw coding string length: 1
fwrite(fid,length(coding),'uchar');
% coding: length(coding)
fwrite(fid,coding);
