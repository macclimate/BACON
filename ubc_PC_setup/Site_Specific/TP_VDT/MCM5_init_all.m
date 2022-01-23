%===============================================================
function c = MCM5_init_all(dateIn)
%===============================================================
%
% (c) Zoran Nesic             File created:       Feb  25, 2018
%                              Last modification:  Feb  25, 2018
%
% McM5 

%
% Revisions:


Dates    = zeros(1,100);
% All times are GMT
Dates(1) = datenum(2018,3,1,0,30,0);                     %#ok<*NASGU> % system set up (approximate)

% The following line needs to be changed when dateIn becomes datenum (not a string yyyymmddQQ)
dateIn = datenum(str2num(dateIn(1:4)),str2num(dateIn(5:6)),str2num(dateIn(7:8)),str2num(dateIn(9:10))/96*24,0,0); %#ok<*ST2NM>

%-------------------------------
% Common 
%-------------------------------
c.PC_name       = fr_get_pc_name;
[c.path,c.hhour_path,c.database_path] = fr_get_local_path;
c.ext           = '.DMCM5';
c.hhour_ext     = '.hMCM5.mat';
c.site          = 'MCM5';
localPCname	   = fr_get_pc_name;					        % check for this name later on to select 
															% dataBase option (see nTair below)
c.gmt_to_local = -5/24;
                                                            
% Instrument numbers in the order of their dependency
% (independent first)

nSONIC = 1;     % Sonic CSAT3 
nIRGA_op  = 2;  % LI-7500 IRGA
nPb    = 3;     % barometric pressure (from IRGA)
nTair  = 4;     % from Sonic


% Variables listed within this section will become part of the
% output stats
c.MiscVariables(1).Name             = 'BarometricP';
c.MiscVariables(1).Execute          = {['nPb = ' num2str(nPb) ';'],...
                                        'miscVar = mean(Instrument_data(nPb).EngUnits);'};                                
%                                        'miscVar = 94;'};                                                                

c.MiscVariables(2).Name             = 'Tair';
%c.MiscVariables(2).Execute          = {['nTair = ' num2str(nTair) ';'],...
%                                       'miscVar = mean(Instrument_data(nTair).EngUnits);'};
% Jan 31, 2012 										   
c.MiscVariables(2).Execute          = {['nTair = ' num2str(nTair) ';'],...
                                       'miscVar = [];'};


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
c.Instrument(nSONIC).FileID     = '2';               % String!
c.Instrument(nSONIC).Fs         = 20;               % Frequency of sampling
c.Instrument(nSONIC).Oversample = 1;                     % 
c.Instrument(nSONIC).ChanNumbers = 1:5;            % chans to read from
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
%c.Instrument(nSONIC).Orientation  = 0;                   % degrees from North 
c.Instrument(nSONIC).Orientation  = 270;                   % degrees from North, CSAT facing west at VDT plots 3 Aug 2018
c.Instrument(nSONIC).Alignment.Type = 'Master';        % all instruments get aligned to this instrument (Master)
c.Instrument(nSONIC).Alignment.ChanNum = 3;            % chanel used for the alignment

