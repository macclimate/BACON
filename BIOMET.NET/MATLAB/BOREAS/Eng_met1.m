function [EngUnits] = eng_met(RawData, header, DelayFlag,CO2corr,H2Ocorr)
%
%   [EngUnits] = eng_met(RawData, header, DelayFlag,CO2corr)
%
%
%   This file converts RawData to Eng. units. It uses the outputs
%   from read_met.m.
%
%   Inputs:
%
%       RawData     - matrix with raw data (see read_met.m)
%       header      - header data (see read_met.m)
%       DelayFlag   - 1 - no delay time correction,
%                     otherwise do delay time correction (default)
%       CO2corr     - 1 (default) full correction
%                     otherwise no correction
%       H2Ocorr     - 1 (default) output mixing ration (mmol/mol of dry air) using (Po/P)^0.9
%                     otherwise   output mmol/mol of wet air (chi) (Po/P)^1
%
%   Outputs:
%
%       EngUnits    - data in eng. units
%
% (c) Zoran Nesic           File created:       Mar 29, 1996
%   & Paul Yang             Last modification:  Sep  8, 1998
%

% Revisions:
%
%   Sep 8, 1998
%       - added H2Ocorr option to enable eng_met1 to output h2o as wet air or
%         as dry air. This was needed to keep compatibility with the original
%         on-line eddy correlation program (met2xx.exe, 1994-1997).
%
%       May 13, 1997
%                   Changed the order of calculation: now we do H2O first
%                   and then CO2 so we can use the water corrections to
%                   correct the CO2 values.
%                   licor_h now outputs EngUnits(6,:) (mmol/mol of dry air) and
%                   chi (mmol/mol of wet air). The latter is needed for the CO2
%                   correction.
%                   Introduced CO2corr and DelayFlag flags 
%       May 8, 1997
%                   Added delay time correction for the RawData
%                   Delay time correction used to be done in met_calc.m
%

if nargin < 5
    H2Ocorr = 1;                                % default is to do H2O as mixing ratio (wet air)
end
if nargin < 4
    CO2corr = 1;                                % default is to do CO2 corrections
end
if nargin < 3
    DelayFlag = 0;                              % default is to do delay time correction
end
if nargin < 2
    error 'Not enough input parameters!'
end
if header(2) ~= 83
    error 'Only Solent data is supported!'
end

%----------------------------------------------
% Remove the time delay from CO2 and H2O
% if needed
if DelayFlag ~= 1
    RawData = metshift(RawData, [5,header(5);6,header(5)]);
end 

MaxChannelsForSolent = 9;
[n,m] = size(RawData);
cc = min([n m]);
rr = max([n m]);
if cc ~= MaxChannelsForSolent 
    error 'Too many channels in RawData!'
elseif cc ~= n
    % 
    % Transpose RawData
    %
    RawData = RawData.';
end

%
% dimension the output matrix
%
EngUnits = zeros(cc,rr);

%
% Convert the wind speeds
%
ChanNum = 1;
EngUnits(ChanNum,:) = RawData(ChanNum,:) * header(27 + ChanNum);
ChanNum = 2;
EngUnits(ChanNum,:) = RawData(ChanNum,:) * header(27 + ChanNum);
ChanNum = 3;
EngUnits(ChanNum,:) = RawData(ChanNum,:) * header(27 + ChanNum);

%
% convert the air temperature
%
ChanNum = 4;
EngUnits(ChanNum,:) = ( ( RawData(ChanNum,:) .* 0.02).^2 ./403 .* header(31) - 273 ) .* header(81) + header(82);

%
% convert barometric pressure
%
ChanNum = 8;
v = RawData(ChanNum,:) .* header(73) + header(72);      % Voltage (mV) 
EngUnits(ChanNum,:) = ( v ./1000 .* header(26) + header(27) ) ./ 10;
EngUnits(ChanNum,:) = filter([0 1-header(25)], [1 -header(25)], EngUnits(ChanNum,:), mean(EngUnits(ChanNum,1:10)) );   % filtering

%
% convert gauge pressure
%
ChanNum = 9;
v = RawData(ChanNum,:) .* header(73) + header(72);      % Voltage (mV) 
EngUnits(ChanNum,:) = ( v ) .* header(78) + header(79);
EngUnits(ChanNum,:) = filter([0 1-header(37)], [1 -header(37)], EngUnits(ChanNum,:), mean(EngUnits(ChanNum,1:10)) );   % filtering

%
% h2o
%
ChanNum = 6;
hp = [header(62:-1:58) 0];
Th = header(54);
v = ( RawData(ChanNum,:) .* header(73) + header(72) ) / header(55) + header(56);      % Voltage (mV) before the offset box
if H2Ocorr == 0
    [EngUnits(ChanNum,:) chi] = licor_h( hp, Th, EngUnits(8,:), EngUnits(9,:), header(33),...
                                     header(75), header(77), v, 'm',1);
    EngUnits(ChanNum,:) = chi;      % user has requested mmol/mol of wet air
else
    [EngUnits(ChanNum,:) chi] = licor_h( hp, Th, EngUnits(8,:), EngUnits(9,:), header(33),...
                                     header(75), header(77), v, 'm');
end
%
% co2
%
ChanNum = 5;
cp = [header(47:-1:43) 0];
Tc = header(39);
v = ( RawData(ChanNum,:) .* header(73) + header(72) ) / header(40) + header(41);      % Voltage (mV) before the offset box

if CO2corr == 1
    EngUnits(ChanNum,:) = licor_c( cp, Tc, EngUnits(8,:), EngUnits(9,:), header(33),...
                                 header(74), header(76), v, 'm', chi,0,EngUnits(4,:));
else
    EngUnits(ChanNum,:) = licor_c( cp, Tc, EngUnits(8,:), EngUnits(9,:), header(33),...
                                 header(74), header(76), v, 'm');
end


%
% Krypton
%
ChanNum = 7;
v = RawData(ChanNum,:) .* header(73) + header(72);      % Voltage (mV) 
EngUnits(ChanNum,:) = log( abs( v / header(70) ) ) / header(71);
