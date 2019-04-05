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

persistent lastDBupdate

Dates    = zeros(1,100);
% All times are GMT
Dates(1) = datenum(2011,10,30,0,30,0);                     % system set up

% The following line needs to be changed when dateIn becomes datenum (not a string yyyymmddQQ)
yearX = dateIn(1:4);   % added Jan 25, 2006.  It's used in the data base creation part
dateIn = datenum(str2num(dateIn(1:4)),str2num(dateIn(5:6)),str2num(dateIn(7:8)),str2num(dateIn(9:10))/96*24,0,0);

%-------------------------------
% Common 
%-------------------------------
c.PC_name       = fr_get_pc_name;
[c.path,c.hhour_path,c.database_path,c.csi_path] = fr_get_local_path;
c.ext           = '.dMCM4';
c.hhour_ext     = '.hMCM4.mat';
c.hhour_ch_ext  = '.hMCM4_ch.mat';
c.site          = 'MCM4';
localPCname		= fr_get_pc_name;							% check for this name later on to select 
c.gmt_to_local  = -5/24;
% dataBase option (see nTair below)

%------------------------------------------------------------------
% Local climate database update *** DEACTIVATED JAN 22, 2010 ****
%------------------------------------------------------------------
% if strcmp(localPCname,'ULTRA_002')
%    try
%        if isempty(lastDBupdate)
%            lastDBupdate = 0; % May 15, 2009:  Nick modified to ensure the met db is updated during chamber flux
%                                % calcs
%        end
%       
%       if (now - lastDBupdate)*24*60 > 5   
%           lastDBupdate = now;
%           % Climate data extraction
%           TableID = 60; % Because the first variable (timestamp) is not exporte
%           channelsIn = [26 31 54 55 25 33];
%           channelNames = {'wind_speed_cup_main','wind_direction_main','air_temperature_main',...
%                 'relative_humidity_main','barometric_pressure_main','precipitation'};
%           pthProgressList = fullfile(c.database_path,'yf_clim1_pthProgressList.mat');
%           fileType = 1;
%           gmt_shift = 0;
%           yy = datevec(now);
%           [nFiles1,nHHours1]=fr_site_met_database(fullfile(c.csi_path,'yf_clim1.*'),...
%              channelsIn,channelNames,TableID,pthProgressList,...
%              fullfile(c.database_path,'yyyy',fr_current_siteid,'clean','ThirdStage',filesep),...
%              fileType,gmt_shift);
%           
%           if nFiles1>0
%              fprintf(1,'Read %i *.DAT files \n',nFiles1);
%           end    
%       end
%    catch
%       disp('Could not update database.');
%    end
% end

% Instrument numbers in the order of their dependency
% (independent first)

nGILL = 1;        % Sonic GillR3 
nIRGA_GATCH1 = 2; % The closed path put in Sep 2003
nPb_site   = 3;        % barometric pressure (from IRGA)
nTair_site = 4;        % from database if possible
nIRGA2 = 5;       % LI-7500 IRGA
nGILL2 = 6;       % Sonic GillR2 
nIRGA = 7;        % LI-7500 IRGA (removed in Sep 2003)

% Variables listed within this section will become part of the
% output stats
c.MiscVariables(1).Name             = 'BarometricP';
c.MiscVariables(1).Execute          = {['nPb = ' num2str(nPb_site) ';'],...
      'miscVar = Instrument_data(nPb).EngUnits;'};
c.MiscVariables(2).Name             = 'Tair';
c.MiscVariables(2).Execute          = {['nTair = ' num2str(nTair_site) ';'],...
      'miscVar = Instrument_data(nTair).EngUnits;'};

%------------------------------------------------
% Calibration tank values
%------------------------------------------------

if dateIn < Dates(13)
   c.cal1 = 356.68;
elseif dateIn >= Dates(13) & dateIn < Dates(14)
   c.cal1 = 360.69;
elseif dateIn >= Dates(14) & dateIn < Dates(15)
   c.cal1 = 361.42;
elseif dateIn >= Dates(15) & dateIn < Dates(16)
   c.cal1 = 383.25; 
elseif dateIn >= Dates(16) & dateIn < Dates(17)
   c.cal1 = 379.94; 
elseif dateIn >= Dates(17) & dateIn < Dates(19)
   c.cal1 = 381.44;
elseif dateIn >= Dates(19) & dateIn < Dates(22)
   c.cal1 = 387.36; 
elseif dateIn >= Dates(22) & dateIn < Dates(23)
   c.cal1 = 385.91; 
elseif dateIn >= Dates(23) & dateIn < Dates(24)
   c.cal1 = 381.63;
elseif dateIn >= Dates(24) & dateIn < Dates(25)
   c.cal1 = 382.09; 
elseif dateIn >= Dates(25) & dateIn < Dates(26)
   c.cal1 = 386.08; 
