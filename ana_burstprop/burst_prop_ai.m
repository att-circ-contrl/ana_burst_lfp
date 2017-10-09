function out = burst_prop_ai(sta,cfg,spkInfo)
% out = burst_prop_ai(sta,cfg,spkInfo)
%
% sta: from get_sta_lfp_v02
% spkInfo: from list.spike

%check options
cfg = checkfield(cfg,'baseline',[-0.5, 0] );
cfg = checkfield(cfg,'win','needit');
cfg = checkfield(cfg,'minnumtrials',1);
cfg = checkfield(cfg,'time','needit');

%set some parameters
time = cfg.time;
    
selbaseline = time >= cfg.baseline(1) & time <= cfg.baseline(2);
otime = sta.origtime;
otrial = sta.origtrial;

stimChange = sta.cfg.timeStimChange;
nTrls = numel(stimChange);
   
% calculate burst/ nonburst rate, in baseline and attention periods
disp('calulating burst prop AI...')

rateNonburst = nan(1,numel(time));
rateBurst = nan(1,numel(time));

%calculate seperatley for baseline, attention period
for it=1:2
    scfg = [];
    scfg.minN = cfg.minnumtrials;
    scfg.fsample = 1000;
    scfg.win = cfg.win;

    if it==1; 
        toilim = repmat(cfg.baseline,nTrls,1);
        seltime = selbaseline;
    else
        toilim = [zeros(nTrls,1) + 0.0001, stimChange];
        seltime = ~selbaseline;
    end
    
    scfg.time = time(seltime);
    scfg.toilim = toilim;
    scfg.trlsel = nTrls;
    
    rateNonburst(seltime) = ratetime( otime(spkInfo.selnonburst), otrial(spkInfo.selnonburst), scfg );  
    rateBurst(seltime) = ratetime( otime(spkInfo.selburst), otrial(spkInfo.selburst), scfg );  
end


% calculate burst proportion
base_prop = rateBurst(selbaseline) ./ (rateBurst(selbaseline) + rateNonburst(selbaseline));
base_prop = nanmean(base_prop);

full_prop = rateBurst ./ (rateBurst + rateNonburst);

%calculate AI
num = bsxfun(@minus, full_prop, base_prop);
den = bsxfun(@plus, full_prop, base_prop);

ai = num ./ den;
ai(den==0) = 0;

%output
out = [];
out.cfg = cfg;
out.time = time;
out.selbaseline = selbaseline;
out.rate_burst = rateBurst;
out.rate_nonburst = rateNonburst;
out.base_prop = base_prop;
out.full_prop = full_prop;
out.ai_prop = ai;
