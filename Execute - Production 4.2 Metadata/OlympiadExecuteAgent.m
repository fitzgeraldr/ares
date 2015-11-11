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



function OlympiadExecuteAgent(obj,~,fig,fleacam)

gui=get(fig,'userdata');

expstate=get(obj,'userdata');
experiment=get(gui.SequenceOrder,'userdata');
seq=get(gui.MCU,'userdata');
expstate.dbstate = 0;

%which sequence is running? (expstate.i)
%are we in initialization? (expstate.sv==0)
%are we in temp seeking?  (expstate.sv==1)
%are we in sequence execution? (expstate.sv==2)
%are we in cleanup? (expstate.sv==3)
try
    switch expstate.sv
        case 0
            %should all be handled in button press
            
        case 1
            %Temperature seek, check for video, place in videomode
            switch expstate.tr
                case 0
                    expstate.BAFtime = 0;
                    expstate.i=expstate.i+1;
                    if expstate.i>length(experiment.actionlist)
                        expstate.sv=3;
                        expstate.tr=0;
                        set(obj,'userdata',expstate)
                        return
                    end
                    set(gui.visTimeLine,'xdata',[0 0]);
                    %load sequence to vis and program
                    experiment=get(gui.SequenceOrder,'userdata');
                    action=experiment.actionlist(expstate.i).action;
                    flyExecute('visExp',action,gui.fig);
                    
                    expstate.dbstate = 1;
                    
                    %Prep acquisition
                    if gui.MCU.bytesavailable>0; fread(gui.MCU,gui.MCU.bytesavailable); end
                    %if gui.MCU.framesavailable>0; getdata(gui.MCU,gui.MCU.framesavailable); end
                    expstate.dbstate = 1.1;

                    fclose(gui.MCU);
                    gui.MCU.bytesavailablefcn={@exec_BAF,gui.fig,obj,fleacam};
                    gui.MCU.BytesAvailableFcnMode = 'byte';
                    gui.MCU.BytesAvailableFcnCount = 5;
                    fopen(gui.MCU);
                    
                    %force HW reset
                    set(gui.MCU,'RequestToSend','off');
                    %set (gui.MCU.Source,'RTS',0);
                    pause (.1)
                    set(gui.MCU,'RequestToSend','on');
                    %set (gui.MCU.Source,'RTS',1);
                    pause (.1)
                    fwrite(gui.MCU,0); %Reset MCU
                    %set(gui.MCU.Source,'WriteBuffer',0) %Reset MCU
                    expstate.error8 = 0; % clear error 8 (MCU i2c hang) flag
                    set(gui.error,'Value',0) % clear MCU error indicator
                    
                    expstate.dbstate = 1.2;
                    pause(.2);  %to attempt to remove timeouts when polling mcu
                    c=fread(gui.MCU,5);
                    %c=getdata(gui.MCU,5);  %this line frequently errors on zeus (3/29/10 gkl)
                    expstate.dbstate = 1.3;
                    c = char(c(:)');
                    if strcmp(c(1:4),'JFRC')
                        disp('Olympiad MCU Reset');
                    else
                        disp('Olympiad MCU Reset ERROR');
                    end
                    
                    expstate.dbstate = 2;
                    
                    %Seek TEMPERATURE
                    set(gui.TemperatureTarget,'string',num2str(experiment.actionlist(expstate.i).T));
                    TC=get(gui.Tsp,'userdata');
                    TC.Tdt = 0;
                    set(gui.Tsp,'userdata',TC)
                    
                    set(gui.vi,'DiskLogger',[])
                    
                    if experiment.actionlist(expstate.i).Vid
                        stop(gui.vi);
                        %setup logging for seek to target value
                        avifname=initTvidFile(expstate,experiment,gui);
                        disp('%setup logging for seek to target value-------')
                        start(gui.vi);
                        set(gui.vidMode,'string','Recording','backgroundcolor','g')
                        set(gui.vidFile,'string',[avifname,'.avi'])
                        set(gui.vidFrameRate,'string','25 Hz')
                        
                    end
                    dat=get(gui.SequenceOrder,'data');
                    for i=1:size(dat,1)
                        dat{i,3}=0;
                    end
                    dat{expstate.i,3}=true;
                    set(gui.SequenceOrder,'data',dat)
                    expstate.tr=1;
                    
                    expstate.dbstate = 3;
                case 1
                    %if at temp for certain period of time, stop video and move
                    %to execution mode and set expstate.tr=0;
                    
                    %This is odd code here, not sure why it is necessary.
                    %These should always be the same length
                    gT1 = get(gui.TPl(1),'ydata');
                    gT2 = get(gui.TPl(2),'ydata');
                    t1=get(gui.TPl(1),'xdata');
                    t2=get(gui.TPl(2),'xdata');
                    if length(gT1)~=length(gT2) %Bad juju, this should never be the case
                        disp('Possible Error - Temperature plots different lengths - email gus');
                        len = min([length(gT1),length(gT2)]);
                        gT1 = gT1(1:len);
                        gT2 = gT2(1:len);
                        t1 = t1(1:len);
                        t2 = t2(1:len);
                    end
                    
                    temperature=(gT1 + gT2)/2;
                    time = (t1+t2)/2;
                    
                    %This could be changing temperature and time differently
                    %This could cause indexing differences
                    %                 temperature(isnan(temperature))=[];  %These lines are a possible error spot
                    %                 time(isnan(time))=[];
                    ind = isnan(temperature);
                    temperature(ind)=[]; %this should make the vectors the same length no matter what (3/29/10 gkl)
                    time(ind)=[];
                    
                    sp=experiment.actionlist(expstate.i).T;
                    historyWindow=1; %minute into the past to seek stability
                    
                    if isnan(time(end)); return; end %last time value must be non-nan
                    expstate.dbstate = 4;
                    %error occurs after here but before 5/6, index exceeds
                    %matrix dimensions error
                    
                    set(gui.ForceSeq,'enable','on')
                    stableind = time>(time(end)-historyWindow);
                    %Temperature could be different length than time, POSSIBLE ERROR SOURCE-
                    stablewindow = abs(sp-temperature(time>(time(end)-historyWindow))); %Logical indexing cannot be error
                    stabletime = time(time>(time(end)-historyWindow));  %logical indexing cannot be error
                    % time(end) on an empty returns "Subscript indices must either be real positive integers or logicals."
                    % Not exeeds matrix dimensions
                    
                    if get(gui.ForceSeq,'value')==0
                        if (max(time)<historyWindow)  % if the system has not accrued a window width of data.
                            ind = find(stablewindow>1,1,'last'); %Could return no values within window (empty ind)
                            ind = max([ind,1]);  %if ind is empty, this will return 1
                            
                            rawsec = 60-(stabletime(end)-stabletime(ind))*60; %Stabletime could be empty and ind could be 1
                            
                            hours=floor(rawsec/(60*60)); %no error
                            mins=floor((rawsec-hours*60*60)/60); %no error
                            sec=floor(rawsec-hours*60*60-mins*60); %no error
                            if mins <1 %no error
                                set(gui.SeqTime,'string',sprintf('Delay: [-%d:%02d:%02d]',hours,mins,sec)) %no error
                            else
                                set(gui.SeqTime,'string','Seeking Temp') %No error
                            end
                            expstate.dbstate = 5; %no error
                            return
                        end
                        if (max(stablewindow)>1) %at least gather a minute of history %within a degree for a minute
                            ind = find(stablewindow>1, 1, 'last' ); %Could produce empty
                            rawsec = 60-(stabletime(end)-stabletime(ind))*60;
                            hours=floor(rawsec/(60*60));
                            mins=floor((rawsec-hours*60*60)/60);
                            sec=floor(rawsec-hours*60*60-mins*60);
                            if mins <1
                                set(gui.SeqTime,'string',sprintf('Delay: [-%d:%02d:%02d]',hours,mins,sec))
                            else
                                set(gui.SeqTime,'string','Seeking Temp')
                            end
                            expstate.dbstate = 6;
                            return
                        end
                    else
                        expstate.forceSeq = 1;
                        expstate.dbstate = 7;
                    end
                    set(gui.ForceSeq,'value',0,'enable','off')
                    
                    if strcmpi(gui.vi.running,'on')
                        stop(gui.vi)
                    end
                    %Store temperature track for transition
                    ind=time>expstate.stopTimes(end);
                    time=time(ind);
                    temperature=temperature(ind);
                    datafile=[sprintf('%02d',expstate.i),'_Transition_to_',experiment.actionlist(expstate.i).name,'.mat'];
                    save(fullfile(expstate.expdir,datafile),'temperature','time');
                    %move onto state 2
                    expstate.tr=0; expstate.sv=2;
                    expstate.dbstate = 8;
                    
                    
                    
            end
        case 2
            switch expstate.tr
                case 0 %Parse & Upload experiment, clear temperature data and start both, prep video files, initialize and run experiment
                    
                    
                    %parse experiment, turn off baf on serial port, clear out serial buffer
                    %Upload experiment
                    action=experiment.actionlist(expstate.i).action;
                    pattern=get(gui.patternAx,'userdata');
                    disp('Uploading Sequence')
                    fwrite(gui.MCU,254);
                    %set(gui.MCU.Source,'WriteBuffer',254)
                    pause(.1)
                    if gui.MCU.bytesavailable>0
                        fread(gui.MCU,gui.MCU.bytesavailable);
                    end
                    %if gui.MCU.framesavailable>0
                    %    getdata(gui.MCU,gui.MCU.framesavailable);
                    %end
                    expstate.dbstate = 9;
                    
                    UploadExp(gui,action,pattern)
                    expstate.dbstate = 10;
                    
                    %prep video files if any
                    try stop(gui.vi); end
                    seq=initVideoFiles(expstate,experiment,gui);
                    
                    expstate.dbstate = 11;
                    %hand seq to something for future reference, probably gui.MCU,'userdata'
                    set(gui.MCU,'userdata',seq)
                    
                    %toss verticle bar on plot to indicate experiment start time
                    thisStartTime=gui.ai.samplesacquired/gui.ai.samplerate;
                    line([1 1]*thisStartTime/60,[18 36],'color','b','tag','expStatLine','parent',gui.TAx,'marker','.','linewidth',1)
                    expstate.startTimes=[expstate.startTimes,thisStartTime];
                    expstate.dbstate = 12;
                    
                    %start baf on serial port and send experiment execute command
                    if gui.MCU.bytesavailable>0; fread(gui.MCU,gui.MCU.bytesavailable); end
                    %if gui.MCU.framesavailable>0; getdata(gui.MCU,gui.MCU.framesavailable); end
                    
                    

                    %stop(gui.MCU)
                    %gui.MCU.bytesacquiredfcn={@exec_BAF,gui.fig,obj};
                    %gui.MCU.framesacquiredfcncount = 5;
                    %start(gui.MCU)
                    
                    expstate.seqComplete=0;
                    gui.vi.tag='0';
                    expstate.BAFtime = 0;
                    set(obj,'userdata',expstate);
                    disp('Activating MCU')
                    fwrite(gui.MCU,255);
                    %set(gui.MCU.Source,'WriteBuffer',255)
                    expstate.dbstate = 13;
                    
                    expstate.tr=1;
                    disp('done loading and executing');
                    
                case 1 %wait for experiment to complete, when complete, iterate expstate.i and goto case 1 or case 3, change active check block in experiment uitable
                    if expstate.seqComplete==1
                        %close video files
                        logger = get(gui.vi,'userdata');
                        if ~isempty(get(gui.vi,'userdata'))
                            while strcmpi(gui.vi.running,'on')
                                drawnow %wait for end of experiment frames to finish logging to disk.  This could potentially go infinite if there's a problem
                                disp('Waiting for Video to Finish')
                            end
                            for i=1:(size(logger,1)*size(logger,2))
                                logger(i).aviobj=close(logger(i).aviobj);
                            end
                        end
                        expstate.dbstate = 14;
                        
                        %Save Action List
                        action=experiment.actionlist(expstate.i).action;
                        patterns=get(gui.patternAx,'userdata');
                        pattern=patterns.vals;
                        ff=fullfile(seq.dir,[experiment.actionlist(expstate.i).name,'.seq']);
                        save(ff,'action','-MAT');
                        expstate.dbstate = 15;
                        %save experiment details
                        wrapupSeq(experiment,expstate,gui.fig)
                        expstate.dbstate = 16;
                        %Save Temperature File
                        temperature=experiment.actionlist(expstate.i).T;
                        save(fullfile(seq.dir,'temperature.mat'),'temperature');
                        expstate.dbstate = 17;
                        %save video file timecodes
                        for i=seq.vidinds
                            ftime=action(i).time;
                            Tcam=action(i).command(2);
                            
                            vidaction=action;
                            for j=1:length(vidaction) %make time point relative to frames in each file
                                vidaction(j).time=vidaction(j).time-ftime;
                                vidaction(j).time=vidaction(j).time/Tcam;
                            end
                            
                            %vidaction now contains times relative to frames of movie file "fname" and in units of frames
                            fname=[seq.name,'_',action(i).userdata,'.mat'];
                            ff=fullfile(seq.dir,fname);
                            save(ff,'vidaction','patterns')
                            
                        end
                        expstate.dbstate = 18;
                        expstate.stopTimes=[expstate.stopTimes,gui.ai.samplesacquired/gui.ai.samplerate];
                        expstate.sv=1;
                        expstate.tr=0;
                    end
                    
                    
            end
        case 3
            %Cleanup entire experiment, save global data, notes, etc, return to
            %passive state, pop up button, delete this timer, re-enable temp
            %seek and set to 21
            
            disp('EXPERIMENT COMPLETED')
            set(gui.ExperimentGo,'backgroundcolor',[.9 .2 .2],'value',0)
            
            
            if strcmpi(gui.vi.Running,'on')
                stop(gui.vi)
            end
            expstate.dbstate = 19;
            gui.MCU.bytesavailablefcn='';
            fwrite(gui.MCU,254);
            %gui.MCU.framesacquiredfcn='';
            %set(gui.MCU.Source,'WriteBuffer',254);
            
            fread(gui.MCU,1);
            %getdata(gui.MCU,1);
            
            pause(.2)
            if gui.MCU.bytesavailable>0; fread(gui.MCU,gui.MCU.bytesavailable); end
            %if gui.MCU.framesavailable>0; getdata(gui.MCU,gui.MCU.framesavailable); end
            expstate.dbstate = 20;
            stop(obj)
            delete(obj)
            set(gui.TemperatureTarget,'string',num2str(experiment.actionlist(1).T));
            
            %save experiment file
            patterns=get(gui.patternAx,'userdata');
            patterns=patterns.vals;
            fname=get(gui.ExpName,'string');
            ff=fullfile(expstate.expdir,[fname,'_',expstate.start,'.exp']);
            save(ff,'experiment','patterns','-MAT');
            expstate.dbstate = 21;
                       
            %save extra experiment data & popup modal dialog
            saveRunData(gui,expstate,experiment,fname)
            expstate.dbstate = 22;
            %wrapupExp(experiment,expstate,gui.fig)
            set([gui.openExp gui.SetDir gui.ExpName gui.TemperatureTarget],'enable','on')
            
    end
    
catch e
    disp('Agent Error Detected:')
    disp(['SV = ',num2str(expstate.sv),', TR = ',num2str(expstate.tr)])
    disp(['DBState = ',num2str(expstate.dbstate)])
    %expstate
    set(obj,'userdata',expstate);
    disp(e)
    
    %     %%Automatically Send an email to gus
    %     setpref('Internet','E_mail','lottg@janelia.hhmi.org');
    %     setpref('Internet','SMTP_Server','exchange03.janelia.priv');
    %     subject = sprintf('[BOX ERROR] %s Error Detected', gui.boxName);
    %
    %     body='';
    %     body = [body, sprintf('Date/Time: %s\n\n\n',datestr(now))];
    %     body = [body, sprintf('Error: %s\n\n\n',lasterr)];
    %     body = [body, sprintf('BoxName = %s\n',gui.boxName)];
    %     body = [body, sprintf('dbstate = %f\n',expstate.dbstate)];
    %     body = [body, sprintf('sv = %d, tr = %d, i = %d\n',expstate.sv,expstate.tr,expstate.i)];
    %
    %     save error.mat e expstate
    %     mailList = {'lottg@janelia.hhmi.org','korffw@janelia.hhmi.org'};
    %     sendmail(mailList,subject,body,'error.mat')
    %     disp('This info was emailed to Gus & Wyatt')
    %     stop(obj)
    
end
set(obj,'userdata',expstate);

%extracts data to save with the experiment (temperature, etc)
function saveRunData(gui,expstate,experiment,fname) %#ok<INUSL>
global handles;

%Code modified in V3.0
%Code change begins
data.calibratezz = gui.calibratezz;
data.zzcalOffset = gui.zzcalOffset;
data.NIST  = gui.NIST;
data.Cal = gui.Cal;
data.resolution = gui.resolution;
%Code change ends

if gui.c == 0  %if not in calibration mode
    temperature1=get(gui.TPl(1),'ydata');
    temperature2=get(gui.TPl(2),'ydata');
    temperature = (temperature1+temperature2)/2;
    
    time=get(gui.TPl(1),'xdata');
    control = (get(gui.controlPlot,'ydata')-18)/(36-18);
    setpoint = get(gui.Tsp,'ydata');
    tempstate = get(gui.stateLine,'ydata')-18;
    vibrationY = get(gui.TiltPl(1),'ydata');
    vibrationX = get(gui.TiltPl(2),'ydata');
    vibrationZ = get(gui.TiltPl(3),'ydata');
    bounds=get(gui.subROI,'userdata');
    
    vals.time = time;
    vals.temperature1 = temperature1; vals.temperature2 = temperature2;
    vals.control = control; vals.setpoint = setpoint;
    vals.tempstate = tempstate; vals.vibrationY = vibrationY;
    vals.vibrationX = vibrationX; vals.vibrationZ = vibrationZ;
    vals.bounds = bounds;
    
    data.vals = vals;
    data.failure = 0;

    data.errorcode = '';
    
    %EXPERIMENT VALIDATION------------------------------------
    
    %verify temperature in range during exp
    if length(experiment.actionlist) == 1
        if experiment.actionlist(1).T < 25
            indsCool = (tempstate==1);
            data.coolMaxVar = max(abs(temperature(indsCool)-setpoint(indsCool)));
            indsHot = []; %#ok<NASGU>
            data.hotMaxVar = nan;
        else
            indsCool = [];
            data.coolMaxVar = nan;
            indsHot = (tempstate==1);
            data.hotMaxVar = max(abs(temperature(indsHot)-setpoint(indsHot)));
        end
        data.transitionDuration = nan;
        
        % TODO: any other single-temp validation to be done?
    else
        indsCool = (tempstate==1);
        indsHot = (tempstate==2);
        data.coolMaxVar = max(abs(temperature(indsCool)-setpoint(indsCool)));
        data.hotMaxVar = max(abs(temperature(indsHot)-setpoint(indsHot)));

        %verify Transition Region
        heatStarti = find(tempstate == 2,1,'first');
        coolEndi = find(tempstate ==1,1,'last');

        %was there a region 1.5 (section between low and high temp)
        if ~isempty(heatStarti)
            %what was the duration of this transition region
            data.transitionDuration=time(heatStarti)-time(coolEndi);
            if (data.transitionDuration < gui.settings.minRamp) ||...
                    (data.transitionDuration > gui.settings.maxRamp)
                data.failure = 1;
                data.errorcode = 'Temp Ramp Duration Out Of Range';
            end
        else
            data.transitionDuration = nan;
            data.failure = 2;
            data.errorcode = 'No Transition from Hot to Cold';
        end
    end
 
    
    %get user check boxes and notes field
    data=setfield(data,gui.settings.button(1).name,get(gui.userCheck(1),'value')); 
    data=setfield(data,gui.settings.button(2).name,get(gui.userCheck(2),'value')); 
   
    %Code modified in V3.0
    %Code change begins
    % check flag_review
    data.Questionable_Data = handles.defaultsTree.getNodeByPathString('flag_review').value;
        
    % check flag_redo
    data.Redo_Experiment = handles.defaultsTree.getNodeByPathString('flag_redo').value;
    
    % grab notes
    % update defaults tree notes from gui to make sure latest changes are
    % seen
    data.NotesBehavioral = handles.defaultsTree.getNodeByPathString('notes_behavioral.content').value;
    data.NotesTechnical = handles.defaultsTree.getNodeByPathString('notes_technical.content').value;
    data.Operator = handles.defaultsTree.getNodeByPathString('experimenter').value;
    %Code change ends
    
    %max vibration
    data.maxVibration = max(sqrt(vibrationX.^2+vibrationY.^2+vibrationZ.^2));
    
    %Experiment Duration
    data.totalDurationStr = get(gui.TotalTime,'string');
    a = sscanf(data.totalDurationStr,'Total: [%d:%02d:%02d]');
    data.totalDurationSeconds = a(1)*60*60 + a(2)*60 + a(3);
    
    %other failure modes
    data.forceSeqStart = expstate.forceSeq;  %hitting the force sequence start button
    data.haltEarly = expstate.haltEarly; %if the experiment was halted manually by the user
    if data.forceSeqStart
        data.failure = 3;
        data.errorcode = 'Skipped a Temperature Settling Sequence';
    end
    if data.haltEarly
        data.failure = 4;
        data.errorcode = 'Halted Experiment Early';
    end
    
    %popup modal dialog about experiment completion
    %stick data into figure, save all data when figure closed
    ui.wrapupfig = figure('WindowStyle','modal','tag','ConfirmExp','resize','off',...
        'units','pixel','position',[0 0 400 400],'name','Experiment Results Validation','numbertitle','off',...
        'closerequestfcn','');
     
    
    if data.failure
        set(ui.wrapupfig,'color','r')
        set(ui.wrapupfig,'name',['Failure: ',data.errorcode])
    elseif expstate.error8
        set(ui.wrapupfig,'color','r')
        set(ui.wrapupfig,'name','Failure: I2C Hang')
    end
    ui.valspan = uipanel('parent',ui.wrapupfig,'units','pixels','position',[0 300 400 98],'title','Experiment Parameters','fontweight','bold');
    ui.techpan = uipanel('parent',ui.wrapupfig,'units','pixels','position',[0 180 400 118],'title','Technical Issues?','fontweight','bold');
    ui.behaviorpan = uipanel('parent',ui.wrapupfig,'units','pixels','position',[0 60 400 118],'title','Fly Behavioral Issues?','fontweight','bold');
    ui.ok = uicontrol('style','pushbutton','string','Ok','enable','off','units','pixels',...
        'position',[250 10 100 40],'callback',{@closeReqValidate,gui.fig,expstate,fname,data},'fontweight','bold');
    
    %Experiment Parameters display (DeltaT heat/cool, max motor, ramp time, total duration)
    uicontrol(ui.valspan,'style','text','units','normalized','position',[0.05 0.8 .55 .2],'horizontalalignment','left',...
        'string',sprintf('Cool to Hot Transition Time: %.2f (min)',data.transitionDuration));
    uicontrol(ui.valspan,'style','text','units','normalized','position',[0.05 0.6 .55 .2],'horizontalalignment','left',...
        'string',sprintf('DeltaT During Cool (first): %.2f C',data.coolMaxVar));
    uicontrol(ui.valspan,'style','text','units','normalized','position',[0.05 0.4 .55 .2],'horizontalalignment','left',...
        'string',sprintf('DeltaT During Hot (Second): %.2f C',data.hotMaxVar));
    uicontrol(ui.valspan,'style','text','units','normalized','position',[0.05 0.2 .55 .2],'horizontalalignment','left',...
        'string',sprintf('Max Motor Amp: %.2f',data.maxVibration));
    uicontrol(ui.valspan,'style','text','units','normalized','position',[0.05 0.0 .55 .2],'horizontalalignment','left',...
        'string',sprintf('Experiment Duration: %s',data.totalDurationStr));
    
    uicontrol(ui.valspan,'style','text','units','normalized','position',[0.6 0.8 .4 .2],'horizontalalignment','left',...
        'string',sprintf('Max During Cool: %.2fC',max(temperature(indsCool))));
    uicontrol(ui.valspan,'style','text','units','normalized','position',[0.6 0.6 .4 .2],'horizontalalignment','left',...
        'string',sprintf('Max Total Exp: %.2fC',max(temperature)));
    uicontrol(ui.valspan,'style','text','units','normalized','position',[0.6 0.4 .4 .2],'horizontalalignment','left',...
        'string',sprintf('Max Vibration: %.2f',max(sqrt(vibrationX.^2 + vibrationY.^2 + vibrationZ.^2))));
    
    %Technical issues ui
    ui.techN = uicontrol(ui.techpan,'style','radio','value',0,'units','normalized','position',[.05 .7 .3 .18],...
        'string','No Issues');
    ui.techY = uicontrol(ui.techpan,'style','radio','value',0,'units','normalized','position',[.05 .5 .3 .18],...
        'string','Yes Issues');
    ui.techUnk = uicontrol(ui.techpan,'style','radio','value',0,'units','normalized','position',[.05 .3 .3 .18],...
        'string','Unknown');
    set([ui.techN,ui.techY,ui.techUnk],'userdata',[ui.techN,ui.techY,ui.techUnk],'callback',{@uiradio,ui.wrapupfig})
    ui.techNotes = uicontrol(ui.techpan,'style','edit','min',0,'max',2,'unit','normalized','position',[.3 .1 .65 .8],...
        'horizontalalignment','left','backgroundcolor','w','callback',{@valNote,ui.wrapupfig});
    
    %behavioral issues ui
    ui.behaveN = uicontrol(ui.behaviorpan,'style','radio','value',0,'units','normalized','position',[.05 .7 .3 .18],...
        'string','No Issues');
    ui.behaveY = uicontrol(ui.behaviorpan,'style','radio','value',0,'units','normalized','position',[.05 .5 .3 .18],...
        'string','Yes Issues');
    ui.behaveUnk = uicontrol(ui.behaviorpan,'style','radio','value',0,'units','normalized','position',[.05 .3 .3 .18],...
        'string','Unknown');
    set([ui.behaveN,ui.behaveY,ui.behaveUnk],'userdata',[ui.behaveN,ui.behaveY,ui.behaveUnk],'callback',{@uiradio,ui.wrapupfig})
    ui.behaveNotes = uicontrol(ui.behaviorpan,'style','edit','min',0,'max',2,'unit','normalized','position',[.3 .1 .65 .8],...
        'horizontalalignment','left','backgroundcolor','w','callback',{@valNote,ui.wrapupfig});
    
    
    set(ui.behaveNotes,'string', handles.defaultsTree.getNodeByPathString('notes_behavioral.content').value);
    set(ui.techNotes,'string', handles.defaultsTree.getNodeByPathString('notes_technical.content').value);
    
    
    set(ui.wrapupfig,'userdata',ui)
    centerfig(ui.wrapupfig)
    
elseif gui.c == 1  %if in calibration mode
    
    %store all the temperature values 
    calData.T(1).data=get(gui.TPl(1),'ydata');
    calData.T(1).name='Dummy Tube 1';
    calData.T(2).data=get(gui.TPl(2),'ydata');
    calData.T(2).name='Dummy Tube 2';
    for i = 1:6
        calData.T(2+i).data = get(gui.calPl(i),'ydata');
    end
    calData.T(3).name = 'Tube 6, Left';
    calData.T(4).name = 'Tube 6, Right';
    calData.T(5).name = 'Tube 1, Left';
    calData.T(6).name = 'Tube 4, Left';
    calData.T(7).name = 'Tube 4, Right';
    calData.T(8).name = 'Tube 1, Right';
    
    
    calData.setpoint = get(gui.Tsp,'ydata');
    calData.control = 200*(get(gui.controlPlot,'ydata')-18)/(36-18)-100;
    calData.state = get(gui.stateLine,'ydata')-18;
    
    calData.time = get(gui.Tsp,'xdata');
    calData.date = datestr(now);
    calData.boxName = gui.boxName;
    calData.boxID = gui.boxID;
    calData.TopPlate = gui.snum;
    
    %Log the calibration data to a file
    datafile = fullfile(expstate.expdir,[num2str(gui.boxID),'_',gui.boxName,'_',datestr(now,29),'_TempCal','.mat']);
    save(datafile,'calData')
    
    %Draw the data into a figure for display
    tempfig = figure('name','Temperature Calibration Output');
    plot(calData.time,calData.control,'color',[0 .5 0],'linewidth',2,'DisplayName','Control Signal');
    ax1 = gca;
    set(ax1,'ylim',[-100 100],'YAxisLocation','right','ycolor',[0 .5 0])
    xlabel('Time (min)')
    ylabel('Heat Power Output (%)')
    title([num2str(gui.boxID),' ',gui.boxName,' ',datestr(now,29),' Temperature Calibration'])
    
    ax2=axes('position',get(ax1,'position'),'color','none');
    plot(calData.time,calData.setpoint,'color',[.8 .8 .8],'linewidth',2,'DisplayName','Set Point');
    hold on
    for i=1:8
        tempPl(i)=plot(calData.time,calData.T(i).data,'DisplayName',calData.T(i).name);
    end
    
    set(tempPl(1),'color','k','linestyle','-')
    set(tempPl(2),'color','k','linestyle','--')
    set(tempPl(3),'color','r','linestyle','--') %1
    set(tempPl(4),'color','r','linestyle','-') %2
    set(tempPl(5),'color','b','linestyle','--') %3
    set(tempPl(6),'color','g','linestyle','--') %4
    set(tempPl(7),'color','g','linestyle','-') %5
    set(tempPl(8),'color','b','linestyle','-') %6
    
    set(ax2,'ylim',[18 36])
    ylabel('Degrees C');
    
    legend('location','best');
    
    %Capture a screen shot of the plotted data to associate with the
    %calibration data results logged above
    f = getframe(gcf);
    imagefile = fullfile(expstate.expdir,[num2str(gui.boxID),'_',gui.boxName,'_',datestr(now,29),'_TempCal','.png']);
    imwrite(f.cdata,imagefile,'PNG')
    
    
end

%%%UIHANDLING CODE FOR WRAPUPFIG
function uiradio(obj,~,fig)
%exclusive radio buttons in a group
set(get(obj,'userdata'),'value',0)
set(obj,'value',1)
ui = get(fig,'userdata');
valValidate(ui)

function valNote(~,~,fig)
ui = get(fig,'userdata');
valValidate(ui)

%Enable or disable OK button given response state
function valValidate(ui)

set(ui.ok,'enable','off')
en = 0;

sT = get(ui.techNotes,'string');
sB = get(ui.behaveNotes,'string');
techN = get(ui.techN,'value');
techY = get(ui.techY,'value');
techU = get(ui.techUnk,'value');
behN = get(ui.behaveN,'value');
behY = get(ui.behaveY,'value');
behU = get(ui.behaveUnk,'value');

%if tech issues, require text in notes field
if (techY||techU)&&(numel(sT)~=0) en = 1;
elseif techN; en = 1;
else en = 0; end

%if behavior issues, require text in notes field
if (behY||behU)&&(numel(sB)~=0); en = en;
elseif behN; en=en;
else en = 0; end


%if conditions are met, allow the window to be closed
if en; set(ui.ok,'enable','on'); end

%When user completes log the data out to the RunData file
function closeReqValidate(~,~,fig,expstate,fname,data)
global handles;
gui = get(fig,'userdata');
ui = get(gcbf,'userdata');

time = data.vals.time;
temperature1 = data.vals.temperature1; temperature2 = data.vals.temperature2;
temperature = (temperature1+temperature2)/2;
control = data.vals.control; setpoint = data.vals.setpoint;
tempstate = data.vals.tempstate; vibrationY = data.vals.vibrationY;
vibrationX = data.vals.vibrationX; vibrationZ = data.vals.vibrationZ;
bounds = data.vals.bounds;
OperatorName = data.Operator; 
data = rmfield(data,'vals');
i2cHang = expstate.error8;

%Code modified in V3.0
%Code change begins 
if(get(ui.techN,'value'))
    data.techIssue = 'No';
elseif get(ui.techY,'value')
    data.techIssue = 'Yes';
elseif get(ui.techUnk,'value')
    data.techIssue = 'Unknown';
end

data.NotesTechnical = get(ui.techNotes,'string');

if(get(ui.behaveN,'value'))
    data.behaveIssue = 'No';
elseif get(ui.behaveY,'value')
    data.behaveIssue = 'Yes';
elseif get(ui.behaveUnk,'value')
    data.behaveIssue = 'Unknown';
end
data.NotesBehavioral = get(ui.behaveNotes,'string');
%end addition 1/18/11 gkl
%Code change ends

datafile=[fname,'_RunData','.mat'];
save(fullfile(expstate.expdir,datafile),...
    'temperature1','temperature2','temperature','time','control','setpoint','tempstate',...
    'vibrationY','vibrationX','vibrationZ','bounds','OperatorName','data','i2cHang');

%Code modified in V3.0
% KB: copy over defaults file
[~,name,ext] = fileparts(handles.defaultsTreeFileName);
outfilename = fullfile(expstate.expdir,[name,ext]);
[success,msg] = copyfile(handles.defaultsTreeFileName,outfilename);
if ~success,
    warning('Could not copy defaults file %s to %s:\n%s',...
        handles.defaultsTreeFileName,outfilename,msg);
end

%Code modified in V3.0
%Code change begins
handles.pgrid.setValueByPathString('flag_aborted.content',data.haltEarly);
handles.defaultsTree.setValueByPathString('notes_technical',data.NotesTechnical);
handles.defaultsTree.setValueByPathString('notes_behavioral',data.NotesBehavioral);

XmlFileName = [fname,'_Metadata','.xml'];
metaDataTree = createXMLMetaData(handles.defaultsTree);
metaDataTree.write(fullfile(expstate.expdir,XmlFileName));
% KB: write defaults file so that last values are stored
handles.defaultsTree.write(handles.defaultsTreeFileName);
% refresh JGrid
pause(.1);
InitializeJGrid();
%Code change ends

delete(ui.wrapupfig)
%delete(d);

%Clear notes fields
set(gui.userNotesT,'string','')
set(gui.userNotesB,'string','')

%CLOSE OUT EXPERIMENT, SAVE DATA (including temperature) & CONFIG
function wrapupSeq(experiment,expstate,fig) %#ok<INUSL>
global handles;
gui=get(fig,'userdata');

expstate.dir(expstate.i).name
%Save Experiment and Analysis details m file
ff=fullfile(expstate.expdir,expstate.dir(expstate.i).name,['sequence_details_',get(gui.ExpName,'string'),'.m']);
a=fopen(ff,'w');
fwrite(a,['% analyze ',get(gui.ExpName,'string'),' data:']);
fprintf(a,'\n'); fprintf(a,'\n');
fwrite(a,['% path to one folder w. 5 movies:']);fprintf(a,'\n');
fwrite(a,'analysis_detail.exp_path = ''O:\'';');fprintf(a,'\n');
fwrite(a,'analysis_detail.analysis_path = ''\Output'';');fprintf(a,'\n');
for i=1:5
    fwrite(a,['analysis_detail.seq(',sprintf('%01d',i),').path = ''\',sprintf('%02d',expstate.i),get(gui.ExpName,'string'),'_seq',sprintf('%01d',i),''';']); fprintf(a,'\n');
    %     fwrite(a,['analysis_detail.seq(',sprintf('%02d',i),').path = ''\',sprintf('%02d',expstate.i),'_2.7_seq',num2str(i),''';']); fprintf(a,'\n');
end

%Analysis Detail information here
fprintf(a,'\n');
fwrite(a,['% create exp_detail and tube_info structure']); fprintf(a,'\n');
fwrite(a,['exp_detail.date_time = ''',expstate.start,'''; %as a matlab standard ''yyyymmddTHHMMSS''']); fprintf(a,'\n');
fprintf(a,'\n');

for i=1:6
%Code modified in V3.0
    %Code change begins
    gt=get(gui.tube(i).Genotype,'string');
    fwrite(a,['[exp_detail.tube_info(',num2str(i),').Genotype] = ','''',gt{get(gui.tube(i).Genotype,'value')},''';']); fprintf(a,'\n');
    linename = handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.line',i)).value;
    effector = handles.defaultsTree.getNodeByPathString(sprintf('session_%d.flies.effector',i)).value;
    fwrite(a,['[exp_detail.tube_info(',num2str(i),').Line] = ','''',linename,''';']); fprintf(a,'\n');
    fwrite(a,['[exp_detail.tube_info(',num2str(i),').Effector] = ','''',effector,''';']); fprintf(a,'\n');
    gt=get(gui.tube(i).Gender,'string');
    fwrite(a,['[exp_detail.tube_info(',num2str(i),').Gender] = ','''',gt{get(gui.tube(i).Gender,'value')},''';']); fprintf(a,'\n');
    fwrite(a,['[exp_detail.tube_info(',num2str(i),').n] = ',get(gui.tube(i).n,'string'),';']); fprintf(a,'\n');
    fwrite(a,['[exp_detail.tube_info(',num2str(i),').n_dead] = ',get(gui.tube(i).n_dead,'string'),';']); fprintf(a,'\n');
    fwrite(a,['[exp_detail.tube_info(',num2str(i),').DOB] = ','''',get(gui.tube(i).DOB,'string'),''';']); fprintf(a,'\n');
    gt=get(gui.tube(i).Rearing,'string');
    fwrite(a,['[exp_detail.tube_info(',num2str(i),').Rearing] = ','''',gt{get(gui.tube(i).Rearing,'value')},''';']); fprintf(a,'\n');
    fwrite(a,['[exp_detail.tube_info(',num2str(i),').Starved] = ',get(gui.tube(i).Starved,'string'),'; % in hours']); fprintf(a,'\n');
    fprintf(a,'\n');
    %Code change ends
end

fprintf(a,'\n%% BoxName\n');
fprintf(a,'BoxName = ''%s'';\n',gui.boxName);
fprintf(a,'TopPlateID = ''%s'';\n',dec2hex(gui.snum));
fprintf(a,'\n');

fclose(a);

%Initialize video for temperature track before sequence
function avifname=initTvidFile(expstate,experiment,gui)

avifname=[sprintf('%02d',expstate.i),'_Transition_to_',...
    experiment.actionlist(expstate.i).name];

switch get(gui.splitTubes,'value')
    case 1
        for i=1:6
            logger(i).aviobj=avifile(fullfile(expstate.expdir,...
                [avifname,'_tube',num2str(i),'.avi']));
            logger(i).aviobj.Colormap=gray(256);
            logger(i).aviobj=set(logger(i).aviobj,'compression','none','fps',25);
            logger(i).ROIs=get(gui.subROI,'userdata');
        end
        set(gui.vi,'DiskLogger',[],'loggingmode','memory','userdata',logger,...
            'framesacquiredfcncount',1,...
            'framesacquiredfcn',{@TFAF,gui.fig,1},'stopfcn',{@TFAF_clean,gui.fig})
    case 0
        logger=avifile(fullfile(expstate.expdir,[avifname,'.avi']));
        logger.Colormap=gray(256);
        logger=set(logger,'compression','none','fps',25);
        set(gui.vi,'loggingmode','disk','framesacquiredfcn','',...
            'stopfcn',{@TFAF_clean,gui.fig},'userdata',[])
        set(gui.vi,'DiskLogger',logger)
end

%called if writing tubes during a temperature ramp
function TFAF(obj,~,fig,fafc) %#ok<INUSL>
logger=get(obj,'userdata');
cdata=getdata(obj,fafc);
b=logger(1).ROIs.b;
if strcmpi(obj.running,'off'); return; end

%Add temperature measurement to one or two of the pixel values?

for i=1:6
    frame.colormap=[];
    frame.cdata=cdata(b(i,2):(b(i,2)+b(i,4)),b(i,1):(b(i,1)+b(i,3)),1);
    try logger(i).aviobj=addframe(logger(i).aviobj,frame); end %catching here because sometimes, this is closed by stop fcn before completed (not relevant in this writing mode)
end
set(obj,'userdata',logger)

%called when stoping writing (cleanup video files that are open)
function TFAF_clean(obj,~,fig)
gui=get(fig,'userdata');

if ~isempty(get(obj,'userdata')) %clean up tube videos
    logger=get(obj,'userdata');
    for i=1:6
        logger(i).aviobj=close(logger(i).aviobj);
    end
elseif ~isempty(get(obj,'disklogger'))
    logger=get(obj,'disklogger');
    logger=close(logger);
end

set(gui.vidMode,'string','Preview','backgroundcolor','r')
set(gui.vidFile,'string','')
set(gui.vidFrameRate,'string','')
disp('%called when stoping writing (cleanup)')

%parse out videos if any for the sequence
function seq=initVideoFiles(expstate,experiment,gui)
gui.vi.DiskLogger=[];
action=experiment.actionlist(expstate.i).action;
seq.vidTimes=[];
seq.stopTimes=[];
seq.vidinds=[];
for i=1:length(action)
    if action(i).command(1)==3&&action(i).command(2)~=0
        seq.vidTimes=[seq.vidTimes,action(i).time];
        seq.vidinds=[seq.vidinds,i];
    end
    if action(i).command(1)==3&&action(i).command(2)==0
        seq.stopTimes=[seq.stopTimes,action(i).time];
    end
end
try stop(gui.vi); end
seq.datetime=datestr(now,30);
seq.dir=fullfile(expstate.expdir,expstate.dir(expstate.i).name,'');
seq.name=[sprintf('%02d',expstate.i),'_',experiment.actionlist(expstate.i).name];

seq.vidlength=seq.stopTimes-seq.vidTimes;
seq.vidTimes=seq.vidTimes/1000; %in seconds
seq.stopTimes=seq.stopTimes/1000;
seq.startTimes=seq.vidTimes-2; %Start video 2 seconds before triggering begins
seq.i=1;


if isempty(seq.vidTimes)
    gui.vi.userdata=[];
    seq.vidinds=[];
else
    %Prep full frame or sub-ROI video files
    switch get(gui.splitTubes,'value')
        case 0 %full frame
            for i=1:length(seq.vidinds)
                fname=[seq.name,'_',action(seq.vidinds(i)).userdata];
                seq.fnames{i}=fname;
                seq.frates{i}=num2str(1000/action(seq.vidinds(i)).command(2));
                
                ff=fullfile(seq.dir,fname)
                logger(i).aviobj=avifile(ff);              
                logger(i).aviobj.Fps=1000/action(seq.vidinds(i)).command(2);
                logger(i).aviobj.Compression='none';
                logger(i).aviobj.Colormap=gray(256);
                logger(i).targetFrames=seq.vidlength(i)/action(seq.vidinds(i)).command(2);
                if logger(i).targetFrames==round(logger(i).targetFrames)
                    logger(i).targetFrames=logger(i).targetFrames+1;
                else
                    logger(i).targetFrames=floor(logger(i).targetFrames);
                end
            end
            gui.vi.LoggingMode='memory';
            gui.vi.framesacquiredfcncount=1;
            gui.vi.framesacquiredfcn={@WriteFullAVI,gui.fig,gui.vi.framesacquiredfcncount};
            gui.vi.stopfcn='';
            gui.vi.userdata=logger;
        case 1 %individual tubes
            b=get(gui.subROI,'userdata');
            %create all video files
            for j=1:length(seq.vidinds)
                fname=[seq.name,'_',action(seq.vidinds(j)).userdata];
                seq.fnames{j}=fname;
                seq.frates{j}=num2str(1000/action(seq.vidinds(j)).command(2));
                
                for i=1:6
                    fname=[seq.name,'_',action(seq.vidinds(j)).userdata(1:(end-4)),'_tube',num2str(i),'.avi'];
                    ff=fullfile(seq.dir,fname);
                    logger(i,j).aviobj=avifile(ff);
                    logger(i,j).aviobj.Fps=1000/action(seq.vidinds(j)).command(2);
                    logger(i,j).aviobj.Compression='none';
                    logger(i,j).aviobj.Colormap=gray(256);
                    logger(i,j).ROIs=b;
                    logger(i,j).targetFrames=seq.vidlength(j)/action(seq.vidinds(j)).command(2);
                    if logger(i,j).targetFrames==round(logger(i,j).targetFrames)
                        logger(i,j).targetFrames=logger(i,j).targetFrames+1;
                    else
                        logger(i,j).targetFrames=floor(logger(i,j).targetFrames);
                    end
                end
            end
            gui.vi.LoggingMode='memory';
            gui.vi.framesacquiredfcncount=1;
            gui.vi.framesacquiredfcn={@WriteSubAVIs,gui.fig,gui.vi.framesacquiredfcncount};
            gui.vi.stopfcn='';
            gui.vi.userdata=logger;
    end
    
    %if first initialization is at t<=3 seconds, start video object in trigger mode
    if seq.startTimes(1)<=3
        start(gui.vi); 
    end
end

%DURING SEQUENCE, WRITE SUB-AVI FILES
function WriteSubAVIs(obj,~,fig,fafc)
gui=get(fig,'userdata');
logger=get(obj,'userdata');
seq=get(gui.MCU,'userdata');
cdata=getdata(obj,fafc);
b=logger(1).ROIs;
b=b.b;
t(1)=round(gui.tempVALUE);
t(2)=round((gui.tempVALUE-t(1))*100);

for j=1:fafc
    for i=1:6
        frame.colormap=[];
        frame.cdata=cdata(b(i,2):(b(i,2)+b(i,4)),b(i,1):(b(i,1)+b(i,3)),1);
        %tag temperature stamp to each frame
        frame.cdata(1,1) = t(1);
        frame.cdata(1,2) = t(2);
        logger(i,seq.i).aviobj=addframe(logger(i,seq.i).aviobj,frame);
    end
end
set(obj,'userdata',logger)

targetFrames=logger(1,seq.i).targetFrames;
storedFrames=logger(1,seq.i).aviobj.TotalFrames;

set(gui.vidFrameRate,'string',[num2str(storedFrames),' / ',num2str(targetFrames)])

%If completed, close video files
if storedFrames==targetFrames
    disp([num2str(storedFrames),' Frames Saved of ',num2str(targetFrames),' Triggered'])
    prepVid(fig)
end

%DURING SEQUENCE, WRITE FULL AVI FILE
%currently fafc must be 1
function WriteFullAVI(obj,~,fig,fafc)
gui=get(fig,'userdata');
logger=get(obj,'userdata');
cdata=getdata(obj,fafc);
seq=get(gui.MCU,'userdata');

frame.colormap=[];
frame.cdata=cdata;

%tag temperature stamp to each frame
t(1)=round(gui.tempVALUE);
t(2)=round((gui.tempVALUE-t(1))*100);
if isnan(gui.tempVALUE)
    t=[0 0];
end
frame.cdata(1,1) = t(1);
frame.cdata(1,2) = t(2);

logger(seq.i).aviobj=addframe(logger(seq.i).aviobj,frame);

set(obj,'userdata',logger)


targetFrames=logger(seq.i).targetFrames;
storedFrames=logger(seq.i).aviobj.TotalFrames;

set(gui.vidFrameRate,'string',[num2str(storedFrames),' / ',num2str(targetFrames)])

%If completed, close video files
if storedFrames==targetFrames
    disp([num2str(storedFrames),' Frames Saved of ',num2str(targetFrames),' Frames Triggered'])
    set(gui.vidFrameRate,'string',[num2str(storedFrames),' / ',num2str(targetFrames)])
    obj.tag='0';
    prepVid(fig)
end

%PREPARE NEXT VIDEO FILE FOR SEQUENCE
function prepVid(fig)
gui=get(fig,'userdata');
seq=get(gui.MCU,'userdata');
% experiment=get(gui.SequenceOrder,'userdata');
% expstate=get(timerfind,'userdata');
% action=experiment.actionlist(expstate.i).action;

seq.i=seq.i+1;
set(gui.MCU,'userdata',seq)

if seq.i>length(seq.vidinds); stop(gui.vi); return; end

if (seq.startTimes(seq.i)-3)<=get(gui.SeqTime,'userdata')
    set(gui.vidMode,'string','Recording','backgroundcolor','g')
    disp('In prepvid-------------------')
    %leave vi running
else
    stop(gui.vi)
    set(gui.vidMode,'string','Previewing','backgroundcolor','r')
end
% nframes=floor((seq.stopTimes(seq.i) - seq.vidTimes(seq.i))/(action(seq.vidinds(seq.i)).command(2)/1000));

%Parse the experiment and send it to the controller for execution
function UploadExp(gui,action,pattern)


%write patterns
disp('Sending Patterns - 25/25')
%     disp(['Sending Patterns - Memory Used: ',num2str(length(pattern.inds)),'/25'])
for i=1:25
    fwrite(gui.MCU,1)
    fwrite(gui.MCU,[pattern.inds(i),pattern.bytes(i,:)])
    %set(gui.MCU.Source,'WriteBuffer',1)
    %set(gui.MCU.Source,'WriteBuffer',[pattern.inds(i),pattern.bytes(i,:)])
    pause(.02)
end

tic
while(gui.MCU.bytesavailable<50&toc<1)
%while(gui.MCU.framesavailable<50&toc<1)
    drawnow
end
disp([num2str(gui.MCU.bytesavailable)])
%disp([num2str(gui.MCU.framesavailable)])

%if ~isempty(pattern.inds);
if (gui.MCU.bytesavailable>0)
    fread(gui.MCU,gui.MCU.bytesavailable);
    %getdata(gui.MCU,gui.MCU.framesavailable);
end

NCOMMANDS = 300;
%parse and write commands
command=zeros(NCOMMANDS,5);
sendtimes=zeros(NCOMMANDS*4,1);

for i=1:length(action)
    command(i,:)=action(i).command;
end

% command(1:10,:)

j=1;
for i=1:length(action)
    val=dec2binvec(action(i).time,32);
    sendtimes(j)=binvec2dec(val(25:32)); j=j+1;
    sendtimes(j)=binvec2dec(val(17:24)); j=j+1;
    sendtimes(j)=binvec2dec(val(9:16)); j=j+1;
    sendtimes(j)=binvec2dec(val(1:8)); j=j+1;
end

%Write TimeStamps
disp(['Sending Time & Commands - Memory Used: ',num2str(length(action)),'/',num2str(NCOMMANDS)])
fwrite(gui.MCU,2)
fread(gui.MCU,1);
fwrite(gui.MCU,sendtimes(:)');
temp = fread(gui.MCU,1);
%set(gui.MCU.Source,'WriteBuffer',2)
%getdata(gui.MCU,1);
%set(gui.MCU.Source,'WriteBuffer',sendtimes(:)');
%temp = getdata(gui.MCU,1);
disp(char(temp(:)'))

%Write Commands
sendcommand=[];
for i=1:size(command,1)
    sendcommand=[sendcommand,command(i,:)];
end
fwrite(gui.MCU,4);
fread(gui.MCU,1);
fwrite(gui.MCU,sendcommand);
%set(gui.MCU.Source,'WriteBuffer',4);
%getdata(gui.MCU,1);
%set(gui.MCU.Source,'WriteBuffer',sendcommand);

temp = fread(gui.MCU,1);
%temp = getdata(gui.MCU,1);
disp(char(temp(:)'))

disp('Upload Complete')

function exec_BAF(obj,~,fig,agent,fleacam)

gui=get(fig,'userdata');
if obj.bytesavailable==0; return; end
%if obj.framesavailable==0; return; end
scode = double(fread(obj,5));
%scode = double(getdata(obj,5));
scode = scode(:)';

printCommand(scode);
seq=get(gui.MCU,'userdata');
expstate=get(agent,'userdata');
% disp(num2str(scode));
switch scode(1)
    case 251 %Time Code
        rawsec=(scode(2)*(256^3)+scode(3)*(256^2)+scode(4)*(256^1)+scode(5)*(256^0))/1000;
        
        rawsec=floor(rawsec);
        expstate.BAFtime=expstate.BAFtime+1;
        if expstate.BAFtime~=rawsec
            disp(['Debug: ',num2str(rawsec),' - ',num2str(expstate.BAFtime),' - CODE: [',num2str(scode),']'])
        end
        if (expstate.BAFtime~=rawsec)&(expstate.BAFtime == (rawsec+1))
            expstate.BAFtime = rawsec;
        end
        rawsec = expstate.BAFtime;
        set(agent,'userdata',expstate)
        
        shifttime(gui,rawsec);
        
        %Check to see if a video "start" is required
        try
            if length(seq.startTimes)>=(seq.i)
                if (seq.startTimes(seq.i)<=rawsec)&strcmpi(get(gui.vi,'running'),'off')
                    start(gui.vi)
%                     disp('agent line 1224')

                    %open video file
                    fleacam.stopCapture()
                    
                end
            end
        end
    case 0 %end sequence
        rawsec=(scode(2)*(256^3)+scode(3)*(256^2)+scode(4)*(256^1)+scode(5)*(256^0))/1000;
        shifttime(gui,rawsec);
        expstate=get(agent,'userdata');
        expstate.seqComplete=1;
        set(agent,'userdata',expstate)
        obj.bytesavailablefcn='';
        %obj.framesacquiredfcn='';
        
        fwrite(obj,254)
        fread(obj,1);

        %set(obj.Source,'WriteBuffer',254)
        %getdata(obj,1);
        
    case 3 %handle video wrapup
        switch scode(2)
            case 0 % end video file
                disp('% end video file')
                set(gui.vidMode,'string','Previewing','backgroundcolor','r')
                
                fleacam.stopCapture(); %fleacam
                fleacam.disableLogging();
                fleacam.startCapture();
                
                set(gui.vidFile,'string','')
                set(gui.vidFrameRate,'string','')
                targetFrames=scode(3)*256*256+scode(4)*256+scode(5);
                str=['Video Acquisition Completed - ',num2str(targetFrames),' frames clocked by MCU '] ;
                

                disp(str)
            otherwise %start video file
                fleatime=datestr(now,30); %fleacam
                fleacam.setVideoFile(['fleacam_','_',seq.fnames{seq.i}]);
%                 fleacam.getVideoFile
                
                str=[num2str(1000/scode(2)),'fps'];
                set(gui.vidMode,'string','Recording','backgroundcolor','g')
                
                fleacam.stopCapture();
                fleacam.enableLogging();
                fleacam.startCapture(); 
                
                set(gui.vidFile,'string',seq.fnames{seq.i})
                set(gui.vidFrameRate,'string',str)
                

        end
    case 1
    case 2
    case 6
    case 7
    case 8 
        set(gui.error,'Value',1) %MCU error
        expstate.error8=1;
        set(agent,'userdata',expstate)
    otherwise
        disp('ERROR: Unrecognized Command - Serial error most likely cause')
        disp(fread(obj,1))
        %disp(getdata(obj,1))
        
        expstate.BAFtime=expstate.BAFtime+1;
        set(agent,'userdata',expstate)
end

function shifttime(gui,rawsec)
rawsec = double(rawsec);
hours=floor(rawsec/(60*60));
mins=floor((rawsec-hours*60*60)/60);
sec=floor(rawsec-hours*60*60-mins*60);
set(gui.SeqTime,'string',sprintf('This: [%d:%02d:%02d]',hours,mins,sec))
set(gui.SeqTime,'userdata',rawsec)
set(gui.visTimeLine,'xdata',[0 0]+rawsec);
set(gui.SeqTime,'userdata',rawsec)

%Parse commands and present readable response to the user about codes
function printCommand(scode)
disp(num2str(scode(1)))
if scode(1)~=251
    disp(num2str(scode))
else
     disp(num2str((scode(2)*256^3+scode(3)*256^2+scode(4)*256+scode(5))/1000))
end
%EOF