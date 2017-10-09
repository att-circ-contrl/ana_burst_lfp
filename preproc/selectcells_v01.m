function list = selectcells_v01(masterlist,cfg)
%list = selectcells_v01(masterlist,lfptoi,nburst,bursttoi)
%
% cfg.lfptoi
% cfg.nburst
% cfg.bursttoi
% cfg.isolationQuality

%common

lfptoi = cfg.lfptoi;
nburst = cfg.nburst;
bursttoi = cfg.bursttoi;
isolationQuality = cfg.isolationQuality;
n = numel(masterlist);

%select cels with nbursts in bursttoi, and sampled LFP data in lfptoi
sellist = false(n,1);

for ii=1:n
    %burst spikes
    selBurst = masterlist(ii).spike.selburst;

    %number of sampled LFP poinst for that spike
    if ~isempty(masterlist(ii).sampledLFPEndpoints)
        sampledlfp = masterlist(ii).sampledLFPEndpoints(:,1) <= lfptoi(1) &...
            masterlist(ii).sampledLFPEndpoints(:,2) >= lfptoi(2);
    else
        sampledlfp = [];
    end
    
    %time of spike
    t = masterlist(ii).spike.origtime >= bursttoi(1) &...
        masterlist(ii).spike.origtime <= bursttoi(2);
    
    %isolation quality
    goodQual = ismember(masterlist(ii).isolationquality,isolationQuality);
    
    %was classfied?
    isClassified = ~isnan(masterlist(ii).celltype);
    
    %make sur enothing is empty, and then check to see if this cell meets
    %the specifications
    if ~any(cellfun(@isempty,{selBurst,sampledlfp,t,goodQual}))...
            && goodQual && isClassified...
            && sum(selBurst & sampledlfp & t) >= nburst
    
        sellist(ii) = true;
    end
end

list = masterlist(sellist);

for n=1:numel(list)
    list(n).lcfg = cfg;
end

%save
    
