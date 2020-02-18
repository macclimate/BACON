function [REW] = VWC_to_REW(VWC,fc, wp)
% This function converts VWC to REW
% Updated on 2019-09-17 after discussion with Eric Beamesderfer: 
% Piechl et al. for TP39: field capacity was 0.16 and wilting point was between 0.01 and 0.04 
% for TP39. Could probably use 0.2 and 0.01 for both sites then? 
if nargin == 1
    fc = 0.2;
    wp = 0.01;
    disp('Using defaults for REW -> fc = 0.2, wp=0.01');
end

REW = (VWC-wp)./(fc - wp);