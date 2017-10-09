function sel = selectNearestToBounds(x,bnds)
% sel = selectNearestInBounds(x,bnds)

st = nearest(x,bnds(1));
fn = nearest(x,bnds(2));
sel = false(size(x));
sel(st:fn) = true;

