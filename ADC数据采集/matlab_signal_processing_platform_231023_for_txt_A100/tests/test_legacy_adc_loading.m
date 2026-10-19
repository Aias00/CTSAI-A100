function test_legacy_adc_loading()
% Packed words decode by hand to [1,2,-1,0,-32768,32767,3,4].
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'init_function'));
folder = tempname; mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, 's'));
file = fullfile(folder, 'capture_Pf0_Rx0.txt');
cfg = struct('rng_nfft',4,'nchirp',2,'nvirtual_chirp',1, ...
    'nvirtual_array',1,'vel_nfft',2);
words = '65538,4294901760,2147516415,196612';
expected = [1,-32768;2,32767;-1,3;0,4];
write_text(file, ['0,4,2,' words ',0']);
assert(isequal(load_adc_data({file}, cfg), expected), ...
    'Header values must never become ADC samples.');
legacy = fullfile(folder, 'legacy.txt');
write_text(legacy, [words ',0']);
assert(isequal(load_adc_data({legacy}, cfg), expected));
write_text(file, ['0,4,2,' words]);
assert(isequal(load_adc_data({file}, cfg), expected));
for invalid = {['1,4,2,' words], ['0,6,2,' words], ...
        '0,4,2,65538', ['0,4,2,' words ',7'], ...
        '0,4,2,65538,NaN,2147516415,196612', ...
        '0,4,2,65538,invalid,2147516415,196612', ...
        '0,4,2,65538,1.5,2147516415,196612', ...
        '0,4,2,65538,-1,2147516415,196612', ...
        '0,4,2,65538,4294967296,2147516415,196612'}
    write_text(file, invalid{1});
    rejected = false;
    try
        load_adc_data({file}, cfg);
    catch
        rejected = true;
    end
    assert(rejected, 'Malformed ADC captures must be rejected.');
end
write_text(file, ['0,4,2,' words]);
cfg.nvirtual_chirp = 2; cfg.nvirtual_array = 2; cfg.vel_nfft = 1;
adc = load_adc_data({file}, cfg);
assert(isequal(adc(:,1,1), expected(:,1)));
assert(isequal(adc(:,1,2), expected(:,2)));
% The committed headered capture and old headerless format remain readable.
cfg = struct('rng_nfft',1024,'nchirp',256,'nvirtual_chirp',1, ...
    'nvirtual_array',4,'vel_nfft',256);
files = cell(1,4);
names = {'adc_test_20260527115033_Pf0_Rx0.txt', ...
    'adc_test_20260527115041_Pf0_Rx1.txt', ...
    'adc_test_20260527115050_Pf0_Rx2.txt', ...
    'adc_test_20260527115059_Pf0_Rx3.txt'};
for rx = 1:4, files{rx} = fullfile(root,'data',names{rx}); end
adc = load_adc_data(files, cfg);
assert(isequal(size(adc), [1024,256,4]));
assert(adc(1,1,1) == -104 && adc(2,1,1) == -88);
cfg.rng_nfft = 2048; cfg.nchirp = 128; cfg.vel_nfft = 128;
listing = dir(fullfile(root,'data','*_f1_*.txt'));
for rx = 1:4, files{rx} = fullfile(listing(rx).folder,listing(rx).name); end
adc = load_adc_data(files, cfg);
assert(isequal(size(adc), [2048,128,4]));
fprintf('Legacy ADC loader regression tests passed.\n');
end

function write_text(file, text)
fid = fopen(file, 'w'); assert(fid >= 0);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', text);
end
