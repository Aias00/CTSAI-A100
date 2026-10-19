function run_tdm_velocity_tests()
% Known physical Doppler tone under both supported acquisition layouts.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'functions'));
base = load_ctsaia100_config(fullfile(root, 'config', 'sensor_config_init0.hxx'));
base.tx_groups = [hex2dec('0001'), hex2dec('0010'), 0, 0];
base.nchirp = 256;
base.vel_nfft = 128;
for layoutCell = {'block', 'interleaved'}
    layout = layoutCell{1};
    cfg = derive_radar_parameters(base, layout);
    % Eight cycles over 128 consecutive raw chirp intervals.
    fd = 8 / (128 * base.fmcw_chirp_period * 1e-6);
    time = (0:base.nchirp-1) * base.fmcw_chirp_period * 1e-6;
    raw = repmat(reshape(exp(2i*pi*fd*time), 1, [], 1), 1, 1, cfg.num_rx);
    cube = organize_virtual_array(raw, cfg, layout);
    opts = struct('window', 'rect', 'remove_static_clutter', false, ...
        'normalize', 'coherent_gain');
    [rd, ~] = doppler_fft(cube, cfg, opts);
    for ch = 1:cfg.nvirtual_array
        [~, peak] = max(abs(rd(1,:,ch)));
        assert(abs(cfg.velocity_axis_mps(peak) - fd*cfg.lambda_m/2) < 1e-10);
    end
    assert(abs(cfg.max_unambiguous_velocity_mps - ...
        cfg.lambda_m/(4*cfg.same_tx_chirp_period_s)) < 1e-10);
end
cfg = derive_radar_parameters(base);
assert(strcmp(cfg.tx_chirp_layout, 'block'));
rejected = false;
try
    organize_virtual_array(raw, cfg, 'interleaved');
catch err
    rejected = strcmp(err.identifier, 'CTSAI:LayoutMismatch');
end
assert(rejected);
rejected = false;
try
    derive_radar_parameters(base, 'unknown');
catch err
    rejected = strcmp(err.identifier, 'CTSAI:InvalidLayout');
end
assert(rejected);
fprintf('TDM layout/physical velocity tests passed.\n');
end
