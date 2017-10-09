function out = ana_sta_pow_timeresolve_noShuffle(list,datadir,figpath,freqoi,foi)
% ana_sta_pow_timeresolved(list,datadir,figpath)

%% ----------------------------------------------------------------------
% SETTINGS
% ----------------------------------------------------------------------
disp('------------------------------------------------------------------')
disp('STA power time-resolved')
disp('------------------------------------------------------------------')

cd(datadir)
checkmakedir(figpath)

eventstr = {'nonburst','burst'};
ncycle = 3;
%foi = [5 10; 16 30];
%freqoi = [5:0.5:30];

timeoi = -0.2:0.001:0.2;

cellstr = {'ns','bs','all'};
celltype = [list.celltype];

% randomization controls
controlForSpikeNumber = 0;
permuteConditionLabels = 0;
nperm = 200;

if permuteConditionLabels; shufflestr = '_shuffleLabel'; else shufflestr = ''; end

%% ----------------------------------------------------------------------
% MAIN
% ----------------------------------------------------------------------

powmu = nan(numel(list),numel(freqoi),numel(timeoi),2);
powmu_perm = nan(numel(list),numel(freqoi),numel(timeoi),2,nperm);

%try, poolobj = parpool(3); end
for id=1:numel(list)
    disp( ['*** cell: ' num2str(id)] )

    name = list(id).fullname;
    in = load(name);

 
    selburst = list(id).spike.selburst;
    selnonburst = list(id).spike.selnonburst;

    %get sepctrum
    timwin = ncycle ./ freqoi;
    tmp = squeeze(in.sta_cue.trial);
    time = in.sta_cue.time;

    [spectrum,~,freqoi2] = ft_specest_mtmconvol(...
            tmp,time,...
            'taper','hanning',...
            'timeoi',timeoi,...
            'timwin',timwin,...
            'freqoi',freqoi,...
            'verbose',0,...
            'pad',2);
        

    %take power
    pow_all = abs(spectrum).^2;
    pow_all = squeeze(pow_all);

    nspk = [sum(selnonburst),sum(selburst)];

    %control for spike number
    if controlForSpikeNumber
        nboots = 200;
        controlstr = '_controlspikenumber';

        minN = min(nspk);
        minN = [minN, minN];
    else
       nboots = 1;
       controlstr = '';

       minN = nspk;
    end

    %calculate average power
    fprintf('calculating average power')
    sz = size(pow_all);
    powmutmp = nan( [ sz(2:3), 2, nboots] );
    powmutmp_rand = nan( [sz(2:3), 2, nboots, nperm] );

    %stuff for permuting condition labels, to make it run faster
    if permuteConditionLabels
        ii = sum(selnonburst);
        sz = size(pow_all);

        ii1 = 1:ii;
        ii2 = ii+1:size(pow_all,1);
    end

    %can control for spike number here: each permutation, make a random
    %draw equal to the minimum spike number
    % - OR, if we dont want to do this, then we just make nboot=1 and the
    % minimum spike number equal to the observed number of burst and
    % nonburst spikes
    for nb=1:nboots
        dotdotdot(nb,20,nboots)
        %if nboots > 1; fprintf(['randomization ' num2str(nb)]); end

        for ievent=1:2
            selevent = list(id).spike.(['sel' eventstr{ievent}]);
            tmp = pow_all(selevent,:,:);

            selrand = randperm(size(tmp,1),minN(ievent));

            powmutmp(:,:,ievent,nb) = nanmean( tmp(selrand,:,:) );
        end

        %do we want to permute the condition labels too?
        if permuteConditionLabels
            %fprintf('permuting condition label')
            for np=1:nperm
                dotdotdot(np,ceil(nperm*0.1),nperm)

                %get indices:
                ind =  randperm(sz(1));
                ii1a = ind( ii1( randperm(numel(ii1),minN(1)) ) );
                ii2a = ind( ii2( randperm(numel(ii2),minN(2)) ) );

                %dat1 = dattmp(ii1a,:,:);
                %dat2 = dattmp(ii2a,:,:);

                dat1 = mean(pow_all(ii1a,:,:));
                dat2 = mean(pow_all(ii2a,:,:));

                powmutmp_rand(:,:,1,nb,np) = dat1;
                powmutmp_rand(:,:,2,nb,np) = dat2;
            end
        end
    end

    %store average power
    randdim = 4;
    powmu(id,:,:,:) = squeeze( nanmean(powmutmp,randdim) );
    powmu_perm(id,:,:,:,:) = squeeze( nanmean(powmutmp_rand,randdim) );

