function virtualCube = organize_virtual_array(rangeRxCube, cfg, layout)
%ORGANIZE_VIRTUAL_ARRAY Build virtual channels after Range FFT.
% Input:  [range, raw chirp, RX]
% Output: [range, slow-time chirp, virtual channel]
%
% SISO: no slow-time deinterleaving; physical-TX geometry is still mapped.
% TDM: chirp groups are selected using block or interleaved layout.
% DDMA/BPM require TX separation that is not implemented here. Even known
% DDMA phase increments only shift the mixture and cannot isolate each TX.

if nargin < 3 || isempty(layout)
    layout = 'block';
end
if size(rangeRxCube, 3) ~= cfg.num_rx
    error('Expected %d RX channels, got %d.', cfg.num_rx, size(rangeRxCube,3));
end
if size(rangeRxCube, 2) ~= cfg.nchirp
    error('Expected %d raw chirps, got %d.', cfg.nchirp, size(rangeRxCube,2));
end

mode = upper(cfg.mimo.mode);
switch mode
    case {'SISO', 'TDM'}
        % Supported below.
    case 'DDMA'
        error('CTSAI:DDMASeparationUnsupported', ...
            ['DDMA TX separation and valid velocity-band constraints are ' ...
            'not implemented. Phase de-rotation alone leaves other TX ' ...
            'components in every channel; refusing physical velocity/angle output.']);
    case 'BPM_UNSUPPORTED'
        error(['bpm_mode is enabled, but this project does not have the ' ...
            'firmware BPM code sequence required for exact decoding.']);
    case 'SIMULTANEOUS_UNRESOLVED'
        error(['tx_groups enables simultaneous transmitters, but the HXX ' ...
            'file contains no explicit DDMA phase increment or Doppler ' ...
            'offset. Refusing to guess the waveform.']);
    otherwise
        error('Unsupported MIMO mode: %s', cfg.mimo.mode);
end

nRange = size(rangeRxCube, 1);
nSlow = cfg.slow_time_chirp_num;
nVirtual = cfg.nvirtual_array;
virtualCube = complex(zeros(nRange, nSlow, nVirtual, 'like', rangeRxCube));
channel = 0;

for iGroup = 1:cfg.mimo.group_count
    chirpIdx = select_group_chirps(iGroup, cfg.mimo.group_count, ...
        nSlow, layout);
    groupCube = rangeRxCube(:, chirpIdx, :);
    txList = cfg.mimo.group_tx_indices{iGroup};

    for iTxList = 1:numel(txList)
        channelIdx = channel + (1:cfg.num_rx);
        virtualCube(:, :, channelIdx) = groupCube;
        channel = channel + cfg.num_rx;
    end
end

if channel ~= nVirtual
    error('Virtual-channel construction mismatch: built %d, expected %d.', ...
        channel, nVirtual);
end
end

function chirpIdx = select_group_chirps(iGroup, nGroups, nSlow, layout)
switch lower(strtrim(layout))
    case 'block'
        chirpIdx = (iGroup-1)*nSlow + (1:nSlow);
    case 'interleaved'
        chirpIdx = iGroup:nGroups:(iGroup + (nSlow-1)*nGroups);
    otherwise
        error('Unknown TX chirp layout: %s', layout);
end
end
