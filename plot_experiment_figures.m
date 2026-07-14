function plot_experiment_figures(stateFile)
%PLOT_EXPERIMENT_FIGURES Regenerate figures exclusively from raw results.
loaded=load(stateFile,'ER'); ER=loaded.ER; outDir=fullfile(fileparts(stateFile),'figures');
if ~exist(outDir,'dir'),mkdir(outDir);end
maps=ER.config.mapNames; algs=ER.config.algorithmNames; colors=lines(numel(algs));
nMaps=numel(maps); nCols=min(2,nMaps); nRows=ceil(nMaps/nCols);

fig=figure('Visible','off','Color','w','Position',[50 50 1200 800]);
tiledlayout(nRows,nCols,'Padding','compact');
for m=1:numel(maps)
    nexttile; hold on;
    for a=1:numel(algs)
        recs=ER.comparison.(maps{m}).(algs{a}); curves=cat(2,recs.convergence);
        plot(mean(curves,2,'omitnan'),'LineWidth',1.4,'Color',colors(a,:));
    end
    title(strrep(maps{m},'_',' ')); xlabel('Iteration'); ylabel('Mean best cost'); grid on;
end
legend(algs,'Location','southoutside','Orientation','horizontal');
exportgraphics(fig,fullfile(outDir,'convergence.png'),'Resolution',220); close(fig);

fig=figure('Visible','off','Color','w','Position',[50 50 1200 800]); tiledlayout(nRows,nCols,'Padding','compact');
for m=1:numel(maps)
    nexttile; values=[]; groups={};
    for a=1:numel(algs)
        c=[ER.comparison.(maps{m}).(algs{a}).cost]; values=[values c]; groups=[groups repmat(algs(a),1,numel(c))]; %#ok<AGROW>
    end
    boxplot(values,groups); title(strrep(maps{m},'_',' ')); ylabel('Cost'); grid on;
end
exportgraphics(fig,fullfile(outDir,'boxplots.png'),'Resolution',220); close(fig);

means=zeros(numel(maps),numel(algs)); errors=means;
for m=1:numel(maps)
    for a=1:numel(algs)
        c=[ER.comparison.(maps{m}).(algs{a}).cost]; means(m,a)=mean(c); errors(m,a)=std(c);
    end
end
fig=figure('Visible','off','Color','w','Position',[50 50 1200 520]);
if nMaps==1
    bar(1:numel(algs),means(1,:)); hold on;
    errorbar(1:numel(algs),means(1,:),errors(1,:),'k.','LineWidth',0.8);
    set(gca,'XTick',1:numel(algs),'XTickLabel',algs);
else
    b=bar(means,'grouped'); hold on;
    for a=1:numel(algs)
        errorbar(b(a).XEndPoints,means(:,a),errors(:,a),'k.','LineWidth',0.8);
    end
    set(gca,'XTick',1:nMaps,'XTickLabel',compose('Map%d',1:nMaps));
    legend(algs,'Location','northoutside','Orientation','horizontal');
end
ylabel('Mean cost'); grid on;
exportgraphics(fig,fullfile(outDir,'comparison_means.png'),'Resolution',220); close(fig);

fig=figure('Visible','off','Color','w','Position',[50 50 1200 900]); tiledlayout(nRows,nCols,'Padding','compact');
for m=1:numel(maps)
    model=BuildFrozenMap(ER.config.mapIds(m),false); nexttile; imagesc(model.H); axis xy equal tight; hold on;
    theta=linspace(0,2*pi,200);
    for j=1:size(model.threats,1)
        hThreat=plot(model.threats(j,1)+model.threats(j,4)*cos(theta), ...
             model.threats(j,2)+model.threats(j,4)*sin(theta),'r--','LineWidth',1);
    end
    selected=[find(strcmp(algs,'SPSO')),find(strcmp(algs,'ICPO'))]; pathHandles=gobjects(1,2);
    for q=1:2
        a=selected(q);
        recs=ER.comparison.(maps{m}).(algs{a}); [~,idx]=min([recs.cost]); p=recs(idx).bestCartesian;
        pathHandles(q)=plot([model.start(1) p.x model.end(1)],[model.start(2) p.y model.end(2)], ...
            'LineWidth',1.8,'Color',colors(a,:));
    end
    hStart=plot(model.start(1),model.start(2),'gs','MarkerFaceColor','g');
    hEnd=plot(model.end(1),model.end(2),'r^','MarkerFaceColor','r');
    title(strrep(maps{m},'_',' ')); xlabel('x [m]'); ylabel('y [m]');
end
legend([hThreat pathHandles hStart hEnd],{'Threat','SPSO','ICPO','Start','End'}, ...
    'Location','southoutside','Orientation','horizontal');
exportgraphics(fig,fullfile(outDir,'best_paths.png'),'Resolution',220); close(fig);

ablMap=fieldnames(ER.ablation); vars=ER.config.ablationNames; mu=zeros(size(vars)); sd=mu;
for a=1:numel(vars),c=[ER.ablation.(ablMap{1}).(vars{a}).cost];mu(a)=mean(c);sd(a)=std(c);end
fig=figure('Visible','off','Color','w'); bar(mu); hold on; errorbar(1:numel(mu),mu,sd,'k.');
set(gca,'XTick',1:numel(vars),'XTickLabel',vars); ylabel('Mean cost');
title(sprintf('Ablation - Map3 (%d particles)',ER.config.nPop)); grid on;
ylim([min(mu-sd)-100 max(mu+sd)+100]);
exportgraphics(fig,fullfile(outDir,'ablation.png'),'Resolution',220);close(fig);
end
