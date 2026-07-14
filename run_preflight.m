function outputs = run_preflight()
%RUN_PREFLIGHT Execute the required smoke and stability profiles.
outputs.smoke = run_experiment_suite('smoke');
outputs.precheck = run_experiment_suite('precheck');
end