elseif dateIn >= Dates(26)
   c.cal1 = 421.32;
end

c.cal2 = NaN;

%------------------------------------------------
% All instruments
%------------------------------------------------
%-----------------------
% Sonic #1 definitions:
%-----------------------
c.Instrument(nGILL).Name       = 'EC Anemometer';
c.Instrument(nGILL).Type       = 'GillR3';
c.Instrument(nGILL).SerNum     = 0;
if dateIn < Dates(20)
    c.Instrument(nGILL).FileType   = 'Digital1'; 
elseif dateIn >= Dates(20)
    c.Instrument(nGILL).FileType   = 'Digital2'; 
end    
c.Instrument(nGILL).FileID     = '3';               % String!
c.Instrument(nGILL).Fs         = 20;                % Frequency of sampling
c.Instrument(nGILL).Oversample = 6;                 % 
c.Instrument(nGILL).ChanNumbers = [1:5];            % chans to read from
c.Instrument(nGILL).NumOfChans = length(c.Instrument(nGILL).ChanNumbers);
c.Instrument(nGILL).ChanNames  = {'u','v','w','T_sonic','diag'};
c.Instrument(nGILL).ChanUnits  = {'m/s','m/s','m/s','degC','1'};
if dateIn < Dates(20)
    c.Instrument(nGILL).Poly       =  [ 1./100  0;...
                                        1./100  0;...
                                        1./100  0;...
                                        1./100  -273.15; 
                                        1 0 ];
elseif dateIn >= Dates(20)
    c.Instrument(nGILL).Poly       =  [ 1  0;...
                                        1  0;...
                                        1  0;...
                                        1  0; 
                                        1  0 ];
end    
c.Instrument(nGILL).Delays.Samples = [0 0 0 0];
c.Instrument(nGILL).ProcessData  = [];
c.Instrument(nGILL).CovChans     = [1 2 3 4];
c.Instrument(nGILL).Orientation  = 20;                   % degrees from North 
c.Instrument(nGILL).Alignment.Type = 'Master';        % all instruments get aligned to this instrument (Master)

% Nov 3, 2009: fix alignment channels retroactively
if dateIn < Dates(20) | dateIn >= Dates(21)
   c.Instrument(nGILL).Alignment.ChanNum = 4; % use T_sonic to align
elseif dateIn >= Dates(20) & dateIn < Dates(21);
   % use w for alignment only for this period when we didn't have
    % Tair connected to AUX2 
      c.Instrument(nGILL).Alignment.ChanNum = 3; 
end


%-----------------------
% IRGA #1 definitions:
%-----------------------
if dateIn < Dates(7);
    c.Instrument(nIRGA).Name      = 'EC IRGA';
    c.Instrument(nIRGA).Type      = '7500';
    if dateIn >= Dates(1) & dateIn < Dates(4);
       %calibrated for co2 and h20 in hut Oct 31, 2001
       %calibrated for co2 and h20 in hut April 18, 2002
       %pre-cal: co2 zero = -3.4 ppm/ h2o zero = -0.32 mmol/mol; co2 span = 350.6 (against 356.68ppm)/h2o span = 8.49 degC (vs. 8.50 degC)
       c.Instrument(nIRGA).SerNum    = 107;
    elseif dateIn >= Dates(4);
       c.Instrument(nIRGA).SerNum    = 046;
    end
    if dateIn >= Dates(1) & dateIn < Dates(7);
       c.Instrument(nIRGA).FileID     = '4';
       c.Instrument(nIRGA).FileType   = 'Digital2';             % 
       c.Instrument(nIRGA).Fs         = 20;                    % Frequency of sampling
       c.Instrument(nIRGA).Oversample = 6;                     % 
       c.Instrument(nIRGA).ChanNumbers = [1:8];                % chans to read from the Instrument(nIRGA)
       c.Instrument(nIRGA).NumOfChans = length(c.Instrument(nIRGA).ChanNumbers);
       c.Instrument(nIRGA).ChanNames  = {'co2','h2o','T_sonic','T_irga','P_air','diag','index','Cooler'};
       c.Instrument(nIRGA).ChanUnits  = {'mmol/(m^3)','mmol/(m^3)','degC','degC','kPa','1','1','mV'};                           
       c.Instrument(nIRGA).CovChans   = [1 2];
       c.Instrument(nIRGA).Delays.Samples = [0 0];
       c.Instrument(nIRGA).Alignment.Type = 'Slave';               % this instrument (Slave) will be aligned with the Master
       c.Instrument(nIRGA).Alignment.ChanNum = 3;                  % chanel used for the alignment
       c.Instrument(nIRGA).ProcessData = {};  
    end
end

