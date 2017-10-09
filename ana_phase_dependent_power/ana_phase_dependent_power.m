function out = ana_phase_dependent_power(pdp,ang_stats,figpath,doFig)
% out = ana_phase_dependent_power(pdp,ang_stats)
% out = ana_phase_dependent_power(pdp,ang_stats,figpath)
% out = ana_phase_dependent_power(pdp,ang_stats,figpath,doFig)


%% settings
if nargin<3 || isempty(figpath)
    saveFig = 0;
else 
	saveFig = 1;
end
if nargin>3
    if numel(doFig)<2; error('which figures do you want to plot?'); end
else
    doFig = [1 1];
end

nperm = 1000;

%extract info
pha_dep_pow = pdp.pha_dep_pow;
freq = pdp.freq;
%freq = 5:0.5:30;
bincentre = pdp.bincentre;
eventstr = pdp.eventstr;
foi = pdp.foi;
nbins = numel(bincentre);

list = pdp.list;
celltype = [list.celltype];
cellstr = {'ns','bs','all'};

raystats = ang_stats.raystats;

%% --------------------------------------------------------
% plot stats on cosine
if doFig(1)
  
    cols = get_safe_colors();
    cols = cols([1 4],:);
    if 1
        icalc=0;
        cosstats_all = {};
        for icell=1:2
            if icell<3
                selcell = celltype==icell;
            else
                selcell = true(size(celltype));
            end

            for ifreq=1:size(foi,1)
                
                %consider only cells with sign locking
                if 1
                    selfreq = selectNearestToBounds(freq,foi(ifreq,:));
                    tmp = raystats(:,selfreq) < 0.05;
                    sellock = any(tmp,2)';
                end

               
    
                for ievent = 1:2
                   
                    icalc = icalc+1;
                    disp( ['calulation # ' num2str(icalc)] )
                    
                    selall = selcell & sellock;
                    dat = squeeze(pha_dep_pow(selall,:,ifreq,ievent));

                    %stats
                    scfg = [];
                    scfg.avgtype = 'median';
                    scfg.bincentre = bincentre;
                    scfg.nperm = nperm;
                    scfg.freq = foi(ifreq,:);
                    scfg.ampstats = 1;
                    scfg.shiftstats = 1;

                    cosstats_all{icell,ifreq,ievent} = phaDepPow_cosine_stats(dat,scfg);
                    cosstats_all{icell,ifreq,ievent}.selcell = selall;
                    
                end
            end
        end
    end
    
    %------------------------------------------------------------------
    %plot cosine stats
    figure;
    nr = 2; nc = size(foi,1)*2; ns = 0;
    hax = [];
    for icell=1:2
        for ifreq=1:size(foi,1)
            for ievent = 1:2
                cs =  cosstats_all{icell,ifreq,ievent};
                
                %things to plot
                mu = cs.mu;
                se = cs.se;
                
                mxx = -1 * cs.fitres.theta;
                mxy = cs.fitres(mxx);
                
                %plot
                ns = (icell-1)*nc + (ifreq-1)*size(foi,1) + ievent;
                subplot(nr,nc,ns)
                
                hl = errorbar(bincentre,mu,se,'ko','markerfacecolor',[0.6 0.6 0.6]);
                hold all
                hf = plot(cs.fitres);
                plot(mxx,mxy,'color',cols(ievent,:),'marker','v','markerfacecolor',cols(ievent,:),'markersize',5)
                
                set(hf,'color',cols(ievent,:),'linestyle', '-','linewidth',2)
                
                str = sprintf('median norm %sHz power\n%s, %s, n=%g,nbin=%g\namp=%.3g,p=%.3g\nshift(ms)=%.3g,p=%.3g',...
                    mat2str(foi(ifreq,:)), cellstr{icell}, eventstr{ievent}, cs.N, nbins,...
                    cs.A, cs.Ap, cs.shift, cs.shiftp);
                title(str)
                xlabel('phase bin relative to pref pha')
                ylabel('norm power')
                
                axis square
                hax(icell,ifreq,ievent) = gca;
                
                legend({'raw','cosfit'},'location','southoutside')
            end
        end
    end
    
    set_bigfig(gcf,[0.8 0.8])
    %setaxesparameter(hax,'xlim',[0 2*pi])
    setaxesparameter(hax,'xlim',[-1*pi pi])
    %setaxesparameter(hax,'ylim',[0.1 0.7])

    %
    for icell=1:2
        for ifreq=1:2
            setaxesparameter(hax(icell,ifreq,:),'ylim')
        end
    end
    %}
    plotcueline(hax,'xaxis',0)
    
    if saveFig
        sname = [figpath '/pha_dep_pow_cos_stats_nbin' num2str(nbins)];
        save2pdf([sname '.pdf'],gcf)
    end    
