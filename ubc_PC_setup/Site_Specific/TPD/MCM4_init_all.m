function c = MCM4_init_all(dateIn)
%===============================================================
%
% (c) Zoran Nesic           File created:       Oct 20, 2011
%                           Last modification:  Oct 20, 2011
%

%
%   Revisions:
%
%

%persistent lastDBupdate

Dates    = zeros(1,100);
% All times are GMT
Dates(1) = datenum(2011,10,30,0,30,0);                     % system set up

% The following line needs to be changed when dateIn becomes datenum (not a
% string yyyymmddQQ)
dateIn = datenum(str2num(dateIn(1:4)),str2num(dateIn(5:6)),str2num(dateIn(7:8)),str2num(dateIn(9:10))/96*24,0,0); %#ok<*ST2NM>

%-------------------------------
% Common 
%-------------------------------
c.PC_name       = fr_get_pc_name;
[c.path,c.hhour_path,c.database_path,c.csi_path] = fr_get_local_path;
c.ext           = '.DMCM4'; % 20120222 - changed case of 'd' 
c.hhour_ext     = '.hMCM4.mat';
c.hhour_ch_ext  = '.hMCM4_ch.mat';
c.site          = 'MCM4';
c.gmt_to_local  = -5/24;
% dataBase option (see nTair below)


% Instrument numbers in the order of their dependency
% (independent first)

nIRGA = 1;             % LI-7200
nSONIC = 2;            % Sonic CSAT3 
nCLIMATE = 3;          % CR3000 logger
nPb_site   = 4;        % barometric pressure (from IRGA)
nTair_site = 5;        % from database if possible

% Variables listed within this section will become part of the
% output stats
if strcmp(c.PC_name, 'TPD_PC')
    c.MiscVariables(1).Name             = 'BarometricP';
	c.MiscVariables(1).Execute          = {'miscVar = 101.3;'};                 % use constant barometric pressure of 101.3 kPa, correct fluxes 
else
c.MiscVariables(1).Name      = 'BarometricP';
% c.MiscVariables(1).Execute   = {['nPb = ' num2str(nPb_site) ';'],...
                                 % 'miscVar = Instrument_data(nPb).EngUnits;'};
% Modified by JJB on 20180324, to run fr_p_bar. 								 
c.MiscVariables(1).Execute          = {['nTair = ' num2str(nTair_site) ';'],...
        ['nPb = ' num2str(nPb_site) ';'],...
        'miscVar = fr_p_bar(Instrument_data(nPb).EngUnits,35,Instrument_data(nTair).EngUnits);'};								 
c.MiscVariables(2).Name      = 'Tair';
c.MiscVariables(2).Execute   = {['nTair = ' num2str(nTair_site) ';'],...
                                 'miscVar = Instrument_data(nTair).EngUnits;'};
end
%------------------------------------------------
% Calibration tank values
%------------------------------------------------

if dateIn > Dates(1)
   c.cal1 = 400.00;   % fake value.  MCM4: fix when you get the first field tank
end

c.cal2 = NaN;

%------------------------------------------------
% All instruments
%------------------------------------------------
%-----------------------
% Sonic definitions:
%-----------------------
c.Instrument(nSONIC).Name       = 'EC Anemometer';
c.Instrument(nSONIC).Type       = 'CSAT3';
c.Instrument(nSONIC).SerNum     = 0;
c.Instrument(nSONIC).FileType   = 'Digital2'; 
c.Instrument(nSONIC).FileID     = '2';               % String!
c.Instrument(nSONIC).Fs         = 20;                % Frequency of sampling
c.Instrument(nSONIC).Oversample = 6;                 % 
c.Instrument(nSONIC).ChanNumbers = (1:5);            % chans to read from
c.Instrument(nSONIC).NumOfChans = length(c.Instrument(nSONIC).ChanNumbers);
c.Instrument(nSONIC).ChanNames  = {'u','v','w','T_sonic','diag'};
c.Instrument(nSONIC).ChanUnits  = {'m/s','m/s','m/s','degC','1'};
c.Instrument(nSONIC).Poly       =  [ 1  0;...
                                    1  0;...
                                    1  0;...
                                    1  0; 
                                    1  0 ];
