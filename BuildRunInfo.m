function info = BuildRunInfo(initialRng, elapsed, best, convergence, model)
global SPHERE_ICPO_EVAL_COUNT
info.seed = initialRng.Seed;
info.rngType = initialRng.Type;
info.elapsed = elapsed;
info.functionEvaluations = SPHERE_ICPO_EVAL_COUNT;
info.bestCost = best.Cost;
info.bestPosition = best.Position;
info.bestCartesian = SphericalToCart(best.Position, model);
info.convergence = convergence;
end
