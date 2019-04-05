%===============================================================
function c = HJP02_init_all(dateIn)
%===============================================================
%
% (c) Elyn Humphreys        File created:       Aug 28, 2003
%                           Last modification:  Feb 11, 2004 
%

%
%   Revisions:
% 
% Feb 11, 2004
%   - added LI-7000 calculations
% Jan 29, 2004 (Zoran)
%   - Modified Tair temperature calculations.  Moved the miscVariable.Tair calculation 
%     to c.System(nMainEddy) part of the program.  This insures that we use the best Tair
%     that we can get out of the Sonic.

Dates    = zeros(1,100);
% All times are GMT
Dates(1) = datenum(2002,9,30,0,30,0);                     % system set up

% The following line needs to be changed when dateIn becomes datenum (not a string yyyymmddQQ)
dateIn = datenum(str2num(dateIn(1:4)),str2num(dateIn(5:6)),str2num(dateIn(7:8)),str2num(dateIn(9:10))/96*24,0,0);

%-------------------------------
% Common 
%-------------------------------
c.PC_name       = fr_get_pc_name;
[c.path,c.hhour_path,c.database_path] = fr_get_local_path;
c.ext           = '.DH';
c.hhour_ext     = '.hHJP02.mat';
c.site          = 'HJP02';
localPCname	   = 'HJP02';							% check for this name later on to select 
															% dataBase option (see nTair below)

% Instrument numbers in the order of their dependency
% (independent first)

nSONIC = 1;     % Sonic CSAT3 
nIRGA_op  = 2;  % LI-7500 IRGA
nPb    = 3;     % barometric pressure (from IRGA)
nTair  = 4;     % from database if possible
nIRGA_cp = 5;   % LI-7000 IRGA

% Variables listed within this section will become part of the
% output stats
c.MiscVariables(1).Name             = 'BarometricP';
c.MiscVariables(1).Execute          = {['nPb = ' num2str(nPb) ';'],...
                                        'miscVar = 94;'};
%                                        'miscVar = mean(Instrument_data(nPb).EngUnits);'};                                
c.MiscVariables(2).Name             = 'Tair';
c.MiscVariables(2).Execute          = {['nTair = ' num2str(nTair) ';'],...
                                       'miscVar = mean(Instrument_data(nTair).EngUnits);'};


%------------------------------------------------
% All instruments
%------------------------------------------------
%-----------------------
% Sonic #1 definitions:
%-----------------------
c.Instrument(nSONIC).Name       = 'EC Anemometer';
c.Instrument(nSONIC).Type       = 'CSAT3';
c.Instrument(nSONIC).SerNum     = 0;
c.Instrument(nSONIC).FileType   = 'Digital2';        %
c.Instrument(nSONIC).FileID     = '5';               % String!
c.Instrument(nSONIC).Fs         = 20;                % Frequency of sampling
c.Instrument(nSONIC).Oversample = 6;                 % 
c.Instrument(nSONIC).ChanNumbers = [1:5];            % chans to read from
c.Instrument(nSONIC).NumOfChans = length(c.Instrument(nSONIC).ChanNumbers);
c.Instrument(nSONIC).ChanNames  = {'u','v','w','T_sonic','diag'};
c.Instrument(nSONIC).ChanUnits  = {'m/s','m/s','m/s','degC','1'};
c.Instrument(nSONIC).Poly       =  [1  0;...
     									1  0;...
    					  				1  0;...
   									   1  0; 
   										1 0 ];
c.Instrument(nSONIC).Delays.Samples = [0 0 0 0];
c.Instrument(nSONIC).ProcessData  = [];
c.Instrument(nSONIC).CovChans     = [1 2 3 4];
c.Instrument(nSONIC).Orientation  = 20;                   % degrees from North 
c.Instrument(nSONIC).Alignment.Type = 'Master';        % all instruments get aligned to this instrument (Master)
c.Instrument(nSONIC).Alignment.ChanNum = 3;            % chanel used for the alignment

