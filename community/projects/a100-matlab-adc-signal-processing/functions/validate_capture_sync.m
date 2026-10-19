function sync = validate_capture_sync(files, ioOpts)
%VALIDATE_CAPTURE_SYNC Require explicit acquisition evidence for coherent DOA.
% File timestamps alone neither prove nor disprove simultaneous sampling.
sync = struct('verified',false,'capture_id','','evidence','', ...
    'status','capture_sync_unverified');
if ~isfield(ioOpts,'capture_sync') || isempty(ioOpts.capture_sync)
    return;
end
claim = ioOpts.capture_sync;
if ~isstruct(claim) || ~isscalar(claim) || ~isfield(claim,'verified') || ...
        ~islogical(claim.verified) || ~isscalar(claim.verified)
    error('CTSAI:InvalidCaptureSync', 'capture_sync must contain a scalar logical verified field.');
end
if ~claim.verified
    return;
end
for name = {'capture_id','evidence'}
    if ~isfield(claim,name{1}) || ~ischar(claim.(name{1})) || ...
            ~isrow(claim.(name{1})) || isempty(strtrim(claim.(name{1})))
        error('CTSAI:InvalidCaptureSync', 'Verified capture requires a nonempty capture_id and evidence.');
    end
end
if ~isfield(claim,'files') || ~iscellstr(claim.files) || ...
        numel(claim.files) ~= numel(files) || ...
        numel(unique(claim.files)) ~= numel(files) || ...
        ~isequal(sort(claim.files(:)),sort(files(:)))
    error('CTSAI:InvalidCaptureSync', 'Synchronization evidence must bind exactly the current capture files.');
end
sync.verified = true;
sync.capture_id = claim.capture_id;
sync.evidence = claim.evidence;
sync.status = 'capture_sync_asserted';
end
