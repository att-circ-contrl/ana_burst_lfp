function chname = get_channel(name)
% namech = get_channel(name)

%get datasetname, chname    
ii = strfind(name,'_');

if numel(ii) < 4
    chname = '';
else
    st = ii(4) + 1;
    if numel(ii) < 6
        fn = numel(name);
    else
        fn = ii(6) - 1;
    end

    chname = name(st:fn);
end

%check that its legit
if ~( strncmp(chname,'AD',2) || strncmp(chname,'sig',3)...
        || strncmp(chname,'SP',2) || strncmp(chname,'FP',2) )
    chname = '';
end
