%% Function Calib2
% Version 1.1
% Author: Magnus Karlson, Lakshmi Ramasamy, Rowell Williams
% Last update done: September 27th 2011


function varargout = Calib2(varargin) %#ok<*STOUT>
delete(instrfind)
clc
global gui

idn = 'Calib2';
boxID ='Not connected';
boxConnect = false;
detectorConnect = false;
normFactor = 1;

%% initialize top plate serial communication
s=serial('COM8');
s.baudrate=115200;
s.flowcontrol='none';
s.inputbuffersize=10000;
s.bytesavailablefcnmode = 'terminator';
s.bytesavailablefcn=@receiveData;
set(s,'Terminator','CR/LF');
set(s,'DataBits',8);
set(s,'StopBits',2);
set(s,'DataTerminalReady','off');
fopen(s);

%% Initialize bottom plate serial communication
s2=serial('COM7');
s2.baudrate=57600;
s2.flowcontrol='none';
s2.inputbuffersize=10000;
set(s2,'DataBits',8);
set(s2,'StopBits',2);
set(s2,'DataTerminalReady','off');
fopen(s2);


%% Make GUI
gui.fig = figure('tag','main','numbertitle','off','menubar','none','name',idn,'visible','off', ...
    'position',[400,150,1200,700]);
set(gui.fig,'CloseRequestFcn',@closefcn);
set(gui.fig,'Visible','on');
set(s,'DataTerminalReady','on');
set(s2,'DataTerminalReady','on');

gui.darkmeasure = uicontrol('Parent', gui.fig,'Style','pushbutton','Units','normalized','HandleVisibility','callback', ...
    'BackGroundColor','red', ...
    'Value',0,'Position',[0.2 0.9 0.2 0.05],'String','Take dark measurement','Callback', @measureDarkButtonCallback);
gui.lightmeasure = uicontrol('Parent', gui.fig,'Style','pushbutton','Units','normalized','HandleVisibility','callback', ...
    'BackGroundColor','red', ...
    'Value',0,'Position',[0.6 0.9 0.2 0.05],'String','Take light measurement','Callback', @measureLightButtonCallback);

correctionData = [0.975 0.810 0.921 0.738 ;...
    0.989 0.962 1.212 0.965 ;...
    1.021 0.829 0.985 0.953 ;...
    1.022 0.885 1.339 0.692 ;...
    1.029 0.933 0.760 0.722 ;...
    1.018 0.829 1.032 0.827];


statusData = {'' ''; '' ''; '' ''; '' ''; '' ''; '' ''};
stable = uitable('Units', 'normalized',...
    'Position', [0.1 0.65 0.1 0.2],...
    'Data', statusData,...
    'ColumnName', {'Left','Right'},...
    'ColumnFormat', {'char'},...
    'ColumnWidth', {40},...
    'ColumnEditable', [false false]);


statusDataPer = zeros(6,4);
stablePer = uitable('Units', 'normalized',...
    'Position', [0.25 0.65 0.2 0.2],...
    'Data', statusDataPer,...
    'ColumnName', {'Gr_L', 'Gr_R', 'UV_L', 'UV_R'},...
    'ColumnFormat', {'numeric', 'numeric', 'numeric', 'numeric'},...
    'ColumnWidth', {40},...
    'ColumnEditable', [false false false false]);

detectorData = zeros(6,4);
%tablesize = size(detectorData);
colnames = {'Gr_L', 'Gr_R', 'UV_L', 'UV_R'};
colfmt = {'numeric', 'numeric', 'numeric', 'numeric'};
coledit = [false false false false];
colwdt = {60 60 60 60};
htable = uitable('Units', 'normalized',...
    'Position', [0.5 0.65 0.25 0.20],...
    'Data',  detectorData,...
    'ColumnName', colnames,...
    'ColumnFormat', colfmt,...
    'ColumnWidth', colwdt,...
    'ColumnEditable', coledit,...
    'ToolTipString',...
    'Select cells to highlight them on the plot',...
    'CellSelectionCallback', {@select_callback});

ylimits = [1500*normFactor 3000*normFactor];

