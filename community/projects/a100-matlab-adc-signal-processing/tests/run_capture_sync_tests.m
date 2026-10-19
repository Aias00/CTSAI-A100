function run_capture_sync_tests()
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'functions'));
files = {'/capture/rx0.txt','/capture/rx1.txt'};
sync = validate_capture_sync(files,struct());
assert(~sync.verified && strcmp(sync.status,'capture_sync_unverified'));
opts.capture_sync = struct('verified',false);
sync = validate_capture_sync(files,opts);
assert(~sync.verified);
opts.capture_sync = struct('verified',true,'capture_id','frame-17', ...
    'evidence','DAQ frame identifier and phase-coherent acquisition record', ...
    'files',{files});
sync = validate_capture_sync(files,opts);
assert(sync.verified && strcmp(sync.capture_id,'frame-17'));
sync = validate_capture_sync(fliplr(files),opts);
assert(sync.verified);
opts.capture_sync.files{2} = '/other/rx1.txt';
assert_rejected(@() validate_capture_sync(files,opts));
opts.capture_sync.files = files;
opts.capture_sync.evidence = '';
assert_rejected(@() validate_capture_sync(files,opts));
opts.capture_sync.verified = 1;
assert_rejected(@() validate_capture_sync(files,opts));
fprintf('Capture synchronization metadata tests passed.\n');
end
function assert_rejected(action)
rejected=false;
try
    action();
catch err
    rejected=strcmp(err.identifier,'CTSAI:InvalidCaptureSync');
end
assert(rejected);
end
