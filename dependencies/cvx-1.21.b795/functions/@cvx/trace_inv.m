function cvx_optval = trace_inv( X ) %#ok

%TRACE_INV   Internal cvx version.

error( nargchk( 1, 1, nargin ) );
if ndims( X ) > 2,
    error( 'trace_inv is not defined for N-D arrays.' );
elseif ~cvx_isaffine( X ),
    error( 'Input must be affine.' );
end
n = size(X,1);
if n ~= size( X, 2 ),
    error( 'Matrix must be square.' );
end

%
% Construct problem
% 

cvx_begin sdp
    if isreal(X),
        variable Y(n,n) symmetric
    else
        variable Y(n,n) Hermitian
    end
    minimize(trace(Y));
    [Y,eye(n);eye(n),X] >= 0; %#ok
cvx_end

% Copyright 2010 Michael C. Grant and Stephen P. Boyd. 
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
