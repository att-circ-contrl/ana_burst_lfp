function [sta,cfg] = clean_sta_data(sta,cfg)
% [sta,cfg] = clean_sta_data(sta,cfg)

%inputs
cfg = checkfield(cfg,'replacenans',0);
cfg = checkfield(cfg,'dolowpassfilt',0);
cfg = checkfield(cfg,'dointerp',0);
cfg = checkfield(cfg,'interptoi',[-0.005, 0.005]);
cfg = checkfield(cfg,'flp',100);
cfg = checkfield(cfg,'toi',[]);

%prepare data
szorig = size(sta.trial);
tmp = squeeze( sta.trial );


%downsample?
if ~isempty(cfg.toi)
    seltime = sta.time >= cfg.toi(1) & sta.time <= cfg.toi(2);
    sta.time(~seltime) = [];
    sta.avg(~seltime) = [];
    sta.trial(:,:,~seltime) = [];
end

%replace nans?
if cfg.replacenans
    cfg.selnan = sum(isnan(tmp),2);
    for is=1:size(tmp,1)
        nans = isnan(tmp(is,:));
        mu = nanmean(tmp(is,~nans));

        tmp(is,nans) = mu;
    end
else
    cfg.selnan = nan(szorig(1),1);
end

%filter
if cfg.dolowpassfilt
    fprintf('lowpass filter at %.3g Hz...\n',cfg.flp)
    N = 4;
    fsample = 1000;
    type = 'but';
    dir='twopass';
    instabilityfix = 'reduce';
    Flp = cfg.flp;

    tmpfilt = tmp;
    %nans = isnan(tmpfilt);
    %tmpfilt(nans) = 0;
    tmpfilt = ft_preproc_lowpassfilter(tmpfilt, fsample, Flp, N, type, dir, instabilityfix);
    %tmpfilt(nans) = nan;
else
    tmpfilt = tmp;
end

%interp segments
tmp2 = reshape(tmpfilt,szorig);
if cfg.dointerp
    icfg = [];
    icfg.timwin = cfg.interptoi;
    icfg.method = 'cubic';
    icfg.fsample = 1000;
    %in2.sta_trial_all(id) = spiketriggeredinterp(in2.sta_trial_all(id),icfg);
    
    sta_tmp = sta;
    sta_tmp.trial = tmp2;
    sta_tmp = spiketriggeredinterp(sta_tmp,icfg);
    sta.trial = sta_tmp.trial;
else
    sta.trial = tmp2;
end






