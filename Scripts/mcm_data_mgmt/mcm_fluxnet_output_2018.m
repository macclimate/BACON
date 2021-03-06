function [] = mcm_fluxnet_output(year, site)
%%% mcm_fluxnet_output.m
% The purpose of this function is to create standardized outputs for each
% year and each site, which are formatted according to the ORNL and Global
% FLUXNET standard format.

%%% What this function does:
% 1. open master files
% 2. go through a pre-established list of desired variables (with orders inserted)
% 3. Read from column 13 (M)
% 4. calculate VPD given other inputs
% 5. calculate DOY (round down of dtime); dtime should start at 1
% 6. Tsdepths are 2 | 5 ; SWC depths are 5 | 10
% 7. Get CO2 height (from params.m)
% 8. Write all of these variables to a final output in the standard format.


if isempty(year)==1
    year = input('Enter Years to process, as integer (e.g. 2008) or sequence (e.g. 2003:2008): ');
end
if ischar(year)==1
    year = str2double(year);
end

[year_start, year_end] = jjb_checkyear(year);


% Declare paths:
[ls_dir, gdrive_loc] = addpath_loadstart;
out_dir =       [ls_dir 'Matlab/Data/Fluxnet/'];
master_dir =    [ls_dir 'Matlab/Data/Master_Files/'];
gdrive_dir = [gdrive_loc '03 - TPFS Data/Fluxnet/'];

% Check to make sure the target directory exists. Make one if it doesn't.
jjb_check_dirs([out_dir site],1);
jjb_check_dirs([gdrive_dir site],1);

site_info  = ...
    {'TP39', 'CA-TP4','1939 Plantation White Pine','Evergreen Needleleaf Forest (ENF)'; ...
    'TP74', 'CA-TP3', '1974 Plantation White Pine','Evergreen Needleleaf Forest (ENF)'; ...
    'TP89', 'CA-TP2', '1989 Plantation White Pine','Evergreen Needleleaf Forest (ENF)'; ...
    'TP02', 'CA-TP1', '2002 Plantation White Pine','Evergreen Needleleaf Forest (ENF)'; ...
    'TPD', 'CA-TPD',  'Deciduous Broadleaf' ,'Deciduous Broadleaf Forest (DBF)'; ...
    'TP39_sapflow', 'CA-TP4_sf','1939 Plantation White Pine','Evergreen Needleleaf Forest (ENF)'; ...
    'TP74_sapflow', 'CA-TP4_sf','1974 Plantation White Pine','Evergreen Needleleaf Forest (ENF)'; ...
    };

rightrow = find(strcmp(site,site_info(:,1))==1);
sitename_out = site_info{rightrow,2};   % Fluxnet site name
forest_desc = site_info{rightrow,3};    % forest description
eco_type = site_info{rightrow,4};       % ecosystem type

% vars_to_write_L1 = {'YEAR', 'YEAR';'GAP','GAP';'DTIME','DTIME';'DOY','DOY';'UST','m/s';'TA','deg C';'WD','deg';'WS','m/s';...
%     'NEE','umol/m2/s';'FC','umol/m2/s';'SFC','umol/m2/s';'H','W/m2';'SH','W/m2';'LE','W/m2';'SLE','W/m2';'FG','W/m2';...
%     'TS1','deg C';'TSdepth1','cm';'TS2','deg C';'TSdepth2','cm';'PREC','mm';'RH','%';'PRESS','kPa';'CO2','umol/mol';...
%     'VPD','kPa';'SWC1','%';'SWC2','%';'Rn','W/m2';'PAR','umol/m2/s';'Rg','W/m2';'Rgdif','W/m2';'PARout','umol/m2/s';...
%     'Rgout','W/m2';'H2O','mmol/mol';'RE','umol/m2/s';'GPP','umol/m2/s';'CO2top','umol/mol';'CO2height','m';...
%     'APAR','umol/m2/s';'PARdfif','umol/m2/s';'APARpct','%';'ZL','unitless';'SWC1b','%';'SWC2b','%';};                                                                                                                                                                                                                                                                                                                      

