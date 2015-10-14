% added by KB:
% pgridPropertyChangeCallback()
% Function that is called whenever a change is made to the property grid.
% Translates all changes to pgrid = XML metadata to original box gui data
function pgridPropertyChangeCallback(name) 
global handles gui;

% barcode
m = regexp(name,'^session_(?<tube>[0-9]+)\.flies\.cross_barcode$','once','names');
if ~isempty(m),
  tubeIdx = str2double(m.tube);
  barcode = handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.cross_barcode',tubeIdx)).value;
  barcode = str2double(barcode);
  
  if isempty(barcode)
      return;
  end
  
  info = [];
  try
  %    info = FlyFQuery(barcode);
  info = FlyBoyQuery(barcode,'BOX',1);
  catch %#ok<CTCH>
  end
  
  if isempty(info)
      fprintf(2,'Bar code %d not found in database.\n',barcode);
  else
      lineName = info.Line_Name;
      crossDate = info.Date_Crossed;
      flipInterval = [0,0,4,7]; % flip -1, 0, 1, 2
      flipIntIndex = str2double(handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.flip_used',tubeIdx)).value) + 2;
      flipDate = datestr(datenum(info.Date_Crossed,'yyyymmddTHHMMSS') + flipInterval(flipIntIndex),'yyyymmddTHHMMSS');
      effector = info.Effector;
      wishList = info.Set_Number;
      cross_handler = info.Handler_Cross;
      sorting_handler = info.Handler_Sorting;
      if strcmp(info.Sorting_DateTime,'00000000T000000')
          hours_since_sorted = num2str(-1);
      else
          hours_since_sorted = num2str(24*floor(now-datenum(info.Sorting_DateTime,'yyyymmddTHHMMSS')));
      end
      
      % LINE_NAME
      handles.pgrid.setValueByPathString(sprintf('session_%d.flies.line',tubeIdx),lineName);
      pgridPropertyChangeCallback(sprintf('session_%d.flies.line',tubeIdx));
      % CROSS_DATE
      try
          handles.pgrid.setValueByPathString(sprintf('session_%d.flies.cross_date',tubeIdx),crossDate);
          pgridPropertyChangeCallback(sprintf('session_%d.flies.cross_date',tubeIdx));
      catch %#ok<CTCH>
          fprintf(2,sprintf('Cross date ''%s'' for bar code %d is out of valid range.\n',crossDate,barcode));
      end
      % FLIP_DATE
      handles.pgrid.setValueByPathString(sprintf('session_%d.flies.flip_date',tubeIdx),flipDate);
      pgridPropertyChangeCallback(sprintf('session_%d.flies.flip_date',tubeIdx));
      % EFFECTOR
      handles.pgrid.setValueByPathString(sprintf('session_%d.flies.effector',tubeIdx),effector);
      pgridPropertyChangeCallback(sprintf('session_%d.flies.effector',tubeIdx));
      % WISH_LIST
      handles.pgrid.setValueByPathString(sprintf('session_%d.flies.wish_list',tubeIdx),wishList);
      pgridPropertyChangeCallback(sprintf('session_%d.flies.wish_list',tubeIdx));
      % HANDLER_CROSS
      handles.pgrid.setValueByPathString(sprintf('session_%d.flies.handling.handler_cross',tubeIdx),cross_handler);
      pgridPropertyChangeCallback(sprintf('session_%d.flies.handling.handler_cross',tubeIdx));
      % HANDLER_SORTING
      handles.pgrid.setValueByPathString(sprintf('session_%d.flies.handling.handler_sorting',tubeIdx),sorting_handler);
      pgridPropertyChangeCallback(sprintf('session_%d.flies.handling.handler_sorting',tubeIdx));
      % SORTING_DATETIME
      handles.pgrid.setValueByPathString(sprintf('session_%d.flies.handling.hours_sorted',tubeIdx),hours_since_sorted);
      pgridPropertyChangeCallback(sprintf('session_%d.flies.handling.hours_sorted',tubeIdx));
      
      if ismember(lineName,handles.controlLineNames),
          handles.pgrid.setValueByPathString('screen_reason','control');
          pgridPropertyChangeCallback('screen_reason');
      end

  end
end

% if this is line or effector, then 
% regenerate genotype
% set experiment name
m = regexp(name,'^session_(?<tube>[0-9]+)\.flies\.(line|effector)$','once','names');
if ~isempty(m),
  tube = str2double(m.tube);
  resetGenotype(tube);
  setExperimentName();
end

% genotype changed?
m = regexp(name,'^session_(?<tube>[0-9]+)\.flies\.(line|effector|genotype).*$','once','names');
if ~isempty(m),
  tube = str2double(m.tube);
  % I don't know why this needs four entries
  x = repmat({'n/a'},[1,4]);
  genotype = handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.genotype.content',tube)).value;
  x{1} = genotype;
  set(gui.tube(tube).Genotype,'string', x);
  set(gui.tube(tube).Genotype,'value',1);
  return;
end

% box name set? then reset experiment
m = regexp(name,'^apparatus\.box.*$','once');
if ~isempty(m),
    setExperimentName();
end

% technical notes?
m = regexp(name,'^notes_technical.*$','once');
if ~isempty(m),
  notes_technical = handles.defaultsTree.getNodeByPathString('notes_technical.content').value;
  set(gui.userNotesT,'string',notes_technical);
  return;
end

% behavioral notes?
m = regexp(name,'^notes_behavioral.*$','once');
if ~isempty(m),
  notes_behavioral = handles.defaultsTree.getNodeByPathString('notes_behavioral.content').value;
  set(gui.userNotesB,'string',notes_behavioral);
  return;
end

% gender?
m = regexp(name,'^session_(?<tube>[0-9]+)\.flies\.gender$','once','names');
if ~isempty(m),
  tube = str2double(m.tube);
  gender = handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.gender',tube)).value;
  genderidx = find(strcmp(gender,handles.genders),1);
  set(gui.tube(tube).Gender,'value',genderidx);
  return;
end

% rearing condition?
m = regexp(name,'^session_(?<tube>[0-9]+)\.flies\.rearing\.rearing_protocol$','once','names');
if ~isempty(m),
  tube = str2double(m.tube);
  rearing_protocol = handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.rearing.rearing_protocol',tube)).value;
  rearingidx = find(strcmp(rearing_protocol,handles.rearing_protocols),1);
  %set(gui.tube(tube).Rearing,'string', handles.rearing_protocols);
  set(gui.tube(tube).Rearing,'value', rearingidx); 
  return;
end

% cross date -> DOB?
m = regexp(name,'^session_(?<tube>[0-9]+)\.flies\.cross_date$','once','names');
if ~isempty(m),
  tube = str2double(m.tube);
  CrossDate = handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.cross_date',tube)).value;
  Clk = datenum(CrossDate,'yyyymmddTHHMMSS');
  Clk = addtodate(Clk, 14, 'day');
  Clk = datevec(Clk);
  DOB = datestr(Clk,'mm/dd/yyyy');
  set(gui.tube(tube).DOB,'string',DOB);
end

% num_flies?
m = regexp(name,'^session_(?<tube>[0-9]+)\.flies\.num_flies$','once','names');
if ~isempty(m),
  tube = str2double(m.tube);
  n = handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.num_flies',tube)).value;
  set(gui.tube(tube).n,'string',n);
  return;
end

% num_flies_dead?
m = regexp(name,'^session_(?<tube>[0-9]+)\.flies\.num_flies_dead$','once','names');
if ~isempty(m),
  tube = str2double(m.tube);
  n_dead = handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.num_flies_dead',tube)).value;
  set(gui.tube(tube).n_dead,'string', n_dead);
  return;
end

% hours_starved?
m = regexp(name,'^session_(?<tube>[0-9]+)\.flies\.handling\.hours_starved$','once','names');
if ~isempty(m),
  tube = str2double(m.tube);
  Starved = handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.handling.hours_starved',tube)).value;
  set(gui.tube(tube).Starved,'string', Starved);
  return;
end


% added by KB:
% resetGenotype(tube)
% generate and set the genotype in the pgrid from the line name and
% effector
function resetGenotype(tube)
global handles;
genotype = generateGenotype(tube);
handles.pgrid.setValueByPathString(sprintf('session_%d.flies.genotype',tube),genotype);

% added by KB:
% generateGenotype(tube)
% generate and the genotype from the line name and effector.
function genotype = generateGenotype(tube)
global handles;
linename = handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.line',tube)).value;
effector = handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.effector',tube)).value;
genotype = sprintf('%s & %s',linename,effector);

function s = generateExperimentName()
global handles gui;
tube = 1;
linename = handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.line',tube)).value;
effector = handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.effector',tube)).value;
if ~isfield(gui,'boxName'),
    box = 'UNKNOWN';
else
    box = gui.boxName;
end
if ~isfield(handles.effector_abbrs,effector)
  warning('Could not find effector %s in abbr table. Using full name.',effector); %#ok<WNTAG>
  effector_abbr = effector;
else
  effector_abbr = handles.effector_abbrs.(effector);
end
s = sprintf('%s_%s_%s',linename,effector_abbr,box);

function setExperimentName()

global gui;
s = generateExperimentName();
set(gui.ExpName, 'string', s);