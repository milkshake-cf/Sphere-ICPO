function manifest = validate_frozen_maps(outputDir)
%VALIDATE_FROZEN_MAPS Validate, preview, and export the frozen map manifest.
if nargin < 1, outputDir = fullfile('results','map_manifest_v1'); end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

maps = frozen_map_registry();
manifest.version = 'sphere-icpo-maps-v1';
manifest.created = datestr(now,30);
manifest.start = [200 100 150]; manifest.end = [800 800 150];
manifest.safetyMargin = 11;
scores = zeros(numel(maps),1);

for k = 1:numel(maps)
    model = maps{k}.func(false);
    threats = model.threats;
    radii = threats(:,4);
    assert(all(threats(:,1)-radii >= model.xmin & threats(:,1)+radii <= model.xmax));
    assert(all(threats(:,2)-radii >= model.ymin & threats(:,2)+radii <= model.ymax));
    ds = hypot(threats(:,1)-model.start(1), threats(:,2)-model.start(2))-radii;
    de = hypot(threats(:,1)-model.end(1), threats(:,2)-model.end(2))-radii;
    assert(all(ds >= 50) && all(de >= 50), 'Threat too close to start or end.');

    [coverage, corridorCoverage, feasible] = geometry_metrics(model, model.safetyMargin);
    assert(feasible, '%s has no 2-D path with the required safety margin.', model.name);
    score = 0.6*(size(threats,1)/7) + 0.4*corridorCoverage;
    scores(k) = score;

    entry.id = k; entry.name = model.name; entry.threats = threats;
    entry.threatCount = size(threats,1); entry.coverage = coverage;
    entry.corridorCoverage = corridorCoverage; entry.complexityScore = score;
    entry.feasible = feasible; manifest.maps(k) = entry;

    fig = figure('Visible','off','Color','w'); PlotModel(model);
    title(sprintf('%s | score %.3f', strrep(model.name,'_',' '), score));
    exportgraphics(fig, fullfile(outputDir, sprintf('map%d_preview.png',k)), 'Resolution',200);
    close(fig);
end
assert(all(diff(scores)>0), 'Frozen-map complexity score must increase from Map1 to Map4.');
save(fullfile(outputDir,'manifest.mat'),'manifest');
writetable(manifest_table(manifest), fullfile(outputDir,'manifest.csv'));
end

function [coverage,corridorCoverage,feasible] = geometry_metrics(model,margin)
step = 5;
[X,Y] = meshgrid(model.xmin:step:model.xmax, model.ymin:step:model.ymax);
blocked = false(size(X));
for i=1:size(model.threats,1)
    blocked = blocked | hypot(X-model.threats(i,1),Y-model.threats(i,2)) <= model.threats(i,4)+margin;
end
coverage = mean(blocked(:));
a=model.start(1:2)'; b=model.end(1:2)'; ab=b-a;
t=((X-a(1))*ab(1)+(Y-a(2))*ab(2))/sum(ab.^2); t=max(0,min(1,t));
d=hypot(X-(a(1)+t*ab(1)),Y-(a(2)+t*ab(2)));
corridor=d<=120; corridorCoverage=mean(blocked(corridor));
sx=round((model.start(1)-model.xmin)/step)+1; sy=round((model.start(2)-model.ymin)/step)+1;
ex=round((model.end(1)-model.xmin)/step)+1; ey=round((model.end(2)-model.ymin)/step)+1;
feasible = grid_reachable(blocked,sy,sx,ey,ex);
end

function ok=grid_reachable(blocked,sy,sx,ey,ex)
visited=false(size(blocked)); q=zeros(numel(blocked),2); head=1; tail=1;
q(1,:)=[sy sx]; visited(sy,sx)=true; dirs=[-1 0;1 0;0 -1;0 1;-1 -1;-1 1;1 -1;1 1];
ok=false;
while head<=tail
    p=q(head,:); head=head+1; if all(p==[ey ex]),ok=true;return;end
    for d=1:8
        n=p+dirs(d,:);
        if n(1)>=1 && n(1)<=size(blocked,1) && n(2)>=1 && n(2)<=size(blocked,2) && ~blocked(n(1),n(2)) && ~visited(n(1),n(2))
            tail=tail+1; q(tail,:)=n; visited(n(1),n(2))=true;
        end
    end
end
end

function T=manifest_table(manifest)
rows=[];
for k=1:numel(manifest.maps)
    m=manifest.maps(k);
    for j=1:size(m.threats,1)
        rows=[rows; k j m.threats(j,:) m.coverage m.corridorCoverage m.complexityScore]; %#ok<AGROW>
    end
end
T=array2table(rows,'VariableNames',{'Map','Threat','X','Y','Z','Radius','Coverage','CorridorCoverage','ComplexityScore'});
end
