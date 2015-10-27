% params = ReadParams(filename,delimiter)
function params = ReadParams(filename,delimiter)

if nargin < 2,
  delimiter = ',';
end

params = struct;
fid = fopen(filename,'r');
if fid < 0,
  error('Could not open parameter file %s for reading',filename);
end
while true,
  s = fgetl(fid);
  
  % end of file
  if ~ischar(s), break; end
  
  % comments
  if isempty(s) || ~isempty(regexp(s,'^\s*$','once')) || ...
        ~isempty(regexp(s,'^\s*#','once')),
    continue;
  end
  
  % split at first ,
  m = regexp(s,delimiter,'split','once');
  m{1} = strtrim(m{1});
  m{2} = strtrim(m{2});
  try
    name = m{1};
    if isempty(m{2}),
      val = {};
    else
      valcell = regexp(m{2},',','split');
      val = str2double(valcell);
      if any(isnan(val)),
        if numel(valcell) == 1,
          val = valcell{1};
        else
          val = valcell;
        end
      end
    end
    params.(name) = val;
  catch ME,
    warning('Unable to parse parameter line\n%s\nof %s:\n',s, ...
            filename,getReport(ME));
    continue;
  end

end

fclose(fid);