c.Instrument(nSONIC).Delays.Samples = [0 0 0 0];
c.Instrument(nSONIC).ProcessData  = [];
c.Instrument(nSONIC).CovChans     = [1 2 3 4];
c.Instrument(nSONIC).Orientation  = 0;                 % degrees from North 
c.Instrument(nSONIC).Alignment.Type = 'Master';        % all instruments get aligned to this instrument (Master)
c.Instrument(nSONIC).Alignment.ChanNum = 3; 
c.Instrument(nSONIC).Alignment.Shift = 0;
c.Instrument(nSONIC).Alignment.Span = [-200,200];


%-----------------------
% IRGA definitions:
%-----------------------
c.Instrument(nIRGA).Name      = 'EC IRGA';
c.Instrument(nIRGA).Type      = '7200';
c.Instrument(nIRGA).SerNum    = 273;
c.Instrument(nIRGA).FileID     = '3';
c.Instrument(nIRGA).FileType   = 'Digital2';             % 
c.Instrument(nIRGA).Fs         = 20;                    % Frequency of sampling
c.Instrument(nIRGA).Oversample = 6;                     % 
c.Instrument(nIRGA).ChanNumbers = (1:9);                % chans to read from the Instrument(nIRGA)
c.Instrument(nIRGA).NumOfChans = length(c.Instrument(nIRGA).ChanNumbers);
c.Instrument(nIRGA).ChanNames  = {'co2'     ,'h2o'     ,'Tin' ,'Tout','Pcell','Pdiff','w_wind','Cooler','diag'};
c.Instrument(nIRGA).ChanUnits  = {'umol/mol','mmol/mol','degC','degC','kPa'  ,'kPa'  ,'m/s'   ,'mV'    ,'1'};                           
c.Instrument(nIRGA).CovChans   = [1 2];
c.Instrument(nIRGA).Delays.Samples = [0 0];
c.Instrument(nIRGA).Alignment.Type = 'Slave';               % this instrument (Slave) will be aligned with the Master
c.Instrument(nIRGA).Alignment.ChanNum = 7;                  % chanel used for the alignment
c.Instrument(nIRGA).ProcessData = {};  
c.Instrument(nIRGA).Alignment.Shift = 0;
c.Instrument(nIRGA).Alignment.Span = [-200,200];

%-----------------------
% CLIMATE definitions:
%-----------------------
c.Instrument(nCLIMATE).Name      = 'CLIMATE_DATA';
c.Instrument(nCLIMATE).Type      = 'CR3000';
c.Instrument(nCLIMATE).SerNum    = 6347;
c.Instrument(nCLIMATE).FileID     = 'CR3000_Thirty_Min.dat';
c.Instrument(nCLIMATE).FileType   = 'TOA5';             % 
c.Instrument(nCLIMATE).Fs         = 1/1800;                    % Frequency of sampling
c.Instrument(nCLIMATE).Oversample = 0;                     % 
c.Instrument(nCLIMATE).ChanNumbers = [4 6 ];                % chans to read from the Instrument(nIRGA)
c.Instrument(nCLIMATE).NumOfChans = length(c.Instrument(nCLIMATE).ChanNumbers);
c.Instrument(nCLIMATE).ChanNames  = {'Tair','Pbarometric'};
c.Instrument(nCLIMATE).ChanUnits  = {'C'   ,'kPa'  };
c.Instrument(nCLIMATE).ProcessData = {};  
c.Instrument(nCLIMATE).Poly       = [ 1    0;...
                                      0.1  0 ];


