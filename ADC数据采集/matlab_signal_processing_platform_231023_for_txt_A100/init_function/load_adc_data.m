function adcData = load_adc_data(file, Cfg)
%LOAD_ADC_DATA Read headered Pf/Rx exports or legacy headerless captures.
% Original author: ZhuXinpeng (2021-05-13).
% A header is [RX index, samples per chirp, chirp count]. Only verified
% zero padding may follow the payload; damaged captures are never padded.

nfiles = numel(file);
if nfiles ~= Cfg.nvirtual_array / Cfg.nvirtual_chirp
    error('CTSAI:ChannelCount', 'ADC file count does not match configuration.');
end
target_dim = [Cfg.rng_nfft/2, Cfg.nchirp];
expected_len = prod(target_dim);
adcTemp2 = zeros(Cfg.nchirp, Cfg.rng_nfft/2, nfiles);
for ifile = 1:nfiles
    tokens = regexp(strtrim(fileread(file{ifile})), ',', 'split');
    if isempty(strtrim(tokens{end}))
        tokens(end) = []; % A single trailing CSV delimiter is allowed.
    end
    values = str2double(tokens(:));
    if any(~isfinite(values))
        error('CTSAI:InvalidToken', 'Non-finite or invalid ADC token in %s.', file{ifile});
    end
    % Pf/Rx filenames explicitly identify the newer three-field format.
    % Older captures have exactly the payload plus optional one zero pad.
    hasHeader = ~isempty(regexp(file{ifile}, '_Pf[0-9]+_Rx[0-9]+', 'once')) || ...
        numel(values) >= expected_len + 3;
    if hasHeader
        if numel(values) < 3 || ...
                ~isequal(values(1:3).', [ifile-1, Cfg.rng_nfft, Cfg.nchirp])
            error('CTSAI:HeaderMismatch', 'ADC channel/dimensions do not match %s.', file{ifile});
        end
        payload = values(4:end);
    else
        payload = values;
    end
    if numel(payload) < expected_len
        error('CTSAI:TruncatedCapture', 'ADC payload is short in %s.', file{ifile});
    end
    if any(payload(expected_len+1:end) ~= 0)
        error('CTSAI:ExcessData', 'Non-zero data follows the ADC payload in %s.', file{ifile});
    end
    words = payload(1:expected_len);
    if any(words < 0 | words > 4294967295 | words ~= floor(words))
        error('CTSAI:InvalidWord', 'ADC words must be uint32 integers in %s.', file{ifile});
    end
    adcTemp2(:,:,ifile) = reshape(words, target_dim).';
end

if Cfg.nvirtual_chirp == 1
    for iArray = 1 : Cfg.nvirtual_array
        adcData(:, :, iArray) = permute(adc_mem_2_real_fixed(adcTemp2(:, :, iArray)), [2, 1]);
    end
else
    for iArray = 1 : Cfg.nvirtual_array / Cfg.nvirtual_chirp
        adcTx1 = adcTemp2(1 : Cfg.vel_nfft, :, iArray);
        adcTx2 = adcTemp2(Cfg.vel_nfft + 1 : end, :, iArray);
        adcData(:, :, iArray * 2 - 1) = permute(adc_mem_2_real_fixed(adcTx1), [2, 1]);
        adcData(:, :, iArray * 2) = permute(adc_mem_2_real_fixed(adcTx2), [2, 1]);
    end
end

end