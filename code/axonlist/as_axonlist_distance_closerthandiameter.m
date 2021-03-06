function [ToBeRm,Mtooclose]=as_axonlist_distance_closerthandiameter(axonlist,criteria,PixelSize)
% distance matrix
Mdist=as_axonlist_distancematrix(cat(1,axonlist.Centroid));
% minimal distance is mean diameter:
diams=cat(1,axonlist.axonEquivDiameter)./PixelSize;
diams=repmat(diams,[1,length(diams)]);
diams=mean(cat(3,diams,diams'),3)*criteria;

% convert to logical
Mtooclose=(Mdist-diams)<0;

ToBeRm=max(tril(Mtooclose),[],1);

