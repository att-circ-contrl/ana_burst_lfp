function sts = spiketriggeredspec_fft(sta,cfg)
% sts = spiketriggeredspec_fft(sta,cfg)
%
% - skimmed down version of ft_spiketriggeredspectrum
% "sta" is a sturcture from ft_spiketriggeredaverage
% - this sturtcure has to have a "trial" field (ie when calling
%   ft_spiketriggeredaverage, keeptrials = 'yes'
%
% adapted from Fieldtrip toolbox
% Copyright 2017, Benjamin Voloh

%inputs
cfg = checkfield( cfg, 'fsample', 1./mean(diff(sta.time)) );
cfg = checkfield( cfg, 'foilim', [0 150] );
cfg = checkfield( cfg, 'timwin', [sta.time(1), sta.time(end)] );
cfg = checkfield( cfg, 'taper', 'hanning' );

%select channels, trials, times

% **** dos ome stuff if we have adaptive window
selspk = 1:size(sta.trial,1);
selch = 1:size(sta.trial,2);
st = nearest(sta.time,round(cfg.timwin(1)*cfg.fsample)./cfg.fsample);
fn = nearest(sta.time,round(cfg.timwin(2)*cfg.fsample)./cfg.fsample);
%seltimwin = sta.time >= cfg.timwin(1) & sta.time <= cfg.timwin(2);
seltimwin = st:fn;

%construct taper
numsmp = numel(seltimwin);
if ~strcmp(cfg.taper,'dpss')
  taper  = window(cfg.taper, numsmp);
  taper  = taper./norm(taper);
else
  % not implemented yet: keep tapers, or selecting only a subset of them.
  taper  = dpss(numsmp, cfg.tapsmofrq);
  taper  = taper(:,1:end-1);            % we get 2*NW-1 tapers
  taper  = sum(taper,2)./size(taper,2); % using the linearity of multitapering
end
taper  = sparse(diag(taper));


%select frequencies
freqaxis = linspace(0, cfg.fsample, numsmp);
fbeg = nearest(freqaxis, cfg.foilim(1));
fend = nearest(freqaxis, cfg.foilim(2));

%make representation of spike
spike_repr = zeros(1,numsmp);
time       = linspace(cfg.timwin(1),cfg.timwin(2), numsmp);
spike_repr(ceil(numsmp/2)) = 1;
spike_fft = specest_nanfft(spike_repr, time);
spike_fft = spike_fft(fbeg:fend);
spike_fft = spike_fft./abs(spike_fft);
rephase   = sparse(diag(conj(spike_fft)));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute the spectra
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dat = sta.trial(selspk,selch,seltimwin);

%preaalocate output
sz = size(dat);
spectrum = nan(sz(1),sz(2),fend-fbeg+1);


for ich=1:size(dat,2)
    segment = reshape(dat(:,ich,:),sz(1),sz(3));
    
    % substract the DC component from every segment, to avoid any leakage of the taper
    segment = bsxfun(@minus,segment,nanmean(segment,2));

    % taper the data segment around the spike and compute the fft
    %segment_fft = specest_nanfft(segment * taper, time);
    segment_fft = fft(segment * taper,[],2);
    
    % select the desired output frquencies and normalize
    segment_fft = segment_fft(:,fbeg:fend) ./ sqrt(numsmp/2);

    % rotate the estimated phase at each frequency to correct for the segment t=0 not being at the first sample
    segment_fft = segment_fft * rephase;
    
    %store
    spectrum(:,ich,:) = segment_fft;
end


%save output in a format similar to ft_spiketriggeredspectrum
sts = [];
try, sts.label = sta.label; end %#ok
sts.time = sta.origtime;
sts.trial = sta.origtrial;
sts.fourierspctrm = spectrum;
sts.freq = freqaxis(fbeg:fend);
sts.cfg = cfg;
