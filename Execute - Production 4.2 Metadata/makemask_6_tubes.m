function mask = makemask_6_tubes(dims,imsize)

mask = zeros(imsize);

for t = 1:6
    for j = 1:imsize(2)
        for i = 1:imsize(1)
            imdim = dims{t};
            if imdim(1)<j && j<imdim(2) && imdim(3)<i && i<imdim(4)
                mask(i,j)=1;
            end
        end
    end
end

return