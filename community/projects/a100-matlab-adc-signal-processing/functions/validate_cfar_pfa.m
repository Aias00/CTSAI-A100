function validate_cfar_pfa(pfa)
%VALIDATE_CFAR_PFA Reject invalid inputs before threshold computation.
if ~isnumeric(pfa) || ~isreal(pfa) || ~isscalar(pfa) || ...
        ~isfinite(pfa) || pfa <= 0 || pfa >= 1
    error('CTSAI:InvalidCfarPfa', 'CFAR pfa must be a finite real scalar strictly between 0 and 1.');
end
end