end
         




%% --------------------------------------------------------
% plot stats on cosine DIFFERENCE
if doFig(2)
    celltype =[list.celltype];
    cellstr = {'ns','bs','all'};
    
    if 1
        cosstats_all_diff = {};
        for icell=1:2
            for ifreq=1:size(foi,1)
                
                if icell<3; selcell = celltype==icell;
                else selcell = true(size(celltype));
                end
        
                if 1
                    selfreq = selectNearestToBounds(freq,foi(ifreq,:));
                    tmp = raystats(:,selfreq) < 0.05;
                    sellock = any(tmp,2)';
                end
                
                selall = selcell & sellock;
                
                dat1 = squeeze(pha_dep_pow(selall,:,ifreq,1));
                dat2 = squeeze(pha_dep_pow(selall,:,ifreq,2));

                %stats
                scfg_diff = [];
                scfg_diff.avgtype = 'median';
                scfg_diff.bincentre = bincentre;
                scfg_diff.nperm = nperm;
                scfg_diff.freq = foi(ifreq,:);
                scfg_diff.randstats = 1;
                scfg_diff.ang2ms = 1;

                cosstats_all_diff{icell,ifreq} = phaDepPow_cosine_difference_stats(dat1,dat2,scfg_diff);
                cosstats_all_diff{icell,ifreq}.selcell = selall;
            end
        end
    end
    
    %plot
    figure
    nr = 2; nc=2;
    hax = [];
    
    cols = [238, 67, 60;
        34, 102, 176] ./ 255;
    
    for ifreq=1:2
        
        % get stats
        Ad = [];
        Adse = [];
        Adp = [];
        Td = [];
        Tdse = [];
        Tdp = [];
        for icell=1:2
            Ad(icell) = cosstats_all_diff{icell,ifreq}.Ad;
            Adse(icell) = nanstd(cosstats_all_diff{icell,ifreq}.Adrand);
            Adp(icell) = cosstats_all_diff{icell,ifreq}.Adp;
            
            Td(icell) = cosstats_all_diff{icell,ifreq}.Td;
            Tdse(icell) = nanstd(cosstats_all_diff{icell,ifreq}.Tdrand);
            Tdp(icell) = cosstats_all_diff{icell,ifreq}.Tdp;

        end

        %plot amp
        subplot(nr,nc,ifreq)

        barwitherr(Adse,Ad);

        set(gca,'xticklabel',cellstr(1:2))

        str = sprintf('cosine amp diff\n(=burst-nonburst)\n%s Hz\nNS_p=%.3g, BS_p=%.3g',...
            mat2str(foi(ifreq,:)), Adp(1), Adp(2));
        title(str)
        ylabel('cosine amp diff')
        
        hax(1,ifreq) = gca;

        %plot shift
        subplot(nr,nc,ifreq+nc)

        barwitherr(Tdse,Td);


        set(gca,'xticklabel',cellstr(1:2))

        str = sprintf('cosine shift diff\n(=burst-nonburst)\n%s Hz\nNS_p=%.3g, BS_p=%.3g',...
            mat2str(foi(ifreq,:)), Tdp(1), Tdp(2));
        title(str)
        ylabel('cosine shift diff')
       
        hax(2,ifreq) = gca;
    end

    set_bigfig(gcf,[0.25 0.5])
    
    for n=1:2
        %setaxesparameter(hax(n,:),'ylim')
    end
    
    if saveFig
        sname = [figpath '/pha_dep_pow_cos_stats_diff_nbin' num2str(nbins)];
        save2pdf([sname '.pdf'],gcf)
    end 
    
    %{
    set_bigfig(gcf,[0.8 0.8])
    %setaxesparameter(hax,'xlim',[0 2*pi])
    setaxesparameter(hax,'xlim',[-1*pi pi])
    %setaxesparameter(hax,'ylim',[0.1 0.7])

    %
    for icell=1:2
        for ifreq=1:2
            setaxesparameter(hax(icell,ifreq,:),'ylim')
        end
    end

    plotcueline(hax,'xaxis',0)  
    %}
end

%% output
out = [];
out.cosstats_all = cosstats_all;
out.cosstats_all_diff = cosstats_all_diff;
out.scfg = scfg;
out.scfg_diff = scfg_diff;
out.foi = foi;
out.dim = 'cell-foi-event';