%-----------------------
% Site barometer
%-----------------------
c.Instrument(nPb_site).Name       = 'Site Barometer';
c.Instrument(nPb_site).Type       = 'Vaisala pressure sensor';
c.Instrument(nPb_site).SerNum     = 0;
c.Instrument(nPb_site).FileType   = 'Database';
c.Instrument(nPb_site).FileID     = fullfile('clean','ThirdStage','barometric_pressure_main');   %
c.Instrument(nPb_site).Fs         = 1/1800;
c.Instrument(nPb_site).Oversample = 0;   % 
c.Instrument(nPb_site).ChanNumbers = [1];  
c.Instrument(nPb_site).NumOfChans = length(c.Instrument(nPb_site).ChanNumbers);  
c.Instrument(nPb_site).ChanNames  = {'Pbarometric'};
c.Instrument(nPb_site).ChanUnits  = {'kPa'};

%-----------------------
% Site air temperature (best measurement of thermodynamic air temperature)
%-----------------------
c.Instrument(nTair_site).Name       = 'Site Tair';
c.Instrument(nTair_site).Type       = 'HMP';
c.Instrument(nTair_site).SerNum     = 0;
c.Instrument(nTair_site).FileType   = 'Database';    % "Instrument" type file mean that an actual instrument should be used
c.Instrument(nTair_site).FileID     = fullfile('clean','ThirdStage','air_temperature_main');   %
c.Instrument(nTair_site).Fs         = 1/1800; 
c.Instrument(nTair_site).Oversample = 0;   % 
c.Instrument(nTair_site).ChanNumbers = [1];  
c.Instrument(nTair_site).NumOfChans = length(c.Instrument(nTair_site).ChanNumbers);  
c.Instrument(nTair_site).ChanNames  = {'T_air'};
c.Instrument(nTair_site).ChanUnits  = {'degC'};

%-----------------------
% IRGA #2 definitions:
%-----------------------
if dateIn >= Dates(3) & dateIn <= Dates(4);
   c.Instrument(nIRGA2).Name      = 'EC IRGA';
   c.Instrument(nIRGA2).Type      = '7500';
   c.Instrument(nIRGA2).SerNum    = 046;
   c.Instrument(nIRGA2).FileID    = '8';
   c.Instrument(nIRGA2).FileType  = 'Digital2';             % 
   c.Instrument(nIRGA2).Fs         = 20;                    % Frequency of sampling
   c.Instrument(nIRGA2).Oversample = 6;                     % 
   c.Instrument(nIRGA2).ChanNumbers = [1:8];                % chans to read from the Instrument(nIRGA)
   c.Instrument(nIRGA2).NumOfChans = length(c.Instrument(nIRGA2).ChanNumbers);
   c.Instrument(nIRGA2).ChanNames = {'co2','h2o','w','T_irga','P_air','diag','index','Cooler'};
   c.Instrument(nIRGA2).ChanUnits = {'mmol/(m^3)','mmol/(m^3)','m/s','degC','kPa','1','1','mV'};
   c.Instrument(nIRGA2).CovChans  = [1 2];
   c.Instrument(nIRGA2).Delays.Samples = [0 0];
   c.Instrument(nIRGA2).Alignment.Type = 'Slave';               % this instrument (Slave) will be aligned with the Master
   c.Instrument(nIRGA2).Alignment.ChanNum = 4;                  % chanel used for the alignment
end

%-----------------------
% Sonic #2 definitions:
%-----------------------
if (dateIn >= Dates(2) & dateIn < Dates(3)) | (dateIn >= Dates(4) & dateIn < Dates(5))
   c.Instrument(nGILL2).Name       = 'EC Anemometer';
   c.Instrument(nGILL2).Type       = 'GillR2';
   c.Instrument(nGILL2).SerNum     = 0;
   c.Instrument(nGILL2).FileType   = 'Digital1';        %
   c.Instrument(nGILL2).FileID     = '6';               % String!
   c.Instrument(nGILL2).Fs         = 20;                % Frequency of sampling
   c.Instrument(nGILL2).Oversample = 6;                 % 
   c.Instrument(nGILL2).ChanNumbers = [1:5];            % chans to read from
   c.Instrument(nGILL2).NumOfChans = length(c.Instrument(nGILL2).ChanNumbers);
   c.Instrument(nGILL2).ChanNames  = {'u2','v2','w2','Ts2','diag'};
   c.Instrument(nGILL2).ChanUnits  = {'m/s','m/s','m/s','degC','1'};
   c.Instrument(nGILL2).Poly      =  [1/100 0 ;...
         1/100 0 ;...
         1/100 0 ;...
         1/100 -273.15; ...
         1     0 ]; 
   c.Instrument(nGILL2).Delays.Samples = [0 0 0 0];
   c.Instrument(nGILL2).ProcessData = [];
   c.Instrument(nGILL2).CovChans   = [1 2 3 4];
   c.Instrument(nGILL2).Orientation= 0;                   % degrees from North 
   c.Instrument(nGILL2).Alignment.Type = '';        % all instruments get aligned to this instrument (Master)
   c.Instrument(nGILL2).Alignment.ChanNum = 0;            % chanel used for the alignment
