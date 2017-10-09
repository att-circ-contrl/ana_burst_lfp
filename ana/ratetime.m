function [psth,cfg] = ratetime(stime,strial,cfg)
%[psth,cfg] = ratetime(stime,strial,cfg)
% 
% cfg: minN (optional)
%       toilim (optional)
%       toi (optional, toi for wntire experiment)
%       fsample (default=1000)
%       win (in sec.)
%       time
%       trlsel (optional)
%
% Copyright 2017, Benjamin Voloh

%inputs
cfg = checkfield(cfg,'minN',-1);
cfg = checkfield(cfg,'toilim',nan);
cfg = checkfield(cfg,'fsample',1000);
cfg = checkfield(cfg,'win','needit');
cfg = checkfield(cfg,'time',nan);
cfg = checkfield(cfg,'trlsel',unique(strial));
cfg = checkfield(cfg,'toi',[]);

if isnan(cfg.time)

    lim = [min(stime) max(stime)];
    cfg.time = lim(1):1/cfg.fsample:lim(2);
end

%convert to array
tmp = [];
tmp.origtime = stime;
tmp.origtrial = strial;

spiketrain = double( sts2bin(tmp,cfg.time,cfg.trlsel) );

%do trials have different limits?
if ~isnan(cfg.toilim)
    if size(cfg.toilim,1)==1
        cfg.toilim = repmat(cfg.toilim,size(spiketrain,1),1);
    end
        
        
    for it=1:size(spiketrain,1)
        sel = cfg.time >= cfg.toilim(it,1) & cfg.time <= cfg.toilim(it,2);
        spiketrain(it,~sel) = nan;
    end
end

%get rid of anything outisde toi
if ~isempty(cfg.toi)
   seltime = cfg.time >= cfg.toi(1) & cfg.time <= cfg.toi(2);
   spiketrain(:,~seltime) = [];
   cfg.time(~seltime) = [];
end
    
%get info for spike rate
count = nansum(spiketrain);

%how many points used to compute
ws = ones( 1, ceil( cfg.win * cfg.fsample) );
kerneldensity = conv(ones(size(cfg.time)), ws, 'same');


%get trial density
trialdensity = sum(~isnan(spiketrain));

%set time points without enough trials to nan
notEnoughTrials = ~( trialdensity > cfg.minN );

%calculate

 %get spike rate
%BV: Sept 21, 2016: divide by trial BEFORE conv
psth = count ./ trialdensity;
psth = conv(psth,ws,'same');
psth = psth ./ kerneldensity; %normalize by number of trials, kernel density
psth = psth .* cfg.fsample; % convert to spikes per second

      
bad = notEnoughTrials | trialdensity==0; %too few trials OR inf
psth(bad) = nan;
    