% vars_to_write_L2 = {'YEAR', 'YEAR';'GAP','GAP';'DTIME','DTIME';'DOY','DOY';'UST','m/s';'TA','deg C';'WD','deg';'WS','m/s';...
%     'NEE','umol/m2/s';'FC','umol/m2/s';'SFC','umol/m2/s';'H','W/m2';'SH','W/m2';'LE','W/m2';'SLE','W/m2';'FG','W/m2';...
%     'TS1','deg C';'TSdepth1','cm';'TS2','deg C';'TSdepth2','cm';'PREC','mm';'RH','%';'PRESS','kPa';'CO2','umol/mol';...
%     'VPD','kPa';'SWC1','%';'SWC2','%';'Rn','W/m2';'PAR','umol/m2/s';'Rg','W/m2';'Rgdif','W/m2';'PARout','umol/m2/s';...
%     'Rgout','W/m2';'H2O','mmol/mol';'RE','umol/m2/s';'GPP','umol/m2/s';'CO2top','umol/mol';'CO2height','m';...
%     'APAR','umol/m2/s';'PARdiff','umol/m2/s';'APARpct','%';'ZL','unitless';'SWC1b','%';'SWC2b','%';};                                                                                                                                                                                                                                                                                                                      

% Load data from the master file:
if exist([master_dir  site '/' site '_data_master.mat'], 'file')== 2
    disp('Loading master file.');
    load([master_dir  site '/' site '_data_master.mat']);
else
    disp('Cannot locate the master file.  Check path in mcm_fluxnet_output.m')
    return
end

%%% Create a list of variables to write to the final output file
%%%% NEED TO SWITCH TO COLUMN 14!!
var_list = master.labels(:,12);
var_list = strrep(var_list_tmp,'NaN','');
rows_to_write = find(cellfun('isempty',var_list(:,1))~=1);

%%% Build TIMESTAMP_START and TIMESTAMP_END
YYYY = master.data(:,strcmp(master.labels(:,1),'Year')==1);
MM = master.data(:,strcmp(master.labels(:,1),'Month')==1);
DD = master.data(:,strcmp(master.labels(:,1),'Day')==1); 
hh = master.data(:,strcmp(master.labels(:,1),'Hour')==1); 
mm = master.data(:,strcmp(master.labels(:,1),'Minute')==1); 
dv = [[YYYY(1),MM(1),DD(1),hh(1),0,0];[YYYY,MM,DD,hh,mm,zeros(length(YYYY),1)]]; %datevector
dstr = datestr(dv,'yyyymmddHHMM'); %datestring
TIMESTAMP_START=dstr(1:end-1,:);
TIMESTAMP_end=dstr(2:end,:);
clear dv dstr MM DD hh mm 
%% Do any corrections/adjustments that might be needed for this data:      
% 1. Convert snow depth to cm
col_snow = find(strncmp(var_list,'D_SNOW',6)==1);
    if ~isempty(r_snow)==1
        master.data(:,col_snow) = master.data(:,col_snow).*100;
    end
    
%% This will be inside of a yearly loop (in case multiple years are entered)
time_int = 30; % At this point, all output files are thirty minute interval
for j = year_start:1:year_end
    clear YYYY_label array_out;
    YYYY_label = num2str(j);
    disp(['Now Working on Site: ' site ', Year: ' YYYY_label '.'])
    % Retrieve site data from params.m
%     site_loc = params(j, site, 'Location'); % lat | long | elev

    %%% Open/create the output file:
    fid_out = fopen([out_dir site '/' sitename_out '_' num2str(j) '_L2.csv'],'w');
%     fid_dp = fopen([out_dir 'data_policy.txt'],'r');
    %%% Write the preamble:
%     fprintf(fid_out,'%s\n',['Sitename: Ontario Turkey Point ' forest_desc ' Ontario CANADA']);
%     fprintf(fid_out,'%s\n',['Location: Latitude: ' num2str(site_loc(1)) ', Longitude: ' num2str(site_loc(2)) ', Elevation (masl): ' num2str(site_loc(3))]);
%     fprintf(fid_out,'%s\n',['Principal Investigator: Altaf Arain, arainm@mcmaster.ca']);
%     fprintf(fid_out,'%s\n',['Ecosystem type (IGBP): ' eco_type]);
%     fprintf(fid_out,'%s\n',['File creation date:  ' datestr(now,'ddmmmyyyy') '. Data reported in Local (Eastern) Standard Time']);
%     fprintf(fid_out,'%s\n',['Data reported in Local (Eastern) Standard Time']);
%     eof = 0;
%     while eof == 0
%         tline = fgetl(fid_dp);
%         fprintf(fid_out,'%s\n',tline);
%         eof = feof(fid_dp);
%     end
    
    % Write the header - variable names:
    for k = 1:1:size(rows_to_write,1)-1
        fprintf(fid_out,'%s',[var_list{rows_to_write(k,1)} ',']);
    end
    fprintf(fid_out,'%s\n',[var_list{rows_to_write(k+1,1)}]);
    
