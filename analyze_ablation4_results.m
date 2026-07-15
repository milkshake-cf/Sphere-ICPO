function report = analyze_ablation4_results(stateFile)
%ANALYZE_ABLATION4_RESULTS Rebuild four-map ablation statistics from raw runs.
loaded = load(stateFile,'AR'); AR = loaded.AR; outDir = fileparts(stateFile);
maps = AR.config.mapNames; variants = AR.config.variantNames;
nMaps = numel(maps); nVariants = numel(variants); milestones = AR.config.milestones;
summaryRows = {}; milestoneRows = {}; finalMean = nan(nMaps,nVariants); aucMean = finalMean;

for m = 1:nMaps
    for v = 1:nVariants
        recs = AR.ablation.(maps{m}).(variants{v});
        costs = [recs.cost]; assert(all(isfinite(costs)),'Non-finite costs in %s/%s.',maps{m},variants{v});
        aucs = arrayfun(@(r)normalized_auc(r.convergence),recs);
        metrics = [recs.metrics];
        finalMean(m,v) = mean(costs); aucMean(m,v) = mean(aucs);
        summaryRows(end+1,:) = {maps{m},variants{v},numel(costs),mean(costs),std(costs), ...
            median(costs),iqr(costs),min(costs),max(costs),mean(aucs),std(aucs), ...
            mean([recs.elapsed]),mean([recs.functionEvaluations]), ...
            mean([metrics.explorationCount]),mean([metrics.exploitationCount]), ...
            mean([metrics.retreatTriggers]),mean([metrics.retreatEvaluations]), ...
            mean([metrics.retreatAccepted]),mean([metrics.retreatBestImprovements])}; %#ok<AGROW>
        curves = cat(2,recs.convergence);
        for q = 1:numel(milestones)
            t = milestones(q); values = curves(t,:);
            milestoneRows(end+1,:) = {maps{m},variants{v},t,mean(values),std(values),median(values)}; %#ok<AGROW>
        end
    end
end

summary = cell2table(summaryRows,'VariableNames',{'Map','Variant','N','Mean','Std','Median','IQR','Min','Max', ...
    'NormalizedAUC','AUCStd','MeanTime','MeanEvaluations','MeanExplorationCount','MeanExploitationCount', ...
    'MeanRetreatTriggers','MeanRetreatEvaluations','MeanRetreatAccepted','MeanRetreatBestImprovements'});
milestoneSummary = cell2table(milestoneRows,'VariableNames',{'Map','Variant','Iteration','Mean','Std','Median'});
writetable(summary,fullfile(outDir,'ablation4_summary.csv'));
writetable(milestoneSummary,fullfile(outDir,'milestone_summary.csv'));

fullIdx = find(strcmp(variants,'Full'),1); removals = {'noSOS','noAdapt','noRetreat'};
components = {'SOS','Adaptive','Retreat'}; removalIdx = cellfun(@(x)find(strcmp(variants,x),1),removals);
testRows = {}; finalHolm = nan(nMaps,3); aucHolm = finalHolm;
for m = 1:nMaps
    fullRecs = AR.ablation.(maps{m}).Full; fullCosts = [fullRecs.cost];
    fullAUC = arrayfun(@(r)normalized_auc(r.convergence),fullRecs);
    rawFinal = zeros(1,3); rawAUC = zeros(1,3); otherCosts = cell(1,3); otherAUC = cell(1,3);
    for j = 1:3
        recs = AR.ablation.(maps{m}).(removals{j});
        assert(isequal([fullRecs.seed],[recs.seed]),'Paired seed mismatch in %s/%s.',maps{m},removals{j});
        otherCosts{j} = [recs.cost]; otherAUC{j} = arrayfun(@(r)normalized_auc(r.convergence),recs);
        rawFinal(j) = safe_signrank(fullCosts,otherCosts{j});
        rawAUC(j) = safe_signrank(fullAUC,otherAUC{j});
    end
    finalHolm(m,:) = holm_adjust(rawFinal); aucHolm(m,:) = holm_adjust(rawAUC);
    for j = 1:3
        testRows(end+1,:) = {maps{m},components{j},removals{j}, ...
            mean(fullCosts-otherCosts{j}),median(fullCosts-otherCosts{j}),mean(fullCosts<otherCosts{j}), ...
            rawFinal(j),finalHolm(m,j),mean(fullAUC-otherAUC{j}),mean(fullAUC<otherAUC{j}), ...
            rawAUC(j),aucHolm(m,j)}; %#ok<AGROW>
    end
end
pairedTests = cell2table(testRows,'VariableNames',{'Map','Component','Removal','FinalMeanDelta', ...
    'FinalMedianDelta','FullFinalWinRate','FinalRawP','FinalHolmP','AUCMeanDelta','FullAUCWinRate','AUCRawP','AUCHolmP'});
writetable(pairedTests,fullfile(outDir,'paired_tests.csv'));

