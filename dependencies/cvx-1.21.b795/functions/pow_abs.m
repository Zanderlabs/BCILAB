function y = pow_abs( x, p )

%POW_POS   Power of absolute value.
%   POW_POS(X,P) = ABS(X).^P. 
%   P must be real and greater than or equal to one.
%
%   Disciplined convex programming information:
%       POW_ABS(X,P) is convex and nonmonotonic, so X must be affine.
%       P must be constant, and its elements must be greater than or
%       equal to one. X may be complex.

error( nargchk( 2, 2, nargin ) );
if ~isnumeric( x ) || ~isnumeric( p ),
    error( 'Arguments must be numeric.' );
elseif ~isreal( p ),
    error( 'Second argument must be real.' );
elseif any( p(:) < 1 ),
    error( 'Second argument must be greater than or equal to one.' );
end
y = abs(x).^p;

% Copyright 2010 Michael C. Grant and Stephen P. Boyd. 
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
