function ana_phase_locking(ang_stats,foi,onlyUseSignLock,figpath)
% ana_phase_locking(ang_stats,foi,onlyUseSignLock,figpath)
%
% onlyUseSignLock: 0 =dont use, 1 =use sign, 2 =use non-sig, 

%extract data
if nargin<4
    figpath = [];
    saveFig = 0;
else
    saveFig = 1;
    checkmakedir(figpath)
end


eventstr = ang_stats.eventstr;
freq = ang_stats.freqoi;

cellstr = {'ns','bs','all'};
celltype = [ang_stats.list.celltype];

cols = get_safe_colors();
cols = cols([1 4],:);


ppc_all2 = ang_stats.ppc_all;
ang_all = ang_stats.ang_all;
r_all = ang_stats.r_all;
raystats = ang_stats.raystats;


signLockStr = {'','_onlyUseSignLock','_noSignLock'};

%selection of cells with significant locking
selsig = [];
for ifreq=1:size(foi,1)
    selfreq = selectNearestToBounds(freq,foi(ifreq,:));
    selsig(:,ifreq) = any(raystats(:,selfreq)<0.05,2)';
end


doMultComp = 0;
makeTransparent = 0;


%% -----------------------------------------------------------------
% plot PPC difference between burst vs nonburst
if 1
    disp('########################################');
    disp('plotting PPC difference between burst and nonburst')
    
    figure
    nr=2; nc=3; 
    hax =[]; haxd = [];
    for icell=1:3
        if icell<3
            selcell = celltype==icell;
        else
            selcell = true(size(celltype));
        end

        %select only the sign - locking cells
        if icell<3; selcell = celltype==icell;
        else selcell = true(size(celltype));
        end

        selsig2 = sum(selsig,2)'>0;

        if onlyUseSignLock==0; selsig2 = true(size(selsig2));
        elseif onlyUseSignLock == 2; selsig2 = ~selsig2;
        end
        selcell = selcell & selsig2;
              
        %stuff
        dat1 = ppc_all2(selcell,:,1);
        dat2 = ppc_all2(selcell,:,2);
        
        if 1
            for ifreq=1:size(dat1,2)
                dat1(:,ifreq) = get_ppcToEffectsize(dat1(:,ifreq));
                dat2(:,ifreq) = get_ppcToEffectsize(dat2(:,ifreq));
            end
            
            ppcstr = ' effectsize';
        else
            ppcstr = '';
        end

        fcfg = [];
        fcfg.avgtype = 'median';
        fcfg.time = freq;
        fcfg.datstr = eventstr;
        fcfg.doMultComp = doMultComp;
        fcfg.comparetype = 'diff';
        fcfg.permutetime = 0;
        fcfg.makeTransparent = makeTransparent;
        fcfg.title = sprintf('%s PPC %s,n=%g',cellstr{icell},ppcstr,sum(selcell));
        fcfg.ylabel = ['PPC' ppcstr];
        fcfg.plotInSubplots = 1;
        fcfg.subplotrc = [nr nc 1];
        fcfg.plot1 = icell;
        fcfg.plot2 = icell + nc;

        [hax(icell), haxd(icell),datout] = plot_difference_multcompcorr(dat1,dat2,fcfg);

        sta_time_all{icell} = datout;
    end
    
    set_bigfig(gcf,[0.7,0.7])
     
    %finish stuff
    xlim = [freq(1), freq(end)];
    setaxesparameter(hax,'xlim',xlim)
    setaxesparameter(hax,'ylim')
    
    setaxesparameter(haxd,'xlim',xlim)
    setaxesparameter(haxd,'ylim')

    plotcueline(hax,'yaxis',0)
    plotcueline(haxd,'yaxis',0)


    %save
    if saveFig
        sname =[figpath '/ppc_diff_full_' fcfg.avgtype '_multcomp' num2str(doMultComp)];
        save2pdf(sname,gcf)
    end
end


%% -----------------------------------------------------------------
% plot PPC difference for just THETA and BETA
if 1
    
    disp('########################################');
    disp('plotting BAND-SPECIFIC PPC difference between burst and nonburst')
    
    figure
    nr=1; nc=3; 
    hax =[];
    for icell=1:3
        mu = [];
        se = [];
        stest = [];
        N =[];
        for ifreq=1:2
            %select only the sign - locking cells
            if icell<3; selcell = celltype==icell;
            else selcell = true(size(celltype));
            end

            selsig2 = selsig(:,ifreq)';
            
            if onlyUseSignLock==0; selsig2 = true(size(selsig2));
            elseif onlyUseSignLock == 2; selsig2 = ~selsig2;
            end
            selcell = selcell & selsig2;
        
            selfreq = selectNearestToBounds(freq,foi(ifreq,:));
            tmp = ppc_all2(selcell,selfreq,:);
            
            if 1
                tmp = get_ppcToEffectsize(tmp);
            
                ppcstr = ' effectsize';
            else
                ppcstr = '';
            end
            

            d = tmp(:,:,2) - tmp(:,:,1);
            d = nanmean(d,2);

            avgtype = 'median';
            [mu(ifreq),se(ifreq)] = avganderror(d,avgtype,1,1,2000);
            stest(ifreq) = signrank(d);
            N(ifreq) = sum(selcell);
        end

        %disp( ['cell ' num2str(icell)] )
        %disp(stest)

        mup = mu;
        mup(stest>0.05) = nan;

        %plot
        ns = icell;
        subplot(nr,nc,ns)

        barwitherr(se,mu)
        hold all
        plot(1:2,mup,'o','markerfacecolor','y','markersize',10)

        set(gca,'xlim',[0 3])

        str = sprintf('difference in PPC %s\n(=burst-nonburst)\n%s,n=%s\n%s, p=%.3g\n%s, p=%.3g',...
            ppcstr,cellstr{icell},mat2str(N), mat2str(foi(1,:)), stest(1), mat2str(foi(2,:)), stest(2));
        title(str)
        ylabel( [avgtype ' ppc ' ppcstr ' diff'] )

        set(gca,'xticklabel',{'theta','beta',''})
        set(gca,'fontsize',14)

        hax(icell) = gca;
    end

    setaxesparameter('ylim')
    set_bigfig(gcf,[0.5 0.5])
    
    if saveFig
        sname = [figpath '/ppc_diff'];
        save2pdf(sname,gcf)
    end

end

%% -----------------------------------------------------------------
% output
out = [];
out.sta_time_all = sta_time_all;
out.dim = 'cell';

out.fcfg = fcfg;
out.foi = foi;



