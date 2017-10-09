function ind = selectsamechannel(spikelabel,lfplabel,getLFPindex)
% ind = selectsamechannel(spikelabel,lfplabel,getLFPindex)

%checks
if ~iscell(spikelabel); spikelabel = {spikelabel}; end
if ~iscell(lfplabel); lfplabel = {lfplabel}; end

%delete the spike channel identifier
for n=1:length(spikelabel)
    ii = strfind(spikelabel{n},'_wf');
    if isempty('wf') || length(ii) > 1
        error('what kind of spike is this?!?!')
    end
    
    spikelabel{n} = spikelabel{n}(1:ii-2);
end

%convert to spike names
lfplabel = spkch2lfpch(lfplabel);

%get indices
if getLFPindex==0
    ind = find( ismember(spikelabel,lfplabel) );
elseif getLFPindex==1
    ind = find( ismember(lfplabel,spikelabel) );
else
    error('?!?!?!?')
end
