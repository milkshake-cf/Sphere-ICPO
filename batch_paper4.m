% batch_paper4.m — 4-map comparison with nPop=500 for ICPO
clear; close all;
nRuns = 20; MaxIt = 200;

maps = {
    struct('name','Map1_Christmas','func',@CreateModel),
    struct('name','Map2_Clustered', 'func',@CreateModel_map2_new),
    struct('name','Map3_Coastal',  'func',@CreateModel_coastal),
    struct('name','Map4_7Threat',  'func',@CreateModel_map4),
};

algs = {
    struct('name','SPSO',  'runner',@runSPSO_mm,       'nPop',500),
    struct('name','GWO',   'runner',@runGWO_mm,        'nPop',150),
    struct('name','CPO',   'runner',@runCPO_mm,        'nPop',150),
    struct('name','WOA',   'runner',@runWOA_mm,        'nPop',150),
    struct('name','ICPO',  'runner',@runICPO_SOSv4_mm, 'nPop',500),
};

ts = datestr(now,'yyyymmdd_HHMMSS');
rd = fullfile('results',['4maps_' ts]); mkdir(rd);
AR = struct();

for m = 1:length(maps)
    mn = maps{m}.name; model = maps{m}.func(); close all;
    fprintf('--- %s ---\n', mn);
    for a = 1:length(algs)
        nm = algs{a}.name; rn = algs{a}.runner; np = algs{a}.nPop;
        fprintf('  %s (nPop=%d)...', nm, np);
        costs = zeros(nRuns,1); t0 = tic;
        for r = 1:nRuns
            [gb,~] = rn(model,np,MaxIt); costs(r) = gb.Cost;
        end
        el = toc(t0);
        fprintf(' Mean=%.2f Std=%.2f (%.1fs)\n', mean(costs), std(costs), el);
        AR.(mn).(nm).costs = costs;
        AR.(mn).(nm).mean = mean(costs);
        AR.(mn).(nm).std = std(costs);
        AR.(mn).(nm).min = min(costs);
        save(fullfile(rd,'results.mat'),'AR');
    end
end

fprintf('\n========== 4-MAP SUMMARY ==========\n');
fprintf('%-18s %-8s %10s %10s %10s\n','Map','Alg','Mean','Std','Min');
for m=1:length(maps)
    mn=maps{m}.name;
    for a=1:length(algs)
        nm=algs{a}.name; d=AR.(mn).(nm);
        fprintf('%-18s %-8s %10.2f %10.2f %10.2f\n',mn,nm,d.mean,d.std,d.min);
    end
end
fprintf('\nSaved: %s\n',rd);
