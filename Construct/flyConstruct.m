function flyConstruct(varargin)
% Olympiad Experiment Construction Interface
% Fly Olympiad Phototaxis Assay
% v1.0
%
%
% Written by Gus K Lott III, PhD
% Neurobiological Instrumentation Engineer
% Howard Hughes Medical Institute - Janelia Farm Research Campus
% 19700 Helix Dr
% Ashburn, VA 20147
% 571.209.4362
% lottg@janelia.hhmi.org
%
% Vi veri veniversum vivus vici
% 
% (c)2008 Gus Lott
%
% - Fix motor resolution to analog value, not discrete

switch nargin
    case 0
        delete(findobj('tag','gOlympiad')); makegui;
    case 1
        %load a file name passed as a string
end


%%----------------------------------------------------
%Misc Functions
function [ms,err]=parseTime(t)

form=strfind(t,':');
err=0;

switch length(form)
    case 0
        ms=str2double(t);
        if isnan(ms); err=1;
        else ms=round(ms*1000); end
    case 1
        mins=str2double(t(1:(form-1)));
        sec=str2double(t((form+1):end));
        if isnan(mins)|isnan(sec); err=1;
        else ms=round((mins*60+sec)*1000);
        end
    case 2
        hours=str2double(t(1:(form(1)-1)));
        mins=str2double(t((form(1)+1):(form(2)-1)));
        sec=str2double(t((form(2)+1):end));
        if isnan(hours)|isnan(mins)|isnan(sec); err=1;
        else ms=round((hours*60*60+mins*60+sec)*1000);
        end
end
if ms>(2^32); err=1; end

function stepActionTime(obj,event,fig)
gui=get(fig,'userdata');

t=get(gui.ActionTime,'string');
[time,err]=parseTime(t);
if err==1
    errordlg('Invalid Time Value','Time Stamp');
    return;
end

Step=str2double(get(gui.ActionStep,'string'));

tSec=time/1000+Step;
hours=floor(tSec/(60*60));
mins=floor((tSec-hours*60*60)/60);
sec=tSec-hours*60*60-mins*60;

tStr='';
if hours~=0
    tStr=[tStr,num2str(hours),':'];
end
if hours~=0|mins~=0
    tStr=[tStr,sprintf('%02.0f',mins),':'];
end
tStr=[tStr,sprintf('%2.3f',sec)];
set(gui.ActionTime,'string',tStr)

function backupExp(fig)
gui=get(fig,'userdata');
maxUndos=20;
undos=get(gui.undo,'userdata');
if isempty(undos)
    undos{1}=get(gui.SequenceList,'userdata');
else
    undos{end+1}=get(gui.SequenceList,'userdata');
end

if length(undos)>maxUndos
    undos(1)=[];
end
set(gui.undo,'userdata',undos)
if ~isempty(undos)
    set(gui.undo,'enable','on')
end

%reset the state of the experiment back one level
function undoAction(obj,event,fig)
gui=get(fig,'userdata');
undos=get(gui.undo,'userdata');

if isempty(undos); return; end

action=undos{end};

if isempty(action)
    clearSequence('','',fig,0);
else
    mainConstructor(action,gui.SequenceList,1,fig);
end

undos(end)=[];
set(gui.undo,'userdata',undos)
if isempty(undos)
    set(gui.undo,'enable','off')
end

function clearSequence(obj,event,fig,questflg)
gui=get(fig,'userdata');
backupExp(gui.fig)
if questflg
    a=questdlg('Clear Sequence?','Are you Sure?','Yes','No','Yes');
    if ~strcmpi(a,'Yes'); return; end
end

mainConstructor([],gui.SequenceList,0,fig)

function genericCheck(obj,event,fig)
val=str2double(get(obj,'string'));
if isnan(val) 
    set(obj,'string',num2str(get(obj,'userdata')));
    val=get(obj,'userdata');
else
    if val<0||val>255
        set(obj,'string',num2str(get(obj,'userdata')));
        val=get(obj,'userdata');
    else
        set(obj,'userdata',val)
    end
end
val=round(val);
set(obj,'string',num2str(val),'userdata',val)

%File handling
function saveSeq(obj,event,fig)
gui=get(fig,'userdata');

[fname, pname] = uiputfile('*.seq','Enter a Sequence File Name...',...
    get(gui.FileMenu,'userdata'));
if isequal(fname,0) || isequal(pname,0)
   return
end
set(gui.FileMenu,'userdata',pname)

action=get(gui.SequenceList,'userdata');

save(fullfile(pname,fname),'action','-mat');

%Load a saved *.seq file
function loadSeq(obj,event,fig)
gui=get(fig,'userdata');

[fname, pname] = uigetfile('*.seq','Select a Sequence File',...
    get(gui.FileMenu,'userdata'));
if isequal(fname,0) || isequal(pname,0)
   return
end
set(gui.FileMenu,'userdata',pname)

load(fullfile(pname,fname),'-mat')

backupExp(gui.fig)

mainConstructor(action,gui.SequenceList,1,fig);
drawnow

%Save a full experiment w/ experiment struct and patterns
function saveExp(obj,event,fig)
gui=get(fig,'userdata');

[fname, pname] = uiputfile('*.exp','Enter an Experiment File Name...',...
    get(gui.FileMenu,'userdata'));
if isequal(fname,0) || isequal(pname,0)
   return
end
set(gui.FileMenu,'userdata',pname)

experiment=get(gui.SequenceOrder,'userdata');
patterns=gui.PanelPatterns(:,:,2);

save(fullfile(pname,fname),'experiment','patterns','-mat');

function loadExp(obj,event,fig)
gui=get(fig,'userdata');

[fname, pname] = uigetfile('*.exp','Select an Experiment File',...
    get(gui.FileMenu,'userdata'));
if isequal(fname,0) || isequal(pname,0)
   return
end
set(gui.FileMenu,'userdata',pname)

load(fullfile(pname,fname),'-mat')

%Create sequence table entries based on experiment size

s=length(experiment.actionsource);
for i=1:s
    newSeq('','',fig)
end

dat={};
for i=1:s
    dat=cat(1,dat,{experiment.actionlist(i).name,experiment.actionlist(i).T,false,experiment.actionlist(i).Vid});
end
%Select first entry and construct
dat{1,3}=true;
set(gui.SequenceOrder,'Data',dat)
set(gui.SequenceOrder,'userdata',experiment)
set(gui.SequenceName,'string',dat{1,1})
mainConstructor(experiment.actionlist(1).action,gui.SequenceList,1,fig)

%Load patterns
gui.PanelPatterns(:,:,2)=patterns;
pp = gui.PanelPatterns;
pp(:,:,2)=pp(:,:,2)/15;
set(gui.PatternIm,'cdata',pp)
set(gui.fig,'userdata',gui)

y=gui.SelectedPattern;
for i=1:64
    val = gui.PanelPatterns(y,i,2);
    set(gui.PatternEntry(i),'userdata',val,'string',num2str(val))
end


function loadActions(obj,event,fig)
gui=get(fig,'userdata');

[fname, pname] = uigetfile('*.exp','Select an Experiment File (action only load)',...
    get(gui.FileMenu,'userdata'));
if isequal(fname,0) || isequal(pname,0)
   return
end
set(gui.FileMenu,'userdata',pname)

load(fullfile(pname,fname),'-mat')

%Create sequence table entries based on experiment size

s=length(experiment.actionsource);
for i=1:s
    newSeq('','',fig)
end

dat={};
for i=1:s
    dat=cat(1,dat,{experiment.actionlist(i).name,experiment.actionlist(i).T,false,false});
end
%Select first entry and construct
dat{1,3}=true;
set(gui.SequenceName,'string',dat{1,1})
set(gui.SequenceOrder,'Data',dat)
set(gui.SequenceOrder,'userdata',experiment)
mainConstructor(experiment.actionlist(1).action,gui.SequenceList,1,fig)


function loadPatterns(obj,event,fig)
gui=get(fig,'userdata');

[fname, pname] = uigetfile('*.exp','Select an Experiment File (pattern only load)',...
    get(gui.FileMenu,'userdata'));
if isequal(fname,0) || isequal(pname,0)
   return
end
set(gui.FileMenu,'userdata',pname)

load(fullfile(pname,fname),'-mat')

%Load patterns
gui.PanelPatterns(:,:,2)=patterns;
pp = gui.PanelPatterns;
pp(:,:,2)=pp(:,:,2)/15;
set(gui.PatternIm,'cdata',pp)
set(gui.fig,'userdata',gui)

y=gui.SelectedPattern;
for i=1:64
    val = gui.PanelPatterns(y,i,2);
    set(gui.PatternEntry(i),'userdata',val,'string',num2str(val))
end

function ClearAll(obj,event,fig,questflg)
gui=get(fig,'userdata');

if questflg
    a=questdlg('Clear Experiment?','Are you Sure?','Yes','No','Yes');
    if ~strcmpi(a,'Yes'); return; end
end

set(gui.SequenceOrder,'data',{},'userdata',[])
set(gui.SequenceList,'userdata',[],'string','','value',0)

%and disable all UI
for i=get(gui.SequenceFrame,'children')
    set(i,'enable','off')
end
for i=get(gui.LoopFrame,'children')
    set(i,'enable','off')
end
for i=findobj(get(gui.ActionAddFrame,'children'),'type','uicontrol')
    set(i,'enable','off')
end
for j=gui.ActionFrame
    for i=get(j,'children')
        set(i,'enable','off')
    end
end

set(gui.SequenceName,'string','')
delete(get(gui.visAx,'children'))
 
if questflg
    gui.PanelPatterns(:,:,2)=0;
    set(gui.PatternIm,'cdata',gui.PanelPatterns)
    set(gui.fig,'userdata',gui)
end


%Sequence Shifting
function sequenceUp(obj,event,fig)
gui=get(fig,'userdata');

dat=get(gui.SequenceOrder,'Data');
if isempty(dat); return; end

for i=1:size(dat,1)
    if dat{i,3}
        ind=i;
    end
end

if ind==1; return; end

experiment=get(gui.SequenceOrder,'userdata');
gTemp=experiment.actionlist(ind);

experiment.actionlist(ind)=experiment.actionlist(ind-1);
experiment.actionlist(ind-1)=gTemp;

gTemp=dat(ind,:);
dat(ind,:)=dat(ind-1,:);
dat(ind-1,:)=gTemp;

set(gui.SequenceName,'string',dat{ind-1,1})
set(gui.SequenceOrder,'Data',dat,'userdata',experiment)


function sequenceDown(obj,event,fig)

gui=get(fig,'userdata');

dat=get(gui.SequenceOrder,'Data');
if isempty(dat); return; end

for i=1:size(dat,1)
    if dat{i,3}
        ind=i;
    end
end

if ind==size(dat,1); return; end

experiment=get(gui.SequenceOrder,'userdata');
gTemp=experiment.actionlist(ind);

experiment.actionlist(ind)=experiment.actionlist(ind+1);
experiment.actionlist(ind+1)=gTemp;

gTemp=dat(ind,:);
dat(ind,:)=dat(ind+1,:);
dat(ind+1,:)=gTemp;

