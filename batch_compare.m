% batch_compare.m — 3 algorithms × 2 maps comparison
% SVCPO vs CPO vs SPSO on Map1 (Christmas) and Map4 (7-Threat)
%
clear; close all;

%% Configuration
nRuns = 20;           % Independent runs per algorithm per map
nPop_CPO = 150;       % CPO/SVCPO population
nPop_SPSO = 500;      % SPSO population (per original paper)
MaxIt = 200;          % Max iterations

% Map definitions
maps = {
    struct('name', 'Map1_Christmas', 'func', @CreateModel),
    struct('name', 'Map4_7Threat',  'func', @CreateModel_map4)
};

% Algorithm definitions
algs = {
    struct('name', 'SPSO',  'runner', @runSPSO_mm,  'nPop', nPop_SPSO),
    struct('name', 'CPO',   'runner', @runCPO_mm,   'nPop', nPop_CPO),
    struct('name', 'SVCPO', 'runner', @runSVCPO_mm, 'nPop', nPop_CPO)
};

%% Results storage
allResults = struct();
allResults.config = struct('nRuns', nRuns, 'MaxIt', MaxIt, 'timestamp', datetime('now'));
allResults.maps = maps;
allResults.algs = algs;

%% Run experiments
timestamp_str = datestr(now, 'yyyymmdd_HHMMSS');
results_dir = fullfile('results', timestamp_str);
mkdir(results_dir);

fprintf('========================================\n');
fprintf('  BATCH COMPARISON: SVCPO vs CPO vs SPSO\n');
fprintf('  Maps: %d | Algs: %d | Runs: %d\n', length(maps), length(algs), nRuns);
fprintf('  Results: %s\n', results_dir);
fprintf('========================================\n\n');

for m = 1:length(maps)
    map_name = maps{m}.name;
    map_func = maps{m}.func;
    fprintf('=== MAP %d/%d: %s ===\n', m, length(maps), map_name);

    model = map_func();
    close all;  % close map figure after model creation

    for a = 1:length(algs)
        alg_name = algs{a}.name;
        nPop = algs{a}.nPop;
        runner = algs{a}.runner;

        fprintf('  --- %s (nPop=%d, %d runs) ---\n', alg_name, nPop, nRuns);

        costs = zeros(nRuns, 1);
        allBestCosts = cell(nRuns, 1);
        t_start = tic;

        for r = 1:nRuns
            [GlobalBest, BestCost] = runner(model, nPop, MaxIt);
            costs(r) = GlobalBest.Cost;
            allBestCosts{r} = BestCost;
            if mod(r, 5) == 0
                fprintf('    Run %d/%d: BestCost = %.2f\n', r, nRuns, costs(r));
            end
        end

        elapsed = toc(t_start);

        % Statistics
        mean_cost = mean(costs);
        std_cost = std(costs);
        min_cost = min(costs);
        max_cost = max(costs);

        fprintf('    >> Mean=%.2f  Std=%.2f  Min=%.2f  Max=%.2f  Time=%.1fs\n', ...
            mean_cost, std_cost, min_cost, max_cost, elapsed);

        % Store results
        allResults.(map_name).(alg_name).costs = costs;
        allResults.(map_name).(alg_name).allBestCosts = allBestCosts;
        allResults.(map_name).(alg_name).mean = mean_cost;
        allResults.(map_name).(alg_name).std = std_cost;
        allResults.(map_name).(alg_name).min = min_cost;
        allResults.(map_name).(alg_name).max = max_cost;
        allResults.(map_name).(alg_name).elapsed = elapsed;

        % Save intermediate results
        save(fullfile(results_dir, 'results.mat'), 'allResults');
    end
end

%% Summary table
fprintf('\n============= SUMMARY =============\n');
fprintf('%-20s %-8s %-10s %-10s %-10s\n', 'Map', 'Alg', 'Mean', 'Std', 'Min');
fprintf('%-20s %-8s %-10s %-10s %-10s\n', '---', '---', '----', '---', '---');
for m = 1:length(maps)
    map_name = maps{m}.name;
    for a = 1:length(algs)
        alg_name = algs{a}.name;
        dat = allResults.(map_name).(alg_name);
        fprintf('%-20s %-8s %10.2f %10.2f %10.2f\n', map_name, alg_name, dat.mean, dat.std, dat.min);
    end
    fprintf('\n');
end

%% Save final results
save(fullfile(results_dir, 'results.mat'), 'allResults');

%% Quick convergence plot
figure('Position', [100 100 800 500]);
for m = 1:length(maps)
    subplot(1, 2, m);
    hold on;
    colors = {'b', 'r', [0 0.6 0]};
    for a = 1:length(algs)
        alg_name = algs{a}.name;
        allBC = allResults.(maps{m}.name).(alg_name).allBestCosts;
        % Average convergence curve
        avg_curve = zeros(MaxIt, 1);
        for r = 1:nRuns
            avg_curve = avg_curve + allBC{r}(:);
        end
        avg_curve = avg_curve / nRuns;
        plot(1:MaxIt, avg_curve, 'Color', colors{a}, 'LineWidth', 1.5);
    end
    legend(algs{1}.name, algs{2}.name, algs{3}.name);
    xlabel('Iteration'); ylabel('Best Cost');
    title(maps{m}.name, 'Interpreter', 'none');
    grid on;
end
saveas(gcf, fullfile(results_dir, 'convergence.png'));
fprintf('\nResults saved to: %s\n', results_dir);
fprintf('Done!\n');
