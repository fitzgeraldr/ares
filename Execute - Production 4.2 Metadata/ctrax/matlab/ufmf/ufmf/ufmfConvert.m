% [infiles,outfiles,paramsfile] = ufmfConvert(infiles,outfiles,paramsfile)
% 
% Convert video(s) to ufmf(s). Any video format supported by 
% get_readframe_fcn can be converted. All arguments are optional. If not
% specified, files will be input from the user interactively.
%
% infiles: One or many input videos to convert. Either cell array or
% string.
% outfiles: Location(s) to write the ufmf version(s) of the input video(s).
% paramsfile: UFMF compression parameters file. See
% ufmfCompressionParamsRoian20141204.txt for an example
%
% optional arguments:
% debug: Whether to not output any debug info (0), print statements to
% command window (1), or plot visualizations (2). Default: 1.
% hfig: Which figure to output to. Default: []. Creates a new figure if
% empty. 
% startframe, endframe: Limits on the frames to compress. Defaults: 1, inf.

function [infiles,outfiles,paramsfile] = ufmfConvert(infiles,outfiles,paramsfile,varargin)

[DEBUG,hfig,~] = myparse_nocheck(varargin,'debug',1,'hfig',[]);

if nargin < 1,
  infiles = {};
end
if nargin < 2,
  outfiles = {};
end
if nargin < 3,
  paramsfile = '';
end

movieexts = {'*.avi','*.mov','*.mp4','*.seq','*.fmf','*.ufmf','*.sbfmf','*.mmf'}';

persistent oldinfile;
persistent oldparamsfile;

timestamp = now;
timestampstr = datestr(timestamp,'yyyymmddTHHMMSS');

% parse inputs

if ~ischar(oldinfile),
  oldinfile = '';
elseif ~exist(oldinfile,'file')
  oldinfile = fileparts(oldinfile);
  if ~exist(oldinfile,'dir'),
    oldinfile = '';
  end
end

if ~ischar(oldparamsfile),
  oldparamsfile = '';
elseif ~exist(oldparamsfile,'file')
  oldparamsfile = fileparts(oldparamsfile);
  if ~exist(oldparamsfile,'dir'),
    oldparamsfile = '';
  end
end

if nargin < 1 || isempty(infiles),
  while true,
    [infiles,inpath] = uigetfile(movieexts,'Select input video',oldinfile,'MultiSelect','on');
    if isnumeric(infiles),
      return;
    end
    if ischar(infiles),
      infiles = {infiles};
    end
    infiles = cellfun(@(x) fullfile(inpath,x),infiles,'Uni',false);
    if ~all(cellfun(@exist,infiles)==2),
      idxmissing = cellfun(@exist,infiles)==0;
      warndlg(sprintf('Input files %sdo not exist',sprintf('%s ',infiles{idxmissing})));
    else
      break;
    end
  end
  oldinfile = infiles{1};
else
  if ischar(infiles),
    infiles = {infiles};
  end
  if ~all(cellfun(@exist,infiles)==2),
    idxmissing = cellfun(@exist,infiles)==0;
    error('Input files %sdo not exist',sprintf('%s ',infiles{idxmissing}));
  end
end


if nargin < 2 || isempty(outfiles),
  
  if numel(infiles) > 1,    
    res = questdlg('Write output ufmfs to the same directory(s) as their corresponding input videos?');
    if strcmpi(res,'Cancel'),
      return;
    elseif strcmpi(res,'No'),
      outdir = uigetdir(fileparts(infiles{1}),'Output directory');
      if isnumeric(outdir),
        return;
      end
    else
      outdir = 0;
    end       
    
    while true,
      suffix = inputdlg({'Suffix to add to create ufmf output file names: '},'Output file names',1,...
        {sprintf('_%s.ufmf',timestampstr)});
      if isempty(suffix),
        return;
      end
      suffix = suffix{1};
      [~,~,e] = fileparts(suffix);
      if ~strcmpi(e,'.ufmf'),
        warndlg('Extension of suffix should be .ufmf');
      else
        break;
      end
    end
    outfiles = cell(size(infiles));
    for i = 1:numel(infiles),
      [p,n,~] = fileparts(infiles{i});
      if ischar(outdir),
        p = outdir;
      end
      outfiles{i} = fullfile(p,[n,suffix]);
      if DEBUG > 0,
        fprintf('%s -> %s\n',infiles{i},outfiles{i});
      end
    end
    
  else
    [p,n] = fileparts(infiles{1});
    defaultoutfile = fullfile(p,[n,'.ufmf']);
    [outfiles,outpath] = uiputfile('*.ufmf','Select output video location',defaultoutfile);
    if isnumeric(outfiles),
      return;
    end
    outfiles = {fullfile(outpath,outfiles)};
  end
else
  
  if ischar(outfiles),
    outfiles = {outfiles};
  end
  if numel(infiles) ~= numel(outfiles),
    error('Number of outputs does not match number of inputs.');
  end
  
end

if nargin < 3 || isempty(paramsfile),
  while true,
    [paramsfile,paramspath] = uigetfile('*.txt','UFMF compression parameters file',oldparamsfile);
    if ~ischar(paramsfile),
      return;
    end
    
    paramsfile = fullfile(paramspath,paramsfile);
    if ~exist(paramsfile,'file'),
      warndlg(sprintf('Parameters file %s does not exist',paramsfile));
      continue;
    else
      break;
    end
  end
end

oldparamsfile = paramsfile;

params = ReadParams(paramsfile,'=');

if DEBUG > 1,
  if isempty(hfig),
    hfig = figure;
  elseif ~ishandle(hfig),
    figure(hfig);
  else
    set(0,'CurrentFigure',hfig);
  end
  clf;
