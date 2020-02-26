function PD = calPopulationDiversity( pop, bound )

n = size(pop, 1);
dim = size(pop, 2);

lb = bound(:,1)';
lb = repmat(lb, n, 1);

width = bound(:,2) - bound(:,1);
width = repmat(width', n, 1);

pop = pop - lb;
pop = pop ./ width;

distance = zeros(n,n);
for i=1:n
    for j=1:n
        d = pop(i,:) - pop(j,:);
        distance(i,j) = norm(d) / (dim ^ 0.5);
    end
end
total_distance = sum(sum(distance,1));
PD = total_distance / (n*n);
end