%-----------------------
% IRGA #1 definitions:
%-----------------------
c.Instrument(nIRGA_op).Name      = 'EC IRGA OP';
c.Instrument(nIRGA_op).Type      = '7500';
c.Instrument(nIRGA_op).SerNum    = '000';
c.Instrument(nIRGA_op).FileID     = '7';
c.Instrument(nIRGA_op).FileType   = 'Digital2';             % 
c.Instrument(nIRGA_op).Fs         = 20;               % Frequency of sampling
c.Instrument(nIRGA_op).Oversample = 1;                     % 
c.Instrument(nIRGA_op).ChanNumbers = 1:8;                % *not* used (bug) for: chans to read from the Instrument(nIRGA_op)
c.Instrument(nIRGA_op).NumOfChans = length(c.Instrument(nIRGA_op).ChanNumbers);
c.Instrument(nIRGA_op).ChanNames  = {'co2','h2o','Aux','Tair','P_air','diag','mndx','cooler'};
c.Instrument(nIRGA_op).ChanUnits  = {'mmol/(m^3)','mmol/(m^3)','mV','degC','kPa','1','1','V'};                           
c.Instrument(nIRGA_op).CovChans   = [1 2];
c.Instrument(nIRGA_op).Delays.Samples = [0 0];
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
c.Instrument(nPb).Type       = 'From LI7500 file';
c.Instrument(nPb).SerNum     = 0;
c.Instrument(nPb).FileType   = 'Instrument';    % "Instrument" type file mean that an actual instrument should be used
c.Instrument(nPb).FileID     = num2str(nIRGA_op);   % 
c.Instrument(nPb).Fs         = c.Instrument(str2num(c.Instrument(nPb).FileID)).Fs;           % Frequency of sampling 
c.Instrument(nPb).Oversample = c.Instrument(str2num(c.Instrument(nPb).FileID)).Fs;   % 
c.Instrument(nPb).ChanNumbers = 5;  
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
c.Instrument(nTair).ChanNumbers = 4; 
c.Instrument(nTair).NumOfChans = length(c.Instrument(nTair).ChanNumbers);  
c.Instrument(nTair).ChanNames  = {'T_air'};
c.Instrument(nTair).ChanUnits  = {'degC'};
c.Instrument(nTair).Poly       = [];
c.Instrument(nTair).Delays.Samples = [];
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
c.System(nMainEddy).Name            = 'MCM5, Open Path System';   % long system name
c.System(nMainEddy).FieldName       = 'MainEddy';               % this is the output structure field name for all the system stats
c.System(nMainEddy).Rotation        = 'three';                  % do three rotations
c.System(nMainEddy).Fs              = c.Instrument(str2num(c.Instrument(nSONIC).FileID)).Fs;                 % sampling freq. for the system (data will be resampled to
                                                                % match this frequency if needed)
c.System(nMainEddy).Instrument      = [ nSONIC nIRGA_op];          % select instruments (Anemometer + IRGA) for system 1
% removed, see below  c.System(1).MaxColumns      = 4+2;                      % Sonic + IRGA + TCs + (KH2O + Misc)
c.System(nMainEddy).MaxFluxes       = 15;
c.System(nMainEddy).MaxMisc         = 15;
c.System(nMainEddy).CovVector = [];                             % create CovVector and Delays vectore 
%c.System(nMainEddy).ChanNames = [];
%c.System(nMainEddy).ChanUnits = [];
c.System(nMainEddy).Delays.Samples = [];                        % based on the intrument setup
c.System(nMainEddy).Delays.RefChan = 3;                         % Delays calculated against this channel (w sonic)
c.System(nMainEddy).Delays.ArrayLengths = [35000 35000];          % the num of points used [ RefChan  DelayedChan]
c.System(nMainEddy).Delays.Span = c.Instrument(str2num(c.Instrument(nSONIC).FileID)).Fs;                            % max LAG (see fr_delay.m)
c.System(nMainEddy).Delays.Channels = [5 6];%[c.Instrument(nIRGA_op).CovChans];                    % Delays calculated on channels 5 and 6 (CO2 and H2O) 
c.System(nMainEddy).Delays.Overide =   1;                       % 1 - use covariance maximization, 0 - use preset delays
c.System(nMainEddy).Alignment.Enable = 'FALSE';                  % 'TRUE' to enable or 'FALSE' to disable the alignment 
                                                                   % It's not usually needed for CSI logger data so it's set to FALSE                                                                  
c.System(nMainEddy).Alignment.SampleLength = 5000;
c.System(nMainEddy).Alignment.MaxAutoSampleReduction = 3;      % when aligning two instruments don't change the number of samples(don't resample)

% Jan 31, 2012 	
% c.System(nMainEddy).ProcessData = {['nIRGA_op = ' num2str(nIRGA_op) ';'],...
                                   % ['nSONIC = ' num2str(nSONIC) ';'],...
                                   % 'Pbarometric = miscVariables.BarometricP;', ...
                                   % 'Tair_v = Instrument_data(nSONIC).EngUnits(:,4);',...
                                   % 'H_density = Instrument_data(nIRGA_op).EngUnits(:,2);',...
                                   % 'C_density = Instrument_data(nIRGA_op).EngUnits(:,1);',...
                                   % 'Tair_a = fr_Tair_Chi_Iteration(H_density, Tair_v, Pbarometric);',...
                                   % 'Instrument_data(nSONIC).EngUnits(:,4) = Tair_a;',...                               
                                   % 'miscVariables.Tair = mean(Tair_a);',... 
                                   % '[Cmix,Hmix] = fr_convert_open_path_irga(C_density, H_density,Tair_a,Pbarometric);', ...
                                   % 'Instrument_data(nIRGA_op).EngUnits(:,1) = Cmix;',...
                                   % 'Instrument_data(nIRGA_op).EngUnits(:,2) = Hmix;',...
                                   % };
								   
