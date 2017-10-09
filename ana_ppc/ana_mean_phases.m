function ana_mean_phases(ang_stats,foi,onlyUseSignLock,figpath)
% ana_phase_locking(ang_stats,foi,onlyUseSignLock,figpath)
%
% onlyUseSignLock: 0 =dont use, 1 =use sign, 2 =use non-sig, 

%% settings
saveFig = 1;

checkmakedir(figpath)

eventstr = ang_stats.eventstr;
freq = ang_stats.freqoi;

cellstr = {'ns','bs','all'};
celltype = [ang_stats.list.celltype];

cols = get_safe_colors();
cols = cols([1 4],:);
nbins = 5;

% extract data
ang_all = ang_stats.ang_all;
ang_events_all = ang_stats.ang_events_all;
raystats = ang_stats.raystats;

%selection of cells with significant locking
signLockStr = {'','_onlyUseSignLock','_noSignLock'};

selsig = [];
for ifreq=1:size(foi,1)
    selfreq = selectNearestToBounds(freq,foi(ifreq,:));
    selsig(:,ifreq) = any(raystats(:,selfreq)<0.05,2)';
end


%% -----------------------------------------------------------------
% proportion of significant cells with locking
if 1
    disp('########################################');
    disp('proportion of cells with significant phase-locking')
    
    obs_orig = {};
    obs_all = [];
    ncell_all = [];
    x = [];
    p = [];
    for ifreq=1:2
        for icell=1:2

            selcell = celltype==icell;
            selfreq = selectNearestToBounds(freq,foi(ifreq,:));
        
            a = any(raystats(selcell,selfreq)<0.05,2);
            
            ii = (ifreq-1)*2;

            obs(1,icell) = sum(a);
            obs(2,icell) = sum(~a);
            obs_orig{icell} = a;

            ncell(icell) = sum(selcell);
            
            str = sprintf('%s,%s: %g/%g',...
                mat2str(foi(ifreq,:)),cellstr{icell},obs(1,icell),ncell(icell));
            disp(str)
        end
        
        obs_all = cat(2,obs_all,obs);
        ncell_all = cat(2,ncell_all,ncell);
        
        [x,p] = ztestproportion(obs_orig{1},obs_orig{2});
        
        str = sprintf('%s, Z-test (NS vs BS prop), p=%.3g',...
            mat2str(foi(ifreq,:)),p);
        disp(str);
    end
end


%% -----------------------------------------------------------------
% average phases
if 1
    disp('########################################');
    disp('average phases...')
    
    figure;
    nr = 2; nc = 2; ns = 0;
    hax = [];
    
    for ifreq=1:size(foi,1)
        a1 = [];
        a2 = [];
        r1 =[];
        r2 = [];
        
        disp('----------------------------------------')
        for icell=1:2
            selcell = celltype==icell;
            selfreq = selectNearestToBounds(freq,foi(ifreq,:));
        
            if onlyUseSignLock
                a = any(raystats(:,selfreq)<0.05,2)';
                selcell = selcell & a;
            end

            tmpa = ang_all(selcell,selfreq);
            tmp2 = circ_mean(tmpa,[],2);
            [lowB, upB, mu, cST] = circstat_confidenceOnMeanPhase_03(tmp2);
            st = mean([mu-lowB upB-mu]);
            
            str = sprintf('%s, %s: mu=%.3g, std=%.3g', ...
                cellstr{icell}, mat2str(foi(ifreq,:)), rad2ang(mu), rad2ang(st));
            disp(str)
            
            if icell==1; 
                a1 = tmp2;
            else
                a2 = tmp2;
            end
            
            lims = [0 0.2 1; 
                    0 0.5 1];
            ns=ns+1;
            subplot(nr,nc,ns)
            %circ_plot(tmp2,'hist',[],6,true,true,false,'linewidth',2,'color','r');
            polar_hist2(tmp2,nbins);
            str = sprintf('%s, %s\nn=%g',cellstr{icell},mat2str(foi(ifreq,:)),sum(selcell));
            title(str)
        end
        
        %p = circ_wwtest(a1,a2,r1,r2);
        [p,~,~] = watsons_U2_perm_test(a1,a2,1000);
        str = sprintf(' > Watson-william test for mu diff, p=%.3g',p);
        disp(str)
        
    end
    
    %setaxesparameter(hax,'xlim')
    if saveFig
        sname = [figpath '/avg_phases' signLockStr{onlyUseSignLock+1}];
        save2pdf(sname,gcf)
    end
