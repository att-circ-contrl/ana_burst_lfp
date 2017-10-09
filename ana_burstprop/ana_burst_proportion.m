function ana_burst_proportion(list,datadir,anaCells,figpath)
%------------------------------------------------------------------
%settings
cd(datadir) 

eventstr = {'nonburst','burst'};
makeTransparent = 0;
saveFig = ~isempty(figpath);
toi = [-0.5 1.8];

acfg = [];
acfg.baseline = [-0.5 0];
acfg.minnumtrials = 30;
acfg.win = 0.2;
acfg.time = -0.5:0.001:2;
    
[~,list,~] = selectCelltypes(list,anaCells);

%------------------------------------------------------------------
%get AI, rate info
if 1
   

    out_all = {};
    ai_all = [];
    burst_all = [];
    nonburst_all = [];
    for id=1:numel(list)
        name = list(id).name;
        disp([num2str(id) ': ' name])

        load([name '_sta.mat']);

        out = burst_prop_ai(sta_cue,acfg,list(id).spike);

        out_all{id} = out;
        ai_all(id,:) = out.ai_prop;
        burst_all(id,:) = out.rate_burst;
        nonburst_all(id,:) = out.rate_nonburst;
    end
end

        
%bit of preproc


seltime = selInBounds(out.time,toi);
selbaseline = out.selbaseline(seltime);

ai_all2 = ai_all(:,seltime);
burst_all2 = burst_all(:,seltime);
nonburst_all2 = nonburst_all(:,seltime);
time2 = out.time(seltime);

celltype = [list.celltype];
cellstr = {'ns','bs','all'};

%% ------------------------------------------------------------------
%plot final fig
if 1
        

    figure;
    set_bigfig(gcf,[0.8 0.8])
    nc = 4; nr = 3; ns=0;
    hax = [];

    cols = get_safe_colors();
    cols = cols([1 4],:);