decisionRows = {};
for j = 1:3
    finalWins = sum(finalMean(:,fullIdx) < finalMean(:,removalIdx(j)));
    finalSigWins = sum(finalHolm(:,j)<0.05 & finalMean(:,fullIdx)<finalMean(:,removalIdx(j)));
    aucWins = sum(aucMean(:,fullIdx) < aucMean(:,removalIdx(j)));
    aucSigWins = sum(aucHolm(:,j)<0.05 & aucMean(:,fullIdx)<aucMean(:,removalIdx(j)));
    removalNeverWorse = all(finalMean(:,fullIdx)>=finalMean(:,removalIdx(j)) & ...
        aucMean(:,fullIdx)>=aucMean(:,removalIdx(j)));
    if finalWins>=3 && finalSigWins>=2
        verdict = 'final_accuracy';
    elseif aucWins>=3 && aucSigWins>=2
        verdict = 'anytime_efficiency';
    elseif removalNeverWorse
        verdict = 'unsupported_remove';
    else
        verdict = 'conditional';
    end
    decisionRows(end+1,:) = {components{j},removals{j},finalWins,finalSigWins,aucWins,aucSigWins,verdict}; %#ok<AGROW>
end
decisions = cell2table(decisionRows,'VariableNames',{'Component','Removal','FinalMapsWon','FinalSignificantWins', ...
    'AUCMapsWon','AUCSignificantWins','Verdict'});
writetable(decisions,fullfile(outDir,'component_decisions.csv'));

report.summary = summary; report.milestones = milestoneSummary; report.pairedTests = pairedTests;
report.decisions = decisions; report.finalMean = finalMean; report.aucMean = aucMean;
save(fullfile(outDir,'statistics.mat'),'report');
write_report(fullfile(outDir,'report.txt'),report);
plot_ablation4(AR,outDir,finalMean,aucMean);
end

function value = normalized_auc(curve)
curve = curve(:); denom = max(abs(curve(1)),eps);
if numel(curve)<2, value = curve(1)/denom; else, value = trapz(curve)/((numel(curve)-1)*denom); end
end

function p = safe_signrank(x,y)
if all(x==y), p = 1; else, p = signrank(x,y,'tail','both'); end
end

function adjusted = holm_adjust(p)
[sorted,idx] = sort(p); m = numel(p); adjSorted = zeros(size(p)); running = 0;
for i = 1:m, running = max(running,(m-i+1)*sorted(i)); adjSorted(i) = min(1,running); end
adjusted = zeros(size(p)); adjusted(idx) = adjSorted;
end

function write_report(path,report)
fid = fopen(path,'w'); cleanup = onCleanup(@()fclose(fid));
fprintf(fid,'Sphere-ICPO four-map ablation report\n\n');
for i = 1:height(report.decisions)
    fprintf(fid,'%s: %s (final wins %d, significant %d; AUC wins %d, significant %d)\n', ...
        report.decisions.Component{i},report.decisions.Verdict{i},report.decisions.FinalMapsWon(i), ...
        report.decisions.FinalSignificantWins(i),report.decisions.AUCMapsWon(i),report.decisions.AUCSignificantWins(i));
end
end

function plot_ablation4(AR,outDir,finalMean,aucMean)
maps = AR.config.mapNames; variants = AR.config.variantNames; colors = lines(numel(variants));
fig = figure('Visible','off','Color','w','Position',[50 50 1200 520]);
bar(finalMean,'grouped'); set(gca,'XTick',1:numel(maps),'XTickLabel',compose('Map%d',1:numel(maps)));
ylabel('Final mean cost'); legend(variants,'Location','northoutside','Orientation','horizontal'); grid on;
exportgraphics(fig,fullfile(outDir,'ablation4_final_means.png'),'Resolution',220); close(fig);
fig = figure('Visible','off','Color','w','Position',[50 50 1200 520]);
bar(aucMean,'grouped'); set(gca,'XTick',1:numel(maps),'XTickLabel',compose('Map%d',1:numel(maps)));
ylabel('Normalized convergence AUC'); legend(variants,'Location','northoutside','Orientation','horizontal'); grid on;
exportgraphics(fig,fullfile(outDir,'ablation4_auc.png'),'Resolution',220); close(fig);
fig = figure('Visible','off','Color','w','Position',[50 50 1200 800]); tiledlayout(2,2,'Padding','compact');
for m = 1:numel(maps)
    nexttile; hold on;
    for v = 1:numel(variants)
        curves = cat(2,AR.ablation.(maps{m}).(variants{v}).convergence);
        plot(mean(curves,2),'LineWidth',1.3,'Color',colors(v,:));
    end
    title(strrep(maps{m},'_',' ')); xlabel('Iteration'); ylabel('Mean best cost'); grid on;
end
legend(variants,'Location','southoutside','Orientation','horizontal');
exportgraphics(fig,fullfile(outDir,'ablation4_convergence.png'),'Resolution',220); close(fig);
end
