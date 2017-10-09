function ang_stats = get_phase_stats3(list,datadir)
% ang_stats = get_phase_stats(list,datadir)

disp('----------------------------------------------------')
disp('getting phase stats...')
disp('----------------------------------------------------')

cd(datadir)
%checkmakedir(figpath)

eventstr = {'nonburst','burst'};

%dim = [numel(list),numel(freqoi)];
ppc_all = []; 
raystats = [];
ang_all = [];
ang_events_all = [];
r_all = [];
raystats_events = [];


%try, poolobj = parpool(3); end
for id=1:numel(list)
    disp( ['*** cell: ' num2str(id)] )

    in = load(list(id).stsname);
    sts = in.sts_cue;
    
    %get PPC stats
    %add this to make it work
    trialTimes = sts.cfg.cfg.timeStimChange;
    trialTimes = [ones(size(trialTimes)) * -0.75, trialTimes];
    sts.trialtime = trialTimes;
    
    cfg_stat               = [];
    cfg_stat.method        = 'ppc1'; % compute the Pairwise Phase Consistency
    cfg_stat.avgoverchan   = 'no'; 
    cfg_stat.timwin        = 'all'; % compute over all available spikes in the window 
    cfg_stat.spikechannel  = sts.label{1};

    for ievent=1:2
        cfg_stat.spikesel = list(id).spike.(['sel' eventstr{ievent}]);
        sts_stat = ft_spiketriggeredspectrum_stat(cfg_stat,sts);
        ppc_all(id,:,ievent) = sts_stat.ppc1;
    end
   
    % extract some info about the phases
    ph = squeeze( angle(sts.fourierspctrm{1}) );
    ang_all(id,:) = circ_mean(ph);
    r_all(id,:) = circ_r(ph);
    for ifreq=1:numel(sts.freq)
        raystats(id,ifreq) = circ_rtest(ph(:,ifreq));
    end
    
    for ievent=1:2
        sel = list(id).spike.(['sel' eventstr{ievent}]);
        ang_events_all(id,:,ievent) = circ_mean(ph(sel,:));
        for ifreq=1:numel(sts.freq)
            raystats_events(id,ifreq,ievent) = circ_rtest(ph(sel,ifreq));
        end
    end
end

%freqoi = [5:0.5:30];
freqoi = sts.freq;

%output
ang_stats = [];
ang_stats.freqoi = freqoi;
ang_stats.eventstr = eventstr;
ang_stats.cfg_stat = ppc_all;
ang_stats.list = list;
ang_stats.ppc_all = ppc_all;
ang_stats.raystats = raystats;
ang_stats.ang_all = ang_all;
ang_stats.ang_events_all = ang_events_all;
ang_stats.raystats_events = raystats_events;
ang_stats.r_all = r_all;
ang_stats.dim = '[cell-freq-event';

