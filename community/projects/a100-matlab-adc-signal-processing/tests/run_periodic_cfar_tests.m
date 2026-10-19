function run_periodic_cfar_tests()
% FFT Doppler is periodic; range is bounded. All diagnostics must align.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'functions'));
opts = struct('training_cells',[2,2],'guard_cells',[1,1], ...
    'pfa',1e-3,'os_rank_ratio',0.75,'vi_threshold',2.5, ...
    'mean_ratio_threshold',2.8,'min_homogeneous_sectors',1);
probe = ones(24,32); probe(12,1) = 1e6; probe(18,32) = 1e6;
fields = {'mask','power','noise','threshold','snr_db','alpha_map', ...
    'num_training_cells','method_map','variability_index','sector_mean_ratio'};
for method = {'CA','OS','GOCA','SOCA','VI'}
    opts.algorithm = method{1};
    result = cfar_2d(probe,opts);
    assert(result.mask(12,1) && result.mask(18,32), ...
        ['Lost a target on the periodic boundary: ' method{1}]);
    assert(~any(any(result.mask([1:3,22:24],:))));
    for idx = 1:numel(fields)
        assert(isequal(size(result.(fields{idx})),size(probe)));
    end
    if ~isscalar(result.alpha), assert(isequal(size(result.alpha),size(probe))); end
    shifted = cfar_2d(circshift(probe,[0,7]),opts);
    assert(isequal(shifted.mask,circshift(result.mask,[0,7])));
    noise = circshift(result.noise,[0,7]);
    good = isfinite(noise) & isfinite(shifted.noise);
    assert(max(abs(noise(good)-shifted.noise(good))) < 1e-9);
    % Interior processing is unchanged: use a triple-period map, whose
    % middle period has complete training neighborhoods even on baseline.
    repeated = cfar_2d(repmat(probe,1,3),opts);
    assert(isequal(result.mask,repeated.mask(:,33:64)));
end
fprintf('Periodic CFAR boundary, shape and shift tests passed.\n');
end
