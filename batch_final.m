% batch_final.m — Final comparison: SPSO vs CPO vs ICPO_SOSv4 on 2 maps
clear; close all;
nRuns = 20; MaxIt = 200;

maps = {
    struct('name','Map1_Christmas','func',@CreateModel),
    struct('name','Map4_7Threat', 'func',@CreateModel_map4)
};

algs = {
    struct('name','SPSO',      'runner',@runSPSO_mm,      'nPop',500),
    struct('name','CPO',       'runner',@runCPO_mm,       'nPop',150),
    struct('name','ICPO_SOSv4','runner',@runICPO_SOSv4_mm,'nPop',150),
};

ts = datestr(now,'yyyymmdd_HHMMSS');
rd = fullfile('results',['final_' ts]); mkdir(rd);
fprintf('=== FINAL: SPSO vs CPO vs ICPO_SOSv4, 2 maps ===\n\n');

AR = struct();
for m = 1:length(maps)
    map_name = maps{m}.name;
    model = maps{m}.func(); close all;
    fprintf('--- %s ---\n', map_name);
    for a = 1:length(algs)
        nm = algs{a}.name; rn = algs{a}.runner; np = algs{a}.nPop;
        costs = zeros(nRuns,1); t0 = tic;
        for r = 1:nRuns
            [gb,~] = rn(model,np,MaxIt); costs(r)=gb.Cost;
        end
        el = toc(t0);
        fprintf('  %s: Mean=%.2f Std=%.2f Min=%.2f (%.1fs)\n',nm,mean(costs),std(costs),min(costs),el);
        AR.(map_name).(nm).costs=costs; AR.(map_name).(nm).mean=mean(costs);
        AR.(map_name).(nm).std=std(costs); AR.(map_name).(nm).min=min(costs);
        save(fullfile(rd,'results.mat'),'AR');
    end
    fprintf('\n');
end

fprintf('============= FINAL SUMMARY =============\n');
fprintf('%-18s %-14s %-10s %-10s %-10s\n','Map','Algorithm','Mean','Std','Min');
for m=1:length(maps)
    mn=maps{m}.name;
    for a=1:length(algs)
        nm=algs{a}.name; d=AR.(mn).(nm);
        fprintf('%-18s %-14s %10.2f %10.2f %10.2f\n',mn,nm,d.mean,d.std,d.min);
    end
end
fprintf('\nSaved: %s\n',rd);
