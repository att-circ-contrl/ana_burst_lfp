function ana_phase_prop_withAttention(ang_pre,ang_post,foi)
% ana_phase_prop_withAttention(ang_pre,ang_post,foi)


disp('----------------------------------------------------')
disp('comparing proportion with significant locking, pre to post...')
fprintf('\n')


%extract
list = ang_pre.list;
celltype = [list.celltype];
cellstr = {'ns','bs'};
freq = ang_pre.freqoi;
raystats1 = ang_pre.raystats;
raystats2 = ang_post.raystats;

%get proportions
c1 = [];
c2 = [];

for icell=1:numel(cellstr)
    selcell = celltype==icell;
    
    p = [];
    for ifreq=1:size(foi,1)
        %get counts
        selfreq = selectNearestToBounds(freq,foi(ifreq,:));
        selsig1 = any(raystats1(selcell,selfreq)<0.05,2)';
        c1 = sum(selsig1);

        selfreq = selectNearestToBounds(freq,foi(ifreq,:));
        selsig2 = any(raystats2(selcell,selfreq)<0.05,2)';
        c2 = sum(selsig2);
        
        %test for difference in proportion
        [~,p] = ztestproportion(selsig1,selsig2);
        prop = [c1,c2];
        
        str = sprintf('%s,n=%g,%sHz| prop1 vs 2= %s, p=%.3g',...
            cellstr{icell},sum(selcell),mat2str(foi(ifreq,:)),mat2str(prop),p);
        disp(str)
    end
end
