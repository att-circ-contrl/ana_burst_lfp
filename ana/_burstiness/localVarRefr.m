function lvR = localVarRefr(isis,R)
% Function to calculate revised local variation LvR. Parameter R represents
% refractory time

if(length(isis)>=2)
    %trick to sum/diff pairs of elements
    isisMatrix=[isis(1:end-1) isis(2:end)];
    for i=1:length(R)
        lvR(i)=3/(length(isis)-1)*sum((1-4*prod(isisMatrix,2)./sum(isisMatrix,2).^2).*(1+4*R(i)./(sum(isisMatrix,2).^2)));
    end
else
    for i=1:length(R)
        lvR(i)=nan;
    end
end