%-----------------------
% IRGA #1 definitions:
%-----------------------
c.Instrument(nIRGA_op).Name      = 'EC IRGA OP';
c.Instrument(nIRGA_op).Type      = '7500';
c.Instrument(nIRGA_op).SerNum    = '';
c.Instrument(nIRGA_op).FileID     = '4';
c.Instrument(nIRGA_op).FileType   = 'Digital2';             % 
c.Instrument(nIRGA_op).Fs         = 20;                    % Frequency of sampling
c.Instrument(nIRGA_op).Oversample = 6;                     % 
c.Instrument(nIRGA_op).ChanNumbers = [1:8];                % chans to read from the Instrument(nIRGA_op)
c.Instrument(nIRGA_op).NumOfChans = length(c.Instrument(nIRGA_op).ChanNumbers);
c.Instrument(nIRGA_op).ChanNames  = {'co2','h2o','w_sonic','T_irga','P_air','diag','index','Cooler'};
c.Instrument(nIRGA_op).ChanUnits  = {'mmol/(m^3)','mmol/(m^3)','degC','degC','kPa','1','1','mV'};                           
c.Instrument(nIRGA_op).CovChans   = [1 2];
c.Instrument(nIRGA_op).Delays.Samples = [0 0];
c.Instrument(nIRGA_op).Alignment.Type = 'Slave';               % this instrument (Slave) will be aligned with the Master
c.Instrument(nIRGA_op).Alignment.ChanNum = 3;                  % chanel used for the alignment
c.Instrument(nIRGA_op).ProcessData = {['nIRGA_op = ' num2str(nIRGA_op) ';'],...
      '[c.Instrument(nIRGA_op).CO2_Cal, c.Instrument(nIRGA_op).H2O_Cal] = fr_get_manual_Licor_cal(char(configIn.site),dateIn);',...
      'Instrument_data(i).EngUnits(:,1) = (Instrument_data(i).EngUnits(:,1) + c.Instrument(nIRGA_op).CO2_Cal(2)).*c.Instrument(nIRGA_op).CO2_Cal(1);',...
      'Instrument_data(i).EngUnits(:,2) = (Instrument_data(i).EngUnits(:,2) + c.Instrument(nIRGA_op).H2O_Cal(2)).*c.Instrument(nIRGA_op).H2O_Cal(1);'};  

%-----------------------
% IRGA #2 definitions:
%-----------------------
c.Instrument(nIRGA_cp).Name      = 'EC IRGA';
c.Instrument(nIRGA_cp).Type      = '7000';
c.Instrument(nIRGA_cp).SerNum    = 0;
c.Instrument(nIRGA_cp).FileID    = '9';
c.Instrument(nIRGA_cp).FileType  = 'Digital2';            % 
c.Instrument(nIRGA_cp).ChanUnits = {'umol/mol' ,'mmol/mol','kPa'   ,'degC'   ,'mV'   ,'1'};   
c.Instrument(nIRGA_cp).Fs         = 20.345;               % Frequency of sampling
c.Instrument(nIRGA_cp).Oversample = 6;                     % 
%c.Instrument(nIRGA_cp).Oversample = 61;                     % 
c.Instrument(nIRGA_cp).ChanNumbers = [1:6];                % chans to read from the Instrument(nIRGA_cp)
c.Instrument(nIRGA_cp).NumOfChans = length(c.Instrument(nIRGA_cp).ChanNumbers);
c.Instrument(nIRGA_cp).ChanNames = {'co2'      ,'h2o'     ,'Tlicor', 'Plicor','T_sonic','Diag'};
c.Instrument(nIRGA_cp).CovChans  = [1 2];
c.Instrument(nIRGA_cp).Delays.Samples = [0 0];
c.Instrument(nIRGA_cp).Alignment.Type = 'Slave';               % this instrument (Slave) will be aligned with the Master
% Align using co2 here and Ts with the sonic, since aux input is srewed up
c.Instrument(nIRGA_cp).Alignment.ChanNum = 1;
% Conversion to mixing ratios
c.Instrument(nIRGA_cp).ProcessData = {['nIRGA_cp = ' num2str(nIRGA_cp) ';'],...
      'Instrument_data(nIRGA_cp).EngUnits(:,1) = Instrument_data(nIRGA_cp).EngUnits(:,1)./(1-Instrument_data(nIRGA_cp).EngUnits(:,2)./1000);',...
      'Instrument_data(nIRGA_cp).EngUnits(:,2) = Instrument_data(nIRGA_cp).EngUnits(:,2)./(1-Instrument_data(nIRGA_cp).EngUnits(:,2)./1000);',...
   };  



