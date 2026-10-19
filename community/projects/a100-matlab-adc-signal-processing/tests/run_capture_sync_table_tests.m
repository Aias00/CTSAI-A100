function run_capture_sync_table_tests()
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'functions')); addpath(fullfile(root,'config'));
opts=default_processing_options();
cfg=derive_radar_parameters(load_ctsaia100_config(fullfile(root,'config','sensor_config_init0.hxx')));
t=table(2,2,1,0,'VariableNames',{'RangeBin','DopplerBin','Range_m','Velocity_mps'});
raw=ones(4,4,4);
% Unknown sync short-circuits before reading or interpreting spatial samples.
[out,diag]=estimate_angles_for_detections(raw,t,cfg,opts.angle);
assert(all(isnan(out.SelectedAngle_deg)) && ~any(out.CaptureSyncVerified) && isempty(diag));
assert(all(isnan(out.MUSIC_deg)) && all(isnan(out.AngleFFT_deg)));
assert(isequal(out.Range_m,t.Range_m) && isequal(out.Velocity_mps,t.Velocity_mps));
[out,~]=estimate_angles_for_detections(raw,t([],:),cfg,opts.angle);
assert(height(out)==0 && ismember('CaptureSyncVerified',out.Properties.VariableNames));
files={'rx0','rx1','rx2','rx3'};
io.capture_sync=struct('verified',true,'capture_id','synthetic', ...
    'evidence','Generated simultaneous calibrated array snapshots','files',{files});
cfg.capture_sync=validate_capture_sync(files,io);
angle=15;
positions=cfg.virtual_array.positions_lambda(:,1);
snapshot=exp(2i*pi*positions*sind(angle));
raw=repmat(reshape(snapshot,1,1,[]),4,4,1);
opts.angle.apply_phase_calibration=false;
[out,~]=estimate_angles_for_detections(raw,t,cfg,opts.angle);
assert(out.CaptureSyncVerified && abs(out.SelectedAngle_deg-angle)<1);
fprintf('Native MATLAB synchronization/table tests passed.\n');
end
