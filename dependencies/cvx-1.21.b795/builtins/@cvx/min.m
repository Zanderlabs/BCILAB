function z = min( x, y, dim )

%   Disciplined convex/geometric programming information:
%       MAX is convex, log-log-concave, and nondecreasing in its first
%       two arguments. Thus when used in disciplined convex programs, 
%       both arguments must be concave (or affine). In disciplined 
%       geometric programs, both arguments must be log-concave/affine.

persistent remap remap_1 remap_2 remap_3
error( nargchk( 1, 3, nargin ) );
if nargin == 2,

    %
    % min( X, Y )
    %

    sx = size( x );
    sy = size( y );
    xs = all( sx == 1 );
    ys = all( sy == 1 );
    if xs,
        sz = sy;
    elseif ys || isequal( sx, sy ),
        sz = sx;
    else
        error( 'Array dimensions must match.' );
    end

    %
    % Determine the computation methods
    %

    if isempty( remap ),
        remap1 = cvx_remap( 'real' );
        remap1 = remap1' * remap1;
        remap2 = cvx_remap( 'log-concave' )' * cvx_remap( 'nonpositive' );
        remap3 = remap2';
        remap4 = cvx_remap( 'log-concave', 'real' );
        remap4 = remap4' * remap4;
        remap5 = cvx_remap( 'concave' );
        remap5 = remap5' * remap5;
        remap   = remap1 + ~remap1 .* ...
            ( 2 * remap2 + 3 * remap3 + ~( remap2 | remap3 ) .* ...
            ( 4 * remap4 + ~remap4 .* ( 5 * remap5 ) ) );
    end
    vx = cvx_classify( x );
    vy = cvx_classify( y );
    vr = remap( vx + size( remap, 1 ) * ( vy - 1 ) );
    vu = sort( vr(:) );
    vu = vu([true;diff(vu)~=0]);
    nv = length( vu );

    %
    % The cvx multi-objective problem
    %

    xt = x;
    yt = y;
    if nv ~= 1,
        z = cvx( sz, [] );
    end
    for k = 1 : nv,

        %
        % Select the category of expression to compute
        %

        if nv ~= 1,
            t = vr == vu( k );
            if ~xs,
                xt = cvx_subsref( x, t );
                sz = size( xt ); %#ok
            end
            if ~ys,
                yt = cvx_subsref( y, t );
                sz = size( yt ); %#ok
            end
        end

        %
        % Apply the appropriate computation
        %

        switch vu( k ),
        case 0,
            % Invalid
            error( 'Disciplined convex programming error:\n    Cannot perform the operation min( {%s}, {%s} )', cvx_class( xt, false, true ), cvx_class( yt, false, true ) );
        case 1,
            % constant
            cvx_optval = cvx( min( cvx_constant( xt ), cvx_constant( yt ) ) );
        case 2,
            % min( log-concave, nonpositive ) (no-op)
            cvx_optval = yt;
        case 3,
            % min( nonpositive, log-concave ) (no-op)
            cvx_optval = xt;
        case 4,
            % posy
            cvx_begin gp
                 hypograph variable zt( sz )
                xt >= zt; %#ok
                yt >= zt; %#ok
            cvx_end
        case 5,
            % non-posy
            cvx_begin
                hypograph variable zt( sz )
                xt >= zt; %#ok
                yt >= zt; %#ok
            cvx_end
        otherwise,
            error( 'Shouldn''t be here.' );
        end

        %
        % Store the results
        %

        if nv == 1,
            z = cvx_optval;
        else
            z = cvx_subsasgn( z, t, cvx_optval );
        end

    end

else

    %
    % min( X, [], dim )
    %

    if nargin > 1 && ~isempty( y ),
        error( 'min with two matrices to compare and a working dimension is not supported.' );
    end
    sx = size( x );
    if nargin < 2,
        dim = cvx_default_dimension( sx );
    elseif ~cvx_check_dimension( dim ),
        error( 'Third argument must be a positive integer.' );
    end

    %
    % Determine sizes, quick exit for empty arrays
    %

    sx = [ sx, ones( 1, dim - length( sx ) ) ];
    nx = sx( dim );
    if any( sx == 0 ),
        sx( dim ) = min( sx( dim ), 1 );
        z = zeros( sx );
        return
    end
    sy = sx;
    sy( dim ) = 1;

    %
    % Type check
    %

    if isempty( remap_3 ),
        remap_1 = cvx_remap( 'real' );
        remap_2 = cvx_remap( 'log-concave', 'real' );
        remap_3 = cvx_remap( 'concave' );
    end
    vx = cvx_reshape( cvx_classify( x ), sx );
    t1 = all( reshape( remap_1( vx ), sx ), dim );
    t2 = all( reshape( remap_2( vx ), sx ), dim );
    t3 = all( reshape( remap_3( vx ), sx ), dim );
    t3 = t3 & ~( t1 | t2 );
    t2 = t2 & ~t1;
    ta = t1 + ( 2 * t2 + 3 * t3 ) .* ~t1;
    nu = sort( ta(:) );
    nu = nu([true;diff(nu)~=0]);
    nk = length( nu );

    %
    % Quick exit for size 1
    %

    if nx == 1 && all( nu ),
        z = x;
        return
    end

    %
    % Permute and reshape, if needed
    %

    if dim > 1 && any( sx( 1 : dim - 1 ) > 1 ),
        perm = [ dim, 1 : dim - 1, dim + 1 : length( sx ) ];
        x   = permute( x,  perm );
        ta  = permute( ta, perm );
        sx  = sx(perm);
        sy  = sy(perm);
        dim = 1;
    else
        perm = [];
    end
    nv = prod( sx ) / nx;
    x  = reshape( x, nx, nv );

    %
    % Perform the computations
    %

    if nk ~= 1,
        z = cvx( [ 1, nv ], [] );
    end
    for k = 1 : nk,

        if nk == 1,
            xt = x;
        else
            tt = ta == nu( k );
            xt = cvx_subsref( x, ':', tt );
            nv = nnz( tt ); %#ok
        end

        switch nu( k ),
            case 0,
                error( 'Disciplined convex programming error:\n   Invalid computation: min( {%s} )', cvx_class( xt, false, true ) );
            case 1,
                cvx_optval = min( cvx_constant( xt ), [], dim );
            case 2,
                cvx_begin gp
                    hypograph variable zt( 1, nv )
                    xt >= ones(nx,1) * zt; %#ok
                cvx_end
            case 3,
                cvx_begin
                    hypograph variable zt( 1, nv )
                    xt >= ones(nx,1) * zt; %#ok
                cvx_end
            otherwise,
                error( 'Shouldn''t be here.' );
        end

        if nk == 1,
            z = cvx_optval;
        else
            z = cvx_subsasgn( z, tt, cvx_optval );
        end

    end

    %
    % Reverse the reshaping and permutation steps
    %

    z = reshape( z, sy );
    if ~isempty( perm ),
        z = ipermute( z, perm );
    end

end

% Copyright 2010 Michael C. Grant and Stephen P. Boyd.
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
