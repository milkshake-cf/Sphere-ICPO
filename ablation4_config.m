function cfg = ablation4_config(profile)
%ABLATION4_CONFIG Frozen configuration for four-map component screening.
if nargin < 1, profile = 'formal'; end
cfg.profile = lower(profile);
cfg.version = 'sphere-icpo-ablation4-v2';
cfg.maps = frozen_map_registry();
cfg.variants = {
    struct('name','CPO','runner',@runCPO_mm), ...
    struct('name','noSOS','runner',@runICPO_noSOS_mm), ...
    struct('name','noAdapt','runner',@runICPO_noAdapt_mm), ...
    struct('name','noRetreat','runner',@runICPO_noRetreat_mm), ...
    struct('name','Full','runner',@runICPO_SOSv4_mm)
};
cfg.mapIds = 1:4;
cfg.baseSeed = 941000;
cfg.milestones = [25 50 100 150 200];
switch cfg.profile
    case 'smoke'
        cfg.nPop = 10; cfg.MaxIt = 8; cfg.nRuns = 1;
        cfg.milestones = [1 4 8];
    case 'precheck'
        cfg.nPop = 50; cfg.MaxIt = 20; cfg.nRuns = 2;
        cfg.milestones = [5 10 20];
    case 'formal'
        cfg.nPop = 500; cfg.MaxIt = 200; cfg.nRuns = 30;
    otherwise
        error('Unknown ablation profile: %s',profile);
end
end
