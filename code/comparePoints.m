function moveon = comparePoints(fitness1, contraint1, fitness2, contraint2)
% superior == 0: the first point is better
% superior == 1: the second point is better

v1 = calV(contraint1);
v2 = calV(contraint2);

if v1 == 0 && v2 == 0
    moveon = compareFitness(fitness1, fitness2);
    return;
end
moveon = compareFitness(v1, v2);
return;


    function v = calV(contraint)
        contraint(1,contraint<=0) = 0;
        v = sum(contraint);
    end

    function moveon = compareFitness(f1, f2)
        if f1 > f2
            moveon = 1;
        else
            moveon = 0;
        end        
    end

end