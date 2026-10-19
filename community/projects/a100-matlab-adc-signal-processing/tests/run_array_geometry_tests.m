function run_array_geometry_tests()
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'functions'));
addpath(fullfile(root,'config'));
opts = default_processing_options();
cfg = derive_radar_parameters(load_ctsaia100_config(fullfile(root,'config','sensor_config_init0.hxx')));
positions = cfg.virtual_array.positions_lambda(:,1);
grid = -75:.25:75;
for angle = [10,30,-20,50]
    snapshot = exp(2i*pi*positions*sind(angle));
    result = estimate_angle_fft(snapshot,positions,grid,opts.angle);
    assert(strcmp(result.method,'GEOMETRY_SCAN'));
    assert(abs(result.angle_deg-angle) <= .25);
    order = [4,2,1,3];
    reordered = estimate_angle_fft(snapshot(order),positions(order),grid,opts.angle);
    assert(abs(reordered.angle_deg-angle) <= .25);
end
% Uniform half-wave array retains the FFT implementation.
positions = (0:7)'*.5;
for angle = [-30,0,30]
    snapshot = exp(2i*pi*positions*sind(angle));
    result = estimate_angle_fft(snapshot,positions,grid,opts.angle);
    assert(strcmp(result.method,'SPATIAL_FFT'));
    assert(abs(result.angle_deg-angle) <= .5);
end
fprintf('Array geometry FFT/scan tests passed.\n');
end
