% plot_all_figures.m — All paper figures
clear; close all;

load('results/4maps_20260710_154251/results.mat','AR');
load('results/convergence_data.mat','CV');

maps = fieldnames(AR);
alg_names = {'SPSO','GWO','CPO','WOA','ICPO'};
colors = {[0 0 0.6],[0.6 0 0],[0 0.5 0],[0.8 0.4 0],[0.8 0 0]};
map_labels = {'Map 1: 6 Threats','Map 2: 5 Clustered','Map 3: 3 Scattered','Map 4: 7 Dense'};

%% Fig 1: Convergence (Map1 + Map4)
figure('Position',[50 300 900 350]);
for sp=[1 4]
    sp_idx=1+(sp==4);subplot(1,2,sp_idx); hold on;
    idx=1+(sp==4);
    for a=1:5
        plot(1:200,CV{idx,a},'Color',colors{a},'LineWidth',1.5);
    end
    xlabel('Iteration');ylabel('Best Cost');title(map_labels{sp});
    legend(alg_names,'Location','northeast');grid on;
end
saveas(gcf,'figures/fig_convergence.png');
fprintf('Fig 1: Convergence\n');

%% Fig 2: Boxplot
figure('Position',[50 50 1100 750]);
for sp=1:4
    subplot(2,2,sp);hold on;
    data=zeros(20,5);
    for a=1:5,data(:,a)=AR.(maps{sp}).(alg_names{a}).costs;end
    boxplot(data,alg_names);ylabel('Cost');title(map_labels{sp});grid on;
end
saveas(gcf,'figures/fig_boxplot.png');
fprintf('Fig 2: Boxplots\n');

%% Fig 3: Ablation
abl_names={'CPO','noSOS','noAdapt','noRetreat','Full'};
abl_means=[6262.77,6539.98,5938.88,5249.58,5159.75];
abl_stds=[109.06,268.78,777.56,349.86,396.07];
figure('Position',[50 50 550 400]);
bar(abl_means,'FaceColor',[0.25 0.5 0.8]);hold on;
errorbar(1:5,abl_means,abl_stds,'k.','LineWidth',1.5);
set(gca,'XTickLabel',abl_names);ylabel('Mean Cost');
title('Ablation Study (Map 1)');grid on;
saveas(gcf,'figures/fig_ablation.png');
fprintf('Fig 3: Ablation\n');

%% Fig 4: Comparison bar
figure('Position',[50 50 750 420]);
data_all=zeros(4,5);
for m=1:4,for a=1:5,data_all(m,a)=AR.(maps{m}).(alg_names{a}).mean;end;end
bar(data_all);set(gca,'XTickLabel',{'Map1','Map2','Map3','Map4'});
legend(alg_names,'Location','northwest');ylabel('Mean Cost');
title('Multi-Map Comparison');grid on;
saveas(gcf,'figures/fig_comparison.png');
fprintf('Fig 4: Comparison\n');
disp('All figures done!');