end

%% ----------------------------------------------------------------------
% PLOTS
% ----------------------------------------------------------------------

%cols = {'r','b'};
cols = get_safe_colors();
cols = cols([1 4],:);

%----------------------------------------------------------------------
%noramlize

if 0
    alph = 0;
    powmu = bsxfun(@times,powmu,freqoi2 .^ alph);
    powmu2 = normalize(powmu,[0 1],0);
    normstr = ['rangenorm1a' num2str(alph)];
else
    powmu2 = powmu;
    powmu_perm2 = powmu_perm;
end

%can downsample further, for visualization purposes
if 0
    toi2 = [-0.2 0.2];
    seltoi = selInBounds(timeoi,toi2);

    timeoi = timeoi(seltoi);
    powmu2(:,:,~seltoi,:) = [];
    powmu_perm2(:,:,~seltoi,:,:) = [];
end


%----------------------------------------------------------------------
%plot POWER over just theta, beta
if 1
     %plot
     figure;
     nr = 4; nc=3; ns=0;
     hax = []; haxd=[];
     
     doMultComp = 1;
     makeTransparent = 0;
     
     pow_time_all = {};
     for icell=1:3
        if icell<3
            selcell = celltype==icell;
        else
            selcell = true(size(celltype));
        end

        for ifreq=1:2
            str = sprintf('*** cell %g, freq %g',icell,ifreq);
            disp(str)
            
            selfreq = selectNearestToBounds(freqoi2,foi(ifreq,:));
            dat1 = squeeze( nanmean(powmu2(selcell,selfreq,:,1),2) );
            dat2 = squeeze( nanmean(powmu2(selcell,selfreq,:,2),2) );
            
            if permuteConditionLabels
                dat1shf = squeeze( nanmean(powmu_perm2(selcell,selfreq,:,1,:),2) );
                dat2shf = squeeze( nanmean(powmu_perm2(selcell,selfreq,:,2,:),2) );
            end
            
            %normalize
            if 1
                ii = size(dat1,2);
                tmp = cat(2,dat1,dat2);
                
                if permuteConditionLabels
                    tmpshf = cat(2,dat1shf,dat2shf);
                end
                
                if 1
                    tmp = zscore(tmp,[],2);
                    
                    if permuteConditionLabels
                        for np=1:size(tmpshf,3)
                            a = tmpshf(:,:,np);
                            tmpshf(:,:,np) = zscore(a,[],2);
                        end
                    end
                    
                    normstr = 'znorm';
                else
                    tmp = normalizerange(tmp,[-1 1],2); 
                    
                    if permuteConditionLabels
                        for np=1:size(tmpshf,3)
                            a = tmpshf(:,:,np);
                            tmpshf(:,:,np) = normalizerange(a,[-1 1],2);
                        end
                    end
                    
                    normstr = 'range';

                end
                
                dat1 = tmp(:,1:ii);
                dat2 = tmp(:,ii+1:end);   
                
                if permuteConditionLabels
                    dat1shf = tmpshf(:,1:ii,:);
                    dat2shf = tmpshf(:,ii+1:end,:); 
                end
            end
            
            %plot
            fcfg = [];
            fcfg.avgtype = 'median';
            fcfg.time = timeoi;
            fcfg.datstr = eventstr;
            fcfg.doMultComp = doMultComp;
            fcfg.comparetype = 'diff';
            fcfg.multcomptype = 'cluster';
            
            if permuteConditionLabels
                fcfg.dat1shf = dat1shf;
                fcfg.dat2shf = dat2shf;
            end

            fcfg.makeTransparent = makeTransparent;
            fcfg.title = sprintf( '%s, %sHz',...
                cellstr{icell},mat2str(foi(ifreq,:)) );
            fcfg.ylabel = 'norm power';
            fcfg.plotInSubplots = 1;
            fcfg.subplotrc = [nr nc 1];
            fcfg.plot1 = (ifreq-1)*2*nc + icell;
            fcfg.plot2 = (ifreq-1)*2*nc + icell + nc;

            [hax(icell,ifreq), haxd(icell,ifreq),datout] = plot_difference_multcompcorr(dat1,dat2,fcfg);
            pow_time_all{icell,ifreq} = datout;

        end
    end
    
    set_bigfig(gcf,[0.8 0.8])
     
    xlim = [timeoi(1), timeoi(end)];
    setaxesparameter(hax,'xlim',xlim)
    setaxesparameter(haxd,'xlim',xlim)
    for ifreq=1:2
        setaxesparameter(hax(:,ifreq),'ylim')
        setaxesparameter(haxd(:,ifreq),'ylim')
    end

    plotcueline(hax,'xaxis',0)
    plotcueline(haxd,'xaxis',0)
     
    %save
    sname = [figpath '/pow_slidewin_fft_ncycle' num2str(ncycle) '_' normstr '_multcomp' num2str(doMultComp) shufflestr];
    save2pdf(sname,gcf)
    
    sname2 = [figpath '/pow_slidewin_datout_ncycle' num2str(ncycle) '_' normstr shufflestr '.mat'];
    save(sname2,'pow_time_all','fcfg')
    
    
    %close(gcf)
