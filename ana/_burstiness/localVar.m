function lv = localVar(isis,minNumIsis)
% Function to calculate local variation Lv

%BV: check inputs
if ~iscolumn(isis); isis = isis'; end
if nargin<2; minNumIsis = 2; end
    
if(length(isis)>=minNumIsis)
    %trick to sum/diff pairs of elements
    isisSumMatrix=[isis(1:end-1) isis(2:end)];
    isisDiffMatrix=[isis(1:end-1) -isis(2:end)];
    lv=3/(length(isis)-1)*sum((sum(isisDiffMatrix,2)./sum(isisSumMatrix,2)).^2);
else
    lv=nan;
end

    

