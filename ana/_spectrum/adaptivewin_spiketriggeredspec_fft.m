function sts = adaptivewin_spiketriggeredspec_fft(sta,cfg)
% sts = adaptivewin_spiketriggeredspec_fft(sta,cfg)
%
% "sta" is a sturcture from ft_spiketriggeredaverage
% - this sturtcure has to have a "trial" field (ie when calling
%   ft_spiketriggeredaverage, keeptrials = 'yes'

%inputs
cfg = checkfield( cfg, 'fsample', 1./mean(diff(sta.time)) );
%cfg = checkfield( cfg, 'foilim', [0 150] );
%cfg = checkfield( cfg, 'timwin', [sta.time(1), sta.time(end)] );
cfg = checkfield( cfg, 'taper', 'hanning' );
cfg = checkfield( cfg, 'freq', 0:1:150);
cfg = checkfield( cfg, 'ncycle', 5);

%loop over selected frequencies
sz = size(sta.trial);
cfg2 = cfg;
freqtmp = [];
spec = nan( [sz(1:2), numel(cfg.freq)] );
for ifreq=1:numel(cfg.freq)
    updatecounter(ifreq,[1 numel(cfg.freq)], 'calculating frequency ',3)
    
    ff = cfg.freq(ifreq);
    cfg2.foilim = [ff ff];
    cfg2.timwin = cfg.ncycle ./ [-ff ff] ./ 2;
    
    tmp = spiketriggeredspec_fft(sta,cfg2);
    
    freqtmp = cat(2,freqtmp,tmp.freq);
    spec(:,:,ifreq) = tmp.fourierspctrm;
end

%save
sts = [];
sts.time{1} = tmp.time;
sts.trial{1} = tmp.trial;
sts.lfplabel = tmp.label;
sts.label = sta.cfg.spikechannel;
sts.freq = freqtmp;
sts.fourierspctrm{1} = spec;
sts.cfg = cfg;
sts.cfg.cfg = sta.cfg;
sts.dimord = '{chan}_spike_lfpchan_freq';

if ~isfield(sta,'trialtime'); sts.trialtime = nan(size(sta.trials,1),2);
else, sts.trialtime = sta.trialtime;
end
if ~isfield(sta,'trialinfo'); sts.trialinfo = nan(size(sta.trials,1),2);
else, sts.trialinfo = sta.trialinfo;
end
