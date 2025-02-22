function [tfr,rtfr,hat] = tfrrsp(x,t,N,h,trace);
%TFRRSP Reassigned Spectrogram.
%	[TFR,RTFR,HAT] = TFRRSP(X,T,N,H,TRACE) 
%	computes the spectrogram and its reassigned version.
% 
%	X     : analysed signal.
%	T     : the time instant(s)      (default : 1:length(X)).
%	N     : number of frequency bins (default : length(X)).
%	H     : frequency smoothing window, H(0) being forced to 1
%	                                 (default : Hamming(N/4)).
%	TRACE : if nonzero, the progression of the algorithm is shown
%	                                 (default : 0).
%	TFR,  : time-frequency representation and its reassigned
%	RTFR    version. When called without output arguments, 
%	        TFRRSP runs TFRQVIEW.
%	HAT   : Complex matrix of the reassignment vectors.
%
%	Example :
%	 sig=fmlin(128,0.1,0.4); t=1:2:128;
%	 h=tftb_window(17,'Kaiser'); tfrrsp(sig,t,64,h,1);
%
%	See also  all the time-frequency representations listed in
%	 the file CONTENTS (TFR*)

%	F. Auger, May-July 1994, July 1995.
%	Copyright (c) 1996 by CNRS (France).
%
%  This program is free software; you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation; either version 2 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program; if not, write to the Free Software
%  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

if (nargin == 0),
 error('At least 1 parameter required');
end;
[xrow,xcol] = size(x);
if (nargin <= 2),
 N=xrow;
end;

hlength=floor(N/4);
hlength=hlength+1-rem(hlength,2);

if (nargin == 1),
 t=1:xrow; h = tftb_window(hlength); trace=0;
elseif (nargin == 2)|(nargin == 3),
 h = tftb_window(hlength); trace=0;
elseif (nargin == 4),
 trace = 0;
end;

if (N<0),
 error('N must be greater than zero');
end;
[trow,tcol] = size(t);
if (xcol~=1),
 error('X must have only one column');
elseif (trow~=1),
 error('T must only have one row'); 
elseif (2^nextpow2(N)~=N),
 fprintf('For a faster computation, N should be a power of two\n');
end; 

[hrow,hcol]=size(h); Lh=(hrow-1)/2; 
if (hcol~=1)|(rem(hrow,2)==0),
 error('H must be a smoothing window with odd length');
end;

if (tcol==1),
 Dt=1; 
else
 Deltat=t(2:tcol)-t(1:tcol-1); 
 Mini=min(Deltat); Maxi=max(Deltat);
 if (Mini~=Maxi),
  error('The time instants must be regularly sampled.');
 else
  Dt=Mini;
 end;
 clear Deltat Mini Maxi;
end;

tfr= zeros(N,tcol); tf2= zeros(N,tcol); tf3= zeros (N,tcol);
if trace, disp('Spectrogram'); end;
Th=h.*[-Lh:Lh]'; Dh=dwindow(h);
for icol=1:tcol,
 ti= t(icol); 
 tau=-min([round(N/2)-1,Lh,ti-1]):min([round(N/2)-1,Lh,xrow-ti]);
 indices= rem(N+tau,N)+1;
 if trace, disprog(icol,tcol,10); end;
 norm_h=norm(h(Lh+1+tau));
 tfr(indices,icol)=x(ti+tau).*conj( h(Lh+1+tau)) /norm_h;
 tf2(indices,icol)=x(ti+tau).*conj(Th(Lh+1+tau)) /norm_h;
 tf3(indices,icol)=x(ti+tau).*conj(Dh(Lh+1+tau)) /norm_h;
end ;
tfr=fft(tfr);
% tf2=round(real(fft(tf2)./tfr/Dt));
% tf3=round(imag(N*fft(tf3)./tfr/(2.0*pi)));
tf2=fft(tf2);
tf3=fft(tf3);
tfr=tfr(:);tf2=tf2(:);tf3=tf3(:);
avoid_warn=find(tfr~=0);
tf2(avoid_warn)=round(real(  tf2(avoid_warn)./tfr(avoid_warn)/Dt));
tf3(avoid_warn)=round(imag(N*tf3(avoid_warn)./tfr(avoid_warn)/(2.0*pi)));
tfr=abs(tfr).^2;
if trace, fprintf ('\nreassignment: \n'); end;
tfr=reshape(tfr,N,tcol);
tf2=reshape(tf2,N,tcol);
tf3=reshape(tf3,N,tcol);

rtfr= zeros(N,tcol); 
Ex=mean(abs(x(min(t):max(t))).^2); Threshold=1.0e-6*Ex;
for icol=1:tcol,
 if trace, disprog(icol,tcol,10); end;
 for jcol=1:N,
  if abs(tfr(jcol,icol))>Threshold,
   icolhat= icol + tf2(jcol,icol);
   icolhat=min(max(icolhat,1),tcol);
   jcolhat= jcol - tf3(jcol,icol);
   jcolhat=rem(rem(jcolhat-1,N)+N,N)+1;
   rtfr(jcolhat,icolhat)=rtfr(jcolhat,icolhat) + tfr(jcol,icol) ;
   tf2(jcol,icol)=jcolhat + j * icolhat;
  else
   tf2(jcol,icol)=inf*(1+j);
   rtfr(jcol,icol)=rtfr(jcol,icol) + tfr(jcol,icol) ;
  end;
 end;
end;

if trace, fprintf('\n'); end;
clear tf3;
if (nargout==0),
 TFTBcontinue=1;
 while (TFTBcontinue==1),
  choice=menu ('Choose the representation:',...
               'stop',...
               'spectrogram',...
               'reassigned spectrogram');
  if (choice==1), TFTBcontinue=0;
  elseif (choice==2), 
   tfrqview(tfr,x,t,'tfrsp',h);
  elseif (choice==3),
   tfrqview(rtfr,x,t,'tfrrsp',h);
  end;
 end;
elseif (nargout>2),
 hat=tf2;
end;
