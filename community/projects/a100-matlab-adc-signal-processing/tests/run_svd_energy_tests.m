function run_svd_energy_tests()
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'functions'));
addpath(fullfile(root, 'config'));
opts = default_processing_options();
clutter = opts.clutter;
clutter.svd_energy_fraction = 0;
% Exact rank-one complex input: zero energy removal must preserve it.
x = reshape((1:4).' * exp(1i*(0:7)), 4, 8, 1);
[y, info] = suppress_clutter(x, clutter);
assert(norm(y(:)-x(:)) < 1e-12);
assert(info.removed_rank == 0 && info.removed_energy_ratio == 0);
% Empty retains the legacy fixed-rank option.
clutter.svd_energy_fraction = [];
[y, info] = suppress_clutter(x, clutter);
assert(norm(y(:)) < 1e-10 && info.removed_rank == 1);
% A positive fraction still chooses enough components, respecting the cap.
x = diag([3,2,1]);
clutter.svd_energy_fraction = 0.8;
[y, info] = suppress_clutter(x, clutter);
assert(info.removed_rank == 2);
assert(norm(y-diag([0,0,1]), 'fro') < 1e-12);
clutter.svd_max_rank = 1;
[~, info] = suppress_clutter(x, clutter);
assert(info.removed_rank == 1);
clutter.svd_energy_fraction = 1;
[~, info] = suppress_clutter(zeros(4,8), clutter);
assert(info.removed_rank == 0);
invalid = {-0.1, 1.1, NaN, Inf, [0.1,0.2], 1i, '0.5'};
for k = 1:numel(invalid)
    clutter.svd_energy_fraction = invalid{k};
    rejected = false;
    try
        suppress_clutter(x, clutter);
    catch err
        rejected = strcmp(err.identifier, 'CTSAI:InvalidSvdEnergyFraction');
    end
    assert(rejected);
end
fprintf('SVD energy fraction tests passed.\n');
end
