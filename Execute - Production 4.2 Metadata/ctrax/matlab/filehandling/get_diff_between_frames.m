
diff = zeros(length(header.timestamps)-1,1);
for i = 1:length(header.timestamps)-1
    diff(i) = header.timestamps(i+1)-header.timestamps(i);
end