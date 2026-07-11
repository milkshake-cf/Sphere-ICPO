% plot_convergence.m — Convergence curves for Sphere-ICPO paper
clear; close all;

load('results/4maps_20260710_154251/results.mat','AR');
maps = {'Map1_Christmas','Map2_Clustered','Map3_3Threat','Map4_7Threat'};
algs = {'SPSO','GWO','CPO','WOA','ICPO'};
colors = {[0 0 0.7],[0.7 0 0],[0 0.5 0],[0.8 0.4 0],[0.8 0 0]};
styles = {'-','--','-.',':','-'};

% Show 2 representative maps
show_maps = [1 4];  % Map1 (middle) and Map4 (hardest)

figure('Position',[100 100 900 350]);
for sp = 1:2
    m = show_maps(sp);
    subplot(1,2,sp); hold on;
    for a = 1:length(algs)
        costs = zeros(200,1);
        nRuns = length(AR.comparison.(maps{m}).(algs{a}).costs);
        allBC = AR.comparison.(maps{m}).(algs{a}).allBestCosts;
        for r = 1:nRuns, costs = costs + allBC{r}(:); end
        costs = costs / nRuns;
        plot(1:200, costs, 'Color', colors{a}, 'LineStyle', styles{a}, 'LineWidth', 1.5);
    end
    xlabel('Iteration'); ylabel('Best Cost');
    title(maps{m}, 'Interpreter', 'none');
    legend(algs, 'Location', 'northeast');
    grid on;
end
saveas(gcf, 'figures/convergence.png');
fprintf('Convergence curves saved\n');
