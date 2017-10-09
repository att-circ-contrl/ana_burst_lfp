function masterlist=get_anatloc_burst(masterlist)
% get_anatloc(masterlist)

%if string, load in masterlist, overrides  masterlist variable
if ischar(masterlist)
    str = 'masterlist.mat';
    masterlistpath = masterlist;
    if strcmp(masterlistpath(end),'/'); masterlistpath(end) = []; end
    if ~strncmp(masterlist(end-numel(str):end),str,numel(str)) 
        masterlistpath = [masterlistpath '/' str];
    end
    load(masterlistpath); 
end


FLAT = load('A_UNITINFO_05_FLATXY');

%anatloc = struct('name',[],'ch1info',[]);

%datasets_mi{1}='ry_av09_055_01_aAD03_pAD01_PAC.mat';
for id = 1: length(masterlist);
    dotdotdot(id,ceil(numel(masterlist)*0.1),numel(masterlist))
    %updatecounter(id,[1 length(masterlist)],'chan # ')
    %disp(id)
    
    iName = masterlist(id).name;
    
    %anatloc(id).name = iName;
   
    %extract info about this channel
    if any( strcmp(iName(end-3:end),{'.mat','_spk','_sta'}) ); name_dataset = iName(1:end-4); 
    else name_dataset = iName;
    end
    
    [ch1info,~] = get_anatomicalLocations_05(FLAT, name_dataset);
    
    
    %check if we have informationa about the area. 
    % IF no info, make it empty for ease
    if sum(ch1info.iXYAREA) < 1
        ch1info.iXYAREA=[];
    else
        ch1info.iXYAREA=logical(ch1info.iXYAREA);
    end
    

    
    %save info about channel
    masterlist(id).ch1info = ch1info ;
    
end

%save
%sname = [resdir '/anatloc.mat'];
%save(sname,'anatloc');