haxes1 = axes('Units', 'normalized',...
    'Position', [0.05 0.05 0.4 .20],...
    'XLim', [1 8],...
    'YLim', ylimits,...
    'XLimMode', 'manual',...
    'YLimMode', 'manual',...
    'XTickLabel',...
    {'1','2','3','4','5','6', '7', '8'});
title(haxes1, 'Gr_L measurement plots');  % Describe data set
xlabel(haxes1, 'Time (Weeks)');

haxes2 = axes('Units', 'normalized',...
    'Position', [0.5 0.05 0.4 0.2],...
    'XLim', [1 8],...
    'YLim', ylimits,...
    'XLimMode', 'manual',...
    'YLimMode', 'manual',...
    'XTickLabel',...
    {'1','2','3','4','5','6', '7', '8'});
title(haxes2, 'Gr_R measurement plots');   % Describe data set
xlabel(haxes2, 'Time (Weeks)');

haxes3 = axes('Units', 'normalized',...
    'Position', [0.05 0.35 0.4 0.2],...
    'XLim', [1 8],...
    'YLim', ylimits,...
    'XLimMode', 'manual',...
    'YLimMode', 'manual',...
    'XTickLabel',...
    {'1','2','3','4','5','6', '7', '8'});
title(haxes3, 'UV_L measurement plots');   % Describe data set
%xlabel(haxes3, 'Time (Weeks)');

haxes4 = axes('Units', 'normalized',...
    'Position', [0.5 0.35 0.4 0.2],...
    'XLim', [1 8],...
    'YLim', ylimits,...
    'XLimMode', 'manual',...
    'YLimMode', 'manual',...
    'XTickLabel',...
    {'1','2','3','4','5','6', '7', '8'});
title(haxes4, 'UV_R measurement plots');   % Describe data set
%xlabel(haxes4, 'Time (Weeks)');

haxes5 = axes('Units', 'normalized',...
    'Position', [0.3 0.35 0.4 0.2],...
    'XLim', [1 6],...
    'YLim', [0 20],...
    'XLimMode', 'manual',...
    'YLimMode', 'manual',...
    'XTickLabel',...
    {'1','2','3','4', '5', '6'},...
    'XTick', [1 2 3 4 5 6]);

title(haxes5, 'Dark measurement plot');   % Describe data set
xlabel(haxes5, 'Tube No.');

set(haxes5, 'visible', 'off');

% Prevent axes from clearing when new lines or markers are plotted
hold(haxes1, 'all');
hold(haxes2, 'all');
hold(haxes3, 'all');
hold(haxes4, 'all');
hold(haxes5, 'all');

% haxes1legend = legend(haxes1, '1','2','3','4','5','6');
% haxes2legend = legend(haxes2, '1','2','3','4','5','6');
% haxes3legend = legend(haxes3, '1','2','3','4','5','6');
haxes4legend = legend(haxes4,  '1','2','3','4','5','6', 'location', [0.92 0.35 0.05 0.2]);


% Create an invisible marker plot of the data and save handles
% to the lineseries objects; use this to simulate data brushing.
hmkrs = plot(detectorData, 'LineStyle', 'none',...
    'Marker', 'o',...
    'MarkerFaceColor', 'r',...
    'HandleVisibility', 'off',...
    'Visible', 'off');

gui.recOn = false;

pause(.1)
fprintf(s2,'0');
pause(.1)
resp = fscanf(s2,'%s',5);
if (strcmp('JFRC1', resp) == true)
    boxID = 'Zeus';
    boxConnect = true;
elseif (strcmp('JFRC2', resp) == true)
    boxID = 'Orion';
    boxConnect = true;
elseif (strcmp('JFRC3', resp) == true)
    boxID = 'Athena';
    boxConnect = true;
elseif (strcmp('JFRC4', resp) == true)
    boxID = 'Apollo';
    boxConnect = true;
elseif (strcmp('JFRC5', resp) == true)
    boxID = 'Ares';
    boxConnect = true;
