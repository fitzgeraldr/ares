function mask = makemask(dims,imsize)

mask = zeros(imsize);

for j = 1:imsize(2)
    for i = 1:imsize(1)
        if dims(1)<j && j<dims(2) && dims(3)<i && i<dims(4)
            mask(i,j)=1;
            
        else
            mask(i,j) = 0;
        end
    end
end

return