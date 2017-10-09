function ana_lfp_psd_all_time_windows(pow_all,foi,figpath)
% ana_lfp_psd_all_time_windows(pow_all,foi,figpath)



%% ------------------------------------------------------------
%extract summary stats
% ------------------------------------------------------------
freq = pow_all.freq;
psd = pow_all.power;
N = size(pow_all,1);
toi = pow_all.toi;
time = mean(toi,2);
ntoi = size(toi,1);

% for itime=1:ntoi
%     [psd2(:,:,itime),~,freqpeaksel(:,:,itime)] = norm_extract_peaks(psd(:,:,itime),freq,foi);
% end
[psd2,freqpeaksel,~] = norm_extract_peaks(psd,freq,foi);

selstr = {'theta', 'beta','theta & beta','no theta/beta','all'};


%% ------------------------------------------------------------
% PLOTS
% ------------------------------------------------------------
disp('plotting...')

xlim = [freq(1) freq(end)];

% ------------------------------------------------------------
% plot average PSD in all time bins
figure
nr = 5; nc=ntoi; ns=0;
h = [];
for isel = 1:5
    for itime=1:ntoi
        if isel==1
            sel = freqpeaksel(:,1,itime) & ~freqpeaksel(:,2,itime);
        elseif isel==2
            sel = ~freqpeaksel(:,1,itime) & freqpeaksel(:,2,itime);
        elseif isel==3
            sel = freqpeaksel(:,1,itime) & freqpeaksel(:,2,itime);
        elseif isel==4
            sel = ~freqpeaksel(:,1,itime) & ~freqpeaksel(:,2,itime);
        else
            sel = true(size(psd2,1),1);
        end
        
        p = psd2(sel,:,itime);
        nsel = sum(sel);
        
        [mu,se] = avganderror(p,'median',1,1,2000);

        ns = itime + nc*(isel-1);        
        subplot(nr,nc,ns)

        htmp = shadedErrorBar(freq,mu,se);
        h(isel,itime) = gca;

        xlabel('freq')
        ylabel('median norm power')
        str = sprintf('%s\ntoi=%s,n=%g',selstr{isel},mat2str(toi(itime,:)),nsel);
        title(str)

        axis square
    end
end
set_bigfig(gcf);
setaxesparameter(h,'ylim',[0 1])
setaxesparameter(h,'xlim',xlim)

%save
if ~isempty(figpath)
    checkmakedir(figpath)
    sname = [figpath '/lfp_psd_time_windows'];
    save2pdf(sname,gcf)
end