%-----------------------
% Barometer
%-----------------------
c.Instrument(nPb).Name       = 'Barometer';
c.Instrument(nPb).Type       = 'LI7500 pressure sensor';
c.Instrument(nPb).SerNum     = 0;
c.Instrument(nPb).FileType   = 'Instrument';    % "Instrument" type file mean that an actual instrument should be used
c.Instrument(nPb).FileID     = num2str(nIRGA_op);   % 
c.Instrument(nPb).Fs         = c.Instrument(str2num(c.Instrument(nPb).FileID)).Fs;           % Frequency of sampling 
c.Instrument(nPb).Oversample = c.Instrument(str2num(c.Instrument(nPb).FileID)).Fs;   % 
c.Instrument(nPb).ChanNumbers = [5];  
c.Instrument(nPb).NumOfChans = length(c.Instrument(nPb).ChanNumbers);  
c.Instrument(nPb).ChanNames  = {'Pbarometric'};
c.Instrument(nPb).ChanUnits  = {'kPa'};
c.Instrument(nPb).Poly       = [1  0];
c.Instrument(nPb).Delays.Samples = [0];
c.Instrument(nPb).ProcessData =  {['nPb = ' num2str(nPb) ';'],...
      'Pbarometric = mean(Instrument_data(nPb).EngUnits(:,1));', ...
      'Instrument_data(nPb).EngUnits = [];',...
      'Instrument_data(nPb).EngUnits = Pbarometric;'};
c.Instrument(nPb).CovChans   = [];
c.Instrument(nPb).Alignment.Type = '';
c.Instrument(nPb).Alignment.ChanNum = [];    

%-----------------------
% mean air temperature (best measurement of thermodynamic air temperature)
%-----------------------
c.Instrument(nTair).Name       = 'EC mean Tair';
c.Instrument(nTair).Type       = 'Tair';
c.Instrument(nTair).SerNum     = 0;
c.Instrument(nTair).FileType   = 'Instrument';    % "Instrument" type file mean that an actual instrument should be used
c.Instrument(nTair).FileID     = num2str(nSONIC);   %
c.Instrument(nTair).Fs         = c.Instrument(str2num(c.Instrument(nTair).FileID)).Fs;           % Frequency of sampling 
c.Instrument(nTair).Oversample = c.Instrument(str2num(c.Instrument(nTair).FileID)).Fs;   % 
c.Instrument(nTair).ChanNumbers = [4];  
c.Instrument(nTair).NumOfChans = length(c.Instrument(nTair).ChanNumbers);  
c.Instrument(nTair).ChanNames  = {'T_air'};
c.Instrument(nTair).ChanUnits  = {'degC'};
c.Instrument(nTair).Poly       = [1  0];
c.Instrument(nTair).Delays.Samples = [0];
c.Instrument(nTair).ProcessData = [];
c.Instrument(nTair).CovChans   = [];
c.Instrument(nTair).Alignment.Type = '';
c.Instrument(nTair).Alignment.ChanNum = []; 



% Space to add hooks for the programs that can be called from the main calc program
c.ExtraCalculations.InstrumentLevel = {};               % add all the extra calculations (Matlab statements as cells)
                                                        % that one wants performed on the instrument data
                                                        
