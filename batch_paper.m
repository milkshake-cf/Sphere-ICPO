% batch_paper.m — Complete experiment for Sphere-ICPO paper
% Ablation study + Multi-map comparison + Statistics
clear; close all;

nRuns = 20; MaxIt = 200;

%% ===== MAPS =====
maps = {
    struct('name','Map1_Christmas','func',@CreateModel),
    struct('name','Map4_7Threat', 'func',@CreateModel_map4),
};

%% ===== PHASE 1: ABLATION STUDY (Map1 only) =====
fprintf('========== PHASE 1: ABLATION STUDY ==========\n');

model = CreateModel(); close all;

abl_algs = {
    struct('name','CPO',        'runner',@runCPO_mm,          'nPop',150),
    struct('name','noSOS',      'runner',@runICPO_noSOS_mm,   'nPop',150),
    struct('name','noAdapt',    'runner',@runICPO_noAdapt_mm, 'nPop',150),
    struct('name','noRetreat',  'runner',@runICPO_noRetreat_mm,'nPop',150),
    struct('name','ICPO_SOSv4', 'runner',@runICPO_SOSv4_mm,  'nPop',150),
};

ts = datestr(now,'yyyymmdd_HHMMSS');
rd = fullfile('results',['paper_' ts]); mkdir(rd);
AR = struct();

for a = 1:length(abl_algs)
    nm = abl_algs{a}.name; rn = abl_algs{a}.runner; np = abl_algs{a}.nPop;
    fprintf('  %s (%d runs)...', nm, nRuns);
    costs = zeros(nRuns,1); t0 = tic;
    for r = 1:nRuns
        [gb,~] = rn(model,np,MaxIt); costs(r) = gb.Cost;
    end
    el = toc(t0);
    fprintf(' Mean=%.2f Std=%.2f Min=%.2f (%.1fs)\n', mean(costs), std(costs), min(costs), el);
    AR.ablation.(nm).costs=costs; AR.ablation.(nm).mean=mean(costs);
    AR.ablation.(nm).std=std(costs); AR.ablation.(nm).min=min(costs);
    AR.ablation.(nm).elapsed=el;
    save(fullfile(rd,'results.mat'),'AR');
end
fprintf('\n');

%% ===== PHASE 2: MULTI-MAP COMPARISON =====
fprintf('========== PHASE 2: MULTI-MAP COMPARISON ==========\n');

cmp_algs = {
    struct('name','SPSO',        'runner',@runSPSO_mm,        'nPop',500),
    struct('name','GWO',         'runner',@runGWO_mm,         'nPop',150),
    struct('name','CPO',         'runner',@runCPO_mm,         'nPop',150),
    struct('name','WOA',         'runner',@runWOA_mm,         'nPop',150),
    struct('name','ICPO_SOSv4',  'runner',@runICPO_SOSv4_mm,  'nPop',150),
};

for m = 1:length(maps)
    map_name = maps{m}.name;
    model = maps{m}.func(); close all;
    fprintf('  --- %s ---\n', map_name);
    for a = 1:length(cmp_algs)
        nm = cmp_algs{a}.name; rn = cmp_algs{a}.runner; np = cmp_algs{a}.nPop;
        fprintf('    %s...', nm);
        costs = zeros(nRuns,1); t0 = tic;
        for r = 1:nRuns
            [gb,~] = rn(model,np,MaxIt); costs(r) = gb.Cost;
        end
        el = toc(t0);
        fprintf(' Mean=%.2f Std=%.2f (%.1fs)\n', mean(costs), std(costs), el);
        AR.comparison.(map_name).(nm).costs=costs;
        AR.comparison.(map_name).(nm).mean=mean(costs);
        AR.comparison.(map_name).(nm).std=std(costs);
        AR.comparison.(map_name).(nm).min=min(costs);
        AR.comparison.(map_name).(nm).elapsed=el;
        save(fullfile(rd,'results.mat'),'AR');
    end
end
fprintf('\n');

%% ===== SUMMARY =====
fprintf('========== ABLATION SUMMARY ==========\n');
fprintf('%-15s %10s %10s %10s\n','Variant','Mean','Std','Min');
for a=1:length(abl_algs)
    nm=abl_algs{a}.name; d=AR.ablation.(nm);
    fprintf('%-15s %10.2f %10.2f %10.2f\n',nm,d.mean,d.std,d.min);
end

fprintf('\n========== COMPARISON SUMMARY ==========\n');
fprintf('%-18s %-14s %10s %10s %10s\n','Map','Algorithm','Mean','Std','Min');
for m=1:length(maps)
    mn=maps{m}.name;
    for a=1:length(cmp_algs)
        nm=cmp_algs{a}.name; d=AR.comparison.(mn).(nm);
        fprintf('%-18s %-14s %10.2f %10.2f %10.2f\n',mn,nm,d.mean,d.std,d.min);
    end
end
fprintf('\nSaved: %s\n',rd);