end

%-----------------------
% Closed path LI-7000 definitions:
%-----------------------
if (dateIn >= Dates(6))
   c.Instrument(nIRGA_GATCH1).Name       = 'EC IRGA';
   c.Instrument(nIRGA_GATCH1).Type       = '7000';
   c.Instrument(nIRGA_GATCH1).SerNum     = 160;
   c.Instrument(nIRGA_GATCH1).FileType   = 'Digital2';          %
   c.Instrument(nIRGA_GATCH1).FileID     = '5';               % String!
   if dateIn < Dates(18) % Frequency of sampling
       c.Instrument(nIRGA_GATCH1).Fs         = 20.34;                
   else 
       c.Instrument(nIRGA_GATCH1).Fs         = 20;  % Oct 10: LI-7000 with new digital board installed Sept 20, 2007                
   end
   c.Instrument(nIRGA_GATCH1).Oversample = 6;  
   
   if dateIn < Dates(20) 
      c.Instrument(nIRGA_GATCH1).ChanNumbers = [1:6];            % chans to read from
      c.Instrument(nIRGA_GATCH1).ChanNames  = {'co2','h2o','Tbench','Plicor','Aux','diag'};
      c.Instrument(nIRGA_GATCH1).ChanUnits  = {'mmol/mol','mmol/mol','degC','kPa','mV','1'};
      c.Instrument(nIRGA_GATCH1).Alignment.Type = 'Slave';               % this instrument (Slave) will be aligned with the Master
                        % chanel used for the alignment - Tsonic is measured but is hardware filtered
                        % Therefore use co2
      c.Instrument(nIRGA_GATCH1).Alignment.ChanNum = 5;                 
   elseif dateIn >= Dates(20) & dateIn < Dates(21);
      c.Instrument(nIRGA_GATCH1).ChanNumbers = [1:6];            % chans to read from
      c.Instrument(nIRGA_GATCH1).ChanNames  = {'co2','h2o','Tbench','Plicor','Aux','diag'};
      c.Instrument(nIRGA_GATCH1).ChanUnits  = {'mmol/mol','mmol/mol','degC','kPa','mV','1'};
      c.Instrument(nIRGA_GATCH1).Alignment.Type = 'Slave';               % this instrument (Slave) will be aligned with the Master
                        % chanel used for the alignment - Tsonic is measured but is hardware filtered
                        % Therefore use co2
      % use sonic w and co2 for alignment only for this period when we didn't have
            % Tsonic connected to IRGA 
      c.Instrument(nIRGA_GATCH1).Alignment.ChanNum = 1; % align to co2
   elseif dateIn >= Dates(21)
      c.Instrument(nIRGA_GATCH1).ChanNumbers = [1:7];            % chans to read from
       % c.Instrument(nIRGA_GATCH1).ChanNames  = {'co2','h2o','Tbench','Plicor','Aux1','Aux2','diag'};
        % Nick modified to match channels used in "extract_LI7000_calibration" 
        c.Instrument(nIRGA_GATCH1).ChanNames  = {'co2','h2o','Tbench','Plicor','Aux','T_sonic','diag'};
        c.Instrument(nIRGA_GATCH1).ChanUnits  = {'mmol/mol','mmol/mol','degC','kPa','V','V','1'};
        c.Instrument(nIRGA_GATCH1).Alignment.Type = 'Slave';               % this instrument (Slave) will be aligned with the Master
                        % chanel used for the alignment - Tsonic is
                        % measured but is hardware filtered
        c.Instrument(nIRGA_GATCH1).Alignment.ChanNum = 6;   % T_sonic input to IRGA
   end
   
   c.Instrument(nIRGA_GATCH1).NumOfChans = length(c.Instrument(nIRGA_GATCH1).ChanNumbers);
   c.Instrument(nIRGA_GATCH1).CovChans   = [1 2];
   c.Instrument(nIRGA_GATCH1).Delays.Samples = [0 0];
   % Conversion to mixing ratios
   c.Instrument(nIRGA_GATCH1).ProcessData = {};  
   c.Instrument(nIRGA_GATCH1).Cal.time = datenum(0,0,0,11,1,0); % gets rounded to end of hhour
   c.Instrument(nIRGA_GATCH1).Cal.ppm = [0 c.cal1 c.cal2];  % for CAL0, CAL1 and CAL2
   if dateIn < Dates(18)
       c.Instrument(nIRGA_GATCH1).Cal.ind.HF_data =        [    1   201]; 
       c.Instrument(nIRGA_GATCH1).Cal.ind.CAL0 =           [  725   925];
       c.Instrument(nIRGA_GATCH1).Cal.ind.CAL1 =           [ 1725  1925];
       c.Instrument(nIRGA_GATCH1).Cal.ind.CAL2 =           [ 2525  2725];
       c.Instrument(nIRGA_GATCH1).Cal.ind.Ambient_before = [    1    80];
       c.Instrument(nIRGA_GATCH1).Cal.ind.Ambient_after  = [ 2950  3150];
   elseif dateIn>=Dates(18) & dateIn<Dates(20)
       c.Instrument(nIRGA_GATCH1).Cal.ind.HF_data =        [ 1   201   ]; 
       c.Instrument(nIRGA_GATCH1).Cal.ind.CAL0 =           [ 705  905  ];
       c.Instrument(nIRGA_GATCH1).Cal.ind.CAL1 =           [ 1705  1905   ];
       c.Instrument(nIRGA_GATCH1).Cal.ind.CAL2 =           [ 2500  2700 ];
       c.Instrument(nIRGA_GATCH1).Cal.ind.Ambient_before = [ 1    80  ];
       c.Instrument(nIRGA_GATCH1).Cal.ind.Ambient_after  = [ 2900  3100  ];
   else
       c.Instrument(nIRGA_GATCH1).Cal.ind.HF_data =        [ 1   201   ]; 
       c.Instrument(nIRGA_GATCH1).Cal.ind.CAL0 =           [ 705  905  ];
       c.Instrument(nIRGA_GATCH1).Cal.ind.CAL1 =           [ 1705  1850   ]; % Jan 14/2010: Nick adjusted cal1 extraction indexes
       c.Instrument(nIRGA_GATCH1).Cal.ind.CAL2 =           [ 2500  2700 ];
       c.Instrument(nIRGA_GATCH1).Cal.ind.Ambient_before = [ 1    80  ];
       c.Instrument(nIRGA_GATCH1).Cal.ind.Ambient_after  = [ 2900  3100  ];
   end
   [c.Instrument(nIRGA_GATCH1).Cal.CO2, c.Instrument(nIRGA_GATCH1).Cal.H2O] = ...
      fr_get_LI7000_cal(fr_current_siteid,dateIn,c,nIRGA_GATCH1);
