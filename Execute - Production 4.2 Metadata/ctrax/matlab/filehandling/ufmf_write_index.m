function indexloc = ufmf_write_index(fp,keylocs,framelocs)

DICT_START_CHAR = 'd';
ARRAY_START_CHAR = 'a';

indexloc = ftell(fp);

% write a 'd': 1
fwrite(fp,DICT_START_CHAR,'char');

% write the number of key frames
fwrite(fp,numel(keylocs),'uchar');

%% keyframe writing
for j = 1:numel(keylocs),
  
  % write the length of the key name: 2
  l = fwrite(fp,1,'ushort');
  % write the key name: l
  key = fwrite(fp,'keyframe','*char');
  % write the next letter to tell if it is an array or another dictionary
  chunktype = fwrite(fp,'d','*char');

    % write in the data type
    [matlabclass,bytes_per_element] = dtypechar2matlabclass(dtypechar);
    dtypechar = fwrite(fp,1,'*char');
    
    % write in number of bytes
    l = fwrite(fp,1,'ulong');
    n = l / bytes_per_element;
    if n ~= round(n),
        error('Length in bytes %d is not divisible by bytes per element %d',l,bytes_per_element);
    end

    % write in the index array
    [index.(key),ntrue] = fwrite(fp,n,['*',matlabclass]);


end

%% frame writing
for j = 1:numel(framelocs),
  
  % write the length of the key name: 2
  l = fwrite(fp,1,'ushort');
  % write the key name: l
  key = fwrite(fp,'frame','*char');
  % write the next letter to tell if it is an array or another dictionary
  chunktype = fwrite(fp,'d','*char');

  % write number of keys = 2
  fwrite(fp,2,'ushort');
  
  % write length of key
  fwrite(fp,length('loc'),'ushort');
  % write key
  fwrite(fp,'loc','*char');
  
 % write dtype
 fwrite(fp,'q','*char');
 
 % write number of bytes
 fwrite(fp,8,'ulong'); % 8*indexsize

 
    
    % read in number of bytes
    l = fread(fp,1,'ulong');
    n = l / bytes_per_element;
    if n ~= round(n),
      error('Length in bytes %d is not divisible by bytes per element %d',l,bytes_per_element);
    end
    
    % read in the index array
    [index.(key),ntrue] = fread(fp,n,['*',matlabclass]);
    if ntrue ~= n,
      warning('Could only read %d/%d bytes for array %s of index',n,ntrue,key);
    end
    
  else
    
    error('Error reading dictionary %s. Expected either ''%s'' or ''%s''.',...
      key,DICT_START_CHAR,ARRAY_START_CHAR);
    
  end

end

% write 0 for now
fwrite(fp,0,'uint64'); 
% max box size
fwrite(fp,boxw,'ushort');
fwrite(fp,boxh,'ushort');
% whether it has fixed size patches
fwrite(fp,is_fixed_size,'uchar');
% coding is the encoding of each bit, e.g. MONO8
coding_str_len = length(coding);
fwrite(fp,coding_str_len,'uchar');
fwrite(fp,coding,'char');