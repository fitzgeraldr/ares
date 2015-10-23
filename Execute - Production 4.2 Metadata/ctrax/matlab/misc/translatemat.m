% y = translatemat(x,u,v)
% replace each instance of u(i) with v(i) in x.
% return result in y.
function y = translatemat(x,u,v)

[ism,idx] = ismember(x,u);
if any(~ism),
  warning('%d elements of x are not in u',nnz(~ism));
end

y = x;
y(ism) = v(idx(ism));