%===============================================================
function c = HP11_init_all(dateIn)
%===============================================================
%
% (c) Nick Grant            File created:       July 18, 2011
%                           Last modification:  July 18, 2011
%
% MPB3 

%
%   Revisions:
% changed everything with MPB1 to MPB3. Changed sampling to 10Hz on
% dates2.6
% changed dates2 channumbers to 10 (was 15)

Dates    = zeros(1,100);
% All times are GMT
Dates(1) = datenum(2011,6,8,0,30,0);                     % system set up
Dates(2) = datenum(2011,8,8,12,0,0);                     % Fs change from 10 Hz to 5 Hz

% The following line needs to be changed when dateIn becomes datenum (not a string yyyymmddQQ)
dateIn = datenum(str2num(dateIn(1:4)),str2num(dateIn(5:6)),str2num(dateIn(7:8)),str2num(dateIn(9:10))/96*24,0,0);

%-------------------------------
% Common 
%-------------------------------
c.PC_name       = fr_get_pc_name;
[c.path,c.hhour_path,c.database_path] = fr_get_local_path;
c.ext           = '.DHP11';
c.hhour_ext     = '.hHP11.mat';
c.site          = 'HP11';
localPCname	   = 'ENG02';							        % check for this name later on to select 
															% dataBase option (see nTair below)

% Instrument numbers in the order of their dependency
% (independent first)

nCR5000 = 1;    % CR1000 HF data
nSONIC = 2;     % Sonic CSAT3 
nPb    = 3;     % barometric pressure (from IRGA)
nTair  = 4;     % from Sonic
nIRGA_op  = 5;  % LI-7200 IRGA
nTc1    = 6;    % EC TC 1


% Variables listed within this section will become part of the
% output stats
c.MiscVariables(1).Name             = 'BarometricP';
c.MiscVariables(1).Execute          = {['nPb = ' num2str(nPb) ';'],...
                                        'miscVar = mean(Instrument_data(nPb).EngUnits);'};                                
%                                        'miscVar = 94;'};                                                                
c.MiscVariables(2).Name             = 'Tair';
c.MiscVariables(2).Execute          = {['nTair = ' num2str(nTair) ';'],...
                                       'miscVar = mean(Instrument_data(nTair).EngUnits);'};


%------------------------------------------------
% All instruments
%------------------------------------------------
%-----------------------
% CR1000 definitions:
%-----------------------
c.Instrument(nCR5000).Name       = 'EC CR1000';
c.Instrument(nCR5000).Type       = 'CSI';
%c.Instrument(nCR5000).SerNum     = 34038;
c.Instrument(nCR5000).FileType   = 'CRBasic';              %
c.Instrument(nCR5000).FileID     = '1';                 % String!
c.Instrument(nCR5000).Oversample = 6;     %
c.Instrument(nCR5000).RemoveNanFlag = 1;% 

if dateIn < Dates(2)
   c.Instrument(nCR5000).Fs         = 10;                % Frequency of sampling
   c.Instrument(nCR5000).SerNum     = 34038;
elseif dateIn >= Dates(2)
   c.Instrument(nCR5000).Fs         = 5;
   c.Instrument(nCR5000).SerNum     = 5748;
end

