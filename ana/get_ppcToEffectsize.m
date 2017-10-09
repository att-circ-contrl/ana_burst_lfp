function effectSize = get_ppcToEffectsize(ppc)

% --- peak to trough modulation
effectPPC = ( 1 + 2.* sqrt(ppc)) ./ (1 - 2.*sqrt(ppc)); 
effectSize = real(effectPPC);