end

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
if (dateIn < Dates(7))
   c.System(nMainEddy).Instrument      = [nGILL nIRGA];          % select instruments (Anemometer + IRGA) for system 1
   c.System(nMainEddy).ProcessData = {};
else
   c.System(nMainEddy).Instrument      = [nGILL nIRGA_GATCH1];   
   c.System(nMainEddy).ProcessData = {};
   % Could be used for maximized covariance but fr_shift does no work with neg. delays
   c.System(nMainEddy).Delays.Overide = 1;
end   
% removed, see below  c.System(1).MaxColumns      = 4+2;                      % Sonic + IRGA + TCs + (KH2O + Misc)
c.System(nMainEddy).MaxFluxes       = 15;
c.System(nMainEddy).MaxMisc         = 15;
c.System(nMainEddy).CovVector = [];                             % create CovVector and Delays vectore 
c.System(nMainEddy).Delays.Samples = [];                        % based on the intrument setup
c.System(nMainEddy).Delays.RefChan = 4;                         % Delays calculated against this channel (T sonic)
c.System(nMainEddy).Delays.ArrayLengths = [5000 5000];          % the num of points used [ RefChan  DelayedChan]
c.System(nMainEddy).Delays.Span = 100;                          % max LAG (see fr_delay.m)
c.System(nMainEddy).Delays.Channels = [5 6];%[c.Instrument(nIRGA).CovChans];                    % Delays calculated on channels 5 and 6 (CO2 and H2O) 
c.System(nMainEddy).Alignment.Enable = 1;
c.System(nMainEddy).Alignment.SampleLength = 5000;
c.System(nMainEddy).Alignment.MaxAutoSampleReduction = 5;      % when aligning two instruments don't change the number of samples(don't resample) 
                                                                % if del_1 <> del_2 by more than MaxAutoSampleReduction samples

