function err = fitlogi3(coeff,x)

%==========================================================================================
%   THIS PROGRAM DO THE BEST FIT OF RECTANGULAR
%       HYPERBOLA 
%       
%       Y = (1 /(a + b^((x-max)/max))) + c
%
%   First created on: 14 Nov 2007 by J Brodeur
%

global X Y;

y_hat=1./(coeff(1) + coeff(2).^(-(X-13)./13))+coeff(3);

err = sum((y_hat - Y).^2);