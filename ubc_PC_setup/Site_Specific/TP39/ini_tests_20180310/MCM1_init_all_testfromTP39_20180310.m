%===============================================================
function c = MCM1_init_all(dateIn)
%===============================================================
%
% (c) Zoran Nesic           File created:       Oct 22, 2002
%                           Last modification:  Oct 18, 2017
%

%
%   Revisions:

% Mar 10, 2018 (JJB) [testing purposes]
%	- edited the name of the function, and extension beneath "% Common" section
%	- Also changed reference to FR_get_pc_name to proper case.
% Oct 18, 2017 (Zoran)
%   - Added options for resampling CSAT3 60Hz data: Dates(3) and Dates(4)
%   - Fixed up how the fr_instrument_align worked.  This will affect the
%   new and the old calculations. The old data will need to be reprocessed 
%   to assess how the fluxes will change.
% Aug 31, 2017 (Zoran)
%   - Changed delay time calculation reference channel.  It was:
%       c.System(nMainEddy).Delays.RefChan = 4
%     now:
%       c.System(nMainEddy).Delays.RefChan = 3
% Apr 10, 2003
%  - added changes necessary for switching the data acquisition from DumpCOM to 
%    proper UBC RS232 programs (UBC_LI7000 and UBC_CSAT3)
%

Dates    = zeros(1,100);
% All times are GMT
Dates(1) = datenum(2002,4,1,0,30,0);           % system set up
Dates(2) = datenum(2003,4,14,14,30,0);         % Change from DumpCOM (Altaf needs to edit this!!!)
Dates(3) = datenum(2017,3,8,0,0,0);            % Date when CSAT3 started sampling at 60Hz for no good reason
Dates(4) = datenum(2017,10,1,20,0,0);          % Date when CSAT3 stopped sampling at 60Hz (it was reset to do 20Hz 
                                               % following the usual CSAT3 setup procedure for UBC_GII)


% The following line needs to be changed when dateIn becomes datenum (not a string yyyymmddQQ)
dateIn = datenum(str2num(dateIn(1:4)),str2num(dateIn(5:6)),str2num(dateIn(7:8)),str2num(dateIn(9:10))/96*24,0,0);

%-------------------------------
% Common 
%-------------------------------
c.PC_name       = fr_get_pc_name;
[c.path,c.hhour_path] = FR_get_local_path; % edited by JJB [20180310] from fr_get_local_path;
c.ext           = '.DMCM'; %edited by JJB [20180310] from .dMcM
c.hhour_ext     = '.hMCM1.mat';  %edited by JJB [20180310] from .hMcM
c.site          = 'MCM1';%edited by JJB [20180310] from McM


% Instrument numbers in the order of their dependency
% (independent first)

nIRGA = 1;      % LI-7000 IRGA
%nCR10 = 2;      % CR10 logger
%nTC   = 3;       % Thermocouple measurements
nCSAT = 2;      % Sonic CSAT (depends on IRGA)

%nPb   = 3;      % barometric pressure (from LI-7500)


% Variables listed within this section will become part of the
% output stats
c.MiscVariables(1).Name             = 'BarometricP';
c.MiscVariables(1).Execute          = {'miscVar = 101.3;'};                 % use constant barometric pressure of 101.3 kPa, correct fluxes 
                                                                            % when correct pressure available

%c.MiscVariables(1).Execute          = {['nPb = ' num2str(nPb) ';'],...
%                                       'miscVar = mean(Instrument_data(nPb).EngUnits);'};

%------------------------------------------------
% All instruments
%------------------------------------------------
%-----------------------
% IRGA #1 definitions:
%-----------------------
c.Instrument(nIRGA).Name      = 'EC IRGA';
c.Instrument(nIRGA).Type      = '7000';
c.Instrument(nIRGA).SerNum    = 0;
c.Instrument(nIRGA).FileID    = '4';
if dateIn <= Dates(2) 
   c.Instrument(nIRGA).FileType  = 'McMLI7000';            % 
	c.Instrument(nIRGA).ChanUnits = {'umol/mol' ,'mmol/mol','kPa'   ,'degC'   ,'degC'   ,'mV'};   
