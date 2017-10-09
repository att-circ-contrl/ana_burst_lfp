function isis = isi(varargin)
% isis = isi(time,trial)
% isis = isi( [fieldtrip struct] )
% 
% time: Nx1 vector of spike times
% trial: Nx1 vector of spike trial
%
% can also accept fieldtrip sturcture

%to make it work with fieldtrip output, check if its a sturcture
if isstruct(varargin{1})
    time = varargin{1}.origtime;
    trial = varargin{1}.origtrial;
else
    time = varargin{1};
    trial = varargin{2};
end


%calculate ISIs
trls = unique(trial);
isis = []; 
for itrl=1:numel(trls)
   sel = trial==trls(itrl);

   d = diff( time(sel) );
   isis = [isis, d'];
end