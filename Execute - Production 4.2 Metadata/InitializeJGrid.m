function InitializeJGrid()
global handles gui;

hwait = waitbar(0,'Initializing JGrid...');
% read the defaults tree from file. 
handles.defaultsTree = loadXMLDefaultsTree(handles.defaultsTreeFileName);

% set apparatus.id
handles.defaultsTree.setValueByPathString('apparatus.apparatus_id',dec2hex(gui.snum));

% set apparatus.computer
[num CompName]  = system('hostname'); %#ok<ASGLU>
handles.defaultsTree.setValueByPathString('apparatus.computer',CompName);

% set apparatus.box
if isfield(gui,'boxName'),
  handles.defaultsTree.setValueByPathString('apparatus.box',gui.boxName);
end

% sample temperature and humidity data from the precon sensor
out = THSampler('precon', 'COM8');
out.start;
[T H Flag] = out.getData
if(Flag == 1)
    handles.defaultsTree.setValueByPathString('environment.temperature',num2str(T));
    handles.defaultsTree.setValueByPathString('environment.humidity',num2str(H));
else
    handles.defaultsTree.setValueByPathString('environment.temperature','00');
    handles.defaultsTree.setValueByPathString('environment.humidity','00');
end
out.stop;

% set string of gui notes to notes string
set(gui.userNotesB,'String',...
  handles.defaultsTree.getNodeByPathString('notes_behavioral.content').value);
set(gui.userNotesT,'String',...
  handles.defaultsTree.getNodeByPathString('notes_technical.content').value);

%Reset line & effector attributes to editable
for count=1:1:handles.ntubes
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.cross_barcode', count)).attribute.appear_basic = 'true';
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.cross_barcode', count)).attribute.appear_advanced = 'true';
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.line', count)).attribute.appear_basic = 'true';
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.line', count)).attribute.appear_advanced = 'true';
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.effector', count)).attribute.appear_basic = 'true';
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.effector', count)).attribute.appear_advanced = 'true';
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.genotype', count)).attribute.appear_basic = 'true';
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.genotype', count)).attribute.appear_advanced = 'true';
end

% associate defaultsTree with pgrid
handles.pgrid.setDefaultsTree(handles.defaultsTree,handles.mode);
if ishandle(hwait),
    delete(hwait);
end