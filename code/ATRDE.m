function [best, history2, diversity_row] = ATRDE(problem)

pop = [];
fitness = [];
constraint = [];
x_dim = problem.x_dim;
popSize = problem.popSize;

Tabu.l = 0;
Tabu.data = zeros(problem.maxEvaluation, problem.x_dim + 1);

best.best_point = NaN;
best.best_fitness = NaN;
best.best_constraint = NaN;
best.local_label = NaN;
best.funccount = 0;
history.l = 0;
history.data = zeros(problem.maxEvaluation, 2);

diversity = [];

globalSearch();
saveDiversity();

iter = 1;
while continueRun(problem, best)
    
    if continueRun(problem, best)
        startPointFiltration();
    end
    
    if continueRun(problem, best)
        diversityEnhancementStrategy();
    end
    
    if continueRun(problem, best)
        globalSearch();
        saveDiversity();
    end
    iter = iter + 1;
end

saveDiversity();
diversity_row = interp1(diversity(:,1),diversity(:,2), problem.popSize : problem.maxEvaluation, 'linear');
diversity_row = [NaN*ones(1,problem.popSize-1) diversity_row];

history2 = zeros(problem.db.l, 1);
best_fitness = NaN;
for idx = 1:problem.db.l
    if isFeasible(problem.db.y(idx, 2:end))
        if isnan(best_fitness) || best_fitness > problem.db.y(idx,1)
            best_fitness = problem.db.y(idx,1);
        end
    end
    history2(idx) = best_fitness;
end
if size(history2,1) < problem.maxEvaluation
    history2(size(history2,1)+1:problem.maxEvaluation) = history2(end);
else
    history2(problem.maxEvaluation+1:end,:) = [];
end

sound(sin(2*pi*25*(1:1000)/800));

    function saveDiversity()
        if ~isempty(diversity) && diversity(end, 1) > problem.db.l
            return;
        end
        if ~isempty(diversity) && diversity(end, 1) == problem.db.l
            diversity(end,:) = [problem.db.l cal_diversity(pop, problem.bound)];
            return;
        end
        
        diversity = [diversity; problem.db.l calPopulationDiversity(pop, problem.bound)];
    end

%% standard DE functions
    function globalSearch()
        if isempty(pop)
            % initialization
            pop = LHD( problem.bound, popSize );
            [fitness, constraint] = obj_con_proxy(pop);
        else
            % obtain the next population
            newpop = move(pop, problem.bound);
            [newfitness, newContraint] = obj_con_proxy(newpop);
            [pop, fitness, constraint] = selection(pop, newpop, fitness, newfitness, constraint, newContraint);
        end
        
        % archive
        step_data.local_label = 0;
        step_data.description = 'DE';
        opt = BestIndividual(pop, fitness, constraint);
        archive(opt, step_data);
    end

    function U = move(X, bound)
        F = 0.8; Cr = 0.4;
        V = X;
        for ii = 1:popSize
            squence = 1:popSize;
            squence(ii) = [];
            r = randperm(popSize-1,3);
            r1 = squence(r(1));
            r2 = squence(r(2));
            r3 = squence(r(3));
            V(ii, :) = X(r1,:) + F * (X(r2,:) - X(r3,:));
        end
        indexCross = logical(rand(popSize, x_dim) <= Cr | repmat(1 : x_dim, popSize, 1) == repmat(randi(x_dim, [popSize, 1]), 1, x_dim));
        U = V .* indexCross + X .* (1 - indexCross);
        U = box(U, bound);
        
        function pop = box(pop, bound)
            for popIndex = 1 : popSize
                for dimIndex = 1:x_dim
                    if pop(popIndex,dimIndex) < bound(dimIndex, 1)
                        pop(popIndex,dimIndex) = bound(dimIndex, 1);
                    end
                    if pop(popIndex,dimIndex) > bound(dimIndex, 2)
                        pop(popIndex,dimIndex) = bound(dimIndex, 2);
                    end
                end
            end
        end
    end

    function [pop, fitness, constraint] = selection(pop, newpop, fitness, newfitness, constraint, newContraint)
        for i = 1:popSize
            if isempty(constraint)
                is_moveon = comparePoints(fitness(i), [], newfitness(i), []);
            else
                is_moveon = comparePoints(fitness(i), constraint(i,:), newfitness(i), newContraint(i,:));
            end
            if is_moveon == 1
                pop(i,:) = newpop(i,:);
                fitness(i) = newfitness(i);
                if ~isempty(constraint)
                    constraint(i,:) = newContraint(i,:);
                end
            end
        end
    end