%------------------------------------------------
% Eddy system 2 - Closed path using GATCH
%
%------------------------------------------------
if (dateIn >= Dates(6) & dateIn < Dates(7))
   nClosedPathEddy = 2;
   c.System(nClosedPathEddy).ON 				  = 1;                        % system #2 calculations are ON
   c.System(nClosedPathEddy).Type            = 'Eddy';                   % eddy correlation system
   c.System(nClosedPathEddy).Name            = 'Tower EC, closed path test, YF site';      % long system name
   c.System(nClosedPathEddy).FieldName       = 'ClosedPathEddy';               % this is the output structure field name for all the system stats
   c.System(nClosedPathEddy).Rotation        = 'three';                  % do three rotations
   c.System(nClosedPathEddy).Fs              = 20;                       % sampling freq. for the system (data will be resampled to
   % match this frequency if needed)
   c.System(nClosedPathEddy).Instrument      = [nGILL nIRGA_GATCH1];          % select instruments (Anemometer + IRGA) for system 1
   c.System(nClosedPathEddy).MaxFluxes       = 15;
   c.System(nClosedPathEddy).MaxMisc         = 15;
   c.System(nClosedPathEddy).CovVector       = [];              % create CovVector and Delays vectore 
   c.System(nClosedPathEddy).Delays.Samples  = [];              % based on the intrument setup
   c.System(nClosedPathEddy).Delays.RefChan  = 4;               % Delays calculated against this channel (T sonic)
   c.System(nClosedPathEddy).Delays.ArrayLengths = [5000 5000]; % the num of points used [ RefChan  DelayedChan]
   c.System(nClosedPathEddy).Delays.Span         = 100;         % max LAG (see fr_delay.m)
   c.System(nClosedPathEddy).Delays.Channels     = [5 6];       % [c.Instrument(nIRGA).CovChans];                    % Delays calculated on channels 5 and 6 (CO2 and H2O) 
   c.System(nClosedPathEddy).Delays.Overide      = 1;            % Do covariance maximisations
   c.System(nClosedPathEddy).ProcessData = {};
end

%------------------------------------------------
% add all the extra calculations (Matlab statements as cells)
% that one wants performed on the System data

c.ExtraCalculations.SystemLevel(1).Type = 'Eddy';
c.ExtraCalculations.SystemLevel(1).Name = 'Turbulence_Statistics';
c.ExtraCalculations.SystemLevel(1).ON   = 0;
c.ExtraCalculations.SystemLevel(1).Execute = { ...
      '[Eddy_HF_data] = fr_create_system_data(configIn,1,dataIn,miscVariables);',...
      'Eddy_delays = configIn.System(1).Delays.Samples;',...
      '[Eddy_HF_data] = fr_shift(Eddy_HF_data, Eddy_delays);',...
      '[Eddy_HF_data] = fr_rotatn_hf(Eddy_HF_data,[stats(end).MainEddy.Three_Rotations.Angles.Eta stats(end).MainEddy.Three_Rotations.Angles.Theta stats(end).MainEddy.Three_Rotations.Angles.Beta]);',...
      'Skewness_out  = skewness(Eddy_HF_data);',...
      'Kurtosis_out  = kurtosis(Eddy_HF_data);',...
      'Turbulence_Statistics.Skewness = Skewness_out;',...
      'Turbulence_Statistics.Kurtosis = Kurtosis_out;'};

if dateIn < Dates(7)
   c.ExtraCalculations.SystemLevel(2).Type = 'Eddy';
   c.ExtraCalculations.SystemLevel(2).Name = 'WPLFluxes';
   c.ExtraCalculations.SystemLevel(2).ON   = 0;
   foo = c.System(nMainEddy).ProcessData(1:8);
   foo(9) = {'Instrument_data(nIRGA).EngUnits(:,1) = C_density.*44.01./1000;'};
   foo(10) = {'Instrument_data(nIRGA).EngUnits(:,2) = H_density.*18.02./1000;'};
   c.ExtraCalculations.SystemLevel(2).Execute = { ...
         ['nMainEddy = ' num2str(nMainEddy) ';'],...
         ['configIn.System(nMainEddy).ProcessData = [];'],... 
         ['configIn.System(nMainEddy).ProcessData(1) = {' 39 char(foo(1)) 39 '};' ]',... 
         ['configIn.System(nMainEddy).ProcessData(2) = {' 39 char(foo(2)) 39 '};'],... 
         ['configIn.System(nMainEddy).ProcessData(3) = {' 39 char(foo(3)) 39 '};'],... 
         ['configIn.System(nMainEddy).ProcessData(4) = {' 39 char(foo(4)) 39 '};'],... 
         ['configIn.System(nMainEddy).ProcessData(5) = {' 39 char(foo(5)) 39 '};'],... 
         ['configIn.System(nMainEddy).ProcessData(6) = {' 39 char(foo(6)) 39 '};'],... 
         ['configIn.System(nMainEddy).ProcessData(7) = {' 39 char(foo(7)) 39 '};'],... 
         ['configIn.System(nMainEddy).ProcessData(8) = {' 39 char(foo(8)) 39 '};'],... 
         ['configIn.System(nMainEddy).ProcessData(9) = {' 39 char(foo(9)) 39 '};'],... 
         ['configIn.System(nMainEddy).ProcessData(10) = {' 39 char(foo(10)) 39 '};'],...       
         '[Eddy_HF_data] = fr_create_system_data(configIn,nMainEddy,dataIn,miscVariables);',... 
         'tmp = do_eddy_calc(Eddy_HF_data,miscVariables,configIn,nMainEddy,stats(end).TimeVector);',...
         'tmp2 = []; tmp2 = setfield(tmp2,configIn.System(nMainEddy).FieldName,tmp);',...
         '[WPLFluxes] = calc_WPL_fluxes(configIn, nMainEddy, miscVariables, tmp2);'};       
