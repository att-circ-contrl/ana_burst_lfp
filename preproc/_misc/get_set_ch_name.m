function [setname,chname]=get_set_ch_name(name,flagCull)
% [setname,chname]=get_set_ch_name(name,flagCull)
ind=findstr(name,'_');
if numel(ind)==4; ind(5) = numel(name)+1; end

setname=name(1:ind(4)-1);
chname=name(ind(4)+1:ind(5)-1);

if nargin>1 && flagCull
    if strncmp(chname,'sig',3)
        chname2=chname(5:6);
    elseif strncmp(chname,'SP',2)
        chname2=chname(4:5);
    elseif strncmp(chname,'AD',2)
        chname2=chname(3:4);
    elseif strncmp(chname,'FP',2)
        chname2=chname(4:5);
    end
    
    chname=chname2;
end