%
%    PFOpt
%    Copyright (C) 2019  Haoyang Liu (liuhaoyang@pku.edu.cn)
%                        Zaiwen Wen  (wenzw@pku.edu.cn)
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

%% test_random.m
% This is the example of PFPG on the nearest correlation matrix problem
% (NCE). G is randomly generated by Example 5.3
%
% File obj_comat_v2.m illustrates how to insert the polynomial-filtered
% algorithm into the gradient evaluations.
%
% Usage:
%   >> test_random
%
% See also:
%   obj_comat_v2.m
%   obj_comat_exact.m
%%
clear;
rng(2333);

do_GBB = 1;
do_inexact = 1;
do_newton = 1;

if ~exist('CorrelationMatrix.m', 'file')
    warning('CorrelationMatrix.m not found. Skipping Newton solvers.');
    do_newton = 0;
end

ns = [500 1000 1500 2000];
nsize = numel(ns);

opts = struct;

opts1 = struct;
opts1.maxit = 1000;
opts1.tau = 5e-2;
opts1.taumax = 30;
opts1.record = 1;
opts1.debug = 0;
opts1.extrap = 1;
opts1.grow = 'none';
opts1.gtol = 8e-8;
opts1.ftol = 1e-15;
opts1.exact_cnt = 3;

opts2 = struct;
opts2.record = 1;
taus = [30 30 30 30];

results_grad = zeros(nsize, 4);
results_pf = zeros(nsize, 4);
results_newton = zeros(nsize, 4);

for ni = 1:nsize
    % generate random matrices
    n = ns(ni);
    G = triu(rand(n));
    G = (G + G') * 2;
    G(1:n+1:n*n) = 1;

    % opts.record = 1;
    y0 = ones(n, 1) - diag(G);
    opts1.taumax = taus(ni);
    
    % compute initial nrmG0
    [~, g0] = obj_comat_exact(y0, G);
    nrmG0 = norm(g0);

    % traditional gradient method
    if do_GBB
        tic;
        [y1, ~, out1] = fminGBB(y0, @obj_comat_exact, opts1, G);
        t1 = toc;
        
        [f1, g1] = obj_comat_exact(y1, G);
        results_grad(ni, :) = [out1.itr, f1, norm(g1) / nrmG0, t1];
    end

    % PFPG method
    if do_inexact
        tic;
        [y2, ~, out2] = fminGBB(y0, @obj_comat_v2, opts1, G);
        t2 = toc;
        
        [f2, g2] = obj_comat_exact(y2, G);
        results_pf(ni, :) = [out2.itr, f2, norm(g2) / nrmG0, t2];
    end

    % Newton method
    if do_newton
        tic;
        [X, y5, out5] = CorrelationMatrix(G, ones(n, 1), 1e-6, 1e-7);
        t5 = toc;
        
        [f5, g5] = obj_comat_exact(y5, G);
        results_newton(ni, :) = [out5.k, f5, norm(g5) / nrmG0, t5];
    end

end

%% print the result table
print_header('Gradient')
print_result(ns, results_grad);
print_header('PFPG');
print_result(ns, results_pf);
print_header('Newton');
print_result(ns, results_newton);

%% plot the elapsed time
TTable = [results_grad(:, 4), results_pf(:, 4), results_newton(:, 4)];
bar(ns, TTable);
xlabel('$n$');
ylabel('time(sec)');
legend('Grad', 'PFPG', 'Newton', 'Location', 'NorthWest');


%% auxiliary functions
function print_result(ns, result)
    fprintf('  n   |  iter      fval      ||g||      time\n');
    fprintf('-----------------------------------------------\n');
    for i = 1:numel(ns)
        fprintf('%5d | %5d   %8.3e  %8.1e  %6.1f \n', ns(i), result(i,:));
    end
end

function print_header(header)
    fprintf('\n**********************************\n');
    fprintf('* Results of %s\n', header);
    fprintf('**********************************\n');
end
