function varargout = phaDepPow_cosine_stats(dat,cfg)
% out = phaDepPow_cosine_stats(dat,cfg)
% [out,fighandle] = phaDepPow_cosine_stats(dat,cfg)
%
% Inputs:
%   - dat: NxM matrix [ndat,nPhaseBins]
%   - cfg: sturct with fields
%       - avgtype: 'median', 'mean'
%       - bincentre: 1xM vector of phase bin centres
%       - ampstats: bool, randomization stats on fit amplitude 
%       - shiftstats: bool, randomization stats on fit phase shift 
%       - nperm: numbr of permutations
%       - nparallel: number of workers
%       - doplot: plot fit (default=false)
%       - plottitle: plot title
%
% Copyright 2017, Benjamin Voloh

%----------------------------------------------------------------
% inputs
cfg = checkfield(cfg,'avgtype','needit');
cfg = checkfield(cfg,'bincentre','needit');
cfg = checkfield(cfg,'ampstats',1);
cfg = checkfield(cfg,'shiftstats',1);
cfg = checkfield(cfg,'nperm',nan);
cfg = checkfield(cfg,'nparallel',0);
cfg = checkfield(cfg,'doplot',0);
cfg = checkfield(cfg,'plottitle','cosine fit to raw data');

if cfg.shiftstats
    cfg = checkfield(cfg,'freq','needit');
end
[ndat,npha] = size(dat);

if numel(cfg.bincentre) ~= npha
    error('dat and bincentre dimensions dont agree')
end

% start parallel if need be
if cfg.nparallel > 1
    pp = parcluster;
    pp.NumWorkers = cfg.nparallel;
else
    cfg.nparallel = 0; % set to zero so parfor works as for loop
end

%cosine inputs
fcfg = [];
fcfg.axistype = 'phase';


%----------------------------------------------------------------
% do stats

% get observed cosine fit
[mu,se] = avganderror(dat,cfg.avgtype,1,1,2000);

fitres = fitcosine(mu,cfg.bincentre,fcfg);
A = fitres.A;
T = fitres.theta;

%randomization stats
disp('stats on amplitude...')
if cfg.ampstats
    Arand = nan(cfg.nperm,1);
    
    parfor (np=1:cfg.nperm,cfg.nparallel)
        %dotdotdot(np,ceil(cfg.nperm*0.1),cfg.nperm)

        %randomize for each cell individually
        tmp = nan(size(dat));
        for id=1:ndat
            ii = randperm(npha);
            tmp(id,:) = dat(id,ii);
        end

        [tmpmu,~] = avganderror(tmp,cfg.avgtype,1,0);
        tmpfit = fitcosine(tmpmu,cfg.bincentre,fcfg);
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
    parfor (np=1:cfg.nperm,cfg.nparallel)
        %dotdotdot(np,ceil(cfg.nperm*0.1),cfg.nperm)

        %randomize for each cell individually
        % - Womelsdorf 2014, Curr Biol
        ii = randperm(ndat,ceil(ndat/2));
        tmp = dat;
        tmp(ii,:) = dat(ii,end:-1:1);

        [tmpmu,~] = avganderror(tmp,cfg.avgtype,1,0);
        tmpfit = fitcosine(cfg.bincentre,tmpmu,fcfg);
        Trand(np) = tmpfit.theta;
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
    Trand = nan;
end

%plot?
if cfg.doplot
    someFigureAlreadyExists = ~isempty(findall(0,'Type','Figure'));
    if someFigureAlreadyExists
        ff = gcf;
    end
   
    cf = figure;
    errorbar(cfg.bincentre,mu,se,'ko','markerfacecolor',[0.5 0.5 0.5],'markersize',10)
    hold all
    hf = plot(fitres);
    set(hf,'color','k');
    
    set(gca,'fontsize',14)
    set(gca,'xlim',[cfg.bincentre(1) cfg.bincentre(end)]*1.1)

    title(cfg.plottitle)
    xlabel('phase bincentre')
    ylabel('amp')
    
    legend({'raw','cosfit'})
    
    %set figure back to whatever it was
    if someFigureAlreadyExists
        figure(ff) 
    end
else
    cf = nan;
end


%output
out = [];
out.A = A;
out.shift = T;
out.mu = mu;
out.se = se;
out.fitres = fitres;
out.Ap = Ap;
out.shiftp = Tp;
out.Arandmean = nanmean(Arand);
out.Trandmean = nanmean(Trand);
out.Arand = Arand;
out.Trand = Trand;
out.N = size(dat,1);
out.cfg = cfg;

varargout{1} = out;
if nargout>1
    varargout{2} = cf;
end

