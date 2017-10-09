% perform time-freq analysis using fieldtrip
% - v2: updated trial selection: dont dlete trials
% - v3: update to use cfg, delte trials in data (undo v2)
% - v4: do some artifact rejection, count number of deleted trials
% - v6: adaptive timwin for STS
function RESDIR = get_sta_lfp_v01(nworkers,varargin)
dbstop if error


if nworkers > 1
    try
        matlabpool('open',nworkers); % open 10
    catch
        parpool(nworkers);
    end
    
    spmd
        [RESDIR,anacfgtmp,NUMSEL]  = save_burst_lfp(varargin{:});
    end
    
    anacfg = anacfgtmp{1};
    anacfg.datasets = cell(numel([NUMSEL{:}]),1);
    anacfg.ndiscardedtrials = nan(numel([NUMSEL{:}]),1);
    anacfg.discardedtrials = cell(numel([NUMSEL{:}]),2);
    for n=1:nworkers
        tmp = anacfgtmp{n};
        ind = NUMSEL{n};
        anacfg.datasets(ind) = tmp.datasets;
        anacfg.ndiscardedtrials(ind) = tmp.ndiscardedtrials(ind);
        anacfg.discardedtrials(ind,:) = tmp.discardedtrials(ind,:);
    end

    try
        matlabpool close
    catch
        delete(gcp('nocreate'))
    end
    
else
    [RESDIR,anacfg,~]  = save_burst_lfp(varargin{:});
end
    
%save cfg
sname = [varargin{4} '/anacfg.mat'];
save(sname,'anacfg')


function [RESDIR,anacfg,NUMSEL] = save_burst_lfp(MDIR, RESDIR,anacfg,rdir)
%settings
%}

if 0
    MDIR = '/Volumes/DATA_05'
elseif 0
    %MDIR = '/Volumes/DATA/DATA_BURST';
    MDIR = '/Volumes/DATA 1/DATA_BURST';
end 
MATDIR_1 = [MDIR '/RES_05/'];
MATDIR_2 = [MDIR '/RESOPX_02/'];
%RESDIR = [MDIR '/RES_BURST_07'];
%RESDIR = [MDIR '/' rdirstr];

if ~exist(RESDIR); mkdir(RESDIR); end
    
%checkfields
anacfg = checkfield(anacfg,'getdata','needit');
anacfg = checkfield(anacfg,'ststimwin','needit');
anacfg = checkfield(anacfg,'toipad','needit');
anacfg = checkfield(anacfg,'toistimchange',anacfg.toipad);
anacfg = checkfield(anacfg,'toipsd','needit');
anacfg = checkfield(anacfg,'foi','needit');
anacfg = checkfield(anacfg,'Flp',[]);
anacfg = checkfield(anacfg,'trls','needit');
anacfg = checkfield(anacfg,'testdata',[]);
anacfg = checkfield(anacfg,'staboundaryaction',[]);
anacfg = checkfield(anacfg,'stsboundaryaction',[]);
anacfg = checkfield(anacfg,'dointerpolation',0);


%convert to workspace variables
calcPSD = anacfg.getdata(1);
getSTA = anacfg.getdata(2);
getSTS = anacfg.getdata(3);
calcFourier = anacfg.getdata(4);
getAllSpk = anacfg.getdata(5);
getSTAnoDemean = anacfg.getdata(6);

sts_timwin = anacfg.ststimwin;
toi_pad = anacfg.toipad;
toi_stimChange = anacfg.toistimchange;
toi_psd = anacfg.toipsd;
foi = anacfg.foi;
trls = anacfg.trls;
toifourier = anacfg.toifourier;
psd_pad = max( abs(diff(toi_psd,[],2)) ) + 0.001;
%lfpiltfreq = foi(end) + foi(end)/3;%min(150,foi(end)*2);
lfpiltfreq = anacfg.Flp;
ncycle = anacfg.ncycle;
filtersta = anacfg.filtersta;
filtersts = anacfg.filtersts;
dointerpolation = anacfg.dointerpolation;
try, staboundaryaction = anacfg.staboundaryaction; end
try, stsboundaryaction = anacfg.stsboundaryaction; end

stsconsiderfullspectrum = anacfg.stsconsiderfullspectrum;

toiinterp = [-0.003 0.003];
freq = foi;
latency = [toi_pad(1) 0; 0.001, toi_pad(2)];%{'prestim','poststim'};

%save the configurations. if the script ever changes, make sure to make a
%new results direcctory
cfg_bl = [];
cfg_bl.trls = trls;
cfg_bl.foi = foi;
cfg_bl.psd_pad = psd_pad;
cfg_bl.toi_psd = toi_psd;
cfg_bl.toi_stimChange = toi_stimChange;
cfg_bl.toi_pad = toi_pad;


%NUMSEL =  1:152;


%(DOSAVE_PPC == 0 & DOSAVE_STS == 0 & DOSAVE_PPC_multiwin == 0)

ignore=[];


% --- --- --- --- --- --- --- --- --- ---
% --- collect datasets
datasets_data = {};
datasets_datadir = {};
dirinfo = dir(MATDIR_2);
for j=1:length(dirinfo)
    if (dirinfo(j).isdir) | strcmp(dirinfo(j).name(1),'.' ),  continue, end
    if ~isempty(findstr(dirinfo(j).name,'_DATA'))
        cL = length(datasets_data)+1;
        datasets_data{cL} = dirinfo(j).name;
        datasets_datadir{cL} = MATDIR_2;
    end
end


