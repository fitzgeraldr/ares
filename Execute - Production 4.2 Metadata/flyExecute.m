%% function flyExecute Version 3.2
% Author: Magnus Karlsson
% Date: December 14, 2011
%
% Added MCU I2C hang detection and reporting
%
%% function flyExecute Version 3.1
% Authors: Lakshmi Ramasamy & Magnus Karlsson 
% Date: June 15th 2011
% 
% Major changes made in this version are listed below
% >Replaced serial port access method. i.e., serial port is now accessed
% via MATLAB object instead of our own driver (Ftdiserial.dll) written by
% Gus Lott III
% >exec_BAF function is now defined at the begining of the program call to
% function (OlympiadExecuteAgent)

%% Version: 3.0
% Authors: Lakshmi Ramasamy & Kristin Branson
% Date: April 5th 2011
% The code was modified to integrate JGrid metadata tool on to the Box GUI

%% Version 2.0 & Earlier
% Author: Gus K Lott III, PhD
%
% - Add calibration button that runs system through controlled ascents to
% temperature values between 19 and 36 to give it a learned value to settle
% to.
%
% - Add Verification button that turns off back light and cycles the panels
% and end caps through their behaviors in rapid sucession (governed by the
% MCU)



function flyExecute(varargin)
% WR: set path to current directory and subdirectories
addpath(genpath(pwd))
% WR: remove all svn garbage from the path
% rmSvnPath()

% WR: add java paths necessary for FlyBoyQuery
thisPath = mfilename('fullpath');
parentDir = fileparts(thisPath);
jarpath = fullfile(parentDir, 'mysql-connector-java-5.0.8-bin.jar');
if ~ismember(jarpath,javaclasspath)
    javaaddpath(jarpath, '-end');
end

switch nargin
    case 0
        makegui('3.2');
        TemperatureConnect;
    otherwise
        switch varargin{1}
            case 'visExp'
                visExp(varargin{2},varargin{3})
        end
        %receive string input to call a file name from another program
       

end


%Main prep/cleanup of experiment
function ExecuteExperiment(~,~,fig,fleacam)
global gui handles; %Code modified in V3.0

%Code modified in V3.0
%Code change begins
% sample temperature and humidity data from the precon sensor
out = THSampler('precon', 'COM8');
fclose(serial('COM8'));
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

for count=1:1:handles.ntubes
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.cross_barcode', count)).attribute.appear_basic = 'true, readonly';
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.cross_barcode', count)).attribute.appear_advanced = 'true, readonly';
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.line', count)).attribute.appear_basic = 'true, readonly';
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.line', count)).attribute.appear_advanced = 'true, readonly';
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.effector', count)).attribute.appear_basic = 'true, readonly';
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.effector', count)).attribute.appear_advanced = 'true, readonly';
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.genotype', count)).attribute.appear_basic = 'true, readonly';
handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.genotype', count)).attribute.appear_advanced = 'true, readonly';
end
handles.pgrid.setDefaultsTree(handles.defaultsTree,handles.mode);
%Code change ends


gui=get(fig,'userdata');
switch get(gui.ExperimentGo,'value') %bascam
    case 1 %Prep and Execute Experiment
        str=get(gui.UserID,'string'); 