else
  hfig = [];
end    

for moviei = 1:numel(infiles),
  
  if DEBUG > 0,
    fprintf('Converting %s to %s...\n',infiles{moviei},outfiles{moviei});
  end
  ufmfConvertMain(infiles{moviei},outfiles{moviei},params,varargin{:},'hfig',hfig);
  
end

function ufmfConvertMain(infile,outfile,params,varargin)

[startframe,endframe,DEBUG,hfig] = myparse(varargin,'startframe',1,'endframe',inf,'debug',1,'hfig',[]);

% open input video
[readframe,nframes,infid] = get_readframe_fcn(infile);

[im] = readframe(1);
iscolor = size(im,3) > 1;
isuint8 = isa(im,'uint8');

[nr,nc,~] = size(im);

% create output file
outfid = fopen(outfile,'wb');
indexlocloc = writeUFMFHeader(outfid,nr,nc);
index = struct;
index.frame = struct;
index.frame.loc = [];
index.frame.timestamp = [];
index.keyframe = struct;
index.keyframe.mean = struct;
index.keyframe.mean.loc = [];
index.keyframe.mean.timestamp = [];

% initialize background
keyi = 1;
lastkeyt = -inf;
lastbgupdate = -inf;
bghist = zeros([nr,nc,256],'single');
nbgupdates = 0;
[xgrid,ygrid] = meshgrid(1:nc,1:nr);

% how often should we output a new background
params.UFMFBGKeyFramePeriods = [params.UFMFBGKeyFramePeriodInit,params.UFMFBGKeyFramePeriod];

endframe = min(endframe,nframes);

if DEBUG > 1 && ishandle(hfig),
  
  clf(hfig);
  hax = createsubplots(1,2,.05,hfig);
  him = nan(1,2);
  for i = 1:2,
    him(i) = image(zeros(nr,nc),'Parent',hax(i));
    axis(hax(i),'image');
    set(hax(i),'XTick',[],'YTick',[]);
  end
  title(hax(2),'Background model');
  hti = title(hax(1),'Frame 0');
  hold(hax(1),'on');
  hbox = plot(hax(1),nan,nan,'r-');
  colormap(hfig,'gray');
end

for f = startframe:endframe,
  
  if DEBUG > 0 && mod(f,100) == 0,
    fprintf('Compressing frame %d/%d\n',f,nframes);
  end
  
  [im,t] = readframe(f);
  if iscolor,
    im = rgb2gray(im);
  end
  if ~isuint8,
    im = im2uint8(im);
  end
  
  % update background?
  if t - lastbgupdate >= params.UFMFBGUpdatePeriod || f <= params.UFMFNFramesInit,
    tic;
    idx = sub2ind([nr,nc,256],ygrid(:),xgrid(:),double(im(:))+1);
    bghist(idx) = bghist(idx) + 1;
    lastbgupdate = t;
    nbgupdates = nbgupdates+1;
    if DEBUG > 0,
      fprintf('Updating background at frame %d/%d, t = %f took %f seconds\n',f,nframes,t,toc);
    end
  end
  
  % output keyframe?
  if t - lastkeyt >= params.UFMFBGKeyFramePeriods(keyi),
    
    tic;
    mu = zeros([nr,nc],'uint8');
    z = zeros([nr,nc],'double');
    thresh = nbgupdates/2;
    isdone = false([nr,nc]);
    for i = 1:256,
      z = z + bghist(:,:,i);
      idx = ~isdone & z >= thresh;
      mu(idx) = i-1;
      isdone(idx) = true;
      if all(isdone(:)),
        break;
      end
    end
    index.keyframe.mean.timestamp(end+1) = t; 
    index.keyframe.mean.loc(end+1) = writeUFMFKeyFrame(outfid,mu,t);
    
    lastkeyt = t;
    keyi = min(keyi+1,numel(params.UFMFBGKeyFramePeriods));
    if keyi==numel(params.UFMFBGKeyFramePeriods),
      bghist(:) = 0;
      nbgupdates = 0;
    end
    if DEBUG > 0,
      fprintf('Writing keyframe at frame %d/%d, t = %f took %f seconds\n',f,nframes,t,toc);
    end
    if DEBUG > 1 && ishandle(him(2)),
      set(him(2),'CData',mu);
      drawnow;
    end
      
  end 
  
  % write frame
  [index.frame.loc(end+1),bb] = writeUFMFFrame(outfid,im,t,mu,params);
  if DEBUG > 1 && ishandle(hti) && mod(f,10) == 1,
    set(him(1),'CData',im);
    if isempty(bb),
      y = nan; x = nan;
    else
      x = cat(2,bb(:,1),...
        bb(:,1),...
        bb(:,1)+bb(:,3),...
        bb(:,1)+bb(:,3),...
        bb(:,1),...
        nan(size(bb,1),1))'-.5;
      y = cat(2,bb(:,2),...
        bb(:,2)+bb(:,4),...
        bb(:,2)+bb(:,4),...
        bb(:,2),...
        bb(:,2),...
        nan(size(bb,1),1))'-.5;
    end
    set(hbox,'xdata',x(:),'ydata',y(:));
    set(hti,'String',sprintf('Frame %d',f));
    drawnow;
  end
  index.frame.timestamp(end+1) = t;
  
end

wrapupUFMF(outfid,index,indexlocloc);
fclose(outfid);
if DEBUG > 0,
  fprintf('Finished compressing to file %s\n',outfile);
end

if infid > 0 && ~isempty(fopen(infid)),
  fclose(infid);
end