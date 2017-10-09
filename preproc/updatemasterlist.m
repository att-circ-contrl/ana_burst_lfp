function varargout = updatemasterlist(cfg,masterlist)
% createmasterlist(loaddir,cfg)
% createmasterlist(loaddir,cfg,masterlist)
% masterlist = createmasterlist(...)
%
% cfg.resdir: string
% cfg.datatype: [1 = sta, 2=PSD]
% cfg.makenewmaster: 1/0
% cfg.masterlistname: string
% cfg.getanatomy: true false

disp('--------------------------------')
disp('   Updating masterlist     ')
disp('--------------------------------')

dbstop if error

%checks
cfg = checkfield(cfg,'datadir',[]);
cfg = checkfield(cfg,'loaddir','needit');
cfg = checkfield(cfg,'resdir',cfg.loaddir);
cfg = checkfield(cfg,'masterlistname','masterlist');
cfg = checkfield(cfg,'datatype',[]);
cfg = checkfield(cfg,'getanatomy',0);

loaddir = cfg.loaddir;

%load the masterlist in if we havent supplied it
if nargin < 2
    cd(cfg.loaddir)
    try
        disp( ['loading masterlist from: ' cfg.loaddir] )
        load('masterlist.mat')
    catch
        error('couldnt load the masterlist')
    end   
end


%settings
spikeFlag = 1;
psdFlag = 2;
artifactFlag = 3;
spikeStuffFlag = 4;

doSpike = ismember(spikeFlag,cfg.datatype);
doPsd = ismember(psdFlag,cfg.datatype);
doArtifact = ismember(artifactFlag,cfg.datatype);
doIntrinsicSpikeInfo = ismember(spikeStuffFlag,cfg.datatype);
getanatomy = cfg.getanatomy;


    
        
%d = dir('*_sta.mat');


% load in spike data
% do thi first because we might need to overwite the list
if doSpike
    disp('...getting spike counts')
    
    in = load( [loaddir '/sta_all.mat'] );
    %spikelist = get_spikedata(in.sta_all,cfg);
    spikelist = get_spikedata2(in.sta_all,cfg);
    clear in
    
    %put it into the masterlist
    disp('  > putting spike counts/isolationquality in masterlist')
    
    for ispike=1:length(spikelist)
        %find index in masterlist
        name = spikelist(ispike).name;
        ii = strncmp(name,{masterlist.name},length(name));

        %add data
        %masterlist(ii).nspike.toi = spikelist.toi;
        %masterlist(ii).nspike.nspk = spikelist.nspk;
        %masterlist(ii).nspike.nburst = spikelist.nburst;
        
        masterlist(ii).isolationquality = spikelist(ispike).isolationQuality;
        masterlist(ii).spike.Binfo = spikelist(ispike).Binfo;% = sta_all.origtime{n};
        masterlist(ii).spike.origtime = spikelist(ispike).origtime;% = sta_all.origtime{n};
        masterlist(ii).spike.origtrial = spikelist(ispike).origtrial;
        masterlist(ii).spike.selspk = spikelist(ispike).selspk;
        %masterlist(ii).spike.spikeidentity = spikelist(ispike).origtrial;
        
    end
    
end


% load in PSD data, get spectral peaks
if doPsd
    disp('...getting PSD')
    
    inpower = load( [loaddir '/power_all.mat'] );
    
    %psdpeakslist = get_psdpeaks(inpow.power_all,cfg);
    %clear in

    disp('  > putting psd in masterlist')

    for imaster = 1:length(masterlist)
        lfpname = spkname2lfpname( masterlist(imaster).name );
        ipow = ismember( inpower.power_all.dataname, lfpname );

        masterlist(imaster).power.psd = inpower.power_all.power(ipow,:,:);
        masterlist(imaster).power.toi = inpower.power_all.toi;
        masterlist(imaster).power.freq = inpower.power_all.freq;
    end
end
   

if doArtifact
    
    disp('...geting artifacts')
    inart = load([loaddir '/anacfg.mat']);
    
    for imaster = 1:length(masterlist)
        ii = strfind(masterlist(imaster).name,'-A');
        dataname = masterlist(imaster).name(1:ii+1);
        iart = strncmp(inart.anacfg.datasets, dataname, numel(dataname) );
        
        masterlist(imaster).ndiscardedtrials = inart.anacfg.ndiscardedtrials(iart);
        
    end
end


