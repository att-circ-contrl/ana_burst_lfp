function out = phaDepPow_stat(dat,cfg)
% out = phaDepPow_stat(dat,cfg)
%
% cfg fields
%   - avgtype: 'median', 'mean'
%   - bincentre: 1xM vector of phase bin centres
%   - ampstats: bool, randomization stats on fit amplitude 
%   - shiftstats: bool, randomization stats on fit phase shift 
%   - nperm: numbr of permutations
%
% Copyright 2017, Benjamin Voloh

%----------------------------------------------------------------
% inputs
cfg = checkfield(cfg,'avgtype','needit');
cfg = checkfield(cfg,'freq','needit');
cfg = checkfield(cfg,'bincentre','needit');
cfg = checkfield(cfg,'ampstats',nan);
cfg = checkfield(cfg,'shiftstats',nan);
cfg = checkfield(cfg,'nperm',nan);

[ndat,npha] = size(dat);

if numel(cfg.bincentre) ~= npha
    error('dat and bincentre dimensions dont agree')
end

%cosine inputs
fcfg = [];
fcfg.axistype = 'phase';


%----------------------------------------------------------------
% do stats

% get observed cosine fit
mu = get_avg(dat,cfg.avgtype,1);
fitres = fitcosine(x,mu,fcfg);
A = fitres.A;
T = fitres.theta;

%randomization stats
disp('stats on amplitude...')
if cfg.ampstats
    Arand = nan(cfg.nperm,1);
    
    for np=1:cfg.nperm
        dotdotdot(np,ceil(cfg.nperm*0.1),cfg.nperm)

        %randomize for each cell individually
        tmp = nan(size(dat));
        for id=1:ndat
            ii = randperm(npha);
            tmp(id,:) = dat(id,ii);
        end

        tmpmu = get_avg(tmp,cfg.avgtype,1);
        tmpfit = fitcosine(x,tmpmu,fcfg);
        Arand(np) = tmpfit.A;
    end
    
    Ap = sum( abs(Arand) > abs(A) ) ./ cfg.nperm;
else
    Ap = nan;
    Arand = nan;
end

disp('stats on phase offset...')
if cfg.shiftstats
    Trand = nan(cfg.nperm,1);
    for np=1:cfg.nperm
        dotdotdot(np,ceil(cfg.nperm*0.1),cfg.nperm)

        %randomize for each cell individually
        % - Womelsdorf 2014, Curr Biol
        ii = randperm(ndat,ceil(ndat/2));
        tmp = dat;
        tmp(ii,:) = dat(ii,end:-1:1);

        tmpmu = get_avg(tmp,cfg.avgtype,1);
        tmpfit = fitcosine(x,tmpmu,fcfg);
        Trand(np) = tmpfit.T;
    end
    
    %wrap phases
    %T = wrapToPi(T);
    %Trand = wrapToPi(Trand);

    % convert phases to times
    T = rad2time(T,cfg.freq);
    Trand = rad2time(Trand,cfg.freq);

    %do stats
    Tp = sum( abs(Trand) > abs(T) )./ cfg.nperm;
else
    Tp = nan;
end


%output
out = [];
out.A = A;
out.shift = T;
out.x = x;
out.mu = mu;
out.fitres = fitres;
out.Ap = Ap;
out.shiftp = Tp;
out.Arandmean = nanmean(Arand);
out.Trandmean = nanmean(Trand);



%----------------------------------------------------------------
% Nested functions

% get mean or median
function mu = get_avg(X,avgstr,dim)

if strcmp(avgstr,'median')
    mu = nanmedian(X,dim);
elseif strcmp(avgstr,'mean')
    mu = nanmean(X,dim);
else
    error('huh?')
end