end


%% -----------------------------------------------------------------
% compare average phase of burst vs nonburst 

if 1
    disp('########################################');
    disp('Comparison of average phase on burst vs nonburst...')
   
    ilim=0;
    lims = [0 0.3 1;0 0.6 1;
            0 0.5 1; 0 0.5 1];

    cols = get_safe_colors();
    cols = cols([1 4],:);
    cols(3,:) = [0 0 0];

    allevents = [eventstr, {'diff'}];
    onlyUseSignLock = 1;
    
    mus = [];
    for icell=1:2
        disp('----------------------------------------')

        figure;
        nr = 2; nc = 3; ns = 0;
        for ifreq=1:size(foi,1)
           
            ilim = ilim+1;
            for ievent=1:3

                selcell = celltype==icell;
                selfreq = selectNearestToBounds(freq,foi(ifreq,:));

                if onlyUseSignLock
                    sellock = any( squeeze(raystats(:,selfreq)) <0.05,2)';
                else
                    sellock = true(size(selcell));
                end
                selcell = selcell & sellock;


                if ievent<3
                    tmpa = ang_events_all(selcell,selfreq,ievent);
                    %tmpr = r_all(selcell,selfreq,ievent);
                    tmp2 = circ_mean(tmpa,[],2); 

                else
                    tmpa1 = ang_events_all(selcell,selfreq,1);
                    tmpa2 = ang_events_all(selcell,selfreq,2);
                    tmp2 = tmpa2 - tmpa1;
                    tmp2 = circ_mean(tmp2,[],2); 

                    statstr = 'medtest';
                    p = circ_medtest(tmp2,0);
                end

                [lowB, upB, mu, cST] = circstat_confidenceOnMeanPhase_03(tmp2);
                st = mean([mu-lowB upB-mu]);
                
                mu = rad2ang(mu);
                st = rad2ang(st);
                
                mus(icell,ifreq,ievent) = mu;
                cis(icell,ifreq,ievent) = st;
                
                str = sprintf('%s, %s, %s: mu=%.3g, std=%.3g', ...
                    cellstr{icell}, mat2str(foi(ifreq,:)), allevents{ievent},mu, st);
                if ievent==3; str = [str, ', Medtest-p=' num2str(p,3)]; end
                disp(str)
            
                %plot
                ns=ns+1;
                subplot(nr,nc,ns)
                if ievent<3
                    handles = polar_hist2(tmp2,nbins,[],[],[],lims(ilim,:));
                else
                    handles = polar_hist2(tmp2,nbins);
                end
                handles.obs.Color = cols(ievent,:);
                handles.mu.Color = cols(ievent,:);
                handles.mu.MarkerFaceColor = cols(ievent,:);
                handles.se.Color = cols(ievent,:);
                
                if ievent<3
                    str = sprintf('%s, %s\nn=%g\nmu=%.3g %.3gCI',...
                        cellstr{icell},mat2str(foi(ifreq,:)),sum(selcell),mu,st);
                    title(str)
                else
                    str = sprintf('burst-nonburst\n%s p=%.3g\nmu=%.3g %.3gCI',...
                        statstr,p,mu,st);
                    title(str)
                end
                
               
            end

        end

        %setaxesparameter(hax,'xlim')
        if saveFig
            sname = [figpath '/avg_event_phases_' cellstr{icell} signLockStr{onlyUseSignLock+1}];
            save2pdf(sname,gcf)
        end
    end
    
end
    