function stateFile = run_ablation4_map(mapId, profile, resultDir)
%RUN_ABLATION4_MAP Run/resume one map in an isolated MATLAB process.
if nargin < 2, profile = 'formal'; end
cfg = ablation4_config(profile); assert(ismember(mapId,cfg.mapIds),'Invalid frozen map id.');
if nargin < 3 || isempty(resultDir)
    resultDir = fullfile('results',sprintf('ablation4_%s_map%d_%s',cfg.profile,mapId,datestr(now,'yyyymmdd_HHMMSS')));
end
if ~exist(resultDir,'dir'), mkdir(resultDir); end
stateFile = fullfile(resultDir,'map_results.mat'); mapDef = cfg.maps{mapId}; model = mapDef.func(false);
if exist(stateFile,'file')
    loaded = load(stateFile,'AM'); AM = loaded.AM;
    assert(strcmp(AM.config.version,cfg.version) && AM.config.mapId==mapId,'Checkpoint configuration mismatch.');
else
    AM.config = struct('version',cfg.version,'profile',cfg.profile,'mapId',mapId,'mapName',mapDef.name, ...
        'nPop',cfg.nPop,'MaxIt',cfg.MaxIt,'nRuns',cfg.nRuns,'baseSeed',cfg.baseSeed, ...
        'milestones',cfg.milestones,'variantNames',{cellfun(@(x)x.name,cfg.variants,'UniformOutput',false)});
    AM.created = datestr(now,30); AM.completed = false; AM.ablation = struct(); save(stateFile,'AM','-v7.3');
end
fprintf('Map %d result directory: %s\n',mapId,resultDir);
for ai = 1:numel(cfg.variants)
    variant = cfg.variants{ai}; key = matlab.lang.makeValidName(variant.name);
    for r = 1:cfg.nRuns
        if isfield(AM.ablation,key) && numel(AM.ablation.(key))>=r && AM.ablation.(key)(r).completed, continue; end
        seed = cfg.baseSeed + mapId*1000 + r;
        fprintf('[ablation4-map%d] %s / run %d/%d / seed %d\n',mapId,variant.name,r,cfg.nRuns,seed);
        rng(seed,'twister'); [best,curve,info] = variant.runner(model,cfg.nPop,cfg.MaxIt);
        recomputed = MyCost(info.bestCartesian,model);
        assert(isfinite(best.Cost) && abs(recomputed-best.Cost)<=max(1e-8,1e-10*abs(best.Cost)), ...
            'Position/cost mismatch for map%d/%s/run%d.',mapId,variant.name,r);
        rec.completed=true; rec.seed=seed; rec.cost=best.Cost; rec.recomputedCost=recomputed;
        rec.elapsed=info.elapsed; rec.functionEvaluations=info.functionEvaluations;
        rec.bestPosition=best.Position; rec.bestCartesian=info.bestCartesian;
        rec.convergence=curve(:); rec.metrics=info.metrics; rec.finishedAt=datestr(now,30);
        AM.ablation.(key)(r)=rec; AM.updated=datestr(now,30); save(stateFile,'AM','-v7.3');
    end
end
AM.completed=true; AM.completedAt=datestr(now,30); save(stateFile,'AM','-v7.3');
end
