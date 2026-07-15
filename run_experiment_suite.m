function resultDir = run_experiment_suite(profile, resultDir)
%RUN_EXPERIMENT_SUITE Run/resume comparison and ablation experiments.
% Examples:
%   run_experiment_suite('smoke')
%   run_experiment_suite('formal')
%   run_experiment_suite('formal','results/formal_20260713_153000')
if nargin < 1, profile='formal'; end
cfg=experiment_config(profile);
if nargin < 2 || isempty(resultDir)
    resultDir=fullfile('results',sprintf('%s_%s',cfg.profile,datestr(now,'yyyymmdd_HHMMSS')));
end
if ~exist(resultDir,'dir'), mkdir(resultDir); end
stateFile=fullfile(resultDir,'results.mat');

manifest=validate_frozen_maps(fullfile(resultDir,'maps'));
if exist(stateFile,'file')
    loaded=load(stateFile,'ER'); ER=loaded.ER;
    assert(strcmp(ER.config.version,cfg.version) && strcmp(ER.config.profile,cfg.profile), ...
        'Existing checkpoint belongs to a different configuration.');
else
    ER.config=serializable_config(cfg); ER.manifest=manifest;
    ER.created=datestr(now,30); ER.completed=false;
    ER.comparison=struct(); ER.ablation=struct();
    save(stateFile,'ER','-v7.3');
end

fprintf('Result directory: %s\n',resultDir);
for mi=cfg.mapIds
    mapDef=cfg.maps{mi}; model=mapDef.func(false);
    for ai=1:numel(cfg.comparison)
        alg=cfg.comparison{ai}; key=matlab.lang.makeValidName(alg.name);
        for r=1:cfg.nRuns
            if is_done(ER.comparison,mapDef.name,key,r), continue; end
            seed=cfg.baseSeed+mi*1000+r;
            fprintf('[comparison] %s / %s / run %d/%d / seed %d\n',mapDef.name,alg.name,r,cfg.nRuns,seed);
            rng(seed,'twister');
            [best,curve,info]=alg.runner(model,cfg.nPop,cfg.MaxIt);
            assert(isfinite(best.Cost),'Non-finite final cost.');
            rec=make_record(seed,best,curve,info);
            ER.comparison.(mapDef.name).(key)(r)=rec;
            ER.updated=datestr(now,30); save(stateFile,'ER','-v7.3');
        end
    end
end

model=cfg.maps{cfg.ablationMap}.func(false); mapName=cfg.maps{cfg.ablationMap}.name;
for ai=1:numel(cfg.ablation)
    alg=cfg.ablation{ai}; key=matlab.lang.makeValidName(alg.name);
    for r=1:cfg.nRuns
        if is_done(ER.ablation,mapName,key,r), continue; end
        seed=cfg.baseSeed+50000+cfg.ablationMap*1000+r;
        fprintf('[ablation] %s / %s / run %d/%d / seed %d\n',mapName,alg.name,r,cfg.nRuns,seed);
        rng(seed,'twister');
        [best,curve,info]=alg.runner(model,cfg.nPop,cfg.MaxIt);
        assert(isfinite(best.Cost),'Non-finite final cost.');
        rec=make_record(seed,best,curve,info);
        ER.ablation.(mapName).(key)(r)=rec;
        ER.updated=datestr(now,30); save(stateFile,'ER','-v7.3');
    end
end
ER.completed=true; ER.completedAt=datestr(now,30); save(stateFile,'ER','-v7.3');
analyze_experiment_results(stateFile);
end

function tf=is_done(section,mapName,algName,r)
tf=isfield(section,mapName) && isfield(section.(mapName),algName) && ...
   numel(section.(mapName).(algName))>=r && section.(mapName).(algName)(r).completed;
end

function rec=make_record(seed,best,curve,info)
rec.completed=true; rec.seed=seed; rec.cost=best.Cost;
rec.elapsed=info.elapsed; rec.functionEvaluations=info.functionEvaluations;
rec.bestPosition=best.Position; rec.bestCartesian=info.bestCartesian;
rec.convergence=curve(:); rec.finishedAt=datestr(now,30);
rec.metrics=info.metrics;
end

function out=serializable_config(cfg)
out=rmfield(cfg,{'maps','comparison','ablation'});
out.mapNames=cellfun(@(x)x.name,cfg.maps(cfg.mapIds),'UniformOutput',false);
out.algorithmNames=cellfun(@(x)x.name,cfg.comparison,'UniformOutput',false);
out.ablationNames=cellfun(@(x)x.name,cfg.ablation,'UniformOutput',false);
end
