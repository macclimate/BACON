function [] = mcm_metfill(year, quickflag)
ls = addpath_loadstart;
load_path = [ls 'Matlab/Data/Met/Final_Cleaned/'];
save_path = [ls 'Matlab/Data/Met/Final_Filled/'];
jjb_check_dirs(save_path,0);

%%%% Soil temperature averaging settings:
% soil_tracker_path = [ls 'Matlab/Data/Met/Final_Filled/Docs/'];
soil_tracker_path = [ls 'Matlab/Config/Met/Filling-SoilPitKeepLists/']; % Changed 01-May-2012


if nargin ==1 
    quickflag = 0;
end
%%%%%%%%%%%%%%%%%
[year_start year_end] = jjb_checkyear(year);
% 
% if isempty(year)==1
%     year = input('Enter year(s) to process; single or sequence (e.g. [2007:2010]): >');
% elseif ischar(year)==1
%     year = str2double(year);
% end
% 
% if numel(year)>1
%         year_start = min(year);
%         year_end = max(year);
% else
%     year_start = year;
%     year_end = year;
% end

%%%%%%%%%%%%%%%%%

%% Main Loop

for year_ctr = year_start:1:year_end
close all
yr_str = num2str(year_ctr);
disp(['Working on year ' yr_str '.']);

%%% If after 2008, exclude TP89 -- discontinued
if year_ctr <= 2008
site_labels = {'TP39'; 'TP74';'TP89'; 'TP02'};
site_refs = (1:1:4)';
TP39 = []; TP89 = []; TP74 = []; TP02 = [];
elseif year_ctr >=2009 && year_ctr <=2011
site_labels = {'TP39'; 'TP74'; 'TP02'};
site_refs = [1;2;4];
TP39 = []; TP74 = []; TP02 = [];
elseif year_ctr >=2012 && year_ctr <=2019
site_labels = {'TP39'; 'TP74'; 'TP02';'TPD';'TP_VDT'};
site_refs = [1;2;4;5;7];
TP39 = []; TP74 = []; TP02 = []; TPD = []; TP_VDT = [];

elseif year_ctr >=2020 && year_ctr <=2021
site_labels = {'TP39'; 'TP74'; 'TP02';'TPD';'TPAg';'TP_VDT'};
site_refs = [1;2;4;5;6;7];
TP39 = []; TP74 = []; TP02 = []; TPD = []; TPAg = []; TP_VDT = [];

elseif year_ctr >=2022
site_labels = {'TP39'; 'TP74'; 'TP02';'TPD';'TPAg'};
site_refs = [1;2;4;5;6];
TP39 = []; TP74 = []; TP02 = []; TPD = []; TPAg = [];

end
num_sites = size(site_labels,1);


% info = struct;
%  for i = 1:1:num_sites
%      
% %     %%% Declare Paths:
% %     if year >= 2008 || (year == 2007 && i == 1)
% %         %Path for Cleaned data -- 2008 onwards:
% %         
% %         
% %         info(i).hdr_path = [ls 'Matlab/Data/Met/Raw1/Docs/'];
% %         info(i).hdr_name = '_OutputTemplate.csv';
% %         info(i).hdr_cols = 3;
% %         info(i).load_dir = [ls 'Matlab/Data/Met/Final_Cleaned/'];
% %     else
% %         info(i).hdr_path = [ls 'Matlab/Data/Met/Final_Cleaned/CCP/Headers/'];
% %         info(i).hdr_name = '_CCP_Names.csv';
% %         info(i).hdr_cols = 2;
% %         info(i).load_dir = [ls 'Matlab/Data/Met/Final_Cleaned/CCP/'];
% %     end
% %     
% info.header = jjb_hdr_read([master_out_path '/Docs/' site_labels(i,:) '_master_list.csv'],',');
% 
%  end
%%% Load Header for the site:

% Load the file that keeps track of what pits were used in Ts averaging:

if exist([soil_tracker_path 'soil_pit_keep_' yr_str '.dat'],'file')==2
    if quickflag == 1
        resp_tracker = 1;
    else
        commandwindow;
    resp_tracker = input('Tracker for soil pit averaging found.  Enter <1> to use these values, <0> to input manually: ');
    end
    if resp_tracker == 1
        prompt_flag = 1;
        soil_tracker = csvread([soil_tracker_path 'soil_pit_keep_' yr_str '.dat']);   
    else
        prompt_flag = 0;
        soil_tracker = zeros(6,4);
    end
    
else
    disp('tracker for soil pit averaging not found. Must be done manually');
    soil_tracker = zeros(6,4);
    prompt_flag = 0;
    
end

%%%
% labels = {'AirTemp_AbvCnpy'; 'RelHum_AbvCnpy'; 'DownPAR_AbvCnpy'; 'WindSpd'; ...
%     'Pressure'; 'SoilTemp_2cm'; 'SoilTemp_5cm'; 'SoilTemp_10cm'; 'SoilTemp_20cm';...
%     'SoilTemp_50cm'; 'SoilTemp_100cm'; 'SM_A_30_avg'; 'SM_B_30_avg'; 'SM_A_30_filled';...
%     'SM_B_30_filled'; 'NetRad_AbvCnpy'; 'DownShortWaveRad_Abv_Cnpy'; 'VPD'};
%%% Updated 2025-03-16 by JJB to add pit C
labels = {'AirTemp_AbvCnpy'; 'RelHum_AbvCnpy'; 'DownPAR_AbvCnpy'; 'WindSpd'; ...
    'Pressure'; 'SoilTemp_2cm'; 'SoilTemp_5cm'; 'SoilTemp_10cm'; 'SoilTemp_20cm';...
    'SoilTemp_50cm'; 'SoilTemp_100cm'; 'SM_A_30_avg'; 'SM_B_30_avg'; 'SM_A_30_filled';...
    'SM_B_30_filled'; 'NetRad_AbvCnpy'; 'DownShortWaveRad_Abv_Cnpy'; 'VPD'; 'SM_C_30_avg';...
    'SM_D_30_filled'; 'SM_D_30_avg'; 'SM_D_30_filled'};

