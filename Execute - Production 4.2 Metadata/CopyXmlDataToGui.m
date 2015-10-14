% Created & modified by Lakshmi Ramasamy, PhD & Kristin Branson, PhD
% Version: 3.0
% Date last modified: April 14th 2011

function CopyXmlDataToGui()
global handles;
% reuse code in pgridPropertyChangeCallback

% fly properties
names = {'line','gender','rearing.rearing_protocol','cross_date','num_flies','num_flies_dead','handling.hours_starved'};
for i = 1:numel(names),
  for tube = 1:handles.ntubes,
    name = sprintf('session_%d.flies.%s',tube,names{i});
    pgridPropertyChangeCallback(name);
  end
end
