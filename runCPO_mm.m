% runCPO_mm.m — CPO runner (baseline, same as CPO_MAIN_v2 logic)
function [GlobalBest, BestCost, RunInfo] = runCPO_mm(model, nPop, MaxIt)

    global SPHERE_ICPO_EVAL_COUNT; SPHERE_ICPO_EVAL_COUNT = 0;
    initialRng = rng; runTimer = tic;

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

    alpha_param = 0.2; Tf = 0.8;

    empty_agent.Position = []; empty_agent.Cost = [];
    GlobalBest.Cost = inf; GlobalBest.Position = [];
    pop = repmat(empty_agent, nPop, 1);
    prev_positions = cell(nPop, 1);

    isInit = false;
    while ~isInit
        for i = 1:nPop
            [pop(i).Position,pop(i).Cost] = CreateFiniteRandomSolution(VarSize,VarMin,VarMax,model);
            prev_positions{i} = pop(i).Position;
            if pop(i).Cost < GlobalBest.Cost
                GlobalBest.Position = pop(i).Position; GlobalBest.Cost = pop(i).Cost; isInit = true;
            end
        end
    end

    BestCost = zeros(MaxIt, 1);

    for t = 1:MaxIt
        BestCost(t) = GlobalBest.Cost;
        for i = 1:nPop
            U1 = rand(VarSize) > rand();
            if rand() < rand()  % EXPLORATION
                if rand() < rand()  % Strategy 1
                    k = randi(nPop);
                    y_r = (pop(i).Position.r + pop(k).Position.r) / 2;
                    pop(i).Position.r = pop(i).Position.r + randn(VarSize).*abs(2*rand()*GlobalBest.Position.r - y_r);
                    y_psi = (pop(i).Position.psi + pop(k).Position.psi) / 2;
                    pop(i).Position.psi = pop(i).Position.psi + randn(VarSize).*abs(2*rand()*GlobalBest.Position.psi - y_psi);
                    y_phi = (pop(i).Position.phi + pop(k).Position.phi) / 2;
                    pop(i).Position.phi = pop(i).Position.phi + randn(VarSize).*abs(2*rand()*GlobalBest.Position.phi - y_phi);
                else  % Strategy 2
                    k = randi(nPop); m = randi(nPop);
                    y_r = (pop(i).Position.r + pop(k).Position.r) / 2;
                    pop(i).Position.r = U1.*pop(i).Position.r + (1-U1).*(y_r + rand()*(pop(m).Position.r - pop(k).Position.r));
                    y_psi = (pop(i).Position.psi + pop(k).Position.psi) / 2;
                    pop(i).Position.psi = U1.*pop(i).Position.psi + (1-U1).*(y_psi + rand()*(pop(m).Position.psi - pop(k).Position.psi));
                    y_phi = (pop(i).Position.phi + pop(k).Position.phi) / 2;
                    pop(i).Position.phi = U1.*pop(i).Position.phi + (1-U1).*(y_phi + rand()*(pop(m).Position.phi - pop(k).Position.phi));
                end
            else  % EXPLOITATION
                Yt = 2 * rand() * (1 - t/MaxIt)^(t/MaxIt);
                U2 = (rand(VarSize) < 0.5) * 2 - 1; S_base = rand() * U2;
                allCosts = [pop.Cost]; finiteCosts = allCosts(isfinite(allCosts));
                sumFitness = sum(finiteCosts) + eps;
                safeCost = pop(i).Cost;
                if ~isfinite(safeCost), safeCost = max(finiteCosts)*10; end
                if rand() < Tf  % Strategy 3
                    St = exp(safeCost / sumFitness); S = S_base .* Yt .* St;
                    k = randi(nPop); m = randi(nPop);
                    pop(i).Position.r = (1-U1).*pop(i).Position.r + U1.*(pop(k).Position.r + St*(pop(m).Position.r - pop(k).Position.r) - S);
                    pop(i).Position.psi = (1-U1).*pop(i).Position.psi + U1.*(pop(k).Position.psi + St*(pop(m).Position.psi - pop(k).Position.psi) - S);
                    pop(i).Position.phi = (1-U1).*pop(i).Position.phi + U1.*(pop(k).Position.phi + St*(pop(m).Position.phi - pop(k).Position.phi) - S);
                else  % Strategy 4
                    Mt = exp(safeCost / sumFitness); k = randi(nPop);
                    vt = pop(i).Position; Vtp = pop(k).Position; r2_param = rand();
                    Ft_r = rand(VarSize).*(Mt*(-vt.r + Vtp.r)); S_r = S_base.*Yt.*Ft_r;
                    pop(i).Position.r = GlobalBest.Position.r + (alpha_param*(1-r2_param)+r2_param)*(U2.*GlobalBest.Position.r - pop(i).Position.r) - S_r;
                    Ft_psi = rand(VarSize).*(Mt*(-vt.psi + Vtp.psi)); S_psi = S_base.*Yt.*Ft_psi;
                    pop(i).Position.psi = GlobalBest.Position.psi + (alpha_param*(1-r2_param)+r2_param)*(U2.*GlobalBest.Position.psi - pop(i).Position.psi) - S_psi;
                    Ft_phi = rand(VarSize).*(Mt*(-vt.phi + Vtp.phi)); S_phi = S_base.*Yt.*Ft_phi;
                    pop(i).Position.phi = GlobalBest.Position.phi + (alpha_param*(1-r2_param)+r2_param)*(U2.*GlobalBest.Position.phi - pop(i).Position.phi) - S_phi;
                end
            end

            pop(i).Position.r = max(min(pop(i).Position.r, VarMax.r), VarMin.r);
            pop(i).Position.psi = max(min(pop(i).Position.psi, VarMax.psi), VarMin.psi);
            pop(i).Position.phi = max(min(pop(i).Position.phi, VarMax.phi), VarMin.phi);

            cartPos = SphericalToCart(pop(i).Position, model);
            if any(isnan(cartPos.x)) || any(isinf(cartPos.x))
                newCost = inf;
            else
                try, newCost = CostFunction(cartPos); catch, newCost = inf; end
            end

            if pop(i).Cost < newCost
                pop(i).Position = prev_positions{i};
            else
                prev_positions{i} = pop(i).Position; pop(i).Cost = newCost;
                if pop(i).Cost < GlobalBest.Cost
                    GlobalBest.Position = pop(i).Position; GlobalBest.Cost = pop(i).Cost;
                end
            end
        end
    end
    RunInfo = BuildRunInfo(initialRng, toc(runTimer), GlobalBest, BestCost, model);
end