end
set(gui.fig,'name',sprintf('%s %s',idn, boxID));
if (detectorConnect == true)
    set(gui.darkmeasure,'BackgroundColor','yellow');
    set(gui.lightmeasure,'BackgroundColor','yellow');
end



%% Dark measurement
    function measureDarkButtonCallback(hObject, eventdata)
        if ((boxConnect == true)&&(detectorConnect == true))
            detectorData = zeros(6,4);
            set(gui.darkmeasure,'BackgroundColor','blue');
            
            
            set(haxes1, 'visible', 'off');
            set(haxes2, 'visible', 'off');
            set(haxes3, 'visible', 'off');
            set(haxes4, 'visible', 'off');
            set(haxes5, 'visible', 'on');
            
%             set(haxes1legend, 'visible', 'off');
%             set(haxes2legend, 'visible', 'off');
%             set(haxes3legend, 'visible', 'off');
            set(haxes4legend, 'visible', 'off');
            
            cla(haxes1);
            cla(haxes2);
            cla(haxes3);
            cla(haxes4);
            cla(haxes5);
            
            
            fileN = sprintf('EndcapLog_%s.%s',boxID,'txt');
            gui.logfileID = fopen(fileN,'a');
            gui.recOn = true;
            fprintf(s2,'1');% all lights off
            pause(.1)
            fprintf(s,'uva\n');% measure UV-A
            pause(1)
            fprintf(s,'uvb\n');%measure UV-B
            pause(1)
            fprintf(s,'gra\n');%measure GR-A
            pause(1)
            fprintf(s,'grb\n');% measure GR-B
            pause(1)
            measurements = round(detectorData./correctionData);
            set(htable,'data', measurements);
            set(haxes5, 'NextPlot', 'Add')
            plot(haxes5, measurements(:,1)*normFactor,'-.dr');
            plot(haxes5, measurements(:,2)*normFactor,'-.dg');
            plot(haxes5, measurements(:,3)*normFactor,'-.dm');
            plot(haxes5, measurements(:,4)*normFactor,'-.db');
            
            
            
            fprintf(gui.logfileID,'Dark Measurment Timestamp:%s\r\n',datestr(now,30));
            fprintf(gui.logfileID,'GR_L,%u,%u,%u,%u,%u,%u\r\n',...
                measurements(1,1),measurements(2,1),measurements(3,1),...
                measurements(4,1),measurements(5,1),measurements(6,1));
            fprintf(gui.logfileID,'GR_R,%u,%u,%u,%u,%u,%u\r\n',...
                measurements(1,2),measurements(2,2),measurements(3,2),...
                measurements(4,2),measurements(5,2),measurements(6,2));
            fprintf(gui.logfileID,'UV_L,%u,%u,%u,%u,%u,%u\r\n',...
                measurements(1,3),measurements(2,3),measurements(3,3),...
                measurements(4,3),measurements(5,3),measurements(6,3));
            fprintf(gui.logfileID,'UV_R,%u,%u,%u,%u,%u,%u\r\n',...
                measurements(1,4),measurements(2,4),measurements(3,4),...
                measurements(4,4),measurements(5,4),measurements(6,4));
            fprintf(gui.logfileID,'\r\n');
            gui.recOn = false;
            fclose(gui.logfileID);
            fileV = sprintf('DarkValues_%s.%s',boxID,'txt');
            gui.valuesfileID = fopen(fileV,'r');
            if gui.valuesfileID ~= -1
                Values = fscanf(gui.valuesfileID, '%u', [6,4]);
                error = 0;
                badEndcap = zeros(6,4);
                for i = 1:6
                    for j = 1:4
                        statusDataPer(i,j) = (measurements(i,j)/(Values(i,j)));
                        if (measurements(i,j) > (Values(i,j) + 5))
                            badEndcap(i,j) = 1;
                            error = 1;
                        end
                    end
                end
                if error == 1
                    set(gui.darkmeasure,'BackgroundColor','red');
                else
                    set(gui.darkmeasure,'BackgroundColor','green');
                end
                for i = 1:6
                    for j = 1:2
                        if badEndcap(i,j) == 1
                            statusData(i,j) = {'BAD!'};
                        elseif badEndcap(i, j+2) == 1
                            statusData(i,j) = {'BAD!'};
                        else
                            statusData(i,j) = {'OK'};
                        end
                    end
                end
                set(stable,'data', statusData);
                set(stablePer,'data', statusDataPer);
                fclose(gui.valuesfileID);
            else
                gui.valuesfileID = fopen(fileV,'w');
                fprintf(gui.valuesfileID,'%u %u %u %u %u %u\r\n',...
                    measurements(1,1),measurements(2,1),measurements(3,1),...
                    measurements(4,1),measurements(5,1),measurements(6,1));
                fprintf(gui.valuesfileID,'%u %u %u %u %u %u\r\n',...
                    measurements(1,2),measurements(2,2),measurements(3,2),...
                    measurements(4,2),measurements(5,2),measurements(6,2));
                fprintf(gui.valuesfileID,'%u %u %u %u %u %u\r\n',...
                    measurements(1,3),measurements(2,3),measurements(3,3),...
                    measurements(4,3),measurements(5,3),measurements(6,3));
                fprintf(gui.valuesfileID,'%u %u %u %u %u %u\r\n',...
                    measurements(1,4),measurements(2,4),measurements(3,4),...
                    measurements(4,4),measurements(5,4),measurements(6,4));
                fclose(gui.valuesfileID);
                set(gui.darkmeasure,'BackgroundColor','yellow');
            end
        end
    end

