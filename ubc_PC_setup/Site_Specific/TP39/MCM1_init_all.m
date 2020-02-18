%===============================================================
function c = MCM1_init_all(dateIn)
%===============================================================
%
% (c) Zoran Nesic           File created:       Oct 22, 2002
%                           Last modification:  Mar 19, 2018
%

%
%   Revisions:

% Mar 19, 2018 (Zoran)
%   - Merging Lab and Field ini files.  There was a difference between the
%     the two so this is the first attempt to unify them.
% Oct 18, 2017 (Zoran)
%   - Added options for resampling CSAT3 60Hz data: Dates(7) and Dates(8)
%   - Fixed up how the fr_instrument_align worked.  This will affect the
%   new and the old calculations. The old data will need to be reprocessed 
%   to assess how the fluxes will change.
% Aug 31, 2017 (Zoran)
%   - Changed delay time calculation reference channel.  It was:
%       c.System(nMainEddy).Delays.RefChan = 4
%     now:
%       c.System(nMainEddy).Delays.RefChan = 3
% Feb 10, 2004
%   - corrected 
%           'miscVariables.Tair = mean(Tair_a);',...
%       to 
%           'miscVariables.Tair = mean(Instrument_data(nSONIC).EngUnits(:,4));'
%     and commented it out.  The reason for commenting it out is to avoid
%     sonic temperature being used for the flux calculation.  Uncomment if
%     the sonic temp is the only available temperature.
% Apr 10, 2003
%  - Implemented use of covariance maximization for flux calc, reading
%    of climate data with fr_read_TurkeyPointClim, change LI7000 frequency to 20.34,
%    despiking, generation of short files
%  - added changes necessary for switching the data acquisition from DumpCOM to 
%    proper UBC RS232 programs (UBC_LI7000 and UBC_CSAT3)
%

Dates    = zeros(1,100);
% All times are GMT
Dates(1) = datenum(2002,4,1,0,30,0);           % system set up
Dates(2) = datenum(2003,4,14,0,30,0);         % Change from DumpCOM (Altaf needs to edit this!!!)
Dates(3) = datenum(2013,2,7,0,30,0);			% Licor motherboard upgraded.  Data output frequency changed
Dates(7) = datenum(2017,3,8,0,0,0);            % Date when CSAT3 started sampling at 60Hz for no good reason
Dates(8) = datenum(2017,10,1,20,0,0);          % Date when CSAT3 stopped sampling at 60Hz (it was reset to do 20Hz % following the usual CSAT3 setup procedure for UBC_GII)
Dates(9) = datenum(2017,12,6,0,0,0);            % Date when CSAT3 started sampling AGAIN at 60Hz for no good reason
Dates(10) = datenum(2018,1,10,0,0,0);            % Date when CSAT3 stopped sampling AGAIN at 60Hz (CSAT replaced)


											   
% The following line needs to be changed when dateIn becomes datenum (not a string yyyymmddQQ)
dateIn = datenum(str2num(dateIn(1:4)),str2num(dateIn(5:6)),str2num(dateIn(7:8)),str2num(dateIn(9:10))/96*24,0,0);

%-------------------------------
% Common 
%-------------------------------
c.PC_name       = fr_get_pc_name;
[c.path,c.hhour_path,c.database_path] = fr_get_local_path;
c.ext           = '.DMCM';
c.hhour_ext     = '.hMCM1.mat';
c.site          = 'MCM1';


% Instrument numbers in the order of their dependency
% (independent first)

nIRGA = 1;      % LI-7000 IRGA
%nCR10 = 2;      % CR10 logger
%nTC   = 3;       % Thermocouple measurements
nCSAT = 2;      % Sonic CSAT (depends on IRGA)
nPb   = 3;      % Barometric pressure
nTair = 4;      % Air temperature

% Variables listed within this section will become part of the
% output stats
if strcmp(c.PC_name, 'TP39_PC')
    c.MiscVariables(1).Name             = 'BarometricP';
	c.MiscVariables(1).Execute          = {'miscVar = 101.3;'};                 % use constant barometric pressure of 101.3 kPa, correct fluxes 
else
	c.MiscVariables(1).Name             = 'BarometricP';
	c.MiscVariables(1).Execute          = {['nPb = ' num2str(nPb) ';'],...
      'miscVar = mean(Instrument_data(nPb).EngUnits);'};
	  c.MiscVariables(2).Name             = 'Tair';
    c.MiscVariables(2).Execute          = {['nTair = ' num2str(nTair) ';'],...
      'miscVar = mean(Instrument_data(nTair).EngUnits);'};
