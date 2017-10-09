function [sel,listout,cellstr] = selectCelltypes(list,anaCells)
% [sel,listout,cellstr] = selectCelltypes(list,anaCells)

celltypes = [list.celltype];
cellstr = {'ns','bs','fz'};
if strcmp(anaCells,'all')
    sel = true(size(list));
elseif strcmp(anaCells,'ns')
    sel = celltypes==1;
elseif strcmp(anaCells,'bs')
    sel = celltypes==2;
end

listout = list;
listout(~sel) = [];


