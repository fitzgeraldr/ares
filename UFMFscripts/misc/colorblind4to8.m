function cm = colorblind4to8(n)

if nargin < 1,
  n = 8;
end

if n <= 4,
  
cm = [0.2 0.133333333333333 0.533333333333333
  0.533333333333333 0.8 0.933333333333333
  0.6 0.6 0.2
  0.666666666666667 0.266666666666667 0.6];

else

  cm = [0.2 0.133333333333333 0.533333333333333
    0.533333333333333 0.8 0.933333333333333
    0.0666666666666667 0.466666666666667 0.2
    0.866666666666667 0.8 0.466666666666667
    0.8 0.4 0.466666666666667
    0.666666666666667 0.266666666666667 0.6
    0.266666666666667 0.666666666666667 0.6
    0.533333333333333 0.133333333333333 0.333333333333333];
  
end
  
cm = cm(1:n,:);

