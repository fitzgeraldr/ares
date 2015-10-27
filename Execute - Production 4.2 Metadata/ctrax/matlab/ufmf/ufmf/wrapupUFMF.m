% indexloc = wrapupUFMF(fid,index,indexlocloc)
%
% Finish writing the UFMF by writing the indices to the file.
% We write the index at the end of the file using subfunction write_dict.
% We store the location of the index in the file at the location stored in
% indexlocloc.
%
function [indexloc] = wrapupUFMF(fid,index,indexlocloc)

INDEX_DICT_CHUNK = 2;

% start of index chunk
fwrite(fid,INDEX_DICT_CHUNK,'uchar');
indexloc = ftell(fid);

% write index
write_dict(fid,index);

fseek(fid,indexlocloc,'bof');
fwrite(fid,indexloc,'uint64');

function write_dict(fid,dict)

keys = fieldnames(dict);

% write a d
fwrite(fid,'d');
% write the number of fields
fwrite(fid,length(keys),'uchar');

for j = 1:length(keys),
  key = keys{j};
  value = dict.(key);
  % write length of key name
  fwrite(fid,length(key),'ushort');
  % write the key
  fwrite(fid,key);
  % if this is a struct, call recursively
  if isstruct(value),
    write_dict(fid,value);
  else
    % write a for array followed by the single char abbr of the class
    dtypechar = matlabclass2dtypechar(class(value));
    fwrite(fid,['a',dtypechar]);
    % write length of array * bytes_per_element
    tmp = whos('value');
    fwrite(fid,tmp.bytes,'ulong');
    % write the array
    fwrite(fid,value,class(value));
  end
end
