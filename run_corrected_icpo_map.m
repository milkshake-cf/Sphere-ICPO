function stateFile = run_corrected_icpo_map(mapId, profile, resultDir)
%RUN_CORRECTED_ICPO_MAP Run corrected ICPO for one frozen map with checkpoints.
if nargin < 2, profile='formal'; end
maps=frozen_map_registry(); assert(mapId>=1 && mapId<=numel(maps));
switch lower(profile)
    case 'smoke', nPop=10; MaxIt=8; nRuns=1;
    case 'formal', nPop=500; MaxIt=200; nRuns=30;
    otherwise, error('Unknown profile: %s',profile);
end
version='sphere-icpo-corrected-v2'; baseSeed=731000; mapDef=maps{mapId}; model=mapDef.func(false);
if nargin < 3 || isempty(resultDir)
    resultDir=fullfile('results',sprintf('corrected_icpo_%s_map%d_%s',profile,mapId,datestr(now,'yyyymmdd_HHMMSS')));
end
if ~exist(resultDir,'dir'),mkdir(resultDir);end
stateFile=fullfile(resultDir,'map_results.mat');
if exist(stateFile,'file')
    loaded=load(stateFile,'IM'); IM=loaded.IM;
    assert(strcmp(IM.config.version,version)&&IM.config.mapId==mapId,'Checkpoint configuration mismatch.');
else
    IM.config=struct('version',version,'profile',lower(profile),'mapId',mapId,'mapName',mapDef.name, ...
        'nPop',nPop,'MaxIt',MaxIt,'nRuns',nRuns,'baseSeed',baseSeed);
    IM.created=datestr(now,30);IM.completed=false;IM.runs=struct([]);save(stateFile,'IM','-v7.3');
end
fprintf('Corrected ICPO map %d directory: %s\n',mapId,resultDir);
for r=1:nRuns
    if numel(IM.runs)>=r && IM.runs(r).completed,continue;end
    seed=baseSeed+mapId*1000+r;fprintf('[corrected-map%d] run %d/%d / seed %d\n',mapId,r,nRuns,seed);
    rng(seed,'twister');[best,curve,info]=runICPO_SOSv4_mm(model,nPop,MaxIt);
    recomputed=MyCost(info.bestCartesian,model);
    assert(isfinite(best.Cost)&&abs(recomputed-best.Cost)<=max(1e-8,1e-10*abs(best.Cost)), ...
        'Corrected ICPO position/cost mismatch in map%d/run%d.',mapId,r);
    rec.completed=true;rec.seed=seed;rec.cost=best.Cost;rec.recomputedCost=recomputed;
    rec.elapsed=info.elapsed;rec.functionEvaluations=info.functionEvaluations;
    rec.bestPosition=best.Position;rec.bestCartesian=info.bestCartesian;
    rec.convergence=curve(:);rec.metrics=info.metrics;rec.finishedAt=datestr(now,30);
    if isempty(IM.runs),IM.runs=rec;else,IM.runs(r)=rec;end
    IM.updated=datestr(now,30);save(stateFile,'IM','-v7.3');
end
IM.completed=true;IM.completedAt=datestr(now,30);save(stateFile,'IM','-v7.3');
end
