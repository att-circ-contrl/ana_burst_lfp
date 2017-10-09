function ana_sta_pow_spikecentered(pow_in,figpath,foi)
% ana_sta_pow_spikecentered(pow_in,figpath,foi)



%% ------------------------------------------------------------

%get power
pow_all2 = pow_in.pow_all;
pow_split2 = pow_in.pow_split;
normstr = pow_in.normstr;
freqoi2 = pow_in.freq;

freqstrs = {};
for ii=1:size(foi,1)
    freqstr{ii} = mat2str(foi(ii,:));
end

%settings
list = pow_in.list;
eventstr = pow_in.eventstr;
cellstr = {'ns','bs','all'};
celltype = [list.celltype];

%% ------------------------------------------------------------
% STA power and difference in power b/t burst vs nonburst
if 1
    figure;
    nr = 2; nc=3; hax = [];

    for icell=1:3
        if icell<3
            csel = celltype==icell;
        else
            csel = true(size(celltype));
        end

        %plot power over all cells
        pow = pow_all2(csel,:);

        avgtype = 'median';
        mu = nanmedian(pow);
        out = getBootstrapStat(pow,2000,avgtype,1);
        se = out.se;

        subplot(nr,nc,icell)

        h = shadedErrorBar(freqoi2,mu,se,{'k-'},0);

        str = sprintf('%s,n=%g, POW over all spk\n1/%s',...
                cellstr{icell},sum(csel),normstr);
        title(str)
        xlabel('frew')
        ylabel('norm power')

        hax(icell) = gca;
        axis square

        set(gca,'xtick',5:5:30)
    end

    xlim = [freqoi2(1)-1, freqoi2(end)+1];
    setaxesparameter(hax,'xlim',xlim)
    setaxesparameter(hax,'ylim')



    %plot power over just theta and beta, comparing burst and nonbursts
    hax2 = [];
    for icell=1:3
        mu = [];
        se = [];
        pval = [];
        N = [];
        prop = [];
        p = [];
        for ifreq=1:2
            if icell<3
                csel = celltype==icell;
            else
                csel = true(size(celltype));
            end
            selfreq = selectNearestToBounds(freqoi2,foi(ifreq,:));

            dat1 = pow_split2(csel,selfreq,1);
            dat2 = pow_split2(csel,selfreq,2);

            d = nanmean( dat2 - dat1, 2 );

            mu(ifreq) = nanmedian(d);
            out = getBootstrapStat(d,2000,avgtype,1);
            se(ifreq) = out.se;

            pval(ifreq) = signrank(d);
            N(ifreq) = sum(csel);
            prop(ifreq) = sum(d>0)./sum(csel);
            p(ifreq) = nanmedian( (nanmean(dat2 ./ dat1,2) - 1) * 100 );

        end
        mup = mu;
        mup(pval>0.05) = nan;

        ns = nc + icell;
        subplot(nr,nc,ns)

        barwitherr(se,mu)
        hold all
        plot(1:2,mup)

        set(gca,'xticklabel',{'theta','beta'})

        str = sprintf('%s power\nP=%s\nN=%s\nprop diff>0=%s\nmedian perc change=%s',...
            mat2str(foi),mat2str(pval,3),mat2str(N),mat2str(prop,3), mat2str(p,3));
        title(str)
        ylabel('median power')

        axis square
        hax2(icell) = gca;
    end

    setaxesparameter(hax2,'ylim',[-0.07 0.07])
    set_bigfig(gcf,[0.5,0.5])

    sname = [figpath '/sta_pow_final_fig'];
    save2pdf(sname,gcf)
end



%% ------------------------------------------------------------
% show dyanmic range
if 1
    cols = get_safe_colors();
    cols = cols([1,4],:);
    
    figure
    nr=2; nc=3;
     for icell=1:3
        for ifreq=1:2
            if icell<3
                csel = celltype==icell;
            else
                csel = true(size(celltype));
            end
            selfreq = selectNearestToBounds(freqoi2,foi(ifreq,:));

            tmpdat1 = pow_split2(csel,selfreq,1);
            tmpdat2 = pow_split2(csel,selfreq,2);
            d = nanmean( tmpdat2 - tmpdat1, 2);
            p = signrank(d);
            
            
            dat1 = nanmean( tmpdat1, 2);
            dat2 = nanmean( tmpdat2, 2);
            
            [mu1,se1] = avganderror(dat1,'median',[],1);
            [mu2,se2] = avganderror(dat2,'median',[],1);
            
            %plot
            ns = icell + (ifreq-1)*nc;
            subplot(nr,nc,ns)
            
            if 1
                xtick = [1 2];
                ecfg = [];
                ecfg.color = cols;
                errorbar_withdata({dat1,dat2},ecfg,xtick,[mu1,mu2],[se1,se2],'k.','linewidth',2);
                plotstr = 'customPlot';
            elseif 0
                notBoxPlot([dat1,dat2],'style','line','markMedian',true)
%                 notBoxPlot2([dat1,dat2],'style','line','markMedian',true,...
%                     'interval','sem','MUfun',@median);
                plotstr = 'matPlot';
            else
                xtick = [1 2];
                errorbarjitter([dat1,dat2],gcf,'average','median','offset',0);
                plotstr = 'jitterPlot';
            end
            
            set(gca,'xtick',[1 2])
            set(gca,'xticklabel',{'nonburst','burst'})
            ylabel('norm pow')
            
            str = sprintf('%s dyanmic range\n%s, n=%g, p=%.g',...
                mat2str(foi(ifreq,:)),cellstr{icell},size(dat1,1),p);
            title(str)
            
        end
     end
     
     setaxesparameter('ylim',[0 1])
     set_bigfig(gcf,[0.5 0.5]);
     
     %save
     sname = [figpath '/pow_dynamicRange_' plotstr];
     save2pdf(sname,gcf)     
end