%% Light level measurement
    function measureLightButtonCallback(hObject, eventdata) %#ok<*INUSD>
        if ((boxConnect == true)&&(detectorConnect == true))
            detectorData = zeros(6,4);
            set(gui.lightmeasure,'BackgroundColor','blue');
            
            cla(haxes1);
            cla(haxes2);
            cla(haxes3);
            cla(haxes4);
            cla(haxes5);
            
            set(haxes1, 'visible', 'on');
            set(haxes2, 'visible', 'on');
            set(haxes3, 'visible', 'on');
            set(haxes4, 'visible', 'on');
            set(haxes5, 'visible', 'off');
            
            fileN = sprintf('EndcapLog_%s.%s',boxID,'txt');
            gui.logfileID = fopen(fileN,'a');
            gui.recOn = true;
            fprintf(s2,'6');% temporarily set UV to full intensity
            pause(1)
            fprintf(s2,'2');% turn on UV-A
            pause(.1)
            fprintf(s,'uva\n');% measure UV-A
            pause(1)
            fprintf(s2,'3');% turn on UV-B
            pause(.1)
            fprintf(s,'uvb\n');%measure UV-B
            pause(1)
            fprintf(s2,'4');% turn on GR-A
            pause(.1)
            fprintf(s,'gra\n');%measure GR-A
            pause(1)
            fprintf(s2,'5');% turn on GR-B
            pause(.1)
            fprintf(s,'grb\n');% measure GR-B
            pause(1)
            fprintf(s2,'1');
            pause(.1)
            fprintf(s2,'9');% restore UV back to 1/4 intensity
            measurements = round(detectorData./correctionData);
            set(htable,'data', measurements);
            
            
            fprintf(gui.logfileID,'Light Measurement Timestamp:%s\r\n',datestr(now,30));
            fprintf(gui.logfileID,'GR_L,%u,%u,%u,%u,%u,%u\r\n',...
                measurements(1,1),measurements(2,1),measurements(3,1),...
                measurements(4,1),measurements(5,1),measurements(6,1));
            fprintf(gui.logfileID,'GR_R,%u,%u,%u,%u,%u,%u\r\n',...
                measurements(1,2),measurements(2,2),measurements(3,2),...
                measurements(4,2),measurements(5,2),measurements(6,2));
            fprintf(gui.logfileID,'UV_L,%u,%u,%u,%u,%u,%u\r\n',...
                measurements(1,3),measurements(2,3),measurements(3,3),...
                measurements(4,3),measurements(5,3),measurements(6,3));
            fprintf(gui.logfileID,'UV_R,%u,%u,%u,%u,%u,%u\r\n',...
                measurements(1,4),measurements(2,4),measurements(3,4),...
                measurements(4,4),measurements(5,4),measurements(6,4));
            fprintf(gui.logfileID,'\r\n');
            gui.recOn = false;
            fclose(gui.logfileID);
            
            fileNlog = sprintf('EndcapLog_%s.%s',boxID,'log');
            save(fileNlog, 'measurements', '-ASCII', '-append');
            logData = load(fileNlog);
            
            set(haxes1, 'NextPlot', 'Add')
            set(haxes2, 'NextPlot', 'Add')
            set(haxes3, 'NextPlot', 'Add')
            set(haxes4, 'NextPlot', 'Add')
            
            nTubes = 6;
            
            x1 = logData(:,1);
            x2 = logData(:,2);
            x3 = logData(:,3);
            x4 = logData(:,4);
            
            
            x1 = reshape(x1, nTubes, []);
            x2 = reshape(x2, nTubes, []);
            x3 = reshape(x3, nTubes, []);
            x4 = reshape(x4, nTubes, []);
            
            x1 = x1'*normFactor;
            x2 = x2'*normFactor;
            x3 = x3'*normFactor;
            x4 = x4'*normFactor;
            
            [nRows ~] = size(x1);
            
            
            
            
            if(nRows < 2 )
                x1(2,:)=NaN;
                plot(haxes1, x1);
                x2(2,:)=NaN;
                plot(haxes2, x2);
                x3(2,:)=NaN;
                plot(haxes3, x3);
                x4(2,:)=NaN;
                plot(haxes4, x4);
            elseif (nRows < 9)
                plot(haxes1, x1);
                plot(haxes2, x2);
                plot(haxes3, x3);
                plot(haxes4, x4);
            else
                plot(haxes1, x1(end-8:end,:));
                plot(haxes2, x2(end-8:end,:));
                plot(haxes3, x3(end-8:end,:));
                plot(haxes4, x4(end-8:end,:));
            end
