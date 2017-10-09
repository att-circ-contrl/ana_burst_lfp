function fr = firingrate(interval,trial,time)
% rate = firingrate(interval,trial,time)

%check if some spikes arent on the interval
if nargin > 2
    sel = time >= interval(1) & time <= interval(2);
    trial(~sel) = [];
    time(~sel) = [];
end


%firing rate
ntrl = numel(unique(trial));
nspk = numel(trial);
dt = diff(interval);

fr = nspk ./ ntrl ./ dt;