else
   c.Instrument(nIRGA).FileType  = 'Digital2';            % 
	c.Instrument(nIRGA).ChanUnits = {'umol/mol' ,'mmol/mol','kPa'   ,'degC'   ,'mV'   ,'1'};   
end
c.Instrument(nIRGA).Fs         = 20;               % Frequency of sampling
c.Instrument(nIRGA).Oversample = 6;                     % 
%c.Instrument(nIRGA).Oversample = 61;                     % 
c.Instrument(nIRGA).ChanNumbers = [1:6];                % chans to read from the Instrument(nIRGA)
c.Instrument(nIRGA).NumOfChans = length(c.Instrument(nIRGA).ChanNumbers);
c.Instrument(nIRGA).ChanNames = {'co2'      ,'h2o'     ,'P_irga', 'T_irga','T_sonic','T_sonic_raw'};

c.Instrument(nIRGA).CovChans  = [1 2];
c.Instrument(nIRGA).Delays.Samples = [5 5];
c.Instrument(nIRGA).Alignment.Type = 'Slave';               % this instrument (Slave) will be aligned with the Master
c.Instrument(nIRGA).Alignment.ChanNum = 5;                  % chanel used for the alignment
c.Instrument(nIRGA).Alignment.Shift = 0;
c.Instrument(nIRGA).Alignment.Span = [-200 200];  
%-----------------------
% TC definitions:
%-----------------------
%c.Instrument(nTC).Name          = 'Thermocouples';
%c.Instrument(nTC).Type          = 'E';
%c.Instrument(nTC).SerNum        = 0;
%c.Instrument(nTC).FileID        = '6';
%c.Instrument(nTC).FileType      = 'McMTC';               % 
%c.Instrument(nTC).Fs            = 20;                    % Frequency of sampling
%c.Instrument(nTC).Oversample    = 6;                     % 
%c.Instrument(nTC).ChanNumbers   = [1:2];                 % chans to read from the Instrument(nIRGA)
%c.Instrument(nTC).NumOfChans    = length(c.Instrument(nTC).ChanNumbers);
% c.Instrument(nTC).ChanNames     = {'Tc1'      ,'Tc2' };
% c.Instrument(nTC).ChanUnits     = {'degC'     ,'degC'};
% c.Instrument(nTC).CovChans      = [];
% c.Instrument(nTC).Delays.Samples = [0 0];
% c.Instrument(nTC).Alignment.Type = 'Slave';               % this instrument (Slave) will be aligned with the Master
% c.Instrument(nTC).Alignment.ChanNum = 5;                  % chanel used for the alignment



%-----------------------
% Sonic #1 definitions:
%-----------------------
c.Instrument(nCSAT).Name       = 'EC Anemometer';
c.Instrument(nCSAT).Type       = 'CSAT3';
c.Instrument(nCSAT).SerNum     = 0;
if dateIn <= Dates(2) 
   c.Instrument(nCSAT).FileType   = 'McMCSAT3';        %
else
   c.Instrument(nCSAT).FileType   = 'Digital2';        %
end   
c.Instrument(nCSAT).FileID     = '5';               % String!
if dateIn <= Dates(3)
    c.Instrument(nCSAT).Fs         = 20;                % Frequency of sampling
    c.Instrument(nCSAT).Resampling_type  = [];          % no resampling needed,
elseif dateIn > Dates(3) & dateIn <= Dates(4) 
    c.Instrument(nCSAT).Fs         = 60;                % Frequency of sampling
    c.Instrument(nCSAT).Resampling_type  = 2;           % 2 - CSAT3 60Hz data, resample by interpolating,
elseif dateIn > Dates(4)
    c.Instrument(nCSAT).Fs         = 20;                % Frequency of sampling
    c.Instrument(nCSAT).Resampling_type  = [];          % no resampling needed,
