function bp = burstProportion(bursts,nonbursts,origtime,toi)
% bp = burstProportion(bursts,nonbursts)
% bp = burstProportion(bursts,nonbursts,origtime,toi)
%
% Copyright 2017, Benjamin Voloh

if nargin>=3 && nargin <4
    error('gotta provide the time and time selection criteria')
end

if nargin >=3
    seltoi = origtime >= toi(1) & origtime <= toi(2);
else
    seltoi = true(size(bursts));
end

b = sum( bursts(seltoi) );
nb = sum( nonbursts(seltoi) );

bp = b ./ (nb+b);



