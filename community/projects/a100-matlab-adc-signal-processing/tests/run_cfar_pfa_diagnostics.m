function report = run_cfar_pfa_diagnostics(numTrials)
% Isolated IID single-look reference, not end-to-end radar calibration.
if nargin < 1, numTrials = 200000; end
assert(isscalar(numTrials) && isfinite(numTrials) && ...
    numTrials >= 10000 && numTrials == floor(numTrials));
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'functions'));
rng(417, 'twister');
[~, ~, counts] = build_cfar_kernels(3, 6, 1, 2);
counts = counts(:).';
nominal = 1e-2; % Enough tail events for a fast diagnostic, not 1e-4 validation.
hits = zeros(1,3);
for first = 1:1000:numTrials
    batch = min(1000, numTrials-first+1);
    cut = -log(max(rand(batch,1), realmin));
    means = zeros(batch, numel(counts));
    for sector = 1:numel(counts)
        means(:,sector) = mean(-log(max(rand(batch,counts(sector)), realmin)), 2);
    end
    ca = means * counts.' / sum(counts);
    [go, goIndex] = max(means, [], 2);
    [so, soIndex] = min(means, [], 2);
    hits(1) = hits(1) + sum(cut > ca * cfar_alpha_ca(sum(counts), nominal));
    hits(2) = hits(2) + sum(cut > go .* reshape(cfar_alpha_ca(counts(goIndex), nominal), [], 1));
    hits(3) = hits(3) + sum(cut > so .* reshape(cfar_alpha_ca(counts(soIndex), nominal), [], 1));
end
names = {'CA', 'GOCA', 'SOCA'};
for k = 1:3
    rate = hits(k)/numTrials;
    z = 1.95996398454005;
    center = (rate + z^2/(2*numTrials))/(1+z^2/numTrials);
    half = z*sqrt(rate*(1-rate)/numTrials + z^2/(4*numTrials^2))/(1+z^2/numTrials);
    report(k).algorithm = names{k};
    report(k).nominal_pfa = nominal;
    report(k).trials = numTrials;
    report(k).hits = hits(k);
    report(k).observed_pfa = rate;
    report(k).wilson95 = [center-half, center+half];
    fprintf('%s nominal=%.4g observed=%.6g Wilson95=[%.6g, %.6g] N=%d\n', ...
        names{k}, nominal, rate, center-half, center+half, numTrials);
end
% Broad 6-sigma reference check avoids treating a 95% interval as a test.
assert(abs(report(1).observed_pfa-nominal) < ...
    6*sqrt(nominal*(1-nominal)/numTrials));
opts = struct('algorithm', 'CA', 'training_cells', [3,6], ...
    'guard_cells', [1,2], 'pfa', nominal);
result = cfar_2d(ones(32,64), opts);
assert(result.nominal_pfa == nominal && ~result.pfa_calibrated);
end