end
c.Instrument(nCSAT).Oversample = 6;                % 
%c.Instrument(nCSAT).Oversample = 60;                % 
c.Instrument(nCSAT).ChanNumbers = [1:5];            % chans to read from
c.Instrument(nCSAT).NumOfChans = length(c.Instrument(nCSAT).ChanNumbers);
c.Instrument(nCSAT).ChanNames  = {'u2','v2','w2','Ts2','diag'};
c.Instrument(nCSAT).ChanUnits  = {'m/s','m/s','m/s','degC','1'};
c.Instrument(nCSAT).Delays.Samples = [0 0 0 0];
c.Instrument(nCSAT).ProcessData = [];
c.Instrument(nCSAT).CovChans   = [1 2 3 4];
c.Instrument(nCSAT).Orientation= 0;                   % degrees from North 
c.Instrument(nCSAT).Alignment.Type = 'Master';        % all instruments get aligned to this instrument (Master)
c.Instrument(nCSAT).Alignment.ChanNum = 4;            % chanel used for the alignment
c.Instrument(nCSAT).Alignment.Shift = 0;
c.Instrument(nCSAT).Alignment.Span = [-200 200];



% Space to add hooks for the programs that can be called from the main calc program
c.ExtraCalculations.InstrumentLevel = {};               % add all the extra calculations (Matlab statements as cells)
                                                        % that one wants performed on the instrument data
c.ExtraCalculations.SystemLevel = {};                   % add all the extra calculations (Matlab statements as cells)
                                                        % that one wants performed on the System data

%------------------------------------------------
% Eddy system 1
%
%------------------------------------------------
nMainEddy = 1;
c.System(nMainEddy).ON 				= 1;                         % system #1 calculations are ON
c.System(nMainEddy).Type            = 'Eddy';                   % eddy correlation system
c.System(nMainEddy).Name            = 'Tower EC, McM site';     % long system name
c.System(nMainEddy).FieldName       = 'MainEddy';               % this is the output structure field name for all the system stats
c.System(nMainEddy).Rotation        = 'three';                  % do three rotations
c.System(nMainEddy).Fs              = 20;                       % sampling freq. for the system (data will be resampled to
                                                                % match this frequency if needed)
c.System(nMainEddy).Instrument      = [ nCSAT nIRGA ];          % select instruments (Anemometer + IRGA) for system 1
% removed, see below  c.System(1).MaxColumns      = 4+2;                      % Sonic + IRGA + TCs + (KH2O + Misc)
c.System(nMainEddy).MaxFluxes       = 15;
c.System(nMainEddy).MaxMisc         = 15;
c.System(nMainEddy).CovVector = [];                             % create CovVector and Delays vector 
c.System(nMainEddy).Alignment.Enable = 'FALSE';                 % do not do the alignment
c.System(nMainEddy).Alignment.SampleLength = 5000;
c.System(nMainEddy).Alignment.MaxAutoSampleReduction = 5;      % when aligning two instruments don't change the number of samples(don't resample) 
                                                                % if del_1 <> del_2 by more than MaxAutoSampleReduction samples
                                                                
   c.System(nMainEddy).Delays.Overide      = 1;         % Do covariance maximisations
c.System(nMainEddy).Delays.Samples = [];                        % based on the intrument setup
c.System(nMainEddy).Delays.RefChan = 3;                         % Delays calculated against this channel (w sonic)
c.System(nMainEddy).Delays.ArrayLengths = [5000 5000];          % the num of points used [ RefChan  DelayedChan]
c.System(nMainEddy).Delays.Span = 100;                          % max LAG (see fr_delay.m)
c.System(nMainEddy).Delays.Channels = [5 6];                    % Delays calculated on channels 5 and 6 (CO2 and H2O) 
c.System(nMainEddy).ProcessData = {};
totalChans = 0;
for i=1:length(c.System(1).Instrument)
    nInstrument = c.System(1).Instrument(i);
    c.System(1).CovVector       = [ c.System(1).CovVector ...
                                            c.Instrument(nInstrument).CovChans + totalChans ];
    c.System(1).Delays.Samples  = [ c.System(1).Delays.Samples  c.Instrument(nInstrument).Delays.Samples];
    totalChans                  = totalChans + c.Instrument(nInstrument).NumOfChans;
end
c.System(1).MaxColumns = totalChans;



