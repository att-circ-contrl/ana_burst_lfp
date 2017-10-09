function cv = coefVar(isis)
% Function to calculate coeficient of variability CV

if(length(isis)>=2)
    cv=std(isis)/mean(isis);
else
    cv=nan;
end

