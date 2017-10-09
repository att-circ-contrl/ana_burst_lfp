function varargout=spkname2lfpname(name)
% [newname]=get_set_ch_name(name)
% - converts spk to lfp name, and vice versa
% - eg: mi_av17_114_01-A_FP003_lfp.mat -> mi_av17_114_01-A_SP003
% - eg: mi_av17_114_01-A_SP003b_wf_spk.mat -> mi_av17_114_01-A_FP003

%get the setname and channel
ind=findstr(name,'_');
if length(ind)>4; fn =ind(5) - 1;
else fn=length(name);
end

setname=name(1:ind(4)-1);
chname=name(ind(4)+1:fn);

%switch names
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

chname3 = [chtype, chname2];

newname = [setname '_' chname3];

varargout{1} = newname;
if nargout > 1
    varargout{2} = chname3;
end