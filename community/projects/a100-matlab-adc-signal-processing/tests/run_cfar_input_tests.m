function run_cfar_input_tests()
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'functions'));
addpath(fullfile(root,'config'));
opts = default_processing_options();
invalid = {-0.1, 0, 1, 2, NaN, Inf, 1i, [0.1,0.2], '0.1'};
for k = 1:numel(invalid)
    pfa = invalid{k};
    assert_rejected(@() os_cfar_alpha(32,24,pfa), 'CTSAI:InvalidCfarPfa');
    assert_rejected(@() cfar_alpha_ca(32,pfa), 'CTSAI:InvalidCfarPfa');
    opts.cfar.pfa = pfa;
    assert_rejected(@() cfar_2d(ones(32,64),opts.cfar), 'CTSAI:InvalidCfarPfa');
end
for pfa = [1e-2,1e-4,1e-100]
    alpha = os_cfar_alpha(32,24,pfa);
    logActual = -sum(log1p(alpha ./ (32-(0:23))));
    assert(abs(logActual-log(pfa)) < 1e-10);
end
% Rank one has the closed form alpha=N*(1/pfa-1).
alpha = os_cfar_alpha(32,1,1e-3);
assert(abs(alpha-32*(1e3-1)) < 1e-8);
assert_rejected(@() os_cfar_alpha(0,1,.1), 'CTSAI:InvalidOsTrainingCount');
assert_rejected(@() os_cfar_alpha(32,0,.1), 'CTSAI:InvalidOsRank');
assert_rejected(@() os_cfar_alpha(32,33,.1), 'CTSAI:InvalidOsRank');
assert_rejected(@() os_cfar_alpha(32,1,realmin), 'CTSAI:OsThresholdUnrepresentable');
fprintf('CFAR input/termination tests passed.\n');
end
function assert_rejected(action, identifier)
rejected = false;
try
    action();
catch err
    rejected = strcmp(err.identifier, identifier);
end
assert(rejected);
end
