function [ x ] = latin_hypercube_design( bound, n )
% Latin Hypercube Sampling for generate the initial population
%   bound       multi-row two-column matrix
%   n           the number of samples

dim = size(bound, 1); % dimension
x = lhsdesign(n, dim, 'criterion','maximin');
for i = 1 : dim
    down = bound(i, 1);
    up = bound(i, 2);
    x(:, i) = x(:, i) .* (up - down) + down;
end
end