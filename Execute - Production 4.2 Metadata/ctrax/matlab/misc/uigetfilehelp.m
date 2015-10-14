function varargout = uigetfilehelp(varargin)

tmp = find(cellfun(@ischar,varargin));
i = tmp(strmatch('helpmsg',varargin(tmp)));
hhelp = nan;
inputs = varargin;
if ~isempty(i),
  inputs(i) = [];
  if i < length(varargin),
    inputs(i) = [];
    hhelp = creategetfileinfodialog(varargin{i+1});
  end
end

varargout = cell(1,nargout);
[varargout{:}] = uigetfile(inputs{:});

delete_dialog = 0;
try
    if ~isnan(hhelp),
        delete_dialog = 1;
    end
catch
    delete_dialog = 1;
end
if delete_dialog
  deletefileinfodialog(hhelp);
end
