function return_value = improvedTRS( problem, start_x, patience )
% problem must contain the following members:
%     solver
%     bound
%     x_dim
%     con_dim
%     db
%     popSize

max_iteration = 100;
if patience > 10
    patience = 10;
end

Tabu.l = 0;
Tabu.data = zeros(max_iteration, problem.x_dim + 1);

TR.center = callRealModel(start_x);
TR.radius = NaN;
TR.next = [];

LRBFN_obj = [];
LRBFN_con = [];

 % the number of points used to construct the LRBFN
m = max(round((problem.x_dim+1)*(problem.x_dim+2)/2), 100);

iter = 0;
successful_move = 0;
failed_move = 0;

show_information = 0;
    
stall = 0;
is_continue = 1;
is_samepoint = 0;
if iter >= max_iteration || stall >= patience
    is_continue = 0;
end
while is_continue && ~is_samepoint
    moveOn();
    updateTrustRegion();
    
    iter = iter + 1;
    if iter >= max_iteration || stall >= patience
        is_continue = 0;
    end
end
return_value.tabu = Tabu.data(1:Tabu.l,:);
return_value.optimum.x = TR.center.x;
return_value.optimum.obj = TR.center.obj;
return_value.optimum.con = TR.center.con;

tip = ['\n\nResult of the improved trust region search:' ...
    '\n    iteration: ' num2str(iter) ...
    '\n    successful move:' num2str(successful_move) ...
    '\n    failed move:' num2str(failed_move) ...
    '\n    tabu regions:' num2str(Tabu.l)];

is_feasible = isFeasible(TR.center.con);
if is_feasible
    tip = [tip '\n    best obj:' num2str(TR.center.obj) '\n\n'];
else
    tip = [tip '\n    best obj: infeasible\n\n'];
end
cprintf('red', tip);



%% subfunctions
    function moveOn()
        % construct local surrogates
        [idx,~] = knnsearch(problem.db.x(1:problem.db.l,:), TR.center.x, 'k', m+1);
        train_x   = problem.db.x(idx,:);
        train_obj = problem.db.y(idx,1);
        train_con = problem.db.y(idx,2:end);
        
        LRBFN_obj = RBFNetwork(train_x, train_obj);
        LRBFN_con = RBFNetwork(train_x, train_con);
        
        TR.center.predicted_obj = LRBFN_obj(TR.center.x);
        TR.center.predicted_con = LRBFN_con(TR.center.x);
                
        % optimize the local surrogates
        if isnan(TR.radius)
            % the initial trust region radius
            lb = (min([TR.center.x; train_x], [], 1))';
            ub = (max([TR.center.x; train_x], [], 1))';
            lenBound = (ub - lb) ./ 2;
            TR.radius = max(lenBound ./ (problem.bound(:,2) - problem.bound(:,1)));
            if TR.radius > 0.2
                TR.radius = 0.2;
            end
        end
        [lb, ub] = calLocalBound(TR.center.x, TR.radius, problem.bound);
        options = optimset('Algorithm', 'interior-point', 'MaxFunEvals', 15000, 'Display', 'off');
        [optimal_x, ~,~,~] = fmincon(@cal_obj_inner, TR.center.x,[],[],[],[],lb,ub, @cal_con_inner, options);
        [~,r] = knnsearch(problem.db.x(1:problem.db.l,:), optimal_x, 'k', 1);
        if r < 10^-7
            is_samepoint = -1;
        end
        
        % call the real model
        TR.next = callRealModel(optimal_x);
        TR.next.predicted_obj = LRBFN_obj(optimal_x);
        TR.next.predicted_con = LRBFN_con(optimal_x);
                
        function obj = cal_obj_inner(x)
            obj = LRBFN_obj(x);
        end
        function [con, d]  = cal_con_inner(x)
            con = LRBFN_con(x);
            d = [];
        end
    end

    function updateTrustRegion()
        scale = 1;
        min_merit = calMinMerit();
        if min_merit < 0.25
            scale = 0.25;
        elseif min_merit > 0.75
            scale = 2;
        end
        TR.radius = TR.radius * scale;
        if TR.radius > 0.2
            TR.radius = 0.2;
        end
        
        if min_merit >= 0.75 && min_merit <= 1.25
            radius = norm(TR.center.x - TR.next.x, inf);
            if radius ~= 0
                if show_information
                    cprintf('black', ['create tabu region, radius=' num2str(radius) '\n']);
                end
                Tabu.data(Tabu.l + 1, :) = [TR.center.x radius];
                Tabu.l = Tabu.l + 1;
            end
        end

        if comparePoints(TR.center.obj, TR.center.con, TR.next.obj, TR.next.con) == 1
            if show_information
                cprintf('blue', ['Successful move, obj=' num2str(TR.next.obj) '\n']);
            end
            successful_move = successful_move + 1;
            
            TR.center = TR.next;
            if isFeasible(TR.center.con)
                stall = 0;
            else
                stall = stall + 1;
            end
        else
            failed_move = failed_move + 1;            
            if show_information
                cprintf('red', 'failed move\n');
            end
            
            stall = stall + 1;
        end
        
        function min_merit = calMinMerit()
            obj_merit = calMerit(TR.center.obj, TR.center.predicted_obj, TR.next.obj, TR.next.predicted_obj);
            con_merit = zeros(1, problem.con_dim);
            for con_id = 1 : problem.con_dim
                con_merit(1, con_id) = calMerit(TR.center.con(1, con_id), TR.center.predicted_con(1, con_id), TR.next.con(1, con_id), TR.next.predicted_con(1, con_id));
            end
            min_merit = min([con_merit obj_merit]); % median
            
            function m = calMerit(real_y, predicted_y, real_y_next, predicted_y_next)
                real_reduction = real_y - real_y_next;
                predicted_reduction = predicted_y - predicted_y_next;
                
                if abs(real_reduction - predicted_reduction) < 10^-9
                    m = 1;
                else
                    if predicted_reduction == 0
                        m = real_reduction;
                    else
                        m = real_reduction / predicted_reduction;
                    end
                end
            end
        end
    end

%% data processing functions
    function point = callRealModel(x)
        response = problem.solver(x);
        point.x = x;
        point.obj = response(:,1);
        point.con = response(:,2:end);

        problem = problem.update();
    end

    function is_feasible = isFeasible(constraint)
        constraint_num = size(constraint,2);
        if constraint_num == 0 || sum(constraint <= 0) == constraint_num
            is_feasible = 1;
        else
            is_feasible = 0;
        end
    end

    function [lb, ub] = calLocalBound(center, factor, bound)
        lb = zeros(size(center,2),1);
        ub = zeros(size(center,2),1);
        for i=1:size(center,2)
            range = bound(i,2) - bound(i,1);
            a = center(1,i) - factor*range;
            b = center(1,i) + factor*range;
            lb(i) = max(a, bound(i,1));
            ub(i) = min(b, bound(i,2));
            
            if center(1,i) < lb(i) || center(1,i) > ub(i)
                warning('³ö´í');
            end
            
        end
    end

end

