function im = videoioreadframe(readerobj,f)

% seek(readerobj,double(f));
% im = getframe(readerobj);
im = read( readerobj, f ); % JAB 9/24/11
