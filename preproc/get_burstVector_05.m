function Binfo = get_burstVector_05(cfg, sts_cue)
% BV 12/09/2015: changed such that all spikes after first burst are listed
% according to their index (ie first spike==1, second spike==2...

dbstop if error

if isempty(cfg)
    cfg.preBurstQuiteness = 0;
    cfg.preBurstControlTimeWin = 0.02; % time where there should be less then 3 spikes before burst
    cfg.preBurstControlTimeWinNSpikes = 2;
end

if ~isfield(cfg,'preBurstQuiteness'), cfg.preBurstQuiteness = 0;                end
if ~isfield(cfg,'preBurstControlTimeWin'), cfg.preBurstControlTimeWin  = 0.02;  end
if ~isfield(cfg,'preBurstControlTimeWinNSpikes'), cfg.preBurstControlTimeWinNSpikes = 2;  end
if ~isfield(cfg,'burstWindows'),cfg.burstWindows = [ 0.003 0.005 0.010 0.015  0.020 0.030 0.050 0.10] ;  end
if ~isfield(cfg,'toi'),cfg.toi = [] ;  end

%restirct time windows, maybe we dont want bursts that bleed into other
%epochs
if ~isempty(cfg.toi)
    selspkForBurst = sts_cue.origtime >= cfg.toi(1) & sts_cue.origtime <= cfg.toi(2);
else
    selspkForBurst = true(size(sts_cue.origtime));
end
cfg.selspkForBurst = selspkForBurst;

sts_cue.origtime(~selspkForBurst) = [];
sts_cue.origtrial(~selspkForBurst) = [];
try sts_cue.trial(~selspkForBurst,:,:) = [];end %#ok


%init
Binfo = [];
Binfo.burstWin        = [];
Binfo.nBursts         = [];
Binfo.nNonBurstSpikes = [];
Binfo.burstProportion = [];
Binfo.burstDurationsMean = [];
Binfo.burstNumSpikesMean = [];
Binfo.burstDurations  = {};
Binfo.burstNumSpikes  = {};
Binfo.burstVector   = {};

%loop for all burst windows
for iB = 1:length(cfg.burstWindows)
    
    
    burstWin = cfg.burstWindows(iB);
    
    burstVector_A = zeros(size(sts_cue.origtrial));
    burstDurations  = [];
    burstNumSpikes  = [];
    
    % prewin = 20
    % minISI = 20
    % interbwins = 0.03;
    % interbwins = 0.03;
    % bwin  = 0.03;
    OTIME = sts_cue.origtime;
    %for n=1:5; OTIME(n+1)=OTIME(1)+0.002*n; end; %for testing
    %OTIME(217) = OTIME(216)+0.003; %for testing
    ISIs  = diff(OTIME);
    % --- set ISIs from Trial Transitions to zero
    trialchange = find(diff(sts_cue.origtrial));
    burstVector_A(trialchange) = -99;
    trialchange(trialchange >= length(burstVector_A)-1) = [];
    burstVector_A(trialchange) = -99;
    ISIs(trialchange) = 0;
    
    % sb = find(diff(OTIME(end-4:end))  <= 0.005);
    % sb = find(diff(OTIME)  <= 0.005);
    if cfg.preBurstQuiteness == 0
        sb = find(ISIs > 0  &  ISIs <= burstWin);
    else
        sb = find(ISIs > 0  &  ISIs <= burstWin & ([0; ISIs(1:end-1)]>=cfg.preBurstQuiteness));
    end
    
    lastsbindex = 0;
    for j=1:length(sb)
        
        if sb(j) <=lastsbindex, continue, end
        if sb(j) >=length(ISIs), continue, end
        % --- Ensure that there are less then 2 spikes in the preBurstControlWind
        
        moreThen2SpikesBeforeBurst = 0;
        if sb(j)-2 >0
            %make sure spikes were in the same trial
            sameTrial=find(sts_cue.origtrial == sts_cue.origtrial(sb(j)));
            nPreBurst=intersect(sameTrial, sb(j)-cfg.preBurstControlTimeWinNSpikes:sb(j)-1);
            if  ~isempty(nPreBurst) && sum(ISIs(nPreBurst)) <= cfg.preBurstControlTimeWin
                moreThen2SpikesBeforeBurst = 1;
            end
        end
        if moreThen2SpikesBeforeBurst == 1, continue, end
        
        % how many ISIs are in this burst ?
        %{
        for iN=1:15
            if  (sb(j)+iN)>length(ISIs), break, end %if bursts encompass current and next trial, ignore
            if ISIs(sb(j)+iN) <= burstWin && (ISIs(sb(j)+iN) ~= 0)
                % --- store the number of the intra burst spike for the current spike...
                %burstVector_A(sb(j)+iN) = -1*(iN+1);
                burstVector_A(sb(j)+iN) = iN+1;
                
            else
                break,
            end
        end
        %}
        
        % storing
        lastBurst = false;
        lastsbindex=sb(j);
        while ~lastBurst
            lastsbindex=lastsbindex+1;
            
            % if (1) the next ISI is too long, or (2) if this is a new trial
            % then previous ISI was the last one of the burst 

            if lastsbindex > length(ISIs) || ~( ISIs(lastsbindex) <= burstWin && (ISIs(lastsbindex) ~= 0) )
                lastsbindex=lastsbindex-1; 
                
                lastBurst=true;
            end
        end
        
        iburst=sb(j):lastsbindex+1; %add one because used diff
        burstVector_A(iburst)=1:length(iburst);
        burstDurations(end+1) = sum(ISIs(iburst(1:end-1)));
        burstNumSpikes(end+1) = length(iburst);
    end
    
    %test=[burstVector_A; sts_cue.origtime; sts_cue.origtrial];
    %test=[burstVector_A; OTIME; sts_cue.origtrial];
    
    Binfo.burstWin(iB)        =  burstWin;
    Binfo.nBursts(iB)         =  length(find(burstVector_A == 1));
    Binfo.nNonBurstSpikes(iB) =  length(find(burstVector_A == 0));
    Binfo.burstProportion(iB) =  Binfo.nBursts(iB) ./ (Binfo.nNonBurstSpikes(iB)+Binfo.nBursts(iB));
    Binfo.burstDurations{iB}  =  burstDurations;
    Binfo.burstNumSpikes{iB}  =  burstNumSpikes;
    Binfo.burstVector{iB}   =  burstVector_A;
    if isempty(Binfo.burstDurations{iB})
        Binfo.burstDurationsMean(iB)  =  NaN;
        Binfo.burstNumSpikesMean(iB)  =  NaN;
    else
        Binfo.burstDurationsMean(iB)  =  nanmean(burstDurations);
        Binfo.burstNumSpikesMean(iB)  =  nanmean(burstNumSpikes);
    end
end
Binfo.cfg = cfg;

%reformat Binfo to original spikes length
ncell = numel(Binfo.burstVector);
tmp = cell(ncell,1);
[tmp{:}] = deal( nan(size(selspkForBurst)) );
for ii=1:ncell
    tmp{ii}(selspkForBurst) = Binfo.burstVector{ii};
end
Binfo.burstVector = tmp;
Binfo.toi = cfg.toi;
%
return,
figure, plot(Binfo.burstWin,Binfo.burstProportion,'r-')
figure, plot(Binfo.burstWin,Binfo.burstDurationsMean,'b-')
figure, plot(Binfo.burstWin,Binfo.burstNumSpikesMean,'g-')

