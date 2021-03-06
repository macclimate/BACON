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
% Jun 08, 2005 (kai*)
%   - Adjusted ini-file to new new_eddy version (instrument calc are no
%       longer defined in the ini-file)
% Apr 12, 2004 (kai*)
%   - Changed ref chan on sonic to 3 so OP can use it. CP alignment is between w and CO2 for now.
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
c.ext           = '.DMCM';
c.hhour_ext     = '.hMCM1.mat'; %'.hHJP02.mat'; % Changed by JJB Jan19-2010
c.site          = 'MCM1'; %'HJP02';             % Changed by JJB Jan19-2010
localPCname	   = fr_get_pc_name;							% check for this name later on to select 
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
% Open Path IRGA definitions:
%-----------------------
c.Instrument(nIRGA_op).Name      = 'EC IRGA OP';
c.Instrument(nIRGA_op).Type      = '7500';
c.Instrument(nIRGA_op).SerNum    = '';
c.Instrument(nIRGA_op).FileID     = '9';
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
c.Instrument(nIRGA_op).Alignment.ChanNum = 2;                  % chanel used for the alignment
c.Instrument(nIRGA_op).ProcessData = {};  

%-----------------------
% Closed Path IRGA definitions:
%-----------------------
c.Instrument(nIRGA_cp).Name      = 'EC IRGA';
c.Instrument(nIRGA_cp).Type      = '7000';
c.Instrument(nIRGA_cp).SerNum    = 0;
c.Instrument(nIRGA_cp).FileID    = '4';
c.Instrument(nIRGA_cp).FileType  = 'Digital2';            % 
c.Instrument(nIRGA_cp).ChanUnits = {'umol/mol' ,'mmol/mol','kPa'   ,'degC'   ,'mV'   ,'1'};   
c.Instrument(nIRGA_cp).Fs         = 20.345;               % Frequency of sampling
c.Instrument(nIRGA_cp).Oversample = 100;                     % 
c.Instrument(nIRGA_cp).ChanNumbers = [1:6];                % chans to read from the Instrument(nIRGA_cp)
c.Instrument(nIRGA_cp).NumOfChans = length(c.Instrument(nIRGA_cp).ChanNumbers);
c.Instrument(nIRGA_cp).ChanNames = {'co2'      ,'h2o'     ,'Tlicor', 'Plicor','T_sonic','Diag'};
c.Instrument(nIRGA_cp).CovChans  = [1 2];
c.Instrument(nIRGA_cp).Delays.Samples = [0 0];
c.Instrument(nIRGA_cp).Alignment.Type = 'Slave';               % this instrument (Slave) will be aligned with the Master
% Align using co2 here and Ts with the sonic, since aux input is srewed up
c.Instrument(nIRGA_cp).Alignment.ChanNum = 2;
% Conversion to mixing ratios
c.Instrument(nIRGA_cp).ProcessData = {};  



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
c.System(nMainEddy).Delays.ArrayLengths = [10000 10000];          % the num of points used [ RefChan  DelayedChan]
c.System(nMainEddy).Delays.Span = 200;                          % max LAG (see fr_delay.m)
c.System(nMainEddy).Delays.Channels = [5 6];%[c.Instrument(nIRGA_op).CovChans];                    % Delays calculated on channels 5 and 6 (CO2 and H2O) 
c.System(nMainEddy).Delays.Overide = 1;
c.System(nMainEddy).ProcessData = {};
 
c.ExtraCalculations = [];
 
%------------------------------------------------
% Eddy system 2
%open  path and sonic
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
c.System(nSecondEddy).Delays.Overide = 0;
c.System(nSecondEddy).ProcessData = {};
 
%------------------------------------------------
% Spike test 
%
%------------------------------------------------
c.Spikes.ON           = 1;
c.Stationarity.ON     = 0;
c.Spectra.ON 	      = 1;

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


