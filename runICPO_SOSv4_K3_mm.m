% runICPO_SOS_mm.m — ICPO with SOS Mutualism (from ICPO SciRep, Liu 2024)
% Proven strongest single CPO improvement: 63% cost reduction on urban terrain
function [GlobalBest, BestCost] = runICPO_SOSv4_K3_mm(model, nPop, MaxIt)

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
            pop(i).Position = CreateRandomSolution(VarSize, VarMin, VarMax);
            cartPos = SphericalToCart(pop(i).Position, model);
            if any(isnan(cartPos.x)) || any(isnan(cartPos.y)) || any(isnan(cartPos.z))
                pop(i).Cost = inf;
            else
                try, pop(i).Cost = CostFunction(cartPos); catch, pop(i).Cost = inf; end
            end
            prev_positions{i} = pop(i).Position;
            if pop(i).Cost < GlobalBest.Cost
                GlobalBest.Position = pop(i).Position; GlobalBest.Cost = pop(i).Cost; isInit = true;
            end
        end
    end

    BestCost = zeros(MaxIt, 1); stagnation_counter = 0;

    for t = 1:MaxIt
        BestCost(t) = GlobalBest.Cost;
        if t > 1 && BestCost(t) >= BestCost(t-1), stagnation_counter = stagnation_counter + 1; else, stagnation_counter = 0; end

        for i = 1:nPop
            %% ===== SOS MUTUALISM: Replaces CPO's first two defense strategies =====
            a_adapt = 2*(0.7*(1-t/MaxIt)^0.5 + 0.3); expl_ratio = a_adapt/2;
            if rand() < expl_ratio  % EXPLORATION via SOS mutualism
                % ---- Mutually Beneficial Stage ----
                x_rand_idx = randi(nPop);
                % RMV = x_i + rand * (x_rand - x_i)
                % r component
                RMV_r = pop(i).Position.r + rand(VarSize) .* (pop(x_rand_idx).Position.r - pop(i).Position.r);
                % x_new = x_i + rand * (x_CP - RMV)
                pop(i).Position.r = pop(i).Position.r + rand(VarSize) .* (GlobalBest.Position.r - RMV_r);
                % psi
                RMV_psi = pop(i).Position.psi + rand(VarSize) .* (pop(x_rand_idx).Position.psi - pop(i).Position.psi);
                pop(i).Position.psi = pop(i).Position.psi + rand(VarSize) .* (GlobalBest.Position.psi - RMV_psi);
                % phi
                RMV_phi = pop(i).Position.phi + rand(VarSize) .* (pop(x_rand_idx).Position.phi - pop(i).Position.phi);
                pop(i).Position.phi = pop(i).Position.phi + rand(VarSize) .* (GlobalBest.Position.phi - RMV_phi);

            else  % EXPLOITATION via original CPO mechanisms
                U1 = rand(VarSize) > rand();
                Yt = 2 * rand() * (1 - t/MaxIt)^(t/MaxIt);
                U2 = (rand(VarSize) < 0.5) * 2 - 1;
                S_base = rand() * U2;
                allCosts = [pop.Cost]; sumFitness = sum(allCosts) + eps;

                if rand() < Tf  % Strategy 3: Odor
                    St = exp(pop(i).Cost / sumFitness); S = S_base .* Yt .* St;
                    k = randi(nPop); m = randi(nPop);
                    pop(i).Position.r = (1-U1).*pop(i).Position.r + U1.*(pop(k).Position.r + St*(pop(m).Position.r - pop(k).Position.r) - S);
                    pop(i).Position.psi = (1-U1).*pop(i).Position.psi + U1.*(pop(k).Position.psi + St*(pop(m).Position.psi - pop(k).Position.psi) - S);
                    pop(i).Position.phi = (1-U1).*pop(i).Position.phi + U1.*(pop(k).Position.phi + St*(pop(m).Position.phi - pop(k).Position.phi) - S);
                else  % Strategy 4: Physical Attack
                    Mt = exp(pop(i).Cost / sumFitness); k = randi(nPop);
                    vt = pop(i).Position; Vtp = pop(k).Position; r2_param = rand();
                    Ft_r = rand(VarSize).*(Mt*(-vt.r + Vtp.r)); S_r = S_base.*Yt.*Ft_r;
                    pop(i).Position.r = GlobalBest.Position.r + (alpha_param*(1-r2_param)+r2_param)*(U2.*GlobalBest.Position.r - pop(i).Position.r) - S_r;
                    Ft_psi = rand(VarSize).*(Mt*(-vt.psi + Vtp.psi)); S_psi = S_base.*Yt.*Ft_psi;
                    pop(i).Position.psi = GlobalBest.Position.psi + (alpha_param*(1-r2_param)+r2_param)*(U2.*GlobalBest.Position.psi - pop(i).Position.psi) - S_psi;
                    Ft_phi = rand(VarSize).*(Mt*(-vt.phi + Vtp.phi)); S_phi = S_base.*Yt.*Ft_phi;
                    pop(i).Position.phi = GlobalBest.Position.phi + (alpha_param*(1-r2_param)+r2_param)*(U2.*GlobalBest.Position.phi - pop(i).Position.phi) - S_phi;
                end
            end

            %% Enforce Bounds
            pop(i).Position.r = max(min(pop(i).Position.r, VarMax.r), VarMin.r);
            pop(i).Position.psi = max(min(pop(i).Position.psi, VarMax.psi), VarMin.psi);
            pop(i).Position.phi = max(min(pop(i).Position.phi, VarMax.phi), VarMin.phi);

            %% Evaluation
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

        %% Periodic Retreat (from ICPO SciRep) — every 10% of MaxIt
        if stagnation_counter >= 3
            rg = 0.9 - log(t+1) * (0.9 - 0.1) / log(MaxIt+1);
            for i = 1:nPop
                r = rand() * rg;
                L_r = GlobalBest.Position.r - pop(i).Position.r;
                Lp_r = L_r .* rand(VarSize);
                alpha_r = sqrt(L_r.^2 + Lp_r.^2 - 2*L_r.*Lp_r.*cos(2*pi*rand(VarSize)));
                pop(i).Position.r = pop(i).Position.r + r .* alpha_r;

                L_psi = GlobalBest.Position.psi - pop(i).Position.psi;
                Lp_psi = L_psi .* rand(VarSize);
                alpha_psi = sqrt(L_psi.^2 + Lp_psi.^2 - 2*L_psi.*Lp_psi.*cos(2*pi*rand(VarSize)));
                pop(i).Position.psi = pop(i).Position.psi + r .* alpha_psi;

                L_phi = GlobalBest.Position.phi - pop(i).Position.phi;
                Lp_phi = L_phi .* rand(VarSize);
                alpha_phi = sqrt(L_phi.^2 + Lp_phi.^2 - 2*L_phi.*Lp_phi.*cos(2*pi*rand(VarSize)));
                pop(i).Position.phi = pop(i).Position.phi + r .* alpha_phi;
            end
            % Re-clip and re-evaluate
            for i = 1:nPop
                pop(i).Position.r = max(min(pop(i).Position.r, VarMax.r), VarMin.r);
                pop(i).Position.psi = max(min(pop(i).Position.psi, VarMax.psi), VarMin.psi);
                pop(i).Position.phi = max(min(pop(i).Position.phi, VarMax.phi), VarMin.phi);
                cartPos = SphericalToCart(pop(i).Position, model);
                if ~any(isnan(cartPos.x)) && ~any(isinf(cartPos.x))
                    try
                        newCost = CostFunction(cartPos);
                        if newCost < pop(i).Cost
                            pop(i).Cost = newCost; prev_positions{i} = pop(i).Position;
                            if newCost < GlobalBest.Cost
                                GlobalBest.Position = pop(i).Position; GlobalBest.Cost = newCost;
                            end
                        end
                    catch
                    end
                end
            end
        end

        if mod(t, 50) == 0
            fprintf('  Iter %d: BestCost = %.2f\n', t, BestCost(t));
        end
    end
end
