function resultDir = run_corrected_icpo_suite(profile, resultDir, sourceFormalState)
%RUN_CORRECTED_ICPO_SUITE Re-run corrected ICPO and rebuild the main comparison.
if nargin < 1, profile = 'formal'; end
profile = lower(profile); maps = frozen_map_registry();
switch profile
    case 'smoke'
        nPop = 10; MaxIt = 8; nRuns = 1; mapIds = 1:4;
    case 'formal'
        nPop = 500; MaxIt = 200; nRuns = 30; mapIds = 1:4;
    otherwise
        error('Unknown corrected-ICPO profile: %s',profile);
end
version = 'sphere-icpo-corrected-v2'; baseSeed = 731000;
if nargin < 2 || isempty(resultDir)
    resultDir = fullfile('results',sprintf('corrected_icpo_%s_%s',profile,datestr(now,'yyyymmdd_HHMMSS')));
end
if nargin < 3, sourceFormalState = ''; end
if ~exist(resultDir,'dir'), mkdir(resultDir); end
stateFile = fullfile(resultDir,'icpo_results.mat');
manifest = validate_frozen_maps(fullfile(resultDir,'maps'));

if exist(stateFile,'file')
    loaded = load(stateFile,'IR'); IR = loaded.IR;
    assert(strcmp(IR.config.version,version) && strcmp(IR.config.profile,profile), ...
        'Existing checkpoint belongs to a different configuration.');
else
    IR.config = struct('version',version,'profile',profile,'nPop',nPop,'MaxIt',MaxIt, ...
        'nRuns',nRuns,'mapIds',mapIds,'baseSeed',baseSeed, ...
        'mapNames',{cellfun(@(x)x.name,maps(mapIds),'UniformOutput',false)});
    IR.manifest = manifest; IR.created = datestr(now,30); IR.completed = false; IR.icpo = struct();
    save(stateFile,'IR','-v7.3');
end

fprintf('Corrected ICPO result directory: %s\n',resultDir);
for mi = mapIds
    mapDef = maps{mi}; model = mapDef.func(false);
    for r = 1:nRuns
        if isfield(IR.icpo,mapDef.name) && numel(IR.icpo.(mapDef.name))>=r && IR.icpo.(mapDef.name)(r).completed
            continue;
        end
        seed = baseSeed + mi*1000 + r;
        fprintf('[corrected-icpo] %s / run %d/%d / seed %d\n',mapDef.name,r,nRuns,seed);
        rng(seed,'twister');
        [best,curve,info] = runICPO_SOSv4_mm(model,nPop,MaxIt);
        recomputed = MyCost(info.bestCartesian,model);
        assert(isfinite(best.Cost) && abs(recomputed-best.Cost)<=max(1e-8,1e-10*abs(best.Cost)), ...
            'Corrected ICPO position/cost mismatch in %s/run%d.',mapDef.name,r);
        rec.completed = true; rec.seed = seed; rec.cost = best.Cost; rec.recomputedCost = recomputed;
        rec.elapsed = info.elapsed; rec.functionEvaluations = info.functionEvaluations;
        rec.bestPosition = best.Position; rec.bestCartesian = info.bestCartesian;
        rec.convergence = curve(:); rec.metrics = info.metrics; rec.finishedAt = datestr(now,30);
        IR.icpo.(mapDef.name)(r) = rec;
        IR.updated = datestr(now,30); save(stateFile,'IR','-v7.3');
    end
end
IR.completed = true; IR.completedAt = datestr(now,30); save(stateFile,'IR','-v7.3');
if strcmp(profile,'formal') && ~isempty(sourceFormalState)
    build_corrected_comparison(sourceFormalState,stateFile,fullfile(resultDir,'combined_results.mat'));
end
end

function build_corrected_comparison(sourceFormalState,correctedState,combinedState)
source = load(sourceFormalState,'ER'); corrected = load(correctedState,'IR'); ER = source.ER; IR = corrected.IR;
assert(ER.config.nRuns==IR.config.nRuns && ER.config.nPop==IR.config.nPop && ER.config.MaxIt==IR.config.MaxIt, ...
    'Source formal comparison configuration does not match corrected ICPO runs.');
for m = 1:numel(IR.config.mapNames)
    mapName = IR.config.mapNames{m};
    oldSeeds = [ER.comparison.(mapName).ICPO.seed]; newSeeds = [IR.icpo.(mapName).seed];
    assert(isequal(oldSeeds,newSeeds),'Corrected ICPO seed schedule mismatch in %s.',mapName);
    ER.comparison.(mapName).ICPO = IR.icpo.(mapName);
end
ER.correctedICPO = struct('version',IR.config.version,'sourceState',sourceFormalState, ...
    'correctedState',correctedState,'created',datestr(now,30));
save(combinedState,'ER','-v7.3');
analyze_experiment_results(combinedState);
end
