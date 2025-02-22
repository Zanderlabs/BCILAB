function cvx_pop( depth, clearmode )
global cvx___
if nargin < 2, clearmode = 'clear'; end

%
% Determine the index of the problem to be cleaned up
%

cvx_global
p = 0;
if ~isempty( cvx___.problems ),
    if nargin < 1 || isempty( depth ),
        depth = evalin( 'caller', 'cvx_problem', '[]' );
        if isempty( depth ),
            st = dbstack;
            depth = length(st) - 2;
        end
    end
    if isa( depth, 'cvxprob' ),
        p = index( depth );
        if p < 1 || p > length( cvx___.problems ) || cvx___.problems( p ).self ~= depth,
            p = 0;
        end
    end
end

%
% Determine the indices of the variables, constraints, etc.
%

if p < 1,
    p   =  1;
    pid = -1;
    nf  =  0;
    ne  =  1;
    nl  =  1;
    nu  =  1;
else
    prob = cvx___.problems( p );
    pid  = cvx_id( prob.self );
    nf   = length( prob.t_variable ) + 1;
    ne   = prob.n_equality + 1;
    nl   = prob.n_linform + 1;
    nu   = prob.n_uniform + 1;
end

%
% Clear the corresponding and equality constraints and variables
%

if ~isequal( clearmode, 'none' ),
    if nf <= 2,
        cvx___.reserved    = 0;
        cvx___.vexity      = 0;
        cvx___.canslack    = false;
        cvx___.readonly    = 0;
        cvx___.cones       = struct( 'type', {}, 'indices', {} );
        if ~isequal( clearmode, 'extract' ),
            cvx___.geometric   = sparse( 1, 1 );
            cvx___.exponential = sparse( 1, 1 );
            cvx___.logarithm   = sparse( 1, 1 );
        end
    elseif length( cvx___.reserved ) >= nf,
        temp = nf : length( cvx___.reserved );
        cvx___.reserved(    temp, : ) = [];
        cvx___.vexity(      temp, : ) = [];
        cvx___.canslack(    temp, : ) = [];
        cvx___.readonly(    temp, : ) = [];
        if ~isempty( cvx___.cones ),
            tt = true( 1, length( cvx___.cones ) );
            for k = 1 : length( cvx___.cones ),
                cvx___.cones( k ).indices( :, any( cvx___.cones( k ).indices >= nf, 1 ) ) = [];
                if isempty( cvx___.cones( k ).indices ), tt( k ) = false; end
            end
            cvx___.cones = cvx___.cones( 1, tt );
        end
        if ~isequal( clearmode, 'extract' ),
            cvx___.geometric(  temp, : ) = [];
            cvx___.exponential( temp, : ) = [];
            cvx___.logarithm(  temp, : ) = [];
        end
    end
    if nf <= 2 || ne <= 1,
        cvx___.equalities = cvx( [ 0, 1 ], [] );
        cvx___.needslack = ( false( 0, 1 ) );
    elseif length( cvx___.equalities ) >= ne,
        cvx___.equalities( ne : end ) = [];
        cvx___.needslack( ne : end ) = [];
    end
    if nf <= 2 || nl <= 1,
        cvx___.linforms = cvx( [ 0, 1 ], [] );
        cvx___.linrepls = cvx( [ 0, 1 ], [] );
    elseif length( cvx___.linforms ) >= nl,
        cvx___.linforms( nl : end ) = [];
        cvx___.linrepls( nl : end ) = [];
    end
    if nf <= 2 || nu <= 1,
        cvx___.uniforms = cvx( [ 0, 1 ], [] );
        cvx___.unirepls = cvx( [ 0, 1 ], [] );
    elseif length( cvx___.uniforms ) >= nu,
        cvx___.uniforms( nu : end ) = [];
        cvx___.unirepls( nu : end ) = [];
    end
    cvx___.nan_used = any( isnan( cvx___.vexity ) );
end

if ~isequal( clearmode, 'extract' ),
    
    %
    % Clear the workspace
    %

    if ~isequal( clearmode, 'reset' ),
        evalin( 'caller', 'clear cvx___' );
        s1 = evalin( 'caller', 'who' );
        if cvx___.hcellfun,
            s2 = sprintf( '%s, ', s1{:} );
            s2 = evalin( 'caller', sprintf( 'cellfun( @cvx_id, { %s } )', s2(1:end-2) ) );
        else
            nvars = numel(  s1  );
            s2 = zeros( 1, nvars );
            for k = 1 : nvars,
                s2(k) = cvx_id( evalin( 'caller', s1{k} ) );
            end
        end
        tt = s2 >= pid;
        s1 = s1( tt );
        s2 = s2( tt );
        if ~isempty( s1 ),
            switch clearmode,
                case 'value',
                    tt = s2 == pid;
                    if any( tt ),
                        evalin( 'caller', sprintf( '%s ', 'clear ', s1{tt} ) );
                        s1(tt) = [];
                    end
                    if ~isempty( s1 ),
                        temp = sprintf( '%s, ', s1{:} );
                        temp(end-1:end) = [];
                        evalin( 'caller', sprintf( '[ %s ] = cvx_values( %s );', temp, temp ) );
                    end
                case 'clear',
                    evalin( 'caller', sprintf( '%s ', 'clear', s1{:} ) );
                case 'none',
                    tt = find( s2 == pid );
                    if any( tt ),
                        evalin( 'caller', sprintf( '%s ', 'clear', s1{tt} ) );
                    end
            end
        end
    end
    
    %
    % Clear the problem stack and value vectors
    %

    cvx___.problems( p : end ) = [];
    cvx___.x = [];
    cvx___.y = [];
    if p == 1,
        cvx_clearpath( 1 );
    end
    
end

% Copyright 2010 Michael C. Grant and Stephen P. Boyd.
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