%     % Write the header - units:
%     for k = 1:1:size(vars_to_write_L2,1)-1
%         fprintf(fid_out,'%s',[vars_to_write_L2{k,2} ',']);
%     end
%     fprintf(fid_out,'%s\n',[vars_to_write_L2{k+1,2}]);
    
    % Close the files:
    fclose(fid_out);% fclose(fid_dp);
    
    %%%%%%%%%%%% Part 2: Write the data to an array %%%%%%%%%%%%%%%
    % Make the blank output file. We know we need to add in two extra
    % columns for TIMESTAMP_START and TIMESTAMP_END
    array_out = -9999.*ones(yr_length(j,time_int),size(rows_to_write,1)+2);
    
    % Pull out the current year's data from the master file (This data is
    % in UTC). Now, rearrange this so that it's in Local Standard time (i.e. EST).
    % We need to add 10 data points from the start of next year to the end
    % of the year of interest.
    ind1 = find(master.data(:,1)==j);
    ind2 = find(master.data(:,1)==j+1);
    if isempty(ind2)
    tmp_data = [master.data(ind1(11:end),:);NaN.*ones(10,size(master.data,2))];
    else
    tmp_data = [master.data(ind1(11:end),:);master.data(ind2(1:10),:)];
    end
    % Retrieve site data from params.m
    heights = params(j, site, 'Heights'); % zmeas | ztree
    
    for k = 1:1:size(vars_to_write_L2,1)
        rrow = find(strcmp(master.labels(:,13),vars_to_write_L2{k,1})==1);
        if ~isempty(rrow)
            array_out(:,k) = tmp_data(:,rrow);
        else
            switch vars_to_write_L2{k,1}
                case 'TSdepth1'
                    array_out(:,k) = 2;
                case 'TSdepth2'
                    array_out(:,k) = 5;
                case 'CO2height'
                    array_out(:,k) = heights(:,1);
                case 'CO2top'
                    array_out(:,k) = array_out(:,strcmp(vars_to_write_L2(:,1),'CO2')==1);
                    
                case 'VPD'
                    array_out(:,k) = VPD_calc(array_out(:,strcmp(vars_to_write_L2(:,1),'RH')==1), array_out(:,strcmp(vars_to_write_L2(:,1),'TA')==1));
                otherwise
                    disp(['Could not find variable ' vars_to_write_L2{k,1} ' in the master file. Column will be -6999.']);
            end
        end
        % Replace NaNs with -6999
        array_out(isnan(array_out(:,k)),k) = -6999;
        clear rrow
    end
    %%% Paste date-related fields into the final array:
    array_out(:,1)=j; % YEAR 
    array_out(:,2) = 0; %The 'GAP' variable is all zeros.
    % Make time vectors and write DOY and HHMM:
    [~, ~, ~, ~, dt, HHMM, ~, ~, JD] = jjb_maketimes(j, time_int);
    array_out(:,3) = dt;
    array_out(:,4) = JD;
    array_out(:,5) = HHMM;
    
    %%% Part 3: Append the array to the final output file:
    dlmwrite([out_dir site '/' sitename_out '_' num2str(j) '_L2.csv'],array_out,'delimiter',',','-append');
    
    % Write success message
    disp(['Completed. File located in ' out_dir site '/' sitename_out '_' num2str(j) '_L2.csv']);
    
    % Copy file to Google Drive
    stat = unix(['cp -vr ' out_dir site '/ "' gdrive_dir '"']);
    if stat ~=0
        disp('Could not copy files to Google Drive-synced folder. Check for problems');
    else
        disp(['Uploaded Master files to Google Drive-synced folder: ' gdrive_dir site]);
    end
end