%c.Instrument(nCR5000).Fs         = 10;                % Frequency of sampling
c.Instrument(nCR5000).ChanNumbers = [1:12];          % chans to read fromc.Instrument(nCR1000).ChanNames  = {'co2','h2o','P','Idiag','u','v','w','T_sonic','Sdiag','Tc1','Tc2','Tc3','Tc4'};
c.Instrument(nCR5000).JunkColumns = [4];             % number of leading channels to be rejected as junk
c.Instrument(nCR5000).ChanNames  = {'co2','h2o','Tbench_in','Tbench_out','P','Idiag','u','v','w','T_sonic','Sdiag','SoilT'};
c.Instrument(nCR5000).ChanUnits  = {'umol/mol_dry','mol/mol_dry','degC','degC','kPa','1','m/s','m/s','m/s','degK','1','degC'};  
c.Instrument(nCR5000).NumOfChans = length(c.Instrument(nCR5000).ChanNumbers);
c.Instrument(nCR5000).Delays.Samples = [];
c.Instrument(nCR5000).ProcessData  = [];
c.Instrument(nCR5000).CovChans     = [];
c.Instrument(nCR5000).Orientation  = 0;                   % degrees from North 
c.Instrument(nCR5000).Alignment.Type = 'Master';        % all instruments get aligned to this instrument (Master)
c.Instrument(nCR5000).Alignment.ChanNum = [];            % chanel used for the alignment


%-----------------------
% Sonic #1 definitions:
%-----------------------
c.Instrument(nSONIC).Name       = 'EC Anemometer';
c.Instrument(nSONIC).Type       = 'CSAT3';
c.Instrument(nSONIC).SerNum     = 0;
c.Instrument(nSONIC).FileType   = 'Instrument';        %
c.Instrument(nSONIC).FileID     = num2str(nCR5000);               % String!
c.Instrument(nSONIC).Fs         = c.Instrument(str2num(c.Instrument(nCR5000).FileID)).Fs;               % Frequency of sampling
c.Instrument(nSONIC).Oversample = c.Instrument(str2num(c.Instrument(nCR5000).FileID)).Oversample;                     % 
c.Instrument(nSONIC).ChanNumbers = [7:11];            % chans to read from
c.Instrument(nSONIC).NumOfChans = length(c.Instrument(nSONIC).ChanNumbers);
c.Instrument(nSONIC).ChanNames  = {'u','v','w','T_sonic','diag'};
c.Instrument(nSONIC).ChanUnits  = {'m/s','m/s','m/s','degC','1'};
c.Instrument(nSONIC).Poly       =  [1  0;...
     								1  0;...
    					  			1  0;...
   									1  0; ...
   									1 0; ...
                                    ];
c.Instrument(nSONIC).Delays.Samples = [0 0 0 0];
c.Instrument(nSONIC).ProcessData  = [];
c.Instrument(nSONIC).CovChans     = [1 2 3 4];
c.Instrument(nSONIC).Orientation  = 0;                   % degrees from North 
c.Instrument(nSONIC).Alignment.Type = 'Master';        % all instruments get aligned to this instrument (Master)
c.Instrument(nSONIC).Alignment.ChanNum = 3;            % chanel used for the alignment

%-----------------------
% IRGA #1 definitions:
%-----------------------
c.Instrument(nIRGA_op).Name      = 'EC IRGA OP';
c.Instrument(nIRGA_op).Type      = '7200';
c.Instrument(nIRGA_op).SerNum    = '';
c.Instrument(nIRGA_op).FileID     = num2str(nCR5000);
c.Instrument(nIRGA_op).FileType   = 'Instrument';             % 
c.Instrument(nIRGA_op).Fs         = c.Instrument(str2num(c.Instrument(nIRGA_op).FileID)).Fs;               % Frequency of sampling
c.Instrument(nIRGA_op).Oversample = c.Instrument(str2num(c.Instrument(nIRGA_op).FileID)).Oversample;                     % 
c.Instrument(nIRGA_op).ChanNumbers = [1:6];                % chans to read from the Instrument(nIRGA_op)
c.Instrument(nIRGA_op).NumOfChans = length(c.Instrument(nIRGA_op).ChanNumbers);
c.Instrument(nIRGA_op).ChanNames  = {'co2','h2o','Tbench_in','Tbench_out','P','Idiag'};
c.Instrument(nIRGA_op).ChanUnits  = {'umol/mol_dry','mol/mol_dry','degC','degC','kPa','1'};                           
c.Instrument(nIRGA_op).CovChans   = [1 2];
c.Instrument(nIRGA_op).Delays.Samples = [5 7];
c.Instrument(nIRGA_op).Alignment.Type = 'Slave';               % this instrument (Slave) will be aligned with the Master
c.Instrument(nIRGA_op).Alignment.ChanNum = 1;                  % chanel used for the alignment
c.Instrument(nIRGA_op).ProcessData = {['nIRGA_op = ' num2str(nIRGA_op) ';'],...
      '[c.Instrument(nIRGA_op).CO2_Cal, c.Instrument(nIRGA_op).H2O_Cal] = fr_get_manual_Licor_cal(char(configIn.site),dateIn);',...
      'Instrument_data(i).EngUnits(:,1) = (Instrument_data(i).EngUnits(:,1) + c.Instrument(nIRGA_op).CO2_Cal(2)).*c.Instrument(nIRGA_op).CO2_Cal(1);',...
      'Instrument_data(i).EngUnits(:,2) = (Instrument_data(i).EngUnits(:,2) + c.Instrument(nIRGA_op).H2O_Cal(2)).*c.Instrument(nIRGA_op).H2O_Cal(1);'};  

