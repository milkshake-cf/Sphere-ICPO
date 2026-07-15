function combinedState = merge_ablation4_maps(mapStateFiles, outputDir)
%MERGE_ABLATION4_MAPS Merge four isolated map checkpoints and analyze them.
assert(numel(mapStateFiles)==4,'Exactly four map state files are required.');
cfg=ablation4_config('formal');
if nargin < 2 || isempty(outputDir), outputDir=fullfile('results',sprintf('ablation4_formal_merged_%s',datestr(now,'yyyymmdd_HHMMSS'))); end
if ~exist(outputDir,'dir'),mkdir(outputDir);end
AR.config=rmfield(cfg,{'maps','variants'});
AR.config.mapNames=cellfun(@(x)x.name,cfg.maps,'UniformOutput',false);
AR.config.variantNames=cellfun(@(x)x.name,cfg.variants,'UniformOutput',false);
AR.created=datestr(now,30); AR.completed=true; AR.ablation=struct();
for i=1:4
    loaded=load(mapStateFiles{i},'AM'); AM=loaded.AM;
    assert(AM.completed && strcmp(AM.config.version,cfg.version),'Incomplete or incompatible map checkpoint.');
    mapName=AM.config.mapName; vars=fieldnames(AM.ablation);
    for v=1:numel(vars)
        recs=AM.ablation.(vars{v}); assert(numel(recs)==cfg.nRuns && all([recs.completed]));
        AR.ablation.(mapName).(vars{v})=recs;
    end
end
AR.completedAt=datestr(now,30); combinedState=fullfile(outputDir,'results.mat'); save(combinedState,'AR','-v7.3');
analyze_ablation4_results(combinedState);
end