dirinfo = dir(MATDIR_1);
for j=1:length(dirinfo)
    if (dirinfo(j).isdir) | strcmp(dirinfo(j).name(1),'.' ),  continue, end
    if ~isempty(findstr(dirinfo(j).name,'_DATA'))
        cL = length(datasets_data)+1;
        datasets_data{cL} = dirinfo(j).name;
        datasets_datadir{cL} = MATDIR_1;
    end
end


% --- --- --- --- --- --- ---
% --- these are the indices to the .trl matrix
iOFFSET     = 3;
i_fixationOn = 6;
i_stimOn    = 7;
i_ret       = 8;
i_TOsample  = 9;
i_colOn     = 10;
i_cueOn     = 11;
i_det       = 12;
i_sStart    = 13;
i_sEnd      = 14;
i_rStart    = 15;
i_rEnd      = 16;

[CONDITION_SETNAME CONDITION_SETS CONDITION_SETSXVALUE CONDITION_SETLABELS] = prepare_conditions_av08();
allCnd = cell2mat(CONDITION_SETS(:)');  allCnd = unique(allCnd(:));
% distill main conditions for neuronal analysis
[CND_SETNAME, CND_SETS, CND_SETSXVALUE, CND_SETLABELS ] = prepare_conditions_final_01(CONDITION_SETNAME, CONDITION_SETS, CONDITION_SETSXVALUE, CONDITION_SETLABELS);

tmp = find(strcmp(CND_SETLABELS,'red'));
red_conditions = CND_SETS{tmp};
tmp = find(strcmp(CND_SETLABELS,'green'));
green_conditions = CND_SETS{tmp};
tmp = find(strcmp(CND_SETLABELS,'TLeft'));
left_conditions = CND_SETS{tmp};
tmp = find(strcmp(CND_SETLABELS,'TRight'));
right_conditions = CND_SETS{tmp};
tmp = find(strcmp(CND_SETLABELS,'CCW'));
ccw_conditions = CND_SETS{tmp};
tmp = find(strcmp(CND_SETLABELS,'CW'));
cw_conditions = CND_SETS{tmp};


DISTRACTOR_CCW  = [ 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 98];
DISTRACTOR_CW = [ 5 7 9 11 13 15 17 19 21 23 25 27 29 31 33 35 37 39 41 43 45 47 49 51 53 55 57 59 61 63 65 67 69 71 73 75 77 79 81 83 85 87 89 91 93 95 97 99  ];

NUMSEL = get_index(labindex,numlabs,length(datasets_data));
if isempty(NUMSEL)
    NUMSEL = 1:length(datasets_data);
end

WAV_FILE = 'A_UNITINFO_02_WAVE';
inWV = load(WAV_FILE);

%might want to test just one dataset
if ~isempty(anacfg.testdata)
    %test='mi_av17_065_01-A';
    test = anacfg.testdata;
    if ischar(test)
        test = {test};
    end
    
    tmpsel = [];
    for n=1:numel(test)
        name = test{n};
        ii = findstr(name,'-');
        if ~isempty(ii); name = name(1:ii-1); end
        tmpsel(n) = find( strncmp(name,datasets_data,numel(name)) );
    end
    
    NUMSEL = NUMSEL( ismember(NUMSEL, unique(tmpsel)) );
end

%update anacfg
anacfg.datasets = datasets_data(NUMSEL);
anacfg.ndiscardedtrials = zeros(numel(NUMSEL),1);
anacfg.discardedtrials = cell(numel(NUMSEL),1);

%
%main
%NUMSEL = get_index(2,10,152);
for iDD=NUMSEL
    
    dataname = datasets_data{iDD};
    name = datasets_data{iDD}(1:findstr(datasets_data{1},'_DATA')-1);
    fprintf('%s, num %d\n',name, iDD)
    
%     snamepow = [RESDIR '/' name '_fft.mat'];
%     if exist(snamepow)~=0
%         continue
%     end


    % ---  ---  ---  ---  ---
    % --- load DATA
    % ---  ---  ---  ---  ---
    in = load([datasets_datadir{iDD} dataname]);
    try
        in.data_stim = in.DATA;
    catch
        disp('old DATA')
    end
    
    
    sellfp = [strmatch('AD',in.data_stim.label)  strmatch('FP',in.data_stim.label)];
    lfpchannels = in.data_stim.label(sellfp);
       
    selspk = [strmatch('sig',in.data_stim.label)  strmatch('SP',in.data_stim.label)];
    spkchannels = in.data_stim.label(selspk);
    
    
    %restrict spike channels based on what the test data input was
    if isfield(anacfg,'testdata') && ~isempty(anacfg.testdata)
        tmpch = {};
        for n=1:numel(anacfg.testdata)
            if strncmp(anacfg.testdata{n},name,numel(name))
               ch = get_channel(anacfg.testdata{n});
               
               if ~strcmp(ch,'')
                   tmpch{numel(tmpch)+1,1} = ch;
               end
            end
        end
        
        if ~isempty(tmpch)
            spkchannels = tmpch;
        end
    end
    
    % ---  ---  ---  ---  ---
    % --- was there a reward difference for red and green attention targets ?
    % ---  ---  ---  ---  ---
    iRewardDifference = diff(minmax([in.data_stim.trl(:,i_rEnd) - in.data_stim.trl(:,i_rStart)]'))
    if iRewardDifference < 40,
        DOHIGH_LOW = 0;
    else
        DOHIGH_LOW = 1;
    end
    
    
    % --- --- --- --- --- --- --- ---
    % realign to attenton cue onset and downsample
    % --- --- --- --- --- --- --- ---
    disp('realigning to cue and downsampling')

    %sts_cue = un.sts;
    data_cue = in.data_stim;
    p_cfg=in.p_cfg;

    
    data_cue.trl(:,[iOFFSET i_fixationOn i_stimOn i_ret i_TOsample i_colOn i_cueOn i_det i_sStart i_sEnd i_rStart i_rEnd]) = ...
    data_cue.trl(:,[iOFFSET i_fixationOn i_stimOn i_ret i_TOsample i_colOn i_cueOn i_det i_sStart i_sEnd i_rStart i_rEnd]) - repmat(data_cue.trl(:,i_cueOn),1,12);
    for iT=1:length(data_cue.time)
        referencetime     = in.data_stim.trl(iT,i_cueOn)*0.001;
        data_cue.time{iT} = in.data_stim.time{iT} - referencetime;
        %sel = find(sts_cue.origtrial == iT);
        %sts_cue.origtime(sel) = sts_cue.origtime(sel) - referencetime;
        
        %downsample
        sel = data_cue.time{iT} >= toi_pad(1) & data_cue.time{iT} <= toi_pad(2);
        data_cue.time{iT}(~sel)=[];
        data_cue.trial{iT}(:,~sel)=[];
    end

    
    % ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
    % --- clean cue aligned epoch from color onset and rotation events ... (for later)
    % --- --- --- --- --- --- --- ---
    if 0
        [data_cue, sts_cue] = cleandata_cuealigned05(data_cue, sts_cue);
    end
    
    
    clear in %should change reference to data_stim in the loop
  
    % ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----  
    %check that the sampleinfo field is there, ned it for some functins
    % ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

    if ~isfield(data_cue,'sampleinfo')
        disp('no sampleinfo, creating fresh')
        data_cue.sampleinfo = data_cue.trl(:,1:2);
    end
    
    
    % ---------------------------------------------------
    % PREPROCESSING
    % ---------------------------------------------------
    
    %TRIAL SELECTION
    
    %select trials that dont have data
    goodtrial = ~cellfun(@isempty,data_cue.trial);
    
   
    %select trials
    [TRLSET  ERRORTYPES_cue ] = get_trialAnalysis_03(data_cue.trl);
    
    trlsel=false(size(TRLSET.attendRight));
    for tr=1:length(trls)
        trlsel=trlsel | TRLSET.(trls{tr});
    end
    
    goodtrial = goodtrial & trlsel';

    
    %analyze only those trials where stim change occured up to toi(2)
    %seconds after cue onset
    timeStimChange = min( data_cue.trl(:,[i_ret,i_det]), [], 2 ) ./ 1000; %first stimulus change

    tsel = timeStimChange >= toi_stimChange(1) & timeStimChange <= toi_stimChange(2);
    goodtrial = goodtrial & tsel';
    
    
    % check trials that have missing data
    selmiss = cellfun(@(x) sum(sum(isnan(x))) > 0, data_cue.trial);
    badtrial = selmiss;
   
   
    
    %select trials with large artifacts
    lfpind = find( ismember(data_cue.label,lfpchannels) );
    
    
    sumval = [];
    numsmp = [];
    sumsqr = [];
    for ilfp = 1:numel(lfpind)
        ii = lfpind(ilfp);
        numsmp(ilfp,1) = sum( cellfun(@(x) size(x,2),data_cue.trial) );
        sumval(ilfp,1) = sum( cellfun(@(x) sum(x(ii,:),2), data_cue.trial) );
        sumsqr(ilfp,1) = sum( cellfun(@(x) sum(x(ii,:).^2,2), data_cue.trial) );
    end
    
    mu = sumval./numsmp;
    st = sqrt(sumsqr./numsmp - (sumval./numsmp).^2);
 

    %find trials where z-score exceeded threhold
    zthreshold = 10;
    selartifact = false(size(badtrial));
    selartifacttime = -99*ones(size(badtrial));
    for ich=1:numel(lfpind)
        ii = lfpind(ich);

        tmp = cellfun(@(x) abs( (x(ii,:)-mu(ich))./st(ich) ),data_cue.trial,'uniformoutput',0);
        tmp = cellfun(@(x) x>zthreshold,tmp,'uniformoutput',0);
        tmp2 = cellfun(@(x,y) y( find(x,1) ), tmp,data_cue.time,'uniformoutput',0);
        
        zartifact = cellfun(@any,tmp);
        
        if any(zartifact)
            selartifact(zartifact) = true;
            selartifacttime(zartifact) = tmp2{zartifact};
        end
    end
    
    %keep this trial if the artifact is after the stimulus change
    selartifact = selartifact & (selartifacttime < timeStimChange');
    
    badtrial = badtrial | selartifact;
    
     %update number of trials we threw out
    anacfg.discardedtrials{iDD,1} = goodtrial;
    anacfg.discardedtrials{iDD,2} = badtrial;
    anacfg.ndiscardedtrials(iDD) = sum(badtrial) ./ (sum(goodtrial) + sum(badtrial));
    
    %final deletions
    deltrl = ~goodtrial | badtrial;
    keeptrls = find( ~deltrl );

    
   
    
    %delete trials
    %
    timeStimChange(deltrl) = [];
    data_cue.time(deltrl) = [];
    data_cue.trial(deltrl) = [];
    data_cue.trialinfo(deltrl,:) = [];
    data_cue.trl(deltrl,:) = [];
    data_cue.sampleinfo(deltrl,:) = [];
    %}
    
   
    %FT crashes in ranodm places because of the empties in data.time
    

    %{
    tmpempty = cellfun(@isempty,data_cue.time);
    selempty = find(tmpempty);
    for n=1:length(selempty)
        if selempty(n)==1
            ii = find(~tmpempty,1);
        else
            ii = selempty(n)-1;
        end

        data_cue.time{selempty(n)} = data_cue.time{ii};
    end
    clear tmpempty


    anacfg = [];
    cfg.trials = find(keeptrls);
    %data_cue = ft_preprocessing(cfg,data_cue);
    %}
    
  
    % ---------------------------------------------------
    % CALCULATE SOME NTRINSIC STUFF HERE
    % ---------------------------------------------------
    
     %select 
     if getAllSpk
        disp('***** Data for some intrinsic spike stuff ******')

        data_cue2 = data_cue;
        for ispk = 1:length(spkchannels)

            sta_cue = [];
            iSpikeChannel = spkchannels{ispk};

            %determine isolation quality, ignore if its too low
            iDatasetname = dataname;
            iDatasetname(min(findstr(iDatasetname,'-')):end) = [];

            iIsolation=ismember(inWV.Wdat.datasetname,iDatasetname)...
                        & ismember(inWV.Wdat.spikechannel,iSpikeChannel);
            isolationQuality = inWV.Wdat.isolationquality(iIsolation);

            %if isolationQuality~=3; continue; end
            spk_cue = [];
            try

                cfg_s = [];
                cfg_s.channel      =  lfpchannels( selectsamechannel(iSpikeChannel,lfpchannels,1) );
                cfg_s.spikechannel = iSpikeChannel;
                cfg_s.feedback     = 'no';
                cfg_s.keeptrials   = 'yes';
                %cfg_s.trials       = keeptrls;
                %cfg_s.trials       = spiketrlselection;
                cfg_s.timwin = sts_timwin; %[-1*sts_timwin, sts_timwin]; %[ -0.4 0.4];
                try, cfg_s.boundaryaction = staboundaryaction; end

                % [sta] = ft_spiketriggeredaverage(cfg_s, data_cue);
                %[sta_cue] = ft_spiketriggeredaverage(cfg_s, data_cue2);
                %sta_tmp = ft_spiketriggeredaverage3(cfg_s, data_cue2);
                spk_cue = ft_spiketriggeredaverage4(cfg_s, data_cue2);
                spk_cue = rmfield(spk_cue,'trial');
              %
            catch err

                warning('DID NOT COMPUTE STA')
                try, displaystack(err); end
                spk_cue = [];
            end

            %save
            disp('saving spike stuff...')
            snamespk = [RESDIR '/' name '_' iSpikeChannel '_spk.mat'];
            disp(snamespk)
            save(snamespk,'spk_cue')


                    %}
        end

    end

    
    % ---------------------------------------------------
    % CALCULATE FFT
    % ---------------------------------------------------
    
    if calcPSD
        sellfp = [strmatch('AD',data_cue.label); strmatch('FP',data_cue.label)]';
        labels = data_cue.label(sellfp);

        %useful stuff
        N = size(toi_psd,1);
        pow_fft = cell(N,1);


        %calculate power for each epoch
        for it=1:N

            %downsample
            data_cue2 = setValuesAfterTimePoint(data_cue,timeStimChange,0); 

            for itrl = 1:length(data_cue2.time)
                seltime = data_cue2.time{itrl} >= toi_psd(it,1) & data_cue2.time{itrl} <= toi_psd(it,2);
                
                %because of the bullshit i did with empties up top, some
                %trials will remain empty, so seltime will fail. thus, only
                %downsample in those trials that arent empty. shouldnt
                %matter  **AS LONG AS** we still select trials below
                %if ~ismember(itrl,selempty)
                %    data_cue2.time{itrl}(:,~seltime)=[];
                %    data_cue2.trial{itrl}(:,~seltime)=[];
                %end
                
                data_cue2.time{itrl}(:,~seltime)=[];
                data_cue2.trial{itrl}(:,~seltime)=[];
            end

           

            pcfg              = [];
            pcfg.output       = 'pow';
            pcfg.channel      = labels;
            pcfg.method       = 'mtmfft';
            pcfg.taper       = 'hanning';
            %pcfg.tapsmofrq   = 2; 
            pcfg.keeptrials   = 'yes';
            %pcfg.foilim       = [foi(1), foi(end)];
            pcfg.foi         = foi;
            pcfg.pad         = psd_pad; %2.001;
            %pcfg.trials = keeptrls;
            
            tmp_pow = ft_freqanalysis(pcfg, data_cue2);

            %add some more to cfg
            tmp_pow.cfg.trl = data_cue2.trl;
            tmp_pow.cfg.trls = trls;
            tmp_pow.cfg.trlsel = keeptrls;
            pow_fft{it} = tmp_pow;

        end
        
        cfg=[];
        cfg.name = name;
        cfg.dimord = '{toi}-[freanalysis output]';
        cfg.toi = toi_psd;
        cfg.pcfg = pcfg;


        %save data
        disp('saving...')
        snamepow = [RESDIR '/' name '_fft.mat'];
        disp(snamepow)

        save(snamepow,'pow_fft','cfg')

        clear data_cue2 pow_fft
    end
    
    
     % ---------------------------------------------------
    % CALCULATE TFR W/ FFT
    % ---------------------------------------------------
    
    if calcFourier
        sellfp = [strmatch('AD',data_cue.label); strmatch('FP',data_cue.label)]';
        labels = data_cue.label(sellfp);

        %useful stuff


        %calculate power for each epoch
        %downsample
        data_cue2 = setValuesAfterTimePoint(data_cue,timeStimChange,0);

        pcfg              = [];
        pcfg.output       = 'fourier';
        pcfg.channel      = labels;
        pcfg.method       = 'tfr';
        pcfg.taper       = 'hanning';
        pcfg.keeptrials   = 'yes';
        %pcfg.foilim       = [foi(1) foi(end)];
        pcfg.foi       = foi;
        pcfg.pad         = diff(toifourier(1),toifourier(end))+1; %psd_pad; %2.001;
        pcfg.toi = toifourier; %toi_pad;
        %pcfg.foi = foi(1):0.55:foi(end);
        %pcfg.t_ftimwin = 2./pcfg.foi;
        pcfg.width = 5;
        
        pow_fourier = ft_freqanalysis(pcfg, data_cue2);


%         %downsample to save
%         for itrl = 1:length(data_cue.time)
%             seltime = pow_fourier.time >= toifourier(1) & pow_fourier.time <= toifourier(end);
% 
% 
%             pow_fourier.time(~seltime) = [];
%             pow_fourier.trial(:,:,:,~seltime) = [];
%         end

        %add some more to cfg
        pow_fourier.cfg.trl = data_cue2.trl;
        pow_fourier.cfg.trls = trls;
        pow_fourier.cfg.trlsel = keeptrls;

        
        cfg=[];
        cfg.name = name;
        cfg.toi = toifourier;
        cfg.pcfg = pcfg;


        %save data
        disp('saving...')
        snamepow = [RESDIR '/' name '_fourier.mat'];
        disp(snamepow)

        save(snamepow,'pow_fourier','cfg')

        clear data_cue2 pow_fft
    end
    
     % --- --- --- --- --- --- --- ---
    % CALCULATE Spike Triggered Average
    % --- --- --- --- --- --- --- ---
    
    if getSTAnoDemean

        %select 
        disp('***** Calculating Spike Trigered AVERAGE ******')
        
        data_cue2 = setValuesAfterTimePoint(data_cue,timeStimChange,[]);
        
        if filtersta
            data_cue2 = applyLowpassFilter(data_cue2,lfpchannels,lfpiltfreq);
        end
       
        for ispk = 1:length(spkchannels)

            sta_cue = [];
            for it = 1:size(latency,1)
                iSpikeChannel = spkchannels{ispk};

                %determine isolation quality, ignore if its too low
                iDatasetname = dataname;
                iDatasetname(min(findstr(iDatasetname,'-')):end) = [];

                iIsolation=ismember(inWV.Wdat.datasetname,iDatasetname)...
                            & ismember(inWV.Wdat.spikechannel,iSpikeChannel);
                isolationQuality = inWV.Wdat.isolationquality(iIsolation);

                 
                %only interpolate once
                if dointerpolation && it==1

                    lfpchannel = lfpchannels{ selectsamechannel(iSpikeChannel,lfpchannels,1) };

                    sti_cfg = [];
                    sti_cfg.timwin = toiinterp;
                    sti_cfg.spikechannel = iSpikeChannel; 
                    sti_cfg.channel = lfpchannel;
                    sti_cfg.method = 'cubic';
                    sti_cfg.outputexamples = 'yes';
                    datatmp  = spiketriggeredinterpolation_02b(sti_cfg, data_cue2);
                    fred=2;
                else
                    datatmp = data_cue2;

                end
                
                %if isolationQuality~=3; continue; end
                
                sta_tmp = [];
                try

                    cfg_s = [];
                    cfg_s.latency      =  latency(it,:);
                    cfg_s.channel      =  lfpchannels( selectsamechannel(iSpikeChannel,lfpchannels,1) );
                    cfg_s.spikechannel = iSpikeChannel;
                    cfg_s.feedback     = 'no';
                    cfg_s.keeptrials   = 'yes';
                    %cfg_s.trials       = keeptrls;
                    %cfg_s.trials       = spiketrlselection;
                    cfg_s.timwin = sts_timwin; %[-1*sts_timwin, sts_timwin]; %[ -0.4 0.4];
                    try, cfg_s.boundaryaction = staboundaryaction; end
                    
                    % [sta] = ft_spiketriggeredaverage(cfg_s, data_cue);
                    %[sta_cue] = ft_spiketriggeredaverage(cfg_s, data_cue2);
                    %sta_tmp = ft_spiketriggeredaverage3(cfg_s, data_cue2);
                    sta_tmp = ft_spiketriggeredaverage4_nodemean(cfg_s, datatmp);

                    %store
                    if isempty(sta_cue)
                        sta_cue = sta_tmp;
                    else
                        sta_cue.origtime = [sta_cue.origtime; sta_tmp.origtime];
                        sta_cue.origtrial = [sta_cue.origtrial; sta_tmp.origtrial];
                        sta_cue.trial = cat(1,sta_cue.trial, sta_tmp.trial);
                        sta_cue.cfg.latency = [sta_cue.cfg.latency; sta_tmp.cfg.latency];
                    end
                  %
                catch err

                    warning('DID NOT COMPUTE STA')
                    try, displaystack(err); end

                    if isempty(sta_cue)
                        sta_cue=[];
                        sta_cue.time = [];
                        sta_cue.avg = [];
                        sta_cue.label = lfpchannels;
                        sta_cue.trial = [];
                        sta_cue.origtrial = [];
                        sta_cue.origtime = [];
                        sta_cue.cfg = cfg_s;
                        sta_cue.err = err;
                    end
                end
                    %}
            end

            %cfg_s.latency = 'maxperiod';
            %sta_cue2 = ft_spiketriggeredaverage3(cfg_s, data_cue2);
            
            
            [~,dum] = sort(sta_cue.origtrial,'ascend');
            sta_cue.origtime = sta_cue.origtime(dum);
            sta_cue.origtrial = sta_cue.origtrial(dum);
            sta_cue.trial = sta_cue.trial(dum,:,:);
            
            %[~,dum] = sort(sta_cue2.origtrial,'ascend');
            %sta_cue2.origtime = sta_cue2.origtime(dum);
            %sta_cue2.origtrial = sta_cue2.origtrial(dum);

            sta_cue.isolationQuality = isolationQuality;
            sta_cue.cfg.timeStimChange = timeStimChange;
            sta_cue.cfg.trl = data_cue2.trl;
            sta_cue.cfg.trls = trls;
            sta_cue.cfg.trlsel = keeptrls;
            
            %save
            disp('saving STA...')
            snamesta = [RESDIR '/' name '_' iSpikeChannel '_staorig.mat'];
            disp(snamesta)
            save(snamesta,'sta_cue')
            
        end
    end
    
    
    % --- --- --- --- --- --- --- ---
    % CALCULATE Spike Triggered Average
    % --- --- --- --- --- --- --- ---
    
    if getSTA

        %select 
        disp('***** Calculating Spike Trigered AVERAGE ******')
        
        data_cue2 = setValuesAfterTimePoint(data_cue,timeStimChange,[]);
        
        if filtersta
            data_cue2 = applyLowpassFilter(data_cue2,lfpchannels,lfpiltfreq);
        end
       
        for ispk = 1:length(spkchannels)

            sta_cue = [];
            for it = 1:size(latency,1)
                iSpikeChannel = spkchannels{ispk};

                %determine isolation quality, ignore if its too low
                iDatasetname = dataname;
                iDatasetname(min(findstr(iDatasetname,'-')):end) = [];

                iIsolation=ismember(inWV.Wdat.datasetname,iDatasetname)...
                            & ismember(inWV.Wdat.spikechannel,iSpikeChannel);
                isolationQuality = inWV.Wdat.isolationquality(iIsolation);

                 
                %only interpolate once
                if dointerpolation && it==1

                    lfpchannel = lfpchannels{ selectsamechannel(iSpikeChannel,lfpchannels,1) };

                    sti_cfg = [];
                    sti_cfg.timwin = toiinterp;
                    sti_cfg.spikechannel = iSpikeChannel; 
                    sti_cfg.channel = lfpchannel;
                    sti_cfg.method = 'cubic';
                    sti_cfg.outputexamples = 'yes';
                    datatmp  = spiketriggeredinterpolation_02b(sti_cfg, data_cue2);
                    fred=2;
                else
                    datatmp = data_cue2;

                end
                
                %if isolationQuality~=3; continue; end
                
                sta_tmp = [];
                try

                    cfg_s = [];
                    cfg_s.latency      =  latency(it,:);
                    cfg_s.channel      =  lfpchannels( selectsamechannel(iSpikeChannel,lfpchannels,1) );
                    cfg_s.spikechannel = iSpikeChannel;
                    cfg_s.feedback     = 'no';
                    cfg_s.keeptrials   = 'yes';
                    %cfg_s.trials       = keeptrls;
                    %cfg_s.trials       = spiketrlselection;
                    cfg_s.timwin = sts_timwin; %[-1*sts_timwin, sts_timwin]; %[ -0.4 0.4];
                    try, cfg_s.boundaryaction = staboundaryaction; end
                    
                    % [sta] = ft_spiketriggeredaverage(cfg_s, data_cue);
                    %[sta_cue] = ft_spiketriggeredaverage(cfg_s, data_cue2);
                    %sta_tmp = ft_spiketriggeredaverage3(cfg_s, data_cue2);
                    sta_tmp = ft_spiketriggeredaverage4(cfg_s, datatmp);

                    %store
                    if isempty(sta_cue)
                        sta_cue = sta_tmp;
                    else
                        sta_cue.origtime = [sta_cue.origtime; sta_tmp.origtime];
                        sta_cue.origtrial = [sta_cue.origtrial; sta_tmp.origtrial];
                        sta_cue.trial = cat(1,sta_cue.trial, sta_tmp.trial);
                        sta_cue.cfg.latency = [sta_cue.cfg.latency; sta_tmp.cfg.latency];
                    end
                  %
                catch err

                    warning('DID NOT COMPUTE STA')
                    try, displaystack(err); end

                    if isempty(sta_cue)
                        sta_cue=[];
                        sta_cue.time = [];
                        sta_cue.avg = [];
                        sta_cue.label = lfpchannels;
                        sta_cue.trial = [];
                        sta_cue.origtrial = [];
                        sta_cue.origtime = [];
                        sta_cue.cfg = cfg_s;
                        sta_cue.err = err;
                    end
                end
                    %}
            end

            %cfg_s.latency = 'maxperiod';
            %sta_cue2 = ft_spiketriggeredaverage3(cfg_s, data_cue2);
            
            
            [~,dum] = sort(sta_cue.origtrial,'ascend');
            sta_cue.origtime = sta_cue.origtime(dum);
            sta_cue.origtrial = sta_cue.origtrial(dum);
            sta_cue.trial = sta_cue.trial(dum,:,:);
            
            %[~,dum] = sort(sta_cue2.origtrial,'ascend');
            %sta_cue2.origtime = sta_cue2.origtime(dum);
            %sta_cue2.origtrial = sta_cue2.origtrial(dum);

            sta_cue.isolationQuality = isolationQuality;
            sta_cue.cfg.timeStimChange = timeStimChange;
            sta_cue.cfg.trl = data_cue2.trl;
            sta_cue.cfg.trls = trls;
            sta_cue.cfg.trlsel = keeptrls;
            
            %save
            disp('saving STA...')
            snamesta = [RESDIR '/' name '_' iSpikeChannel '_sta.mat'];
            disp(snamesta)
            save(snamesta,'sta_cue')
            
        end
    end
        
    
    %{
    iSpikeChannel = spkchannels{ispk};
            
            %can use these indices later when selecting bursts, nonbursts
            tmp=[];
            eventstr = inspk.cfg.scfg.eventstr;
            spiketype = inspk.spiketype_all{ spkInd(ispk) };

            spikeidentity = struct('sel',{});
            spikeidentity(1).type = spiketype;
            spikeidentity(1).events = eventstr;
            for ievent=1:length(eventstr)
                
                selevent = inspk.selevent_all{spkInd(ispk), ievent};
                
                spikeidentity(1).type = spiketype;
                spikeidentity(1).sel{ievent} = selevent;
            end
    %}
    %
    if getSTS
        % --- --- --- --- --- --- --- ---
        % CALCULATE Spike Triggered Spectrum
        % --- --- --- --- --- --- --- ---
        disp('***** Calculating Spike Trigered SPECTRUM ******')
        
        
        data_cue2 = setValuesAfterTimePoint(data_cue,timeStimChange,[]);
        
        if filtersts
            data_cue2 = applyLowpassFilter(data_cue2,lfpchannels,lfpiltfreq);
        end
       
         
        
        tims = [1 ./ freq];
        ich = 1;

        for ispk = 1:length(spkchannels)
            iSpikeChannel = spkchannels{ispk};
                        
             %determine isolation quality, ignore if its too low
            iDatasetname = dataname;
            iDatasetname(min(findstr(iDatasetname,'-')):end) = [];

            iIsolation=ismember(inWV.Wdat.datasetname,iDatasetname)...
                        & ismember(inWV.Wdat.spikechannel,iSpikeChannel);
            isolationQuality = inWV.Wdat.isolationquality(iIsolation);

            if isolationQuality ~= 3
                continue
            end
                
            sts_cue = [];
            for it = 1:size(latency,1)
                
                sts_tmp2 = [];