%             haxes1legend = legend(haxes1, '1','2','3','4','5','6');
%             haxes2legend = legend(haxes2, '1','2','3','4','5','6');
%             haxes3legend = legend(haxes3, '1','2','3','4','5','6');
haxes4legend = legend(haxes4,  '1','2','3','4','5','6', 'location', [0.92 0.35 0.05 0.2]);
            
            
            fileV = sprintf('EndcapValues_%s.%s',boxID,'txt');
            gui.valuesfileID = fopen(fileV,'r');
            if gui.valuesfileID ~= -1
                Values = fscanf(gui.valuesfileID, '%u', [6,4]);
                error = 0;
                badEndcap = zeros(6,4);
                for i = 1:6
                    for j = 1:4
                        statusDataPer(i,j) = (measurements(i,j)/(Values(i,j)));
                        if (measurements(i,j) < (Values(i,j) * 0.9))
                            badEndcap(i,j) = 1;
                            error = 1;
                        elseif (measurements(i,j) > (Values(i,j) * 1.1))
                            badEndcap(i,j) = 1;
                            error = 1;
                        end
                    end
                end
                if error == 1
                    set(gui.lightmeasure,'BackgroundColor','red');
                else
                    set(gui.lightmeasure,'BackgroundColor','green');
                end
                for i = 1:6
                    for j = 1:2
                        if badEndcap(i,j) == 1
                            statusData(i,j) = {'BAD!'};
                        elseif badEndcap(i, j+2) == 1
                            statusData(i,j) = {'BAD!'};
                        else
                            statusData(i,j) = {'OK'};
                        end
                    end
                end
                set(stable,'data', statusData);
                set(stablePer,'data', statusDataPer);
                fclose(gui.valuesfileID);
            else
                gui.valuesfileID = fopen(fileV,'w');
                fprintf(gui.valuesfileID,'%u %u %u %u %u %u\r\n',...
                    measurements(1,1),measurements(2,1),measurements(3,1),...
                    measurements(4,1),measurements(5,1),measurements(6,1));
                fprintf(gui.valuesfileID,'%u %u %u %u %u %u\r\n',...
                    measurements(1,2),measurements(2,2),measurements(3,2),...
                    measurements(4,2),measurements(5,2),measurements(6,2));
                fprintf(gui.valuesfileID,'%u %u %u %u %u %u\r\n',...
                    measurements(1,3),measurements(2,3),measurements(3,3),...
                    measurements(4,3),measurements(5,3),measurements(6,3));
                fprintf(gui.valuesfileID,'%u %u %u %u %u %u\r\n',...
                    measurements(1,4),measurements(2,4),measurements(3,4),...
                    measurements(4,4),measurements(5,4),measurements(6,4));
                fclose(gui.valuesfileID);
                set(gui.lightmeasure,'BackgroundColor','yellow');
                
            end
        end
    end


