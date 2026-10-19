function run_ddma_guard_tests()
% Phase-only de-rotation must not be reported as separated TX channels.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'functions'));
cfg = struct('num_rx',4,'nchirp',8,'vel_nfft',8, ...
    'tx_groups',[1,1,0,0],'ddma_phase_increment_deg',[0,90,0,0]);
cfg = derive_dimensions(cfg);
n = 0:7;
mixture = 2 + 3*exp(1i*pi/2*n);
raw = repmat(reshape(mixture,1,8,1),1,1,4);
rejected = false;
try
    organize_virtual_array(raw, cfg, 'block');
catch err
    rejected = strcmp(err.identifier, 'CTSAI:DDMASeparationUnsupported');
end
assert(rejected, 'DDMA needs TX separation, not only a known phase code.');

cfg = rmfield(cfg,'ddma_phase_increment_deg');
cfg.tx_groups = [0,0,1,0];
cfg = derive_dimensions(cfg);
assert(isequal(organize_virtual_array(raw,cfg,'block'),raw));

cfg.tx_groups = [1,16,0,0];
cfg = derive_dimensions(cfg);
raw = reshape(1:64,2,8,4);
block = organize_virtual_array(raw,cfg,'block');
assert(isequal(block(:,:,1:4),raw(:,1:4,:)));
assert(isequal(block(:,:,5:8),raw(:,5:8,:)));
interleaved = organize_virtual_array(raw,cfg,'interleaved');
assert(isequal(interleaved(:,:,1:4),raw(:,1:2:8,:)));
assert(isequal(interleaved(:,:,5:8),raw(:,2:2:8,:)));
fprintf('DDMA guard and SISO/TDM compatibility tests passed.\n');
end

function cfg = derive_dimensions(cfg)
cfg.mimo = decode_tx_groups(cfg,cfg.num_rx);
cfg.slow_time_chirp_num = cfg.nchirp/cfg.mimo.group_count;
cfg.nvirtual_array = cfg.mimo.virtual_tx_link_count*cfg.num_rx;
end