c.System(nMainEddy).ProcessData = {};								   
%                    
% totalChans = 0;
% for i=1:length(c.System(nMainEddy).Instrument)
%     nInstrument = c.System(nMainEddy).Instrument(i);
%     c.System(nMainEddy).CovVector       = [ c.System(nMainEddy).CovVector ...
%                                             c.Instrument(nInstrument).CovChans + totalChans ];
%                                       
%    c.System(nMainEddy).ChanNames = [c.System(nMainEddy).ChanNames c.Instrument(nInstrument).ChanNames(c.Instrument(nInstrument).CovChans)];
%    c.System(nMainEddy).ChanUnits = [c.System(nMainEddy).ChanUnits c.Instrument(nInstrument).ChanUnits(c.Instrument(nInstrument).CovChans)];  
%    
%    c.System(nMainEddy).Delays.Samples  = [ c.System(nMainEddy).Delays.Samples  c.Instrument(nInstrument).Delays.Samples];
%     totalChans                  = totalChans + c.Instrument(nInstrument).NumOfChans;
% end
% % Adjust channels that get changed
% c.System(nMainEddy)	.ChanNames(4) = {'Ta'};
% c.System(nMainEddy)	.ChanUnits(5:6) = {'\mumol/mol','mmol/mol'};
% 
% c.System(nMainEddy)	.MaxColumns = totalChans;
% 
% %------------------------------------------------
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

 
%------------------------------------------------
% Spike test 
%
%------------------------------------------------
c.Spikes.ON           = 0;

c.Spikes.bp_vect      = [1250:1250:floor(30 * 60 * c.Instrument(nSONIC).Fs)]; %#ok<*NBRAK>
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
%c.Stationarity.stationVec   = 1:length(c.System(nMainEddy).Instrument);%[1 2 3 4 5 6 7];
c.Stationarity.stationVec   = [1 2 3 4 5 6 ];
c.Stationarity.stationRef   = 3;

%------------------------------------------------
% Spectral calculation 
%
%------------------------------------------------
c.Spectra.ON 					= 1;

c.Spectra.no_spec_bins     = 80;  %80
c.Spectra.no_in_bin    	   = 20;  %20 2
%c.Spectra.Fs        	   = 20.0; %set spectra calc frequency to that of system in do_eddy_calc.m
c.Spectra.nfft      		   = [];     % Let the program select the largest window that fits 2^14;
% No of pts returned by psd, the first is just the average of the data
c.Spectra.n_spec 			   = c.Spectra.nfft/2+1;

c.Spectra.noverlap         = 0;
% Here just give the name of the function used for windowing
c.Spectra.filtX            = 'hamming';
c.Spectra.dflag            = 'linear';

% This referes to the vector that is submitted to fr_calc_spectra which is 
% the same Eddy_HF_data that is required for fr_eddy_calc. If you want something 
% else change this before you calc the spectra
c.Spectra.psdVec           = 1:6; %[1 2 3 4 5 6 ];
c.Spectra.csdRef           = 3; % Trace to do co-spectra against, mostly w
c.Spectra.csdVec           = setdiff(1:6,c.Spectra.csdRef);

%------------------------------------------------
% Short file information
%
%------------------------------------------------
c.Shortfiles.Remove(1).System       = ''; %'RovingEddy'; %from this 'system' field remove the following fields below
%c.Shortfiles.Remove(1).Fields       = {'Zero_Rotations'};
%c.Shortfiles.Remove(1).ProcessData  = {...
%      'for k = 1:length(st); st(k).RovingEddy.Three_Rotations.LinDtr = []; end',...
%      'for k = 1:length(st); st(k).RovingEddy.Three_Rotations.AvgDtr.Cov = []; end',...
%};
%	   'for k = 1:length(st); st(k).RovingEddy.Spectra.Csd = []; end;',...
%      'for k = 1:length(st); st(k).RovingEddy.Spectra.fCsd = []; end;',...
%      'for k = 1:length(st); st(k).RovingEddy.Spectra.fPsd = []; end;',...
%      'for k = 1:length(st); st(k).RovingEddy.Spectra.Psd = st(k).RovingEddy.Spectra.Psd(:,[4 5 6]); end',...

%c.Shortfiles.Remove(2).System       = 'Instrument'; %from this 'system' field remove the following fields below
%c.Shortfiles.Remove(2).Fields       = { ...
%      'Type',...
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