set(gui.SequenceName,'string',dat{ind+1,1})
set(gui.SequenceOrder,'Data',dat,'userdata',experiment)


function sequenceDelete(obj,event,fig)
gui=get(fig,'userdata');

dat=get(gui.SequenceOrder,'Data');
if isempty(dat); return; end

for i=1:size(dat,1)
    if dat{i,3}
        ind=i;
    end
end

experiment=get(gui.SequenceOrder,'userdata');
actionnum = experiment.actionsource(ind);
experiment.actionlist(ind)=[];
experiment.actionsource(ind)=[];
% Decrement all action sources > the action being deleted so they continue
% to point to the correct struct in actionlist.
inds = find(experiment.actionsource > actionnum);
experiment.actionsource(inds) = experiment.actionsource(inds) - 1;
dat(ind,:)=[];

if isempty(dat); 
    ClearAll('','',fig,0); 
    
    return;
end

if ind==1; ind=2; end
dat{ind-1,3}=true;
set(gui.SequenceName,'string',dat{ind-1,1})
set(gui.SequenceOrder,'Data',dat,'userdata',experiment)

mainConstructor(experiment.actionlist(ind-1).action,gui.SequenceList,1,gui.fig)


%%----------------------------------------------------
%Experiment Construction Code
function mainConstructor(action,listTarget,iind,fig)
gui=get(fig,'userdata');


%Update stored Action list in temperature sequence
%update visualization
if listTarget==gui.SequenceList
    %update stored action list
    dat=get(gui.SequenceOrder,'Data');
    for i=1:size(dat,1)
        if dat{i,3}
            ind=i;
        end
    end
    experiment=get(gui.SequenceOrder,'userdata');
    si=experiment.actionsource(ind);
    experiment.actionlist(si).action=action;
    set(gui.SequenceOrder,'userdata',experiment);
end

if isempty(action)&listTarget==gui.SequenceList
    set(gui.SequenceList,'string',{},'value',0,'userdata',[])
    visExp(action,gui.fig)
    return;
end

%keep in increasing time order
sorttimes=cell2mat({action.time});
[val,ind]=sort(sorttimes);
action=action(ind);

s={};
for i=1:length(action)
    hours=floor((action(i).time/1000)/(60*60));
    mins=floor((action(i).time/1000)/60-hours*60);
    sec=action(i).time/1000-mins*60-hours*60*60;
    s{end+1}=[num2str(hours),':',sprintf('%02.0f',mins),':',sprintf('%06.3f',sec),','];
    switch action(i).command(1)
        case 0 %end experiment
            s{end}=[s{end},'END'];
        case 1 %set LEDs
            s{end}=['<HTML><FONT color=aa00aa>',s{end},'ENDCAP,',num2str(action(i).command(2)),',',num2str(action(i).command(3)),',',num2str(action(i).command(4)),',',num2str(action(i).command(5)),'</FONT></HTML>'];
        case 2 %vibrate
            s{end}=['<HTML><FONT color="red">',s{end},'VIBRATE,',num2str(action(i).command(2)/10),',',num2str(action(i).command(3)),'</FONT></HTML>'];
        case 3 %video
            if action(i).command(2)==0
                s{end}=['<HTML><FONT color="blue">',s{end},'VIDEOSTOP','</FONT></HTML>'];
            else
                s{end}=['<HTML><FONT color="blue">',s{end},'VIDEO,',num2str(action(i).command(2)),',',action(i).userdata,'</FONT></HTML>'];
            end
        case 5 %analog input
            s{end}=[s{end},'SAMPLE,',dec2bin(action(i).command(2),8),',',num2str(action(i).command(3)),',',action(i).userdata];
        case 6 %reset all
            s{end}=[s{end},'ALLOFF'];
        case 7 %pattern
            s{end}=['<HTML><FONT color="green">',s{end},'PANEL,',num2str(action(i).command(2)),',',num2str(action(i).command(3)),',',num2str(action(i).command(4)),',',num2str(action(i).command(5)),'</FONT></HTML>'];            
     end
end

if iind==0; val=0;
else val=iind; end
set(listTarget,'string',s,'value',val,'userdata',action)

if listTarget==gui.SequenceList
    visExp(action,gui.fig)
end


function ShiftDown(obj,event,fig)
gui=get(fig,'userdata');

s=get(gui.SequenceList,'string');
vals=get(gui.SequenceList,'value');
action=get(gui.SequenceList,'userdata');
if isempty(action); return; end
if isempty(s); return; end

offset=inputdlg('Time in Seconds','Add an Offset');
if isempty(offset); return; end
if isnan(str2double(offset)); disp([offset,' is a bad number']); return; end
offset=str2double(offset)*1000;

for i=1:length(vals)
    action(vals(i)).time=action(vals(i)).time+offset;
end
backupExp(gui.fig)
mainConstructor(action,gui.SequenceList,vals(1),fig)

function deleteAction(obj,event,fig)
gui=get(fig,'userdata');
action=get(gui.SequenceList,'userdata');
if isempty(action); return; end
vals=get(gui.SequenceList,'value');

action(vals)=[];
if isempty(action); clearSequence('','',fig,0); return; end
backupExp(gui.fig)
if vals(1)==1; vals(1)=2; end
mainConstructor(action,gui.SequenceList,vals(1)-1,fig)

function CopyShift(obj,event,fig)
gui=get(fig,'userdata');

s=get(gui.SequenceList,'string');
vals=get(gui.SequenceList,'value');
action=get(gui.SequenceList,'userdata');
if isempty(action); return; end
if isempty(s); return; end

offset=inputdlg('Time in Seconds','Add a Start Offset to Code Segment');
if isempty(offset); return; end
if isnan(str2double(offset)); disp([offset,' is a bad number']); return; end
offset=str2double(offset)*1000;

newaction=action(vals);

for i=1:length(vals)
    newaction(vals(i)).time=newaction(vals(i)).time+offset;
end
backupExp(gui.fig)
mainConstructor([action,newaction],gui.SequenceList,vals(1),fig)


function newaction=buildNewAction(fig)
gui=get(fig,'userdata');

t=get(gui.ActionTime,'string');
%parseTime
[time,err]=parseTime(t);
if err==1
    errordlg('Invalid Time Value','Time Stamp');
    return;
end
newaction.userdata=[];
switch get(gui.ActionType,'value')
    case 1  %Start/Stop Video Acquisition
        fp=get(gui.video.sRate,'userdata');
        newaction.command(1,1:5)=[3 fp 0 0 0];
        newaction.userdata=get(gui.video.file,'string');
    case 2  %End-Cap LEDs
        v=get(gui.EndCap.leftBack(3),'userdata');
        v=[v, get(gui.EndCap.rightBack(3),'userdata')];
        v=[v, get(gui.EndCap.leftFront(3),'userdata')];
        v=[v, get(gui.EndCap.rightFront(3),'userdata')];
        newaction.command(1,1:5)=[1 v(3) v(1) v(4) v(2)];
    case 3  %Vibrate
        intensity=round(100*(5-get(gui.Vibrate.Intensity,'value'))/4);
        duration=round(get(gui.Vibrate.Duration,'userdata')*10);
        newaction.command(1,1:5)=[2 duration intensity 0 0];
    case 4  %Linear Pattern
        ID=str2double(get(gui.Pattern.ID,'string'));
        t_ms=get(gui.Pattern.Velocity,'userdata');
        dir=get(gui.Pattern.Direction,'value')-1;
        offset=get(gui.Pattern.Offset,'userdata');
        newaction.command(1,1:5)=[7 ID t_ms dir offset];        
    case 5  %All System Clear
        newaction.command(1,1:5)=[6 0 0 0 0];
    case 6  %End Sequence
        newaction.command(1,1:5)=[0 0 0 0 0];
end
newaction.time=time;



function AddAction2Sequence(obj,event,fig)
gui=get(fig,'userdata');
action=get(gui.SequenceList,'userdata');
newaction=buildNewAction(fig);
backupExp(fig)
[action ind]=insertElement(newaction,action);
mainConstructor(action,gui.SequenceList,ind,fig)
stepActionTime('','',fig)


%Insert a New Action Element
function [action ind]=insertElement(newaction,action)

gTemp.userdata=newaction.userdata;
gTemp.command=newaction.command;
gTemp.time=newaction.time;
newaction=gTemp;

%Case of empty action list
if isempty(action)
    action=newaction;
    ind=1;
    return;
end

%Find index where action will fit
PREvid=[];
ind=1;
for i=1:length(action)
    if action(i).command(1)==3&action(i).command(2)~=0&action(i).time<newaction.time; 
        PREvid=i; 
    end
    if action(i).command(1)==3&action(i).command(2)==0&action(i).time<newaction.time; 
        PREvid=[];
    end
    if action(i).time<=newaction.time; ind=i; end
end

if ~isempty(PREvid)&newaction.command(1)==3
        newaction.command(2)=0;
        newaction.userdata=[];
end
    
%Either replace or insert
if action(ind).time==newaction.time&action(ind).command(1)==newaction.command(1)
    action(ind)=newaction;   
else
    action=[action(1:ind),newaction,action((ind+1):end)];
    ind=ind+1;
end



%%----------------------------------------------------
%Experiment GUI handling

%Activate GUI for a new sequence
function newSeq(obj,event,fig)
gui=get(fig,'userdata');

set(get(gui.SequenceFrame,'children'),'enable','on')
set(gui.undo,'enable','off')
set(get(gui.LoopFrame,'children'),'enable','on')
set(findobj(get(gui.ActionAddFrame,'children'),'type','uicontrol'),'enable','on')
for j=gui.ActionFrame
    for i=get(j,'children')
        set(i,'enable','on')
    end
end

set(gui.SequenceList,'userdata',[],'string','')

%Add item to Experiment List
dat=get(gui.SequenceOrder,'Data');
if isempty(dat)
    dat={'Temporary Name',21, true,false};
    set(gui.SequenceOrder,'data',dat)
    set(gui.SequenceName,'string','Temporary Name')
else
    for i=1:size(dat,1)
        if dat{i,3}
            dat{i,3}=false;
            dat=cat(1,dat(1:i,:),{'Temporary Name',21, true,false},dat(i+1:end,:));
            break
        end
    end
    set(gui.SequenceOrder,'data',dat)
    set(gui.SequenceName,'string','Temporary Name')
end

experiment=get(gui.SequenceOrder,'userdata');

if isempty(experiment)
    experiment.actionlist(1).action=[];
    experiment.actionlist(1).name='Temporary Name';
    experiment.actionlist(1).T=21;
    experiment.actionlist(1).Vid=false;
    experiment.actionsource(1)=1;
else
    experiment.actionlist(end+1).action=[];
    experiment.actionlist(end).name='Temporary Name';
    experiment.actionlist(end).T=21;
    experiment.actionlist(end).Vid=false;
    experiment.actionsource(end+1)=length(experiment.actionlist);
end
    set(gui.SequenceOrder,'userdata',experiment)
    
    mainConstructor([],gui.SequenceList,0,fig)


%Update the selected sequence and change selection, check for errors in temperature
function ExpClick(obj,event,fig)
gui=get(fig,'userdata');

