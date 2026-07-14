function [position,cost] = CreateFiniteRandomSolution(VarSize,VarMin,VarMax,model,maxAttempts)
%CREATEFINITERANDOMSOLUTION Sample until a valid finite-cost path is found.
if nargin < 5, maxAttempts = 100000; end
cost = inf; position = [];
for attempt=1:maxAttempts
    candidate = CreateRandomSolution(VarSize,VarMin,VarMax);
    cart = SphericalToCart(candidate,model);
    if any(~isfinite(cart.x)) || any(~isfinite(cart.y)) || any(~isfinite(cart.z)), continue; end
    try, candidateCost=MyCost(cart,model); catch, candidateCost=inf; end
    if isfinite(candidateCost), position=candidate; cost=candidateCost; return; end
end
error('CreateFiniteRandomSolution:NoFeasibleSample', ...
    'No finite path found after %d attempts.',maxAttempts);
end