varnames(1,1) = cellstr('Ta'); varnames(2,1) = cellstr('RH'); varnames(3,1) = cellstr('PAR');
varnames(4,1) = cellstr('WS'); varnames(5,1) = cellstr('APR'); varnames(6,1) = cellstr('Ts2');
varnames(7,1) = cellstr('Ts5'); varnames(8,1) = cellstr('Ts10'); varnames(9,1) = cellstr('Ts20'); 
varnames(10,1) = cellstr('Ts50'); varnames(11,1) = cellstr('Ts100');
varnames(12,1) = cellstr('SM_30a'); varnames(13,1) = cellstr('SM_30b');
varnames(14,1) = cellstr('SM_30a_filled'); varnames(15,1) = cellstr('SM_30b_filled');
varnames(16,1) = cellstr('Rn'); varnames(17,1) = cellstr('SW_down');
varnames(18,1) = cellstr('VPD');
%%% Updated 2025-03-16 by JJB to add pit C
varnames(19,1) = cellstr('SM_30c'); 
varnames(20,1) = cellstr('SM_30c_filled');
varnames(21,1) = cellstr('SM_30d'); 
varnames(22,1) = cellstr('SM_30d_filled');
% labels(1,1) = cellstr('AirTemp_AbvCnpy'); labels(1,2) = cellstr('RelHum_AbvCnpy'); 
% labels(1,3) = cellstr('DownPAR_AbvCnpy'); labels(1,4) = cellstr('WindSpd'); 
% labels(1,5) = cellstr('Pressure'); labels(1,6) = cellstr('SoilTemp_2cm'); 
% labels(1,7) = cellstr('SoilTemp_5cm'); labels(1,8) = cellstr('SoilTemp_10cm'); 
% labels(1,9) = cellstr('SoilTemp_20cm'); labels(1,10) = cellstr('SoilTemp_50cm'); 
% labels(1,11) = cellstr('SoilTemp_100cm'); labels(1,12) = cellstr('SM_A_30_avg'); 
% labels(1,13) = cellstr('SM_B_30_avg'); labels(1,14) = cellstr('SM_A_30_filled'); 
% labels(1,15) = cellstr('SM_B_30_filled'); 

%% Load data:
% We want to load the following data:
% Ta, Ts, SM, PAR, WS, APR
% Ts must be averaged and then filled
% SM is just going to be averaged (over top 30cm)
% APR -- will likely have sites without pressure data at all.

for i = 1:1:num_sites
    site = site_labels{i,1};
    %%%% Load Data
    %%% Re-written July 30, 2010 by JJB - instead of reading from the
    %%% master data file (from mcm_data_compiler), we will load the data
    %%% from the /Final_Cleaned/ directory:
    
    
%     load([master_out_path site '/' site '_data_master.mat']);
    load([load_path site '/' site '_met_cleaned_' yr_str '.mat']);
%     data(1).header = jjb_hdr_read([info(i).hdr_path site info(i).hdr_name], ',', info(i).hdr_cols);
%     temp(1).load_path = [info(i).load_dir site '/' site '_' yr_str '.'];
    %%%% Load Variables:
    temp(1).Ta = master.data(:,mcm_find_right_col(master.labels,'AirTemp_AbvCnpy'));
    temp(1).RH = master.data(:,mcm_find_right_col(master.labels,'RelHum_AbvCnpy'));
    temp(1).PAR = master.data(:,mcm_find_right_col(master.labels,'DownPAR_AbvCnpy'));
    temp(1).WS = master.data(:,mcm_find_right_col(master.labels,'WindSpd'));
    temp(1).Wdir = master.data(:,mcm_find_right_col(master.labels,'WindDir'));
    