%------------------------------------------------
% Eddy system 1
%
%------------------------------------------------
nMainEddy = 1;
c.System(nMainEddy).ON 				   = 1;                        % system #1 calculations are ON
c.System(nMainEddy).Type            = 'Eddy';                   % eddy correlation system
c.System(nMainEddy).Name            = 'Tower EC, HJP02 site';   % long system name
c.System(nMainEddy).FieldName       = 'MainEddy';               % this is the output structure field name for all the system stats
c.System(nMainEddy).Rotation        = 'three';                  % do three rotations
c.System(nMainEddy).Fs              = 20;                       % sampling freq. for the system (data will be resampled to
                                                                % match this frequency if needed)
c.System(nMainEddy).Instrument      = [ nSONIC nIRGA_cp];          % select instruments (Anemometer + IRGA) for system 1
% removed, see below  c.System(1).MaxColumns      = 4+2;                      % Sonic + IRGA + TCs + (KH2O + Misc)
c.System(nMainEddy).MaxFluxes       = 15;
c.System(nMainEddy).MaxMisc         = 15;
c.System(nMainEddy).CovVector = [];                             % create CovVector and Delays vectore 
c.System(nMainEddy).Delays.Samples = [];                        % based on the intrument setup
c.System(nMainEddy).Delays.RefChan = 4;                         % Delays calculated against this channel (T sonic)
c.System(nMainEddy).Delays.ArrayLengths = [5000 5000];          % the num of points used [ RefChan  DelayedChan]
c.System(nMainEddy).Delays.Span = 100;                          % max LAG (see fr_delay.m)
c.System(nMainEddy).Delays.Channels = [5 6];%[c.Instrument(nIRGA_op).CovChans];                    % Delays calculated on channels 5 and 6 (CO2 and H2O) 
c.System(nMainEddy).ProcessData = {[...
            'nIRGA_cp = ' num2str(nIRGA_cp) ';'],...
            ['nSONIC = ' num2str(nSONIC) ';'],...
            'Tair_v = Instrument_data(nSONIC).EngUnits(:,4)+273.15;',...
            'H_mole_fraction = Instrument_data(nIRGA_cp).EngUnits(:,2)./(1+Instrument_data(nIRGA_cp).EngUnits(:,2)./1000);',...
            'Tair_a = Tair_v./(1+0.32.*H_mole_fraction./1000);',...
            'Instrument_data(nSONIC).EngUnits(:,4) = Tair_a-273.15;',...      
            'miscVariables.Tair = mean(Instrument_data(nSONIC).EngUnits(:,4));',...
                                   };
totalChans = 0;
for i=1:length(c.System(nMainEddy).Instrument)
    nInstrument = c.System(nMainEddy).Instrument(i);
    c.System(nMainEddy).CovVector       = [ c.System(nMainEddy).CovVector ...
                                            c.Instrument(nInstrument).CovChans + totalChans ];
    c.System(nMainEddy).Delays.Samples  = [ c.System(nMainEddy).Delays.Samples  c.Instrument(nInstrument).Delays.Samples];
    totalChans                  = totalChans + c.Instrument(nInstrument).NumOfChans;
end
c.System(nMainEddy).MaxColumns = totalChans;

%------------------------------------------------
% add all the extra calculations (Matlab statements as cells)
% that one wants performed on the System data

c.ExtraCalculations.SystemLevel = {};
 
%------------------------------------------------
% Eddy system 2
%
%------------------------------------------------
nSecondEddy = 2;
c.System(nSecondEddy).ON 				   = 1;                        % system #1 calculations are ON
c.System(nSecondEddy).Type            = 'Eddy';                   % eddy correlation system
c.System(nSecondEddy).Name            = 'Tower EC, HJP02 site, Open Path System';   % long system name
c.System(nSecondEddy).FieldName       = 'SecondEddy';               % this is the output structure field name for all the system stats
c.System(nSecondEddy).Rotation        = 'three';                  % do three rotations
c.System(nSecondEddy).Fs              = 20;                       % sampling freq. for the system (data will be resampled to
                                                                % match this frequency if needed)