%-----------------------
% Barometer
%-----------------------
c.Instrument(nPb).Name       = 'Barometer';
c.Instrument(nPb).Type       = 'From LI7200 file';
c.Instrument(nPb).SerNum     = 0;
c.Instrument(nPb).FileType   = 'Instrument';    % "Instrument" type file mean that an actual instrument should be used
c.Instrument(nPb).FileID     = num2str(nCR5000);   % 
c.Instrument(nPb).Fs         = c.Instrument(str2num(c.Instrument(nPb).FileID)).Fs;           % Frequency of sampling 
c.Instrument(nPb).Oversample = c.Instrument(str2num(c.Instrument(nPb).FileID)).Fs;   % 
c.Instrument(nPb).ChanNumbers = [5];  
c.Instrument(nPb).NumOfChans = length(c.Instrument(nPb).ChanNumbers);  
c.Instrument(nPb).ChanNames  = {'Pbarometric'};
c.Instrument(nPb).ChanUnits  = {'kPa'};
c.Instrument(nPb).Poly       = [];
c.Instrument(nPb).Delays.Samples = [];
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
c.Instrument(nTair).Poly       = [];
c.Instrument(nTair).Delays.Samples = [];
c.Instrument(nTair).ProcessData = [];
c.Instrument(nTair).CovChans   = [];
c.Instrument(nTair).Alignment.Type = '';
c.Instrument(nTair).Alignment.ChanNum = []; 

%-----------------------
% Tc1 (EC thermocouple)
%-----------------------
c.Instrument(nTc1).Name       = 'EC Thermocouples';
c.Instrument(nTc1).Type       = 'Tsoil';
c.Instrument(nTc1).SerNum     = 0;
c.Instrument(nTc1).FileType   = 'Instrument';    % "Instrument" type file mean that an actual instrument should be used
c.Instrument(nTc1).FileID     = num2str(nCR5000);   %
c.Instrument(nTc1).Fs         = c.Instrument(str2num(c.Instrument(nTc1).FileID)).Fs;           % Frequency of sampling 
c.Instrument(nTc1).Oversample = c.Instrument(str2num(c.Instrument(nTc1).FileID)).Fs;   % 
c.Instrument(nTc1).ChanNumbers = [12];  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c.Instrument(nTc1).NumOfChans = length(c.Instrument(nTc1).ChanNumbers);  
c.Instrument(nTc1).ChanNames  = {'T_soil'};
c.Instrument(nTc1).ChanUnits  = {'degC'};
c.Instrument(nTc1).Poly       = [];
c.Instrument(nTc1).Delays.Samples = [0];
c.Instrument(nTc1).ProcessData = [];
c.Instrument(nTc1).CovChans   = [1];
c.Instrument(nTc1).Alignment.Type = 'Slave';
c.Instrument(nTc1).Alignment.ChanNum = [1]; 