end

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
%% Altaf
%%% Modified by JJB on June 20, 2011.  The listed column locations for P_irga and T_irga were switched for all dates after 20030414..
if dateIn <= Dates(2) 
   c.Instrument(nIRGA).FileType  = 'McMLI7000';            % 
	c.Instrument(nIRGA).ChanUnits =     {'umol/mol' ,'mmol/mol','kPa'   ,'degC'   ,'degC'   ,'mV'};   
    c.Instrument(nIRGA).ChanNames = 	{'co2'      ,'h2o'     ,'P_irga', 'T_irga','T_sonic','T_sonic_raw'};
else
   c.Instrument(nIRGA).FileType  = 'Digital2';            % 
	c.Instrument(nIRGA).ChanUnits = {'umol/mol' ,'mmol/mol', 'degC',	'kPa',    'mV',      '1'};   
c.Instrument(nIRGA).ChanNames = 	{'co2'      ,'h2o',	 'T_irga',	'P_irga', 'T_sonic', 'T_sonic_raw'};
end

% c.Instrument(nIRGA).FileType  = 'Digital2';            % 
% c.Instrument(nIRGA).ChanUnits = {'umol/mol' ,'mmol/mol','kPa'   ,'degC'   ,'mV'   ,'1'};   
    
if dateIn < Dates(3) % Modified 17-Jan-2014 by JJB to accomodate Motherboard change to li7000 in Feb of 2013
	c.Instrument(nIRGA).Fs         = 20.34;               % Frequency of sampling  
else
	c.Instrument(nIRGA).Fs         = 20;                     % Frequency of sampling
end    
%c.Instrument(nIRGA).Fs         = 20.34;               % Frequency of sampling
c.Instrument(nIRGA).Oversample = 6;                     % 
%c.Instrument(nIRGA).Oversample = 61;                     % 
c.Instrument(nIRGA).ChanNumbers = [1:6];                % chans to read from the Instrument(nIRGA)
c.Instrument(nIRGA).NumOfChans = length(c.Instrument(nIRGA).ChanNumbers);
%c.Instrument(nIRGA).ChanNames = {'co2'      ,'h2o'     ,'P_irga', 'T_irga','T_sonic','T_sonic_raw'};

c.Instrument(nIRGA).CovChans  = [1 2];
c.Instrument(nIRGA).Delays.Samples = [2 4]; % Changed by JJB, may 21, 2010 -- appropriate numbers for delays
c.Instrument(nIRGA).Alignment.Type = 'Slave';               % this instrument (Slave) will be aligned with the Master
c.Instrument(nIRGA).Alignment.ChanNum = 1; % Align using co2 here and Ts with the sonic, since aux input is screwed up
c.Instrument(nIRGA).Alignment.Shift = 0; 			% added by JJB, July 15, 2010
c.Instrument(nIRGA).Alignment.Span = [-100 100]; 		% added by JJB, July 15, 2010 % Changed to current values [-100 100] on Sep 8, 2010 by JJB on advice of Zoran 
c.Instrument(nIRGA).Alignment.MaxAutoSampleReduction = 3; 	% added by JJB, July 15, 2010 % Changed to current value 3 on Sep 8, 2010 by JJB on advice of Zoran 

c.Instrument(nIRGA).ProcessData = [];
% Conversion to mixing ratios - turned off in new version of program:
%c.Instrument(nIRGA).ProcessData = {['nIRGA = ' num2str(nIRGA) ';'],...
%      'Instrument_data(nIRGA).EngUnits(:,1) = Instrument_data(nIRGA).EngUnits(:,1)./(1-Instrument_data(nIRGA).EngUnits(:,2)./1000);',...
%      'Instrument_data(nIRGA).EngUnits(:,2) = Instrument_data(nIRGA).EngUnits(:,2)./(1-Instrument_data(nIRGA).EngUnits(:,2)./1000);',...
%   };  
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
if dateIn <= Dates(7)
    c.Instrument(nCSAT).Fs         = 20;                % Frequency of sampling
    c.Instrument(nCSAT).Resampling_type  = [];          % no resampling needed,
elseif dateIn > Dates(7) & dateIn <= Dates(8) 
    c.Instrument(nCSAT).Fs         = 60;                % Frequency of sampling
    c.Instrument(nCSAT).Resampling_type  = 2;           % 2 - CSAT3 60Hz data, resample by interpolating,
elseif dateIn > Dates(8) & dateIn <=Dates(9)
    c.Instrument(nCSAT).Fs         = 20;                % Frequency of sampling
    c.Instrument(nCSAT).Resampling_type  = [];          % no resampling needed,
