function sta_tmp = get_burstinfo(sta_cue,toi)
% sta_out = get_burstinfo(sta_cue)
% sta_out = get_burstinfo(sta_cue,toi)

if ischar(sta_cue)
    load(sta_cue)
end

if nargin<2
    toi = [];
end

disp('getting burst info...')
sta_tmp = sta_cue;
    
%restirct time window, maybe dont want burst trains that bleed into other
%epochs
if ~isempty(toi)
    selspkForBurst = sta_cue.origtime >= toi(1) & sta_cue.origtime <= toi(2);
else
    selspkForBurst = true(size(sta_cue.origtime));
end

sta_tmp.origtime(~selspkForBurst) = [];
sta_tmp.origtrial(~selspkForBurst) = [];
sta_tmp.trial(~selspkForBurst,:,:) = [];
                
%get bursts
bcfg = [];
bcfg.burstWindows = [0.005];%[0.005 0.010 0.015 ];
bcfg.preBurstQuiteness = 0; % if this is e.g. 0.03 then burst are by definition only depetected if they happen after a 30ms no-spike period
bcfg.toi = toi;

try
    Binfo = get_burstVector_05(bcfg,sta_tmp);
    
    %reformat Binfo to original spikes length
    ncell = numel(Binfo.burstVector);
    tmp = cell(ncell,1);
    [tmp{:}] = deal( nan(size(selspkForBurst)) );
    for ii=1:ncell
        tmp{ii}(selspkForBurst) = Binfo{ii};
    end
    Binfo.burstVector = tmp;
    Binfo.toi = toi;

catch
    str = sprintf('found no burst data for: %s',name);
    Binfo = [];
    warning(str)
end



%store
clear sta_tmp
sta_out = sta_cue;
sta_out.Binfo = Binfo;
sta_out.selspkForBurst = selspkForBurst; %keep track of the spikes we've selected
sta_out.bcfg = bcfg;