%%%% Soil pit data
%     Ts(i).Ts2a = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_A_2cm')); if isempty(Ts(i).Ts2a)==1; Ts(i).Ts2a = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts2b = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_B_2cm')); if isempty(Ts(i).Ts2b)==1; Ts(i).Ts2b = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts5a = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_A_5cm')); if isempty(Ts(i).Ts5a)==1; Ts(i).Ts5a = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts5b = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_B_5cm')); if isempty(Ts(i).Ts5b)==1; Ts(i).Ts5b = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts10a = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_A_10cm')); if isempty(Ts(i).Ts10a)==1; Ts(i).Ts10a = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts10b = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_B_10cm')); if isempty(Ts(i).Ts10b)==1; Ts(i).Ts10b = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts20a = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_A_20cm')); if isempty(Ts(i).Ts20a)==1; Ts(i).Ts20a = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts20b = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_B_20cm')); if isempty(Ts(i).Ts20b)==1; Ts(i).Ts20b = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts50a = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_A_50cm')); if isempty(Ts(i).Ts50a)==1; Ts(i).Ts50a = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts50b = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_B_50cm')); if isempty(Ts(i).Ts50b)==1; Ts(i).Ts50b = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts100a = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_A_100cm')); if isempty(Ts(i).Ts100a)==1; Ts(i).Ts100a = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts100b = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_B_100cm')); if isempty(Ts(i).Ts100b)==1; Ts(i).Ts100b = NaN.*ones(length(temp(1).Ta),1);end    
%     
%     SM(i).SM5a = master.data(:,mcm_find_right_col(master.labels,'SM_A_5cm')); if isempty(SM(i).SM5a)==1; SM(i).SM5a = NaN.*ones(length(temp(1).Ta),1);end
%     SM(i).SM5b = master.data(:,mcm_find_right_col(master.labels,'SM_B_5cm')); if isempty(SM(i).SM5b)==1; SM(i).SM5b = NaN.*ones(length(temp(1).Ta),1);end
%     SM(i).SM10a = master.data(:,mcm_find_right_col(master.labels,'SM_A_10cm')); if isempty(SM(i).SM10a)==1; SM(i).SM10a = NaN.*ones(length(temp(1).Ta),1);end
%     SM(i).SM10b = master.data(:,mcm_find_right_col(master.labels,'SM_B_10cm')); if isempty(SM(i).SM10b)==1; SM(i).SM10b = NaN.*ones(length(temp(1).Ta),1);end
%     SM(i).SM20a = master.data(:,mcm_find_right_col(master.labels,'SM_A_20cm')); if isempty(SM(i).SM20a)==1; SM(i).SM20a = NaN.*ones(length(temp(1).Ta),1);end
%     SM(i).SM20b = master.data(:,mcm_find_right_col(master.labels,'SM_B_20cm')); if isempty(SM(i).SM20b)==1; SM(i).SM20b = NaN.*ones(length(temp(1).Ta),1);end
%     SM(i).SM50a = master.data(:,mcm_find_right_col(master.labels,'SM_A_50cm')); if isempty(SM(i).SM50a)==1; SM(i).SM50a = NaN.*ones(length(temp(1).Ta),1);end
%     SM(i).SM50b = master.data(:,mcm_find_right_col(master.labels,'SM_B_50cm')); if isempty(SM(i).SM50b)==1; SM(i).SM50b = NaN.*ones(length(temp(1).Ta),1);end
% 
%     %%%% Added 2025-03-16 by JJB for Soil pit C %%%%%%%%%
%     Ts(i).Ts2c = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_C_2cm')); if isempty(Ts(i).Ts2c)==1; Ts(i).Ts2c = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts5c = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_C_5cm')); if isempty(Ts(i).Ts5c)==1; Ts(i).Ts5c = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts10c = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_C_10cm')); if isempty(Ts(i).Ts10c)==1; Ts(i).Ts10c = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts20c = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_C_20cm')); if isempty(Ts(i).Ts20c)==1; Ts(i).Ts20c = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts50c = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_C_50cm')); if isempty(Ts(i).Ts50c)==1; Ts(i).Ts50c = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts100c = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_C_100cm')); if isempty(Ts(i).Ts100c)==1; Ts(i).Ts100c = NaN.*ones(length(temp(1).Ta),1);end
%  
%     SM(i).SM5c = master.data(:,mcm_find_right_col(master.labels,'SM_C_5cm')); if isempty(SM(i).SM5c)==1; SM(i).SM5c = NaN.*ones(length(temp(1).Ta),1);end
%     SM(i).SM10c = master.data(:,mcm_find_right_col(master.labels,'SM_C_10cm')); if isempty(SM(i).SM10c)==1; SM(i).SM10c = NaN.*ones(length(temp(1).Ta),1);end
%     SM(i).SM20c = master.data(:,mcm_find_right_col(master.labels,'SM_C_20cm')); if isempty(SM(i).SM20c)==1; SM(i).SM20c = NaN.*ones(length(temp(1).Ta),1);end
%     SM(i).SM50c = master.data(:,mcm_find_right_col(master.labels,'SM_C_50cm')); if isempty(SM(i).SM50c)==1; SM(i).SM50c = NaN.*ones(length(temp(1).Ta),1);end
% 
%         %%%% Added 2025-03-16 by JJB for Soil pit C %%%%%%%%%
%     Ts(i).Ts2d = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_D_2cm')); if isempty(Ts(i).Ts2d)==1; Ts(i).Ts2d = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts5d = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_D_5cm')); if isempty(Ts(i).Ts5d)==1; Ts(i).Ts5d = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts10d = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_D_10cm')); if isempty(Ts(i).Ts10d)==1; Ts(i).Ts10d = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts20d = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_D_20cm')); if isempty(Ts(i).Ts20d)==1; Ts(i).Ts20d = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts50d = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_D_50cm')); if isempty(Ts(i).Ts50d)==1; Ts(i).Ts50d = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts100d = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_D_100cm')); if isempty(Ts(i).Ts100d)==1; Ts(i).Ts100d = NaN.*ones(length(temp(1).Ta),1);end
%  
%     SM(i).SM5d = master.data(:,mcm_find_right_col(master.labels,'SM_D_5cm')); if isempty(SM(i).SM5d)==1; SM(i).SM5d = NaN.*ones(length(temp(1).Ta),1);end
%     SM(i).SM10d = master.data(:,mcm_find_right_col(master.labels,'SM_D_10cm')); if isempty(SM(i).SM10d)==1; SM(i).SM10d = NaN.*ones(length(temp(1).Ta),1);end
%     SM(i).SM20d = master.data(:,mcm_find_right_col(master.labels,'SM_D_20cm')); if isempty(SM(i).SM20d)==1; SM(i).SM20d = NaN.*ones(length(temp(1).Ta),1);end
%     SM(i).SM50d = master.data(:,mcm_find_right_col(master.labels,'SM_D_50cm')); if isempty(SM(i).SM50d)==1; SM(i).SM50d = NaN.*ones(length(temp(1).Ta),1);end
% 
%     %%% Added 2026-03-03 by JJB -- including sensors at 7.5 cm
%     Ts(i).Ts7a = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_A_7cm')); if isempty(Ts(i).Ts7a)==1; Ts(i).Ts7a = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts7b = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_B_7cm')); if isempty(Ts(i).Ts7b)==1; Ts(i).Ts7b = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts7c = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_C_7cm')); if isempty(Ts(i).Ts7c)==1; Ts(i).Ts7c = NaN.*ones(length(temp(1).Ta),1);end
%     Ts(i).Ts7d = master.data(:,mcm_find_right_col(master.labels,'SoilTemp_D_7cm')); if isempty(Ts(i).Ts7d)==1; Ts(i).Ts7d = NaN.*ones(length(temp(1).Ta),1);end

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Define the mapping of Variable Names to Master Labels
Ts_mapping = { ...
    'Ts2a',   'SoilTemp_A_2cm';
    'Ts2b',   'SoilTemp_B_2cm';
    'Ts5a',   'SoilTemp_A_5cm';
    'Ts5b',   'SoilTemp_B_5cm';
    'Ts10a',  'SoilTemp_A_10cm';
    'Ts10b',  'SoilTemp_B_10cm';
    'Ts20a',  'SoilTemp_A_20cm';
    'Ts20b',  'SoilTemp_B_20cm';
    'Ts50a',  'SoilTemp_A_50cm';
    'Ts50b',  'SoilTemp_B_50cm';
    'Ts100a', 'SoilTemp_A_100cm';
    'Ts100b', 'SoilTemp_B_100cm';
     'Ts2c',   'SoilTemp_C_2cm';
    'Ts5c',   'SoilTemp_C_5cm';
    'Ts10c',  'SoilTemp_C_10cm';
    'Ts20c',  'SoilTemp_C_20cm';
    'Ts50c',  'SoilTemp_C_50cm';
    'Ts100c', 'SoilTemp_C_100cm';
    'Ts2d',   'SoilTemp_D_2cm';
    'Ts5d',   'SoilTemp_D_5cm';
    'Ts10d',  'SoilTemp_D_10cm';
    'Ts20d',  'SoilTemp_D_20cm';
    'Ts50d',  'SoilTemp_D_50cm';
    'Ts100d', 'SoilTemp_D_100cm';
    'Ts7a',   'SoilTemp_A_7cm';
    'Ts7b',   'SoilTemp_B_7cm';
    'Ts7c',   'SoilTemp_C_7cm';
    'Ts7d',   'SoilTemp_D_7cm'  ...
    };

