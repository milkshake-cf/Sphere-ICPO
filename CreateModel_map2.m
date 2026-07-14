function model = CreateModel_map2(doPlot)
if nargin < 1, doPlot = false; end
model = BuildFrozenMap(2, doPlot);
end