end

%----------------------------------------------------------------------
%plot POWER over all frequencies
if 1

    figure;
    nr = 3; nc=4;
    hax = []; haxd = [];
    for icell=1:3
        disp(['cell: ' num2str(icell)])
        if icell<3
            selcell = celltype==icell;
        else
            selcell = true(size(celltype));
        end
        
        dat1 = powmu2(selcell,:,:,1);
        dat2 = powmu2(selcell,:,:,2);
        
        %normalize
        tmp = cat(3,dat1,dat2);
        ii = size(dat1,3);
        for id=1:size(tmp,1)
            for ifreq=1:numel(freqoi2)
                a = tmp(id,ifreq,:);
            
                mu = nanmean(a(:));
                sd = nanstd(a(:));
            
                tmp(id,ifreq,:) = (a-mu)./sd;
            end
        end
        dat1 = tmp(:,:,1:ii);
        dat2 = tmp(:,:,ii+1:end);
        
        %plot indiviudal stuff
        for ievent=1:2
            if ievent==1; dat=dat1;
            else dat = dat2;
            end

            mu = squeeze( nanmedian(dat) );

            ns = (icell-1)*nc + ievent;
            subplot(nr,nc,ns)
            imagesc(timeoi,freqoi2,mu)


            str = sprintf('%s,%s, norm power\nn=%g,ncycle=%g',...
                cellstr{icell},eventstr{ievent},sum(selcell),ncycle);
            title(str)
            xlabel('time')
            ylabel('freq')

            colorbar
            axis xy
            hax(icell,ievent) = gca;
            set(gca,'fontsize',10)

        end

        
        %plot difference with stats
        d = dat2 - dat1;
        mu = squeeze( nanmedian(d) );

        stest = [];
        for it=1:numel(timeoi)
            for ifreq=1:numel(freqoi2)
                a = squeeze(d(:,ifreq,it));
                stest(ifreq,it) = signrank(a);
            end
        end

        mask = ones(size(stest));
        mask(stest > 0.05) = 0.3;

        ns = (icell-1)*nc + 3;
        subplot(nr,nc,ns)
        imagesc(timeoi,freqoi2,mu,'alphadata',mask)

        str = sprintf('%s,diff in norm power\nn=%g,ncycle=%g',...
                cellstr{icell},sum(selcell),ncycle);
        title(str)
        xlabel('time')
        ylabel('freq')

        colorbar
        axis xy
        haxd(icell) = gca;
        set(gca,'fontsize',10)
        
        %plot p-value
        ns = (icell-1)*nc + 4;
        subplot(nr,nc,ns)
        imagesc(timeoi,freqoi2,stest)

        str = sprintf('%s,stats on norm power\nn=%g,ncycle=%g',...
                cellstr{icell},sum(selcell),ncycle);
        title(str)
        xlabel('time')
        ylabel('freq')

        colorbar
        axis xy
        set(gca,'fontsize',10)
        set(gca,'clim',[0 0.4])
        plotcueline('xaxis',0)
    end

    setaxesparameter(hax,'clim')
    setaxesparameter(haxd,'clim')
    plotcueline(hax,'xaxis',0)
    plotcueline(haxd,'xaxis',0)
    
    set_bigfig(gcf,[0.8 0.8])
    
    sname = [figpath '/pow_slidewin_fft_allfreq_ncycle' num2str(ncycle) '_multcomp' num2str(doMultComp)];
    save2pdf(sname,gcf)
end

%output
out = [];
out.pow_time_all = pow_time_all;
out.fcfg = fcfg;
out.dim = 'cell-foi';
out.powmu = powmu;
out.powmudim = 'cell-freqoi-timeoi-event';
out.timeoi = timeoi;
out.freqoi = freqoi2;
out.time = time;


  