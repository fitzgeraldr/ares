% Fly Olympiad Phototaxis Assay Rig 1
% v3.0
% JGrid Integration function
%
% Created by Lakshmi Ramasamy, PhD & Kristin Branson, PhD
% Version: 3.0
% Date last modified: April 5th 2011
% The code was modified to integrate JGrid metadata tool on to the Box GUI

function IntegrateJGrid()
global gui h handles;
% GUI control for advanced vs basic mode
%Advance/Basic xml tree gui
h.uimodeselect=uibuttongroup('units','normalized', 'position',[0.87 0.02 0.1 .1],'title','Select Mode','fontweight','bold','backgroundcolor',get(gui.fig,'color'), 'SelectionChangeFcn', {@(x,y) SelectMode});
h.uibasic = uicontrol('style','radiobutton','unit','normalized','parent',h.uimodeselect,'position',[0 0 1 0.5],...
    'horizontalalignment','left','backgroundcolor','w', 'string', 'Basic');
h.uiadvance = uicontrol('style','radiobutton','unit','normalized','parent',h.uimodeselect,'position',[0 0.5 1 0.5],...
    'horizontalalignment','left','backgroundcolor','w', 'string', 'Advance');
set(h.uibasic, 'value', 1);
set(h.uiadvance, 'value', 0);
handles.mode = 'basic';
% KB: set constants
handles.ntubes = 6;
handles.rearing_protocols = {'RP_Olympiad_v001p0.xlsx', 'RP_Olympiad_v002p0.xlsx', 'RP_Olympiad_v003p0.xlsx', 'RP_Olympiad_v003p1.xlsx', 'RP_Olympiad_v003p2.xlsx', 'RP_Olympiad_v004p0.xlsx', 'RP_Olympiad_v005p0.xlsx', 'RP_Olympiad_v006p0.xlsx', 'RP_Olympiad_v006p1.xlsx', 'RP_Olympiad_v007p0.xlsx', 'RP_Olympiad_v008p0.xlsx', 'RP_Olympiad_v008p1.xlsx', 'RP_Olympiad_v009p0.xlsx'};
handles.genders = {'m','f','b','x'};
for tube = 1:handles.ntubes,
    set(gui.tube(tube).Rearing,'String',handles.rearing_protocols);
    set(gui.tube(tube).Gender,'String',handles.genders);
end
% KB: changed this to _last.xml so that we can save the last values
handles.defaultsTreeFileName = 'TheBoxDefaultXmlFile_last.xml';
% KB: effector lookup table
handles.effector_abbrs = struct('UAS_Shi_ts1_3_0001','shi',...
    'UAS_TNT_2_0003','tnt',...
    'UAS_dTrpA1_2_0002','trp',...
    'DL_UAS_GAL80ts_Kir21_23_0010','Kir21DL'); % added DLKir2.1
% WR: control names list 20110726
handles.controlLineNames = {'pBDPGAL4U','attp2','EXT_DL'};
% create the XML metadata property grid
% TODO: position hardcoded
handles.pgrid = PropertyGrid(gui.fig,'Units','Normalized','Position', [0.67 0.25 .32 0.75]);
% KB: add callback whenever any property is changed
handles.pgrid.setPropertyChangeCallback(@pgridPropertyChangeCallback)
% KB: moved code to a function so that it could be called at the end of experiment
InitializeJGrid();
% propagate uicontrols:
% note: positions are hardcoded, won't work for ntubes ~= 6
uicontrol(gui.fig, 'style','text','units','normalized', 'position',[0.67 0.22 0.06 .02],'string','Copy From:','fontweight','bold','fontsize',9);
h.g1 = uibuttongroup(gui.fig, 'position', [0.67 0.02 0.08 .2]);
% KB: made uis, uos arrays
h.uis = nan(1,handles.ntubes);
for i = 1:handles.ntubes,
    h.uis(i) = uicontrol('parent', h.g1, 'position', [4 110-20*(i-1) 60 15], 'style', 'radiobutton', 'string', sprintf('Tube%d',i));
