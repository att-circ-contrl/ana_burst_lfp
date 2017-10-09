function out = ana_firingrate_binnedByPower(list,datadir,foi,nbin,toiwin,plotFig,figpath)
%  out = ana_firingrate_binnedByPower(list,datadir,foi,nbin,toiwin,plotFig)
%  out = ana_firingrate_binnedByPower(list,datadir,foi,nbin,toiwin,plotFig,figpath)

disp('------------------------------------------------------------')
str = sprintf('firing rate binned by local power\nnbins=%g, %sHz, toiwin=%s sec',...
    nbin,mat2str(foi),mat2str(toiwin));
disp(str)
disp('------------------------------------------------------------')

cd(datadir)

%toiwin = [-0.1 0.1];
%nbin = 4;
bins = 0:100/nbin:100;
cellstr = {'ns','bs','all'};
celltype = [list.celltype];
normtype = 'range';

if 1
    fr_pow_bin = [];
    pow_split = [];

    %try, poolobj = parpool(3); endft_preproc_lowpassfilter
    for id=1:numel(list)
        disp( ['cell: ' num2str(id)] )
        
        name = list(id).stsname;
        in = load(name);

        spectrum = in.sts_cue.fourierspctrm{1};

        pow = abs(spectrum).^2;
        pow = squeeze(pow);
        
        %find power bins, split in percetiles
        pp = prctile(pow,bins,1);
        
        prc = nan(size(pow));
        for ifreq=1:size(pow,2)
            for ibin=1:nbin
                selbin = pow(:,ifreq) > pp(ibin,ifreq) & pow(:,ifreq) <= pp(ibin+1,ifreq);
                prc(selbin,ifreq) = ibin;
            end
        end
        
        %get firing rate locked to each spike
        tr2 = in.sts_cue.trial{1};
        t = in.sts_cue.time{1};

        localFR = [];        
        for ispk=1:numel(tr2)
            t2 = t;
            tt = t2(ispk);
            t2 = t2 - tt;
            
            sel1 = tr2==tr2(ispk);
            sel2 = t2 >=toiwin(1) & t2<=toiwin(2);
            sel3 = sel1 & sel2;
            
            localFR(ispk) = (sum(sel3)-1) ./ diff(toiwin);
        end
        
        %average firing rate by perctile
        prcFR = nan(nbin-1,size(pow,2));
        for ifreq=1:size(pow,2)
            for ibin=1:nbin
                s = prc(:,ifreq)==ibin;
                tmp = nanmean(localFR(s));
                prcFR(ibin,ifreq) = tmp;
            end
        end

        %store
        fr_pow_bin(id,:,:) = prcFR;
    end
    
end

%----------------------------------------------------------------------
%dont adjst raw power
freqoi = in.sts_cue.freq;

fr_pow_bin3 = [];
for id=1:size(fr_pow_bin,1)
    for ifreq=1:size(foi,1)
        %select
        selfreq = selectNearestToBounds(freqoi,foi(ifreq,:));
        tmp = squeeze(fr_pow_bin(id,:,selfreq));
        tmp = nanmean(tmp,2);
        
        %normalize
        if strcmp(normtype,'range')
            tmp = normalizerange(tmp);
        elseif strcmp(normtype,'zscore')
            tmp = zscore(tmp);
        end
        
        %store
        fr_pow_bin3(id,:,ifreq) = tmp;
    end
end

%plot
if plotFig
    figure
    nr = 2; nc=3;
end

mu_all = [];
se_all = [];
kwp_all = [];

for icell=1:3
    for ifreq=1:size(foi,1)
        if icell<3; selcell = celltype==icell;
        else selcell = celltype == 1 | celltype==2;
        end
        
        tmp = fr_pow_bin3(selcell,:,ifreq);
        
        [mu,se] = avganderror(tmp,'median',1,1);
        x = mean( [bins(1:end-1);bins(2:end)] );
        kwp = kruskalwallis(tmp,[],'off');
        
        
        str = sprintf('%s,n=%g,%sHz: KWp=%.3g',...
            cellstr{icell},sum(selcell),mat2str(foi(ifreq,:)),kwp);
        disp(str)
        
        %store
        mu_all(icell,ifreq,:) = mu;
        se_all(icell,ifreq,:) = se;
        kwp_all(icell,ifreq) = kwp;
        
        %plot
        if plotFig
            ns = icell + (ifreq-1)*nc;
            subplot(nr,nc,ns)
            shadedErrorBar(x,mu,se,{'ko-'});

            str = sprintf('firing rate, norm %s\n%s, %sHz\nKurskal-Wallis p=%.3g',...
                normtype,cellstr{icell},mat2str(foi(ifreq,:)),kwp);
            title(str)
            ylabel('norm FR')
            xlabel('power percentile centre')
        end
        
        %set(gca,'xticklabel',xtick)
    end
end

if plotFig
    setaxesparameter('ylim')
end

if nargin > 5 && ~isempty(figpath)
    checkmakedir(figpath)
    sname = [figpath '/firingRate_binnedByPower_nbin' num2str(nbin) '_norm' normtype];
    save2pdf(sname)
end

%output
out = [];
out.bins = bins;
out.fr_pow_bin = fr_pow_bin3;
out.normtype = normtype;
out.mu_all = mu_all;
out.se_all = se_all;
out.kwp_all = kwp_all;