SM_mapping = {
    'SM5a',   'SM_A_5cm';
    'SM5b',   'SM_B_5cm';
    'SM10a',  'SM_A_10cm';
    'SM10b',  'SM_B_10cm';
    'SM20a',  'SM_A_20cm';
    'SM20b',  'SM_B_20cm';
    'SM50a',  'SM_A_50cm';
    'SM50b',  'SM_B_50cm';
    'SM5c',   'SM_C_5cm';
    'SM10c',  'SM_C_10cm';
    'SM20c',  'SM_C_20cm';
    'SM50c',  'SM_C_50cm';
    'SM5d',   'SM_D_5cm';
    'SM10d',  'SM_D_10cm';
    'SM20d',  'SM_D_20cm';
    'SM50d',  'SM_D_50cm';
    'SM7a',   'SM_A_7cm';
    'SM7b',   'SM_B_7cm';
    'SM7c',   'SM_C_7cm';
    'SM7d',   'SM_D_7cm';
};

for k = 1:1:size(Ts_mapping,1)
    try
        Ts(i).(Ts_mapping{k,1}) = master.data(:,mcm_find_right_col(master.labels,Ts_mapping{k,2}));
    catch
        Ts(i).(Ts_mapping{k,1}) = NaN.*ones(length(temp(1).Ta),1);
        disp(['Variable ' Ts_mapping{k,2} ' not found for site ' site ' and year ' yr_str '.']);
    end
    if isempty(Ts(i).(Ts_mapping{k,1}))==1; Ts(i).(Ts_mapping{k,1}) = NaN.*ones(length(temp(1).Ta),1);end
end

for k = 1:1:size(SM_mapping,1)
    try
        SM(i).(SM_mapping{k,1}) = master.data(:,mcm_find_right_col(master.labels,SM_mapping{k,2}));
    catch
        SM(i).(SM_mapping{k,1}) = NaN.*ones(length(temp(1).Ta),1);
        disp(['Variable ' SM_mapping{k,2} ' not found for site ' site ' and year ' yr_str '.']);
    end
    if isempty(SM(i).(SM_mapping{k,1}))==1; SM(i).(SM_mapping{k,1}) = NaN.*ones(length(temp(1).Ta),1);end
end

%%%%%%%%%%%%%%%%%%%%% 
    %%% Added 2021-01-01 by JJB - Loading SM data for TPAg
    if strcmp(site,'TPAg')==1 || strcmp(site,'TP_VDT')==1
    SM(i).SM10_40a = master.data(:,mcm_find_right_col(master.labels,'SM_A_10-40cm'));
    end
    
     %%%%% APR might not exist, so if it doesn't, we don't load it.
        try data(i).APR = master.data(:,mcm_find_right_col(master.labels,'Pressure')); 
        catch;  data(i).APR = NaN.*ones(length(temp(1).Ta),1);
            disp(['Can''t find Pressure data for site ' site]);
        end
        if isempty(data(i).APR)==1
           data(i).APR = NaN.*ones(length(temp(1).Ta),1);
           disp(['No Pressure data for site ' site ' and year ' yr_str '.']);
        end

    %%%% Load Rn and SW_down (SW_down for TP39 only)
    data(i).Rn = master.data(:,mcm_find_right_col(master.labels,'NetRad_AbvCnpy'));
    try
        data(i).SW = master.data(:,mcm_find_right_col(master.labels,'DownShortwaveRad'));
    catch
        data(i).SW = NaN.*ones(length(temp(1).Ta),1);

        disp(['Can''t find SW_down data for site ' site]);
    end
    if isempty(data(i).SW)==1
        data(i).SW = NaN.*ones(length(temp(1).Ta),1);
        disp(['Can''t find SW_down data for site ' site]);
    end
    % Load Neural Networks - These were created using:
    % making_Rn_nnet_filling.m
    data(i).net = load([save_path 'Rn_nnet/' site '_nnet.mat']);
        

    
    
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% This command restructures all the variables from temp into one
%%% matrix per site --  removed first column that was just a 'year' tag 
% Any variables you want filled, throw into this matrix..
        eval([site ' = [' site ' ;  temp(1).Ta temp(1).RH temp(1).PAR temp(1).WS];' ]);
        clear temp master;     
end

%% Step 2:  Do Some averaging for Ts 2--100cm:
for i = 1:1:num_sites
        site = site_labels{i,1};
        right_col = site_refs(i);
    fsoil(i) = figure('Name',[site ': Ts'],'NumberTitle','off'); clf; set(fsoil(i),'WindowStyle','Docked');
%         subplot(3,2,1); plot(Ts(i).Ts2a,'b'); hold on; plot(Ts(i).Ts2b,'c');title('2cm'); legend('Pit A', 'Pit B');
%         subplot(3,2,2); plot(Ts(i).Ts5a,'b'); hold on; plot(Ts(i).Ts5b,'c');title('5cm')
%         subplot(3,2,3); plot(Ts(i).Ts10a,'b'); hold on; plot(Ts(i).Ts10b,'c');title('10cm')
%         subplot(3,2,4); plot(Ts(i).Ts20a,'b'); hold on; plot(Ts(i).Ts20b,'c');title('20cm')
%         subplot(3,2,5); plot(Ts(i).Ts50a,'b'); hold on; plot(Ts(i).Ts50b,'c');title('50cm')
%         subplot(3,2,6); plot(Ts(i).Ts100a,'b'); hold on; plot(Ts(i).Ts100b,'c');title('100cm')

%%%% Updated 2025-05-16 by JJB - adding a third pit
        subplot(3,2,1); plot(Ts(i).Ts2a,'b'); hold on; plot(Ts(i).Ts2b,'c');plot(Ts(i).Ts2c,'m');title('2cm'); legend('Pit A', 'Pit B', 'Pit C');
        subplot(3,2,2); plot(Ts(i).Ts5a,'b'); hold on; plot(Ts(i).Ts5b,'c');plot(Ts(i).Ts5c,'m');title('5cm')
        subplot(3,2,3); plot(Ts(i).Ts10a,'b'); hold on; plot(Ts(i).Ts10b,'c');plot(Ts(i).Ts10c,'m');title('10cm')
        subplot(3,2,4); plot(Ts(i).Ts20a,'b'); hold on; plot(Ts(i).Ts20b,'c');plot(Ts(i).Ts20c,'m');title('20cm')
        subplot(3,2,5); plot(Ts(i).Ts50a,'b'); hold on; plot(Ts(i).Ts50b,'c');plot(Ts(i).Ts50c,'m');title('50cm')
        subplot(3,2,6); plot(Ts(i).Ts100a,'b'); hold on; plot(Ts(i).Ts100b,'c');plot(Ts(i).Ts100c,'m');title('100cm')
          
        if prompt_flag == 1
            resp2 = soil_tracker(1,right_col); resp5 = soil_tracker(2,right_col); resp10 = soil_tracker(3,right_col); 
            resp20 = soil_tracker(4,right_col); resp50 = soil_tracker(5,right_col); resp100 = soil_tracker(6,right_col); 
        else
            commandwindow;
           
