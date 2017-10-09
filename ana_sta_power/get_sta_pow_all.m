function out = get_sta_pow_all(list,datadir,normtype,alph)
% out = get_sta_pow_all(list,datadir,normtype,alph)


    
%% ----------------------------------------------------------------------
%init
disp('-----------------------------------------------------------------')
disp('getting STA power...')
disp('-----------------------------------------------------------------')


cd(datadir)

eventstr = {'nonburst','burst'};

pow_all = [];
pow_split = [];
spk_info = {};

for id=1:numel(list)
    disp( ['cell: ' num2str(id)] )

    name = list(id).stsname;
    load(name);

    %get spectrum

    spectrum = sts_cue.fourierspctrm{1};

    pow = abs(spectrum).^2;
    pow = squeeze(pow);

    %get power
    pow_all(id,:) = nanmean(pow);

    for ievent=1:2
        selevent = list(id).spike.(['sel' eventstr{ievent}]);

        pow_split(id,:,ievent) = nanmean(pow(selevent,:));
    end
end



%% ----------------------------------------------------------------------
%dont adjst raw power
pow_all2 = pow_all;
pow_split2 = pow_split;
freqoi2 = sts_cue.freq;

%normalize
if nargin > 3 && ~isempty(alph)
    pow_all2 = bsxfun(@times,pow_all2,freqoi2.^alph);
    pow_split2 = bsxfun(@times,pow_split2,freqoi2.^alph);
end

if ~isempty(normtype)
    if strcmp(normtype,'range')
        normlim = [0 1];
        pow_all2 = normalizerange(pow_all2,normlim,2);

        for id=1:size(pow_split2)
            tmp = pow_split2(id,:,:);
            tmp = normalizerange(tmp,normlim,0);
            pow_split2(id,:,:) = tmp;
        end

        normstr = ['alph=' num2str(alph) ', [0 1] norm'];
    elseif strcmp(normtype,'znorm')
        pow_split2 = zscore(pow_split2,[],2);

        for id=1:size(pow_split2)
            tmp = pow_split2(id,:,:);
            tmp = zscoreall(tmp);
            pow_split2(id,:,:) = tmp;
        end

        normstr = ['alph=' num2str(alpha) ', znorm'];
    else
        error('unrecognized normlization')
    end
else
    normstr = '';
end

%% ----------------------------------------------------------------------
%output
out = [];
out.pow_all = pow_all2;
out.pow_split = pow_split2;
out.list = list;
out.normstr = normstr;
out.freq = freqoi2;
out.eventstr = eventstr;