function varargout=sts2bin(sts,varargin) 
% spiketrain=sts2bin(sts) 
% spiketrain=sts2bin(sts,time) 
% spiketrain=sts2bin(sts,time,ntrls) 
% spiketrain=sts2bin(sts,time,ntrls,ignoreEmptyTrials) 
% spiketrain=sts2bin(sts,time,ntrls,ignoreEmptyTrials,verbose) 
% [spiketrain,time]=sts2bin(...)
% [spiketrain,time,itrls]=sts2bin(...)
%
% Copyright 2017, Benjamin Voloh

if numel(varargin) < 4
    verbose = 0;
end

if verbose; disp('converting sts spike data to binary spiketrain'); end    

origtime=sts.origtime;
origtrial=sts.origtrial;

%intialize time if not provided as input
if length(varargin)>0 && ~isempty(varargin{1})
    time=varargin{1};
else
    st=min(origtime);
    fn=max(origtime);
    step=0.001;
    
    time=st:step:fn;
   
end

%round to prevent floating point errors
origtime=round( origtime*1000 );
time=round( time*1000 );

%check how many trials to loop over
if length(varargin)>1 && ~isempty(varargin{2})
    ntrls=varargin{2};
    
    if isvector(ntrls)
        itrls = ntrls;
        ntrls = max(itrls);
    else
        itrls = 1:ntrls;
    end
else
    ntrls = max(origtrial);
    itrls = 1:ntrls;
end


%find index of spike times in terms of the toi
[~,ind]=ismember(origtime,time);
z = ind==0;
origtrial(z) = [];
origtime(z) = [];
ind(z) = [];


%initialize spiektrain. Rows may include trials with NO events
spiketrain=false(ntrls,length(time));

%convert index of trial and spike time to linear index
linindex=sub2ind(size(spiketrain),origtrial,ind);
spiketrain(linindex)=true;

%select whtheer to get rid of non-relevant trials in final representation
if length(varargin)>2 && ~isempty(varargin{3})
    ignoreEmptyTrials=varargin{3};
else
    ignoreEmptyTrials=0;
end

if ignoreEmptyTrials
    del=~ismember(itrls,unique(origtrial));
    spiketrain(del,:)=[];
end

    
%{
for ii=1:size(spiketrain,1)
    seltrl=origtrial==ii; %find all instances of trial
    seltime=ismember(time,origtime(seltrl)); %find index of selected spikes in time
    
    spiketrain(ii,seltime)=true;
end
%}

%reconvert time
time=time*0.001;

%output
varargout{1} = double(spiketrain);
if nargout>1
    varargout{2}=time;
end

if nargout>2
    varargout{3}=itrls;
end
    


