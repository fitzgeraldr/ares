% [mu,S,priors] = mygmm(X,k,...)
% Input:
% X: N x D matrix of N D-dimensional data points
% k: number of clusters
% optional:
% 'Replicates' = 1
% 'CovarType' = 'full'
% 'display' = -1
% 'precision' = .0001
% 'ResetCovar' = 1
% 'MaxIters' = 100
% 'Start' = 'furthestfirst'
% 'distance' = 'sqEuclidean'
% 'weights' = []
function [mu,S,priors,post] = gmm_lines_2d(X,k,endpoint,varargin)

[nreplicates,display,precision,resetcovar,maxiters,start,weights,allowed_endpoints] = ...
  myparse(varargin,'Replicates',1,...
  'display',-1,'precision',.0001,'ResetCovar',1,'MaxIters',100,...
  'Start','furthestfirst','weights',[],...
  'allowed_endpoints',[]);
              
[N,D] = size(X);
if D ~= 2,
  error('X must be N x 2');
end
if numel(endpoint) ~= 2,
  error('endpoint must be 1 x 2');
end
endpoint = reshape(endpoint,1,2);

if isstruct(start),
  nreplicates = length(start);
end

if isempty(allowed_endpoints),
  idxhull = convhull(X(:,1),X(:,2));
  allowed_endpoints = X(idxhull,:);
end
nallowed_endpoints = size(allowed_endpoints,1);
if nallowed_endpoints <= k,
  % TODO set mix to just the allowed_endpoints
end

minerr = inf;


for replicate = 1:nreplicates,

  % initialize
  if isstruct(start),
    mix = start(replicate);
  elseif ischar(start) && strcmpi(start,'furthestfirst'),
    % choose the point farthest from the fixed endpoint
    endpointidx = nan(1,k);
    mind = bsxfun(@minus,endpoint,allowed_endpoints).^2;
    [~,endpointidx(1)] = max(mind);
    
    for i = 1:k,
      [~,endpointidx(i)] = max(mind);
      if i == k, break; end
      d = bsxfun(@minus,allowed_endpoints(endpointidx(i),:),allowed_endpoints).^2;
      mind = min(mind,d);
    end
    
    
    
    
  end
    
    
    [idx,C] = mykmeans(X,k,kmeansparams{:});
    for i = 1:k,
      if ~any(idx==k),
        keyboard;
      end
    end
    % create gmm structure
    mix = mygmminit(X,C,idx,covartype);
  end

  if replicate == 1,
    mixsave = mix;
  end
  
  if isempty(weights),
    [mix,options,errlog,post] = gmmem(mix,X,options);
  else
    [mix,options,errlog,post] = gmmem_weighted(mix,X,weights,options);
  end
  if errlog(end) < minerr,
    minerr = errlog(end);
    mixsave = mix;
  end;

end;

mu = mixsave.centres;
S = mixsave.covars;
priors = mixsave.priors;