function combinedState = merge_corrected_icpo_maps(mapStateFiles, sourceFormalState, outputDir)
%MERGE_CORRECTED_ICPO_MAPS Replace only invalid ICPO records in formal comparison.
assert(numel(mapStateFiles)==4,'Exactly four corrected map files are required.');
if nargin<3||isempty(outputDir),outputDir=fullfile('results',sprintf('corrected_comparison_%s',datestr(now,'yyyymmdd_HHMMSS')));end
if ~exist(outputDir,'dir'),mkdir(outputDir);end
source=load(sourceFormalState,'ER');ER=source.ER;
for i=1:4
    loaded=load(mapStateFiles{i},'IM');IM=loaded.IM;
    assert(IM.completed&&numel(IM.runs)==30&&all([IM.runs.completed]),'Incomplete corrected ICPO checkpoint.');
    mapName=IM.config.mapName;oldSeeds=[ER.comparison.(mapName).ICPO.seed];newSeeds=[IM.runs.seed];
    assert(isequal(oldSeeds,newSeeds),'Seed mismatch in %s.',mapName);
    ER.comparison.(mapName).ICPO=IM.runs;
end
ER.correctedICPO=struct('version','sphere-icpo-corrected-v2','sourceState',sourceFormalState, ...
    'mapStates',{mapStateFiles},'created',datestr(now,30));
combinedState=fullfile(outputDir,'results.mat');save(combinedState,'ER','-v7.3');
analyze_experiment_results(combinedState);
end