%Check for bad temperature values
dat=get(obj,'Data');

if isnan(event.NewData)
    dat{event.Indices(1),event.Indices(2)}=event.PreviousData;
end
set(gui.SequenceOrder,'Data',dat)

experiment=get(gui.SequenceOrder,'userdata');
%update temperature in experiment struct
if event.Indices(2)==2  
    ind=event.Indices(1);
    experiment.actionlist(ind).T=dat{event.Indices(1),event.Indices(2)};
end
%Update video preferences in experiment struct
if event.Indices(2)==4
   ind=event.Indices(1);
   experiment.actionlist(ind).Vid=dat{event.Indices(1),event.Indices(2)};
end

%check for selection change
if event.Indices(2)==3
    for i=1:size(dat,1)
        dat{i,3}=false;
    end
end


set(gui.SequenceName,'string',dat{event.Indices(1),1})
dat{event.Indices(1),3}=true;

set(gui.SequenceOrder,'userdata',experiment)
set(gui.undo,'userdata',[],'enable','off')
set(obj,'Data',dat)

function cellselect(obj,event,fig)
if isempty(event.Indices); return; end;
gui=get(fig,'userdata');
dat=get(obj,'Data');
for i=1:size(dat,1)
    dat{i,3}=false;
end

dat{event.Indices(1),3}=true;
set(obj,'Data',dat)


%Update Sequence info with selected Sequence
experiment=get(gui.SequenceOrder,'userdata');

ind=event.Indices(1);
action=experiment.actionlist(ind).action;

set(gui.SequenceName,'string',dat{event.Indices(1),1})
mainConstructor(action,gui.SequenceList,1,fig)
    
    
function seqName(obj,event,fig)
gui=get(fig,'userdata');

dat=get(gui.SequenceOrder,'Data');
for i=1:size(dat,1)
    if dat{i,3}
        dat{i,1}=get(obj,'string');
        ind=i;
        break
    end
end
set(gui.SequenceOrder,'Data',dat)

%update stored action name
experiment=get(gui.SequenceOrder,'userdata');
si=experiment.actionsource(ind);
experiment.actionlist(si).name=get(obj,'string');
set(gui.SequenceOrder,'userdata',experiment);


%When user clicks on the sequence list
function clickSequence(obj,event,fig)
gui=get(fig,'userdata');

s=get(obj,'string');
if isempty(s); return; end

val=get(obj,'value');
if isempty(val); return; end
val=val(1);
action=get(obj,'userdata');
if isempty(action); return; end

    tSec=action(val).time/1000;
    hours=floor(tSec/(60*60));
    mins=floor((tSec-hours*60*60)/60);
    sec=tSec-hours*60*60-mins*60;

    tStr='';
    if hours~=0
        tStr=[tStr,num2str(hours),':'];
    end
    if hours~=0|mins~=0
        tStr=[tStr,sprintf('%02.0f',mins),':'];
    end
    tStr=[tStr,sprintf('%2.3f',sec)];
    set(gui.ActionTime,'string',tStr)
        
switch action(val).command(1)
    case 1; set(gui.ActionType,'value',2); ActionSwitch(gui.ActionType,'',gui.fig);
    case 2; set(gui.ActionType,'value',3); ActionSwitch(gui.ActionType,'',gui.fig);
    case 7; set(gui.ActionType,'value',4); ActionSwitch(gui.ActionType,'',gui.fig);
    case 5; set(gui.ActionType,'value',5); ActionSwitch(gui.ActionType,'',gui.fig);
    case 3; set(gui.ActionType,'value',1); ActionSwitch(gui.ActionType,'',gui.fig);
end

%Create action element for addition to 
function buildLoop(obj,event,fig)
gui=get(fig,'userdata');
%parseTime
t=get(gui.ActionTime,'string');

[time,err]=parseTime(t);
if err; return; end

newaction=buildNewAction(fig);

insert2Loop(newaction,fig)
stepActionTime('','',fig)

%Insert an action into the loop action struct
function insert2Loop(newaction,fig)
gui=get(fig,'userdata');

action=get(gui.LoopList,'userdata');
if isempty(action)
    action=newaction;
    setLoopEnd(action, fig)
    mainConstructor(action,gui.LoopList,1,gui.fig)
    return
end

replaced=0;
for i=1:length(action)
    if action(i).command(1)==newaction.command(1)&action(i).time==newaction.time
        action(i)=newaction;
        replaced=1;
    end
    if replaced==1
        iind=i;
    end
end

if replaced==0
    action(end+1).command=newaction.command;
    action(end).time=newaction.time;
    iind=length(action);
end

setLoopEnd(action, fig)
mainConstructor(action,gui.LoopList,iind,gui.fig)

function setLoopEnd(action, fig)
gui=get(fig,'userdata');
time=action(end).time;
Step=str2double(get(gui.ActionStep,'string'));

tSec=time/1000+Step;
hours=floor(tSec/(60*60));
mins=floor((tSec-hours*60*60)/60);
sec=tSec-hours*60*60-mins*60;

tStr='';
if hours~=0
    tStr=[tStr,num2str(hours),':'];
end
if hours~=0|mins~=0
    tStr=[tStr,sprintf('%02.0f',mins),':'];
end
tStr=[tStr,sprintf('%2.3f',sec)];
set(gui.LoopDur,'string',tStr)

function loopClear(obj,event,fig)
gui=get(fig,'userdata');
set(gui.LoopList,'userdata',[],'string',{},'value',0)

function loopRemoveAction(obj,event,fig)
gui=get(fig,'userdata');
val=get(gui.LoopList,'value');
action=get(gui.LoopList,'userdata');
if isempty(action); return; end

action(val)=[];
if isempty(action); loopClear('','',fig); return; end
if (val-1)<1; val=2; end
mainConstructor(action,gui.LoopList,val-1,gui.fig)
setLoopEnd(action,fig)

function loop2Experiment(obj,event,fig)
gui=get(fig,'userdata');
loop=get(gui.LoopList,'userdata');

if isempty(loop); return; end

t=get(gui.LoopTime,'string');
[time,err]=parseTime(t);
    
duration=str2double(get(gui.LoopDur,'string'))*1000;
if isnan(duration)|duration<=loop(end).time
    errordlg('Invalid Loop Duration (may be too short)','Loop Error');
    return
end

N=str2double(get(gui.LoopN,'string'));
if isnan(N)|N<1
    errordlg('Bad Value of Itterations (N)','Loop Error');
    return
end
k=1;
for i=1:N
    for j=1:length(loop)
        newaction(k).command=loop(j).command;
        newaction(k).time=time+loop(j).time;
        newaction(k).userdata=loop(j).userdata;
        k=k+1;
    end
    time=time+duration;
end

backupExp(gui.fig)
action=get(gui.SequenceList,'userdata');
for i=1:length(newaction)
    [action ind]=insertElement(newaction(i),action);
    mainConstructor(action,gui.SequenceList,ind,fig)
    drawnow
end

%Set Action time back to 0
function clearActionTime(obj,event,fig)
gui=get(fig,'userdata');
set(gui.ActionTime,'string','0')

%Update Experiment Visualization Display
function visExp(action,fig)
gui=get(fig,'userdata');
delete(get(gui.visAx,'children'))

%Loop through action struct and build vectors for each type of event:
vis.endcapT=[0]; vis.endcapAmp=[0;0;0;0];
vis.vibrateT=[0]; vis.vibrateAmp=[0];
vis.videoT=[]; vis.videoFile={}; vis.videoRate=[];
vis.panelT=[0]; vis.panelID=[nan]; vis.panelVel=[0]; vis.panelOff=[nan]; vis.panelDir=[-1];

for i=1:length(action)
    vis=visBuilder(vis,action(i));
end

endT=max([vis.endcapT,vis.vibrateT,vis.panelT,vis.videoT]);
vis.endcapT=[vis.endcapT,endT];
vis.endcapAmp=[vis.endcapAmp,vis.endcapAmp(:,end)];
vis.vibrateT=[vis.vibrateT,endT];
vis.vibrateAmp=[vis.vibrateAmp,vis.vibrateAmp(end)];
vis.panelT=[vis.panelT,endT];
vis.panelVel=[vis.panelVel,vis.panelVel(end)]; vis.panelDir=[vis.panelDir,vis.panelDir(end)];

val=1;
if ~isempty(vis.videoT)
    if length(vis.videoT)/2~=floor(length(vis.videoT)/2)
        vis.videoT=[vis.videoT,action(end).time];
    end
    for i=1:2:length(vis.videoT)
       gT=patch([vis.videoT(i) vis.videoT(i+1) vis.videoT(i+1) vis.videoT(i)]/1000,[-5000 -5000 5000 5000],'r','parent',gui.visAx);
       set(gT,'facecolor',[.1 .1 .8],'facealpha',.2,'edgecolor',[0 0 1],'linewidth',2)
       fps=1000/vis.videoRate(i);
       dur=abs(diff([vis.videoT(i),vis.videoT(i+1)]))/1000;
        if val==1
            text(vis.videoT(i)/1000,305*7+100,[vis.videoFile{i},' @ ',num2str(fps),'Hz for ',num2str(dur),'sec (',num2str(floor(dur*fps)),'frames)'],'fontweight','bold','parent',gui.visAx)
            val=0;
        else
            text(vis.videoT(i)/1000,-150,[vis.videoFile{i},' @ ',num2str(fps),'Hz for ',num2str(dur),'sec (',num2str(floor(dur*fps)),'frames)'],'fontweight','bold','parent',gui.visAx)
            val=1;
        end
    end
end

if ~isempty(vis.endcapT)
    xdata=zeros(1,length(vis.endcapT)*2-1);
    ydata=zeros(1,length(vis.endcapT)*2-1);
    c(1,:)=[2/3 0 2/3];
    c(2,:)=[2/3 0 2/3];
    c(3,:)=[2/3 0 2/3];
    c(4,:)=[2/3 0 2/3];
    for i=1:4
        xdata(1:2:end)=vis.endcapT;
        xdata(2:2:end)=vis.endcapT(2:end);
        ydata(1:2:end)=vis.endcapAmp(i,:);
        ydata(2:2:end)=vis.endcapAmp(i,1:end-1);
        line(xdata/1000,ydata+(i-1)*255+(i-1)*50,'parent',gui.visAx,'linewidth',2,'color',c(i,:))
    end
end
if ~isempty(vis.vibrateT)
    xdata=zeros(1,length(vis.vibrateT)*2-1);
    ydata=zeros(1,length(vis.vibrateT)*2-1);
    
    xdata(1:2:end)=vis.vibrateT;
    xdata(2:2:end)=vis.vibrateT(2:end);
    ydata(1:2:end)=vis.vibrateAmp;
    ydata(2:2:end)=vis.vibrateAmp(1:end-1);
    line(xdata/1000,ydata*255/100+(4)*255+(4)*50,'parent',gui.visAx,'linewidth',2,'color',[1 0 0],'linestyle','-')
end

