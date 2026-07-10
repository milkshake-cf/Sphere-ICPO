function [GlobalBest, BestCost] = runWOA_mm(model, nPop, MaxIt)
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

    b = 1;  % spiral constant
    empty_whale.Position = []; empty_whale.Cost = [];
    GlobalBest.Cost = inf; GlobalBest.Position = [];
    pop = repmat(empty_whale, nPop, 1);

    isInit = false;
    while ~isInit
        for i = 1:nPop
            pop(i).Position = CreateRandomSolution(VarSize, VarMin, VarMax);
            cartPos = SphericalToCart(pop(i).Position, model);
            if any(isnan(cartPos.x)) || any(isnan(cartPos.y)) || any(isnan(cartPos.z))
                pop(i).Cost = inf;
            else
                try, pop(i).Cost = CostFunction(cartPos); catch, pop(i).Cost = inf; end
            end
            if pop(i).Cost < GlobalBest.Cost
                GlobalBest.Position = pop(i).Position; GlobalBest.Cost = pop(i).Cost; isInit = true;
            end
        end
    end

    BestCost = zeros(MaxIt, 1);

    for t = 1:MaxIt
        BestCost(t) = GlobalBest.Cost;
        a = 2 - t*(2/MaxIt);
        a2 = -1 + t*(-1/MaxIt);
        for i = 1:nPop
            r1 = rand(); r2 = rand();
            A = 2*a*r1 - a; C = 2*r2;
            l = (a2-1)*rand() + 1; p = rand();

            if p < 0.5
                if abs(A) >= 1
                    k = randi(nPop);
                    D_r = abs(C*pop(k).Position.r - pop(i).Position.r);
                    pop(i).Position.r = pop(k).Position.r - A*D_r;
                    D_psi = abs(C*pop(k).Position.psi - pop(i).Position.psi);
                    pop(i).Position.psi = pop(k).Position.psi - A*D_psi;
                    D_phi = abs(C*pop(k).Position.phi - pop(i).Position.phi);
                    pop(i).Position.phi = pop(k).Position.phi - A*D_phi;
                else
                    D_r = abs(C*GlobalBest.Position.r - pop(i).Position.r);
                    pop(i).Position.r = GlobalBest.Position.r - A*D_r;
                    D_psi = abs(C*GlobalBest.Position.psi - pop(i).Position.psi);
                    pop(i).Position.psi = GlobalBest.Position.psi - A*D_psi;
                    D_phi = abs(C*GlobalBest.Position.phi - pop(i).Position.phi);
                    pop(i).Position.phi = GlobalBest.Position.phi - A*D_phi;
                end
            else
                D_r = abs(GlobalBest.Position.r - pop(i).Position.r);
                pop(i).Position.r = D_r .* exp(b*l) .* cos(2*pi*l) + GlobalBest.Position.r;
                D_psi = abs(GlobalBest.Position.psi - pop(i).Position.psi);
                pop(i).Position.psi = D_psi .* exp(b*l) .* cos(2*pi*l) + GlobalBest.Position.psi;
                D_phi = abs(GlobalBest.Position.phi - pop(i).Position.phi);
                pop(i).Position.phi = D_phi .* exp(b*l) .* cos(2*pi*l) + GlobalBest.Position.phi;
            end

            pop(i).Position.r = max(min(pop(i).Position.r, VarMax.r), VarMin.r);
            pop(i).Position.psi = max(min(pop(i).Position.psi, VarMax.psi), VarMin.psi);
            pop(i).Position.phi = max(min(pop(i).Position.phi, VarMax.phi), VarMin.phi);

            cartPos = SphericalToCart(pop(i).Position, model);
            if any(isnan(cartPos.x)) || any(isnan(cartPos.y)) || any(isnan(cartPos.z))
                pop(i).Cost = inf;
            else
                try, pop(i).Cost = CostFunction(cartPos); catch, pop(i).Cost = inf; end
            end
            if pop(i).Cost < GlobalBest.Cost
                GlobalBest.Position = pop(i).Position; GlobalBest.Cost = pop(i).Cost;
            end
        end
    end
end
