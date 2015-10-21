function  res = isufmf(inputFile)

%% determine if movie is a ufmf

dots = find(inputFile ==  '.');
if( numel(dots) == 0 )
    extension = '---';
else
    last_dot = dots(end);
    extension = inputFile(last_dot+1:end);
end

if( strcmp(extension,'ufmf') )
    res = 1;
else
    res = 0;
end
