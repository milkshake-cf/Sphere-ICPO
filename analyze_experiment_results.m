function report = analyze_experiment_results(stateFile)
%ANALYZE_EXPERIMENT_RESULTS Rebuild all statistics from raw run records.
loaded=load(stateFile,'ER'); ER=loaded.ER; outDir=fileparts(stateFile);
mapNames=ER.config.mapNames; algNames=ER.config.algorithmNames;
nMaps=numel(mapNames); nAlgs=numel(algNames);
means=nan(nMaps,nAlgs); ranks=nan(nMaps,nAlgs); summaryRows={};

for m=1:nMaps
    for a=1:nAlgs
        recs=ER.comparison.(mapNames{m}).(algNames{a});
        costs=[recs.cost]; elapsed=[recs.elapsed]; evals=[recs.functionEvaluations];
        assert(all(isfinite(costs)),'Non-finite costs in %s/%s.',mapNames{m},algNames{a});
        means(m,a)=mean(costs);
        summaryRows(end+1,:)={mapNames{m},algNames{a},numel(costs),mean(costs),std(costs), ...
            median(costs),iqr(costs),min(costs),max(costs),mean(elapsed),mean(evals)}; %#ok<AGROW>
    end
    [~,order]=sort(means(m,:),'ascend'); ranks(m,order)=1:nAlgs;
end
summary=cell2table(summaryRows,'VariableNames',{'Map','Algorithm','N','Mean','Std','Median','IQR','Min','Max','MeanTime','MeanEvaluations'});
writetable(summary,fullfile(outDir,'summary.csv'));

avgRanks=mean(ranks,1); wins=sum(ranks==1,1);
rankTable=table(algNames(:),avgRanks(:),wins(:),'VariableNames',{'Algorithm','AverageRank','MapWins'});
rankTable=sortrows(rankTable,'AverageRank'); writetable(rankTable,fullfile(outDir,'ranks.csv'));
if nMaps>=2, [friedmanP,~,~]=friedman(ranks,1,'off'); else, friedmanP=NaN; end

icpo=find(strcmp(algNames,'ICPO')); baseline=setdiff(1:nAlgs,icpo,'stable'); testRows={};
for m=1:nMaps
    x=[ER.comparison.(mapNames{m}).ICPO.cost]; rawP=zeros(1,numel(baseline));
    for j=1:numel(baseline)
        y=[ER.comparison.(mapNames{m}).(algNames{baseline(j)}).cost];
        rawP(j)=ranksum(x,y,'tail','both');
    end
    adjusted=holm_adjust(rawP);
    for j=1:numel(baseline)
        y=[ER.comparison.(mapNames{m}).(algNames{baseline(j)}).cost];
        testRows(end+1,:)={mapNames{m},algNames{baseline(j)},rawP(j),adjusted(j),a12_lower(x,y),mean(x)<mean(y)}; %#ok<AGROW>
    end
end
wilcoxon=cell2table(testRows,'VariableNames',{'Map','Baseline','RawP','HolmP','A12','ICPOLowerMean'});
writetable(wilcoxon,fullfile(outDir,'wilcoxon_holm_a12.csv'));

ablMap=fieldnames(ER.ablation); ablNames=ER.config.ablationNames; ablRows={};
for a=1:numel(ablNames)
    costs=[ER.ablation.(ablMap{1}).(ablNames{a}).cost];
    ablRows(end+1,:)={ablMap{1},ablNames{a},numel(costs),mean(costs),std(costs),median(costs),iqr(costs),min(costs),max(costs)}; %#ok<AGROW>
end
ablation=cell2table(ablRows,'VariableNames',{'Map','Variant','N','Mean','Std','Median','IQR','Min','Max'});
writetable(ablation,fullfile(outDir,'ablation_summary.csv'));

report.summary=summary; report.ranks=rankTable; report.rankMatrix=ranks;
report.friedmanP=friedmanP; report.wilcoxon=wilcoxon; report.ablation=ablation;
report.ICPOFirst=strcmp(rankTable.Algorithm{1},'ICPO');
save(fullfile(outDir,'statistics.mat'),'report');
write_text_report(fullfile(outDir,'report.txt'),report);
plot_experiment_figures(stateFile);
end

function adjusted=holm_adjust(p)
[sorted,idx]=sort(p); m=numel(p); adjSorted=zeros(size(p)); running=0;
for i=1:m
    running=max(running,(m-i+1)*sorted(i)); adjSorted(i)=min(1,running);
end
adjusted=zeros(size(p)); adjusted(idx)=adjSorted;
end

function score=a12_lower(x,y)
score=0;
for i=1:numel(x), score=score+sum(x(i)<y)+0.5*sum(x(i)==y); end
score=score/(numel(x)*numel(y));
end

function write_text_report(path,report)
fid=fopen(path,'w'); cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'Sphere-ICPO experiment report\n');
fprintf(fid,'Friedman p: %.6g\n',report.friedmanP);
fprintf(fid,'ICPO average-rank first: %d\n\n',report.ICPOFirst);
for i=1:height(report.ranks)
    fprintf(fid,'%s: average rank %.3f, map wins %d\n',report.ranks.Algorithm{i},report.ranks.AverageRank(i),report.ranks.MapWins(i));
end
end
