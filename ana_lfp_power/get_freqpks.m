function freqpks = get_freqpks(pow,cfg)
%freqpks = get_freqpks(pow,cfg,freq)
% cfg.fscale (default=0)
% cfg.pkdetection 
% cfg.freq
% cfg.threshscale (default=0.5)
% cfg.minpeakdistance (default = ceil( length(cfg.freq) / 20 ) )
%
% Copyright 2017, Benjamin Voloh

%defaults
cfg = checkfield(cfg,'fscale',0);
cfg = checkfield(cfg,'pkdetection','needit');
cfg = checkfield(cfg,'freq','needit');
cfg = checkfield(cfg,'threshscale',0.5);
cfg = checkfield(cfg,'minpeakdistance', ceil( length(cfg.freq) / 20 ));

%adjust
pow = pow .* cfg.freq.^cfg.fscale;

%setings
mpd = cfg.minpeakdistance;
minHeight = cfg.threshscale * ( max(pow) - min(pow) ) + min(pow);

%smooth
pow = smooth(pow);

%getpeaks
if strcmp(cfg.pkdetection,'findpeaks')
    [~, sel] = findpeaks(pow,'MinPeakDistance',mpd,'MinPeakHeight',minHeight);
elseif strcmp(cfg.pkdetection,'percent')
    mu = nanmean(pow);
    sel = cfg.freq > mu * threshscale;
end

freqpks = cfg.freq(sel);
