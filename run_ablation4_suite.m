function resultDir = run_ablation4_suite(profile, resultDir)
%RUN_ABLATION4_SUITE Run/resume the frozen four-map ablation experiment.
if nargin < 1, profile = 'formal'; end
cfg = ablation4_config(profile);
if nargin < 2 || isempty(resultDir)
    resultDir = fullfile('results',sprintf('ablation4_%s_%s',cfg.profile,datestr(now,'yyyymmdd_HHMMSS')));
end
if ~exist(resultDir,'dir'), mkdir(resultDir); end
stateFile = fullfile(resultDir,'results.mat');
manifest = validate_frozen_maps(fullfile(resultDir,'maps'));

if exist(stateFile,'file')
    loaded = load(stateFile,'AR'); AR = loaded.AR;
    assert(strcmp(AR.config.version,cfg.version) && strcmp(AR.config.profile,cfg.profile), ...
        'Existing checkpoint belongs to a different configuration.');
else
    AR.config = serializable_config(cfg); AR.manifest = manifest;
    AR.created = datestr(now,30); AR.completed = false; AR.ablation = struct();
    save(stateFile,'AR','-v7.3');
end

fprintf('Ablation result directory: %s\n',resultDir);
for mi = cfg.mapIds
    mapDef = cfg.maps{mi}; model = mapDef.func(false);
    for ai = 1:numel(cfg.variants)
        variant = cfg.variants{ai}; key = matlab.lang.makeValidName(variant.name);
        for r = 1:cfg.nRuns
            if is_done(AR.ablation,mapDef.name,key,r), continue; end
            seed = cfg.baseSeed + mi*1000 + r;
            fprintf('[ablation4] %s / %s / run %d/%d / seed %d\n', ...
                mapDef.name,variant.name,r,cfg.nRuns,seed);
            rng(seed,'twister');
            [best,curve,info] = variant.runner(model,cfg.nPop,cfg.MaxIt);
            assert(isfinite(best.Cost),'Non-finite final cost.');
            recomputed = MyCost(info.bestCartesian,model);
            assert(abs(recomputed-best.Cost) <= max(1e-8,1e-10*abs(best.Cost)), ...
                'Saved position/cost mismatch for %s/%s/run%d.',mapDef.name,variant.name,r);
            rec = make_record(seed,best,curve,info,recomputed);
            AR.ablation.(mapDef.name).(key)(r) = rec;
            AR.updated = datestr(now,30); save(stateFile,'AR','-v7.3');
        end
    end
end
AR.completed = true; AR.completedAt = datestr(now,30); save(stateFile,'AR','-v7.3');
analyze_ablation4_results(stateFile);
end

function tf = is_done(section,mapName,variantName,r)
tf = isfield(section,mapName) && isfield(section.(mapName),variantName) && ...
    numel(section.(mapName).(variantName)) >= r && section.(mapName).(variantName)(r).completed;
end

function rec = make_record(seed,best,curve,info,recomputed)
rec.completed = true; rec.seed = seed; rec.cost = best.Cost; rec.recomputedCost = recomputed;
rec.elapsed = info.elapsed; rec.functionEvaluations = info.functionEvaluations;
rec.bestPosition = best.Position; rec.bestCartesian = info.bestCartesian;
rec.convergence = curve(:); rec.metrics = info.metrics; rec.finishedAt = datestr(now,30);
end

function out = serializable_config(cfg)
out = rmfield(cfg,{'maps','variants'});
out.mapNames = cellfun(@(x)x.name,cfg.maps(cfg.mapIds),'UniformOutput',false);
out.variantNames = cellfun(@(x)x.name,cfg.variants,'UniformOutput',false);
end
