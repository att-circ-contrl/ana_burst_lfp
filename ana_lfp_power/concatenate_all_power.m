function pow_all = concatenate_all_power(list,datadir,savepath,savename,itime)
% pow = concatenate_all_power(list,datadir,savepath,savename,itime)
%
% - if savename is empty, then it doesnt save
% - if itime is empty, loops ovr all times in pow_fft


disp('compiling all data...')

cd(datadir)
lfps = unique({list.lfpname});

str = sprintf('...analying %g unique LFP channels, based on %g cells',...
    numel(lfps),numel(list));
disp(str)

pow = [];
for n=1:numel(lfps)
    disp( [num2str(n) ': ' lfps{n}] )

    [name,ch] = get_set_ch_name(lfps{n});
    name = [name '_fft.mat'];
    in = load(name);
    
    ich = strcmp(in.pow_fft{1}.label,ch);
    if ~any(ich)
        error('no channel?')
    end
    
    %figure out what time points to loop over
    if nargin < 5 || isempty(itime)
        itime = 1:numel(in.pow_fft);
    end
    
    for it=1:numel(itime)
        it2 = itime(it);
        pow(n,:,it) = in.pow_fft{it2}.powspctrm(ich,:);
    end
end

%finalize 
pow_all = [];
pow_all.power = pow;
pow_all.itime = itime;
pow_all.toi = in.cfg.toi(itime,:);
pow_all.freq = in.pow_fft{1}.freq;
pow_all.list = list;
pow_all.lfpname = lfps;

%save
if isempty(savepath)
    savepath = pwd;
end
if ~isempty(savename)
    checkmakedir(savepath)
    sname = [savepath '/' savename '.mat'];
    save(sname,'pow_all')
end

