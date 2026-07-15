function metrics = InitRunMetrics()
%INITRUNMETRICS Counters that do not consume random numbers or alter search.
metrics.explorationCount = 0;
metrics.exploitationCount = 0;
metrics.retreatTriggers = 0;
metrics.retreatEvaluations = 0;
metrics.retreatAccepted = 0;
metrics.retreatBestImprovements = 0;
end
