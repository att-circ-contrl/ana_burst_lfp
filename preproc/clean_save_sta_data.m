function clean_save_sta_data(list,outlistpath,inpath,outpath,suffix,ccfg)
% clean_save_sta_data(list,inpath,outpath,suffix,cfg)

disp('preprocessing on selected cell STAs...')

%checks
ccfg = checkfield(ccfg,'replacenans',0);
ccfg = checkfield(ccfg,'dolowpassfilt',0);
ccfg = checkfield(ccfg,'dointerp',0);
ccfg = checkfield(ccfg,'interptoi',[-0.005, 0.005]);
ccfg = checkfield(ccfg,'flp',100);
ccfg = checkfield(ccfg,'lfptoi',[]);
ccfg = checkfield(ccfg,'spiketoi',[]);

if strcmp(outlistpath(end-4:end),'.mat')
    outlistpath = [outlistpath '.mat'];
end

%main
outlist = list;
for n=1:numel(list)
    name = list(n).name;
    disp([num2str(n) ': ' name])
    
    in = [inpath '/' name '_sta.mat'];
    outname = [name '_sta' suffix '.mat'];
    out = [outpath '/' outname];
    
    %load in data
    load(in)
    
    disp('deleting spikes...')
    %choose spikes to deletethat fall outside the analysis window
    if ~isempty(ccfg.spiketoi)
        spikeInWin = sta_cue.origtime >= ccfg.spiketoi(1) & sta_cue.origtime <= ccfg.spiketoi(2);
    else
        spikeInWin = false(size(sta_cue.trial,1));
    end
    
    %delete spikes that dont have enough concurrent sampled LFP
    if ~isempty(ccfg.lfptoi)
        %downsample first
        seltime = sta_cue.time >= ccfg.lfptoi(1) & sta_cue.time <= ccfg.lfptoi(2);
        sta_cue.time(~seltime) = [];
        sta_cue.avg(~seltime) = [];
        sta_cue.trial(:,:,~seltime) = [];
        
        %check for nans
        selnan = any(isnan(sta_cue.trial),3);
    else
        selnan = false(size(sta_cue.trial,1),1);
    end
    
    %only consider the nonburst and first burst of a spike
    selspk = list(n).spike.selburst | list(n).spike.selnonburst;
    
    %delet those spikes
    del = ~( selspk & spikeInWin & ~selnan );
    sta_cue.origtime(del) = [];
    sta_cue.origtrial(del) = [];
    sta_cue.trial(del,:,:) = [];
    
    %update the list
    outlist(n).fullname = outname;
    outlist(n).spike.selspikes = ~del;
    outlist(n).spike.origtime(del) = [];
    outlist(n).spike.origtrial(del) = [];
    outlist(n).spike.selnonburst(del) = [];
    outlist(n).spike.selburst(del) = [];
    outlist(n).spike.Binfo.burstVector{1}(del) = [];
    
    %replace nans?
    tmp = squeeze( sta_cue.trial );
    if ccfg.replacenans
        disp('replacing missing data with mean...')
        for it=1:size(tmp,1)
           nans = isnan(tmp(it,:)); 
           mu = mean(tmp(it,~nans));
           tmp(it,nans) = mu;
        end
    end
    
    %filter
    szorig = size(sta_cue.trial);
    if ccfg.dolowpassfilt
        fprintf('lowpass filter at %.3g Hz...\n',ccfg.flp)
        N = 4;
        fsample = 1000;
        type = 'but';
        dir='twopass';
        instabilityfix = 'reduce';
        Flp = ccfg.flp;

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
    if ccfg.dointerp
        icfg = [];
        icfg.timwin = ccfg.interptoi;
        icfg.method = 'cubic';
        icfg.fsample = 1000;

        sta_tmp = sta_cue;
        sta_tmp.trial = tmp2;
        sta_tmp = spiketriggeredinterp(sta_tmp,icfg);
        sta_cue.trial = sta_tmp.trial;
    else
        sta_cue.trial = tmp2;
    end
    
    %add this to make it compatible later
    sta_cue.eventstr = {'nonburst','burst'};
    
    %save
    sta_cue.ccfg = ccfg;
    save(out,'sta_cue','ccfg')
end

list = outlist;
save(outlistpath,'list')
