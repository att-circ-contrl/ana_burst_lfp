function sta = spiketriggeredinterp(sta,cfg)
% sta = spiketriggeredinterp(sta,cfg)
%
% "sta" is a sturcture from ft_spiketriggeredaverage
% - this sturtcure has to have a "trial" field (ie when calling
%   ft_spiketriggeredaverage, keeptrials = 'yes'
%
% Copyright 2017, Benjamin Voloh

%dont give us a warning about using PCHIP instead of CUBIC 
warnid = 'MATLAB:interp1:UsePCHIP';
try warning('off',warnid); end %#ok

%inputs
cfg = checkfield(cfg,'timwin',[-0.001 0.002]);
cfg = checkfield(cfg,'method','nan');
cfg = checkfield(cfg,'interptoi',0.01);
cfg = checkfield(cfg,'fsample',1./mean(diff(sta.time)));
cfg = checkfield(cfg,'outputexamples',false);

if cfg.outputexamples
    cnte = 0;
    spkexample = cell(100,1);
end

%segment indices
interppad = 0;
if ~strcmp(cfg.method,'nan')
    interppad = round( cfg.interptoi*cfg.fsample);
end

st = nearest(sta.time,cfg.timwin(1));
fn = nearest(sta.time,cfg.timwin(2));
xall = st-interppad : fn+interppad;
x = [st-interppad:st-1, fn+1:fn+interppad];

%selections
channelsel = 1:size(sta.trial,2);
segsel = 1:size(sta.trial,1);

dat = sta.trial(segsel,channelsel,:);

%loop over all selected channels, segments
fprintf('interpolating over %ss from spike...\n',mat2str(cfg.timwin))
for is = 1:size(dat,1)
    for ich = 1:size(dat,2)
        y = squeeze(dat(is,ich,x));
        
        if any(isnan(y))
            continue
        end
        
        yi = interp1(x,y,xall,cfg.method);

        if cfg.outputexamples && (cnte<100)
            yall = squeeze(dat(is,ich,xall))';
            cnte = cnte+1;
            spkexample{cnte} = [yall; yi]; 
            %plot(x,y,'r.',xall,yall,'bo',xall,yi,'g-d')
        end

        %store
        dat(is,ich,xall) = yi;
    end
end

%save
sta.trial(segsel,channelsel,:) = dat;

if cfg.outputexamples
    spkexample(cnte+1:end) = [];
    sta.spkexample = spkexample;
end

%turn the warning back on
try warning('on',warnid); end %#ok
        
        