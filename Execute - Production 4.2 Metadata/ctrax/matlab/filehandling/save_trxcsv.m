function save_trxcsv( filename, trx )
% save_trxcsv( filename, trx )
%
% Write TRX data to a CSV file. Format follows Ctrax CSV export.
%
% JAB 5/2/12

% count frames
n_frames = 0;
for f = 1:length( trx )
   n_frames = max( [n_frames, trx(f).endframe] );
end

data = zeros( [n_frames, length( trx )*6] ) - 1;

% rearrange data
for f = 1:length( trx )
   if isfield( trx, 'x_mm' ) && length( trx(f).x_mm ) == length( trx(f).x )
      x = trx(f).x_mm;
      y = trx(f).y_mm;
      a = trx(f).a_mm;
      b = trx(f).b_mm;
   else
      x = trx(f).x;
      y = trx(f).y;
      a = trx(f).a;
      b = trx(f).b;
   end
   
   data(trx(f).firstframe:trx(f).endframe,6*(f-1) + 1) = f;
   data(trx(f).firstframe:trx(f).endframe,6*(f-1) + 2) = x;
   data(trx(f).firstframe:trx(f).endframe,6*(f-1) + 3) = y;
   data(trx(f).firstframe:trx(f).endframe,6*(f-1) + 4) = a;
   data(trx(f).firstframe:trx(f).endframe,6*(f-1) + 5) = b;
   data(trx(f).firstframe:trx(f).endframe,6*(f-1) + 6) = trx(f).theta;   
end

% save data
save( filename, 'data', '-ascii' )
