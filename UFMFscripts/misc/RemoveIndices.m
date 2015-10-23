function newidx = RemoveIndices(idx,idxremove)

maxidx = max(idx);
if islogical(idxremove),
  maxidx = max(maxidx,numel(idxremove));
else
  maxidx = max(maxidx,max(idxremove));
end
idxl = false(1,maxidx);
idxl(idx) = true;

idxl(idxremove) = [];
newidx = find(idxl);