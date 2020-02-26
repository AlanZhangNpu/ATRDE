function is_continue = continueRun(problem, best)
    if problem.db.l >= problem.maxEvaluation || ...
            (~isnan(best.best_fitness) ...
            && abs(best.best_fitness - problem.optimum) < 1e-4 ...
            && problem.db.l >= problem.minEvaluation)
        is_continue = 0;
    else
        is_continue = 1;
    end
end