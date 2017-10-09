%plot power across all cells
%selectdir = '/Volumes/DATA/DATA_BURST/RES_BURST_revision/ana_burst_lfp';
selectdir = '/Volumes/DATA/DATA_BURST/RES_BURST_revision3/ana_burst_lfp';
listdir = [selectdir '/select_burst'];

%selectdir = '/Volumes/DATA/comp_dieing/ana_sta_power/select_burst';
%listdir = selectdir;

figdir = [selectdir '/_figures2'];
checkmakedir(figdir)
cd(selectdir)

load('masterlist.mat')
load('power_all.mat')
load([listdir '/list.mat'])

if 1
    tmplist = masterlist;
else
    tmplist = downsample_list(list,'41cell');
end

%settings and stuff
itime = 1:2; %1:5;
isolationquality = [tmplist.isolationquality];
freq = tmplist(1).power.freq;
foi = [5 10; 16 30];

%selectionc
if 1
    selcell = ismember(isolationquality, [3]); %3
else
    selcell = true(size(isolationquality));
end
tmplist(~selcell) = [];

sellfp = ismember(power_all.dataname,{tmplist.lfpname});
power_all.power(~sellfp,:,:) = [];
power_all.dataname(~sellfp) = [];
power_all.channel(~sellfp) = [];
power_all.ntrls(~sellfp) = [];

pcfg = [];
pcfg.threshscale = 0.5;
pcfg.pkdetection = 'findpeaks';
pcfg.freq = freq;
pcfg.fscale = 0;

%main
psd = [];
psd = power_all.power(:,:,itime);

dpsd = ainorm(psd(:,:,1),psd(:,:,2:end));

N = size(psd,1);

% ------------------------------------------------------------
% plots median theta, beta change
if 1
    figure
    nr = 2; nc = 1; ns=0;
    for ifreq=1:2
        selfreq = getseltoi(freq,foi(ifreq,:));

        tmp = dpsd(:,selfreq,:);
        tmp = squeeze(nanmean(tmp,2));

        [mu,se] = avganderror(tmp,'median',1,1);
        t = mean(power_all.toi(2:end-1,:),2);

        p=[];
        for it=1:numel(t)
            p(it) = signrank(tmp(:,it));
        end
        mup = mu;
        mup(p>0.05) = nan;

        ns = ns+1;
        subplot(nr,nc,ns)
        if numel(t)>1
            shadedErrorBar(t,mu,se,'ko-')
        else
            errorbar(t,mu,se,'ko')
        end
        hold all


        plot(t,mup,'ko','markerfacecolor','k')

        tstr = sprintf('n=%g,power, %s Hz, change from baseline %ss',...
            N,mat2str(foi(ifreq,:),3),mat2str(power_all.toi(1,:),3));
        title(tstr)
        xlabel('time bin')
        ylabel('AI power')

        set(gca,'xtick',t)
    end

    sname = [figdir '/lfpPower_withAttn_' num2str(N)];
    save2pdf(sname,gcf)
end

% ------------------------------------------------------------
% plot example spectra

if 1
    figdir2 = [figdir '/sample_spectra'];
    checkmakedir(figdir2)
    
    itime = 6;
    pow = power_all.power;
    [normPow,pks] = normalizepsd(power_all,itime,pcfg);
    
    for ii=1:size(pow,1)
        a = squeeze(pow(ii,:,itime));
        b = squeeze(normPow(ii,:));
        p = pks{ii};
        
        %plot raw
        figure
        subplot(1,2,1)
        plot(freq,a)
        
        xlabel('freq')
        ylabel('raw pow')
        str = sprintf('%s',power_all.dataname{ii});
        title(str)
        axis square
        
        % plot processed
        subplot(1,2,2)
        plot(freq,b)
        hold all
        plot(p,b(ismember(freq,p)),'k^')
        
        
        xlabel('freq')
        ylabel('norm pow')
        title('power, scaled by 1/f, norm to [0 1]')
        axis square
        
        setaxesparameter('xlim',round([freq(1)-1, freq(end)+1]));
        
        %save
        sname = [figdir2 '/' power_all.dataname{ii} '_spectra'];
        save2pdf(sname,gcf)
        close(gcf)
        
        x=1;
    end

    
end

