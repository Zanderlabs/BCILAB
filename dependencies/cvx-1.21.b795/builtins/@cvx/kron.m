function z = kron( x, y )
error( nargchk( 2, 2, nargin ) );

%Disciplined convex/geometric programming information for KRON:
%   KRON(X,Y) computes scalar products between every element of X and
%   every element of Y. Each of those scalar products must obey the
%   DCP or DGP ruleset.

%
% Check sizes and handle cases that can be computed
% using non-Kronecker products
%

sx = size( x );
sy = size( y );
if length( sx ) > 2 || length( sy ) > 2,
    error( 'N-D arrays not supported.' );
elseif sx( 2 ) == 1 && sy( 1 ) == 1,
    z = mtimes( x, y );
    return
elseif sx( 1 ) == 1 && sy( 2 ) == 1,
    z = mtimes( y, x );
    return
else
    sz = sx .* sy;
end

%
% Expand and multiply
%

[ ix, jx, vx ] = find(x);
[ iy, jy, vy ] = find(y);
ix = ix(:); jx = jx(:); nx = numel(ix); kx = ones(nx,1);
iy = iy(:); jy = jy(:); ny = numel(iy); ky = ones(ny,1);
t  = sy(1) * ( ix - 1 )';
iz = t( ky, : ) + iy( :, kx );
t  = sy(2) * ( jx - 1 )';
jz = t( ky, : ) + jy( :, kx );
z  = reshape( vy, ny, 1 ) * reshape( vx, 1, nx );
z  = sparse( iz, jz, z, sz(1), sz(2) );

% Copyright 2010 Michael C. Grant and Stephen P. Boyd.
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