%                 sts_tmp2.fourierspctrm = {nan};
%                 sts_tmp2.time = {nan};
%                 sts_tmp2.trial = {nan};
%                 sts_tmp2.cfg.latency = [];
                for ifreq=1:numel(foi)

                    cfg_sts              = [];
                    cfg_sts.latency      = latency(it,:);
                    cfg_sts.method       = 'mtmfft';

                    cfg_sts.taper        = 'hanning';
                    cfg_sts.spikechannel = iSpikeChannel;
                    cfg_sts.channel      = lfpchannels;
                    %cfg_sts.trials       = keeptrls;
                    %cfg_sts.eventtime = eventtime;

                    if freq(ifreq)==1,
                        cfg_sts.timwin = [ -tims(ifreq)*1 tims(ifreq)*1];
                    else
                        cfg_sts.timwin = [ -tims(ifreq)*ncycle/2 tims(ifreq)*ncycle/2];
                    end
                    cfg_sts.foilim = [freq(ifreq),freq(ifreq)];
                    
                    try
                        sts_tmp = [];
                        
                        %only interpolate once
                        if dointerpolation && it==1 && ifreq==1

                            lfpchannel = lfpchannels{ selectsamechannel(iSpikeChannel,lfpchannels,1) };

                            sti_cfg = [];
                            sti_cfg.timwin = toiinterp;
                            sti_cfg.spikechannel = iSpikeChannel; 
                            sti_cfg.channel = lfpchannel;
                            sti_cfg.method = 'cubic';
                            sti_cfg.outputexamples = 'yes';
                            datatmp  = spiketriggeredinterpolation_02b(sti_cfg, data_cue2);
                            fred=2;
                
                        end
            
                        %testing
                        cfg_sts.boundaryaction = stsboundaryaction; %'shift';
                        cfg_sts.considerfullspectrum = stsconsiderfullspectrum;
                        sts_tmp = ft_spiketriggeredspectrum5(cfg_sts, datatmp);

                        %sts_tmp = ft_spiketriggeredspectrum3(cfg_sts, data_cue2);
                        %sts_tmp = ft_spiketriggeredspectrum4(cfg_sts, data_cue2);
                        
                        %sts_tmp = spike_triggeredspectrum_01(cfg_f, datatmp);
                        if isempty(sts_tmp2)
                            sts_tmp2 = sts_tmp;
                            sts_tmp2.freq = [];
                        end
                        sts_tmp2.fourierspctrm{ich}(:,:,ifreq) = sts_tmp.fourierspctrm{ich};
                        sts_tmp2.freq = [sts_tmp2.freq sts_tmp.freq];
                        sts_tmp2.cfg.timwin = [sts_tmp2.cfg.timwin; sts_tmp.cfg.timwin];


                    catch err

                        warning('DID NOT COMPUTE STS')
                        try, displaystack(err); end

                        if isempty(sts_cue)
                            sts_cue=[];
                            sts_cue.time = [];
                            sts_cue.avg = [];
                            sts_cue.label = lfpchannels;
                            sts_cue.trial = [];
                            sts_cue.cfg = cfg_sts;
                            sts_cue.err = err;
                        end
                    end
                end
                
                if isempty(sts_cue)
                    sts_cue = sts_tmp2;
                else
                    
                    sts_cue.fourierspctrm{ich} = cat(1,sts_cue.fourierspctrm{ich},sts_tmp2.fourierspctrm{ich});
                    sts_cue.time{ich} = [sts_cue.time{ich}; sts_tmp2.time{ich}];
                    sts_cue.trial{ich} = [sts_cue.trial{ich}; sts_tmp2.trial{ich}];
                    sts_cue.cfg.latency = [sts_cue.cfg.latency; sts_tmp2.cfg.latency];
                end
            end
            
            for ich=1:numel(sts_cue.label)
                [~,dum] = sort(sts_cue.trial{ich},'ascend');
                sts_cue.time{ich} = sts_cue.time{ich}(dum);
                sts_cue.trial{ich} = sts_cue.trial{ich}(dum);
                sts_cue.fourierspctrm{ich} = sts_cue.fourierspctrm{ich}(dum,:,:);
            end
            
            %isolation quality
            %determine isolation quality, ignore if its too low
            iDatasetname = dataname;
            iDatasetname(min(findstr(iDatasetname,'-')):end) = [];

            iIsolation=ismember(inWV.Wdat.datasetname,iDatasetname)...
                    & ismember(inWV.Wdat.spikechannel,iSpikeChannel);
            isolationQuality = inWV.Wdat.isolationquality(iIsolation);

            sts_cue.isolationQuality = isolationQuality;

            %add alst bit of info
            sts_cue.cfg.timeStimChange = timeStimChange;
            sts_cue.cfg.trl = data_cue2.trl;
            sts_cue.cfg.trls = trls;
            sts_cue.cfg.trlsel = keeptrls;

            %save
            disp('saving STS...')
            snamests = [RESDIR '/' name '_' iSpikeChannel '_sts.mat'];
            disp(snamests)
            %save(snamests,'sts_cue','spikeidentity','sts_stat_all','sts_stat_time_all')
            save(snamests,'sts_cue')
        end
    end
    %}
    
        %{
    if 0
        %calculate stats, looping over different spike deifnitions
        tmp=[];
        eventstr = inspk.cfg.scfg.eventstr;
        sts_stat_all={};
        sts_stat_time_all={};
        for ievent=1:length(eventstr)
            % --- --- --- --- --- --- --- ---
            % CALCULATE Spike Triggered stats
            % --- --- --- --- --- --- --- ---

            cfg_stat=[];
            cfg_stat.channel = lfpchannels;
            cfg_stat.spikechannel  = sts_cue.label{1};
            cfg_stat.spikesel      = spikeidentity.sel{ievent};
            cfg_stat.foi = 'all';
            cfg_stat.trials = 'all';
            cfg_stat.latency = 'maxperiod';
            cfg_stat.checksize = 1e5; %ft_default.checksize;
            %[stat] = ft_spike_phaselockstat_cnd(cfg_stat,sts_cue);
            tmp = ft_spike_phaselockstat_clusters_02(cfg_stat ,sts_cue);

            %compute p-values here
            p = sum( bsxfun(@gt, tmp.ppcRand, tmp.ppcAct) ) ./ tmp.cfg.nRandomizations;
            tmp.ppc_p = p;
            sts_stat_all{ievent} = tmp;

            %{
            cfg_stat               = [];
            cfg_stat.method        = 'ppc1'; % compute the Pairwise Phase Consistency
            cfg_stat.spikechannel  = sts_cue.label{1};
            cfg_stat.channel       = lfpchannels; % selected LFP channels
            cfg_stat.avgoverchan   = 'no'; %'weighted'; % weight spike-LFP phases irrespective of LFP power
            cfg_stat.timwin        = 'all'; % compute over all available spikes in the window 
            cfg_stat.latency       = toi_pad;
            cfg_stat.spikesel      = spikeidentity.sel{ievent};

           tmp = ft_spiketriggeredspectrum_stat(cfg_stat,sts_cue);
            %sts_stat_all{ievent}           = ft_spiketriggeredspectrum_stat(cfg_stat,sts_cue);




            cfg_stat2          = cfg_stat;            
            cfg.winstepsize    = 0.01; % step size of the window that we slide over time
            cfg.timwin         = 0.5; % duration of sliding window
            sts_stat_time_all{ievent}           = ft_spiketriggeredspectrum_stat(cfg_stat2,sts_cue);
            %}



        end

            
            %save
            disp('saving STS...')
            snamests = [RESDIRPPC '/' name '_' iSpikeChannel '_sts.mat'];
            disp(snamests)
            save(snamests,'sts_cue','spikeidentity','sts_stat_all','sts_stat_time_all')
        end
        
    end
    %}
    
  
        
