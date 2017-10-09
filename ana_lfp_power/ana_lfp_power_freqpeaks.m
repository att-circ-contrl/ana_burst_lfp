function ana_lfp_power_freqpeaks(pow_all,foi,figpath)
% ana_lfp_power_freqpeaks(pow_all,foi,figpath)



%% ------------------------------------------------------------
%extract summary stats
% ------------------------------------------------------------
freq = pow_all.freq;
psd = pow_all.power;
N = size(psd,1);

[psd2,freqpeaksel,pks] = norm_extract_peaks(psd,freq,foi);
sel1 = freqpeaksel(:,1);
sel2 = freqpeaksel(:,2);
selstr = {'theta', 'beta','theta & beta','no theta/beta'};


%% ------------------------------------------------------------
% PLOTS
% ------------------------------------------------------------
disp('plotting...')

xlim = [freq(1) freq(end)];

figure
nr = 6; nc=5; ns=0;



% ------------------------------------------------------------
%plot sorteded psd
[~,imx] = max(psd2,[],2);
mxfreq = freq(imx);
[~,sortmx] = sort(mxfreq,'ascend');

psd_sort = psd2(sortmx,:);
x = freq;
y = 1:N;

ns = 1:nc-1;
ns = [ns; ns + 1*nc; ns + 2*nc; ns + 3*nc];
ns = ns(:);
%ns = 1:(nr-1)*(nc-1)-1;
subplot(nr,nc,ns)
imagesc(x,y,psd_sort)
hold all

%plot freq peaks
for n=1:N
    x = pks{sortmx(n)};
    y = n*ones(size(x));
    plot(x,y,'k^')
end
    
axis xy
colorbar

str = sprintf('n=%g, power (norm by max peak), sorted by max pow foi=%s',numel(pks), mat2str(foi));
title(str)
xlabel('freq')
ylabel('sorted LFP ID')

% ------------------------------------------------------------
%plot frequency resolved porpotion
prop = zeros(size(freq));
for ii=1:N
    sel = ismember(freq,pks{ii});
    prop(sel)  = prop(sel) + 1;
end

prop = prop ./ N;

ns = (1:nc-1) + (nr - 2)*nc;
%ns = (1:nc) + (nr - 1)*nc;
subplot(nr,nc,ns)

plot(freq,prop)
hold all

y = max(prop)*1.1;
for ifreq=1:size(foi)
    x = foi(ifreq,:);
    y2 = ones(size(x)) * y;
    
    plot(x,y2,'k','linewidth',2)
end

xlabel('freq')
ylabel('prop')

%axis square
set(gca,'xlim',xlim)

% ------------------------------------------------------------
%plot average PSD
mu = nanmedian(psd2);
se = getBootstrapStat(psd2,2000,'median',1);
se = se.se;

ns = (1:nc-1) + (nr - 1)*nc;
subplot(nr,nc,ns)

shadedErrorBar(freq,mu,se);

xlabel('freq')
ylabel('median norm power')

%axis square
set(gca,'xlim',xlim)

% ------------------------------------------------------------
%plot avergae psds
count = [];
for isel=1:4
    if isel==1
        sel = sel1 & ~sel2;
    elseif isel==2
        sel = ~sel1 & sel2;
    elseif isel==3
        sel = sel1 & sel2;
    else
        sel = ~sel1 & ~sel2;
    end

    count(isel) = sum(sel);

    %plot
    
    dat = psd2(sel,:);
    mu = nanmedian(dat);
    se = getBootstrapStat(dat,2000,'median',1);
    se = se.se;
    
    ns = (isel-1)*nc + nc;
    subplot(nr,nc,ns)
    shadedErrorBar(freq,mu,se);
    
    xlabel('freq')
    ylabel('median norm power')
    str = sprintf('n=%g, %s',sum(sel),selstr{isel});
    title(str)
    
    axis square
    set(gca,'xlim',xlim)
    set(gca,'ylim',[0 1])
end

% ------------------------------------------------------------
%pie chart
ns = nr*nc;
subplot(nr,nc,ns)
h=pie(count);

hText = findobj(h,'Type','text'); % text object handles
set(hText, 'fontsize',14)

percentValues = get(hText,'String'); % percent values
combinedstrings = strcat(selstr,':', percentValues'); % strings and percent values
oldExtents_cell = get(hText,'Extent'); % cell array
oldExtents = cell2mat(oldExtents_cell); % numeric array

for ih=1:length(hText)
    set(hText(ih),'string',combinedstrings{ih})
end

cols = get_safe_colors();
cols = cols([6 3 4 7],:);
hp = findall(h,'Type','patch');
for ih=1:numel(hp)
    set(hp(ih),'facecolor',cols(ih,:))
end

%save
set_bigfig(gcf,[0.5 1])
pause(0.5)

if ~isempty(figpath)
    checkmakedir(figpath)
    sname = [figpath '/lfp_pow'];
    save2pdf(sname,gcf)
end
    
