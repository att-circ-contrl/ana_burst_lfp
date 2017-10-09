function F = fano(X)
% F = fano(trial)
%
% calculate Fano factor


%fano factor
F = nanvar(X) ./ nanmean(X);