end
% KB: initialize outputs to checked, as usually we will propagate to all
% tubes
uicontrol(gui.fig, 'style','text','units','normalized', 'position',[0.77 0.22 0.06 .02],'string','Copy To:','fontweight','bold','fontsize',9);
h.g2 = uibuttongroup(gui.fig, 'position', [0.77 0.02 0.08 .2]);
h.uos = nan(1,handles.ntubes);
for i = 1:handles.ntubes,
    h.uos(i) = uicontrol('parent', h.g2, 'position', [4 110-20*(i-1) 60 15], 'style', 'checkbox', 'string', sprintf('Tube%d',i),'value',1);
end
h.uiprop = uicontrol(gui.fig, 'style','pushbutton','units','normalized', 'position',[0.87 0.17 0.1 .05],'string','Propagate','fontweight','bold','fontsize',9,'Callback', {@(x,y) Propagate});
%Made "Save XML as" button invisible
h.uisave = uicontrol(gui.fig, 'style','pushbutton','units','normalized', 'position',[0.87 0.12 0.1 .05],'string','Save XML as ...','fontweight','bold','fontsize',9, 'Callback', {@(x,y) SaveMetadataXML}, 'visible', 'off');

function SaveMetadataXML()
global handles;
disp('save metadata');
saveDialogName = 'Save metadata to XML file';
[fileName, pathName, ~] =  uiputfile('metadata_test_write.xml', saveDialogName);
if ~fileName == 0
    fileName = [pathName,fileName];
    metaDataTree = createXMLMetaData(handles.defaultsTree);
    metaDataTree.write(fileName);
end

function Propagate()
global h handles;
set(h.uiprop, 'enable', 'off');

% KB: made this into looping code
% get input tube
for tube = 1:handles.ntubes,
    if get(h.uis(tube),'value'),
        TubeNo = tube;
        break;
    end
end
% get output tube(s)
isout = false(1,handles.ntubes);
for tube = 1:handles.ntubes,
    isout(tube) = get(h.uos(tube),'value');
end
% KB: use recursion to propagate
% input session node
pathString1 = sprintf('session_%d',TubeNo);
n1 = handles.defaultsTree.getNodeByPathString(pathString1);
% for each output session node
for i = find(isout),
    % path to output session node
    pathString2 = sprintf('session_%d',i);
    % output session node
    n2 = handles.defaultsTree.getNodeByPathString(pathString2);
    % copy everything from n1 to n2: recursiveCopy function copied from
    % basicMetaDataDlg
    recursiveCopy(n1,n2,handles.mode,handles.pgrid);
end
set(h.uiprop, 'enable', 'on');


function SelectMode()
global handles h;
if(get(h.uibasic, 'value')),
    handles.mode = 'basic';
else
    handles.mode = 'advanced';
end
% KB: just set mode, not reset tree
handles.pgrid.setMode(handles.mode);
% recursiveCopy(n1,n2,mode,pgrid)
%
% Copy values from defaultsTree node n1 to n2 recursively.
% Only viewable and writable properties are copied.
% Properties are copied in such a way that the property grid will reflect
% these changes.
%
% added by KB
function recursiveCopy(n1,n2,mode,pgrid)

if strcmp(n1.getPathString(),n2.getPathString())
    return;
end
if n1.isLeaf() && strcmpi(n1.getAppearString(mode),'true'),
    pgrid.setValueByPathString(n2.getPathString(),n1.value);
    % update gui elements as well
    pgridPropertyChangeCallback(n2.getPathString);
elseif n1.isContentNode(),
    childNode1 = n1.children(1);
    pgrid.setValueByPathString(n2.getPathString(),childNode1.value);
    % update gui elements as well
    pgridPropertyChangeCallback(n2.getPathString);
else
    chil1 = n1.children();
    chil2 = n2.children();
    for i = 1:length(chil1),
        recursiveCopy(chil1(i),chil2(i),mode,pgrid);
    end
end