disp(['Please look at Ts data for ' site_labels{i,1}]);
disp('Pit A = 1, Pit B = 2, Pit C = 3'); 
resp2 = input('2cm -- enter (no commas) all pits to use [e.g., 13 for pits 1 and 3; 123 to average 1,2,3]: ');
resp5 = input('5cm -- enter (no commas) all pits to use [e.g., 13 for pits 1 and 3; 123 to average 1,2,3]: ');
resp10 = input('10cm -- enter (no commas) all pits to use [e.g., 13 for pits 1 and 3; 123 to average 1,2,3]: ');
resp20 = input('20cm -- enter (no commas) all pits to use [e.g., 13 for pits 1 and 3; 123 to average 1,2,3]: ');
resp50 = input('50cm -- enter (no commas) all pits to use [e.g., 13 for pits 1 and 3; 123 to average 1,2,3]: ');
resp100 = input('100cm -- enter (no commas) all pits to use [e.g., 13 for pits 1 and 3; 123 to average 1,2,3]: ');

            soil_tracker(1,right_col) = resp2; soil_tracker(2,right_col)= resp5;  soil_tracker(3,right_col) = resp10; 
            soil_tracker(4,right_col) = resp20; soil_tracker(5,right_col)= resp50;  soil_tracker(6,right_col) = resp100;    
        end
    % 2025-03-16: Something new: use the value indicated in the tracker
    % (e.g., 123) to dictate which pits get averaged.