%-----------------------
% Site barometer
%-----------------------
c.Instrument(nPb_site).Name       = 'Site Barometer';
c.Instrument(nPb_site).Type       = '61302V Barometric Pressure Sensor';
c.Instrument(nPb_site).SerNum     = 0;
%%%%%%%%%%%%%%% Following changed by JJB, 20180324 -non-commented lines pulled from MCM1_init_all.m
% c.Instrument(nPb_site).FileType   = 'Instrument';
% c.Instrument(nPb_site).FileID     = num2str(nCLIMATE);   %
% c.Instrument(nPb_site).Fs         = c.Instrument(nCLIMATE).Fs;
% c.Instrument(nPb_site).Oversample = 0;   % 
% c.Instrument(nPb_site).ChanNumbers = 2;  
% c.Instrument(nPb_site).NumOfChans = length(c.Instrument(nPb_site).ChanNumbers);  
% c.Instrument(nPb_site).ChanNames  = {'Pbarometric'};
% c.Instrument(nPb_site).ChanUnits  = {'kPa'};
c.Instrument(nPb_site).FileType   = 'TurkeyPointClim';    % Changed by JJB, 20180324
	c.Instrument(nPb_site).FileID     = '';   % (this is the datalogger database files)
	c.Instrument(nPb_site).Fs         = 1;           % Frequency of sampling 
	c.Instrument(nPb_site).Oversample = 0;   % 
	c.Instrument(nPb_site).ChanNumbers = [1];  
	c.Instrument(nPb_site).NumOfChans = 1;  
	c.Instrument(nPb_site).ChanNames  = {'Pressure'};
	c.Instrument(nPb_site).ChanUnits  = {'kPa'};
	c.Instrument(nPb_site).Delays.Samples = [0];
	c.Instrument(nPb_site).ProcessData = {['nPb_site = ' num2str(nPb_site) ';'],...
      'Instrument_data(nPb_site).EngUnits = Instrument_data(nPb_site).EngUnits(2);'...
      };
	c.Instrument(nPb_site).CovChans   = [];
	c.Instrument(nPb_site).Alignment.Type = '';
	c.Instrument(nPb_site).Alignment.ChanNum = [];

%-----------------------
% Site air temperature (best measurement of thermodynamic air temperature)
%-----------------------
c.Instrument(nTair_site).Name       = 'Site Tair';
c.Instrument(nTair_site).Type       = 'HMP155A Temperature Sensor';
c.Instrument(nTair_site).SerNum     = 0;
%%%%%%%%%%%%%%% Following changed by JJB, 20180324 -non-commented lines pulled from MCM1_init_all.m
% c.Instrument(nTair_site).FileType   = 'Instrument';    % "Instrument" type file mean that an actual instrument should be used
% c.Instrument(nTair_site).FileID     = num2str(nCLIMATE);   %
% c.Instrument(nTair_site).Fs         = c.Instrument(nCLIMATE).Fs; 
% c.Instrument(nTair_site).Oversample = 0;   % 
% c.Instrument(nTair_site).ChanNumbers = 1;  
% c.Instrument(nTair_site).NumOfChans = length(c.Instrument(nTair_site).ChanNumbers);  
% c.Instrument(nTair_site).ChanNames  = {'T_air'};
% c.Instrument(nTair_site).ChanUnits  = {'degC'};
 c.Instrument(nTair_site).FileType   = 'TurkeyPointClim';    % "Instrument" type file mean that an actual instrument should be used
	c.Instrument(nTair_site).FileID     = '';   % (this is the datalogger database files)
	c.Instrument(nTair_site).Fs         = 1;           % Frequency of sampling 
	c.Instrument(nTair_site).Oversample = 0;   % 
	c.Instrument(nTair_site).ChanNumbers = [1];  
	c.Instrument(nTair_site).NumOfChans = 1;  
    c.Instrument(nTair_site).ChanNames  = {'AirTemp_AbvCnpy'}; %modified from 'Ta_28m' by JJB on 20200217 - I think this has been wrong for a while.
	c.Instrument(nTair_site).ChanUnits  = {'degC'};
	c.Instrument(nTair_site).Delays.Samples = [0];
	c.Instrument(nTair_site).ProcessData = {['nTair_site = ' num2str(nTair_site) ';'],...
      'Instrument_data(nTair_site).EngUnits = Instrument_data(nTair_site).EngUnits(1);'...
      };
	c.Instrument(nTair_site).CovChans   = [];
	c.Instrument(nTair_site).Alignment.Type = '';
	c.Instrument(nTair_site).Alignment.ChanNum = []; 
