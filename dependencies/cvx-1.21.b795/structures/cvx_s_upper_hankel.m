function y = cvx_s_upper_hankel( m, n )
%CVX_S_UPPER_HANKEL Upper Hankel matrices.
c  = 0 : n - 1;
c  = c( ones( 1, m ), : );
r  = ( 0 : m - 1 )';
r  = r( :, ones( 1, n ) );
v  = abs( r + c ) + 1;
temp = v <= min( m, n );
y = sparse( v( temp ), r( temp ) + m * c( temp ) + 1, 1, min( m, n ), m * n );

% Copyright 2010 Michael C. Grant and Stephen P. Boyd. 
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