elseif dateIn > Dates(9) & dateIn <= Dates(10) 
    c.Instrument(nCSAT).Fs         = 60;                % Frequency of sampling
    c.Instrument(nCSAT).Resampling_type  = 2;           % 2 - CSAT3 60Hz data, resample by interpolating,
elseif dateIn > Dates(10)
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
c.Instrument(nCSAT).Alignment.ChanNum = 3;            % channel used for the alignment (w),  % Changed from (T sonic, ch 4) on Sep 8, 2010 by JJB (from Zoran).
c.Instrument(nCSAT).Alignment.Shift = 0;
c.Instrument(nCSAT).Alignment.Span = [-100 100];
c.Instrument(nCSAT).Alignment.MaxAutoSampleReduction = [3]; 	% added by JJB, July 15, 2010 % Changed to current value 3 on Sep 8, 2010 by JJB on advice of Zoran

%-----------------------
% Barometer
%-----------------------
c.Instrument(nPb).Name       = 'Barometer';
c.Instrument(nPb).Type       = 'Vaisala pressure sensor';
c.Instrument(nPb).SerNum     = 0;
c.Instrument(nPb).FileType   = 'TurkeyPointClim';    % "Instrument" type file mean that an actual instrument should be used
c.Instrument(nPb).FileID     = '';   % (this is the datalogger database files)
c.Instrument(nPb).Fs         = 1;           % Frequency of sampling 
c.Instrument(nPb).Oversample = 0;   % 
c.Instrument(nPb).ChanNumbers = [1];  
c.Instrument(nPb).NumOfChans = 1;  
c.Instrument(nPb).ChanNames  = {'Pressure'};
c.Instrument(nPb).ChanUnits  = {'kPa'};
c.Instrument(nPb).Delays.Samples = [0];
c.Instrument(nPb).ProcessData = {['nPb = ' num2str(nPb) ';'],...
      'Instrument_data(nPb).EngUnits = Instrument_data(nPb).EngUnits(2);'...
      };
c.Instrument(nPb).CovChans   = [];
c.Instrument(nPb).Alignment.Type = '';
c.Instrument(nPb).Alignment.ChanNum = []; 

%-----------------------
% mean air temperature (best measurement of thermodynamic air temperature)
%-----------------------
c.Instrument(nTair).Name       = 'Mean Air Temperature';
c.Instrument(nTair).Type       = 'Tair';
c.Instrument(nTair).SerNum     = 0;
c.Instrument(nTair).FileType   = 'TurkeyPointClim';    % "Instrument" type file mean that an actual instrument should be used
c.Instrument(nTair).FileID     = '';   % (this is the datalogger database files)
c.Instrument(nTair).Fs         = 1;           % Frequency of sampling 
c.Instrument(nTair).Oversample = 0;   % 
c.Instrument(nTair).ChanNumbers = [1];  
c.Instrument(nTair).NumOfChans = 1;  
c.Instrument(nTair).ChanNames  = {'AirTemp_AbvCnpy'}; %modified from 'Ta_28m' by JJB on 20200217 - I think this has been wrong for a while.
c.Instrument(nTair).ChanUnits  = {'degC'};
c.Instrument(nTair).Delays.Samples = [0];
c.Instrument(nTair).ProcessData = {['nTair = ' num2str(nTair) ';'],...
      'Instrument_data(nTair).EngUnits = Instrument_data(nTair).EngUnits(1);'...
      };
c.Instrument(nTair).CovChans   = [];
c.Instrument(nTair).Alignment.Type = '';
c.Instrument(nTair).Alignment.ChanNum = []; 


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
%%% The following was commented out on Sep 18, 2010 by JJB at request of Zoran
c.System(nMainEddy).ProcessData = [];
%%% This correction is applied in new versions of fr_create_system_data.m, so must remove to avoid double-calculation
%c.System(nMainEddy).ProcessData = {['nSONIC = ' num2str(nCSAT) ';'],...
%      ['nIRGA = ' num2str(nIRGA) ';'],...
%      'Tair_v = Instrument_data(nSONIC).EngUnits(:,4)+273.15;',...
%      'H_mole_fraction = Instrument_data(nIRGA).EngUnits(:,2)./(1+Instrument_data(nIRGA).EngUnits(:,2)./1000);',...
%      'Tair_a = Tair_v./(1+0.32.*H_mole_fraction./1000);',...
%      'Instrument_data(nSONIC).EngUnits(:,4) = Tair_a-273.15;',...      
%   };