% Space to add hooks for the programs that can be called from the main calc program
c.ExtraCalculations.InstrumentLevel = {};               % add all the extra calculations (Matlab statements as cells)
                                                        % that one wants performed on the instrument data
                                                        
%------------------------------------------------
% Eddy system 1
%
%------------------------------------------------
nRovingEddy = 1;
c.System(nRovingEddy).ON 				   = 1;                        % system #1 calculations are ON
c.System(nRovingEddy).Type            = 'Eddy';                   % eddy correlation system
c.System(nRovingEddy).Name            = 'HP11 site, LI-7200 system';   % long system name
c.System(nRovingEddy).FieldName       = 'HP11';               % this is the output structure field name for all the system stats
c.System(nRovingEddy).Rotation        = 'three';                  % do three rotations
c.System(nRovingEddy).Fs              = c.Instrument(str2num(c.Instrument(nCR5000).FileID)).Fs;                       % sampling freq. for the system (data will be resampled to
% c.System(nRovingEddy).Fs              = 10;                       % sampling freq. for the system (data will be resampled to
                                                                % match this frequency if needed)
c.System(nRovingEddy).Instrument      = [ nSONIC nIRGA_op nTc1];          % select instruments (Anemometer + IRGA) for system 1
% removed, see below  c.System(1).MaxColumns      = 4+2;                      % Sonic + IRGA + TCs + (KH2O + Misc)
c.System(nRovingEddy).MaxFluxes       = 15;
c.System(nRovingEddy).MaxMisc         = 15;
c.System(nRovingEddy).CovVector = [];                             % create CovVector and Delays vectore 
c.System(nRovingEddy).ChanNames = [];
c.System(nRovingEddy).ChanUnits = [];
c.System(nRovingEddy).Delays.Samples = [];                        % based on the intrument setup
c.System(nRovingEddy).Delays.RefChan = 4;                         % Delays calculated against this channel (T sonic)
c.System(nRovingEddy).Delays.ArrayLengths = [5000 5000];          % the num of points used [ RefChan  DelayedChan]
c.System(nRovingEddy).Delays.Span = c.Instrument(str2num(c.Instrument(nCR5000).FileID)).Fs;                          % max LAG (see fr_delay.m)
% c.System(nRovingEddy).Delays.Span = 100;                          % max LAG (see fr_delay.m)
c.System(nRovingEddy).Delays.Channels = [5 6];%[c.Instrument(nIRGA_op).CovChans];                    % Delays calculated on channels 5 and 6 (CO2 and H2O) 
c.System(nRovingEddy).Delays.Overide =   0;                       % 1 - use covariance maximization, 0 - use preset delays
c.System(nRovingEddy).Alignment.Enable = 'FALSE';                  % 'TRUE' to enable or 'FALSE' to disable the alignment 
                                                                   % It's
                                                                   % not usually needed for CSI logger data so it's set to FALSE   

% removed the open path conversions of co2 and h2o from densities to mixing ratios in the following, since
% an LI7200 is being used: a "closed" open path instrument with inline WPL correction
c.System(nRovingEddy).ProcessData = {};
% RETURN the following 1 line!!!!!!!!!!!!!!!!!!!!                               
%                                   'Instrument_data(nSONIC).EngUnits(:,4) = Tair_a;',...                               
%                                   'miscVariables.Tair = mean(Tair_a);',... % already done under RovingEddy!!                      
totalChans = 0;
for i=1:length(c.System(nRovingEddy).Instrument)
    nInstrument = c.System(nRovingEddy).Instrument(i);
    c.System(nRovingEddy).CovVector       = [ c.System(nRovingEddy).CovVector ...
                                            c.Instrument(nInstrument).CovChans + totalChans ];
                                      
   c.System(nRovingEddy).ChanNames = [c.System(nRovingEddy).ChanNames c.Instrument(nInstrument).ChanNames(c.Instrument(nInstrument).CovChans)];
   c.System(nRovingEddy).ChanUnits = [c.System(nRovingEddy).ChanUnits c.Instrument(nInstrument).ChanUnits(c.Instrument(nInstrument).CovChans)];  
   
   c.System(nRovingEddy).Delays.Samples  = [ c.System(nRovingEddy).Delays.Samples  c.Instrument(nInstrument).Delays.Samples];
    totalChans                  = totalChans + c.Instrument(nInstrument).NumOfChans;
end
% Adjust channels that get changed
%c.System(nRovingEddy)	.ChanNames(4) = {'Ta'};
%c.System(nRovingEddy)	.ChanUnits(5:6) = {'\mumol/mol','mmol/mol'};

c.System(nRovingEddy)	.MaxColumns = totalChans;

%------------------------------------------------
% add all the extra calculations (Matlab statements as cells)
% that one wants performed on the System data

c.ExtraCalculations.SystemLevel = {};
 
 
%------------------------------------------------
% Spike test 
%
%------------------------------------------------
c.Spikes.ON           = 0;

c.Spikes.bp_vect      = [1250:1250:floor(30 * 60 * c.Instrument(nSONIC).Fs)];
c.Spikes.spike_av     = 'c';
c.Spikes.spike_limit  = 5;
c.Spikes.spike_thold  = [0.25 0.25 0.25 0.2 3.65 0.5 0.2]; % 
c.Spikes.despike.ON   = 1;

%------------------------------------------------
% Stationarity test 
%
%------------------------------------------------
c.Stationarity.ON           = 1;

c.Stationarity.no_of_rec    = 6;
c.Stationarity.no_of_subrec = 6;
c.Stationarity.min_length   = 20 * 60 * c.Instrument(nSONIC).Fs; % Minimum record length in samples
c.Stationarity.stationVec   = [1 2 3 4 5 6 7];
c.Stationarity.stationRef   = 3;

%------------------------------------------------
% Spectral calculation 
%
%------------------------------------------------
c.Spectra.ON 					= 1;

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
c.Spectra.psdVec           = 1:length(c.System(nRovingEddy).Instrument); %[1 2 3 4 5 6 7];
c.Spectra.csdRef           = 3; % Trace to do co-spectra against, mostly w
c.Spectra.csdVec           = setdiff(1:length(c.System(nRovingEddy).Instrument),c.Spectra.csdRef);
;

%------------------------------------------------
% Short file information
%
%------------------------------------------------
c.Shortfiles.Remove(1).System       = ''; %from this 'system' field remove the following fields below
% c.Shortfiles.Remove(1).Fields       = {'Zero_Rotations'};
% c.Shortfiles.Remove(1).ProcessData  = {...
%       'for k = 1:length(st); st(k).RovingEddy.Three_Rotations.LinDtr = []; end',...
%       'for k = 1:length(st); st(k).RovingEddy.Three_Rotations.AvgDtr.Cov = []; end',...
%    };
%	   'for k = 1:length(st); st(k).RovingEddy.Spectra.Csd = []; end;',...
%      'for k = 1:length(st); st(k).RovingEddy.Spectra.fCsd = []; end;',...
%      'for k = 1:length(st); st(k).RovingEddy.Spectra.fPsd = []; end;',...
%      'for k = 1:length(st); st(k).RovingEddy.Spectra.Psd = st(k).RovingEddy.Spectra.Psd(:,[4 5 6]); end',...
% 
% c.Shortfiles.Remove(2).System       = 'Instrument'; %from this 'system' field remove the following fields below
% c.Shortfiles.Remove(2).Fields       = { ...
%       'Type',...
%       'SerNum',...
%       'ChanNames',...
%       'ChanUnits',...
%    };
%       'Name',...
%       'Avg',...
%       'Min',...
%       'Max',...
%       'Std',...
%       'MiscVariables',...


