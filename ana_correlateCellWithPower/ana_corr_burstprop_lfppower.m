function out = ana_corr_burstprop_lfppower(list,pow_lfp,itime,foi,toi,figpath)
% out = ana_corr_burstprop_lfppower(list,pow_lfp,itime,foi,toi)
% out = ana_corr_burstprop_lfppower(list,pow_lfp,itime,foi,toi,figpath)

%% settings
%itime = 6;
%foi = [5 10; 16 30];
%toi = [0 2];

cellstr = {'ns','bs','all'};
celltype = [list.celltype];
corrtype = 'spearman';
freq = pow_lfp.freq;
zthresh = 3;

plotFig = 1;
if nargin > 5; plotFig = 1; end

%% -----------------------------------------------------------------
%correlate burst proportion with LFP power
%-----------------------------------------------------------------

disp('----------------------------------------------------------------')
disp('correlation burst porportion with LFP power')
disp('----------------------------------------------------------------')

%get burst proportion, lfp power
bp = [];
pow = [];
for n=1:numel(list)
    b = list(n).spike.selburst;
    nb = list(n).spike.selnonburst;
    t = list(n).spike.origtime;
    
    bp(n,1) = burstProportion(b,nb,t,toi);
    
    for ifreq=1:size(foi,1)
        ii = ismember(pow_lfp.lfpname,list(n).lfpname);
        
        if isempty(ii)
            error('no power for cell %s', list(n).name)
        end
        
        selfreq = selectNearestToBounds(freq,foi(ifreq,:));
        
        pow(n,ifreq) = nanmean(pow_lfp.power(ii,selfreq,itime));
    end
end


%plot
if plotFig
    figure
    nr = size(foi,1); nc=2;
    cols = {'b','r'};
end

for icell=1:2
    for ifreq=1:size(foi,1)
        if icell<3; selcell = celltype==icell;
        else selcell = true(size(celltype));
        end
        selcell = find(selcell);

        %take away ouliers
        xtmp = zscore( bp(selcell) );
        ytmp = zscore( pow(selcell,ifreq) );
        bad = abs(xtmp)>zthresh | abs(ytmp) > zthresh;
        selcell(bad) = [];
        
        %re-normalize with the good cells
        x = zscore( bp(selcell) );
        y = zscore( pow(selcell,ifreq) );
        
        [r,p] = corr(x,y,'type',corrtype);
        N = numel(x);
        
        str = sprintf('%s, n=%g, %s corr, %s power: r=%.3g,p=%.3g',...
            corrtype,N,cellstr{icell},mat2str(foi(ifreq,:)),r,p);
        disp(str)
        
        %plot
        if plotFig
            ns = icell + nc*(ifreq-1);
            subplot(nr,nc,ns)
            %scatter(x,y)
            %lsline
            plot(x,y,[cols{icell} 'o'],'markersize',5);
            hl = lsline;
            hl.Color = [0 0 0];

            str = sprintf('%s, %s, n=%g\n%s, p=%.3g',...
                cellstr{icell},mat2str(foi(ifreq,:)),N,corrtype,p);
            title(str)
            xlabel('z(burst prop')
            ylabel('z(pow')

            axis square
            
            %set(gca,'xlim',[-5 5],'ylim',[-2 4])
        end
        
    end
end

if plotFig && nargin > 5
    setaxesparameter('ylim')
    setaxesparameter('xlim')
    checkmakedir(figpath)
    
    sname = [figpath '/corr_burstprop_lfppower'];
    save2pdf(sname,gcf)
end

%% output
out = [];
out.freq = freq;
out.foi = foi;
out.itime = itime;
out.burstprop = bp;
out.power = pow;
out.list = list;
out.cellstr = cellstr;