c.System(nSecondEddy).Instrument      = [ nSONIC nIRGA_op];          % select instruments (Anemometer + IRGA) for system 1
% removed, see below  c.System(1).MaxColumns      = 4+2;                      % Sonic + IRGA + TCs + (KH2O + Misc)
c.System(nSecondEddy).MaxFluxes       = 15;
c.System(nSecondEddy).MaxMisc         = 15;
c.System(nSecondEddy).CovVector = [];                             % create CovVector and Delays vectore 
c.System(nSecondEddy).Delays.Samples = [];                        % based on the intrument setup
c.System(nSecondEddy).Delays.RefChan = 4;                         % Delays calculated against this channel (T sonic)
c.System(nSecondEddy).Delays.ArrayLengths = [5000 5000];          % the num of points used [ RefChan  DelayedChan]
c.System(nSecondEddy).Delays.Span = 100;                          % max LAG (see fr_delay.m)
c.System(nSecondEddy).Delays.Channels = [5 6];%[c.Instrument(nIRGA_op).CovChans];                    % Delays calculated on channels 5 and 6 (CO2 and H2O) 
c.System(nSecondEddy).ProcessData = {['nIRGA_op = ' num2str(nIRGA_op) ';'],...
                                   ['nSONIC = ' num2str(nSONIC) ';'],...
                                   'Pbarometric = miscVariables.BarometricP;', ...
                                   'Tair_v = Instrument_data(nSONIC).EngUnits(:,4);',...
                                   'H_density = Instrument_data(nIRGA_op).EngUnits(:,2);',...
                                   'C_density = Instrument_data(nIRGA_op).EngUnits(:,1);',...
                                   'Tair_a = fr_Tair_Chi_Iteration(H_density, Tair_v, Pbarometric);',...
                                   'Instrument_data(nSONIC).EngUnits(:,4) = Tair_a;',...
                                   '[Cmix,Hmix] = fr_convert_open_path_irga(C_density, H_density,Tair_a,Pbarometric);', ...
                                   'Instrument_data(nIRGA_op).EngUnits(:,1) = Cmix;',...
                                   'Instrument_data(nIRGA_op).EngUnits(:,2) = Hmix;',...
                                   'miscVariables.Tair = mean(Tair_a);',...
                                   };
totalChans = 0;
for i=1:length(c.System(nSecondEddy).Instrument)
    nInstrument = c.System(nSecondEddy).Instrument(i);
    c.System(nSecondEddy).CovVector       = [ c.System(nSecondEddy).CovVector ...
                                            c.Instrument(nInstrument).CovChans + totalChans ];
    c.System(nSecondEddy).Delays.Samples  = [ c.System(nSecondEddy).Delays.Samples  c.Instrument(nInstrument).Delays.Samples];
    totalChans                  = totalChans + c.Instrument(nInstrument).NumOfChans;
end
c.System(nSecondEddy).MaxColumns = totalChans;

 
%------------------------------------------------
% Spike test 
%
%------------------------------------------------
c.Spikes.ON           = 1;

c.Spikes.bp_vect      = [1250:1250:floor(30 * 60 * c.Instrument(nSONIC).Fs)];
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
c.Stationarity.min_length   = 20 * 60 * c.Instrument(nSONIC).Fs; % Minimum record length in samples
c.Stationarity.stationVec   = [1 2 3 4 5 6];
c.Stationarity.stationRef   = 3;

%------------------------------------------------
% Spectral calculation 
%
%------------------------------------------------
c.Spectra.ON 					= 0;

c.Spectra.no_spec_bins     = 100;
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
c.Shortfiles.Remove(2).Fields       = { ...
      'Type',...
      'SerNum',...
      'ChanNames',...
      'ChanUnits',...
   };
%       'Name',...
%       'Avg',...
%       'Min',...
%       'Max',...
%       'Std',...
%       'MiscVariables',...


