function ana_corr_lv_stapow(stspow,spkinfo,foi)
% ana_corr_lv_stapow(stspow,spkinfo,foi)

%foi = [5 10; 16 30];
%stspow = stspow_post;

%settings
corrtype = 'spearman';

%extract info
pow_all = stspow.pow_all;
freq = stspow.freq;
lv = [spkinfo.localVar]';

for ifreq=1:size(foi,1)
    %selfreq = selInBounds(freq,foi(ifreq,:));
    selfreq = selectNearestToBounds(freq,foi(ifreq,:));
    pow = nanmean(pow_all(:,selfreq),2);
    
    [r,p] = corr(pow,lv,'type',corrtype);
    
    str = sprintf('%s, r=%.3g, p=%.3g',...
        mat2str(foi(ifreq,:)),r,p);
    disp(str)
    
end