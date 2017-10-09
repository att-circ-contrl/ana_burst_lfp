function varargout = phaDepPow_cosine_difference_stats(dat1,dat2,cfg)
% out = phaDepPow_cosine_stat(dat,cfg)
% [out,fighandle] = phaDepPow_cosine_stat(dat,cfg)
%
% Inputs:
%   - dat: NxM matrix [ndat,nPhaseBins]
%   - cfg: sturct with fields
%       - avgtype: 'median', 'mean'
%       - bincentre: 1xM vector of phase bin centres
%       - ampstats: bool, randomization stats on fit amplitude 
%       - shiftstats: bool, randomization stats on fit phase shift 
%       - nperm: numbr of permutations
%
% Copyright 2017, Benjamin Voloh

%----------------------------------------------------------------
% inputs and checks
cfg = checkfield(cfg,'avgtype','needit');
cfg = checkfield(cfg,'freq','needit');
cfg = checkfield(cfg,'bincentre','needit');
cfg = checkfield(cfg,'randstats',0);
cfg = checkfield(cfg,'nperm',nan);
cfg = checkfield(cfg,'doplot',0);
cfg = checkfield(cfg,'plottitle','cosine fit to raw data');
cfg = checkfield(cfg,'ang2ms',false);

[ndat1,npha1] = size(dat1);
[ndat2,npha2] = size(dat2);

if npha1~=npha2 && (numel(cfg.bincentre) ~= npha1 || numel(cfg.bincentre) ~= npha2)
    error('dat and bincentre dimensions dont agree')
end

%cosine inputs
fcfg = [];
fcfg.axistype = 'phase';


%----------------------------------------------------------------
% do stats

% get observed cosine fits
[mu1,se1] = avganderror(dat1,cfg.avgtype,1,1,2000);
fitres1 = fitcosine(mu1,cfg.bincentre,fcfg);
A1 = fitres1.A;
T1 = fitres1.theta;


[mu2,se2] = avganderror(dat2,cfg.avgtype,1,1,2000);
fitres2 = fitcosine(mu2,cfg.bincentre,fcfg);
A2 = fitres2.A;
T2 = fitres2.theta;

Ad = ampdiff(A1,A2);
Td = phadiff(T1,T2,cfg.freq,cfg.ang2ms);

%randomization stats
disp('stats on cosine difference...')
if cfg.randstats
    Adrand = nan(cfg.nperm,1);
    Tdrand = nan(cfg.nperm,1);
    
    %randomize labels
    tmp = cat(1,dat1,dat2);
    sz = size(tmp);
    ii = size(dat1,1);

    for np=1:cfg.nperm
        dotdotdot(np,ceil(cfg.nperm*0.1),cfg.nperm)

        ind = randperm(sz(1));
        
        rand1 = tmp( ind(1:ii), : );
        rand2 = tmp( ind(ii+1:end), : );

        [tmpmu1,~] = avganderror(rand1,cfg.avgtype,1,1,2000);
        tmpfit1 = fitcosine(tmpmu1,cfg.bincentre,fcfg);
        
        [tmpmu2,~] = avganderror(rand2,cfg.avgtype,1,1,2000);
        tmpfit2 = fitcosine(tmpmu2,cfg.bincentre,fcfg);
        
        Adrand(np) = ampdiff(tmpfit1.A, tmpfit2.A);
        Tdrand(np) = phadiff(tmpfit1.theta, tmpfit2.theta, cfg.freq, cfg.ang2ms);
    end
    
    Adp = sum( abs(Adrand) > abs(Ad) ) ./ cfg.nperm;
    Tdp = sum( abs(Tdrand) > abs(Td) ) ./ cfg.nperm;
else
    Adp = nan;
    Adrand = nan;
    Tdp = nan;
    Tdrand = nan;
end


%output
out = [];
out.A1 = A1;
out.mu1 = mu1;
out.se1 = se1;
out.fitres1 = fitres1;
out.A2 = A2;
out.mu2 = mu2;
out.se2 = se2;
out.fitres2 = fitres2;
out.Ad = Ad;
out.Td = Td;
out.Adp = Adp;
out.Adrand = Adrand;
out.Tdp = Tdp;
out.Tdrand = Tdrand;

varargout{1} = out;
if nargout>1
    varargout{2} = cf;
end
    


%----------------------------------------------------------------
% Nested functions

function d = ampdiff(A1,A2)

d = A2 - A1;

function d = phadiff(T1,T2,freq,convertFlag)

if convertFlag
    T1 = rad2time(T1,freq);
    T2 = rad2time(T2,freq);
end

d = T2 - T1;

