function plot_ppc_indiv_spectra(ang_stat,figpath,plotSamples)
% plot_ppc_indiv_spectra(ang_stat,figpath)
% plot_ppc_indiv_spectra(ang_stat,figpath,plotSamples)


%% settings


list = ang_stat.list;
ppc_all = ang_stat.ppc_all;
raystats_events = ang_stat.raystats_events;
eventstr = ang_stat.eventstr;
cellstr = {'ns','bs','fz'};
celltype = [list.celltype];
freq = ang_stat.freqoi;

cols = get_safe_colors();
cols = cols([1,4],:);

if nargin<3
    plotSamples = {list.name};
end

spath = [figpath '/indiv_ppc_spectra'];
checkmakedir(spath)
    
%% plot individual PPC spectra
for id=1:numel(list)
    
    if ~any( strncmp( list(id).name,plotSamples,numel(list(id).name) ) )
       continue 
    end
        
    disp([num2str(id) 'plotting PPC spectrum for ' list(id).name])
   
    %convert to effect size
    if 1
        tmp = get_ppcToEffectsize(ppc_all);
    else
        tmp = ppc_all;
    end

    %plot
    figure
    hax = [];
    for ievent=1:2
        y = tmp(id,:,ievent);
        hax(ievent) = plot(freq,y,'color',cols(ievent,:));
        
        mx = tmp(id,:,:);
        mx = max(mx(:)) * (1 + 0.1*ievent);
        yp = ones(1,numel(freq))*mx;
        yp(raystats_events(id,:,ievent)>0.05) = nan;
        hold all
        plot(freq,yp,'.','color',cols(ievent,:),'markersize',10)
    end
 
    str = sprintf('ppc effect size\n%s, %s',cellstr{celltype(id)},list(id).name);
    title(str)
    xlabel('freq')
    ylabel('ppc efect size')

    ylim = get(gca,'ylim');
    set(gca,'ylim',[max([ylim(1),0]),ylim(2)])
    axis square
    
    legend(hax,eventstr,'location','southoutside')

    %save
    sname = [spath '/' list(id).name '_ppc'];
    save2pdf(sname,gcf)
    close(gcf)
end
