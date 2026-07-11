% plot_paths.m — Path visualization for Sphere-ICPO paper
clear; close all;

maps = {@CreateModel, @CreateModel_map4};
map_names = {'Map1','Map4'};
algs = {@runSPSO_mm, 500; @runICPO_SOSv4_mm, 500};
alg_names = {'SPSO','ICPO'};

for m = 1:2
    model = maps{m}(); close all;

    for a = 1:2
        % Run to get best path
        [gb, ~] = algs{a,1}(model, algs{a,2}, 200);
        bestPos = SphericalToCart(gb.Position, model);

        figure('Position',[50 50 600 500]);
        PlotSolution(bestPos, model, 0.95);
        title(sprintf('%s — %s (Cost=%.2f)', map_names{m}, alg_names{a}, gb.Cost));
        saveas(gcf, sprintf('figures/path_%s_%s.png', map_names{m}, alg_names{a}));
        close;
    end
end
fprintf('Path figures saved\n');