%         if isempty(str)
%             errordlg('Enter Operator Initials','Operator Name')
%             set(gui.ExperimentGo,'value',0)
%             return
%         end
        clc
        set(gui.ExperimentGo,'enable','off')
        drawnow
        set(gui.ExperimentGo,'enable','on')
        %Grab Experiment Struct, check for video towards target
        experiment=get(gui.SequenceOrder,'userdata');
        if isempty(experiment); set(gui.ExperimentGo,'value',0); return; end
        set(0,'userdata',[])
        
        delete(findobj('tag','expStatLine'))
        
        set(gui.ExperimentGo,'backgroundcolor',[.2 .9 .2])
        set([gui.openExp gui.SetDir gui.ExpName gui.TemperatureTarget],'enable','off')
        
        %Generate Base Directory for experiment based on unique date/time
        thistime=datestr(now,30);
        set(gui.SetDir,'userdata','C:\');
        expdir=[get(gui.SetDir,'userdata'),get(gui.ExpName,'string'),'_',thistime];
        mkdir(expdir);
        
        %Copy over ROI.txt file
        %         dos(sprintf('copy %s %s','ROI.txt',fullfile(expdir,'ROI.txt')));
        fin = fopen('ROI.txt','r');
        roiContents = fread(fin);
        fclose(fin);
        fout = fopen(fullfile(expdir,'ROI.txt'),'w');
        fwrite(fout,char(roiContents));
        fclose(fout);
        
        
        %Prep folders for all sequences
        for i=1:length(experiment.actionlist)
            expstate.dir(i).name=[sprintf('%02d',i),'_',experiment.actionlist(i).name,'_',...
                num2str(experiment.actionlist(i).T)];
            mkdir(expdir,expstate.dir(i).name);
        end
        
        expstate.start=thistime;
        expstate.expdir=expdir;
        expstate.i=0;
        expstate.sv=1;
        expstate.tr=0;
        expstate.startTimes=[];
        expstate.stopTimes=0;
        expstate.BAFtime = 0;
        expstate.forceSeq = 0;
        expstate.haltEarly = 0;
        
        expstate.dbstate = -1;
        
        % KB: store start time in defaultsTree immediately
        exp_datetime = expstate.start;
        handles.pgrid.setValueByPathString('exp_datetime',exp_datetime);
        
        %reset timers
        stop(gui.ai)
        set(gui.SeqTime,'string','0:00:00')
        set(gui.TotalTime,'string','Total: [0:00:00]')
        set([gui.Tsp,gui.TPl,gui.controlPlot],'xdata',nan,'ydata',nan)
        if gui.c
            set(gui.calPl,'xdata',nan,'ydata',nan)
        end
        set(gui.TiltPl,'xdata',nan,'ydata',nan)
        set(gui.stateLine,'xdata',nan,'ydata',nan)
        
        
        start(gui.ai)
        %Create experiment Agent
        delete(timerfind('tag','OlympiadAgent'));
        agent=timer('startdelay',1,'busymode','queue','period',1.5,'executionmode','fixedSpacing','tag','OlympiadAgent');
        set(agent,'timerfcn',{@OlympiadExecuteAgent,gui.fig,fleacam},'TasksToExecute',inf)
        expstate.dbstate = -2;
        %reset AI and start agent timer (will start 1 minute later)
        set(agent,'userdata',expstate)
        stop(gui.ai); start(gui.ai); start(agent);
        
    case 0
        expstate=get(timerfind('tag','OlympiadAgent'),'userdata');
        expstate.sv=3;
        expstate.haltEarly = 1;
        set(timerfind('tag','OlympiadAgent'),'userdata',expstate)
        disp('Experiment Halted Manually')
        stop(gui.vi);
        fleacam.stopCapture();
        fleacam.disableLogging();
        flushdata(gui.vi);
        logger = get(gui.vi,'userdata');
        if ~isempty(logger)
            for i=1:length(logger)
                try
                    logger(i).aviobj=close(logger(i).aviobj);
                end
            end
        end
        set(gui.vidMode,'string','Previewing','backgroundcolor','r') %bascam
        set(gui.vidFile,'string','')
        set(gui.vidFrameRate,'string','')
        set(gui.ExperimentGo,'backgroundcolor',[.9 .2 .2])
        set([gui.openExp gui.SetDir gui.ExpName gui.TemperatureTarget],'enable','on')
        
        fleacam.startCapture();
        
        if strcmpi(gui.vi.Running,'on')
            stop(gui.vi)
        end
        
        fclose(gui.MCU)
        gui.MCU.BytesavailableFcn='';
        fopen(gui.MCU)
        fwrite(gui.MCU,254);
        
        try expVidStop(gui.vi,'',gui.fig); end
end

%for cleanup when video system is stopped by command button
function expVidStop(obj,event,fig)
logger=get(obj,'userdata');
if ~isempty(logger)
    for j=1:size(logger,2)
        for i=1:size(logger,1)
            logger(i,j)=close(logger(i,j));
        end
    end
end
logger=get(obj,'disklogger');
if ~isempty(logger)
    logger=close(logger);
    
fleacam.stopCapture();
fleacam.disableLogging();
fleacam.disconnect(); %fleacam
end

function TEMP_SAF(obj,event,fig)
gui=get(fig,'userdata');

%This switch statement is a box dependent way of achieving target
%temperature on a calibrated thermocouple in the tube field relative to the
%steady state value seen at the raw temperature sensor in the dummy tube
%
% I can't use the box ID number here because you may not be connected to
% the box yet.  The serial number is loaded when the software starts.
switch gui.snum
    case 20563085 %Calibration top plate
    case 20563395 %zeus
        calibratezz=1;      %0 is no calibration, 1 is measured calibraion, 2 is offset correction
        dispzzcalib=0;      %0is no display, 1 is display to command window output
        zzcalOffset = -.4;
    case 20983739 %orion
        calibratezz=1;
        dispzzcalib=0;
        zzcalOffset = -.4;
    case 21023991 %athena
        calibratezz=1;
        dispzzcalib=0;
        zzcalOffset = -.4;
    case 21002361 %apollo
        calibratezz=1;
        dispzzcalib=0;
        zzcalOffset = -.4;
    case 19764821 %Ares
        calibratezz=1;
        dispzzcalib=0;
        zzcalOffset = -.4;
end
%added warning 20110510 to prevent box from running uncalibrated - WR
if (calibratezz==0)
    disp(['WARNING: NO TEMPERATURE CALIBRATION IS BEING USED.']);
end
%end of addition

%Code modified in V3.0
%Code change begins
gui.calibratezz = calibratezz;
gui.zzcalOffset = zzcalOffset;
%Code change ends

backtime = gui.backtime;
[data time]=getdata(obj,obj.samplesacquiredfcncount);

if isempty(gui) return; end
data=(data/127e3+2.5/30.9e3)*15.21e3; %correction due to extraction of resistors in NIDAQ
data = data*100; %Conversion for LM35 Temp sensors (10mV/degree)

% figure(10)
% plot(data(:,1:2))
% set(gca,'ylim',[22 26])

if ~gui.c
    accel = data(:,3:end)/100;
end

data=mean(data,1);
time=time(end)/60;

%Uncomment this to spam data to the screen, raw sensor values
% disp(data(1:2))
if dispzzcalib==1
    disp(['raw= ',num2str(data (1:2))])
end

%extract calibration channels
if gui.c
    %Calibrate to calibration top plate values
    for i=1:8
        %         data(i)=interp1(gui.Cal(:,i),gui.NIST(:,i),data(i),'linear','extrap');
        pfit = polyfit(gui.Cal(:,i),gui.NIST(:,i),1);
        data(i) = pfit(1)*data(i)+pfit(2); %y=m*x+b
    end
    calChans = data(3:end);
    data = data([1,2]);
else
    % apply calibration data if there is any
    %     gui.Cal=gui.Cal(:,2:-1:1); %if the probes were switched
    if dispzzcalib==1
        rawtemp=data(1:2);
    end
    for i=1:2
        if calibratezz==1
            %Linear interpolation between points with extrapolation
            %         data(i)=interp1(gui.Cal(:,i),gui.NIST(:,i),data(i),'linear','extrap');
            
            %Linear Regression to data
            pfit = polyfit(gui.Cal(:,i),gui.NIST(:,i),1);  %original
%             pfit = polyfit(gui.NIST(:,i),gui.Cal(:,i),1);   %test-transpose x and y
            data(i) = pfit(1)*data(i)+pfit(2); %y=m*x+b
            
            if dispzzcalib==1
                
                fprintf('calibrate');
            end
            
        elseif calibratezz==2
            data(i)=data(i)+zzcalOffset;  %tuned at 34 based on wlk recording 2/2/10 zeus
            if dispzzcalib==1
                           fprintf('offset');
            end
        else
            if dispzzcalib==1
                               fprintf('raw');
            end
        end
        
    end
    if dispzzcalib==1
          disp(data(1:2))
    end
    %extract Accelerometer Values4
    
    
    var = max(accel)-min(accel);  %the extent of the acceleration data (mean invariant measure)
    rawaccel = accel;
    mean(accel,1);
    data = data([1,2]);
    for i = 1:3
        xdat = get(gui.TiltPl(i),'xdata');
        ydat = get(gui.TiltPl(i),'ydata');
        ydat = [ydat,var(i)];
        xdat = [xdat,time];
        set(gui.TiltPl(i),'xdata',xdat,'ydata',ydat)
        %         set(gui.TiltPl(i),'xdata',linspace(time-backtime,time,length(accel)),'ydata',accel(:,i))
    end
    ylim = 2;
    set(gui.TiltAx,'ylim',[0 ylim],'xlim',[time-backtime time])
    set(gui.TiltAx,'ytick',linspace(0,ylim,11),'yticklabel','','ygrid','on')
    %     set(gui.TiltAx,'ytick',0:5,'yticklabel','','ygrid','on')
    set(gui.TiltVal,'string',num2str(round(sqrt(sum(var.^2))*1000)/1000))
    set(gui.TiltVal,'string',num2str(round(var(1)*1000)/1000))
    
    %for debugging acceleration values
    if var>.5; disp(num2str(round(var(1)*1000)/1000));
        previousVal = get(0,'userdata');
        set(0,'userdata',[previousVal, accel(:,1)])
    end
end

set(gui.TemperatureNow,'string',sprintf('%0.2f',mean(data)))

%Set Point Graph Update
sp=str2double(get(gui.TemperatureTarget,'string'));
% sp = get(gui.TemperatureTarget,'userdata');
dat=get(gui.Tsp,'ydata');
dat=[dat,sp];
t=get(gui.Tsp,'xdata');
t=[t,time];
set(gui.Tsp,'ydata',dat,'xdata',t)

%Current Temp Graph for 2 channels
for i = 1:2
    dat=get(gui.TPl(i),'ydata');
    dat=[dat,data(i)];
    t=get(gui.TPl(i),'xdata');
    t=[t,time];
    set(gui.TPl(i),'ydata',dat,'xdata',t);
end

%expstate graph update
dat = get(gui.stateLine,'ydata');
t = get(gui.stateLine,'xdata');
tmr = timerfind('tag','OlympiadAgent');
if isempty(tmr)
    dat = [dat,dat(end)];
    t = [t,time];
else
    expstate = get(tmr,'userdata');
    if isempty(expstate)
        dat = [dat,dat(end)];
        t = [t,time];
    else
        dat = [dat,expstate.i-.5*(2-expstate.sv)+18];
        t = [t,time];
    end
end
set(gui.stateLine,'ydata',dat,'xdata',t)

%update calibration plot channels
if gui.c
    for i=1:6
        dat=get(gui.calPl(i),'ydata');
        dat=[dat,calChans(i)];
        t=get(gui.calPl(i),'xdata');
        t=[t,time];
        set(gui.calPl(i),'ydata',dat,'xdata',t);
    end
end



%Hand temperature value to GUI struct so the video writer can access
gui.tempVALUE = mean(data);
set(gui.fig,'userdata',gui)

%Execute Thermal Control Algorithm
learned = [];
TC=get(gui.Tsp,'userdata');
if ~isnan(sp)
    [TC.cs TC.e TC.Tdt learned offset]=OlympiadHeatControl(TC.cs,sp,mean(data),TC.e,TC.scale,TC.Tdt,learned);
end

set(gui.Tsp,'userdata',TC);



val = TC.cs/100;
if val>=0
    c='r';
else
    c='b';
end
set(gui.CSpatch,'ydata',[0 0 1 1]*val,'facecolor',c);
set(gui.csText,'string',num2str(round(TC.cs*10)/10))

if ~isempty(gui.HEAT)
    fwrite(gui.HEAT,TC.cs+100);
    
    %set offsets
    if offset(1)
        fwrite(gui.HEAT,offset(1)+211);
        %set(gui.HEAT.Source,'WriteBuffer',offset(1)+211);
    else
        fwrite(gui.HEAT,offset(2)+233);
        %set(gui.HEAT.Source,'WriteBuffer',offset(2)+233);
    end
end

%Track Control Signal
dat=get(gui.controlPlot,'ydata');
newval = ((TC.cs+100)/200)*(36-18)+18;
dat = [dat, newval];
t = get(gui.controlPlot,'xdata');
t = [t, time];
set(gui.controlPlot,'xdata',t,'ydata',dat)

%Handle Axis shape
xlim = [time-backtime time];

j = 0;
xtick = (-100:(5^j):5000);
xtick = xtick(xtick>xlim(1)&xtick<xlim(2));
j = j+1;

while length(xtick)>10
    xtick = (-100:(5^j):5000);
    xtick = xtick(xtick>xlim(1)&xtick<xlim(2));
    j = j+1;
end

set(gui.TAx,'xlim',xlim,'xtick',xtick,...
    'ylim',[18 36])

if get(gui.ExperimentGo,'value')
    eTime=gui.ai.SamplesAcquired/gui.ai.Samplerate;
    hour=floor(eTime/3600);
    minutes=floor((eTime-hour*3600)/60);
    sec=floor(eTime-hour*3600-minutes*60);
    set(gui.TotalTime,'string',sprintf('Total: [%d:%02d:%02d]',hour,minutes,sec))
end

function popTemperature(obj,event,fig)
gui = get(fig,'userdata');

switch get(obj,'value')
    case 0
        oldfig = get(obj,'userdata');
        set(obj,'userdata',gui.fig)
        set(gui.TPanel,'parent',gui.fig,'units','pixels','position',[5 500 595 200])
        delete(oldfig);
    case 1
        newfig = figure('closerequestfcn',{@closePopFig,obj,gui.fig},'numbertitle','off','name','Olympiad Phototaxis Temperature Control System');
        set(newfig,'WindowScrollWheelFcn',{@ScrollFcn,gui.fig})
        set(obj,'userdata',newfig)
        set(gui.TPanel,'parent',newfig,'units','normalized','position',[0 0 1 1])
end

function closePopFig(obj,event,button,fig)
set(button,'value',0)
popTemperature(button,'',fig)

function targetchange(obj,event,fig)
gui= get(fig,'userdata');
TC=get(gui.Tsp,'userdata');
TC.Tdt = 0;

sp = str2double(get(obj,'string'));
if isnan(sp)
    set(obj,'string',num2str(get(obj,'userdata')))
else
    set(obj,'userdata',sp)
end

roomtemp = 26.5;
if (sp<roomtemp)&&(TC.cs>0)
    TC.cs = -10;
end
set(gui.Tsp,'userdata',TC)

%Load an *.exp file
function LoadExperiment(obj,event,fig)
gui=get(fig,'userdata');
[fname, pname] = uigetfile('*.exp','Load a Saved Experiment File',...
    get(gui.FileMenu,'userdata'));
if isequal(fname,0) || isequal(pname,0)
    return
end
set(gui.FileMenu,'userdata',pname)
load(fullfile(pname,fname),'-mat')

%Fill out experiment list and store experiment struct
set(gui.visTimeLine,'xdata',[0 0])
s=length(experiment.actionsource);
dat={};
for i=1:s
    dat=cat(1,dat,{experiment.actionlist(i).name,experiment.actionlist(i).T,...
        false,experiment.actionlist(i).Vid});
end
%Select first entry and construct
dat{1,3}=true;


%make sure all actions are in appropriate time order
for i=1:length(experiment.actionlist)
    action=experiment.actionlist(i).action;
    sorttimes=cell2mat({action.time});
    [val,ind]=sort(sorttimes);
    action=action(ind);
    experiment.actionlist(i).action=action;
end
set(gui.SequenceOrder,'data',dat,'userdata',experiment)

%Update display with first experiment
visExp(experiment.actionlist(1).action,gui.fig)

%Prep Patterns for Upload
patterninds=0:24; %(zero indexed patterns on controller)
pattern.inds=patterninds;
pattern.vals=patterns;
for i=1:length(pattern.inds)
    for j = 1:2:63
        pattern.bytes(i,(j+1)/2) = pattern.vals(pattern.inds(i)+1,j)*16+pattern.vals(pattern.inds(i)+1,j+1);
    end
end

sz=size(patterns);
c=zeros(sz(1),sz(2),3);
c(:,:,2)=patterns/15;
delete(get(gui.patternAx,'children'));
image(c,'parent',gui.patternAx,'alphadata',1);

set(gui.patternAx,'xtick',[1:8:64]-.5,'xticklabel',[],'ytick',[1:100]-.5,'ylim',[1 5]-.5,'xlim',[1 64]-.5,'xgrid','on','ygrid','on',...
    'userdata',pattern)
set(gui.fig,'userdata',gui)

%Update Experiment Visualization Display
function visExp(action,fig)
gui=get(fig,'userdata');
a=get(gui.visAx,'children');
a=a(a~=gui.visTimeLine);
delete(a)

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

%Save Tube Data as it is updated
function saveTubes(obj,event,fig)
gui=get(fig,'userdata');
try delete('gOlympTubes.cfg'); end

for i=1:6
    config.tube(i).Genotype=get(gui.tube(i).Genotype,'value');
    config.tube(i).Gender=get(gui.tube(i).Gender,'value');
    config.tube(i).Rearing=get(gui.tube(i).Rearing,'value');
    config.tube(i).n=get(gui.tube(i).n,'string');
    config.tube(i).n_dead=get(gui.tube(i).n_dead,'string');
    config.tube(i).DOB=get(gui.tube(i).DOB,'string');
    config.tube(i).Starved=get(gui.tube(i).Starved,'string');
end

save('gOlympTubes.cfg','config','-MAT')

%Auto-load tube data on startup
function tubeDataLoad(obj,event,fig)
global handles gui;
gui=get(fig,'userdata');
load('gOlympTubes.cfg','-MAT');

genString = get(gui.tube(1).Genotype,'string');
rearString = get(gui.tube(1).Rearing,'string');

for i=1:6
    if config.tube(i).Genotype > length(genString)
        config.tube(i).Genotype = 1;
    end
    set(gui.tube(i).Genotype,'value',config.tube(i).Genotype)
    set(gui.tube(i).Gender,'value',config.tube(i).Gender)
    if config.tube(i).Rearing > length(rearString)
        config.tube(i).Rearing = 1;
    end
    set(gui.tube(i).Rearing,'value',config.tube(i).Rearing)
    set(gui.tube(i).n,'string',config.tube(i).n)
    set(gui.tube(i).n_dead,'string',config.tube(i).n_dead)
    set(gui.tube(i).DOB,'string',config.tube(i).DOB)
    set(gui.tube(i).Starved,'string',config.tube(i).Starved)
end

%Extract string associated w/ genotype selection
gInd = get(gui.tube(1).Genotype,'value');
s = get(gui.tube(1).Genotype,'string');
s=s{gInd};

s = ['GMR_',s]; %prepend GMR

loc = strfind(s,'&'); %Copy only up to the & in the name
if ~isempty(loc)
    s = s(1:(loc(1)-2));
end
set(gui.ExpName,'string',s) %Set experiment name
CopyXmlDataToGui();


%Copy Previous Tube Data from GUI
function copyTube(obj,event,fig,ind)
gui=get(fig,'userdata');

set(gui.tube(ind+1).Genotype,'value',get(gui.tube(ind).Genotype,'value'))
set(gui.tube(ind+1).Gender,'value',get(gui.tube(ind).Gender,'value'))
set(gui.tube(ind+1).Rearing,'value',get(gui.tube(ind).Rearing,'value'))
set(gui.tube(ind+1).n,'string',get(gui.tube(ind).n,'string'))
set(gui.tube(ind+1).n_dead,'string',get(gui.tube(ind).n_dead,'string'))
set(gui.tube(ind+1).DOB,'string',get(gui.tube(ind).DOB,'string'))
set(gui.tube(ind+1).Starved,'string',get(gui.tube(ind).Starved,'string'))

saveTubes([],[],fig);

function copyTubeAll(~,~,fig)
gui=get(fig,'userdata');

%Populate down the entire list from tube 1
for ind = 1:5
    set(gui.tube(ind+1).Genotype,'value',get(gui.tube(ind).Genotype,'value'))
    set(gui.tube(ind+1).Gender,'value',get(gui.tube(ind).Gender,'value'))
    set(gui.tube(ind+1).Rearing,'value',get(gui.tube(ind).Rearing,'value'))
    set(gui.tube(ind+1).n,'string',get(gui.tube(ind).n,'string'))
    set(gui.tube(ind+1).n_dead,'string',get(gui.tube(ind).n_dead,'string'))
    set(gui.tube(ind+1).DOB,'string',get(gui.tube(ind).DOB,'string'))
    set(gui.tube(ind+1).Starved,'string',get(gui.tube(ind).Starved,'string'))
end

%Extract string associated w/ genotype selection
gInd = get(gui.tube(1).Genotype,'value');
s = get(gui.tube(1).Genotype,'string');
s=s{gInd};

s = ['GMR_',s]; %prepend GMR to filename...don't think this is used now


loc = strfind(s,'&'); %Copy only up to the & in the name
if ~isempty(loc)
    s = s(1:(loc(1)-2));
end

set(gui.ExpName,'string',s) %Set experiment name
saveTubes([],[],fig);  %Log tube state to file so that it is the same on restart




%_______________________________________________________________________________________________________
%Camera Configuration Handling Section

%_________________________________________________________________________________________
%Change Configuration Properties in Camera
%bascam
function ConfigCam(obj,event,fig)



gui=get(fig,'userdata');
switch obj
    case gui.ROI
        try
            ROI=str2num(get(gui.ROI,'string'));
            if ~isempty(ROI); set(gui.vi,'ROIPosition',ROI); end
            set(gui.ROI,'string',num2str(get(gui.vi,'ROIPosition')))
        end
        ROI=get(gui.vi,'ROIPosition');
        set(gui.ROI,'string',num2str(ROI))
        set(gui.vidAx,'xlim',[-ROI(1) -ROI(1)+655])
        set(gui.vidAx,'ylim',[-ROI(2) -ROI(2)+490])
        if get(gui.subROI,'value')
            drawSubROI(ROI,fig)
        end
        setCross(obj,event,fig)
    case gui.ROIReset
        ROI=[0 0 656 491];
        set(gui.vi,'ROIPosition',ROI)
        set(gui.vidAx,'xlim',[1 656],'ylim',[1 491])
        set(gui.ROI,'string',num2str(ROI))
        if get(gui.subROI,'value')
            drawSubROI(ROI,fig)
        end
        setCross(obj,event,fig)
    case gui.Bright
        try
            B=str2num(get(gui.Bright,'string'));
            if ~isempty(B); set(getselectedsource(gui.vi),'Brightness',B); end
            set(gui.Bright,'string',get(getselectedsource(gui.vi),'Brightness'))
        end
        B=get(getselectedsource(gui.vi),'Brightness');
        set(gui.Bright,'string',num2str(B))
    case gui.Gain
        try
            G=str2num(get(gui.Gain,'string'));
            if ~isempty(G); set(getselectedsource(gui.vi),'Gain',G); end
            set(gui.Gain,'string',get(getselectedsource(gui.vi),'Gain'))
        end
        G=get(getselectedsource(gui.vi),'Gain');
        set(gui.Gain,'string',num2str(G))
    case gui.Shutter
        try
            S=str2num(get(gui.Shutter,'string'));
            if ~isempty(S); set(getselectedsource(gui.vi),'Shutter',S); end
            set(gui.Shutter,'string',get(getselectedsource(gui.vi),'Shutter'))
        end
        S=get(getselectedsource(gui.vi),'Shutter');
        set(gui.Shutter,'string',num2str(S))
end

%_________________________________________________________________________________________
%draw regions as defined in gui.subROI userdata "bounds" struct
function drawSubROI(ROI,fig)
gui=get(fig,'userdata');

bounds=get(gui.subROI,'userdata');
delete(findobj('type','line','parent',gui.vidAx,'tag','TubeROIBox'))
b=bounds.b;
% b(:,1)=b(:,1)-ROI(1);
% b(:,2)=b(:,2)-ROI(2);
for i=1:6
    a(1)=line([b(i,1) b(i,1)+b(i,3)],[b(i,2) b(i,2)],'color','r','linewidth',1,'parent',gui.vidAx);
    a(2)=line([b(i,1) b(i,1)],[b(i,2) b(i,2)+b(i,4)],'color','r','linewidth',1,'parent',gui.vidAx);
    a(3)=line([b(i,1)+b(i,3) b(i,1)+b(i,3)],[b(i,2) b(i,2)+b(i,4)],'color','r','linewidth',1,'parent',gui.vidAx);
    a(4)=line([b(i,1) b(i,1)+b(i,3)],[b(i,2)+b(i,4) b(i,2)+b(i,4)],'color','r','linewidth',1,'parent',gui.vidAx);
    set(a,'tag','TubeROIBox')
end
bounds.ROI=ROI;
set(gui.subROI,'userdata',bounds)

%_________________________________________________________________________________________
%respond to browse button for sub-rois
function subROIBrowse(obj,event,fig)
gui=get(fig,'userdata');

[fname, pname] = uigetfile('*.txt','Load ROI Definitions');
if isequal(fname,0) || isequal(pname,0)
    set(gui.subROI,'value',0)
    return
end
b=load(fullfile(pname,fname));
ROI=get(gui.vi,'ROIPosition');
bounds.b=b;
bounds.fullfile=fullfile(pname,fname);
bounds.ROI=ROI;
set(gui.subROI,'userdata',bounds,'value',1)
drawSubROI(ROI,fig)

%_________________________________________________________________________________________
%activate sub-ROIs
function SetROIs(obj,event,fig)
gui=get(fig,'userdata');

%remove old rois
delete(findobj('type','line','parent',gui.vidAx,'tag','TubeROIBox'))
switch get(gui.subROI,'value')
    case 0
        set(gui.subROI,'userdata',[])
    case 1
        subROIBrowse('','',fig)
end

function setCross(obj,event,fig)
gui = get(fig,'userdata');
ROI = get(gui.vi,'ROIPosition');

switch get(gui.crosshair,'value')
    case 1
        set(gui.pxH,'ydata',[1 1]*ROI(4)/2);
        set(gui.pxV,'xdata',[1 1]*ROI(3)/2);
    case 0
        set(gui.pxH,'ydata',[1 1]*nan);
        set(gui.pxV,'xdata',[1 1]*nan);
end

function dragCross(obj,event,fig)
gui=get(fig,'userdata');
switch obj
    case gui.pxH
        set(gui.vfig,'windowbuttonmotionfcn',{@moveCross,obj,0})
    case gui.pxV
        set(gui.vfig,'windowbuttonmotionfcn',{@moveCross,obj,1})
end
set(gui.vfig,'windowbuttonupfcn','set(gcbf,''windowbuttonmotionfcn'','''')');
function moveCross(obj,event,pTrace,ID)
pos = get(gca,'currentpoint');
switch ID
    case 0
        set(pTrace,'ydata',[1 1]*pos(1,2));
    case 1
        set(pTrace,'xdata',[1 1]*pos(1,1));
end

%generate a histogram of the current image
function makeHist(obj,event,fig)
gui = get(fig,'userdata');
im = get(gui.pImage,'cdata');
figure;
hist(im(:),0:255)

function ScrollFcn(obj,event,fig)
gui = get(fig,'userdata');
Val=event.VerticalScrollCount;

switch sign(Val)
    case -1
        if gui.backtime == 1
            return
        end
end

%xlim set
gui.backtime = gui.backtime + Val;
xlim = get(gui.TAx,'xlim');
xlim = [xlim(2)-gui.backtime xlim(2)];

%xtick set
j = 0;
xtick = (-100:(5^j):5000);
xtick = xtick(xtick>xlim(1)&xtick<xlim(2));
j = j+1;
while length(xtick)>10
    xtick = (-100:(5^j):5000);
    xtick = xtick(xtick>xlim(1)&xtick<xlim(2));
    j = j+1;
end

set([gui.TAx gui.TiltAx],'xlim',xlim,'xtick',xtick)



set(fig,'userdata',gui)

%_________________________________________________________________________________________
%Construct Base GUI Elements
function makegui(ver)
% AL: This try-catch block checks to see if the FlyCore database can be
% accessed by looking up a barcode that is known to exist. The FlyCore
% database lookup is used for populating the PropertyTable with fly
% line/cross information. The reason this try-catch block is here, as
% opposed to near the creation/initialization of the PropertyGrid, is a bit
% quirky:
%
% FlyFQuery() requires a non-built in java class. At the moment, if this
% class is not on the static java path, FlyFQuery expects it to be
% installed within a jarfile at a certain location, and it does a
% javaaddpath to this expected location. This has the side effect of
% clearing all global variables (not necessarily unexpected; see 'help
% javaaddpath' and 'help clear'). Thus the FlyFQuery() call cannot occur
% after global variables have been declared/initialized.
%
% So at the moment, I have put this code here, before any global variables
% come into existence. One obvious alternative is to put the required
% driver (see 'help FlyFQuery') in the static java classpath. This is
% annoying in its own way (maintenance of the classpath).
% try
%     FlyFQuery(25185);
% catch %#ok<CTCH>
%     warning('flyExecute:barCodeLookupFailed',...
%         'Barcode lookup in Fly Core Filemaker database is not working.');
% end

global gui fleacam; %Code modified in V3.0

%Splash Screen
gui.version=ver;
imaqreset
daqreset
delete(timerfind)
delete(findobj('tag','gOx1'));
delete(findobj('tag','gOx2'));
delete(findobj('tag','ConfirmExp'))

gui.settings = execINI;

tempFig=figure('position',[0 0 1050 1150]/2,'menubar','none','numbertitle','off','name',...
    ['Olympiad Experiment Execution v',gui.version],'tag','gOx','resize','off');
centerfig(tempFig)
axes('position',[0 0 1 1],'color',[.8 .9 .8],'ytick',[]...
    ,'xtick',[],'xlim',[0 1],'ylim',[0 1],'xcolor',[.4 .4 .4],'ycolor',[.4 .4 .4]);
axis off
aTemp=imread('Olympic_OlympiadLogo.jpg');
image(aTemp)
axis off
drawnow

gTEMP=imaqhwinfo('dcam'); %bascam
%find dcam basler a602f
for i=1:length(gTEMP.DeviceInfo)
    if strcmpi(gTEMP.DeviceInfo(i).DeviceName,'A602f')
        %% Open Point Grey Flea3 camera for control with BIAS 
        !bias_gui_v0p54.lnk &
        fleacam = BiasControl('127.0.0.1',5010); %fleacam
        pause(5)
        fleacam.connect();

        %Videoinput for clocked frames from MCU
        gui.vi=videoinput('dcam',gTEMP.DeviceInfo(i).DeviceID,'F7_Y8_656x491');
        gui.vi.framespertrigger=1;
        gui.vi.triggerrepeat=inf;
        triggerconfig(gui.vi,'hardware','risingEdge','externalTrigger')
        gui.vi.startfcn='disp(''Video System Started'')';

%         fleacam.stopCapture();
%         fleacam.enableLogging();
        fleacam.startCapture();
        
        break;
    end
    if i==length(gTemp.DeviceInfo)
        errordlg('No Basler A602f Camera Found')
        return;
    end
end


%Check Calibration information
info=daqhwinfo('nidaq');
ind=[];
for i=1:length(info.BoardNames)
    if strcmpi(info.BoardNames(i),'USB-6009')
        ind=info.InstalledBoardIds{i};
        break
    end
end
if isempty(ind)
    disp('ERROR,NIDAQ NOT CONNECTED')
    return
end

cal = 0;
snum = nidaq_serial(ind);
disp(['NIDAQ Serial: 0x',dec2hex(snum)])
gui.snum = snum;

if (snum==20563085) %Calibration Top Plate
    cal = 1;
    load('TemperatureCalibration\139C48D-CALIBRATION-TOP-PLATE.mat')
    gui.c = 1;
    gui.Cal = Cal; %Cal is a variable loaded from the file.
    gui.NIST = NIST; %NIST is a variable loaded from the file
else
    cal = 0;
    NIST = [];
    try load(['TemperatureCalibration\',dec2hex(snum),'.mat']);
        disp(['Loaded Calibration Data for top plate SN: ',dec2hex(snum)]);
    catch
        disp('WARNING: NO CALIBRATION DATA PRESENT FOR THIS TOP PLATE')
        disp('Temperature reports will represent raw sensor data')
    end
    
    gui.c = 0;
    gui.Cal = Cal; %Cal is a variable loaded from the file.
    gui.NIST = NIST; %NIST is a variable loaded from the file
end

gui.backtime = 1;
gui.resolution = resolution;



%_________________________________________________________________________________________
%Load Presets from files, Connect to hardware
[a t]=xlsread('parameters.xls');
genotypes={t{2:end,1}};
rearingCycle={t{2:end,2}};

%_________________________________________________________________________________________
%Construct Status/Control Window


gui.fig = figure('position',[0 0 900 700],'tag','gOx1','menubar','none','numbertitle','off',...
    'name',['Olympiad Experiment Execution v',gui.version,' - Gus Lott III, PhD - x4362'],'resize','off','color',[.7 .7 1]); %Code modified in V3.0

centerfig(gui.fig)
set(gui.fig,'WindowScrollWheelFcn',{@ScrollFcn,gui.fig})
delete(tempFig)

gui.FileMenu=uimenu('label','File','userdata','C:\Documents and Settings\Olympiad_local\Desktop\Production Execute Protocols\');
gui.openExp=uimenu('parent',gui.FileMenu,'label','Open Experiment','callback',{@LoadExperiment,gui.fig});
gui.AVICheck=uimenu('parent',gui.FileMenu,'label','AVI File Parameters','callback',{@AVICheck,gui.fig});

gui.TPanel=uipanel('units','pixels','position',[5 500 595 200],'title','Temperature Track & Control System Status',...
    'fontweight','bold','backgroundcolor',get(gui.fig,'color'));
ytl={'18',' ','20',' ','22',' ','24',' ','26',' ','28',' ','30',' ','32',' ','34',' ','36'};
gui.TAx=axes('parent',gui.TPanel,'position',[.2 .1 .68 .85],'tag','gTemperatureAxis',...
    'yaxislocation','right','xlim',[-30 0],'ylim',[18 36],'ycolor','k',...
    'ytick',[18:1:36],'yticklabel',ytl,'ygrid','on','xtick',[0:5:5000],'color',[.9 .9 .9],'box','on','xgrid','on');

%Initialize control system parameters
TC.cs=0;
TC.e=[];
TC.scale=20;
TC.Tdt=0;

gui.Tsp=line(nan,nan,'color','w','parent',gui.TAx,'linewidth',3,'userdata',TC);
gui.TPl(1)=line(nan,nan,'color','k','parent',gui.TAx,'linewidth',2);
gui.TPl(2)=line(nan,nan,'color','k','parent',gui.TAx,'linewidth',2);
gui.controlPlot=line(nan,nan,'color',[.3 .7 .3],'parent',gui.TAx,'linewidth',2);

gui.stateLine = line(nan,nan,'color',[.7 .7 .3],'parent',gui.TAx,'linewidth',1);

gui.c = cal;
if gui.c
    %TPl are channels 0,3
    for i=1:6
        gui.calPl(i) = line(nan,nan,'color','b','parent',gui.TAx,'linewidth',1);
    end
    % 1 2 4 5 6 7
    %tube 1 = Channels 4,7 = gui.calPl([3,6])
    set(gui.calPl([3,6]),'color','b')
    %tube 4 = Channels 5,6 = gui.calPl([4,5])
    set(gui.calPl([4,5]),'color','g')
    %tube 6 = Channels 1,2 = gui.calPl([1,2])
    set(gui.calPl([1,2]),'color','r')
    %Set Left side to dashed
    set(gui.calPl([3,4,1]),'linestyle','--')
end



gui.CSAx=axes('parent',gui.TPanel,'position',[.92 .1 .07 .85],...
    'yaxislocation','right','xlim',[0 1],'ylim',[-1 1],'ycolor',[.8 0 0],...
    'ytick',-1:.1:1,'yticklabel',[],'ygrid','on','xtick',[],'color',[.9 .9 .9],'box','on','userdata',0);
gui.CSpatch=patch([0 1 1 0],[0 0 0 0],'r','parent',gui.CSAx,'facealpha',.6);
gui.csText=xlabel('');

gui.TemperatureNow=uicontrol(gui.TPanel,'units','normalized','position',[0.01 0.55 0.18 0.4],'style','Text','fontweight','bold',...
    'fontsize',25,'string','','backgroundcolor',get(gui.TPanel,'backgroundcolor'));
gui.TemperatureTarget=uicontrol(gui.TPanel,'units','normalized','position',[0.01 0.1 0.18 0.4],'style','edit','fontweight','bold',...
    'fontsize',25,'string','','backgroundcolor','w','enable','off','callback',{@targetchange,gui.fig});

gui.TempPop = uicontrol(gui.TPanel,'style','toggle','units','normalized','position',...
    [0.97 0.96 0.03 0.08],'backgroundcolor',[.8 0 0],'callback',{@popTemperature,gui.fig},'userdata',gui.fig);

gui.SeqVisPanel=uipanel('units','pixels','position',[5 250 595 250],'title','Current Sequence Visualization','fontweight','bold','backgroundcolor',get(gui.fig,'color'));

gui.visAx=axes('parent',gui.SeqVisPanel,'units','normalized','position',[0.01 .1 .98 .7],'ytick',[],'color',[.6 .6 .6],'box','on','xlim',[0 1],'ylim',[-250 2385]);
gui.visTimeLine=line([0 0],[-250 2385],'linewidth',2,'marker','o','parent',gui.visAx,'color','w');
gui.patternAx=axes('parent',gui.SeqVisPanel,'units','normalized','position',[.01 .81 .94 .19],'xtick',[],'ytick',[],'color','none','box','on');
gui.pDown=uicontrol('parent',gui.SeqVisPanel,'style','pushbutton','units','normalized','position',[0.96 0.81 0.03 0.06],'string','\/','callback',{@patternScroll,gui.fig});
gui.pUp=uicontrol('parent',gui.SeqVisPanel,'style','pushbutton','units','normalized','position',[0.96 0.94 0.03 0.06],'string','/\','callback',{@patternScroll,gui.fig});

gui.MCUPanel=uipanel('units','pixels','position',[5 110 290 140],'title','Configure & Control Experiment','fontweight','bold',...
    'backgroundcolor',get(gui.fig,'color'));
%Connect, upload experiment
gui.MCUConnect=uicontrol(gui.MCUPanel,'style','toggle','units','normalized','position',[.55 .5 .4 .3],'string','MCU/Heat Connect',...
    'fontweight','bold','callback',{@MCU_connect,gui.fig});
gui.error=uicontrol(gui.MCUPanel,'style','Radiobutton','units','normalized','position',[.55 .8 .3 .2],'string','MCU error',...
    'Enable','inactive','Value',0,'backgroundcolor',get(gui.fig,'color'));

%Experiment Directory, open directory
gui.SetDir=uicontrol(gui.MCUPanel,'style','pushbutton','units','normalized','position',[.05 .7 .4 .15],'string','Set Directory',...
    'userdata','C:\','callback',{@SetExpDir,gui.fig});
gui.OpenDir=uicontrol(gui.MCUPanel,'style','pushbutton','units','normalized','position',[.05 .5 .4 .15],'string','Open Directory',...
    'callback',{@OpenExpDir,gui.fig});
gui.ExpName=uicontrol(gui.MCUPanel,'style','Edit','units','normalized','position',[.05 .25 .4 .15],'string','ExperimentName','backgroundcolor','w','fontweight','bold');

%Run Execution
gui.ExperimentGo=uicontrol(gui.MCUPanel,'style','toggle','units','normalized','position',[.55 .22 .4 .24],'string','Run Experiment',...
    'backgroundcolor',[.9 .2 .2],'fontweight','bold','enable','off','callback',{@ExecuteExperiment,gui.fig,fleacam});
%Status Text
gui.ExpDirectory=uicontrol(gui.MCUPanel,'style','text','units','normalized','position',[.01 .02 .98 .16],'backgroundcolor',[.7 .5 0],...
    'foregroundcolor','w','string','','horizontalalignment','left',...
    'fontunits','normalized','fontsize',.5,'fontweight','bold');

gui.ExpPanel=uipanel('units','pixels','position',[5 10 290 100],'title','Experiment','fontweight','bold','backgroundcolor',get(gui.fig,'color'));
gui.SequenceOrder=uitable('parent',gui.ExpPanel,'units','normalized','position',[0 0 1 1],...
    'ColumnName',{'Sequence Name','T','Active','Video Trans'},...
    'ColumnFormat',{'char','Numeric','logical','logical'},...
    'columneditable',[false false false],'enable','inactive');


gTemp=uipanel('units','pixels','position',[300 10 300 80],'title','Tilt/Vibration','fontweight','bold','backgroundcolor',get(gui.fig,'color')); %Code modified in V3.0
gui.TiltAx = axes('parent',gTemp,'position',[0 0 1 1],'xtick',[],'ytick',[],'box','on');
gui.TiltPl(1)=line(NaN,NaN,'color',[.8 0 0],'linewidth',1,'parent',gui.TiltAx);
gui.TiltPl(2)=line(NaN,NaN,'color',[0 .8 0],'linewidth',1,'parent',gui.TiltAx);
gui.TiltPl(3)=line(NaN,NaN,'color',[0 0 .8],'linewidth',1,'parent',gui.TiltAx);
gui.TiltVal = uicontrol(gTemp,'style','text','backgroundcolor','w','units','normalized',...
    'position',[0.05 0.75 0.2 0.2]);


gui.userCheck(1) = uicontrol('style','checkbox','units','pixels','position',[480 185 150 20],'string',gui.settings.button(1).name,...
    'backgroundcolor',get(gui.fig,'color'),'fontweight','bold','enable','on','callback','', 'visible', 'on'); %Modified on Feb 7th 2011
gui.userCheck(2) = uicontrol('style','checkbox','units','pixels','position',[480 160 150 20],'string',gui.settings.button(2).name,...
    'backgroundcolor',get(gui.fig,'color'),'fontweight','bold','enable','on','callback','', 'visible', 'on'); %Modified on Feb 7th 2011

 
%%Code modified in V3.0
%Code change begins
gTemp=uipanel('units','pixels','position',[300 90 170 140],'fontweight','bold','backgroundcolor',get(gui.fig,'color'));
% KB: these were in the wrong order, switched
gui.labelB = uicontrol('fontweight','bold','unit','normalized','style', 'text', 'string', 'Notes Behavioral', 'parent', gTemp, 'position',[0 0.9 1 0.1]);
gui.userNotesB = uicontrol('style','edit','min',0,'max',2,'unit','normalized','parent',gTemp,'position',[0 0.5 1 0.4],...
     'horizontalalignment','left','backgroundcolor','w', 'callback', {@(x,y) TransBehaveNotesGuiXml}); 
gui.labelT = uicontrol('fontweight','bold','unit','normalized','style', 'text', 'string', 'Notes Technical', 'parent', gTemp, 'position',[0 0.4 1 0.1]);
gui.userNotesT = uicontrol('style','edit','min',0,'max',2,'unit','normalized','parent',gTemp,'position',[0 0 1 0.4],...
     'horizontalalignment','left','backgroundcolor','w', 'callback', {@(x,y) TransTechNotesGuiXml}); 
%Code change ends

gui.SeqTime=uicontrol('style','text','units','pixels','position',[450 230 150 19],'string','0:00:00',...
    'fontweight','bold','fontunits','normalized','fontsize',.7,'backgroundcolor',get(gui.fig,'color'));
gui.TotalTime=uicontrol('style','text','units','pixels','position',[300 230 150 19],'string','Total: [0:00:00]',...
    'fontweight','bold','fontunits','normalized','fontsize',.7,'backgroundcolor',get(gui.fig,'color'),'foregroundcolor',[.5 0 0]);

gui.ForceSeq=uicontrol('style','toggle','units','pixels','position',[480 210 120 20],'string','Force Sequence Start',...
    'backgroundcolor',[.7 .7 .7],'fontweight','bold','enable','off','callback',''); %Code modified in V3.0


for i=1:6
    gui.tubeconfig(i)=uipanel('units','pixels','position',[800-195 110*5.1-(i-1)*115 185 110],'title',['Tube ',num2str(i)],'backgroundcolor',[1 .8 .6],'fontweight','bold', 'visible', 'off'); %Code modified in V3.0
    gui.tube(i).Genotype=uicontrol('parent',gui.tubeconfig(i),'style','popupmenu','units','normalized',...
        'position',[0.02 0.8 0.96 .2],'string',genotypes,'backgroundcolor','w','callback',{@saveTubes,gui.fig});
    gui.tube(i).Gender=uicontrol('parent',gui.tubeconfig(i),'style','popupmenu','units','normalized',...
        'position',[0.02 0.55 0.25 .2],'string',{'M','F','M/F'},'backgroundcolor','w','callback',{@saveTubes,gui.fig});
    gui.tube(i).Rearing=uicontrol('parent',gui.tubeconfig(i),'style','popupmenu','units','normalized',...
        'position',[0.29 0.55 0.69 .2],'string',rearingCycle,'backgroundcolor','w','callback',{@saveTubes,gui.fig});
    uicontrol('parent',gui.tubeconfig(i),'style','text','units','normalized',...
        'position',[0.05 0.3 0.1 .2],'string','N:','backgroundcolor',get(gui.tubeconfig(i),'backgroundcolor'),'horizontalalignment','left','fontweight','bold','fontsize',10);
    gui.tube(i).n=uicontrol('parent',gui.tubeconfig(i),'style','Edit','units','normalized',...
        'position',[0.15 0.3 0.3 .2],'string','0','backgroundcolor','w','callback',{@saveTubes,gui.fig});
    uicontrol('parent',gui.tubeconfig(i),'style','text','units','normalized',...
        'position',[0.5 0.3 0.18 .2],'string','N_d:','backgroundcolor',get(gui.tubeconfig(i),'backgroundcolor'),'horizontalalignment','left','fontweight','bold','fontsize',10);
    gui.tube(i).n_dead=uicontrol('parent',gui.tubeconfig(i),'style','Edit','units','normalized',...
        'position',[0.68 0.3 0.3 .2],'string','0','backgroundcolor','w','callback',{@saveTubes,gui.fig});
    uicontrol('parent',gui.tubeconfig(i),'style','text','units','normalized',...
        'position',[0.02 0.05 0.18 .2],'string','DOB:','backgroundcolor',get(gui.tubeconfig(i),'backgroundcolor'),'horizontalalignment','left','fontweight','bold','fontsize',9);
    gui.tube(i).DOB=uicontrol('parent',gui.tubeconfig(i),'style','Edit','units','normalized',...
        'position',[0.20 0.05 0.4 .2],'string',datestr(now,23),'backgroundcolor','w','callback',{@saveTubes,gui.fig});
    uicontrol('parent',gui.tubeconfig(i),'style','text','units','normalized',...
        'position',[0.63 0.05 0.18 .2],'string','Stv:','backgroundcolor',get(gui.tubeconfig(i),'backgroundcolor'),'horizontalalignment','left','fontweight','bold','fontsize',9);
    gui.tube(i).Starved=uicontrol('parent',gui.tubeconfig(i),'style','Edit','units','normalized',...
        'position',[0.79 0.05 0.21 .2],'string','9','backgroundcolor','w','callback',{@saveTubes,gui.fig});
    if i==6; break; end
    gui.tube(i).copy=uicontrol('parent',gui.tubeconfig(i),'style','pushbutton','units','normalized','string','v',...
        'position',[.9 -.1 .1 .15],'fontweight','bold','callback',{@copyTube,gui.fig,i});
end

IntegrateJGrid(); %Code modified in V3.0


gui.CopyAll = uicontrol('parent',gui.fig,'style','pushbutton','units','Pixels','string','\/ \/ \/',...
    'position',[690 660 40 15],'fontweight','bold','callback',{@copyTubeAll,gui.fig}, 'visible', 'off'); %Code modified in V3.0

uicontrol('style','text','units','pixels','position',[605 675 60 18],'string','Operator','backgroundcolor',get(gcf,'color'),'fontweight','bold', 'visible', 'off'); %Code modified in V3.0
gui.UserID = uicontrol('style','edit','units','pixels','position',[665 678 60 20],...
    'string','','backgroundcolor','w', 'visible', 'off'); %Code modified in V3.0

%_________________________________________________________________________________________
%Construct Video Window %bascam

gui.vfig=figure('position',[0 0 656 511],'tag','gOx2','menubar','none','numbertitle','off',...
    'name',['VIDEO: Olympiad Experiment Execution v',gui.version],'color',[.7 .7 1],'resize','off');
centerfig(gui.vfig)
pos=get(gui.vfig,'position');
pos(1)=10;
set(gui.vfig,'position',pos)
gui.vidAx=axes('units','pixels','position',[0 20 656 491],'color','none');
gui.pImage = image( zeros(491, 656, 1) ,'parent',gui.vidAx);
preview(gui.vi,gui.pImage)

gui.pxH = line([-1000 1000],[nan nan],'color','r','linewidth',2,'linestyle','--','buttondownfcn',{@dragCross,gui.fig});
gui.pxV = line([nan nan],[-1000 1000],'color','r','linewidth',2,'linestyle','--','buttondownfcn',{@dragCross,gui.fig});

%Video System Status Panels
gui.vidp(1)=uipanel('units','pixels','position',[0 0 656/4 20]);
gui.vidMode=uicontrol('parent',gui.vidp(1),'style','text','units','normalized','position',[0 0 1 1],'string','Preview','backgroundcolor','r','fontweight','bold');
gui.vidp(2)=uipanel('units','pixels','position',[656/4 0 656/4 20]);
gui.vidFile=uicontrol('parent',gui.vidp(2),'style','text','units','normalized','position',[0 0 1 1],'string','');
gui.vidp(3)=uipanel('units','pixels','position',[2*656/4 0 656/4 20]);
gui.vidFrameRate=uicontrol('parent',gui.vidp(3),'style','text','units','normalized','position',[0 0 1 1],'string','');
gui.vidp(4)=uipanel('units','pixels','position',[3*656/4 0 656/4 20]);
gui.vidControl=uicontrol('parent',gui.vidp(4),'style','Toggle','units','normalized','position',[0 0 1 1],'string','Open Configuration',...
    'fontweight','bold','callback',{@OpenCamCFG,gui.fig},'backgroundcolor',get(gui.vidp(4),'backgroundcolor')-.1);

%Configuration Panel for Camera
gui.camCFGp=uipanel('units','pixels','position',[0 0 656/3 75],'visible','off');
uicontrol('parent',gui.camCFGp,'style','text','string','Brightness:','units','normalized','position',[.02 .68 .32 .25],...
    'horizontalalignment','left','backgroundcolor',get(gui.camCFGp,'backgroundcolor'),'fontweight','bold');
gui.Bright=uicontrol('parent',gui.camCFGp,'style','edit','string','',...
    'units','normalized','position',[.35 .7 .3 .25],'backgroundcolor','w','callback',...
    {@ConfigCam,gui.fig},'enable','off');
uicontrol('parent',gui.camCFGp,'style','text','string','Gain:','units','normalized','position',[.02 .4 .28 .25],'horizontalalignment','left',...
    'backgroundcolor',get(gui.camCFGp,'backgroundcolor'),'fontweight','bold');
gui.Gain=uicontrol('parent',gui.camCFGp,'style','edit','string','',...
    'units','normalized','position',[.35 .38 .3 .25],'backgroundcolor','w','callback',...
    {@ConfigCam,gui.fig},'enable','off');
uicontrol('parent',gui.camCFGp,'style','text','units','normalized','string','Shutter:','position',[.02 .1 .28 .25],'horizontalalignment','left',...
    'backgroundcolor',get(gui.camCFGp,'backgroundcolor'),'fontweight','bold');
gui.Shutter=uicontrol('parent',gui.camCFGp,'style','edit','string','',...
    'units','normalized','position',[.35 .08 .3 .25],'backgroundcolor','w','callback',...
    {@ConfigCam,gui.fig},'enable','off');

%Absolute ROI and global ROI configuration
gui.camROIp=uipanel('units','pixels','position',[656/3 0 656*2/3 75],'visible','off');
uicontrol('parent',gui.camROIp,'style','text','string','Absolute ROI:','units','normalized','position',[.02 .68 .28 .25],'horizontalalignment','left',...
    'backgroundcolor',get(gui.camROIp,'backgroundcolor'),'fontweight','bold')
gui.ROI=uicontrol('parent',gui.camROIp,'style','edit','string','',...
    'units','normalized','position',[.2 .7 .3 .25],'backgroundcolor','w','callback',...
    {@ConfigCam,gui.fig},'userdata',[],'enable','off');
gui.ROIReset=uicontrol('parent',gui.camROIp,'style','pushbutton','string','Reset ROI',...
    'units','normalized','position',[.55 .7 .2 .25],'backgroundcolor',get(gui.camROIp,'backgroundcolor')-.1,...
    'callback',{@ConfigCam,gui.fig});
gui.subROI=uicontrol('parent',gui.camROIp,'style','checkbox','string','6 Tube Sub-Regions',...
    'units','normalized','position',[.01 .4 .3 .25],'backgroundcolor',get(gui.camROIp,'backgroundcolor'),...
    'callback',{@SetROIs,gui.fig});
gui.subROIfile=uicontrol('parent',gui.camROIp,'style','pushbutton','string','Browse...',...
    'units','normalized','position',[.05 .1 .2 .25],'backgroundcolor',get(gui.camROIp,'backgroundcolor')-.1,...
    'callback',{@subROIBrowse,gui.fig});
gui.splitTubes=uicontrol('parent',gui.camROIp,'style','checkbox','string','Split Video Streams',...
    'units','normalized','position',[.3 .4 .3 .25],'backgroundcolor',get(gui.camROIp,'backgroundcolor'),...
    'callback','');

gui.crosshair=uicontrol('parent',gui.camROIp,'style','checkbox','string','Cross-hair overlay',...
    'units','normalized','position',[.65 .4 .3 .25],'backgroundcolor',get(gui.camROIp,'backgroundcolor'),...
    'callback',{@setCross,gui.fig});
gui.histmake = uicontrol('parent',gui.camROIp,'style','pushbutton','string','Histogram',...
    'units','normalized','position',[.65 .1 .3 .25],'backgroundcolor',get(gui.camROIp,'backgroundcolor'),...
    'callback',{@makeHist,gui.fig});


gui.HEAT=[];
gui.MCU=[];
set(gui.fig,'userdata',gui)
set([gui.fig, gui.vfig],'deletefcn',{@OxExit,gui.fig})

%_________________________________________________________________________________________
% Set Config Values from Camera %bascam
set(gui.ROI,'string',num2str(get(gui.vi,'ROIPosition')),'enable','on')
set(gui.Bright,'string',get(getselectedsource(gui.vi),'Brightness'),'enable','on')
set(gui.Gain,'string',get(getselectedsource(gui.vi),'Gain'),'enable','on')
set(gui.Shutter,'string',get(getselectedsource(gui.vi),'Shutter'),'enable','on')

% fleacam.initializeCamera(50,'ufmf',[0,0,1280,1024],'Internal');
fleacam.initializeCamera(50,'ufmf',[0,0,1280,1024],'External');
fleacam.startCapture();


%Set Presets
%auto-load default.mat
ad=dir;
for i=1:length(ad)
    if strcmpi(ad(i).name,'default.cfg')
        ConfigLoad([],'default',gui.fig);
    end
end

for i=1:length(ad)
    if strcmpi(ad(i).name,'ROI.txt')
        b=load(ad(i).name);
        ROI=get(gui.vi,'ROIPosition');
        bounds.b=b;
        bounds.fullfile=fullfile(pwd,'ROI.txt');
        bounds.ROI=ROI;
        set(gui.subROI,'userdata',bounds,'value',1)
        drawSubROI(ROI,gui.fig)
    end
end

for i=1:length(ad)
    if strcmpi(ad(i).name,'gOlympTubes.cfg')
        tubeDataLoad([],'default',gui.fig)
    end
end


%Open Interfaces
function TemperatureConnect
gui=get(findobj('tag','gOx1'),'userdata');
daqreset

%NIDAQ FOR SENSOR ACQUISITION
info=daqhwinfo('nidaq');
ind=[];
for i=1:length(info.BoardNames)
    if strcmpi(info.BoardNames(i),'USB-6009')
        ind=info.InstalledBoardIds{i};
        break
    end
end

if isempty(ind)
    disp('ERROR,NIDAQ NOT CONNECTED')
    return
end

gui.ai=analoginput('nidaq',ind);
gui.ai.inputtype='SingleEnded';
if ~gui.c
    addchannel(gui.ai,[0,4]); %Temperature Sensors
    addchannel(gui.ai,[1,5,2]); %Accelerometer
else
    disp('WARNING: In Calibration Mode')
    addchannel(gui.ai,[0,3]);
    addchannel(gui.ai,[1 2 4 5 6 7]);
end

%callibration top plate
gui.ai.samplerate=1000;
gui.ai.samplesacquiredfcncount=gui.ai.samplerate;
gui.ai.samplesacquiredfcn={@TEMP_SAF,gui.fig};
gui.ai.samplespertrigger=inf;
start(gui.ai)

set(gui.fig,'userdata',gui)


%CONNECT TO MCU AND HEATER
function MCU_connect(obj,event,fig)
global handles gui;
gui=get(fig,'userdata');

switch get(gui.MCUConnect,'value')
    case 0
        try fwrite(gui.HEAT,100); end
        try fwrite(gui.MCU,0); end
        try fclose(gui.HEAT); end
        try fclose(gui.MCU); end
        delete([gui.HEAT gui.MCU])
        gui.MCU=[];
        gui.HEAT=[];
        set(gui.fig,'userdata',gui)
        set(gui.ExperimentGo,'enable','off','value',0,'backgroundcolor',[.9 .2 .2])
        set(gui.TemperatureTarget,'string','','enable','off')
        set([gui.openExp gui.SetDir gui.ExpName gui.TemperatureTarget],'enable','on')
        disp('Disconnected from box.');
        set(obj,'string','MCU/Heat Connect')
        %wrapup a running experiment
    case 1
        %HEATER AND MCU SERIAL PORT OBJECTS
        
        %in response to 0,
        % MCU should respond w/ JFRC#
        % Peltier should respond w/ 0 (and you should immediately send a
        % 100)
        gui.HEAT=serial('COM8');
        gui.HEAT.baudrate=57600;
        gui.HEAT.flowcontrol='none';
        gui.HEAT.inputbuffersize=1000;
        gui.HEAT.outputbuffersize=1000;
        set(gui.HEAT,'DataBits',8);
        set(gui.HEAT,'StopBits',2);
        set(gui.HEAT,'RequestToSend','off');
        fopen(gui.HEAT);
        set(gui.HEAT,'RequestToSend','on');
        pause(.1);
        %flush any characters in the buffer
        if (gui.HEAT.bytesavailable)
            fread(gui.HEAT,gui.HEAT.bytesavailable);
        end
        %send a soft reset
        fwrite(gui.HEAT,0);
        %get the response
        [a,count,msg] = fread(gui.HEAT,1);
        if (count == 1 && a == 0) % found peltier controller
            fwrite(gui.HEAT,100);
            pause(.1);
            disp('Found Peltier')
            set(gui.TemperatureTarget,'string',24,'enable','on','userdata',24);
            % now try open the MCU
            gui.MCU=serial('COM7');
            gui.MCU.baudrate=57600;
            gui.MCU.flowcontrol='none';
            gui.MCU.inputbuffersize=1000;
            gui.MCU.outputbuffersize=10000;
            set(gui.MCU,'DataBits',8);
            set(gui.MCU,'StopBits',2);
            set(gui.MCU,'RequestToSend','off');            
            fopen(gui.MCU);
            set(gui.MCU,'RequestToSend','on');
            pause(.1);
            %flush any characters in the buffer
            if (gui.MCU.bytesavailable)
                fread(gui.MCU,gui.MCU.bytesavailable);
            end
            %send a soft reset
            fwrite(gui.MCU,0);
            [a,count,msg] = fread(gui.MCU,1);
            if (count == 1 && a == 'J') % found MCU controller
                id = fread(gui.MCU,4);
                id = char(id(:)');
                gui.boxID = str2double(id(end));
                if (gui.MCU.bytesavailable)
                    fread(gui.MCU,gui.MCU.bytesavailable);
                end
                switch gui.boxID
                    case 1
                        gui.boxName = 'Zeus';
                    case 2
                        gui.boxName = 'Orion';
                    case 3
                        gui.boxName = 'Athena';
                    case 4
                        gui.boxName = 'Apollo';
                    case 5
                        gui.boxName = 'Ares';
                    otherwise
                        gui.boxName = 'Unknown';
                        disp('Problem connecting to devices')
                        try fwrite(gui.HEAT,100);; end
                        try fwrite(gui.MCU,0); end
                        try fclose(gui.HEAT); end
                        try fclose(gui.MCU); end
                        delete([gui.HEAT gui.MCU])
                        gui.MCU=[];
                        gui.HEAT=[];
                        set(gui.MCUConnect,'value',0)
                        set(gui.TemperatureTarget,'string','','enable','off')
                        set(gui.fig,'userdata',gui)
                        return
                end
                disp(['Found MCU: ',gui.boxName])
			    %Code modified in V3.0
                %Code change begins
                % KB: store box name in metadata, set in experiment
                % name
                handles.pgrid.setValueByPathString('apparatus.box',gui.boxName);
                pgridPropertyChangeCallback('apparatus.box') 
                %Code change ends
            else
                disp('Problem connecting to MCU')
                try fwrite(gui.HEAT,100); end
                try fwrite(gui.MCU,0); end
                try fclose(gui.HEAT); end
                try fclose(gui.MCU); end
                delete([gui.HEAT gui.MCU])
                gui.MCU=[];
                gui.HEAT=[];
                set(gui.MCUConnect,'value',0)
                set(gui.TemperatureTarget,'string','','enable','off')
                set(gui.fig,'userdata',gui)
                return;
            end
        else
            disp('Problem connecting to Peltier');
            try fwrite(gui.HEAT,100); end
            try fclose(gui.HEAT); end
            delete(gui.HEAT)
            gui.HEAT=[];
            set(gui.MCUConnect,'value',0)
            set(gui.TemperatureTarget,'string','','enable','off')
            set(gui.fig,'userdata',gui)
            return;
        end

        %store new instrument interfaces
        set(gui.ExperimentGo,'enable','on','value',0,'backgroundcolor',[.9 .2 .2])
        set(gui.fig,'userdata',gui)
end




function ConfigLoad(~,~,fig)
gui=get(fig,'userdata');

load('default.cfg','-MAT')

set(gui.vi,'ROIPosition',str2num(config.ROI))
gssvi=getselectedsource(gui.vi);
set(gssvi,'Brightness',str2num(config.Bright))
set(gssvi,'Gain',str2num(config.Gain))
set(gssvi,'Shutter',str2num(config.Shutter))

set(gui.ROI,'string',num2str(get(gui.vi,'ROIPosition')))
set(gui.Bright,'string',get(gssvi,'Brightness'))
set(gui.Gain,'string',get(gssvi,'Gain'))
set(gui.Shutter,'string',get(gssvi,'Shutter'))


%_________________________________________________________________________________________
%Exit the Program cleanly
function OxExit(~,~,fig)
%run through and gather config data
gui=get(fig,'userdata');
config.ROI=get(gui.ROI,'string');
config.Bright=get(gui.Bright,'string');
config.Gain=get(gui.Gain,'string');
config.Shutter=get(gui.Shutter,'string');

save('default.cfg','config')

delete(findobj('tag','gOx1'))
delete(findobj('tag','gOx2'))
delete(findobj('name','Olympiad Phototaxis Temperature Control System'))
delete(timerfind)

daqreset
imaqreset
try
    fclose(gui.MCU);
    fclose(gui.HEAT);
end

%_________________________________________________________________________________________
%GUI handling for opening camera config properties %bascam
function OpenCamCFG(obj,event,fig)
gui=get(fig,'userdata'); 
val=~get(obj,'value');
growsize=75;

switch val
    case 1
        set(obj,'string','Open Configuration')
        set([gui.camCFGp gui.camROIp],'visible','off')
        drawnow
    case 0
        set(obj,'string','Hide Configuration')
        set([gui.camCFGp gui.camROIp],'visible','on')
end

pos=get(gui.vfig,'position');
pos(2)=pos(2)-growsize*(-1)^val;
pos(4)=pos(4)+growsize*(-1)^val;
set(gui.vfig,'position',pos);

for i=1:4
    pos=get(gui.vidp(i),'position');
    pos(2)=pos(2)+growsize*(-1)^val;
    set(gui.vidp(i),'position',pos)
end
pos=get(gui.vidAx,'position');
pos(2)=pos(2)+growsize*(-1)^val;
set(gui.vidAx,'position',pos)

function SetExpDir(obj,event,fig)
gui=get(fig,'userdata');
gdir=get(gui.SetDir,'userdata');
gdir=uigetdir(gdir,'Experiment Directory Selection');

if ~isstr(gdir); return; end
set(gui.SetDir,'userdata',gdir)

function OpenExpDir(obj,event,fig)
gui=get(fig,'userdata');
dos(['explorer ',get(gui.SetDir,'userdata')])

%Code modified in V3.0
%Code change begins
function TransTechNotesGuiXml()
global handles gui;
% KB: notes not shown in pgrid, only need to modify in defaultsTree
notes_technical = get(gui.userNotesT, 'string');
handles.defaultsTree.setValueByPathString('notes_technical.content',notes_technical);
%Code change ends

%Code modified in V3.0
%Code change begins
function TransBehaveNotesGuiXml()
global handles gui;
% KB: notes not shown in pgrid, only need to modify in defaultsTree
notes_behavioral = get(gui.userNotesB, 'string');
handles.defaultsTree.setValueByPathString('notes_behavioral.content',notes_behavioral);
%Code change ends

%EOF