%         burst_all2 = burst_all2(selcell,:);
%         nonburst_all2 = nonburst_all2(selcell,:);
%         ai_all2 = ai_all2(selcell,:);
    N = numel(list);

    %normalize
    zburst = burst_all2;
    zburst = bsxfun(@minus,zburst,nanmean(zburst(:,selbaseline),2));
    zburst = bsxfun(@rdivide,zburst,nanstd(zburst(:,selbaseline),[],2));

    znonburst = nonburst_all2;
    znonburst = bsxfun(@minus,znonburst,nanmean(znonburst(:,selbaseline),2));
    znonburst = bsxfun(@rdivide,znonburst,nanstd(znonburst(:,selbaseline),[],2));

    %% ------------------------------------------------------------
    %plot rates
    [mu1,se1] = avganderror(znonburst,'median',1,1);
    [mu2,se2] = avganderror(zburst,'median',1,1);

    [mu1pre,se1pre] = avganderror(nanmean(nonburst_all2(:,selbaseline),2),'median',[],2000);
    [mu1post,se1post] = avganderror(nanmean(nonburst_all2(:,~selbaseline),2),'median',[],2000);
    [mu2pre,se2pre] = avganderror(nanmean(burst_all2(:,selbaseline),2),'median',[],2000);
    [mu2post,se2post] = avganderror(nanmean(burst_all2(:,~selbaseline),2),'median',[],2000);

    
    ns = 1:nc-1;
    subplot(nr,nc,ns)

    h = [];
    htmp = shadedErrorBar(time2,mu1,se1',{'color',cols(1,:)},makeTransparent);
    h(1) = htmp.mainLine;
    hold all
    htmp = shadedErrorBar(time2,mu2,se2,{'color',cols(2,:)},makeTransparent);
    h(2) = htmp.mainLine;

    set(gca,'xlim',[time2(1), time2(end)])
    plotcueline('yaxis',0)
    plotcueline('xaxis',0)

%     str = sprintf('%s, n=%g\nmedian mean nonburst rate =%.3g spk/s\n...median mean burst rate =%.3g spk/s',...
%         anaCells,N,r1,r2);
    str = sprintf('%s cells, n=%g\n median mean rates:\nonburst, pre=%.3g + %.3gSE; post=%.3g + %.3gSE\nburst, pre=%.3g + %.3gSE; post=%.3g + %.3gSE',...
        anaCells,N,mu1pre,se1pre,mu1post,se1post,mu2pre,se2pre,mu2post,se2post);
    title(str)
    xlabel('time to cue')
    ylabel('median normalized rate')
    legend(h,eventstr(1:2),'location','northwest')

    %% ------------------------------------------------------------
    %plot AI
    [mu,se] = avganderror(ai_all2,'median',1,1);

    stest = [];
    for it=1:numel(time2)
        stest(it) = signrank(ai_all2(:,it));
    end
    mup = mu;
    mup(stest>0.05) = nan;


    ns = (1:nc-1) + nc;
    subplot(nr,nc,ns)

    shadedErrorBar(time2,mu,se);
    hold all
    plot(time2,mup,'k-','linewidth',3)

    ylim = max(abs(get(gca,'ylim')));
    ylim = [-ylim, ylim];
    set(gca,'xlim',[time2(1), time2(end)])
    set(gca,'ylim',ylim)
    plotcueline('yaxis',0)
    plotcueline('xaxis',0)

    str = sprintf('%s, %g,median AI burst prop, win=%g',anaCells,N,acfg.win);
    title(str)
    xlabel('time')
    ylabel('median AI')

    %% ------------------------------------------------------------
    %correlate AI with time
    corrtype = 'spearman';

    r=[];
    p=[];
    for ii=1:size(ai_all2,1)
        y = ai_all2(ii,:)';
        nans = isnan(y);

        x = time2(~nans)';
        y = y(~nans);
        try
            [r(ii), p(ii)] = corr(x,y,'type',corrtype);
        end
    end

    rpos = [sum(r>0 & p<0.05), sum(r>0 & p>0.05)];
    rneg = [sum(r<0 & p<0.05), sum(r<0 & p>0.05)];
    rall = [rpos;rneg]; % 

    mupos = mean(r(r>0));
    muneg = mean(r(r<0));

    [~,xp] = x2test(sum(rall,2),[],[],sum(rall)/2*ones(size(rall)));

    disp('> count, increasing and decreasing correlation of time/AI')
    disp(rall)
    rall = rall ./ numel(r);

    ns = nc;
    subplot(nr,nc,ns)
    bar(rall,'stacked')

    set(gca,'xticklabel',{'r>0','r<0'})
    str = sprintf('n=%g, %s corr,mu+=%.3g, mu-=%.3g\nX2p=%.3g,nbl=sign, yell=not sign',...
        numel(r),corrtype,mupos,muneg,xp);
    title(str)

    set(gca,'ylim',[0 1])

    %% ------------------------------------------------------------
    % prop +/- correlation of firing rate with time
    r2=[];
    p2=[];
    for ievent=1:2
        % time resolved correlation
        if strcmp(eventstr{ievent},'nonburst'); dat = znonburst;
        else dat = zburst;
        end

        for ii=1:size(dat,1)
            y = dat(ii,:);
            nans = isnan(y);

            x = time2(~nans);
            y = y(~nans);
            [r2(ii,ievent), p2(ii,ievent)] = corr(x',y','type',corrtype);
        end

        r3 = r2(:,ievent);
        p3 = p2(:,ievent);

        rpos = [sum(r3>0 & p3<0.05), sum(r3>0 & p3>0.05)];
        rneg = [sum(r3<0 & p3<0.05), sum(r3<0 & p3>0.05)];
        rall = [rpos;rneg]; % 

        mupos = mean(r3(r3>0));
        muneg = mean(r3(r3<0));

        [~,xp] = x2test(sum(rall,2),[],[],sum(rall)/2*ones(size(rall)));

        disp(['> count,' eventstr{ievent} ' increasing and decreasing correlation of time/AI'])
        disp(rall)
        rall = rall ./ numel(r3);

        ns = nc*2 + ievent;
        subplot(nr,nc,ns)
        bar(rall,'stacked')

        set(gca,'xticklabel',{'r>0','r<0'})
        str = sprintf('%s rate, n=%g\n%s corr,mu+=%.3g, mu-=%.3g\nX2p=%.3g,nbl=sign, yell=not sign',...
            eventstr{ievent},numel(r),corrtype,mupos,muneg,xp);
        title(str)

        set(gca,'ylim',[0 1])
    end

    %% ------------------------------------------------------------
    %only consider teh icnreasing proportion
    del = r<0;

    a=r2(~del,1);
    b=r2(~del,2);

    n1= sum(a<0 & b<0);
    n2= sum(a<0 & b>0);
    n3= sum(a>0 & b>0);


    nall = [n1,n2,n3]; % ./ sum(~del);

    exp = ones(size(nall)) * (numel(a)/numel(nall));
    [~,xp] = x2test(nall,[],[],exp);


    ns = nc*2 + 3;
    subplot(nr,nc,ns)

    str = {'dec nonburst-dec burst','dec nonburst-inc burst','inc nonburst-inc burst'};

    disp(cell2str(str))
    disp(nall)
    nall = nall./ numel(a);
    bar(nall)

    set(gca,'xticklabel',str)

    str = sprintf('reason for change in burst porportion\nn=%g,X2p=%.3g',...
        numel(a),xp);
    title(str)

    set(gca,'ylim',[0 1])

    %save

    if saveFig
        sname = [figpath '/burst_prop_ai_median_win' num2str(ceil(acfg.win * 1000)) '_' anaCells];
        save2pdf(sname,gcf);
    end

end





