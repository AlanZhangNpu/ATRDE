function [ func ] = RBFNetwork( trainx, trainy )

rbf = newrb(trainx',trainy');
func = @predict;

    function y = predict(x)
        y = rbf(x')';
    end

end

