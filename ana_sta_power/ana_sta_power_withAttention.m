function ana_sta_power_withAttention(stspow_pre, stspow_post, foi)
% ana_sta_power_withAttention(stspow_pre, stspow_post, foi)

disp('--------------------------------------------------------')
disp('change in STA power with attention')
disp('--------------------------------------------------------')

%extract
freq = stspow_pre.freq;
pow1 = stspow_pre.pow_all;
pow2 = stspow_post.pow_all;

% AI difference
ai = ainorm(pow1,pow2);

for ifreq=1:size(foi,1)
   selfreq = selectNearestToBounds(freq,foi(ifreq,:));
   tmp = nanmean(ai(:,selfreq),2);

   
   [mu,se] = avganderror(tmp,'median',1,1,2000);
   p = signrank(tmp);
   
   str = sprintf('%s STA power difference: %.3g + %.3g SE, p=%.3g',...
       mat2str(foi(ifreq,:)),mu,se,p);
   disp(str)
end


