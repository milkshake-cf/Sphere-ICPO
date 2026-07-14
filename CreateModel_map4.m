function model = CreateModel_map4(doPlot)
if nargin < 1, doPlot = false; end
model = BuildFrozenMap(4, doPlot);
end