%% functions to improve the offspring quality

    function startPointFiltration()
        opt = BestIndividual(pop, fitness, constraint);
        for id = 1 : size(pop,1)
            start_point = pop(id,:);
            if inTabuRegion(start_point) && id ~= opt.id
                continue;
            end
            
            improved_point = trustRegionSearch(start_point);
            
            pop(id,:) = improved_point.x;
            fitness(id,:) = improved_point.obj;
            constraint(id,:) = improved_point.con;
            
            info.local_label = 1;
            info.description = 'LS';
            archive(improved_point, info);
            
            if continueRun(problem, best) ~= 1
                break;
            end
        end
    end

%% subfunctions for local search

    function improved_point = trustRegionSearch(start_point, k)
        TR_result = trust_region( problem, start_point, k );
        problem = problem.update();
        improved_point = TR_result.optimum;
        
        nt = size(TR_result.tabu,1);
        Tabu.data(Tabu.l+1:Tabu.l+nt, :) = TR_result.tabu;
        Tabu.l = Tabu.l + nt;
    end

%% database management

    function [ fitness, constraint] = obj_con_proxy(pop)
        response = problem.solver(pop);
        fitness = response(:,1);
        constraint = response(:,2:end);
        problem = problem.update();
    end

    function archive(point, step_data)
        if isFeasible(point.con)
            if isnan(best.best_fitness) || point.obj < best.best_fitness
                best.best_point = point.x;
                best.best_fitness = point.obj;
                best.best_constraint = point.con;
            end
        end
        best.local_label = step_data.local_label;
        best.funccount = problem.db.l;
        
        history.data(history.l+1, :) = [best.funccount best.best_fitness];
        history.l = history.l+1;
        
        switch best.local_label
            case 0
                color = 'text';
            case 1
                color = 'blue';
            case 2
                color = 'red'; % Cyan Magenta
        end
        cprintf(color, '%s,funcount=%d,y_best=%e,delta=%e\n', step_data.description, problem.db.l, best.best_fitness, abs(best.best_fitness - problem.optimum));
    end

    function is_feasible = isFeasible(constraint)
        constraint_num = size(constraint,2);
        if constraint_num == 0 || sum(constraint <= 0) == constraint_num
            is_feasible = 1;
        else
            is_feasible = 0;
        end
    end

    function opt = BestIndividual(pop, fitness, constraint)
        best_id = 1;
        for i = 2 : size(fitness,1)
            is_moveon = comparePoints(fitness(best_id), constraint(best_id,:), fitness(i), constraint(i,:));
            if is_moveon == 1
                best_id = i;
            end
        end
        opt.id = best_id;
        opt.x   = pop(best_id,:);
        opt.obj = fitness(best_id,:);
        opt.con = constraint(best_id,:);
    end

    function is_in = inTabuRegion(point)
        for ii = 1 : Tabu.l
            d = norm(point - Tabu.data(ii,1:problem.x_dim), inf);
            if d < Tabu.data(ii,end)
                is_in = 1;
                return;
            end
        end
        is_in = 0;
    end

    function sp = sparsestPoint(bound)
        current_points = problem.db.x(1:problem.db.l,:);
        ntrial = 1e4;
        trialP = LHD(bound, ntrial);
        max_dist = NaN;
        id = 1;
        for point_id = 1:ntrial
            if inTabuRegion(trialP(point_id,:))
                continue;
            end
            [~,dd] = knnsearch(current_points, trialP(point_id,:), 'k', 1);
            if isnan(max_dist) || max_dist < dd
                max_dist = dd;
                id = point_id;
            end
        end
        sp = trialP(id, :);
    end

    function diversityEnhancementStrategy()
        n_tabu_individuals = 0;
        for id = 1 : popSize
            if ~inTabuRegion(pop(id,:))
                continue;
            end
            n_tabu_individuals = n_tabu_individuals + 1;
            
            pop_bound = calBound(pop, problem.bound);
            pnew = sparsestPoint(pop_bound);
            [fnew, cnew] = obj_con_proxy(pnew);
            
            pop(id,:) = pnew;
            fitness(id,:) = fnew;
            constraint(id,:) = cnew;
        end
        
        cprintf('red', ['\n\nResult of the diversity enhancement strategy:' ...
            '\n    tabu individuals: %d\n'], n_tabu_individuals);
    end

end