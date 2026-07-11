% stats_test.m — Wilcoxon + Friedman tests
clear;
load('results/4maps_20260710_154251/results.mat','AR');
maps = fieldnames(AR);
algs = {'SPSO','GWO','CPO','WOA','ICPO'};
fprintf('WILCOXON (ICPO vs each): * p<0.05, ** p<0.01\n');
for m=1:length(maps)
    icpo=AR.(maps{m}).ICPO.costs;
    fprintf('%s:',maps{m});
    for a=1:4
        p=ranksum(icpo,AR.(maps{m}).(algs{a}).costs);
        if p<0.01,fprintf(' %.4f**',p);elseif p<0.05,fprintf(' %.4f*',p);else,fprintf(' %.4f',p);end
    end
    fprintf('\n');
end
fprintf('\nFRIEDMAN RANKING:\n');
for m=1:length(maps)
    for a=1:length(algs)
        vals(a)=AR.(maps{m}).(algs{a}).mean;
    end
    [~,idx]=sort(vals);
    for a=1:length(algs),R(m,idx(a))=a;end
end
for a=1:length(algs),fprintf('%-6s: %.2f\n',algs{a},mean(R(:,a)));end
fprintf('Friedman p=%.4f\n',friedman(R,1,'off'));
