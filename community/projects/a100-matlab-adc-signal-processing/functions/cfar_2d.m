function result = cfar_2d(powerMap, cfarOpts)
%CFAR_2D Two-dimensional CA/OS/GOCA/SOCA/VI-CFAR.
trainR = cfarOpts.training_cells(1);
trainD = cfarOpts.training_cells(2);
guardR = cfarOpts.guard_cells(1);
guardD = cfarOpts.guard_cells(2);
halfR = trainR + guardR;
halfD = trainD + guardD;
algorithm = upper(strtrim(cfarOpts.algorithm));

% Supply a complete periodic Doppler neighborhood to every CFAR variant.
% Distance remains bounded and is excluded by the existing range margin.
numDoppler = size(powerMap,2);
columns = mod(-halfD:numDoppler+halfD-1,numDoppler) + 1;
powerMap = powerMap(:,columns);

switch algorithm
    case 'CA'
        [kernel, ~, ~] = build_cfar_kernels(trainR, trainD, guardR, guardD);
        numTraining = sum(kernel(:));
        noiseMap = conv2(powerMap, kernel, 'same') / numTraining;
        alpha = cfar_alpha_ca(numTraining, cfarOpts.pfa);
        thresholdMap = alpha * noiseMap;
        mask = powerMap > thresholdMap;
        methodMap = ones(size(powerMap), 'uint8');
        methodNames = {'INVALID','CA'};
        numTrainingMap = numTraining * ones(size(powerMap));
        alphaMap = alpha * ones(size(powerMap));
        variabilityIndex = local_variability_index(powerMap, kernel, numTraining);
        sectorMeanRatio = ones(size(powerMap));

    case 'OS'
        [mask, noiseMap, thresholdMap, alpha, numTraining] = ...
            os_cfar_map(powerMap, trainR, trainD, guardR, guardD, ...
            cfarOpts.os_rank_ratio, cfarOpts.pfa);
        methodMap = repmat(uint8(5), size(powerMap));
        methodNames = {'INVALID','CA','GOCA','VI_SELECTED', ...
            'GOCA_FALLBACK','OS'};
        numTrainingMap = numTraining * ones(size(powerMap));
        alphaMap = alpha * ones(size(powerMap));
        [kernel, ~, ~] = build_cfar_kernels(trainR, trainD, guardR, guardD);
        variabilityIndex = local_variability_index(powerMap, kernel, numTraining);
        sectorMeanRatio = ones(size(powerMap));

    case {'GOCA','SOCA'}
        [mask, noiseMap, thresholdMap, alphaMap, numTrainingMap, ~, ...
            sectorMeanRatio] = sector_cfar_map(powerMap, trainR, trainD, ...
            guardR, guardD, cfarOpts.pfa, algorithm);
        if strcmp(algorithm, 'GOCA')
            methodMap = repmat(uint8(2), size(powerMap));
            methodNames = {'INVALID','CA','GOCA'};
        else
            methodMap = repmat(uint8(6), size(powerMap));
            methodNames = {'INVALID','CA','GOCA','VI_SELECTED', ...
                'GOCA_FALLBACK','OS','SOCA'};
        end
        [kernel, ~, ~] = build_cfar_kernels(trainR, trainD, guardR, guardD);
        variabilityIndex = local_variability_index(powerMap, kernel, sum(kernel(:)));
        alpha = alphaMap;

    case {'VI','ADAPTIVE','VI-CFAR'}
        viResult = vi_cfar_map(powerMap, trainR, trainD, guardR, guardD, cfarOpts);
        mask = viResult.mask;
        noiseMap = viResult.noise;
        thresholdMap = viResult.threshold;
        alphaMap = viResult.alpha;
        alpha = alphaMap;
        numTrainingMap = viResult.num_training_cells;
        methodMap = viResult.method_map;
        methodNames = viResult.method_names;
        variabilityIndex = viResult.variability_index;
        sectorMeanRatio = viResult.sector_mean_ratio;

    otherwise
        error('Unsupported CFAR algorithm: %s', cfarOpts.algorithm);
end

valid = false(size(powerMap));
valid(halfR+1:end-halfR, halfD+1:end-halfD) = true;
mask = mask & valid;
methodMap(~valid) = 0;

result.algorithm = algorithm;
result.mask = mask;
result.power = powerMap;
result.noise = noiseMap;
result.threshold = thresholdMap;
result.snr_db = 10 * log10((powerMap + eps) ./ (noiseMap + eps));
result.alpha = alpha;
result.alpha_map = alphaMap;
result.num_training_cells = numTrainingMap;
result.edge_margin = [halfR, 0];
result.method_map = methodMap;
result.method_names = methodNames;
result.variability_index = variabilityIndex;
result.sector_mean_ratio = sectorMeanRatio;

% Return the original grid for every diagnostic, including matrix alpha.
columns = halfD + (1:numDoppler);
mapFields = {'mask','power','noise','threshold','snr_db','alpha_map', ...
    'num_training_cells','method_map','variability_index','sector_mean_ratio'};
for iField = 1:numel(mapFields)
    name = mapFields{iField};
    values = result.(name);
    result.(name) = values(:,columns);
end
if ~isscalar(result.alpha)
    result.alpha = result.alpha(:,columns);
end
end

function variabilityIndex = local_variability_index(powerMap, kernel, numTraining)
localSum = conv2(powerMap, kernel, 'same');
localSumSq = conv2(powerMap.^2, kernel, 'same');
localMean = localSum / numTraining;
localVariance = max(localSumSq / numTraining - localMean.^2, 0);
variabilityIndex = localVariance ./ (localMean.^2 + eps);
end
