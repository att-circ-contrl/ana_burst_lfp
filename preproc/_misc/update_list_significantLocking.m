function listout = update_list_significantLocking(list,ang_stats,foi,savepath)
% listout = update_list_significantLocking(list,ang_stats,foi)
% listout = update_list_significantLocking(list,ang_stats,foi,savedir)

disp('updating list with phase locking information...')
tmp = ang_stats.list;
statsCellnames = {list.name};

listout = list;
for n=1:numel(list)
    name = list(n).name;
    ii = ismember(statsCellnames,name);
    
    if isempty(ii)
        listout(n).phaselocking = [];
        warning(['ang_stats doesnt contain this cell: ' name])
    else
        r = ang_stats.raystats(ii,:);
        a = ang_stats.ang_all(ii,:);
        freq = ang_stats.freqoi;

        listout(n).phaselocking = [];
        listout(n).phaselocking.freq = freq;
        listout(n).phaselocking.foi = foi;
        listout(n).phaselocking.raystat = r;
        listout(n).phaselocking.angle = a;
        listout(n).phaselocking.sigfoi = zeros(1,size(foi,1));
        
        for ifreq=1:size(foi,1)
            selfreq = selInBounds(freq,foi(ifreq,:));
            
            if any(r(selfreq)<0.05,2)
                listout(n).phaselocking.sigfoi(ifreq) = true;
            end                
        end
        
    end
end

% save list?
if nargin>3
    list = listout;
    save(savepath,'list')
end


