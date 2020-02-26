function test_differential_evolution()


% problem definition
problem.lb = [-1 -1];           % lower bound
problem.ub = [ 1  1];           % upper bound
problem.solver = @solver;       % objective and constraint functions
problem.popSize = 20;           % population size (optional, default: min(D*10, 100), where D is the NO. of design variables)
problem.maxFuncCount = 1e6;     % maximal function evaluations (optional, default: infinity)


% run DE
[best, result] = differential_evolution(problem);


% results
best.best_point
best.best_fitness
best.best_constraint

result.elapsed_time
result.funccount
result.msg


    function response = solver(x)
        
        x1 = x(:,1);
        x2 = x(:,2);
        
        % objective
        f = x1.^2 + x2.^2 - 1;
        
        % constraints
        g1 = x1 + x2 - 1;
        g2 = -1 - (x1 + x2);
        
        response = [f g1 g2];
    end


end