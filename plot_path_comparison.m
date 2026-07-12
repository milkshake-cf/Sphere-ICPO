% plot_path_comparison.m — Fig. 5: Path comparison top-down view (2x2 subplots)
% Runs all 5 algorithms on 4 maps, plots top-down path + threats
clear; close all;

%% ===== CONFIG =====
nRuns = 1;  % just need one representative path per algorithm
MaxIt = 200;

maps = {
    struct('name','Map 1: 6 Threats (Baseline)','func',@CreateModel),
    struct('name','Map 2: 5 Clustered Threats','func',@CreateModel_map2_new),
    struct('name','Map 3: 3 Scattered Threats','func',@CreateModel_map3_new),
    struct('name','Map 4: 7 Dense Threats','func',@CreateModel_map4),
};

algs = {
    struct('name','SPSO',   'runner',@runSPSO_mm,        'nPop',500, 'color',[0.0 0.0 0.7], 'style','-'),
    struct('name','GWO',    'runner',@runGWO_mm,         'nPop',150, 'color',[0.7 0.0 0.0], 'style','--'),
    struct('name','CPO',    'runner',@runCPO_mm,         'nPop',150, 'color',[0.0 0.5 0.0], 'style','-.'),
    struct('name','WOA',    'runner',@runWOA_mm,         'nPop',150, 'color',[0.8 0.4 0.0], 'style',':'),
    struct('name','ICPO',   'runner',@runICPO_SOSv4_mm,  'nPop',500, 'color',[0.8 0.0 0.0], 'style','-'),
};

%% ===== PLOT =====
figure('Position',[50 50 1200 900]);

for m = 1:length(maps)
    model = maps{m}.func(); close all;
    subplot(2,2,m); hold on;

    % Plot terrain as background (grayscale)
    H = model.H;
    H_plot = H;
    H_plot(H_plot < 0) = 0;
    [Xg,Yg] = meshgrid(1:size(H,2),1:size(H,1));
    contourf(Xg, Yg, H_plot, 20, 'EdgeColor','none');
    colormap(gca,flipud(gray));
    caxis([0 max(H_plot(:))]);

    % Draw threats
    threats = model.threats;
    for t = 1:size(threats,1)
        tx = threats(t,1); ty = threats(t,2); tr = threats(t,4);
        viscircles([tx ty], tr, 'Color',[1 0.3 0.3], 'LineWidth',1.2, 'LineStyle','--');
        % fill with semi-transparent red
        ang = linspace(0,2*pi,40);
        patch(tx+tr*cos(ang), ty+tr*sin(ang), 'r', 'FaceAlpha',0.12, 'EdgeColor','none');
    end

    % Start and End
    plot(model.start(1), model.start(2), 'gs', 'MarkerSize',10, 'MarkerFaceColor','g', 'LineWidth',1.2);
    plot(model.end(1), model.end(2), 'r^', 'MarkerSize',10, 'MarkerFaceColor','r', 'LineWidth',1.2);

    % Run each algorithm and plot best path
    leg_handles = [];
    leg_labels = {};
    for a = 1:length(algs)
        [gb, ~] = algs{a}.runner(model, algs{a}.nPop, MaxIt);
        bp = SphericalToCart(gb.Position, model);
        path_x = [model.start(1) bp.x model.end(1)];
        path_y = [model.start(2) bp.y model.end(2)];
        h = plot(path_x, path_y, 'LineWidth',1.8, 'Color', algs{a}.color, ...
                 'LineStyle', algs{a}.style);
        leg_handles = [leg_handles h];
        leg_labels{end+1} = sprintf('%s (%.0f)', algs{a}.name, gb.Cost);
    end

    title(maps{m}.name, 'FontSize',12, 'FontWeight','bold');
    xlabel('X (m)'); ylabel('Y (m)');
    xlim([model.xmin model.xmax]); ylim([model.ymin model.ymax]);
    axis equal; grid on;

    % Legend only on first subplot
    if m == 1
        legend(leg_handles, leg_labels, 'Location','southwest', 'FontSize',7);
    end
end

%% Save
mkdir('figures');
saveas(gcf, 'figures/fig_path_comparison.png');
fprintf('Fig 5: Path comparison saved to figures/fig_path_comparison.png\n');