%         num2pit = {1,'a';2,'b';3,'c';4,'d';5,'e';6,'f';7,'g';8,'h';9,'i'};
        % Conver the response from a multidigit number to multiple
        % single-digit numbers (e.g., 123 to [1,2,3]
        resp2 = dec2base(resp2,10) - '0'; Ts2_tmp = [Ts(i).Ts2a,Ts(i).Ts2b,Ts(i).Ts2c]; Ts(i).Ts2 = nanmean(Ts2_tmp(:,resp2),2);
        resp5 = dec2base(resp5,10) - '0'; Ts5_tmp = [Ts(i).Ts5a,Ts(i).Ts5b,Ts(i).Ts5c]; Ts(i).Ts5 = nanmean(Ts5_tmp(:,resp5),2);
        resp10 = dec2base(resp10,10) - '0'; Ts10_tmp = [Ts(i).Ts10a,Ts(i).Ts10b,Ts(i).Ts10c]; Ts(i).Ts10 = nanmean(Ts10_tmp(:,resp10),2);
        resp20 = dec2base(resp20,10) - '0'; Ts20_tmp = [Ts(i).Ts20a,Ts(i).Ts20b,Ts(i).Ts20c]; Ts(i).Ts20 = nanmean(Ts20_tmp(:,resp20),2);
        resp50 = dec2base(resp50,10) - '0'; Ts50_tmp = [Ts(i).Ts50a,Ts(i).Ts50b,Ts(i).Ts50c]; Ts(i).Ts50 = nanmean(Ts50_tmp(:,resp50),2);
        resp100 = dec2base(resp100,10) - '0'; Ts100_tmp = [Ts(i).Ts100a,Ts(i).Ts100b,Ts(i).Ts100c]; Ts(i).Ts100 = nanmean(Ts100_tmp(:,resp100),2);

        %%%% The old method
% switch resp2;   case 1; Ts(i).Ts2 = Ts(i).Ts2a;      case 2; Ts(i).Ts2 = Ts(i).Ts2b;    case 3; Ts(i).Ts2 = row_nanmean([Ts(i).Ts2a Ts(i).Ts2b]); end
% switch resp5;   case 1; Ts(i).Ts5 = Ts(i).Ts5a;      case 2; Ts(i).Ts5 = Ts(i).Ts5b;    case 3; Ts(i).Ts5 = row_nanmean([Ts(i).Ts5a Ts(i).Ts5b]); end
% switch resp10;  case 1; Ts(i).Ts10 = Ts(i).Ts10a;    case 2; Ts(i).Ts10 = Ts(i).Ts10b;  case 3; Ts(i).Ts10 = row_nanmean([Ts(i).Ts10a Ts(i).Ts10b]); end
% switch resp20;  case 1; Ts(i).Ts20 = Ts(i).Ts20a;    case 2; Ts(i).Ts20 = Ts(i).Ts20b;  case 3; Ts(i).Ts20 = row_nanmean([Ts(i).Ts20a Ts(i).Ts20b]); end
% switch resp50;   case 1; Ts(i).Ts50 = Ts(i).Ts50a;      case 2; Ts(i).Ts50 = Ts(i).Ts50b;    case 3; Ts(i).Ts50 = row_nanmean([Ts(i).Ts50a Ts(i).Ts50b]); end
% switch resp100;  case 1; Ts(i).Ts100 = Ts(i).Ts100a;    case 2; Ts(i).Ts100 = Ts(i).Ts100b;  case 3; Ts(i).Ts100 = row_nanmean([Ts(i).Ts100a Ts(i).Ts100b]); end


%%% JJB 2025-03-19: I've disabled the entire next section--I don't think it
%%% helps gapfilling to fill one pit with another. It's probably much
%%% better to fill large gaps with correlations with air temperature (later
%%% in the script)
% Fill any gaps with 
% ind_Ts2 = find(isnan(Ts(i).Ts2) & (~isnan(Ts(i).Ts2a) | ~isnan(Ts(i).Ts2b)));
% if ~isempty(ind_Ts2);   Ts(i).Ts2(ind_Ts2) = row_nanmean([Ts(i).Ts2a(ind_Ts2) Ts(i).Ts2b(ind_Ts2)]); end
% ind_Ts5 = find(isnan(Ts(i).Ts5) & (~isnan(Ts(i).Ts5a) | ~isnan(Ts(i).Ts5b)));
% if ~isempty(ind_Ts5);   Ts(i).Ts5(ind_Ts5) = row_nanmean([Ts(i).Ts5a(ind_Ts5) Ts(i).Ts5b(ind_Ts5)]); end
% ind_Ts10 = find(isnan(Ts(i).Ts10) & (~isnan(Ts(i).Ts10a) | ~isnan(Ts(i).Ts10b)));
% if ~isempty(ind_Ts10);   Ts(i).Ts10(ind_Ts10) = row_nanmean([Ts(i).Ts10a(ind_Ts10) Ts(i).Ts10b(ind_Ts10)]); end
% ind_Ts20 = find(isnan(Ts(i).Ts20) & (~isnan(Ts(i).Ts20a) | ~isnan(Ts(i).Ts20b)));
% if ~isempty(ind_Ts20);   Ts(i).Ts20(ind_Ts20) = row_nanmean([Ts(i).Ts20a(ind_Ts20) Ts(i).Ts20b(ind_Ts20)]); end
% ind_Ts50 = find(isnan(Ts(i).Ts50) & (~isnan(Ts(i).Ts50a) | ~isnan(Ts(i).Ts50b)));
% if ~isempty(ind_Ts50);   Ts(i).Ts50(ind_Ts50) = row_nanmean([Ts(i).Ts50a(ind_Ts50) Ts(i).Ts50b(ind_Ts50)]); end
% ind_Ts100 = find(isnan(Ts(i).Ts100) & (~isnan(Ts(i).Ts100a) | ~isnan(Ts(i).Ts100b)));
% if ~isempty(ind_Ts100);   Ts(i).Ts100(ind_Ts100) = row_nanmean([Ts(i).Ts100a(ind_Ts100) Ts(i).Ts100b(ind_Ts100)]); end
% clear resp2 resp5 resp10 resp20 resp50 resp100;
end

%%% Save soil_tracker:
csvwrite([soil_tracker_path 'soil_pit_keep_' yr_str '.dat'],soil_tracker)
commandwindow;
disp('soil tracker saved');
%% Step 3: Do 30cm averaging for SM:

for  i = 1:1:num_sites
        site = site_labels{i,1};   
        disp(site);
        switch site 
            case {'TPAg'}
                SM_ina = [SM(i).SM5a, SM(i).SM10_40a];
                [SM(i).SM30a SM(i).flag_a]= mcm_SM30cm_avg(SM_ina,2);  
                SM(i).SM30b = NaN.*ones(size(SM_ina,1),1);     
                SM(i).flag_b = NaN.*ones(size(SM_ina,1),1);     
                SM_inc = [SM(i).SM7c, SM(i).SM20c];
                [SM(i).SM30c SM(i).flag_c]= mcm_SM30cm_avg(SM_inc,3);  
                
                
            case {'TP_VDT'}
                SM_ina = [SM(i).SM5a, SM(i).SM10_40a];
                [SM(i).SM30a SM(i).flag_a]= mcm_SM30cm_avg(SM_ina,2);   
                SM(i).SM30b = NaN.*ones(size(SM_ina,1),1);    
                SM(i).flag_b = NaN.*ones(size(SM_ina,1),1);
                SM(i).SM30c = NaN.*ones(size(SM_ina,1),1);
                SM(i).flag_c = NaN.*ones(size(SM_ina,1),1);

            otherwise
                SM_ina = [SM(i).SM5a, SM(i).SM10a, SM(i).SM20a, SM(i).SM50a];
                SM_inb = [SM(i).SM5b, SM(i).SM10b, SM(i).SM20b, SM(i).SM50b];
                SM_inc = [SM(i).SM5c, SM(i).SM10c, SM(i).SM20c, SM(i).SM50c];
                
   [SM(i).SM30a SM(i).flag_a]= mcm_SM30cm_avg(SM_ina,1);
   [SM(i).SM30b SM(i).flag_b]= mcm_SM30cm_avg(SM_inb,1);
   [SM(i).SM30c SM(i).flag_c]= mcm_SM30cm_avg(SM_inc,1);
   
        end
        SM(i).SM30a = mcm_adjust_SM(site, 'A', SM(i).SM30a, SM(i).flag_a);
        SM(i).SM30b = mcm_adjust_SM(site, 'B', SM(i).SM30b, SM(i).flag_b);
        SM(i).SM30c = mcm_adjust_SM(site, 'C', SM(i).SM30c, SM(i).flag_c);
end
%%% Use SMfill to fill gaps in SM values:
SMfill = mcm_fill_SM(site_labels, SM);


%% Step 4: If Pressure has NaNs, just fill it with Pressure from TP39, then with Pressure from TP74:
for i = 1:1:num_sites
    ind_ok = find(isnan(data(i).APR)==1);
    data(i).APR(ind_ok,1) = data(1).APR(ind_ok,1); % fill with TP39 if needed
    ind_ok2 = find(isnan(data(i).APR)==1);
    data(i).APR(ind_ok2,1) = data(2).APR(ind_ok2,1); % fill with TP74 if needed
    ind_ok3 = find(isnan(data(i).APR)==1);
    data(i).APR(ind_ok3,1) = data(3).APR(ind_ok3,1); % fill with TP02 if needed
    ind_ok4 = find(isnan(data(i).APR)==1);
    data(i).APR(ind_ok4,1) = data(4).APR(ind_ok4,1); % fill with TPD if needed
    ind_ok5 = find(isnan(data(i).APR)==1);
    data(i).APR(ind_ok5,1) = 101; % fill with 99 if there are still NaNs
end    

%% Put all variables into their proper site-label matricies:

for i = 1:1:num_sites
    site = site_labels{i,1};
    eval([site '=[' site ' data(i).APR Ts(i).Ts2 Ts(i).Ts5 Ts(i).Ts10 Ts(i).Ts20 Ts(i).Ts50 Ts(i).Ts100 SM(i).SM30a SM(i).SM30b SM(i).SM30c SMfill(i).SM30a SMfill(i).SM30b SMfill(i).SM30c data(i).Rn data(i).SW];']);
end

%% Fill Ts2 and Ts5 gaps (1 or 2 points) with linear interpolation.
for i = 1:1:num_sites
    site = site_labels{i,1};
    %%% Linear interpolation first (max 2 consecutive data points)
    eval([ '[' site '_Ts2_pred] = jjb_interp_gap2(' site '(:,6),2);']);
    eval([ '[' site '_Ts5_pred] = jjb_interp_gap2(' site '(:,7),2);']);
    ind_Ts2 = eval(['find(isnan(' site '(:,6))==1);']);
    ind_Ts5 = eval(['find(isnan(' site '(:,7))==1);']);
    
    eval ([site '(ind_Ts2,6) = ' site '_Ts2_pred(ind_Ts2,1);']);
    eval ([site '(ind_Ts5,7) = ' site '_Ts5_pred(ind_Ts5,1);']);
    clear ind_Ts2 ind_Ts5 *_Ts2_pred *_Ts5_pred;

    %%% Testing
%     switch site
%         case 'TP02'
%     
%     figure(99);clf;
%     plot(eval([site '_Ts2_pred']),'r');hold on;
%     plot(eval([site '_filled(:,6)']),'b');
%     end
   %%%%%
end



%% Fill Ta, RH, PAR, WS using regression between sites:
%%% I am still not decided whether to parameterize these comparisons on one
%%% year of data, or to load in all years to get a better fit...

for i = 1:1:num_sites
site = site_labels{i,1};

    eval([site '_filled = ' site ';'])
%         TP39_filled = TP39;
%         TP74_filled = TP74;
%         TP89_filled = TP89;
%         TP02_filled = TP02;
end   

% We are only filling the first 4 variables in this method:
fill_cols = [1:1:4 6:7]';

for fill_loop = 1:1:length(fill_cols)
    tic; 
    disp(['Now filling variable: ' varnames{fill_cols(fill_loop,1)}]);
    left_side = '';
    right_side = '';
    for i = 1:1:num_sites
site = site_labels{i,1};
% left_side = [left_side site '_filled(:,fill_cols(fill_loop,1)) ']; 
right_side = [right_side site '(:,fill_cols(fill_loop,1)) '];
  
    end
    
    eval(['data_in = [' right_side '];']);
    try
        data_filled = mcm_fillvars(data_in);
    catch
        disp(['Something went wrong when filling variable: ' varnames{fill_cols(fill_loop,1)}]);
        s1 = input('Press enter to continue with next variable, or enter <q> to quit ');
        if strcmpi(s1,'q')==1
            return;
        else
            disp('Continuing on... but you''ll want to check in on that problem...');
            data_filled = data_in;
%             continue
        end
    end
    
    for i = 1:1:num_sites
site = site_labels{i,1};
eval([site '_filled(:,' num2str(fill_cols(fill_loop,1)) ') = data_filled(:,' num2str(i) ');']);
    end
    clear data_filled;
    
%     eval(['[' left_side '] = mcm_fillvars(' right_side ');'])
    
%     if year >= 2009
%         
%     else 
%     [TP39_filled(:,fill_cols(fill_loop,1)) TP74_filled(:,fill_cols(fill_loop,1)) TP89_filled(:,fill_cols(fill_loop,1)) TP02_filled(:,fill_cols(fill_loop,1))] = mcm_fillvars(TP39(:,fill_cols(fill_loop,1)), TP74(:,fill_cols(fill_loop,1)), TP89(:,fill_cols(fill_loop,1)), TP02(:,fill_cols(fill_loop,1)));
%     end
    t = toc;
    disp(['Variable ' varnames{fill_cols(fill_loop,1)} ' finished in ' num2str(t) ' seconds']);

end

%% Final adjustments and calculations
% 1. Clean up RH values (0 if <0, 100 if > 100)
% 2. Clean up PAR (0 if <25)
% 3. Calculate VPD from Ta (col 1) and RH (col 2) [Added 20180314]
    for i = 1:1:num_sites
site = site_labels{i,1};
eval([site '_filled(' site '_filled(:,2)>100,2) = 100; ' site '_filled(' site '_filled(:,2)<0,2) = 0;']); %% Clean up RH values (0 if <0, 100 if > 100)
eval([site '_filled(' site '_filled(:,3)<25,3) = 0;']); % Make all PAR <25 = 0;
eval([site '_filled(:,18) = VPD_calc(' site '_filled(:,2),' site '_filled(:,1),2);']); % Calculate VPD in hPa.
    end

% 
% TP39_filled(TP39_filled(:,2)>100,2) = 100; TP39_filled(TP39_filled(:,2)<0,2) = 0;
% TP74_filled(TP74_filled(:,2)>100,2) = 100; TP74_filled(TP74_filled(:,2)<0,2) = 0;
% TP89_filled(TP89_filled(:,2)>100,2) = 100; TP89_filled(TP89_filled(:,2)<0,2) = 0;
% TP02_filled(TP02_filled(:,2)>100,2) = 100; TP02_filled(TP02_filled(:,2)<0,2) = 0;

%% We can try to fill Ts within sites by a regression with air temperature:
 % loops through Ts5 and Ts2
%  TP02_Ts2_pred = [];
%  TP02_filled = [];
 for i = 1:1:num_sites
    site = site_labels{i,1};
    

    %%% Now fill the rest using regression with Ta
    eval([ '[' site '_Ts2_px_y ' site '_Ts2_pred] = Ts_fit(' site '_filled(:,1), ' site '_filled(:,6),''pw'');']);
    eval([ '[' site '_Ts5_px_y ' site '_Ts5_pred] = Ts_fit(' site '_filled(:,1), ' site '_filled(:,7),''pw'');']);
       
    ind_Ts2 = eval(['find(isnan(' site '_filled(:,6))==1);']);
    ind_Ts5 = eval(['find(isnan(' site '_filled(:,7))==1);']);
    
    eval ([site '_filled(ind_Ts2,6) = ' site '_Ts2_pred(ind_Ts2,1);']);
    eval ([site '_filled(ind_Ts5,7) = ' site '_Ts5_pred(ind_Ts5,1);']);
    
    clear ind_Ts2 ind_Ts5;
    
 end

    
 %% Added Jan 25, 2011 
 %%% Fill in Net Radiation (using a neural network and filled met
 %%% variables - Ta, RH, PAR, WS), and SW down (Using linear relationship with PAR data):
 %%% Step 7(ish): Fill Rn (for all) and SW_down (for TP39):
% 1. Rn
for i = 1:1:num_sites
    site = site_labels{i,1};
    inputs = eval([site '_filled(:,[1 4 2 3]);' ]);
    ind_sim_all = find(~isnan(prod(inputs,2)));
    sim_inputs = inputs(ind_sim_all,:);
    net_to_use = eval(['data(i).net.nnet_' site ';']);
    [Y,Pf,Af,E,perf] = sim(net_to_use.net,sim_inputs');
    Rn_pred = NaN.*ones(size(data(i).Rn,1),1);
    Rn_pred(1:length(Y)) = Y';
    data(i).Rn(isnan(data(i).Rn),1) = Rn_pred(isnan(data(i).Rn),1);
    clear ind_sim_all sim_inputs net_to_use Y Pf Af E perf Rn_pred inputs;
    
    if strcmp(site,'TP39')==1 || strcmp(site,'TPD')==1
        PAR = eval([site '_filled(:,3);']);
        ind_good_PAR = find(~isnan(PAR.*data(i).SW));
        p = polyfit(PAR(ind_good_PAR), data(i).SW(ind_good_PAR),1);
        pred_SW = polyval(p,PAR);
        data(i).SW(isnan(data(i).SW),1) = pred_SW(isnan(data(i).SW),1);
        
        clear PAR ind_good_PAR p pred_SW;
    else
        data(i).SW = NaN.*ones(length(data(i).Rn),1);
    end
    eval([site '_filled(:,16:17) = [data(i).Rn data(i).SW];']);
end
 
 
% %%%% Update the file: 
% for i = 1:1:num_sites
%     site = site_labels{i,1};
% eval([site '_filled =[' site '_filled data(i).Rn data(i).SW];']);    
% end 



 %% Plot data for each site and Determine if there's any data still missing:
% varnames(1,1) = cellstr('Ta'); varnames(2,1) = cellstr('RH'); varnames(3,1) = cellstr('PAR');
% varnames(4,1) = cellstr('WS'); varnames(5,1) = cellstr('APR'); varnames(6,1) = cellstr('Ts2');
% varnames(7,1) = cellstr('Ts5'); varnames(8,1) = cellstr('Ts10'); varnames(9,1) = cellstr('Ts20'); 
% varnames(10,1) = cellstr('Ts50'); varnames(11,1) = cellstr('Ts100');
% varnames(12,1) = cellstr('SM_30a'); varnames(13,1) = cellstr('SM_30b');
% varnames(14,1) = cellstr('SM_30a_filled'); varnames(15,1) = cellstr('SM_30b_filled');
% varnames(16,1) = cellstr('Rn'); varnames(17,1) = cellstr('SW_down');

% varnames(12,1) = cellstr('SM5a'); varnames(13,1) = cellstr('SM5b');
% varnames(14,1) = cellstr('SM10a'); varnames(15,1) = cellstr('SM10b');
% varnames(16,1) = cellstr('SM20a'); varnames(17,1) = cellstr('SM20b');
plot_list = [(1:1:10) 16];
for i = 1:1:num_sites
    site = site_labels{i,1};
    figure('Name',site_labels{i,1},'NumberTitle','off'); clf;
    for j = 1:1:12
        subplot(4,3,j);
        if j < 12
            try eval (['plot(' site '_filled(:,plot_list(j)),''r'')']); hold on; catch; end
            try eval (['plot(' site '(:,plot_list(j)),''b'')']); catch; end
            try title(char(varnames(plot_list(j),1))); catch; end
        else % soil moisture
            eval (['plot(' site '_filled(:,j),''r'')']); hold on;
            eval (['plot(' site '_filled(:,j+1),''b'')']); hold on;
            legend('Pit A', 'Pit B');
            title(char(varnames(j,1)));
        end
        
        % find number of NaNs in each variable:
        nans(i,j) = eval (['length(find(isnan(' site '_filled(:,j))==1));']);
        
    end

end

%% Save the Final Data:
time_int = 30;
%%%% Create list of column names for meteo output:
col_names = {'YYYY';'MM';'DD';'JD';'hh';'mm';'ss'};
col_names = [col_names;labels]';
%%%% Create time vectors for meteo output:
YYYY = year_ctr.*ones(yr_length(year_ctr,time_int),1);
[MM, DD] = make_Mon_Day(year_ctr,time_int,2);
[hh, mm] = make_HH_MM(year_ctr,time_int,2);
JD = repmat(1:1:yr_length(year_ctr,1440),1440/time_int,1); JD = JD(:);
JD(1440/time_int:1440/time_int:length(JD)) = JD(1440/time_int:1440/time_int:length(JD))+1;
ss = zeros(size(YYYY));
for i = 1:1:num_sites
    site = site_labels{i,1};
    jjb_check_dirs([ls 'SiteData/' site '/MET-DATA/meteo/'],1);
master.data = eval([site '_filled']);
master.labels = labels;  
%%%% Write the filled data to met_filled_master
    jjb_check_dirs([save_path '/' site '/'],0);
    save([save_path '/' site '/' site '_met_filled_' yr_str '.mat'], 'master');
%%% Added 20180323 - Export daily meteo files to \SiteData\TPxx\MET-DATA\meteo                               \    
% Needs to be tab delimited, using format meteoDDMMYY.dat
% First, write the column headers:
fid_hdr = fopen([ls 'SiteData/' site '/MET-DATA/meteo/column_headers.dat'],'w');
fprintf(fid_hdr,'%s',sprintf('%s\t',col_names{:}));
fclose(fid_hdr);

    to_write = [YYYY MM DD JD hh mm ss master.data];
    for j = 1:48:yr_length(year_ctr,time_int)
        ind_start = j;
        ind_end = ind_start + 47;
        fid = fopen([ls 'SiteData/' site '/MET-DATA/meteo/meteo' num2str(DD(ind_start),'%02i') num2str(MM(ind_start),'%02i') num2str(YYYY(ind_start)-2000,'%02i') '.dat'],'w');
        fprintf(fid,'%s\n',sprintf('%s\t',col_names{:}));
        fclose(fid);

        tmp_write = to_write(ind_start:ind_end,:);
        dlmwrite([ls 'SiteData/' site '/MET-DATA/meteo/meteo' num2str(DD(ind_start),'%02i') num2str(MM(ind_start),'%02i') num2str(YYYY(ind_start)-2000,'%02i') '.dat'],tmp_write,'delimiter','\t','-append');
    end
    clear master to_write;
end

%%
if quickflag == 1
else
    junk = input('Press Enter to Continue to Next Year');
end
end
disp('done!');

if quickflag == 1
else
    mcm_start_mgmt;
end
end

function [data_out] = sf_load_from_master(year, data_in,var_name)
right_col = find(strcmp(data_in.labels(:,3),var_name)==1 & strcmp(data_in.labels(:,5),'Final_Cleaned')==1);
data_out = data_in.data(data_in.data(:,1) == year,right_col);
end
