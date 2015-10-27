% [bb,isfore] = backsub(im,mu,params)
%
% Performs background subtraction on the input image. If using box-based
% compression, it then finds the connected components and returns their
% bounding boxes in bb. Otherwise, it returns the foreground pixel
% locations in bb. 
%
% Inputs:
% im: Current frame. Assumed to be grayscale. 
% mu: Background image.
% params: Struct containing parameters. 
% 
% Outputs:
% bb: Bounding boxes of the connected components of foregroud pixels, where
% bb(j,:) is the jth bounding box and has the format [xmin, ymin, width,
% height].
% isfore: binary mask of foreground pixels. 
%
function [bb,diffim] = backsub(im,mu,params)

persistent UFMFDilateRadius;
persistent se;

if isempty(UFMFDilateRadius) || params.UFMFDilateRadius ~= UFMFDilateRadius,
  UFMFDilateRadius = params.UFMFDilateRadius;
  if UFMFDilateRadius > 0,
    se = strel('disk',UFMFDilateRadius);
  end
end

% compute difference
diffim = imabsdiff(im,mu);
if UFMFDilateRadius > 0,
  isfglow = diffim >= params.UFMFBackSubThreshLow;
end

% threshold
diffim = diffim >= params.UFMFBackSubThresh;

% dilate
if UFMFDilateRadius > 0,
  diffim = imdilate(diffim,se);
  diffim = diffim & isfglow;
end

% connected components
bb = regionprops(bwconncomp(diffim),'boundingbox','Area');
dokeep = [bb.Area] >= params.UFMFMinConnCompSize;
bb = cat(1,bb(dokeep).BoundingBox);