end



%get list
%get_list_burst(RESDIR);
%get_anatloc_burst(RESDIR);
%reformat_power(RESDIRPOW);


disp('...done')


%------------------------------------------------------------
%subfunctions

function data_cue = setValuesAfterTimePoint(data_cue,timeStimChange,setval)


 %set everyting after stim rotation to zero
for itrl=1:length(data_cue.trial)
    tsel = data_cue.time{itrl} > timeStimChange(itrl);

    
    if isempty(setval)
        data_cue.time{itrl}(tsel) = [];
        data_cue.trial{itrl}(:,tsel) = [];
    else
        data_cue.trial{itrl}(:,tsel) = setval;
    end
end


function data_cue2=applyLowpassFilter(data_cue,channels,Flp)

if isempty(Flp); 
    warning('Not applying low-pass filter'); 
    data_cue2 = data_cue;
    return;
end

selchannels = ismember(data_cue.label,channels);
Fsample = data_cue.fsample;
%Flp = 120;
N = 6;
type = 'but';
dir = 'twopass';
instabilityfix = 'reduce';

data_cue2 = data_cue;
for n=1:numel(data_cue.trial)
    dat = data_cue.trial{n}(selchannels,:);
    filt = ft_preproc_lowpassfilter(dat, Fsample, Flp, N, type, dir, instabilityfix);
    data_cue2.trial{n}(selchannels,:) = filt;
end