end 

%------------------------------------------------
% Chamber specific stuff
%------------------------------------------------
if dateIn < Dates(8)
   c.chamber.ON = 0;                               % calculate chamber data 1-ON, 0-OFF
else
   c.chamber.ON = 1;
end

if c.chamber.ON
   
   c.chamber.systemType = 2;
   c.chamber.ID_23x_HF = 101;
   c.chamber.ID_23x_HH = 102;
   
   c.chamber.HH_ext   = '.ryf.mat';
   c.chamber.HF_ext   = '.syf.mat';
   c.chamber.cal_ext  = '.cyf';
   c.chamber.name23x    = 'Cham_23x';
   c.chamber.name23x_HF = 'YF_ACS2';
   c.chamber.name23x_HH = 'YF_ACS1';
   
   c.chamber.chans_23x_HF = 51;
   c.chamber.chans_23x_HH = 124;
   c.chamber.ChanReorder.data_HF = [1:5 11:14 6 17 15:16 18:43];
   c.chamber.ChanReorder.data_HH = [1:124];
   
   %flux calculation information
   c.chamber.chNbr = 12;
   c.chamber.slopeLength = 150;     %seconds 
   c.chamber.slopeStartPeriod = 20; %seconds
   c.chamber.slopeEndPeriodShort = 80;   %seconds
   c.chamber.slopeEndPeriodLong = c.chamber.slopeLength - 35;   %seconds
   c.chamber.area = 0.216;
   c.chamber.areaBole = 0.33;
   
   if dateIn < Dates(10)   
      %effective volume calibration information
      c.chamber.evCalHour  = 23;
      %licor calibration information
      c.chamber.calHour = 22;
   elseif dateIn >= Dates(10)  
      %effective volume calibration information
      c.chamber.evCalHour  = 22;
      %licor calibration information
      c.chamber.calHour = 23;
   end
   
   c.chamber.calMinute = 1;
   c.chamber.calSkipSec = 15;
   c.chamber.calPeriodSec = 45;
   c.chamber.flowRate = 10;
   c.chamber.effectiveVolGas = 0.10; 
   c.chamber.GasCorrFactor = 0.97;
   c.chamber.Licor.Type = '6262';
   
   c.chamber.CalFilePath = fullfile(c.hhour_path,'calibrations.cyf_ch');
   
   try
      [c.chamber.Licor.CO2_cal,c.chamber.Licor.H2O_cal] = ...
         fr_get_licor_cal(c.chamber.CalFilePath,dateIn);
   catch
      % if the calibration file is missing use default span/zero
      c.chamber.Licor.CO2_cal = [1 0];
      c.chamber.Licor.H2O_cal = [1 0];
   end
   
   if dateIn >= Dates(8) & dateIn < Dates(9) 
      c.chamber.Licor.Num = 118;
   elseif dateIn >= Dates(9) 
      c.chamber.Licor.Num = 740;
   end
   
if dateIn < Dates(13)
   c.chamber.span_conc = 356.68;
elseif dateIn >= Dates(13) & dateIn < Dates(14)
   c.chamber.span_conc = 360.69;
elseif dateIn >= Dates(14) & dateIn < Dates(15)
   c.chamber.span_conc = 361.42;
elseif dateIn >= Dates(15) & dateIn < Dates(16)
   c.chamber.span_conc = 383.25; 
elseif dateIn >= Dates(16) & dateIn < Dates(17)
   c.chamber.span_conc = 379.94; 
elseif dateIn >= Dates(17) & dateIn < Dates(19)
   c.chamber.span_conc = 381.44;
elseif dateIn >= Dates(19) & dateIn < Dates(22)
   c.chamber.span_conc = 387.36; 
elseif dateIn >= Dates(22) & dateIn < Dates(23)
   c.chamber.span_conc = 385.91; 
elseif dateIn >= Dates(23) & dateIn < Dates(24)
   c.chamber.span_conc = 381.63;
elseif dateIn >= Dates(24) & dateIn < Dates(25)
   c.chamber.span_conc = 382.09; 
elseif dateIn >= Dates(25) & dateIn < Dates(26)
   c.chamber.span_conc = 386.08; 
elseif dateIn >= Dates(26)
   c.chamber.span_conc = 421.32;
