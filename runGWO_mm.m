function [Alpha, BestCost] = runGWO_mm(model, nPop, MaxIt)
    CostFunction = @(x) MyCost(x, model);
    nVar = model.n; VarSize = [1 nVar];

    VarMin.x = model.xmin; VarMax.x = model.xmax;
    VarMin.y = model.ymin; VarMax.y = model.ymax;
    VarMin.z = model.zmin; VarMax.z = model.zmax;
    VarMax.r = 2 * norm(model.start - model.end) / nVar; VarMin.r = 0;
    AngleRange = pi/4; VarMin.psi = -AngleRange; VarMax.psi = AngleRange;
    dirVector = model.end - model.start;
    phi0 = atan2(dirVector(2), dirVector(1));
    VarMin.phi = phi0 - AngleRange; VarMax.phi = phi0 + AngleRange;

    empty_wolf.Position = []; empty_wolf.Cost = [];
    Alpha.Cost = inf; Alpha.Position = [];
    Beta.Cost = inf;  Beta.Position = [];
    Delta.Cost = inf; Delta.Position = [];
    pack = repmat(empty_wolf, nPop, 1);

    isInit = false;
    while ~isInit
        for i = 1:nPop
            pack(i).Position = CreateRandomSolution(VarSize, VarMin, VarMax);
            cartPos = SphericalToCart(pack(i).Position, model);
            if any(isnan(cartPos.x)) || any(isnan(cartPos.y)) || any(isnan(cartPos.z))
                pack(i).Cost = inf;
            else
                try, pack(i).Cost = CostFunction(cartPos); catch, pack(i).Cost = inf; end
            end
            if pack(i).Cost < Alpha.Cost
                Delta = Beta; Beta = Alpha; Alpha.Position = pack(i).Position; Alpha.Cost = pack(i).Cost; isInit = true;
            elseif pack(i).Cost < Beta.Cost
                Delta = Beta; Beta.Position = pack(i).Position; Beta.Cost = pack(i).Cost;
            elseif pack(i).Cost < Delta.Cost
                Delta.Position = pack(i).Position; Delta.Cost = pack(i).Cost;
            end
        end
    end
    if isempty(Beta.Position), Beta = Alpha; end
    if isempty(Delta.Position), Delta = Alpha; end

    BestCost = zeros(MaxIt, 1);

    for t = 1:MaxIt
        BestCost(t) = Alpha.Cost;
        a = 2 - t*(2/MaxIt);
        for i = 1:nPop
            [X1_r, X2_r, X3_r] = GWO_update(pack(i).Position.r, Alpha.Position.r, Beta.Position.r, Delta.Position.r, a, VarSize);
            pack(i).Position.r = (X1_r + X2_r + X3_r) / 3;
            [X1_psi, X2_psi, X3_psi] = GWO_update(pack(i).Position.psi, Alpha.Position.psi, Beta.Position.psi, Delta.Position.psi, a, VarSize);
            pack(i).Position.psi = (X1_psi + X2_psi + X3_psi) / 3;
            [X1_phi, X2_phi, X3_phi] = GWO_update(pack(i).Position.phi, Alpha.Position.phi, Beta.Position.phi, Delta.Position.phi, a, VarSize);
            pack(i).Position.phi = (X1_phi + X2_phi + X3_phi) / 3;

            pack(i).Position.r = max(min(pack(i).Position.r, VarMax.r), VarMin.r);
            pack(i).Position.psi = max(min(pack(i).Position.psi, VarMax.psi), VarMin.psi);
            pack(i).Position.phi = max(min(pack(i).Position.phi, VarMax.phi), VarMin.phi);

            cartPos = SphericalToCart(pack(i).Position, model);
            if any(isnan(cartPos.x)) || any(isnan(cartPos.y)) || any(isnan(cartPos.z))
                pack(i).Cost = inf;
            else
                try, pack(i).Cost = CostFunction(cartPos); catch, pack(i).Cost = inf; end
            end
            if pack(i).Cost < Alpha.Cost
                Delta = Beta; Beta = Alpha; Alpha.Position = pack(i).Position; Alpha.Cost = pack(i).Cost;
            elseif pack(i).Cost < Beta.Cost
                Delta = Beta; Beta.Position = pack(i).Position; Beta.Cost = pack(i).Cost;
            elseif pack(i).Cost < Delta.Cost
                Delta.Position = pack(i).Position; Delta.Cost = pack(i).Cost;
            end
        end
    end
end

function [X1, X2, X3] = GWO_update(X, A_Pos, B_Pos, D_Pos, a, VarSize)
    A1 = 2*a*rand(VarSize) - a; C1 = 2*rand(VarSize);
    D_alpha = abs(C1.*A_Pos - X); X1 = A_Pos - A1.*D_alpha;
    A2 = 2*a*rand(VarSize) - a; C2 = 2*rand(VarSize);
    D_beta = abs(C2.*B_Pos - X); X2 = B_Pos - A2.*D_beta;
    A3 = 2*a*rand(VarSize) - a; C3 = 2*rand(VarSize);
    D_delta = abs(C3.*D_Pos - X); X3 = D_Pos - A3.*D_delta;
end