% Zoran: Feb 10, 2004 -> use the following line under .ProcessData if the
% sonic temperature is the only available air temperature
%      'miscVariables.Tair = mean(Instrument_data(nSONIC).EngUnits(:,4));',...

% Could be used for maximized covariance but fr_shift does no work with neg. delays
c.System(nMainEddy).Delays.Overide = 1; % Currently using default delays (see line 102) -- Need to change back to 1 : JJB, Jan 20, 2010

% removed, see below  c.System(1).MaxColumns      = 4+2;                      % Sonic + IRGA + TCs + (KH2O + Misc)
c.System(nMainEddy).MaxFluxes       = 15;
c.System(nMainEddy).MaxMisc         = 15;
c.System(nMainEddy).CovVector = [];                             % create CovVector and Delays vector 
c.System(nMainEddy).Alignment.Enable = 'FALSE';                 % do not do the alignment
c.System(nMainEddy).Alignment.SampleLength = 5000;
c.System(nMainEddy).Alignment.MaxAutoSampleReduction = 3;      % when aligning two instruments don't change the number of samples(don't resample) 
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

%------------------------------------------------
% Spike test 
%
%------------------------------------------------
c.Spikes.ON           = 1;

c.Spikes.bp_vect      = [1250:1250:floor(30 * 60 * c.Instrument(nCSAT).Fs)];
c.Spikes.spike_av     = 'c';
c.Spikes.spike_limit  = 5;
c.Spikes.spike_thold  = [0.25 0.25 0.25 0.2 3.65 0.5]; % 
c.Spikes.despike.ON   = 1;

%------------------------------------------------
% Stationarity test 
%
%------------------------------------------------
c.Stationarity.ON           = 0;

c.Stationarity.no_of_rec    = 6;
c.Stationarity.no_of_subrec = 6;
c.Stationarity.min_length   = 20 * 60 * c.Instrument(nCSAT).Fs; % Minimum record length in samples
c.Stationarity.stationVec   = [1 2 3 4 5 6];
c.Stationarity.stationRef   = 3;

%------------------------------------------------
% Spectral calculation 
%
%------------------------------------------------
c.Spectra.ON 					= 1;

c.Spectra.no_spec_bins     = 80;
c.Spectra.no_in_bin    	   = 20;
%c.Spectra.Fs        	   = 20.0; %set spectra calc frequency to that of system in do_eddy_calc.m
c.Spectra.nfft      		   = 2^15;
% No of pts returned by psd, the first is just the average of the data
c.Spectra.n_spec 			   = c.Spectra.nfft/2+1;

c.Spectra.noverlap         = 0;
% Here just give the name of the function used for windowing
c.Spectra.filtX            = 'hamming';
c.Spectra.dflag            = 'linear';

% This referes to the vector that is submitted to fr_calc_spectra which is 
% the same Eddy_HF_data that is required for fr_eddy_calc. If you want something 
% else change this before you calc the spectra
c.Spectra.psdVec           = [1 2 3 4 5 6];
c.Spectra.csdVec           = [1 2 4 5 6];
c.Spectra.csdRef           = 3; % Trace to do co-spectra against, mostly w
%------------------------------------------------
% Short file information
%
%------------------------------------------------
c.Shortfiles.Remove(1).System       = 'MainEddy'; %from this 'system' field remove the following fields below
c.Shortfiles.Remove(1).Fields       = {'Zero_Rotations'};
c.Shortfiles.Remove(1).ProcessData  = {...
      'for k = 1:length(st); st(k).MainEddy.Three_Rotations.LinDtr = []; end',...
      'for k = 1:length(st); st(k).MainEddy.Three_Rotations.AvgDtr.Cov = []; end',...
   };
%	   'for k = 1:length(st); st(k).MainEddy.Spectra.Csd = []; end;',...
%      'for k = 1:length(st); st(k).MainEddy.Spectra.fCsd = []; end;',...
%      'for k = 1:length(st); st(k).MainEddy.Spectra.fPsd = []; end;',...
%      'for k = 1:length(st); st(k).MainEddy.Spectra.Psd = st(k).MainEddy.Spectra.Psd(:,[4 5 6]); end',...

c.Shortfiles.Remove(2).System       = 'Instrument'; %from this 'system' field remove the following fields below
c.Shortfiles.Remove(2).Fields       = {'Name',...
      'Type',...
      'SerNum',...
      'ChanNames',...
      'ChanUnits',...
      'Avg',...
      'Min',...
      'Max',...
      'Std',...
      'MiscVariables',...
   };




