%%
%newOrOld = 'orig';
newOrOld = 'new_newstats';

%%
% fprintf('Running ''%s''-style retracking\n',newOrOld);
% pth = getpath;
% fprintf(1,'Path:\n');
% disp(pth(1:5));

%%
% expNames = { % "problem" exps
%     'GMR_87D07_AE_01_shi_Apollo_20110126T140659'
%     'pBDPGAL4U_shi_Orion_20110310T151951'
%     'GMR_pBDPGal4U;attP2_shi_Zeus_20110127T145124'
%     'pBDPGAL4U_shi_Athena_20110318T144810'
%     'GMR_38B11_AE_01_shi_Ares_20111110T125332'
%     'pBDPGAL4U_shi_Zeus_20120104T135654'
%     'pBDPGAL4U_shi_Orion_20120201T083419'
%     'pBDPGAL4U_shi_Athena_20120301T100212'
%     };    
% expNames = {
%     'pBDPGAL4U_shi_Zeus_20120104T135654';
%     'GMR_38B11_AE_01_shi_Ares_20111110T125332';
%     }
expNames = {
    '48A08AD_Kir_Ares_20130222T130339'
    };
Nexp = numel(expNames);

%%
rootdir = '/Volumes/flyolympiad/Olympiad_Screen/box/reiser_protocol_test_2013/Feb22/';
cd(rootdir)

%%
dryName = sprintf('dryBatchRetrack_%s',datestr(now,'yyyymmddTHHMMSS'));
diary(dryName);
for c = 1:Nexp
    cd(rootdir); % tracking changes our dir for some reason
    
    exp = expNames{c};
    seqs = 5;
    tbs = 1:6;
    fprintf(1,'## Running Experiment: %s\n',exp);
    fprintf(1,'   Seqs: %s. Tubes: %s.\n',mat2str(seqs),mat2str(tbs));
    
    tic;
    ts = retrackExperiment(exp,newOrOld,seqs,tbs);
    %ts = retrackExperiment(exp,newOrOld,2,2);
    disp(ts);
    toc;
end
cd(rootdir);
diary off;
    
%% run merge_analysis_output. (move this into loop above)
retrackDir = '/Volumes/flyolympiad/Olympiad_Screen/box/reiser_protocol_test_2013/Feb22/';
for c = 1:Nexp
    exp = expNames{c};
    fprintf(1,'## Experiment: %s\n',exp);
    merge_analysis_output(fullfile(retrackDir,exp));
end

    
