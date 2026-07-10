function model = CreateModel_map2_new()
    H = imread('ChrismasTerrain.tif');
    H(H < 0) = 0;
    MAPSIZE_X = size(H,2);
    MAPSIZE_Y = size(H,1);
    [X,Y] = meshgrid(1:MAPSIZE_X,1:MAPSIZE_Y);

    % 5 threats — clustered in the center, forcing a detour
    R1=90; x1=450; y1=400; z1=150;  % Large central threat
    R2=60; x2=350; y2=350; z2=120;
    R3=60; x3=550; y3=300; z3=120;
    R4=50; x4=500; y4=500; z4=140;
    R5=50; x5=400; y5=550; z5=140;

    xmin=1; xmax=MAPSIZE_X;
    ymin=1; ymax=MAPSIZE_Y;
    zmin=100; zmax=200;

    start_location = [200;100;150];
    end_location = [800;800;150];
    n=10;

    model.start=start_location; model.end=end_location; model.n=n;
    model.xmin=xmin; model.xmax=xmax;
    model.ymin=ymin; model.ymax=ymax;
    model.zmin=zmin; model.zmax=zmax;
    model.MAPSIZE_X=MAPSIZE_X; model.MAPSIZE_Y=MAPSIZE_Y;
    model.X=X; model.Y=Y; model.H=H;
    model.threats=[x1 y1 z1 R1;x2 y2 z2 R2;x3 y3 z3 R3;x4 y4 z4 R4;x5 y5 z5 R5];
    PlotModel(model);
end
