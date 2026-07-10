% batch_icpo.m — Test SOS variants
clear; close all;
nRuns = 20; nPop = 150; MaxIt = 200;
model = CreateModel(); close all;

algs = {
    struct('name', 'CPO',         'runner', @runCPO_mm),
    struct('name', 'ICPO_SOSv2',  'runner', @runICPO_SOSv2_mm),
    struct('name', 'ICPO_SOSv4',  'runner', @runICPO_SOSv4_mm),
};

ts = datestr(now, 'yyyymmdd_HHMMSS');
rd = fullfile('results', ['icpo_' ts]); mkdir(rd);
fprintf('=== SOSv4 (adaptive explore): Map1, %d runs ===\n\n', nRuns);
AR = struct();
for a = 1:length(algs)
    nm = algs{a}.name; rn = algs{a}.runner;
    costs = zeros(nRuns,1); t0 = tic;
    for r = 1:nRuns
        [gb,~] = rn(model,nPop,MaxIt); costs(r)=gb.Cost;
        if mod(r,5)==0, fprintf('  %s Run %d/%d: %.2f\n',nm,r,nRuns,costs(r)); end
    end
    el = toc(t0);
    fprintf('  >> %s: Mean=%.2f Std=%.2f Min=%.2f (%.1fs)\n\n',nm,mean(costs),std(costs),min(costs),el);
    AR.(nm).costs=costs; AR.(nm).mean=mean(costs); AR.(nm).std=std(costs); AR.(nm).min=min(costs);
    save(fullfile(rd,'results.mat'),'AR');
end
fprintf('===== SUMMARY =====\n');
for a=1:length(algs), nm=algs{a}.name; d=AR.(nm);
    fprintf('%-15s Mean=%-8.2f Std=%-8.2f Min=%-8.2f\n',nm,d.mean,d.std,d.min);
end
fprintf('Saved: %s\n',rd);
