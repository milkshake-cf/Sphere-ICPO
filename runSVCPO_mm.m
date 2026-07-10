% SVCPO: Spherical Vector Crested Porcupine Optimizer
% 4 innovations on top of CPO:
%   1. Spherical vector encoding (inherited from SPSO framework)
%   2. pBest personal memory
%   3. Adaptive exploration ratio a(t) → smooth explore→exploit transition
%   4. Cauchy-Gaussian stagnation mutation
%
function [GlobalBest, BestCost] = runSVCPO_mm(model, nPop, MaxIt)

    %% Problem Definition
    CostFunction = @(x) MyCost(x, model);
    nVar = model.n;
    VarSize = [1 nVar];

    % Lower and upper Bounds (spherical vector)
    VarMin.x = model.xmin;  VarMax.x = model.xmax;
    VarMin.y = model.ymin;  VarMax.y = model.ymax;
    VarMin.z = model.zmin;  VarMax.z = model.zmax;
    VarMax.r = 2 * norm(model.start - model.end) / nVar;
    VarMin.r = 0;
    AngleRange = pi/4;
    VarMin.psi = -AngleRange;  VarMax.psi = AngleRange;
    dirVector = model.end - model.start;
    phi0 = atan2(dirVector(2), dirVector(1));
    VarMin.phi = phi0 - AngleRange;  VarMax.phi = phi0 + AngleRange;

    %% SVCPO Parameters
    alpha_param = 0.2;      % CPO convergence rate (4th defense)
    Tf = 0.8;               % 3rd vs 4th defense threshold
    eta = 0.5;              % pBest learning factor (INNOVATION 2)
    K_stag = 5;             % Stagnation detection threshold (INNOVATION 4)
    gamma_cauchy = 0.01;    % Cauchy scale for mutation
    sigma_gauss = 0.1;      % Gaussian std for mutation

    %% Initialization
    empty_agent.Position = [];
    empty_agent.Cost = [];
    empty_agent.pBest = [];     % INNOVATION 2: personal best
    empty_agent.pBestCost = [];

    GlobalBest.Cost = inf;
    GlobalBest.Position = [];
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
                try
                    pop(i).Cost = CostFunction(cartPos);
                catch
                    pop(i).Cost = inf;
                end
            end
            prev_positions{i} = pop(i).Position;
            % INNOVATION 2: initialize pBest
            pop(i).pBest = pop(i).Position;
            pop(i).pBestCost = pop(i).Cost;

            if pop(i).Cost < GlobalBest.Cost
                GlobalBest.Position = pop(i).Position;
                GlobalBest.Cost = pop(i).Cost;
                isInit = true;
            end
        end
    end

    BestCost = zeros(MaxIt, 1);
    stagnation_counter = 0;  % INNOVATION 4

    %% SVCPO Main Loop
    for t = 1:MaxIt
        BestCost(t) = GlobalBest.Cost;

        % INNOVATION 3: Adaptive exploration ratio a(t)
        a_adapt = 2 * (0.7 * (1 - t/MaxIt)^0.5 + 0.3);
        expl_ratio = a_adapt / 2;  % normalized to [0.3, 1.0]

        for i = 1:nPop
            U1 = rand(VarSize) > rand();

            %% Exploration vs Exploitation (using adaptive ratio)
            if rand() < expl_ratio  % EXPLORATION phase
                if rand() < rand()  % Strategy 1: Visual/Sight
                    k = randi(nPop);
                    % r component
                    y_r = (pop(i).Position.r + pop(k).Position.r) / 2;
                    pop(i).Position.r = pop(i).Position.r + randn(VarSize) .* ...
                        abs(2*rand()*GlobalBest.Position.r - y_r);
                    % psi
                    y_psi = (pop(i).Position.psi + pop(k).Position.psi) / 2;
                    pop(i).Position.psi = pop(i).Position.psi + randn(VarSize) .* ...
                        abs(2*rand()*GlobalBest.Position.psi - y_psi);
                    % phi
                    y_phi = (pop(i).Position.phi + pop(k).Position.phi) / 2;
                    pop(i).Position.phi = pop(i).Position.phi + randn(VarSize) .* ...
                        abs(2*rand()*GlobalBest.Position.phi - y_phi);
                else  % Strategy 2: Sound
                    k = randi(nPop); m = randi(nPop);
                    y_r = (pop(i).Position.r + pop(k).Position.r) / 2;
                    pop(i).Position.r = U1.*pop(i).Position.r + (1-U1).* ...
                        (y_r + rand()*(pop(m).Position.r - pop(k).Position.r));
                    y_psi = (pop(i).Position.psi + pop(k).Position.psi) / 2;
                    pop(i).Position.psi = U1.*pop(i).Position.psi + (1-U1).* ...
                        (y_psi + rand()*(pop(m).Position.psi - pop(k).Position.psi));
                    y_phi = (pop(i).Position.phi + pop(k).Position.phi) / 2;
                    pop(i).Position.phi = U1.*pop(i).Position.phi + (1-U1).* ...
                        (y_phi + rand()*(pop(m).Position.phi - pop(k).Position.phi));
                end
            else  % EXPLOITATION phase
                Yt = 2 * rand() * (1 - t/MaxIt)^(t/MaxIt);
                U2 = (rand(VarSize) < 0.5) * 2 - 1;
                S_base = rand() * U2;
                allCosts = [pop.Cost];
                sumFitness = sum(allCosts) + eps;

                if rand() < Tf  % Strategy 3: Odor
                    St = exp(pop(i).Cost / sumFitness);
                    S = S_base .* Yt .* St;
                    k = randi(nPop); m = randi(nPop);
                    pop(i).Position.r = (1-U1).*pop(i).Position.r + U1.*(pop(k).Position.r + St*(pop(m).Position.r - pop(k).Position.r) - S);
                    pop(i).Position.psi = (1-U1).*pop(i).Position.psi + U1.*(pop(k).Position.psi + St*(pop(m).Position.psi - pop(k).Position.psi) - S);
                    pop(i).Position.phi = (1-U1).*pop(i).Position.phi + U1.*(pop(k).Position.phi + St*(pop(m).Position.phi - pop(k).Position.phi) - S);
                else  % Strategy 4: Physical Attack (with pBest!)
                    Mt = exp(pop(i).Cost / sumFitness);
                    k = randi(nPop);
                    vt = pop(i).Position;
                    Vtp = pop(k).Position;
                    r2_param = rand();

                    Ft_r = rand(VarSize) .* (Mt * (-vt.r + Vtp.r));
                    S_r = S_base .* Yt .* Ft_r;
                    % INNOVATION 2: add pBest guidance
                    pop(i).Position.r = GlobalBest.Position.r + ...
                        (alpha_param*(1-r2_param)+r2_param)*(U2.*GlobalBest.Position.r - pop(i).Position.r) ...
                        + eta * rand() * (pop(i).pBest.r - pop(i).Position.r) - S_r;

                    Ft_psi = rand(VarSize) .* (Mt * (-vt.psi + Vtp.psi));
                    S_psi = S_base .* Yt .* Ft_psi;
                    pop(i).Position.psi = GlobalBest.Position.psi + ...
                        (alpha_param*(1-r2_param)+r2_param)*(U2.*GlobalBest.Position.psi - pop(i).Position.psi) ...
                        + eta * rand() * (pop(i).pBest.psi - pop(i).Position.psi) - S_psi;

                    Ft_phi = rand(VarSize) .* (Mt * (-vt.phi + Vtp.phi));
                    S_phi = S_base .* Yt .* Ft_phi;
                    pop(i).Position.phi = GlobalBest.Position.phi + ...
                        (alpha_param*(1-r2_param)+r2_param)*(U2.*GlobalBest.Position.phi - pop(i).Position.phi) ...
                        + eta * rand() * (pop(i).pBest.phi - pop(i).Position.phi) - S_phi;
                end
            end

            %% Enforce Bounds
            pop(i).Position.r = max(min(pop(i).Position.r, VarMax.r), VarMin.r);
            pop(i).Position.psi = max(min(pop(i).Position.psi, VarMax.psi), VarMin.psi);
            pop(i).Position.phi = max(min(pop(i).Position.phi, VarMax.phi), VarMin.phi);

            %% Evaluation
            cartPos = SphericalToCart(pop(i).Position, model);
            if any(isnan(cartPos.x)) || any(isnan(cartPos.y)) || any(isnan(cartPos.z)) || ...
               any(isinf(cartPos.x)) || any(isinf(cartPos.y)) || any(isinf(cartPos.z))
                newCost = inf;
            else
                try
                    newCost = CostFunction(cartPos);
                catch
                    newCost = inf;
                end
            end

            %% Greedy Selection + pBest Update
            if pop(i).Cost <= newCost
                pop(i).Position = prev_positions{i};
            else
                prev_positions{i} = pop(i).Position;
                pop(i).Cost = newCost;
                % INNOVATION 2: update pBest
                if newCost < pop(i).pBestCost
                    pop(i).pBest = pop(i).Position;
                    pop(i).pBestCost = newCost;
                end
                if pop(i).Cost < GlobalBest.Cost
                    GlobalBest.Position = pop(i).Position;
                    GlobalBest.Cost = pop(i).Cost;
                end
            end
        end

        %% INNOVATION 4: Cauchy-Gaussian stagnation mutation
        if t > 1 && BestCost(t) >= BestCost(t-1)
            stagnation_counter = stagnation_counter + 1;
        else
            stagnation_counter = 0;
        end

        if stagnation_counter >= K_stag
            for i = 1:nPop
                if rand < 0.5  % Cauchy big jump
                    pop(i).Position.r = pop(i).Position.r + ...
                        gamma_cauchy * tan(pi*(rand()-0.5)) * (GlobalBest.Position.r - pop(i).Position.r);
                    pop(i).Position.psi = pop(i).Position.psi + ...
                        gamma_cauchy * tan(pi*(rand()-0.5)) * (GlobalBest.Position.psi - pop(i).Position.psi);
                    pop(i).Position.phi = pop(i).Position.phi + ...
                        gamma_cauchy * tan(pi*(rand()-0.5)) * (GlobalBest.Position.phi - pop(i).Position.phi);
                else  % Gaussian small perturbation
                    pop(i).Position.r = pop(i).Position.r + ...
                        sigma_gauss * randn(VarSize) .* (GlobalBest.Position.r - pop(i).Position.r);
                    pop(i).Position.psi = pop(i).Position.psi + ...
                        sigma_gauss * randn(VarSize) .* (GlobalBest.Position.psi - pop(i).Position.psi);
                    pop(i).Position.phi = pop(i).Position.phi + ...
                        sigma_gauss * randn(VarSize) .* (GlobalBest.Position.phi - pop(i).Position.phi);
                end
            end
            % Re-clip and re-evaluate after mutation
            for i = 1:nPop
                pop(i).Position.r = max(min(pop(i).Position.r, VarMax.r), VarMin.r);
                pop(i).Position.psi = max(min(pop(i).Position.psi, VarMax.psi), VarMin.psi);
                pop(i).Position.phi = max(min(pop(i).Position.phi, VarMax.phi), VarMin.phi);
                cartPos = SphericalToCart(pop(i).Position, model);
                if ~any(isnan(cartPos.x)) && ~any(isinf(cartPos.x))
                    try
                        newCost = CostFunction(cartPos);
                        if newCost < pop(i).Cost
                            pop(i).Cost = newCost;
                            prev_positions{i} = pop(i).Position;
                            if newCost < pop(i).pBestCost
                                pop(i).pBest = pop(i).Position; pop(i).pBestCost = newCost;
                            end
                            if newCost < GlobalBest.Cost
                                GlobalBest.Position = pop(i).Position; GlobalBest.Cost = newCost;
                            end
                        end
                    catch
                    end
                end
            end
            stagnation_counter = 0;
        end

        if mod(t, 50) == 0
            fprintf('  Iter %d: BestCost = %.2f\n', t, BestCost(t));
        end
    end
end