%% Function receiveData
    function receiveData(obj,evnt)
        token = fscanf(s,'%s',4);
        if (strcmp('$FR,', token) == true)
            idn = fscanf(s);
            set(gui.fig,'name',sprintf('%s %s',idn, boxID));
            detectorConnect = true;
            if (boxConnect == true)
                set(gui.darkmeasure,'BackgroundColor','yellow');
                set(gui.lightmeasure,'BackgroundColor','yellow');
            end
        elseif(strcmp('GRA,', token) == true)
            inpline = fscanf(s);
            [gr1a,gr2a,gr3a,gr4a,gr5a,gr6a] = strread(inpline,'%u%u%u%u%u%u','delimiter',',');
            detectorData(:,1) = [gr1a,gr2a,gr3a,gr4a,gr5a,gr6a];
        elseif(strcmp('GRB,', token) == true)
            inpline = fscanf(s);
            [gr1b,gr2b,gr3b,gr4b,gr5b,gr6b] = strread(inpline,'%u%u%u%u%u%u','delimiter',',');
            detectorData(:,2) = [gr1b,gr2b,gr3b,gr4b,gr5b,gr6b];
        elseif(strcmp('UVA,', token) == true)
            inpline = fscanf(s);
            [uv1a,uv2a,uv3a,uv4a,uv5a,uv6a] = strread(inpline,'%u%u%u%u%u%u','delimiter',',');
            detectorData(:,3) = [uv1a,uv2a,uv3a,uv4a,uv5a,uv6a];
        elseif(strcmp('UVB,', token) == true)
            inpline = fscanf(s);
            [uv1b,uv2b,uv3b,uv4b,uv5b,uv6b] = strread(inpline,'%u%u%u%u%u%u','delimiter',',');
            detectorData(:,4) = [uv1b,uv2b,uv3b,uv4b,uv5b,uv6b];
        end
    end

%% Function Select_Callback
    function select_callback(hObject, eventdata)
        % hObject    Handle to uitable1 (see GCBO)
        % eventdata  Currently selected table indices
        % Callback to erase and replot markers, showing only those
        % corresponding to user-selected cells in table.
        % Repeatedly called while user drags across cells of the uitable
        
        % hmkrs are handles to lines having markers only
        set(hmkrs, 'Visible', 'off') % turn them off to begin
        
        % Get the list of currently selected table cells
        sel = eventdata.Indices;     % Get selection indices (row, col)
        % Noncontiguous selections are ok
        selcols = unique(sel(:,2));  % Get all selected data col IDs
        table = get(hObject,'Data'); % Get copy of uitable data
        
        % Get vectors of x,y values for each column in the selection;
        for idx = 1:numel(selcols)
            col = selcols(idx);
            xvals = sel(:,1);
            xvals(sel(:,2) ~= col) = [];
            yvals = table(xvals, col)';
            % Create Z-vals = 1 in order to plot markers above lines
            zvals = col*ones(size(xvals));
            % Plot markers for xvals and yvals using a line object
            set(hmkrs(col), 'Visible', 'on',...
                'XData', xvals,...
                'YData', yvals,...
                'ZData', zvals)
        end
    end

%% GUI close callback function
    function closefcn(obj,evnt)
        fclose('all');
        delete(s);
        delete(s2);
        delete(obj);
    end
end
