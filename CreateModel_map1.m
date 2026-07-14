function model = CreateModel_map1(doPlot)
if nargin < 1, doPlot = false; end
model = BuildFrozenMap(1, doPlot);
end
