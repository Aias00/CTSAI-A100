function run_periodic_neighbor_tests()
% Native MATLAB test: table-based detection and MUSIC callers wrap Doppler.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'functions')); addpath(fullfile(root,'config'));
opts = default_processing_options();
cfg = struct('range_axis_m',0:23,'max_range_m',23, ...
    'velocity_axis_mps',-16:15, 'ant_pos',[(0:3)'*0.5,zeros(4,1)], ...
    'ant_comps',zeros(4,1));
power = ones(24,32); power(12,1) = 100; power(12,32) = 200;
cfar = struct('power',power,'noise',ones(24,32), ...
    'threshold',ones(24,32),'mask',false(24,32), ...
    'method_map',ones(24,32),'method_names',{{'INVALID','CA'}}, ...
    'algorithm','CA','variability_index',ones(24,32), ...
    'sector_mean_ratio',ones(24,32));
cfar.mask(12,[1,32]) = true;
opts.detection.min_snr_db = 0;
found = extract_detections(cfar,cfg,opts.detection);
assert(height(found) == 1 && found.DopplerBin == 32, ...
    'A weaker edge bin must see its stronger neighbor across the FFT seam.');

% Moving the same neighborhood away from the seam must not change MUSIC.
rd = complex(zeros(24,32,4));
a = exp(1i*2*pi*(0:3)'*0.5*sind(20));
b = exp(1i*2*pi*(0:3)'*0.5*sind(-30));
rd(12,1,:) = reshape(2*a,1,1,4);
rd(12,2,:) = reshape(a,1,1,4);
rd(12,32,:) = reshape(4*b,1,1,4);
detection = table(12,1,11,-16, ...
    'VariableNames',{'RangeBin','DopplerBin','Range_m','Velocity_mps'});
[~,edge] = estimate_angles_for_detections(rd,detection,cfg,opts.angle);
detection.DopplerBin = 8;
[~,interior] = estimate_angles_for_detections( ...
    circshift(rd,[0,7,0]),detection,cfg,opts.angle);
assert(max(abs(edge.music_spectrum-interior.music_spectrum)) < 1e-7);
fprintf('Periodic peak and MUSIC neighborhood tests passed.\n');
end
