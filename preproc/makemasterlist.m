function [masterlist,mcfg] = makemasterlist(mcfg)
% [masterlist,mcfg] = makemasterlist(mcfg)
%
% config input:
%       loaddir (required)
%       searchsuffix (default='_sat.mat')
%       resdir (required)
%       savename (default='masterlist')
%       bursttoi (deafault=[])

disp('--------------------------------')
disp('   Creating masterlist     ')
disp('--------------------------------')

%configure the name of directory to save the masterlist
% cfg.loaddir,searchstring,cfg.resdir,cfg.savename
mcfg = checkfield(mcfg,'loaddir','needit');
mcfg = checkfield(mcfg,'searchsuffix','_sta.mat');
mcfg = checkfield(mcfg,'resdir','needit');
mcfg = checkfield(mcfg,'savename','masterlist');
mcfg = checkfield(mcfg,'bursttoi',[]);

%create directories
if strcmp(mcfg.resdir(end), '/'); mcfg.resdir = mcfg.resdir(1:end-1); end
if ~exist(mcfg.resdir); mkdir(mcfg.resdir); end
if strcmp(mcfg.savename(end-3:end),'.mat')
    mcfg.savename = mcfg.savename(end-3:end);
end

%get the masterlist names based on teh search string
cd(mcfg.loaddir)
d = dir(['*' mcfg.searchsuffix]);
if isempty(d); error( ['couldnt find anything with the following searchstring: ' mcfg.searchstring] ); end

masterlist = [];
for n=1:length(d)
    name = d(n).name;
    cull = length(mcfg.searchsuffix);
    %if strcmp(mcfg.searchsuffix,'_'); cull = cull-1; end
        
    masterlist(n).name = name(1:end - cull);
    masterlist(n).lfpname = spkname2lfpname(name);
end

%get spike/burst stuff
disp('...extracting spike/burst info')
bcfg = [];
bcfg.burstWindows = [0.005];%[0.005 0.010 0.015 ];
bcfg.preBurstQuiteness = 0; % if this is e.g. 0.03 then burst are by definition only depetected if they happen after a 30ms no-spike period
bcfg.toi = mcfg.bursttoi;

mcfg.bcfg = bcfg;

%masterlist(4:end) = []; %debggging
nmaster = numel(masterlist);
for n=1:nmaster
    dotdotdot(n,ceil(nmaster*0.1),nmaster)
    %disp(n)
    in = load([mcfg.loaddir '/' masterlist(n).name mcfg.searchsuffix]);

    Binfo = get_burstVector_05(bcfg,in.sta_cue);

    %store burst, spike info
    masterlist(n).spike.Binfo = Binfo;
    masterlist(n).spike.origtime = in.sta_cue.origtime;
    masterlist(n).spike.origtrial = in.sta_cue.origtrial;
    masterlist(n).spike.selnonburst = Binfo.burstVector{1}==0;
    masterlist(n).spike.selburst = Binfo.burstVector{1}==1;
    masterlist(n).isolationquality = in.sta_cue.isolationQuality;
    
    %figure out end points of sampled LFP segments
    time = in.sta_cue.time;
    ntr = size(in.sta_cue.trial,1);
    smpEndPoints = nan(ntr,2);
    for it=1:ntr
    	good = ~isnan( in.sta_cue.trial(it,:,:) );
        st = find(good,1);
        fn = find(good,1,'last');
        if isempty(st)
            masterlist(n).sampledLFPEndpoints(it,1) = nan;
            masterlist(n).sampledLFPEndpoints(it,2) = nan;
        else
            masterlist(n).sampledLFPEndpoints(it,1) = time(st);
            masterlist(n).sampledLFPEndpoints(it,2) = time(fn);

        end      
    end
end

%number of discarded trials
disp('...getting number of discarded trials')
%inart = load([mcfg.loaddir '/anacfg.mat']);
%inart = load(['/Volumes/DATA/DATA_BURST/RES_BURST_revision2/ana_burst_lfp/anacfg.mat']);
inart = load([mcfg.resdir '/anacfg.mat']);

for imaster = 1:nmaster
    ii = strfind(masterlist(imaster).name,'-A');
    dataname = masterlist(imaster).name(1:ii+1);
    iart = strncmp(inart.anacfg.datasets, dataname, numel(dataname) );

    masterlist(imaster).ndiscardedtrials = inart.anacfg.ndiscardedtrials(iart);
end

%get anatomy
if 1
    disp('...getting anatomy data')
    try
        masterlist = get_anatloc_burst(masterlist);
    catch
        warning('didnt extract the anatomical data...')
        [masterlist(:).ch1info] = deal([]);
    end
else
    [masterlist(:).ch1info] = deal([]);
end

%get celltypes
disp('...getting cell type')
W =  load('wFpreprocessed.mat');
nlist = numel(masterlist);
for n=1:nlist
    tmp = get_celltypes(masterlist(n),W);
    masterlist(n).celltype = tmp.ctype;
end

%save
disp('...saving masterlist')
sname = [mcfg.resdir '/' mcfg.savename '.mat'];
disp(sname)
save(sname,'masterlist','mcfg')

%output
if nargout > 0
    varargout{1} = masterlist;
end
