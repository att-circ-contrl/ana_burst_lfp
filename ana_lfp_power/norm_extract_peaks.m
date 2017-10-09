function [normpsd,freqpeaksel,pks] = norm_extract_peaks(psd,freq,foi,pcfg)
% [normpsd,freqpeaksel,pks] = norm_extract_peaks(psd,freq,foi)
% [normpsd,freqpeaksel,pks] = norm_extract_peaks(psd,freq,foi,pcfg)
%
% normalizes PSD, and finds channels with peaks in the defined frequency
% ranges.
%  - normalization is per channel. Preserves differences in time
% 
% Inputs:
% - freq: 1xM vector defining the frequency range
% - PSD: matrix of size NxMxT matrix, correspondingt to N channels by M
%       frequencies and T tois
% - foi: Px2 matrix, defining the lower and upper limit of P frequency
%       bands
% - pcfg (optional): config for get_freqpks function. if empty, sets default

% normalize and get peaks of each channel...
normpsd = nan(size(psd));
for ich=1:size(psd,1)
    tmp = psd(ich,:,:);
    tmp = bsxfun(@times,tmp,freq);
    %tmp = bsxfun(@rdivide,tmp,max(tmp,[],2));
    %tmp = tmp ./ max(tmp(:));
    normpsd(ich,:,:) = normalizerange(tmp,[0 1],0);
end

if nargin<4
    pcfg = [];
    pcfg.threshscale = 0.5;
    pcfg.pkdetection = 'findpeaks';
    pcfg.freq = freq;
    pcfg.fscale = 0;
end

pks = {};
for id=1:size(normpsd,1)
    for it=1:size(psd,3)
        pks{id,it} = get_freqpks(normpsd(id,:,it),pcfg);
    end
end

%select cells with peak in the defined range
freqpeaksel = false(size(normpsd,1),2,size(normpsd,3));
for ifreq=1:size(foi,1)
    sel = cellfun(@(x) any( selInBounds(x,foi(ifreq,:)) ), pks);
    freqpeaksel(:,ifreq,:) = sel;
end

