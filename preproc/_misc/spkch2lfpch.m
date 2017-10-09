function newchname = spkch2lfpch(chname)
% newchname = spkch2lfpch(chname)

%switch names

newchname = {};
if iscell(chname)
    for n=1:length(chname)
        newchname{n} = convertname(chname{n});
    end
else
    newchname = convertname(chname);
end


%converts chname
function newchname = convertname(chname)

if strncmp(chname,'sig',3)
    chtype = 'AD';
    chname2= chname(5:6);
elseif strncmp(chname,'SP',2)
    chtype =  'FP';
    chname2=chname(3:5);
elseif strncmp(chname,'AD',2)
    chtype =  'sig0';
    chname2=chname(3:4);
elseif strncmp(chname,'FP',2)
    chtype =  'SP';
    chname2=chname(3:5);
end

newchname = [chtype, chname2];