if doIntrinsicSpikeInfo
   disp('... getting intrinsic spike stuff')

   inart = load([loaddir '/anacfg.mat']);
   interval = inart.anacfg.toipad; 
   
   if isempty(cfg.datadir)
       warning('datadir not supplied')
   else
       d = dir( [cfg.datadir '/*_spk.mat'] );

       for idat=1:numel(d)
           dotdotdot(idat,ceil(numel(d)*0.1),numel(d))
           
           name = masterlist(idat).name;

           ii = strncmp(name,{masterlist.name},numel(name));

           in = load( [cfg.datadir '/' d(ii).name] );
           
           if isempty(in.spk_cue)
               LV = nan;
               FR = nan;
               F = nan;
           else
               tr = in.spk_cue.origtrial;
               t = in.spk_cue.origtime;
               
               isis = isi(t,tr);
               
               LV = localVar(isis);
               FR = firingrate(interval,tr,t);
               F = fano(tr);
           end
           
           %store
           masterlist(idat).intrinsicspike.interval = interval;
           masterlist(idat).intrinsicspike.rate = FR;
           masterlist(idat).intrinsicspike.lv = LV;
           masterlist(idat).intrinsicspike.fano = F;

       end
   end 
end


%add anatomical data to master list
if getanatomy
    %FLAT = load('A_UNITINFO_05_FLATXY');
    %get_anatloc_burst(
    str = [loaddir '/anatloc.mat'];
    if exist(str)==2
        load( [loaddir '/anatloc.mat'] )
    else
        get_anatloc_burst(loaddir,masterlist)
    end
end

if 1
    disp('...getting cell type')
    W =  load('wFpreprocessed.mat');
    nlist = numel(masterlist);
    for n=1:nlist
        p = mod( n/nlist*100, 5);
        if floor(p)==1 && p<=1.5/nlist 
            fprintf('.'); 
        end
        
        tmp = get_celltypes(masterlist(n),W);
        
        masterlist(n).celltype = tmp.ctype;
    end
end


%save
if strcmp(cfg.masterlistname(end-3:end),'.mat'); 
    cfg.masterlistname = cfg.masterlistname(end-3:end);
end
sname = [cfg.resdir '/' cfg.masterlistname '.mat'];
disp('...saving...')
disp(sname)
save(sname,'masterlist')

%output
if nargout>0
    varargout{1} = masterlist;
end


% ---------------------
% SUB FUNCTIONS
% ---------------------


%{
defaults = {'datatype',needit;
            'spktoi',[];
            'psdtoi',needit;
            'burstsequence',needit;
            'foi',needit};
        
   
if ~isfield(cfg,checkstr)
    ii = ismember(defaults(:,1),checkstr);
    val = defaults{ii,2};
    if isstring(val) && strcmp(val,needit)
        error( ['Need to provide field in cfg: ' checkstr] )
    end
end
%}

%get burststuff
function spikelist = get_spikedata2(sta_all,cfg)
disp('  > creating nspike list')

names = sta_all.dataname;
%toi = cfg.spktoi;
%burstSeq = cfg.burstsequence;

spikelist = [];
for n=1:length(names)
    name=names{n};
    
    %disp( [num2str(n) ': ' name] )
    %load(name)

    spikelist(n).name = name;
    spikelist(n).isolationQuality = sta_all.isolationQuality(n);

    spikelist(n).origtime = sta_all.origtime{n};
    spikelist(n).origtrial = sta_all.origtrial{n};
    spikelist(n).Binfo = sta_all.Binfo{n};
    spikelist(n).selspk = sta_all.selspk{n};
    
end




%{
function spikelist = get_spikedata(sta_all,cfg)
disp('**** creating nspike list ***')

names = sta_all.dataname;
toi = cfg.spktoi;
burstSeq = cfg.burstsequence;

spikelist = [];
for n=1:length(names)
    name=names{n};
    
    %disp( [num2str(n) ': ' name] )
    %load(name)

    spikelist(n).name = name;
    spikelist(n).isolationQuality = sta_all.isolationQuality(n);

    %might have to extract toi from spk_cue if not provided
    step=.05; %100 ms time step
    if toi==0
        st=floor(min(spk_cue.origtime));
        fn=ceil(max(spk_cue.origtime));
    elseif numel(toi)==2
        st = toi(1);
        fn = toi(2);
    end
    toi = [ (st:step:fn-step); (st+step:step:fn)]';

   
    
    %spike and burst info
    Binfo = sta_all.Binfo{n};

    %extract number of spikes and bursts for each time step
    spikelist(n).toi = toi;
    for t=1:size(toi,1)
        %list(n).nspk(t,1:2)=toi(t,1:2);
        %list(n).nburst(t,1:2)=toi(t,1:2);

        tsel=sta_all.origtime{n} >= toi(t,1) & sta_all.origtime{n} <= toi(t,2);

        %get number of non-burst spikes in bins defined by toi
        spikelist(n).nspk(t,1) = sum( tsel & Binfo.burstVector{1}==0 );

        %get number of bursts in bins defined by toi
        spikelist(n).nburst(t,1) = sum( tsel & ismember(Binfo.burstVector{1}, burstSeq) );
    end
end
%}