% Space to add hooks for the programs that can be called from the main calc program
c.ExtraCalculations.InstrumentLevel = {};               % add all the extra calculations (Matlab statements as cells)
% that one wants performed on the instrument data

%------------------------------------------------
% Eddy system 1
%
%------------------------------------------------
nMainEddy = 1;
c.System(nMainEddy).ON 				  = 1;                        % system #1 calculations are ON
c.System(nMainEddy).Type            = 'Eddy';                   % eddy correlation system
c.System(nMainEddy).Name            = 'Tower EC, YF site';      % long system name
c.System(nMainEddy).FieldName       = 'MainEddy';               % this is the output structure field name for all the system stats
c.System(nMainEddy).Rotation        = 'three';                  % do three rotations
c.System(nMainEddy).Fs              = 20;                       % sampling freq. for the system (data will be resampled to
% match this frequency if needed)
c.System(nMainEddy).Instrument      = [nSONIC nIRGA];          % select instruments (Anemometer + IRGA) for system 1
c.System(nMainEddy).ProcessData = {};
c.System(nMainEddy).Delays.Overide = 1;
c.System(nMainEddy).MaxFluxes       = 15;
c.System(nMainEddy).MaxMisc         = 15;
c.System(nMainEddy).CovVector = [];                             % create CovVector and Delays vectore 
c.System(nMainEddy).Delays.Samples = [];                        % based on the intrument setup
c.System(nMainEddy).Delays.RefChan = 4;                         % Delays calculated against this channel (T sonic)
c.System(nMainEddy).Delays.ArrayLengths = [5000 5000];          % the num of points used [ RefChan  DelayedChan]
c.System(nMainEddy).Delays.Span = 100;                          % max LAG (see fr_delay.m)
c.System(nMainEddy).Delays.Channels = [5 6];%[c.Instrument(nIRGA).CovChans];                    % Delays calculated on channels 5 and 6 (CO2 and H2O) 
%c.System(nMainEddy).Alignment.Enable = 1;                   	% added by JJB, July 15, 2010
c.System(nMainEddy).Alignment.Enable = 'FALSE';                   	% updated by JJB on Nov 01, 2017. Commented line above
c.System(nMainEddy).Alignment.SampleLength = 5000;
c.System(nMainEddy).Alignment.MaxAutoSampleReduction = 3;      % when aligning two instruments don't change the number of samples(don't resample) 
                                                                % if del_1
                                                                % <> del_2 by more than MaxAutoSampleReduction samples
%------------------------------------------------
% Spectral calculation 
%
%------------------------------------------------
c.Spectra.ON 	   = 1;
c.Spikes.ON        = 1;
c.Stationarity.ON  = 0;

%------------------------------------------------
% Short file information
%
%------------------------------------------------
c.Shortfiles.Remove(1).System       = 'MainEddy'; %from this 'system' field remove the following fields below
c.Shortfiles.Remove(1).Fields       = {'Zero_Rotations', ...
      'Stationarity', ...
      'Turbulence_Statistics'};
c.Shortfiles.Remove(1).ProcessData  = {...
      'for k = 1:length(st); st(k).MainEddy.Three_Rotations.LinDtr = []; end',...
      'for k = 1:length(st); st(k).MainEddy.Three_Rotations.AvgDtr.Cov = []; end',...
   };
