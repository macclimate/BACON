function [meansS, covsS,meansS1, covsS1,meansS2, covsS2,OutData,ind, RawData, header,EngUnits] = recalc(FileName)
%
%   [meansS, covsS,meansS1, covsS1,meansS2, covsS2,OutData, ind, RawData, header,EngUnits] = recalc(FileName)
%
%   This function is used to recalculate raw data (high freq.)
%   collected by the UBC eddy correlation system. It works on
%   files created between Apr 1996 and ??? 1997.
%
%   Inputs:
%       FileName        the name of the file with raw data
%   Outputs:
%       OutData         two-row matrix of the output values.
%                       For the column-definitions look in "boreas.key".
%
% (c) Zoran Nesic               File created:       Jan 28, 1997
%                               Last modification:  Sep  8, 1998
%

% Revisions:
%
%   Sep 8, 1998
%       - changed EngUnits = eng_met1(RawData, header);
%         to      EngUnits = eng_met1(RawData, header,0,0,0);
%         This forced the program to produce the results using the same algorithm
%         as the met200.exe (Basic eddy correlation program 1994-1997) - no dilution
%         and broadening corrections.

tic
% Read raw data file
[RawData,header] = read_met(FileName);
%disp(sprintf('Read_met = %f',toc));tic

% remove bad data (spiking caused by the communication errors)
Threshold = 1800;
ind = find(abs(RawData(1,:)) > Threshold | abs(RawData(2,:)) > Threshold | abs(RawData(3,:)) > Threshold);
RawData(:,ind) = [];
if length(ind) > 0
    fid = fopen('recalc.log','a');
    fprintf(fid,'%d of %d lines removed in %s\n',length(ind),length(RawData), FileName);
    fclose(fid);
end

%header(25)=0.999;

% change the calibration constants if they don't
% make sense
if header(76) > 1.1 | header(76) < 0.8 | abs(header(75))>100 | abs(header(74))>100
    header(77) = 1;
    header(75) = 22;
    header(76) = 0.908;
    header(74) = 36;
end
% Convert to Eng. units
EngUnits = eng_met1(RawData, header,0,0,0);

%disp(sprintf('Eng_met1 = %f',toc));tic

% calculate means and covariances
[meansS, covsS,meansS1, covsS1,meansS2, covsS2] =  met_calc(EngUnits, header);

% Finish calculation of fluxes and set up the output data matrix (OutData)
OutData = met_out(meansS, covsS,meansS1, covsS1,meansS2, covsS2, header, length(EngUnits));

% File name without the path
tmp = length(FileName);
Fname = FileName(tmp-10:tmp);

% Find the index in the data base where this data goes to
ind = findind(Fname,1996);

%OutData'