end
   
   % Mandatory Climate data to be extracted
   c.chamber.Chan_bVol = 5;             
   c.chamber.Chan_cTCHTemp = 6;         
   c.chamber.Chan_pTCHTemp = 7;         
   
   c.chamber.Air_Temp.Chan_Measured = [19 21 23 26]'; 
   c.chamber.Air_Temp.Chan_Stored = [2 3 4 7]';          
   c.chamber.Soil_Temp.Chan_Measured = [17 18 20 22 24 25 27]'; 
   c.chamber.Soil_Temp.Chan_Stored = [1 2 3 4 5 6 7]';          
   c.chamber.VWC.Chan_Measured = []'; 
   c.chamber.VWC.Chan_Stored = []';         
   c.chamber.PAR.Chan_Measured = []'; 
   c.chamber.PAR.Chan_Stored = []';         
   c.chamber.Misc_Temp.Chan_Measured = []';     
   c.chamber.Misc_Temp.Chan_Stored = []';        
   c.chamber.codeMissingData = -99999;
   
   c.chamber.Chan_misc_climate = [85:92]';
   c.chamber.Names_misc_climate = {...
         'Soil_CO2_05cm_A',...
         'Soil_CO2_05cm_B',...
         'Soil_CO2_05cm_C',...
         'Soil_CO2_15cm_A',...
         'Soil_CO2_50cm_A',...
         'Soil_CO2_50cm_B',...
         'Soil_CO2_50cm_C',...
         'Soil_CO2_100cm_A'};
   
   c.chamber.Pbar = 101;                       % default barometric pressure
   c.chamber.MFC.ChannelNum = 11;              % MFC channel number
   c.chamber.MFC.Gain = 1/250;                 % conversion factor to sccm.
   c.chamber.Licor.ChannelNum = [6 7 8 9];     % Licor channels [co2 h2o Tbench Plicor]
   c.chamber.TV_HF.ChannelNum = [2 3 4 5];     % date/time channels [year doy hhmm seconds] for HF data
   c.chamber.TV_HH.ChannelNum = [2 3 4];       % date/time channels [year doy hhmm] for HH data
   c.chamber.BadDataPoints = [c.chamber.evCalHour*2+[1 2] c.chamber.calHour*2+[1 2]] ;  % Indexes of bad points
   areaSoil = 0.216;                           % m^2
   areaBole = 0.33;                            % m^2
   tempArea = ones(1,c.chamber.chNbr) * areaSoil; % create a vector of chamber areas
   c.chamber.Area = tempArea(ones(1,48),:);       % convert the area to a matrix 48 x chNbr
end

%------------------------------------------------
% Spectral calculation 
%
%------------------------------------------------
c.Spectra.ON 	   = 0;
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
%	   'for k = 1:length(st); st(k).MainEddy.Spectra.Csd = []; end;',...
%      'for k = 1:length(st); st(k).MainEddy.Spectra.fCsd = []; end;',...
%      'for k = 1:length(st); st(k).MainEddy.Spectra.fPsd = []; end;',...
%      'for k = 1:length(st); st(k).MainEddy.Spectra.Psd = st(k).MainEddy.Spectra.Psd(:,[4 5 6]); end',...

%c.Shortfiles.Remove(2).System       = 'Instrument'; %from this 'system' field remove the following fields below
%c.Shortfiles.Remove(2).Fields       = {'Name',...
%      'Type',...
%      'SerNum',...
%      'ChanNames',...
%       'ChanUnits',...
%       'Avg',...
%       'Min',...
%       'Max',...
%       'Std',...
%       'MiscVariables',...
%    };

if (dateIn >= Dates(6) & dateIn < Dates(7))
   c.Shortfiles.Remove(3).System       = 'ClosedPathEddy'; %from this 'system' field remove the following fields below
   c.Shortfiles.Remove(3).Fields       = {'Zero_Rotations', ...
         'Stationarity', ...
         'Turbulence_Statistics',...
         'Delays',...
         'SourceInstrumentNumber',...
         'SourceInstrumentChannel',...
      };
   c.Shortfiles.Remove(3).ProcessData  = {...
         'for k = 1:length(st); st(k).ClosedPathEddy.Three_Rotations.LinDtr = []; end',...
         'for k = 1:length(st); st(k).ClosedPathEddy.Three_Rotations.AvgDtr.Cov = []; end',...
         'for k = 1:length(st); st(k).ClosedPathEddy.Three_Rotations.AvgDtr.Fluxes.Ustar = []; end',...
         'for k = 1:length(st); st(k).ClosedPathEddy.Three_Rotations.AvgDtr.Fluxes.Hs = []; end',...
         'for k = 1:length(st); st(k).ClosedPathEddy.Three_Rotations.AvgDtr.Fluxes.Htc1 = []; end',...
         'for k = 1:length(st); st(k).ClosedPathEddy.Three_Rotations.AvgDtr.Fluxes.Htc2 = []; end',...
         'for k = 1:length(st); st(k).ClosedPathEddy.Three_Rotations.AvgDtr.Fluxes.MiscVariables = []; end',...
         'for k = 1:length(st); st(k).ClosedPathEddy.Three_Rotations.AvgDtr.Fluxes.LE_K = []; end',...
         'for k = 1:length(st); st(k).ClosedPathEddy.Three_Rotations.Angles = []; end',...
      };
end
