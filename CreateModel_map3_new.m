function model = CreateModel_map3_new()
    H = imread('ChrismasTerrain.tif');
    H(H < 0) = 0;
    MAPSIZE_X = size(H,2);
    MAPSIZE_Y = size(H,1);
    [X,Y] = meshgrid(1:MAPSIZE_X,1:MAPSIZE_Y);

    % 3 threats — scattered, blocking the direct diagonal
    R1=100; x1=450; y1=300; z1=150;  % Large, blocks middle-left
    R2=90;  x2=600; y2=600; z2=150;  % Large, blocks upper-right
    R3=95;  x3=350; y3=600; z3=150;  % Large, blocks upper-left

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
    model.threats=[x1 y1 z1 R1;x2 y2 z2 R2;x3 y3 z3 R3];
    PlotModel(model);
end
