function [fr,minInterval] = rate(spikes,spkTrain,interval,minInterval)
% Function to calculate firing rate and fano factor

spikeCount=length(spikes);

if(interval(2)==0)
    fr=nan;
else
    fr=spikeCount/(interval(2)-interval(1));
    if(interval(2)-interval(1)<minInterval)
        minInterval=interval(2)-interval(1);
    end
end

