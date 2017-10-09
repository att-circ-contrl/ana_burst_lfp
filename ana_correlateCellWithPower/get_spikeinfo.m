function spkinfo = get_spikeinfo(list,datadir,avgtype)
% spkinfo = get_spikeinfo(list,datadir)
% spkinfo = get_spikeinfo(list,datadir,avgtype)

cd(datadir)
if nargin<3; avgtype = 'mean'; end

% get spikeing info
for n=1:numel(list)
    name = [list(n).name '_staall.mat'];
    disp([num2str(n) ': ' name])

    in = load(name);

    spkinfo(n) = get_spikestuff(in.spk_cue);
    %spkinfo(n).name = list(n).name;
end

%update the names
for n=1:numel(list)
    spkinfo(n).name = list(n).name;
end

%display the averages
cellstr = {'ns','bs','all'};
celltype = [list.celltype];
fields = {'isi','localVar','fr','fano'};
for icell=1:2
    selcell = celltype==icell;

    disp('................................................')
    disp([cellstr{icell} ' cells....'])
    
    for ff=1:numel(fields)
        tmp = [spkinfo.(fields{ff})];
        tmp = tmp(selcell);
        
        [mu,se] = avganderror(tmp,avgtype,[],1,2000);
        
        str = sprintf( '  > %s: %.3g + %.3gSE',...
            fields{ff},mu,se);
        disp(str)
    end
end
        
        
        
        
        
function out = get_spikestuff(sta)
% out = get_spikestuff(sta)

%get stuff
interval = sta.cfg.latency;

if ~isempty(sta)
    t = sta.origtime;    
    tr = sta.origtrial;

    isis = isi(t,tr);
    LV = localVar(isis,2);
    FR = firingrate(interval,tr,t);
    F = fano(isis);
    %BP = burstProportion(sta.sp);
else
    isis = nan;
    LV = nan;
    FR = nan;
    F = nan;
    %BP = nan;
end


%output
out = [];
out.isi = isis;
out.localVar = LV;
out.fr = FR;
out.fano = F;
%out.burstProp = BP;


    