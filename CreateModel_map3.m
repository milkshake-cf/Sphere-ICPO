function model = CreateModel_map3(doPlot)
if nargin < 1, doPlot = false; end
model = BuildFrozenMap(3, doPlot);
end
