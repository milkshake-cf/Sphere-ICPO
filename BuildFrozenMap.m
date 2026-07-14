function model = BuildFrozenMap(mapId, doPlot)
%BUILDFROZENMAP Construct one of the preregistered Sphere-ICPO benchmarks.
% Threat format: [x, y, z, radius]. Coordinates are frozen before scoring.

if nargin < 2, doPlot = false; end

H = imread('ChrismasTerrain.tif');
H(H < 0) = 0;
[mapSizeY, mapSizeX] = size(H);
[X, Y] = meshgrid(1:mapSizeX, 1:mapSizeY);

switch mapId
    case 1 % Four sparse threats (Coastal-derived)
        name = 'Map1_4Threat_Sparse';
        threats = [300 300 100 100; 650 450 120 90; ...
                   500 650 110 85; 240 600 100 95];
    case 2 % Five centrally clustered threats
        name = 'Map2_5Threat_Clustered';
        threats = [450 400 150 90; 360 350 120 60; ...
                   550 310 120 60; 510 500 140 50; 410 550 140 50];
    case 3 % Six mixed threats forming staggered alternatives
        name = 'Map3_6Threat_Staggered';
        threats = [420 500 100 80; 600 220 150 70; 500 360 150 80; ...
                   360 210 150 70; 690 560 150 70; 650 720 150 80];
    case 4 % Seven dense threats forming an S-shaped corridor
        name = 'Map4_7Threat_Dense';
        threats = [400 700 150 70; 350 530 150 70; 390 190 150 70; ...
                   510 380 150 70; 610 560 150 70; 620 230 150 70; ...
                   680 690 150 70];
    otherwise
        error('BuildFrozenMap:InvalidMap', 'mapId must be 1, 2, 3, or 4.');
end

model.name = name;
model.mapId = mapId;
model.start = [200; 100; 150];
model.end = [800; 800; 150];
model.n = 10;
model.xmin = 1; model.xmax = mapSizeX;
model.ymin = 1; model.ymax = mapSizeY;
model.zmin = 100; model.zmax = 200;
model.MAPSIZE_X = mapSizeX; model.MAPSIZE_Y = mapSizeY;
model.X = X; model.Y = Y; model.H = H;
model.threats = threats;
model.safetyMargin = 11;
model.frozenVersion = 'sphere-icpo-maps-v1';

if doPlot, PlotModel(model); end
end
