function ana_lfp_power_timeresolved(pow_all,foi,figpath,doFig)
% ana_lfp_power_timeresolved(pow_all,foi,figpath)
% ana_lfp_power_timeresolved(pow_all,foi,figpath,doFig)

%init
if nargin <4; doFig=1; end

psd = pow_all.power;
freq = pow_all.freq;
toi = pow_all.toi;
time = mean(toi,2);

% plot average theta/beta, in time
%take the un-normalized psd

if doFig
    figure
    nr = 2; nc=1; h=[];
end

ibase = 1;
time2 = time(2:end);
for ifreq=1:size(foi,1)
    selfreq = selInBounds(freq,foi(ifreq,:));
    tmp = psd(:,selfreq,2:end);
    tmp_base = psd(:,selfreq,ibase);
    
    d = ainorm(tmp_base,tmp);
    d = nanmean(d,2);
    d = squeeze(d);

%     tmp = squeeze(nanmean(psd(:,selfreq,2:end),2));
%     tmp_base = squeeze(nanmean(psd(:,selfreq,ibase),2));
%     d = ainorm(tmp_base,tmp);
     
    [mu,se] = avganderror(d,'median',1,1,2000);
    prop_reduced = sum(d<0);

    stest = [];
    for it=1:size(d,2)
        stest(it) = signrank(d(:,it));
    end
    mup = mu;
    mup(stest>0.05) = nan;
    
    %show some info in the command window
    disp(['***** ' mat2str(foi(ifreq,:)) 'Hz *****'])
    for it=1:size(d,2)
        str = sprintf('%ss: p=%.4g, prop>base=%g, AI=%.4g + %.4gSE',...
            mat2str(toi(it+1,:)),stest(it),prop_reduced(it),mu(it),se(it));
        disp(str)
        
    end
    
    %plot
    if doFig
        subplot(nr,nc,ifreq)
        shadedErrorBar(time2,mu,se,{'ko-'})
        hold on
        plot(time2,mup,'k.','markersize',15)

        set(gca,'xtick',time2,'xticklabel',time2)
        ylabel('AI power')
        xlabel('time from attention cue')
        str = sprintf('Median change in power (AI), %s Hz', mat2str(foi(ifreq,:)));
        title(str)
        h(ifreq) = gca;
    end
end


%save
if ~isempty(figpath) && doFig
    setaxesparameter(h,'ylim')
    set_bigfig(gcf)

    checkmakedir(figpath)
    sname = [figpath '/lfp_psd_timeresolved'];
    save2pdf(sname,gcf)
end
    
