function trak_success = retrackProt7Exp(expName)

for phase = 1:2,

tb = [1,3,6];

if phase == 1,
seq = 1:4;
elseif phase == 2,
seq = 5:9;
end

expDirIn = fullfile('/Volumes/flyolympiad/Olympiad_Screen/box/reiser_protocol_test_2013/Motion_Nulling/7_00',expName);

expDirOut = fullfile('/Volumes/flyolympiad/Olympiad_Screen/box/reiser_protocol_test_2013/Motion_Nulling/7_00',expName);

Nseq = numel(seq);
Ntb = numel(tb);
trak_success = cell(Nseq,Ntb);

for seqIdx = 1:Nseq
for tbIdx = 1:Ntb  
    sbfmfname = BoxData.FileSystemReader.sbfmfFilenameStatic(expDirIn,phase,seq(seqIdx),tb(tbIdx))
    outputdir = BoxData.FileSystemReader.outputDirStatic(expDirOut,phase,seq(seqIdx),tb(tbIdx));
    
    if exist(outputdir,'dir')~=7
        mkdir(outputdir);
    end

    trak_success{seqIdx,tbIdx} = olympiadTrak('params_Olympiad.txt',sbfmfname,outputdir);
end
end

end