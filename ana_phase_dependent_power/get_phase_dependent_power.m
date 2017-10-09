function out = get_phase_dependent_power(list,datadir,foi,nbins)
% out = get_phase_dependent_power(list,datadir,foi,nbins)

disp('------------------------------------------------------------')
disp('getting phase dependent power...')
disp('------------------------------------------------------------')

cd(datadir)

%settings
eventstr = {'nonburst','burst'};
%nbins = 6;

%make phase bins
b = linspace(0,2*pi,nbins+1) - pi;
phbins = [b(1:end-1); b(2:end)];
bincentre = nanmean(phbins);
    

%init
dim = [numel(list), size(phbins,2), size(foi,1), numel(eventstr)];
pha_dep_pow = nan(dim);

%try, poolobj = parpool(3); end
for id=1:numel(list)
    name = list(id).stsname;
    disp( [num2str(id) ': ' name] )

    %get spectrum
    in = load(name);
    spectrum = squeeze(in.sts_cue.fourierspctrm{1});
    freq = in.sts_cue.freq;

    pow = abs(spectrum).^2;
    ph = angle(spectrum);

    %adjust phases to preferred phase, wrap to [-pi, pi]
    mu = circ_mean(ph);
    if 1
        phmu = bsxfun(@minus,ph,mu);
        phmu = wrapToPi(phmu);
    else
        phmu = ph;
        phmu = wrapTo2Pi(phmu);
    end

    %get power per phase bin
    pdptmp = [];
    for ievent=1:2
        selevent = list(id).spike.(['sel' eventstr{ievent}]);
        for ib = 1:size(phbins,2)
            for ifreq=1:numel(freq)
                selb = selInBounds(phmu(:,ifreq),phbins(:,ib));
                sel = selb & selevent;
                pdptmp(ib,ifreq,ievent) = nanmean(pow(sel,ifreq));                    
            end
        end
    end

    %average over FOI, and normalize
    pdptmp2 = [];
    for ifreq=1:size(foi,1)
        %average
        selfreq = selectNearestToBounds(freq,foi(ifreq,:));
        p = nanmean( pdptmp(:,selfreq,:), 2);

        %normalize, preserve all differences
        p = zscoreall(p);

        pdptmp2(:,ifreq,:) = p;
    end

    %store
    pha_dep_pow(id,:,:,:) = pdptmp2;
end

%output
out = [];
out.pha_dep_pow = pha_dep_pow;
out.freq = freq;
out.foi = foi;
out.phbins = phbins;
out.bincentre = bincentre;
out.eventstr = eventstr;
out.list = list;
out.dim = 'cell-bin-foi-event';
out.nbins = nbins;
