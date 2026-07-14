function cfg = experiment_config(profile)
%EXPERIMENT_CONFIG Single source of truth for all reruns.
if nargin < 1, profile = 'formal'; end
cfg.profile = lower(profile);
cfg.version = 'sphere-icpo-experiment-v1';
cfg.maps = frozen_map_registry();
cfg.comparison = {
    struct('name','SPSO','runner',@runSPSO_mm), ...
    struct('name','GWO','runner',@runGWO_mm), ...
    struct('name','CPO','runner',@runCPO_mm), ...
    struct('name','WOA','runner',@runWOA_mm), ...
    struct('name','ICPO','runner',@runICPO_SOSv4_mm)
};
cfg.ablation = {
    struct('name','CPO','runner',@runCPO_mm), ...
    struct('name','noSOS','runner',@runICPO_noSOS_mm), ...
    struct('name','noAdapt','runner',@runICPO_noAdapt_mm), ...
    struct('name','noRetreat','runner',@runICPO_noRetreat_mm), ...
    struct('name','Full','runner',@runICPO_SOSv4_mm)
};
cfg.ablationMap = 3;
switch cfg.profile
    case 'smoke'
        cfg.nPop=10; cfg.MaxIt=3; cfg.nRuns=1; cfg.mapIds=3;
    case 'precheck'
        cfg.nPop=100; cfg.MaxIt=20; cfg.nRuns=3; cfg.mapIds=1:4;
    case 'formal'
        cfg.nPop=500; cfg.MaxIt=200; cfg.nRuns=30; cfg.mapIds=1:4;
    otherwise
        error('Unknown experiment profile: %s',profile);
end
cfg.baseSeed = 731000;
end
