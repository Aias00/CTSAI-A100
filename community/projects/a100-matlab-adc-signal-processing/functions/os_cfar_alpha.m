function alpha = os_cfar_alpha(numTraining, rankIndex, pfa)
%OS_CFAR_ALPHA Bounded log-domain exponential-noise OS-CFAR solver.
validate_cfar_pfa(pfa);
if ~isnumeric(numTraining) || ~isreal(numTraining) || ~isscalar(numTraining) || ...
        ~isfinite(numTraining) || numTraining < 1 || numTraining ~= floor(numTraining)
    error('CTSAI:InvalidOsTrainingCount', 'OS training count must be a positive integer.');
end
if ~isnumeric(rankIndex) || ~isreal(rankIndex) || ~isscalar(rankIndex) || ...
        ~isfinite(rankIndex) || rankIndex < 1 || rankIndex > numTraining || rankIndex ~= floor(rankIndex)
    error('CTSAI:InvalidOsRank', 'OS rank must be an integer in [1,N].');
end
samples = numTraining-(0:rankIndex-1);
logProbability = @(a) -sum(log1p(a ./ samples));
target = log(pfa);
low = 0;
high = 1;
for iteration = 1:1024
    if logProbability(high) <= target
        break;
    end
    if high > realmax/2
        error('CTSAI:OsThresholdUnrepresentable', 'OS threshold exceeds the finite numeric range.');
    end
    high = high * 2;
end
if logProbability(high) > target
    error('CTSAI:OsThresholdUnrepresentable', 'Could not bracket a finite OS threshold.');
end
for iteration = 1:80
    mid = low + (high-low)/2;
    if logProbability(mid) > target
        low = mid;
    else
        high = mid;
    end
end
alpha = low + (high-low)/2;
end
