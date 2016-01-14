function trak_success = retrackExperiment(expName,newOrOrig,seq,tb)

if nargin < 3
    seq = 1:5;
end
if nargin < 4
    tb = 1:6;
end

assert(ismember(newOrOrig,{'new' 'orig' 'new_newstats'}));

expDirIn = fullfile('C:\Users\user\Dropbox\wrk\fo\box_data',expName);
outDir = sprintf('box_data_retrack_%s',newOrOrig);
expDirOut = fullfile('C:\Users\user\Dropbox\wrk\fo',outDir,expName);

Nseq = numel(seq);
Ntb = numel(tb);
trak_success = cell(Nseq,Ntb);
for seqIdx = 1:Nseq
for tbIdx = 1:Ntb  
    sbfmfname =  BoxData.FileSystemReader.sbfmfFilenameStatic(expDirIn,34,seq(seqIdx),tb(tbIdx));
    outputdir = BoxData.FileSystemReader.outputDirStatic(expDirOut,34,seq(seqIdx),tb(tbIdx));
    
    if exist(outputdir,'dir')~=7
        mkdir(outputdir);
    end
    trak_success{seqIdx,tbIdx} = olympiadTrak('params_Olympiad.txt',sbfmfname,outputdir);
end
end