if ~isempty(vis.panelT)
    xdata=zeros(1,length(vis.panelT)*2-1);
    ydata=zeros(1,length(vis.panelT)*2-1);
    y2=zeros(1,length(vis.panelT)*2-1);
    
    xdata(1:2:end)=vis.panelT;
    xdata(2:2:end)=vis.panelT(2:end);
    evens=vis.panelDir/2==floor(vis.panelDir/2);

    ydata(1:2:end)=vis.panelVel.*(-1).^evens;
    ydata(2:2:end)=vis.panelVel(1:end-1).*(-1).^evens(1:end-1);    
    ydata=ydata*256/20;
    
    y2(1:2:end)=vis.panelDir~=-1;
    y2(2:2:end)=vis.panelDir(1:end-1)~=-1;
    
    line(xdata/1000,y2*300+5*305,'parent',gui.visAx,'linewidth',2','color','k')
    line(xdata/1000,ydata+(6)*305,'parent',gui.visAx,'linewidth',2,'color',[0 .7 0],'linestyle','-')
end

set(gui.visAx,'xlim',[0 endT+1]/1000,'ylim',[-250 305*7+250])
set(gui.visAx,'ytick',[0 305 305*2 305*3 305*4 305*5 305*6]-25,...
    'yticklabel',{'LF','LB','RF','RB','Vib','Panel','Speed',''},'ygrid','on')

function vis=visBuilder(vis,action)
    switch action.command(1)
        case 0 %End Experiment
            vis.endcapT=[vis.endcapT,action.time];
            vis.endcapAmp=[vis.endcapAmp,[0;0;0;0]];
            vis.vibrateT=[vis.vibrateT,action.time];
            vis.vibrateAmp=[vis.vibrateAmp,0];
            vis.panelT=[vis.panelT,action.time];
            vis.panelID=[vis.panelID,nan]; vis.panelVel=[vis.panelVel,0]; vis.panelOff=[vis.panelOff,nan]; vis.panelDir=[vis.panelDir,-1];
        case 1 %End Cap LEDs
            vis.endcapT=[vis.endcapT,action.time];
            vis.endcapAmp=[vis.endcapAmp,action.command(2:5)'];
        case 2 %Vibrate Motor
            vis.vibrateT=[vis.vibrateT,action.time];
            vis.vibrateAmp=[vis.vibrateAmp,action.command(3)];
            vis.vibrateT=[vis.vibrateT,action.time+action.command(2)*100];
            vis.vibrateAmp=[vis.vibrateAmp,0];
        case 3 %Video Acquisition
            vis.videoT=[vis.videoT,action.time];
            vis.videoRate=[vis.videoRate,action.command(2)];
            vis.videoFile{end+1}=action.userdata;
        case 5 %Analog input
        case 6 %ALL OFF
            vis.endcapT=[vis.endcapT,action.time];
            vis.endcapAmp=[vis.endcapAmp,[0;0;0;0]];
            vis.vibrateT=[vis.vibrateT,action.time];
            vis.vibrateAmp=[vis.vibrateAmp,0];
            vis.panelT=[vis.panelT,action.time];
            vis.panelID=[vis.panelID,nan]; vis.panelVel=[vis.panelVel,0]; vis.panelOff=[vis.panelOff,nan]; vis.panelDir=[vis.panelDir,-1];            
        case 7 %Panel Patterns
            vis.panelT=[vis.panelT,action.time];
            vis.panelID=[vis.panelID,action.command(2)]; vis.panelVel=[vis.panelVel,action.command(3)]; 
            vis.panelOff=[vis.panelOff,action.command(5)]; vis.panelDir=[vis.panelDir,action.command(4)];            
    end


%%----------------------------------------------------
%Misc GUI handling
function patternGraph(obj,event,fig)
gui=get(fig,'userdata');
switch obj
    case gui.PatternSelect
        set([gui.GraphSelect gui.FlashPatternSelect],'value',0)
        set(gui.PatternSelect,'value',1)
        set(gui.PatternFrame,'visible','on')
        set(gui.FlashPatternFrame,'visible','off')
        set(gui.VisFrame,'visible','off')
    case gui.FlashPatternSelect
        set([gui.GraphSelect gui.PatternSelect],'value',0)
        set(gui.FlashPatternSelect,'value',1)
        set(gui.FlashPatternFrame,'visible','on')
        set(gui.PatternFrame,'visible','off')
        set(gui.VisFrame,'visible','off')
    case gui.GraphSelect
        set([gui.PatternSelect gui.FlashPatternSelect],'value',0)
        set(gui.GraphSelect,'value',1)
        set(gui.VisFrame,'visible','on')
        set(gui.PatternFrame,'visible','off')
        set(gui.FlashPatternFrame,'visible','off')
end

function graphShift(obj,event,fig)
gui=get(fig,'userdata');
xlim=get(gui.visAx,'xlim');
dx=abs(diff(xlim))*.25;
switch obj
    case gui.visLeft
        xlim=xlim-dx;
    case gui.visRight
        xlim=xlim+dx;
end
if min(xlim)<0; xlim=xlim-min(xlim); end
set(gui.visAx,'xlim',xlim)

%Switch displayed parameter interface
function ActionSwitch(obj,event,fig)
gui=get(fig,'userdata');
val=get(gui.ActionType,'value');
set(gui.ActionFrame,'visible','off')
set(gui.ActionFrame(val),'visible','on')

function editPatternEntry(obj,event,index,fig)
gui=get(fig,'userdata');
val = round(str2double(get(obj,'string')));

if isnan(val)||val<0||val>15 %Bad Value Entered
    set(obj,'string',num2str(get(obj,'userdata')))
    return
end

ind = [];
for i=1:gui.nPatterns
    if gui.PanelPatterns(i,1,1)==0.4
        ind = i;
        break
    end
end

gui.PanelPatterns(ind,index,2)=val;

pp = gui.PanelPatterns;
pp(:,:,2)=pp(:,:,2)/15;
set(gui.PatternIm,'cdata',pp)

set(gui.fig,'userdata',gui)


%%----------------------------------------------------
%Pattern Handling Code
function editPattern(obj,event,fig)
gui=get(fig,'userdata');
a=get(gca,'currentpoint');
x=round(a(1,1));
y=round(a(1,2));
if x<1|x>64; return; end
if y<1|y>gui.nPatterns; return; end

if gui.PanelPatterns(y,1,1)~=.4  %this row has not been selected yet
gui.PanelPatterns(:,:,[1,3])=0;  
gui.PanelPatterns(y,:,[1,3])=.4; %select this row
gui.SelectedPattern=y;
pp = gui.PanelPatterns;
pp(:,:,2)=pp(:,:,2)/15;
set(gui.PatternIm,'cdata',pp)
set(gui.fig,'userdata',gui)
for i=1:64
    val = gui.PanelPatterns(y,i,2);
    set(gui.PatternEntry(i),'userdata',val,'string',num2str(val))
end
return
end

%if already on the row
% if gui.PanelPatterns(y,x,2)==1; gui.PanelPatterns(y,x,2)=0;
% else gui.PanelPatterns(y,x,2)=1; end
% set(gui.PatternIm,'cdata',gui.PanelPatterns)
% set(gui.fig,'userdata',gui)

function patternScroll(obj,event,fig)
gui=get(fig,'userdata');

Val=event.VerticalScrollCount;

if strcmpi(get(gui.VisFrame,'visible'),'on'); 
    xlim=get(gui.visAx,'xlim');
    mx=min(xlim);
    xlim=(xlim-mx)*2^Val+mx;
    if min(xlim)<0; 
        xlim=xlim-min(xlim);
    end
    set(gui.visAx,'xlim',xlim)
    return; 

elseif strcmpi(get(gui.PatternFrame,'visible'),'on'); 
    ylim=get(gui.PatternStorageAx,'ylim')+Val;

    if min(ylim)<.5; return; end
    if (max(ylim)>(gui.nPatterns+.5)); return; end

    set(gui.PatternStorageAx,'ylim',ylim)
    set(gui.PatternID,'visible','off')
    ylim=round(ylim);
    set(gui.PatternID(min(ylim):(max(ylim)-1)),'visible','on')

elseif strcmpi(get(gui.FlashPatternFrame,'visible'),'on'); 
    ylim=get(gui.FlashPatternStorageAx,'ylim')+Val;

    if min(ylim)<.5; return; end
    if (max(ylim)>(gui.flashSize+.5)); return; end

    set(gui.FlashPatternStorageAx,'ylim',ylim)
    set(gui.FlashPatternID,'visible','off')
    ylim=round(ylim);
    set(gui.FlashPatternID(min(ylim):(max(ylim)-1)),'visible','on')
end


function patternClearSet(obj,event,fig)
gui=get(fig,'userdata');
ID=gui.SelectedPattern;
switch obj
    case gui.PatternClear;  gui.PanelPatterns(ID,:,2)=0;
    case gui.PatternSet;    gui.PanelPatterns(ID,:,2)=15;
end
pp = gui.PanelPatterns;
pp(:,:,2)=pp(:,:,2)/15;
set(gui.PatternIm,'cdata',pp)
set(gui.fig,'userdata',gui)

y=gui.SelectedPattern;
for i=1:64
    val = gui.PanelPatterns(y,i,2);
    set(gui.PatternEntry(i),'userdata',val,'string',num2str(val))
end



function patternRandom(obj,event,fig)
gui=get(fig,'userdata');
ID=gui.SelectedPattern;
gui.PanelPatterns(ID,:,2)=round(rand(1,64)*15);
pp = gui.PanelPatterns;
pp(:,:,2)=pp(:,:,2)/15;
set(gui.PatternIm,'cdata',pp)
set(gui.fig,'userdata',gui)

y=gui.SelectedPattern;
for i=1:64
    val = gui.PanelPatterns(y,i,2);
    set(gui.PatternEntry(i),'userdata',val,'string',num2str(val))
end

function patternPrevious(obj,event,fig)
gui=get(fig,'userdata');
ID=gui.SelectedPattern;
if ID==1; return; end

gui.PanelPatterns(ID,:,2)=gui.PanelPatterns(ID-1,:,2);
pp = gui.PanelPatterns;
pp(:,:,2)=pp(:,:,2)/15;
set(gui.PatternIm,'cdata',pp)
set(gui.fig,'userdata',gui)

y=gui.SelectedPattern;
for i=1:64
    val = gui.PanelPatterns(y,i,2);
    set(gui.PatternEntry(i),'userdata',val,'string',num2str(val))
end


function patternInvert(obj,event,fig)
gui=get(fig,'userdata');
ID=gui.SelectedPattern;
gui.PanelPatterns(ID,:,2)=15-gui.PanelPatterns(ID,:,2);
pp = gui.PanelPatterns;
pp(:,:,2)=pp(:,:,2)/15;
set(gui.PatternIm,'cdata',pp)
set(gui.fig,'userdata',gui)

y=gui.SelectedPattern;
for i=1:64
    val = gui.PanelPatterns(y,i,2);
    set(gui.PatternEntry(i),'userdata',val,'string',num2str(val))
end


%----------------------------------------------------
%Main GUI Generation Code
function makegui
gui.version='1.0';

delete(findobj('tag','GvidFig'))
tempFig=figure('position',[0 0 1050 1150]/2,'menubar','none','numbertitle','off','name',...
    ['Olympiad Experiment Design v',gui.version],'tag','gOlympiad','resize','off');
centerfig(tempFig)
axes('position',[0 0 1 1],'color',[.8 .9 .8],'ytick',[]...
    ,'xtick',[],'xlim',[0 1],'ylim',[0 1],'xcolor',[.4 .4 .4],'ycolor',[.4 .4 .4]);
axis off
aTemp=imread('Olympic_OlympiadLogo.jpg');
image(aTemp)
axis off
% pause(1)

gui.fig=figure('name',['Olympiad Phototaxis, Experiment Design - Gus K. Lott III, PhD - For HHMI Internal Use Only, - v',gui.version],'numbertitle','off','tag','gOlympiad',...
    'menubar','none','position',[0 0 800 800],'resize','on','doublebuffer','on','color',[.7 .7 1],'deletefcn','delete(findobj(''tag'',''GvidFig''))');
set(gui.fig,'WindowScrollWheelFcn',{@patternScroll,gui.fig})

centerfig(gui.fig)
delete(tempFig)
gui.constructionPanel=uipanel('units','normalized','position',[0 0 1 1],'backgroundcolor',[.5 .5 .8]);

%Final Experiment w/ Thermal Path & Action Sequences
gui.ExperimentFrame=uipanel('parent',gui.constructionPanel,'title','Experiment Sequence/Thermal Order','units','normalized',...
    'position',[0.01 0.77 .48 .22],'backgroundcolor',[1 .8 .6]);
gui.SequenceOrder=uitable('parent',gui.ExperimentFrame,'units','normalized','position',[0.01 0.15 0.98 0.84],...
    'ColumnName',{'Sequence Name','T','Select','Video Trans'},...
    'ColumnFormat',{'char','Numeric','logical','logical'},...
    'columneditable',[false true true true],...
    'CellEditCallback',{@ExpClick,gui.fig},'CellSelectionCallback',{@cellselect,gui.fig});
gui.AddSequence=uicontrol(gui.ExperimentFrame,'style','pushbutton','units','normalized',...
    'position',[0.01 0.01 .28 .13],'string','New Sequence','fontweight','bold','callback',{@newSeq,gui.fig});
gui.ClearAll=uicontrol(gui.ExperimentFrame,'style','pushbutton','units','normalized',...
    'position',[0.30 0.01 .20 .13],'string','Clear All','fontweight','bold','callback',{@ClearAll,gui.fig,1});

gui.UpSeq=uicontrol(gui.ExperimentFrame,'style','pushbutton','units','normalized',...
    'position',[0.64 0.01 .1 .13],'string','Up','fontweight','bold','callback',{@sequenceUp,gui.fig});
gui.DownSeq=uicontrol(gui.ExperimentFrame,'style','pushbutton','units','normalized',...
    'position',[0.75 0.01 .1 .13],'string','Down','fontweight','bold','callback',{@sequenceDown,gui.fig});
gui.DeleteSeq=uicontrol(gui.ExperimentFrame,'style','pushbutton','units','normalized',...
    'position',[0.86 0.01 .13 .13],'string','Delete','fontweight','bold','callback',{@sequenceDelete,gui.fig});


%Sequence Display and editing
gui.SequenceFrame=uipanel('parent',gui.constructionPanel,'title','Sequence','units','normalized',...
    'position',[0.01 0.31 .48 .45],'backgroundcolor',[1 .8 .6]);

uicontrol('parent',gui.SequenceFrame','style','text','backgroundcolor',get(gui.SequenceFrame,'backgroundcolor'),'units','normalized',...
    'position',[0.01 .93 .11 .05],'string','Name:','horizontalalignment','left','fontweight','bold');
gui.SequenceName=uicontrol('parent',gui.SequenceFrame,'style','edit','backgroundcolor','w','units','normalize',...
    'position',[0.12 0.93 0.87 0.06],'horizontalalignment','left','fontweight','bold','callback',{@seqName,gui.fig});
gui.SequenceList=uicontrol(gui.SequenceFrame,'style','listbox','backgroundcolor','w','units','normalized','min',0,'max',2,...
    'position',[0.01 0.14 .98 .78],'userdata',[],'fontweight','bold','fontsize',10,'foregroundcolor',[.6 .6 .6],'callback',{@clickSequence,gui.fig});
gui.ShiftAction=uicontrol(gui.SequenceFrame,'style','pushbutton','units','normalized',...
    'position',[0.01 0.01 .28 .05],'string','Shift Up/Down','fontweight','bold','callback',{@ShiftDown,gui.fig});
gui.CopyAction=uicontrol(gui.SequenceFrame,'style','pushbutton','units','normalized',...
    'position',[0.31 0.01 .38 .05],'string','Copy + Paste','fontweight','bold','callback',{@CopyShift,gui.fig});

gui.SaveSequence=uicontrol(gui.SequenceFrame,'style','pushbutton','units','normalized',...
    'position',[0.71 0.01 .14 .05],'string','Save...','fontweight','bold','callback',{@saveSeq,gui.fig});
gui.LoadSequence=uicontrol(gui.SequenceFrame,'style','pushbutton','units','normalized',...
    'position',[0.86 0.01 .13 .05],'string','Load...','fontweight','bold','callback',{@loadSeq,gui.fig});

gui.undo=uicontrol(gui.SequenceFrame,'style','pushbutton','units','normalized',...
    'position',[0.71 0.07 .28 .05],'string','Undo','fontweight','bold','callback',{@undoAction,gui.fig},'enable','off');
gui.RemoveAction=uicontrol(gui.SequenceFrame,'style','pushbutton','units','normalized',...
    'position',[0.31 0.07 .38 .05],'string','Remove Action','fontweight','bold','callback',{@deleteAction,gui.fig});
gui.ResetSequence=uicontrol(gui.SequenceFrame,'style','pushbutton','units','normalized',...
    'position',[0.01 0.07 .28 .05],'string','Clear','fontweight','bold','callback',{@clearSequence,gui.fig,1});

for i=get(gui.SequenceFrame,'children')
    set(i,'enable','off')
end

%Create a Loop
gui.LoopFrame=uipanel('parent',gui.constructionPanel,'title','Create a Loop','units','normalized','position',[0.51 0.31 .48 .39],'backgroundcolor',[1 .8 .6]);
gui.LoopList=uicontrol(gui.LoopFrame,'style','listbox','backgroundcolor','w','units','normalized',...
    'position',[0.01 0.17 .98 .82],'fontweight','bold','fontsize',10,'foregroundcolor',[.6 .6 .6]);

gui.LoopAdd=uicontrol(gui.LoopFrame,'style','pushbutton','units','normalized',...
    'position',[0.01 0.09 .49 .07],'string','<< Add to Sequence','fontweight','bold','callback',{@loop2Experiment,gui.fig});
gui.LooptClear=uicontrol(gui.LoopFrame,'style','pushbutton','units','normalized',...
    'position',[0.51 0.09 .49 .07],'string','Action Time to 0','fontweight','bold','callback',{@clearActionTime,gui.fig});

gui.LoopRemove=uicontrol(gui.LoopFrame,'style','pushbutton','units','normalized',...
    'position',[0.01 0.01 .25 .07],'string','Remove Action','fontweight','bold','callback',{@loopRemoveAction,gui.fig});
gui.LoopClear=uicontrol(gui.LoopFrame,'style','pushbutton','units','normalized',...
    'position',[0.27 0.01 .11 .07],'string','Clear','fontweight','bold','callback',{@loopClear,gui.fig});
uicontrol(gui.LoopFrame,'style','Text','units','normalized','horizontalalignment','left','tooltipstring','Number of Iterations',...
    'position',[0.39 0.01 .15 .07],'string','N:','backgroundcolor',get(gui.LoopFrame,'backgroundcolor'),'fontunits','normalized','fontsize',.8,'fontweight','bold');
gui.LoopN=uicontrol(gui.LoopFrame,'style','Edit','units','normalized','backgroundcolor','w',...
    'position',[0.45 0.01 .06 .07],'string','2','userdata',2,'fontweight','bold');
uicontrol(gui.LoopFrame,'style','Text','units','normalized','horizontalalignment','left','tooltipstring','Time Code for Loop Initation (units: seconds)',...
    'position',[0.52 0.01 .15 .07],'string','Time:','backgroundcolor',get(gui.LoopFrame,'backgroundcolor'),'fontunits','normalized','fontsize',.8,'fontweight','bold');
gui.LoopTime=uicontrol(gui.LoopFrame,'style','Edit','units','normalized','backgroundcolor','w',...
    'position',[0.64 0.01 .12 .07],'string','0','userdata',0,'fontweight','bold');
uicontrol(gui.LoopFrame,'style','Text','units','normalized','horizontalalignment','left','tooltipstring','Loop Duration (units: seconds)',...
    'position',[0.77 0.01 .14 .07],'string','Dur:','backgroundcolor',get(gui.LoopFrame,'backgroundcolor'),'fontunits','normalized','fontsize',.8,'fontweight','bold');
gui.LoopDur=uicontrol(gui.LoopFrame,'style','Edit','units','normalized','backgroundcolor','w',...
    'position',[0.87 0.01 .12 .07],'string','0','fontweight','bold');

for i=get(gui.LoopFrame,'children')
    set(i,'enable','off')
end

%Element Addition, Batching
%Include onscreen instructions for each action
gui.ActionAddFrame=uipanel('parent',gui.constructionPanel,'title','Add an Action','units','normalized','position',[0.51 0.71 .48 .28],'backgroundcolor',[1 .8 .6]);
gui.ActionAdd=uicontrol(gui.ActionAddFrame,'style','pushbutton','units','normalized',...
    'position',[0.01 0.01 .43 .1],'string','<<Add to Sequence','fontweight','bold','callback',{@AddAction2Sequence,gui.fig});
gui.ActionStep=uicontrol(gui.ActionAddFrame,'style','pushbutton','units','normalized',...
    'position',[0.45 0.01 .19 .1],'string','Step','fontweight','bold','callback',{@stepActionTime,gui.fig});
gui.ActionLoop=uicontrol(gui.ActionAddFrame,'style','pushbutton','units','normalized',...
    'position',[0.65 0.01 .34 .1],'string','Add to Loop  \/','fontweight','bold','callback',{@buildLoop,gui.fig});

gui.ActionType=uicontrol(gui.ActionAddFrame,'style','popupmenu','units','normalized',...
    'position',[0.01 0.89 .49 .1],'string',' ','fontweight','bold','backgroundcolor','w','callback',{@ActionSwitch,gui.fig});
s={'Start/Stop Video Acquisition','Set End-Cap LEDs','Vibrate','Linear Pattern',...
    'All Systems Clear','End Sequence'};
set(gui.ActionType,'string',s)

uicontrol(gui.ActionAddFrame,'style','Text','units','normalized','horizontalalignment','left',...
    'position',[0.51 0.89 .1 .1],'string','Time:','backgroundcolor',get(gui.ActionAddFrame,'backgroundcolor'),'fontunits','normalized','fontsize',.7,'fontweight','bold');
gui.ActionTime=uicontrol(gui.ActionAddFrame,'style','Edit','units','normalized',...
    'position',[0.62 0.89 .17 .1],'string','0','fontweight','bold','backgroundcolor','w','userdata',0,'tooltipstring','Time in (s), (min:sec),(hour:min:sec)');
uicontrol(gui.ActionAddFrame,'style','Text','units','normalized','horizontalalignment','left',...
    'position',[0.8 0.89 .1 .1],'string','Step:','backgroundcolor',get(gui.ActionAddFrame,'backgroundcolor'),'fontunits','normalized','fontsize',.7,'fontweight','bold');
gui.ActionStep=uicontrol(gui.ActionAddFrame,'style','Edit','units','normalized',...
    'position',[0.91 0.89 .08 .1],'string','0','fontweight','bold','backgroundcolor','w','userdata',0,'tooltipstring','Time in (s), (min:sec),(hour:min:sec)');

for i=get(gui.ActionAddFrame,'children')
    set(i,'enable','off')
end

%Sub-frame for each element type
%Start/Stop Video Acquisition
gui.ActionFrame(1)=uipanel(gui.ActionAddFrame,'title','','unit','normalized','position',[.01 .12 .98 .75],'backgroundcolor',[1 .9 .7],'visible','on');
gui.video.txt=uicontrol(gui.ActionFrame(1),'style','Text','units','normalized','horizontalalignment','left',...
    'position',[0.01 0.6 .45 .13],'string','Video Frame Period (ms):','backgroundcolor',get(gui.ActionFrame(1),'backgroundcolor'),'fontsize',10,'fontweight','bold');
gui.video.sRate=uicontrol(gui.ActionFrame(1),'style','edit','units','normalized',...
    'position',[0.46 0.6 .1 .13],'string','20','fontweight','bold','backgroundcolor','w','userdata',20,'callback',{@genericCheck,gui.fig});
gui.video.file=uicontrol(gui.ActionFrame(1),'style','edit','units','normalized',...
    'position',[0.4 0.31 .59 .13],'string','temp.avi','backgroundcolor','w','fontsize',8,'fontweight','bold');
gui.video.fileselect=uicontrol(gui.ActionFrame(1),'style','text','units','normalized',...
    'position',[0.01 0.31 .35 .13],'string','File Name','fontweight','bold','backgroundcolor',get(gui.ActionFrame(1),'backgroundcolor'));

%Add End-Cap LED Element (set alpha)----------------------------
gui.ActionFrame(2)=uipanel(gui.ActionAddFrame,'title','','unit','normalized','position',[.01 .12 .98 .75],'backgroundcolor',get(gui.ActionFrame(1),'backgroundcolor'),'visible','off');
uicontrol('parent',gui.ActionFrame(2),'style','text','units','normalized','backgroundcolor',[0 0 0],'position',[0.05-.01 0.8-.02 0.05+.02 0.1+.04]);
gui.EndCap.leftBack(1)=uicontrol('parent',gui.ActionFrame(2),'style','text','units','normalized','backgroundcolor',[0 1 0],'position',[0.05 0.8 0.05 0.1],'callback',{@EndCapFunction,gui.fig});
gui.EndCap.leftBack(2)=uicontrol('parent',gui.ActionFrame(2),'style','slider','units','normalized','position',[0.15 0.8 0.3 0.1],'min',0,'max',255,'value',255,'sliderstep',[1/256 20/256],'callback',{@EndCapFunction,gui.fig});
gui.EndCap.leftBack(3)=uicontrol('parent',gui.ActionFrame(2),'style','edit','units','normalized','backgroundcolor','w','position',[0.15 0.65 0.1 0.14],'string','255','userdata',255,'callback',{@EndCapFunction,gui.fig});
gui.EndCap.leftBack(4)=uicontrol('parent',gui.ActionFrame(2),'style','pushbutton','units','normalized','fontweight','bold','position',[0.28 0.65 0.08 0.14],'string','Off','callback',{@EndCapFunction,gui.fig});
gui.EndCap.leftBack(5)=uicontrol('parent',gui.ActionFrame(2),'style','pushbutton','units','normalized','fontweight','bold','position',[0.37 0.65 0.08 0.14],'string','Max','callback',{@EndCapFunction,gui.fig});

uicontrol('parent',gui.ActionFrame(2),'style','text','units','normalized','backgroundcolor',[0 0 0],'position',[0.9-.01 0.8-.02 0.05+.02 0.1+.04]);
gui.EndCap.rightBack(1)=uicontrol('parent',gui.ActionFrame(2),'style','text','units','normalized','backgroundcolor',[0 1 0],'position',[0.9 0.8 0.05 0.1],'callback',{@EndCapFunction,gui.fig});
gui.EndCap.rightBack(2)=uicontrol('parent',gui.ActionFrame(2),'style','slider','units','normalized','position',[0.55 0.8 0.3 0.1],'min',0,'max',255,'value',255,'sliderstep',[1/256 20/256],'callback',{@EndCapFunction,gui.fig});
gui.EndCap.rightBack(3)=uicontrol('parent',gui.ActionFrame(2),'style','edit','units','normalized','backgroundcolor','w','position',[0.75 0.65 0.1 0.14],'string','255','userdata',255,'callback',{@EndCapFunction,gui.fig});
gui.EndCap.rightBack(4)=uicontrol('parent',gui.ActionFrame(2),'style','pushbutton','units','normalized','fontweight','bold','position',[0.55 0.65 0.08 0.14],'string','Off','callback',{@EndCapFunction,gui.fig});
gui.EndCap.rightBack(5)=uicontrol('parent',gui.ActionFrame(2),'style','pushbutton','units','normalized','fontweight','bold','position',[0.64 0.65 0.08 0.14],'string','Max','callback',{@EndCapFunction,gui.fig});

uicontrol('parent',gui.ActionFrame(2),'style','text','units','normalized','backgroundcolor',[0 0 0],'position',[0.05-.01 0.2-.02 0.05+.02 0.1+.04]);
gui.EndCap.leftFront(1)=uicontrol('parent',gui.ActionFrame(2),'style','text','units','normalized','backgroundcolor',[.7 .7 1],'position',[0.05 0.2 0.05 0.1],'callback',{@EndCapFunction,gui.fig});
gui.EndCap.leftFront(2)=uicontrol('parent',gui.ActionFrame(2),'style','slider','units','normalized','position',[0.15 0.2 0.3 0.1],'min',0,'max',255,'value',255,'sliderstep',[1/256 20/256],'callback',{@EndCapFunction,gui.fig});
gui.EndCap.leftFront(3)=uicontrol('parent',gui.ActionFrame(2),'style','edit','units','normalized','backgroundcolor','w','position',[0.15 0.31 0.1 0.14],'string','255','userdata',255,'callback',{@EndCapFunction,gui.fig});
gui.EndCap.leftFront(4)=uicontrol('parent',gui.ActionFrame(2),'style','pushbutton','units','normalized','fontweight','bold','position',[0.28 0.31 0.08 0.14],'string','Off','callback',{@EndCapFunction,gui.fig});
gui.EndCap.leftFront(5)=uicontrol('parent',gui.ActionFrame(2),'style','pushbutton','units','normalized','fontweight','bold','position',[0.37 0.31 0.08 0.14],'string','Max','callback',{@EndCapFunction,gui.fig});

uicontrol('parent',gui.ActionFrame(2),'style','text','units','normalized','backgroundcolor',[0 0 0],'position',[0.9-.01 0.2-.01 0.05+.02 0.1+.02]);
gui.EndCap.rightFront(1)=uicontrol('parent',gui.ActionFrame(2),'style','text','units','normalized','backgroundcolor',[.7 .7 1],'position',[0.9 0.2 0.05 0.1],'callback',{@EndCapFunction,gui.fig});
gui.EndCap.rightFront(2)=uicontrol('parent',gui.ActionFrame(2),'style','slider','units','normalized','position',[0.55 0.2 0.3 0.1],'min',0,'max',255,'value',255,'sliderstep',[1/256 20/256],'callback',{@EndCapFunction,gui.fig});
gui.EndCap.rightFront(3)=uicontrol('parent',gui.ActionFrame(2),'style','edit','units','normalized','backgroundcolor','w','position',[0.75 0.31 0.1 0.14],'string','255','userdata',255,'callback',{@EndCapFunction,gui.fig});
gui.EndCap.rightFront(4)=uicontrol('parent',gui.ActionFrame(2),'style','pushbutton','units','normalized','fontweight','bold','position',[0.55 0.31 0.08 0.14],'string','Off','callback',{@EndCapFunction,gui.fig});
gui.EndCap.rightFront(5)=uicontrol('parent',gui.ActionFrame(2),'style','pushbutton','units','normalized','fontweight','bold','position',[0.64 0.31 0.08 0.14],'string','Max','callback',{@EndCapFunction,gui.fig});

%Vibrator Motor Control---------------------------------------
gui.ActionFrame(3)=uipanel(gui.ActionAddFrame,'title','','unit','normalized','position',[.01 .12 .98 .75],'backgroundcolor',[1 .9 .7],'visible','off');
uicontrol(gui.ActionFrame(3),'style','Text','units','normalized','horizontalalignment','left',...
    'position',[0.01 0.7 .35 .15],'string','Intensity:','backgroundcolor',get(gui.ActionFrame(1),'backgroundcolor'),'fontsize',10,'fontweight','bold');
gui.Vibrate.Intensity=uicontrol(gui.ActionFrame(3),'style','popupmenu','units','normalized',...
    'position',[0.25 0.72 .24 .15],'string',{'100%','75%','50%','25%'},'fontweight','bold','backgroundcolor','w');
uicontrol(gui.ActionFrame(3),'style','Text','units','normalized','horizontalalignment','left',...
    'position',[0.01 0.55 .35 .13],'string','Duration (s):','backgroundcolor',get(gui.ActionFrame(1),'backgroundcolor'),'fontsize',10,'fontweight','bold');
gui.Vibrate.Duration=uicontrol(gui.ActionFrame(3),'style','Edit','units','normalized',...
    'position',[0.25 0.55 .14 .13],'string','0.5','fontweight','bold','backgroundcolor','w','userdata',0.5,'callback',{@VibrateCheck,gui.fig});
uicontrol(gui.ActionFrame(3),'style','Text','units','normalized','horizontalalignment','left',...
    'position',[0.1 0.1 .7 .3],'string',...
    'Duration should not exceed 2 seconds (motor may overheat)',...
    'backgroundcolor',get(gui.ActionFrame(3),'backgroundcolor'),'fontsize',8,'fontweight','bold');

%Linear Pattern Control
gui.ActionFrame(4)=uipanel(gui.ActionAddFrame,'title','','unit','normalized','position',[.01 .12 .98 .75],'backgroundcolor',[1 .9 .7],'visible','off');

uicontrol(gui.ActionFrame(4),'style','Text','units','normalized','horizontalalignment','left',...
    'position',[0.01 0.8 .35 .13],'string','Pattern ID:','backgroundcolor',get(gui.ActionFrame(1),'backgroundcolor'),'fontsize',10,'fontweight','bold');
gui.Pattern.ID=uicontrol(gui.ActionFrame(4),'style','Edit','units','normalized',...
    'position',[0.3 0.8 .1 .13],'string','0','fontweight','bold','backgroundcolor','w','userdata',0,'callback',{@PatternCheck,gui.fig});

uicontrol(gui.ActionFrame(4),'style','Text','units','normalized','horizontalalignment','left',...
    'position',[0.01 0.65 .35 .13],'string','Rate (ms/step):','backgroundcolor',get(gui.ActionFrame(1),'backgroundcolor'),'fontsize',10,'fontweight','bold');
gui.Pattern.Velocity=uicontrol(gui.ActionFrame(4),'style','Edit','units','normalized',...
    'position',[0.3 0.657 .2 .13],'string','20','fontweight','bold','backgroundcolor','w','userdata',20,'callback',{@PatternCheck,gui.fig});

uicontrol(gui.ActionFrame(4),'style','Text','units','normalized','horizontalalignment','left',...
    'position',[0.01 0.5 .35 .13],'string','Direction:','backgroundcolor',get(gui.ActionFrame(1),'backgroundcolor'),'fontsize',10,'fontweight','bold');
gui.Pattern.Direction=uicontrol(gui.ActionFrame(4),'style','popupmenu','units','normalized','horizontalalignment','left',...
    'position',[0.3 0.52 .35 .13],'string',{'Left to Right','Right to Left','Back & Forth','Forth & Back','Sweep Panel IDs','Bounce Panel IDs'},'fontweight','bold','backgroundcolor','w');

uicontrol(gui.ActionFrame(4),'style','Text','units','normalized','horizontalalignment','left',...
    'position',[0.01 0.35 .35 .13],'string','Offset:','backgroundcolor',get(gui.ActionFrame(1),'backgroundcolor'),'fontsize',10,'fontweight','bold');
gui.Pattern.Offset=uicontrol(gui.ActionFrame(4),'style','edit','units','normalized',...
    'position',[0.3 0.35 .1 .13],'string','0','fontweight','bold','backgroundcolor','w','userdata',0,'callback',{@PatternCheck,gui.fig});


%All Systems Clear
gui.ActionFrame(5)=uipanel(gui.ActionAddFrame,'title','','unit','normalized','position',[.01 .12 .98 .75],'backgroundcolor',[1 .9 .7],'visible','off');
uicontrol(gui.ActionFrame(5),'style','Text','units','normalized','horizontalalignment','left',...
    'position',[0.1 0.5 .8 .25],'string',...
    'Turn Off: End-Cap LEDs, Panels, Vibrator',...
    'backgroundcolor',get(gui.ActionFrame(1),'backgroundcolor'),'fontsize',8);


%End Sequence
gui.ActionFrame(6)=uipanel(gui.ActionAddFrame,'title','','unit','normalized','position',[.01 .12 .98 .75],'backgroundcolor',[1 .9 .7],'visible','off');
uicontrol(gui.ActionFrame(6),'style','Text','units','normalized','horizontalalignment','left',...
    'position',[0.1 0.5 .8 .25],'string',...
    'End Sequence',...
    'backgroundcolor',get(gui.ActionFrame(1),'backgroundcolor'),'fontsize',8);

for j=gui.ActionFrame
    for i=get(j,'children')
        set(i,'enable','off')
    end
end

% 
%List of available patterns (scrollable patch graphics with text labels)
gui.PatternFrame=uipanel('parent',gui.constructionPanel,'title','','units','normalized',...
    'position',[0.01 0.01 .98 .26],'backgroundcolor',[1 .8 .6]);
gui.PatternStorageAx=axes('parent',gui.PatternFrame,'units','normalized',...
    'position',[0.05 0.12 0.9 0.55],'visible','off','ydir','reverse');

%EDIT BOXES FOR 16-LEVEL PATTERN ENTRY
for i=1:8
    gui.PatternEntry(i)=uicontrol('parent',gui.PatternFrame,'style','edit','backgroundcolor','white','units','normalized',...
        'position',[0.01+.033*(i-1) 0.87 0.03 0.08],'string',0,'userdata',0);
end
for i=9:16
    gui.PatternEntry(i)=uicontrol('parent',gui.PatternFrame,'style','edit','backgroundcolor','white','units','normalized',...
        'position',[0.01+0.033*(i-1)+0.01 0.87 0.03 0.08],'string',0,'userdata',0);
end
for i=17:24
    gui.PatternEntry(i)=uicontrol('parent',gui.PatternFrame,'style','edit','backgroundcolor','white','units','normalized',...
        'position',[0.01+.033*(i-1)+.02 0.87 0.03 0.08],'string',0,'userdata',0);
end
for i=25:32
    gui.PatternEntry(i)=uicontrol('parent',gui.PatternFrame,'style','edit','backgroundcolor','white','units','normalized',...
        'position',[0.01+.033*(i-25)+.01 0.78 0.03 0.08],'string',0,'userdata',0);
end
for i=33:40
    gui.PatternEntry(i)=uicontrol('parent',gui.PatternFrame,'style','edit','backgroundcolor','white','units','normalized',...
        'position',[0.01+.033*(i-25)+.01+.01 0.78 0.03 0.08],'string',0,'userdata',0);
end
for i=41:48
    gui.PatternEntry(i)=uicontrol('parent',gui.PatternFrame,'style','edit','backgroundcolor','white','units','normalized',...
        'position',[0.01+.033*(i-25)+.02+.01 0.78 0.03 0.08],'string',0,'userdata',0);
end
for i=49:56
    gui.PatternEntry(i)=uicontrol('parent',gui.PatternFrame,'style','edit','backgroundcolor','white','units','normalized',...
        'position',[0.01+.033*(i-49)+.02 0.69 0.03 0.08],'string',0,'userdata',0);
end
for i=57:64
    gui.PatternEntry(i)=uicontrol('parent',gui.PatternFrame,'style','edit','backgroundcolor','white','units','normalized',...
        'position',[0.01+.033*(i-49)+.01+.02 0.69 0.03 0.08],'string',0,'userdata',0);
end
%Set Callbacks for 0-15 edit boxes
for i=1:64
    set(gui.PatternEntry(i),'callback',{@editPatternEntry,i,gui.fig})
end

nPatterns=25;
gui.nPatterns=nPatterns;
gui.PanelPatterns=zeros(gui.nPatterns,64,3);

gui.PanelPatterns(1,:,[1,3])=.4;
gui.SelectedPattern=1;

gui.PatternIm=image(gui.PanelPatterns);
set(gui.PatternStorageAx,'xlim',[.5 64.5],'ylim',[.5 6.5],'xtick',[1:64]-.5,'ytick',(1:gui.nPatterns)-.5,...
    'xticklabel',[],'yticklabel',[],'xgrid','on','ygrid','on','xcolor',[.4 .4 .4],'ycolor',[.4 .4 .4])
set(gui.PatternIm,'alphadata',.7,'cdatamapping','scaled','buttondownfcn',{@editPattern,gui.fig})

for i=0:(gui.nPatterns-1)
    gui.PatternID(i+1)=text(-1.5,i+1,num2str(i));
end
set(gui.PatternID(7:end),'visible','off')

line([1 1]*.5,[0 nPatterns+1],'color',[0 .5 0],'linewidth',2)
line([1 1]*8.5,[0 nPatterns+1],'color',[0 .5 0],'linewidth',2)
line([1 1]*16.5,[0 nPatterns+1],'color',[0 .5 0],'linewidth',2)
line([1 1]*24.5,[0 nPatterns+1],'color',[0 .5 0],'linewidth',2)
line([1 1]*32.5,[0 nPatterns+1],'color',[0 .5 0],'linewidth',2)
line([1 1]*40.5,[0 nPatterns+1],'color',[0 .5 0],'linewidth',2)
line([1 1]*48.5,[0 nPatterns+1],'color',[0 .5 0],'linewidth',2)
line([1 1]*56.5,[0 nPatterns+1],'color',[0 .5 0],'linewidth',2)
line([1 1]*64.5,[0 nPatterns+1],'color',[0 .5 0],'linewidth',2)

gui.PatternScrollUp=uicontrol('parent',gui.PatternFrame,'units','normalized','position',[0.96 0.85 0.03 0.1],'style','pushbutton','string','/\',...
    'fontweight','bold','callback',{@scrollPatternButtons,gui.fig});
gui.PatternScrollDown=uicontrol('parent',gui.PatternFrame,'units','normalized','position',[0.96 0.05 0.03 0.1],'style','pushbutton','string','\/',...
    'fontweight','bold','callback',{@scrollPatternButtons,gui.fig});

gui.PatternClear=uicontrol('parent',gui.PatternFrame,'units','normalized','position',[0.05 0.02 0.1 0.08],'style','pushbutton','string','Clear','fontweight','bold','callback',{@patternClearSet,gui.fig});
gui.PatternSet=uicontrol('parent',gui.PatternFrame,'units','normalized','position',[0.16 0.02 0.1 0.08],'style','pushbutton','string','Set','fontweight','bold','callback',{@patternClearSet,gui.fig});
gui.PatternInvert=uicontrol('parent',gui.PatternFrame,'units','normalized','position',[0.27 0.02 0.1 0.08],'style','pushbutton','string','Invert','fontweight','bold','callback',{@patternInvert,gui.fig});
gui.PatternRandom=uicontrol('parent',gui.PatternFrame,'units','normalized','position',[0.54 0.02 0.1 0.08],'style','pushbutton','string','Random','fontweight','bold','callback',{@patternRandom,gui.fig});
gui.PatternPrevious=uicontrol('parent',gui.PatternFrame,'units','normalized','position',[0.38 0.02 0.15 0.08],'style','pushbutton','string','Copy Previous','fontweight','bold','callback',{@patternPrevious,gui.fig});

%Frame for visualization of fixed (flash memory) patterns in the linear panels
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
gui.FlashPatternFrame = uipanel('parent',gui.constructionPanel,'title','','units','normalized','position',[0.01 0.01 .98 .26],'backgroundcolor',[1 .8 .6],'visible','off');
flashpatterns = load('linearcodes64.txt');
flashP=zeros(size(flashpatterns,1),64,3);
flashP(:,:,2) = flashpatterns;
gui.flashSize = size(flashpatterns,1);

gui.FlashPatternStorageAx=axes('parent',gui.FlashPatternFrame,'units','normalized',...
    'position',[0.05 0.05 0.9 0.9],'visible','off','ydir','reverse');

gui.FlashPatternIm=image(flashP/15);
set(gui.FlashPatternStorageAx,'xlim',[.5 64.5],'ylim',[.5 6.5],'xtick',[1:64]-.5,'ytick',(1:gui.nPatterns)-.5,...
    'xticklabel',[],'yticklabel',[],'xgrid','on','ygrid','on','xcolor',[.4 .4 .4],'ycolor',[.4 .4 .4])
set(gui.FlashPatternIm,'alphadata',.7,'cdatamapping','scaled')

for i=1:size(flashpatterns,1)
    gui.FlashPatternID(i)=text(-1.5,i,num2str(i+gui.nPatterns-1));
end
set(gui.FlashPatternID(7:end),'visible','off')

gui.FlashPatternScrollUp=uicontrol('parent',gui.FlashPatternFrame,'units','normalized',...
    'position',[0.96 0.85 0.03 0.1],'style','pushbutton','string','/\',...
    'fontweight','bold','callback',{@scrollPatternButtons,gui.fig});
gui.FlashPatternScrollDown=uicontrol('parent',gui.FlashPatternFrame,'units','normalized',...
    'position',[0.96 0.05 0.03 0.1],'style','pushbutton','string','\/',...
    'fontweight','bold','callback',{@scrollPatternButtons,gui.fig});

%Frame for graphical visualization of experiment
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
gui.VisFrame=uipanel('parent',gui.constructionPanel,'title','','units','normalized','position',[0.01 0.01 .98 .26],'backgroundcolor',[1 .8 .6],'visible','off');
gui.visAx=axes('parent',gui.VisFrame,'units','normalized','position',[0.05 0.15 0.9 0.83],'ytick',[],'color','none','box','on');
gui.visLeft=uicontrol('parent',gui.VisFrame,'units','normalized','position',[0.01 0.01 0.03 0.1],'style','pushbutton','string','<','fontweight','bold','callback',{@graphShift,gui.fig});
gui.visRight=uicontrol('parent',gui.VisFrame,'units','normalized','position',[0.96 0.01 0.03 0.1],'style','pushbutton','string','>','fontweight','bold','callback',{@graphShift,gui.fig});

gui.PatternSelect=uicontrol('parent',gui.constructionPanel,'style','toggle','units','normalized',...
     'position',[0.01 0.27 .1 .025],'string','Pattern Edit','fontweight','bold','value',1,'callback',{@patternGraph,gui.fig});
gui.FlashPatternSelect=uicontrol('parent',gui.constructionPanel,'style','toggle','units','normalized',...
     'position',[0.12 0.27 .15 .025],'string','Fixed Patterns','fontweight','bold','value',0,'callback',{@patternGraph,gui.fig});
gui.GraphSelect=uicontrol('parent',gui.constructionPanel,'style','toggle','units','normalized',...
     'position',[0.28 0.27 .1 .025],'string','Graph View','fontweight','bold','value',0,'callback',{@patternGraph,gui.fig});


%Menus for script saving and Loading (add buttonpress features for ctrl+s
%and ctrl+a and ctrl+o)
gui.FileMenu=uimenu('parent',gui.fig,'label','File','userdata',pwd);
gui.save=uimenu('parent',gui.FileMenu','label','Save Experiment','callback',{@saveExp,gui.fig});
gui.open=uimenu('parent',gui.FileMenu','label','Open Experiment','callback',{@loadExp,gui.fig});
gui.patternonly=uimenu('parent',gui.FileMenu','label','Load Patterns Only','separator','on','callback',{@loadPatterns,gui.fig});
gui.exponly=uimenu('parent',gui.FileMenu','label','Load Sequences Only','callback',{@loadActions,gui.fig});


set(gui.fig,'userdata',gui)

function scrollPatternButtons(obj,event,fig)
gui = get(fig,'userdata');

switch obj
    case gui.PatternScrollUp
        val.VerticalScrollCount = -1;
    case gui.PatternScrollDown
        val.VerticalScrollCount = 1;
    case gui.FlashPatternScrollUp
        val.VerticalScrollCount = -1;
    case gui.FlashPatternScrollDown
        val.VerticalScrollCount = 1;
end
patternScroll(obj,val,fig);


function PatternCheck(obj,event,fig)
gui=get(fig,'userdata');
switch obj
%     case gui.Pattern.ID
%         val=str2double(get(obj,'string'));
%         if isnan(val) 
%             set(obj,'string',num2str(get(obj,'userdata')));
%             val=get(obj,'userdata');
%         else
%             if val<0||val>gui.nPatterns
%                 set(obj,'string',num2str(get(obj,'userdata')));
%                 val=get(obj,'userdata');
%             else
%                 set(obj,'userdata',val)
%             end
%         end
%         val=round(val);
%         set(obj,'string',num2str(val),'userdata',val)
    case gui.Pattern.Offset
        val = str2double(get(obj,'string'));
        if isnan(val) 
            set(obj,'string',num2str(get(obj,'userdata')));
            val=get(obj,'userdata');
        end
        val=round(val);
        set(obj,'string',num2str(val),'userdata',val)
        
    case gui.Pattern.Velocity
        val=str2double(get(obj,'string'));
        if isnan(val) 
            set(obj,'string',num2str(get(obj,'userdata')));
            val=get(obj,'userdata');
        else
            if val<0|val>(2^12-1)
                set(obj,'string',num2str(get(obj,'userdata')));
                val=get(obj,'userdata');
            else
                set(obj,'userdata',val)
            end
        end
        set(obj,'string',num2str(val),'userdata',val)
end

function VibrateCheck(obj,event,fig)
    val=str2double(get(obj,'string'));
    if isnan(val) 
        set(obj,'string',num2str(get(obj,'userdata')));
        val=get(obj,'userdata');
    else
        if val<0||val>5
            set(obj,'string',num2str(get(obj,'userdata')));
            val=get(obj,'userdata');
        else
            set(obj,'userdata',val)
        end
    end
    val=round(val*10)/10;
    set(obj,'string',num2str(val),'userdata',val)


%handle internal consistancy of end cap gui
function EndCapFunction(obj,event,fig)
gui=get(fig,'userdata');

%error Checking
switch obj
    case gui.EndCap.leftBack(3)
        val=str2double(get(obj,'string'));
        if isnan(val) 
            set(obj,'string',num2str(get(obj,'userdata')));
            val=get(obj,'userdata');
        else
            if val<0||val>255
                set(obj,'string',num2str(get(obj,'userdata')));
                val=get(obj,'userdata');
            else
                set(obj,'userdata',val)
            end
        end
        set(gui.EndCap.leftBack(2),'value',val)
        set(gui.EndCap.leftBack(1),'backgroundcolor',[0 val/255 0])
    case gui.EndCap.leftBack(2)
        val=round(get(obj,'value'));
        set(gui.EndCap.leftBack(3),'string',num2str(val),'userdata',val)
        set(gui.EndCap.leftBack(2),'value',val)
        set(gui.EndCap.leftBack(1),'backgroundcolor',[0 val/255 0])
    case gui.EndCap.rightBack(3)
        val=str2double(get(obj,'string'));
        if isnan(val) 
            set(obj,'string',num2str(get(obj,'userdata')));
            val=get(obj,'userdata');
        else
            if val<0||val>255
                set(obj,'string',num2str(get(obj,'userdata')));
                val=get(obj,'userdata');
            else
                set(obj,'userdata',val)
            end
        end
        set(gui.EndCap.rightBack(2),'value',val)
        set(gui.EndCap.rightBack(1),'backgroundcolor',[0 val/255 0])
    case gui.EndCap.rightBack(2)
        val=round(get(obj,'value'));
        set(gui.EndCap.rightBack(3),'string',num2str(val),'userdata',val)
        set(gui.EndCap.rightBack(2),'value',val)
        set(gui.EndCap.rightBack(1),'backgroundcolor',[0 val/255 0])
    case gui.EndCap.leftFront(3)
        val=str2double(get(obj,'string'));
        if isnan(val) 
            set(obj,'string',num2str(get(obj,'userdata')));
            val=get(obj,'userdata');
        else
            if val<0||val>255
                set(obj,'string',num2str(get(obj,'userdata')));
                val=get(obj,'userdata');
            else
                set(obj,'userdata',val)
            end
        end
        set(gui.EndCap.leftFront(2),'value',val)
        set(gui.EndCap.leftFront(1),'backgroundcolor',[.7 .7 1]*val/255)
    case gui.EndCap.leftFront(2)
        val=round(get(obj,'value'));
        set(gui.EndCap.leftFront(3),'string',num2str(val),'userdata',val)
        set(gui.EndCap.leftFront(2),'value',val)
        set(gui.EndCap.leftFront(1),'backgroundcolor',[.7 .7 1]*val/255)
    case gui.EndCap.rightFront(3)
        val=str2double(get(obj,'string'));
        if isnan(val) 
            set(obj,'string',num2str(get(obj,'userdata')));
            val=get(obj,'userdata');
        else
            if val<0||val>255
                set(obj,'string',num2str(get(obj,'userdata')));
                val=get(obj,'userdata');
            else
                set(obj,'userdata',val)
            end
        end
        set(gui.EndCap.rightFront(2),'value',val)
        set(gui.EndCap.rightFront(1),'backgroundcolor',[.7 .7 1]*val/255)
    case gui.EndCap.rightFront(2)
        val=round(get(obj,'value'));
        set(gui.EndCap.rightFront(3),'string',num2str(val),'userdata',val)
        set(gui.EndCap.rightFront(2),'value',val)
        set(gui.EndCap.rightFront(1),'backgroundcolor',[.7 .7 1]*val/255)
    case gui.EndCap.leftBack(4)
        set(gui.EndCap.leftBack(2),'value',0)
        set(gui.EndCap.leftBack(3),'string','0','userdata',0)
        set(gui.EndCap.leftBack(1),'backgroundcolor',[0 0/255 0])
    case gui.EndCap.leftBack(5)
        set(gui.EndCap.leftBack(2),'value',255)
        set(gui.EndCap.leftBack(3),'string','255','userdata',255)
        set(gui.EndCap.leftBack(1),'backgroundcolor',[0 255/255 0])
    case gui.EndCap.rightBack(4)
        set(gui.EndCap.rightBack(2),'value',0)
        set(gui.EndCap.rightBack(3),'string','0','userdata',0)
        set(gui.EndCap.rightBack(1),'backgroundcolor',[0 0/255 0])
    case gui.EndCap.rightBack(5)
        set(gui.EndCap.rightBack(2),'value',255)
        set(gui.EndCap.rightBack(3),'string','255','userdata',255)
        set(gui.EndCap.rightBack(1),'backgroundcolor',[0 255/255 0])
    case gui.EndCap.leftFront(4)
        set(gui.EndCap.leftFront(2),'value',0)
        set(gui.EndCap.leftFront(3),'string','0','userdata',0)
        set(gui.EndCap.leftFront(1),'backgroundcolor',[.7 .7 1]*0/255)
    case gui.EndCap.leftFront(5)
        set(gui.EndCap.leftFront(2),'value',255)
        set(gui.EndCap.leftFront(3),'string','255','userdata',255)
        set(gui.EndCap.leftFront(1),'backgroundcolor',[.7 .7 1]*255/255)
    case gui.EndCap.rightFront(4)
        set(gui.EndCap.rightFront(2),'value',0)
        set(gui.EndCap.rightFront(3),'string','0','userdata',0)
        set(gui.EndCap.rightFront(1),'backgroundcolor',[.7 .7 1]*0/255)
    case gui.EndCap.rightFront(5)
        set(gui.EndCap.rightFront(2),'value',255)
        set(gui.EndCap.rightFront(3),'string','255','userdata',255)
        set(gui.EndCap.rightFront(1),'backgroundcolor',[.7 .7 1]*255/255)
end




%EOF