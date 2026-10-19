function test_fixed_noise()
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));
cfg = default_simulation_config();
cfg.generate_reference_waveforms = false;
cfg.num_samples = 64; cfg.num_chirps = 16;
cfg.noise_rms = 0.05;
original = cfg.targets;
reference_noise = [];
for count = [1,2,4]
    cfg.targets = original(1:count);
    scene = simulate_lfmcw_scene(cfg);
    noise = scene.beat-scene.beat_clean;
    if isempty(reference_noise), reference_noise = noise; end
    assert(norm(noise(:)-reference_noise(:)) < 1e-12);
    assert(scene.noise_rms == 0.05 && strcmp(scene.noise_mode,'fixed_rms'));
    assert(abs(scene.reference_target_snr_db - 20*log10(1/.05)) < 1e-12);
end
cfg.noise_rms = 0;
scene = simulate_lfmcw_scene(cfg);
assert(isequal(scene.beat,scene.beat_clean));
cfg.noise_rms = [];
legacy = simulate_lfmcw_scene(cfg);
assert(strcmp(legacy.noise_mode,'scene_snr'));
assert(abs(legacy.noise_rms - legacy.signal_rms/10^(cfg.noise_snr_db/20)) < 1e-12);
cfg = rmfield(cfg,'noise_rms');
missing = simulate_lfmcw_scene(cfg);
assert(isequal(legacy.beat,missing.beat));
invalid = {-1,NaN,Inf,1i,[.1,.2]};
for k = 1:numel(invalid)
    cfg.noise_rms = invalid{k}; rejected = false;
    try
        simulate_lfmcw_scene(cfg);
    catch err
        rejected = strcmp(err.identifier,'a100:InvalidNoiseRms');
    end
    assert(rejected);
end
fprintf('Fixed noise floor tests passed.\n');
end
