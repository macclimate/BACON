function [] = mcm_metfixer(year, site, data_type, auto_flag)
%% mcm_metfixer.m
%%% This function is designed to be run on data after being processed with
%%% mcm_metclean.  Currently, this function should be used only on data
%%% collected in 2008 or later.  This function gives the user a chance to
%%% make final, manual adjustments to the data, that may not be fixable
%%% with a simple threshold.
%%% Variables are loaded from /Cleaned3/ and saved in /Final_Cleaned/

%%% Usage: mcm_metfixer(year, site), where year is a number and site a
%%% string
% auto_flag = 0 runs in standard mode
% auto_flag = 1 runs in automated mode

% Created Mar 11, 2009 by JJB
% Revision History:
% Mar 12, 2009 - changed variables input_data and output to be the same
% size as the entire list of variables -- whether 30 min variables or not.
% This preserves the numbering of the columns of variables to be consistent

%%%%%%%%%%%%%%%%%
if nargin == 1
    site = year;
    year = [];
elseif nargin == 2
    data_type = [];
    auto_flag = 0;
elseif nargin == 3
    auto_flag = 0;    
end
if auto_flag == 1
        skipall_flag = 1;
    else
        skipall_flag = 0;
end

[year_start year_end] = jjb_checkyear(year);

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
%%% Added Jan 24, 2011 by JJB.
%%% Want to include data_type in the program, so we can process such things
%%% are trenched, sapflow, OTT, etc data.
if isempty(data_type) == 1
    data_type = 'met';
end

%%%%%%%%%%%%%%%%%
%%% Check if site is entered as string -- if not, convert it.
if ischar(site) == false
    site = num2str(site);
end
%%%%%%%%%%%%%%%%
%%% Set a flag that tells the program whether or not to do tasks associated
%%% with main met sites: '1' means that extra stuff will be processed, 0
%%% means that it won't be:

% if strcmp(data_type, 'met')==1
switch data_type
    case {'met','WX','TP_PPT'}
        switch site
            case {'TP_PPT','MCM_WX'}
                proc_flag = 0;
            otherwise
                proc_flag = 1;
        end
    otherwise
        proc_flag = 0;
        %%% For sapflow, OTT, trenched, we need to change site to include the
        %%% data_type.
        site = [site '_' data_type];
end


%%%%%%%%%%%%%%%%%%%%%




%%%%%% Declare Paths:
loadstart = addpath_loadstart;
%%% Header Path
% hdr_path = [loadstart 'Matlab/Data/Met/Raw1/Docs/'];
hdr_path = [loadstart 'Matlab/Config/Met/Organizing-Header_OutputTemplate/']; % Changed 01-May-2012
%%% Load Path
load_path = [loadstart 'Matlab/Data/Met/Cleaned3/' site '/'];%[loadstart 'Matlab/Data/Met/Cleaned3/' site '/Column/30min/' site '_' year '.'];
%%% Save Path
output_path = [loadstart 'Matlab/Data/Met/Final_Cleaned/' site '/'];
jjb_check_dirs(output_path,0);
header = jjb_hdr_read([hdr_path site '_OutputTemplate.csv'], ',', 3);
%%% Path for bad data tracker (used by jjb_remove_data):
% tracker_path = [loadstart 'Matlab/Data/Met/Final_Cleaned/Docs/bad_data_trackers/'];
tracker_path = [loadstart 'Matlab/Config/Met/Cleaning-BadDataTrackers/']; % Changed 01-May-2012

%%% Take information from columns of the header file
%%% Column vector number
col_num = str2num(char(header(:,1)));
%%% Title of variable
var_names = char(header(:,2));
%%% Minute intervals
header_min = str2num(char(header(:,3)));
%%% Use minute intervals to find 30-min variables onlya
switch site
    case 'MCM_WX'
        vars30 = find(header_min == 15);
    otherwise
        vars30 = find(header_min == 30);
end
%%% Create list of extensions needed to load all of these files
vars30_ext = create_label(col_num(vars30),3);
%%% Create list of titles that are 30-minute variables:
% names30 = var_names(vars30,:);
names30 = header(vars30,2);

names30_str = char(names30);


%% Main Loop
for year_ctr = year_start:1:year_end
    close all
    RH_max = [];
    yr_str = num2str(year_ctr);
    disp(['Working on year ' yr_str '.']);
    
    if isleapyear(year_ctr) == 1
        len_yr = 17568;
    else
        len_yr = 17520;
    end
    switch site
        case 'MCM_WX'
            len_yr = len_yr*2;
        otherwise
    end
    
    input_data = NaN.*ones(len_yr,length(vars30)); % will be filled by loaded variables
    output = input_data;                           % will be final cleaned variables
    
    % Column numbers, names and string of names for the final variables:
    output_cols = (1:1:length(vars30))';
    output_names = names30;
    output_names_str = char(output_names);
    
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Step 1: Cycle through all variables so the investigator can look at the
    %%% data closely
    
    j = 1;
    switch skipall_flag
        case 1
            resp3 = 'n';
        otherwise
            commandwindow;
            resp3 = input('Do you want to scroll through variables before fixing? <y/n> ', 's');
    end
    if strcmpi(resp3,'y') == 1
        scrollflag = 1;
    else
        scrollflag = 0;
    end
    
    while j <= length(vars30)
        try
            temp_var = load([load_path site '_' yr_str '.' vars30_ext(j,:)]);
        catch
            temp_var = NaN.*ones(len_yr,1);
            disp(['unable to locate variable: ' var_names(vars30(j),:)]);
        end
        
        input_data(:,j) = temp_var;
        output(:,j) = temp_var;
        
        switch scrollflag
            case 1
                f1=figure(1); set(f1,'WindowStyle','docked');
                clf;
                plot(temp_var,'b.-');
                %     hold on;
                title([var_names(vars30(j),:) ', column no: ' num2str(j)]);
                grid on;
                
                
                %% Gives the user a chance to change the thresholds
                response = input('Press enter to move forward, enter "1" to move backward: ', 's');
                
                if isempty(response)==1
                    j = j+1;
                    
                elseif strcmp(response,'1')==1 && j > 1;
                    j = j-1;
                else
                    j = 1;
                end
            case 0
                j = j+1;
        end
        
    end
    clear j response accept
    figure(1);
    text(0,0,'Make changes in program now (if necessary) -exit script')
    
    if proc_flag == 1
        %%@@@@@@@@@@@@@@@@@@ SOIL PROBES @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        %%% Plot Soil Temperature and Moisture data from each pit to make sure that
        %%% all data is in the right place:
        
        % A. Soil Temperature:
        %Check to see where soil temperature data starts:
        Ts_cols_A = find(strncmpi(names30(:,1),'SoilTemp_A',10)==1);
        Ts_cols_B = find(strncmpi(names30(:,1),'SoilTemp_B',10)==1);
        TsA_labels = char(names30(Ts_cols_A,1));
        TsB_labels = char(names30(Ts_cols_B,1));
        clrs = colormap(lines(7));
        
        % Uncorrected
        figure(2);clf;
        for i = 1:1:length(Ts_cols_A)
            subplot(2,1,1)
            hTsA(i) = plot(input_data(:,Ts_cols_A(i)),'Color',clrs(i,:)); hold on;
        end
        legend(hTsA,TsA_labels(:,12:end))
        title('Pit A - Temperatures -- uncorrected')
        
        for i = 1:1:length(Ts_cols_B)
            subplot(2,1,2)
            hTsB(i) = plot(input_data(:,Ts_cols_B(i)),'Color',clrs(i,:)); hold on;
        end
        % legend(hTsB,TsB_labels(:,12:end))
        % Current Error at Line 240 so commented out
        title('Pit B - Temperatures -- uncorrected')
        
       
        % B. Soil Moisture:
        SM_cols_A = find(strncmpi(names30(:,1),'SM_A',4)==1);
        SM_cols_B = find(strncmpi(names30(:,1),'SM_B',4)==1);
        SMA_labels = char(names30(SM_cols_A,1));
        SMB_labels = char(names30(SM_cols_B,1));
        
        figure(3);clf;
        
        for i = 1:1:length(SM_cols_A)
            subplot(2,1,1)
            hSMA(i) = plot(input_data(:,SM_cols_A(i)),'Color',clrs(i,:)); hold on;
        end
        legend(hSMA,SMA_labels(:,6:end))
        title('Pit A - Moisture -- uncorrected')
        
        for i = 1:1:length(SM_cols_B)
            subplot(2,1,2)
            hSMB(i) = plot(input_data(:,SM_cols_B(i)),'Color',clrs(i,:)); hold on;
        end
%         legend(hSMB,SMB_labels(:,6:end))
        try legend(hSMB,SMB_labels(:,6:end)); catch; end

        % Same as Line 240 - not working
        title('Pit B - Moisture -- uncorrected')
    end
    
    %% @@@@@@@@@@@@@@@@@@@@ SPECIFIC CLEANS TO DATA @@@@@@@@@@@@@@@@@@@@@@@@@@@
    %%% Step 2: Specific Cleans to the Data
    
    switch site
        case 'MCM_WX'
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%% MCM_WX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            switch yr_str
                case '2008'
                case '2009'
                case '2010'
                    
                case '2011'
                case '2012'
                case '2013'
                case '2014'
                case '2015'
                    output(4922:5070,16) = NaN;
                case '2016'
                case '2017'
                case '2018'
            end
        case 'TP39_OTT'
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%% TP39_OTT %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            switch yr_str
                case '2010'
                    output([3737 3775:3776 ],2:3) = NaN;
                case '2011'
                    output([8211 8266],4) = NaN;
                case '2012'
                case '2013'
                    % Bad offset data (missing)
                    output(4742:4745,1) = NaN;
                case '2014'
                case '2015'
                case '2016'   
                case '2021'
                case '2023' %EAR NS
                    output([4830:4899 6483:6613 7008:7015 7275:7319 7949:8206 11293:11552],3) = NaN;
                   
            end
            %%% Convert The OTT reading to a WT depth:
            WT_Depth = 8.53 - output(:,output_cols(strcmp(output_names,'Water_Height')==1));
            %%% Save the Water Table Depth Data to the /Calculated4 directory:
            jjb_check_dirs([loadstart 'Matlab/Data/Met/Calculated4/' site '/'],0);
            save([loadstart 'Matlab/Data/Met/Calculated4/' site '/' site '_' yr_str '.WT_Depth'],'WT_Depth','-ASCII');
            %             save([output_path site '_' yr_str '.WT_Depth'],'WT_Depth','-ASCII');
            figure('Name','WT Depth, m below sfc');
            plot(WT_Depth);
            clear WT_Depth;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'TP39_trenched'
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%% TP39_trenched %%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            switch yr_str
                case '2009'
                    % remove bad points:
                    output([5987:5988 6374:6377],[4 5]) = NaN;
                    output(5987:6377,[6 7]) = NaN;
                    output( 1:11069, [10:14]) = NaN;
                case '2010'
                    output(3981,[12:13]) = NaN;
                    output(4351,15:16) = NaN;
                case '2011'
                case '2012'
                case '2013'
                    % Inactive sensors
                    output(:,[5 7 9:14 18:22]) = NaN;
                    
                case '2014'
                    % Poorly functioning sensors
                    output(:,[18 19 20 21]) = NaN;
                    output(13869,3:4) = NaN;
                    output(16518,[8 15]) = NaN;
                    % Inactive sensors
                    output(:,[22]) = NaN;
                case '2015'
                    % Bad points SM_DR_50cm
                    output([6366:6569 14431:end],4) = NaN;
                    % Bad points SM_DR2_2_0cm
                    output([11764:12203],15) = NaN;
                case '2016'
                    % TS Tr 20cm
                    output([1677 9837],3) = NaN;
                    % SMDR 100cm
                    output([7926:7929 7950 7956:8151 8172:8249 8471:8669 8699:8706 ...
                        8789:9166 9191:9195 9222:9239 9369:9562 10132:10144 13273:13283 17333],6) = NaN;
                    % SMTR 0-30cm
                    output([8003 8473:8553 8811:9166 9480:9492 11992:11994 12032:12047 12075:12096 12129:12143 17333],8) = NaN;
                    % SMDR 2 20cm
                    output([1672 1963 5024 6504 7155:8249 8490:9765 9999:10281 10562:12520],15) = NaN;
                    % SMDR 2 50cm
                    output([1670 1816 1963 8115 8471:8669 8696:8714 8785:9562 17333],16) = NaN;
                    % SMDR 2 5cm
                    output([8242 8471:8669 8790:9165 9308:9369 9455:9564 10272],17) = NaN;
                case '2017'
                     % Ts DR5cm, TR5cm & Tr20cm
                    output([8270 10658 10693:10697 10733 10805 10970 13819 14166 14660:14726 15465:15536 15565:15582 15605 15606 16272:16275 16303:16329 16868 16878 16879 16890 16929 16966 17032 17123:17125 17143 17447],[1:3]) = NaN;
                    % SMDR 2 20cm
                    output([8105:10000 13819],15) = NaN;
                                        
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'TP39_sapflow'
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%% TP39_sapflow %%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            switch yr_str
                case '2008'
                case '2009'
                    % manual fixes to dt data:
                    ind_bad = [11065:11115 13835:13846 14949:14950 16472:16475 4805:4806 10559:10600 2815:3051];
                    output(ind_bad,3) = NaN; %  dt sensor 1
                    ind_bad = [11065:11115 14955:14957 4805:4807 8562:8563 9917:9919 13839:13846 10560:10595 14949:14950 16473:16474];
                    output(ind_bad,4) = NaN;
                    ind_bad = [11065:11115 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16472:16474 17405:17520];
                    output(ind_bad,5) = NaN;
                    ind_bad = [11065:11115 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 3084:3107 2814:2816    ];
                    output(ind_bad,6) = NaN;
                    ind_bad = [11065:11115 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474];
                    output(ind_bad,7) = NaN; %  dt sensor 5
                    ind_bad = [11065:11115 14956:14957 10560:10595 4805:4807 8562:8564 13838:13846 14949:14950 16473:16474 6369:6371 17405:17520 4110:4132];
                    output(ind_bad,8) = NaN;
                    ind_bad = [11065:11115 14956:14957 10560:10595 4805:4807 8562:8564 13838:13846 14949:14950 16473:16474 6369:6373 9917:9919];
                    output(ind_bad,9) = NaN;
                    ind_bad = [11065:11115 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 9917:9919 13844:13875];
                    output(ind_bad,10) = NaN;
                    ind_bad = [11065:11115 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 10556:10593];
                    output(ind_bad,11) = NaN;
                    ind_bad = [11065:11115 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 10556:10593];
                    output(ind_bad,12) = NaN;%  dt sensor 10
                    ind_bad = [11065:11115 14956:14957 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 13844:13846 9917:9919];
                    output(ind_bad,13) = NaN;
                    ind_bad = [11065:11115 14956:14957 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 13844:13846 9917:9919 2772:3055];
                    output(ind_bad,14) = NaN;
                    ind_bad = [11065:11115 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 13845:13846 9917:9919 11376 11392];
                    output(ind_bad,15) = NaN;
                    ind_bad = [11065:11115 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 13845:13846 9917:9919 11748:11760 13085:13110 11376];
                    output(ind_bad,16) = NaN;
                    ind_bad = [11065:11115 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 13845:13846 9917:9919 11745:11766 13085:13106 14912:14926 11376];
                    output(ind_bad,17) = NaN;%  dt sensor 15
                    ind_bad = [11065:11115 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 13845:13846 9917:9919 11748:11759 13088:13103 14048:14060 11376];
                    output(ind_bad,18) = NaN;
                    ind_bad = [11065:11115 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 13845:13846 9917:9919 11748:11766 13088:13106 14912:14924 11376];
                    output(ind_bad,19) = NaN;
                    ind_bad = [11065:11115 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 13845:13846 9917:9919 11748:11760 13085:13105 14915:14924 11376];
                    output(ind_bad,20) = NaN;
                    ind_bad = [11065:11115 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 13845:13846 9917:9919 11367:11460 11745:11759 13100:13104 14915:14925 11376];
                    output(ind_bad,21) = NaN;
                    ind_bad = [11065:11115 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 13844:13846 9917:9919];
                    output(ind_bad,22) = NaN;%  dt sensor 20
                    output([11065:11115 4797],23) = NaN;
                    ind_bad = [11065:11115 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 13845:13846 9917:9919 1:4115 6380:6391];
                    output(ind_bad,24) = NaN;
                    ind_bad = [11065:11115 11065:11115 10560:10595 4805:4807 8562:8564 13838:13840 14949:14950 16473:16474 13845:13846 9917:9919 1:6391];
                    output(ind_bad,25) = NaN;
                    output(11065:11115,26) = NaN;%  dt sensor 24
                    clear ind_bad;
                    
                    
                case '2010'
                    output([6004 6005 15375 16602 16607],3) = NaN;
                    output([6004 6005 8962:8981 9438:9455 15375 16607],4) = NaN;
                    output([6004 6005 15375 16602 16607],5) = NaN;
                    output([6004 6005 7423:7796 15375 16602 16607],6) = NaN;
                    output([6004 6005 15375 16602 16607],7) = NaN;
                    output([4598 6014 9438 16607],10) = NaN;
                    output([6004 6005 9438 15375 16602 16607],11) = NaN;
                    output([6004 6005 15375 16602 16607],12) = NaN;
                    output([6004 6005 15375 16602 16607],13) = NaN;
                    output([6004 6005 15375 16602 16607],14) = NaN;
                    output([6004 6005 9438:9442 15375 16602 16607],15) = NaN;
                    output([6004 6005 6533:6553 8312 15375 16602 16607],16) = NaN;
                    output([6004 6005 6533:6553 8312 15375 16602 16607],17) = NaN;
                    output([6004 6005 6533:6553 8312 15375 16602 16607],18) = NaN;
                    output([6004 6005 6533:6553 8312 15375 16607],19) = NaN;
                    output([6004 6005 6533:6553 8312 15375 16602 16607],20) = NaN;
                    output([6004 6005 6533:6553 8312 15375 16602 16607],21) = NaN;
                    output([6004 6005 15375 16602 16607],22) = NaN;
                    output([1152:1351],84) = NaN;
                    output([2826:7256],85) = NaN;
                    output([6004 6005 15375 16602 16607],107) = NaN;
                    output([6004 6005 15375 16602 16607],108) = NaN;
                    output([4598 6004 6005 6014 15375 16602 16607],110) = NaN;
                    output([4598 6004 6005 15375 16602 16607],111) = NaN;
                    output([4598 6004 6005 15375 16602 16607],112) = NaN;
                    
                case '2011'
                    output([3911:3913 5662 7084],3) = NaN;
                    output([3911:3913 5662 7084],4) = NaN;
                    output([3911:3913 5662 7084 8265],5) = NaN;
                    output([3911:3913 4347:4358 5662 7084],6) = NaN;
                    output([3911:3913 5662 7084],7) = NaN;
                    output([3911:3913 4172 5078:5080 5198:5403 5662 5935:5951 7084 7961:9927],10) = NaN;
                    output([3911:3913 4172 5662 7084],11) = NaN;
                    output([3911:3913 4172 5662 7084],12) = NaN;
                    output([3911:3913 5662 7084],13) = NaN;
                    output([3911:3913 5662 7084 7980:8061],14) = NaN;
                    output([3911:3913 5662 7084],15) = NaN;
                    output([3911:3913 5662 7084],16) = NaN;
                    output([3911:3913 5662 7084],17) = NaN;
                    output([3911:3913 4169:4178 5662 7084],18) = NaN;
                    output([3911:3913 4169 5662 7084],19) = NaN;
                    output([3911:3913 5662 7084 8247:8289 9678:9819],20) = NaN;
                    output([3911:3913 5662 7084],21) = NaN;
                    output([3911:3913 5662 7084 8265],22) = NaN;
                    output([5240:6121],85) = NaN;
                    output([9803:9805],86) = NaN;
                    output([3911:3913 5662 6317 7084 8266],107) = NaN;
                    output([3911:3913 4172 5662 7084 8266],108) = NaN;
                    output([3911:3913 5662 6317 7084 8265:8266],110) = NaN;
                    output([3911:3913 5662 6317 7084],111) = NaN;
                    output([3911:3913 5662 6317 7084 8265:8266],112) = NaN;
                    output(4171:4172,[3:27 111:113]) = NaN;
                case '2012'
                    output(:,16) = NaN;
                case '2013'
                    % Bad points across sapflow data
                    output([1320:1325 1723 6137 8565 8570 9602:9603 12649 13610 15857:15860 17053:17054],:) = NaN;
                    % Inactive sensors (#2,#4,#6,#7,#8,#21,#22avg,#23,#24avg,#25,dr23)
                    output(:,[4 6 8 9 10 23:27 30 34 38:42 68 72 109]) = NaN;
                    % Bad sapref3avg
                    output(6134,[5 32]) = NaN;
                    % Bad sapref5avg
                    output(6134,[7 36]) = NaN;
                    % Non-functioning sensors (#11,#14,#16,#22max,#23hrmnmx,#24mm,#25m/mm,dr22avg)
                    output(:,[13 16 18 48 54 58 70 73 75 76 77 108]) = NaN;
                    % Incomplete data (#20)
                    output(:,[22 66]) = NaN;
                    % Incomplete tsdr5avg
                    output(:,87) = NaN;
                    % Inactive Ts Ref Tavg
                    output(:,90) = NaN;
                    % Bad SM DR50 avg data
                    output(3022:3025,95) = NaN;
                    % Non-functioning SM sensors (#7-12 avg)
                    output(:,101:106) = NaN;
                    
                    
                case '2014'
                    % Spikes in sensor 1
                    output([1316 1323 5651 6286 6296 13872 10451 13892 15000:17520],3) = NaN;
                    
                    % Missing past 15000 - no power
                    output([15000:17520],[3 5 6 7 11 12 14 15 16 17 18 19 20 21 22 ...
                        28 29 30 31 32 33 34 35 36 37 43 44 45 46 47 48 49:71 73:79 82 83:89 ...
                        91 95:100 107 110 111:117]) = NaN;
                    
                    % Spikes in all sensors
                    output([1323 13892],:) = NaN;
                    
                    % Bad sensors: # 11,14,20,22,24,25,Dr22-23 (+ others)
                    output(:,[4 6 8 9 10 13 16 22 23 24 25 26 27 30 34 38 39 40 ...
                        41 42 48 54 66 70 74 76 108 109]) = NaN;
                    
                    % Inactive moisture/temp sensors: #23,leaf_wet1-2, TsDr5avg,
                    % TsRefTavg, Ts10-12avg, SM7-12avg (+ others)
                    output(:,[8 9 10 13 23:26 39:42 72 80 81 87 90 92:94 101:106]) = NaN;
                    
                    
                    % Bad points in sapflow data (with dip):
                    % #12,13,15,18,19, Dr6-7 (+ others)
                    output([1316:1323 6286 11490:11492 13872 ],...
                        [5 11 12 14 15 17 20 21 28 32 44 46 50 52 56 62 64 111 112 113 115]) = NaN;
                    % Bad points in # 21 sapflow data (with dip):
                    output(1323,68) = NaN;
                    
                    % Missing data in SFref5avg
                    output(5649:12000,7) = NaN;
                    % Missing/poor data in Sap 5 max
                    output([1323 6000:17520],19) = NaN;
                    % Missing and poor data in #16 avg and max:
                    output([1:101 110 111 82:825 6000:10000],[18 58]) = NaN;
                    % Missing and poor data in # 17 avg and max
                    output([1323 6000:17520],[19 60]) = NaN;
                    % Missing and poor data in # 24 TapRoot avg
                    output([1323 6000:10000],[110]) = NaN;
                    % Spike in TsDr50 avg
                    output(14531,83) = NaN;
                    % Spike in TsRef50 avg
                    output([1367 13867 14384 14531 14066 10492 10716],[86 91]) = NaN;
                    % Spike in TsRef50 avg
                    output([14756],88:89) = NaN;
                    
                case '2015'
                    % *** Rachel found the following sensors to be working prior to April:
                    % 1,3,5,9,10,12,13,15,17,18,19
                    % After April, the following sensors are working:
                    % 1,3,9,10,12,13,15,18
                    
                    
                    % Spike in Sap1avg,
                    output([2918 7246 7249 9010 11745 14230 14487 15159],3) = NaN;
                    % Spike in Sap3avg
                    output([4973:4977 7246 7249 9010 11745 14230 14487 15159],5) = NaN;
                    % Inactive Sap sensors 4,6,8,16,17,19
                    output(1:end,[6,10,18,19,21,22]) = NaN;
                    
                    % Repeat this for min and max, refer to inventory for
                    % working and inactive sensors
                    
                    % Removed Sap19avg in April
                    output([4976:end],21) = NaN;
                    % Spike in Sap9avg
                    output([4977 7246 7249],11) = NaN;
                    % Spike in Sap10avg
                    output([7246 7249],12) = NaN;
                    % Spike in Sap13avg
                    output([4788 7246 7249 11746],15) = NaN;
                    % Spike in Sap15avg
                    output([7246 7249 13143],17) = NaN;
                    % Spike in Sap16avg, + 8500:11000 points? Rachel
                    % documented this sensor as having no data
                    output([7246 7249],18) = NaN;
                    % Spike in Sap20avg
                    output([7246 7249],20) = NaN;
                    % Spike in Sap1mAX
                    output([14230],28) = NaN;
                    % Spike in Sap3mAX
                    output([14230],32) = NaN;
                    % Spike in Sap9mAX
                    output([14230],44) = NaN;
                    % Spike in Sap1_0mAX
                    output([14230],46) = NaN;
                    % Spike in Sap1_3mAX
                    output([14230],52) = NaN;
                    % Spike in Sap1_8mAX
                    output([14230],62) = NaN;
                    
                    
                case '2016'
                    % Sap Ref 1 Avg
                    output([4210 10991 13228:13234 17332:17338],3) = NaN;
                    % Sap Ref 3, 9, 10, 13, 15, 18 Avg
                    output([4210 5644:5647 9832 10875 10880 10991 13228:13234 17332:17338],[5 11 12 15 17 20]) = NaN;
                    % Sap 1 Max
                    output([5646 17336],[28 32 44 62]) = NaN;
                    % Sap 13 Max
                    output([10991 13234 17336],52) = NaN;
                    % Sap 15 Max
                    output([11458:12214],[68 107]) = NaN;
                    % Sap 21 Max
                    output([10991 13234 17336],68) = NaN;
                    % Sap 24 Max
                    output([5827:5830 6405 6459:7261 10682 10827:10832 10875 10880 10991 11690 13227:13235 16095:16408 16529:16560 16959:17079 17336],74) = NaN;
                    % Sap Dr 50 Avg
                    output([9804:11869 12032:12489 12531:12969],95) = NaN;
                    % Sap Dr 6B Avg
                    output([5645 13228 17332:17338],111:115) = NaN;
                    
                case '2017'    
                    % HFlux A
                    output([4255:4261 5262 5732:5736 5763:5767 5795 5796],[1 2]) = NaN;
                    % Sap Ref 1 Avg
                    output([1090:1092 1235:1238 1241 1301 1543 2121 2122 2153 2154 2172 2184 2192 2414 2600 2621 2640 2914 2915 ...
                        3205:3248 9712:9715 10710:10713 11013 11044 11045],3) = NaN;
                    % Sap Ref 3, 9, 13, 18 Avg
                    output([2914 2915 3205 3247 13821 13822 14207 14208 15036 15107 15554 15555 15632 16215 16275],[5 11 15 20]) = NaN;
                    % Sap Fall 15 Avg and Max
                    output([2055:2084 2914 2915 3205 3247],[17 56]) = NaN;
                    % Sap 1 Max
                    ouput([1091 1092 1237 1241 2121 2184 2192 2414 3206:3248],28) = NaN;
                    % Sap 3, 9, 13, 24 Max
                    output([3247],[32 44 52 74]) = NaN;
                                 
                case '2018'
      
                case '2019'
                    output(:,[4 7]) = NaN;
                    output([15893:15896],11) = NaN;
                    output([6409 6417],12) = NaN;
                    
                case '2021' % EAR & LL
                    %HfluxB spikes
                    output([9023 15170 16280],2) = NaN;
                    % SapREF1Avg spikes 
                    output([277:14080],3) = NaN;
                    % SapREF4Avg spikes 
                    output([200:3000],6) = NaN;
                    % Sap1MAX
                    output([0:14100],28) = NaN;
                    % Sap2MAX
                    output([0:14100],30) = NaN;
                    % Sap4MAX
                    output([0:14970],34) = NaN;
                    % Sap5MAX
                    output([0:14970],36) = NaN;
                    % TsREF20AAVG
                    output([12250 12280 12350 13230 13460 14100],85) = NaN;
                    
                case '2022' % EAR & LL
                    output([1:end], 1) = NaN;%HFluxA
                    output([7330 11247:11276 16180 17218:17222], 3) = NaN;%SapREF1Avg
                    output([10386 11246:11275 11280 16177:16178 17218:17221], 4) = NaN;%SapREF2Avg
                    output([11248:11274 16177:16182 17218:17224], 5) = NaN;%SapREF3Avg
                    output([16180:16181 17218:17224], 6) = NaN;
                    output([5353 7330 7430 7709 16180:16181 17218:17224], 7) = NaN;
                    output([11247 16180:16181 17218:17224], 10) = NaN;
                    output([16180:16181 17218:17224], 11) = NaN;
                    output([16180:16181 17218:17224], 12) = NaN;%SapDR10Avg
                    output([3683 5362 7330 7430 7710 11247 16180:16181 17218:17224], 13) = NaN;
                    output([342 16180:16181 17218:17224], 14) = NaN;
                    output([16180:16181 17218:17224], 15) = NaN;
                    output([3681 11247 16180:16181 17218:17224], 16) = NaN;
                    output([5097 5464 11247 16180:16181 17218:17224], 17) = NaN;%SapFALL15Avg
                    output([3738 16180:16181 17218:17224], 18) = NaN;
                    output([5097 5353 16180:16181 17218:17224], 19) = NaN;%SapTHIN17Avg
                    output([11247 16180:16181 17218:17224], 20) = NaN;
                    output([16180:16181 17218:17224], 21) = NaN;
                    output([16180:16181 17218:17224], 22) = NaN;
                    output([11247 16180:16181 17218:17224], 27) = NaN;%Sap25Avg
                    output([7330:7333 11247:11259 16180:16181 17218:17224], 28) = NaN;
                    output([3327:3329 3636 3973 3976 4290:4296 4311 4545:4547 4560 4563 4594 4606:4607 4627:4629 4638 4642 4716:4718 5308:5311 5320 5354:5357 5425 5457 5479:5482 5495 5946:5965 6230 6317:6318 7186:7198 7286 7330 7348 7429 7708:7709 8120 8150 8239:8245 8770 10386 11275 16180:16181 17218:17224], 30) = NaN;%Sap2MAX
                    output([1:10387 11247:11258 16180:16181 17218:17224], 32) = NaN; 
                    output([16180:16181 17218:17224], 34) = NaN;
                    output([7330 7708 11247:11258 16180:16181 17218:17224], 36) = NaN;%Sap5MAX
                    output([1:3685 5903: 6063 16180:16181 17218:17224], 42) = NaN;
                    output([1:3685 11259 16180:16181 17218:17224], 44) = NaN;
                    output([1:3685 11262:11274 16180:16181 17218:17224], 46) = NaN;
                    output([1:3682 16180:16181 17218:17224], 50) = NaN;
                    output([1:3726 5307 16180:16181 17218:17224], 52) = NaN;%Sap13MAX
                    output([1:3691 11247:11259 16180:16181 17218:17224], 54) = NaN;
                    output([1:3687 5328:5353 5311 5464:5465 16180:16181 17218:17224], 56) = NaN;
                    output([1:3678 3737 16180:16181 17218:17224], 58) = NaN;
                    output([1:3741 11247:11259 16180:16181 17218:17224], 60) = NaN;
                    output([1:10386 16180:16181 17218:17224], 62) = NaN;
                    output([1:10386 16180:16181 17218:17224], 64) = NaN;
                    output([1:10386 16180:16181 17218:17224], 66) = NaN;
                    output([1:10386 16180:16181 17218:17224], 62) = NaN;
                    output([1:10386 16180:16181 17218:17224], 68) = NaN;
                    output([1:10386 16180:16181 17218:17224], 70) = NaN;%Sap22MAX
                    output([1:10386 16180:16181 17218:17224], 72) = NaN;
                    output([1:10386 16180:16181 17218:17224], 74) = NaN;
                    output([1:10386 16180:16181 17218:17224], 76) = NaN;
                    output([7709 10836], 84) = NaN;%TsDR20Avg
                    output([3683], 85) = NaN;
                    output([2284:2290 3109:3117], 86) = NaN;
                    output([3184:3374 3577 3624 3628 4102 4114:4115 4209:4213 10386], 91) = NaN;
                    output([11247 16180:16181 17218:17224], 107) = NaN;%
                    output([11247 16180:16181 17218:17224], 108) = NaN;
                    output([16180:16181 17218:17224], 109) = NaN;
                    output([16180:16181 17218:17224], 110) = NaN;
                    output([5097 5353 7330 7430 11262:11274 16180:16181 17218:17224], 111) = NaN;
                    output([11247 16180:16181 17218:17224], 112) = NaN;
                    output([7330 11262:11274 16180:16181 17218:17224], 113) = NaN;
                    output([1:3689 16180:16181 17218:17224], 115) = NaN;
               
                case '2023' % EAR & NS
                    output([1:end], 1) = NaN;%HFluxA
                    output([2543 2972:2973 4323 11255 11327 12875 13340:13341 13353 14503:14509 14980:14982 16458:16463 17295:17297], 2) = NaN;
                    output([1204:1206 1919:1920 2586:2589 2976:2983 4068:4073 4323 6241 8729 12008 12023 16125], 3) = NaN;
                    output([1204 1653:1674 1919 2023 2787 2886:2590 4323 9728:9729 12008 12023 13448:13465 15855], 4) = NaN;
                    output([1204:1216 1919:1921 2586:2590 2974:2997 4068:4076 4323 6241 8779 12008 12023 13237:end], 5) = NaN;%SapREF3Avg
                    output([1205:1216 1919:1921 2586:2590 2974:2995 4068:4078 4323 6241 8779 12008 12023], 6) = NaN;
                    output([1:end], 7) = NaN;
                    output([1204:1217 1919 1921 2586:2589 2972:2993 4021:4073 4323 6241:6243 12008 12023], 10) = NaN;
                    output([1204:1216 1919:1922 2486:2590 2572:2597 4021:4078 4323 6241:6243 8779 12008 12023], 11) = NaN;
                    output([1204:1208 1919:1921 2586:2591 2972:2982 4021:4070 4322:4328 6240:6245 12008 12023], 12) = NaN;%SapDR10Avg
                    output([1204:1210 1919:1923 2529 2586:2594 2972:2983 4021:4072 4321:4324 6240:6246 12008:12062 12407 14174:end], 13) = NaN;
                    output([12008], 14) = NaN;
                    output([1204:1207 1919:1923 2586:2591 2972:2984 4021:4076 4323 6240:6248 12008], 15) = NaN;
                    output([840 1204:1206 1919:1922 2586:2591 2971:2992 4021:4075 4323 6240:6245 12008], 16) = NaN;
                    output([1204:1207 1919:1924 2586:2590 2972:2982 4021:4069 4323 6240:6246 8778 8779 12008], 17) = NaN;%SapFALL15Avg
                    output([1204:1211 1919:1922 2586:2591 2972:2985 3579:3587 4021:4076 4323 6240:6244 8777:8780 12008], 18) = NaN;
                    output([1204:1206 1795:1797 1911:1920 2040:2042 2586:2591 2972:2983 4021:4074 4323 6241:6244 12008], 19) = NaN;
                    output([1204:1215 1919:1921 2586:2590 2971:2983 4021:4075 4323 6241:6247 8779 10109:10112 12008], 20) = NaN;
                    output([1204:1210 1919:1922 2586:2591 2972:2985 4021:4081 4323 6241:6245 8779 12008], 21) = NaN;
                    output([1204:1210 1919:1923 2586:2591 2974:2984 4068:4080 4322:4325 6241:6246 8779 12008], 22) = NaN;
                    output([1204:1211 1919:1923 2586:2592 2972:2984 4022:4068 4323 6241:6246 8779 12008], 27) = NaN;%Sap25Avg
                    output([1204:1211 1919:1923 2586:2592 2972:2984 4022:4068 4323 6241:6246 8779 12008 16125:16126], 28) = NaN;
                    output([846 1204 1234:1272 1339 1429 1436 1745 1853:1900 1919 2023 2187:2199 2244 2393 2430 2488 2586 3010 3724:3725 3778:3781 4018:4072 6320 9916 10012 10586:10589], 30) = NaN;%Sapo2MAX
                    output([1919 2586 2973 4068 8779 8829], 32) = NaN;
                    output([8779], 34) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 36) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 42) = NaN;%Sap8MAX
                    output([1919 2586 2973 4068 8779 8829], 44) = NaN;%Sap9MAX
                    output([1919 2586 2973 4068 8779 8829], 46) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 50) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 52) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 54) = NaN;%Sap14MAX
                    output([1919 2586 2973 4068 8779 8829], 56) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 58) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 60) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 62) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 64) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 66) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 68) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 70) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 72) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 74) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 76) = NaN;
                    output([12023 12703 12747 12749 13344], 85) = NaN;
                    output([4323 9208 9398:9403 9636:9640 10713 10879:10880 11327 11958], 86) = NaN;
                    output([1:end], 87) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 107) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 108) = NaN;
                    output([1919 2586 2973 4068 8779 8829], 109) = NaN;
                    output([1919 2586 2973 4068 4323 8779 8829], 110) = NaN;
                    output([1204:1213 1919:1922 2586:2590 2971:2985 4021:4080 4323 6240:6251 8779 8829], 111) = NaN;
                    output([1204:1207 1919:1922 2586:2592 2972:2983 4021:4070 4323 6240:6246 8779 8829], 112) = NaN;
                  
                    case '2024' 
                    output([1:end], 1) = NaN;%HFluxA
                    output([1130 1205 2762:2764 5176 8660 8661 16266:16275 16842:16844 17185:17190], 2) = NaN;
                    output([16019:end], 3) = NaN;
                    output([16019:end], 5) = NaN;
                    output([16019:end], 6) = NaN;
                    output([10539], 7) = NaN;
                    output([10365:10385 16019:end], 10) = NaN;
                    output([16019:end], 12) = NaN;
                    output([16019:end], 13) = NaN;
                    output([16019:end], 20) = NaN;
                    output([16019:end], 28) = NaN;
                    output([16019:end], 30) = NaN;
                    output([16019:end], 32) = NaN;
                    output([16019:end], 34) = NaN;
                    output([10365:10385 16019:end], 42) = NaN;
                    output([16019:end], 46) = NaN;
                    output([16019], 52) = NaN;
                    output([10539], 78) = NaN;
                    output([7247 7248 10539:10560 11786:11808 13416:13440 16020:16032], 79) = NaN;
                    output([16019], 83) = NaN;
                    output([16019], 84) = NaN;
                    output([16019 2758:2770], 85) = NaN;
                    output([8529:8532 8660:8661 10305 10337:10340 10485:10491 14512:14513], 86) = NaN;
                    output([12064], 87) = NaN;
                    output([16019], 88) = NaN;
                    output([16019], 89) = NaN;
                    output([10539 16019], 107) = NaN;
                    output([10539 16019:end], 111) = NaN;
                    output([10364:10539 16019], 112) = NaN;
                    output([16019:end], 113) = NaN;
                    output([10364:10539 16019], 115) = NaN;
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'TP74_sapflow'
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%% TP74_sapflow %%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            switch yr_str
                case '2010'
                    
                case '2011'
                    output([6951 11850],1) = NaN;
                    output([4161:5016 6951:6983 7007 11850],2) = NaN;
                    output([6951 11850],3) = NaN;
                    output([6951:7032 11850],4) = NaN;
                    output([6951:6983 11850],5) = NaN;
                    output([4979 6952:6983 11850],6) = NaN;
                    output([4227:4256 6951:6983 11850],7) = NaN;
                    output([4007 6951:6983 11850],8) = NaN;
                    output([6951:6983 11850],9) = NaN;
                    output([6951:6983 11850],10) = NaN;
                    output([6951:6983 11850],12) = NaN;
                    output([6951:6983 11850 15915:17520],13) = NaN;
                    output([6951:6983 11850],14) = NaN;
                    output([6951:6983 11850],15) = NaN;
                    output([4978 6951:6983 11850],16) = NaN;
                    output([6951:6983 11850],15) = NaN;
                    output([11000:14470],17) = NaN;
                case '2012'
                case '2013'
                case '2014'
                    % Spikes in all sensors
                    output([14827],:) = NaN;
                    % poor sensor #3 and 13 data
                    output([6801:7355 9932:12200 15168:15172 16053 16460:16480 16503],[3 37 47 54 63 63]) = NaN;
                    output(14000:17520,[47 64]) = NaN; % Sensor 13 all wonky after fall
                    % inactive sensors: #10, 11
                    output(:,[10 11 27 28 44 45 61 62]) = NaN;
                    % Sensor #12 removed in April ***
                    output(6131:17520, [12 29 46]) = NaN;
                    % poor sensor #17 data
                    output(:,[51 68]) = NaN;
                    % v. high sensor #1,2,4,5,7,8,9,14 data
                    %output(6125:6186,52) = NaN;
                    
                    % Seonsr 17 spikes
                    output([14827:14891],34) = NaN;
                    
                    
                case '2015'
                    % Sensors 10,11,12 are inactive
                    % Sap_DT 5 has bad data after April
                    % Sap_DT_max 5 has bad data after April,
                    % Sap_vel 5 has bad data after April, 13+17 has bad data
                    % Sapflow 5 has bad data after April, 13+17 has bad data
                    
                    % Spike from changing sapflow sensors, shift afterwards
                    output([4984:4985 ],2:4 ) = NaN;
                    
                case '2016'
                    % Sensor dt Spikes
                    output([4976 5051 9775 10282],[1:9 14:16]) = NaN;
                    % Sensor dt Tree 9 Spikes
                    output([5652],[9 14]) = NaN;
                    % Sap dt Max Tree 1
                    output([4976:5002 5051:5099 9775:9802],18) = NaN;
                    % Sap dt Max Tree 4,8,14,15,16
                    output([9775:9802],[21 25 31:33]) = NaN;
                    % Sap dt Max Tree 13 & 17
                    output([4976:5156 9775:9850],[30 34]) = NaN;
                    % Sap Velocity Tree 1
                    output([9775],35) = NaN;
                    % Sensor Velocity Spikes
                    output([4976 5051 9775 10282],[36:43 48:50]) = NaN;
                    % Sensor Flow Spikes
                    output([4976 5051 9775 10282],[52:60 65:67]) = NaN;
                    
                case '2017'
                    % Sap dt Tree 3
                    output([1207:1562],3) = NaN;
                    % Sap dt Tree 4
                    output([2385 2386 3248], 4) = NaN;
                    % Sap dt Tree 7, 8, 9, 14, 15 16
                    output([3248],[7:9 14:16]) = NaN;
                    % Sensor Velocity Spikes
                    output([3248],[36:43 48:50]) = NaN;
                    % Sensor Flow Spikes
                    output([3248],[52:60 65:67]) = NaN;
                    
                case '2018'
                case '2019'
                case '2020'
                case '2021' % EAR & LL
                    output([391:491 1041:1308],[42 59]) = NaN;
                    output([412:433 1098:1164],[48 65]) = NaN;
                    output([370:397 1066:1115],[50 67]) = NaN;
                    
                case '2022' % EAR & LL - Nothing - 2023-05-05
                    
                case '2023' % EAR & NS - Nothing - 2023-01-12
                    output([1608:1852],6) = NaN;
                                  
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'TP_PPT'
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%% TP_PPT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            PPT_raw = output(:,output_cols(strcmp(output_names,'GN_Precip')==1));
            
            switch yr_str
                case '2008'
                    output_shift = [output(1:9000,1:end); output(9002:end,1:end); NaN.*ones(1,size(output,2))];
                    output = output_shift;
                    %             Geo_PPT_shift = [PPT_raw(1:9000); PPT_raw(9002:end); NaN];
                    %             output(:,output_cols(strcmp(output_names,'GN_Precip')==1))= Geo_PPT_shift;
                    %             PPT_out = Geo_PPT_shift;
                    %             clear Geo_PPT_shift;
                    %             PPT_tx_shift = [PPT_tx(1:9000); PPT_tx(9002:end); NaN];
                    %             PPT_tx = PPT_tx_shift;
                    %             clear PPT_tx_shift;
                    % Take out obvious bad data;
                    %             output([5496:5497 938 13707 16833],1:end) = NaN;
                case '2009'
                    % Take out bad data in wind speed:
                    output(1819:3437,4:7) = NaN;
                case '2010'
                    
                    
                    % Added Oct 09, 2010 by JJB:%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%% We need to insert an algorithm for removing large
                    %%% diurnal(ish) variations in bucket level during the start of
                    %%% 2010, due to the bucket being improperly balanced.  We'll
                    %%% do this by manually removing points where there seems to be
                    %%% no precipitation, and making these values equal to the last
                    %%% good point before it.  Doing this creates a much more
                    %%% acceptible result for PPT, as otherwise, these variations
                    %%% will be incorrectly counted as precipitation events.
                    %%% The list defines regions where we want to make the values
                    %%% constant (i.e. no precipitation)
                    GN_Precip = PPT_raw;
                    
                    bad_data = {522:862 891:1130 1324:1550 1610:1883 1954:2112 2170:2280 2286:2300 ...
                        2322:2525 2570:2615 2622:2686 2775:3359 3492:3731};
                    for k = 1:1:length(bad_data)
                        ind_last = find(~isnan(PPT_raw(1:bad_data{1,k}(1,1)-1)),1,'last');
                        last_good = PPT_raw(ind_last);
                        GN_Precip(bad_data{1,k}(1,:),1) = last_good;
                    end
                    %%% Copy over the bad data:
                    output(:,output_cols(strcmp(output_names,'GN_Precip')==1)) = GN_Precip;
                    clear GN_Precip;
                case '2011'
                    % Missing data in all fields
                    output(10789:10982, 1:15) = NaN;
                case '2015'
                    % Missing data in all fields
                    output([1:5409],:) = NaN; % Datalogger malfunctioned / bad data
                    output([16304:end],1) = NaN; % Bad battery voltage
                    output([16445:end],10:15) = NaN; % Bad PPT data
                    output([14286:14506 15675:16292],[4:6 8 10:15]) = NaN; % Bad data (Wind + PPT)
                    % Bad data point
                    output(5583,[12 15]) = NaN;
                case '2016'
                    % Faulty Sensor -> Tried to remove data but code did
                    % not work
                    %                     output([174:1567],15) = NaN;
                    output(14281,[11 12 13 15]) = NaN; % Bad battery voltage
                case '2017'
                    
                case '2018'
                    output(16317:16501,[10:15]) = NaN;
                case '2019' 
                   output(7330,[10:15]) = NaN; 
                   output(4872,[14:15]) = NaN; 
                   
                case '2020'
                    
                case '2021' % EAR & LL
                    output([9681:11816],3) = NaN;% panel temp
                    
                    output([4399:end],15) = NaN;% Geonor precip
                case '2022' % EAR & LL - 2023-05-05
                    output([8953], 12) = NaN;
                    
                case '2023' % EAR - 2024-01-12
                    output([9635], 4) = NaN;
                    output([4556 9634 9923 10990 11800 16590], 5) = NaN;
                    output([1438 1573:1593 1913 2480 3148 4349:4376 5737:5740 7796:7813 9278:9290], 6) = NaN;
                    output([2540:2707 4345 4349 4556 4559 5076 5736 9634:9635 9923], 7) = NaN;
                case '2024'    
                    output([11539 14378], 10) = NaN;
                    output([14378 14379], 11) = NaN;
                    output([11539 14378 14379], 12) = NaN;
                    output([14378 14379], 15) = NaN;
            end
            %%% Call mcm_PPTfixer to Calculate event-based precipitation at
            %%% TP_PPT:
            GN_Precip = output(:,output_cols(strcmp(output_names,'GN_Precip')==1));
            TX_Rain = output(:,output_cols(strcmp(output_names,'TX_Rain')==1));
            
            % mcm_PPTfixer will automatically save data to /Cleaned/ and /Final_Cleaned/
            mcm_PPTfixer(year_ctr, GN_Precip,PPT_raw, TX_Rain);
            disp('mcm_PPTfixer finished.');
            disp('GEONOR and TX data saved separately to /Cleaned/ and /Final_Cleaned/.');
            clear GN_Precip TX_Rain;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'TP39'
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%% TP39  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            switch yr_str
                case '2002' % TP39 2002
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = 100;
                    % Swap some mixed up Ts sensors:
                    Ts5B_orig = output(:,output_cols(strcmp(output_names,'SoilTemp_B_5cm')==1));
                    Ts2B_orig = output(:,output_cols(strcmp(output_names,'SoilTemp_B_2cm')==1));
                    
                    output(:,output_cols(strcmp(output_names,'SoilTemp_B_5cm')==1)) = [Ts5B_orig(1:5538,1) ; Ts2B_orig(5539:end)];
                    output(:,output_cols(strcmp(output_names,'SoilTemp_B_2cm')==1)) = [Ts2B_orig(1:5538,1) ; Ts5B_orig(5539:end)];
                    
                    % bad LW_down data:
                    output(:,18) = NaN;
                    
                    %%%%%%%%%%%%%%%%%%%% correcting too-low PAR values %%%
                    % using correlation with SW down:
                    PAR_tmp = output(:,9); SWdown_tmp = output(:,14);
                    figure(77);clf; plot(PAR_tmp,SWdown_tmp,'k.');
                    % line of best-fit
                    p = polyfit(SWdown_tmp(~isnan(PAR_tmp+SWdown_tmp)),PAR_tmp(~isnan(PAR_tmp+SWdown_tmp)),1);
                    PAR_pred = polyval(p,SWdown_tmp);
%                     PAR_diffn = (PAR_tmp - PAR_pred)./PAR_pred;
%                     figure(78);plot(PAR_diffn,'k.')
%                     figure(79);clf;plot(PAR_tmp,'b'); hold on; plot(PAR_pred,'r');
                   
                    % fix for the affected period:
                    output(12720:13240,9) = PAR_pred(12720:13240,1);
                     clear PAR_tmp SWdown_tmp PAR_pred p;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                    
                    % Noisy Snow Depth Data
                    % output([1086:3822 4635:4971 16000:17520],31) = NaN;
                    output(:,31)=NaN; % JJB 20180427 - completely removing it.
                    %%%%%%%%%%%%%%%%%%%%% START SHIFTING %%%%%%%%%%%%%%%%%%
                    % Shift data so that it's all in UTC: %%%%%%%%%%%%%%%%%%%%
                    % need to load last 8 datapoints from 2001
                    num_to_shift = 8;
                    for i = 1:1:length(vars30)
                        try
                            temp_var = load([load_path site '_2001.' vars30_ext(i,:)]);
                        catch
                            %                         disp(['could not load the 2001 variable: ' names30_str(i,:)]);
                            %                         disp(['Check if column should exist -- making NaNs']);
                            
                            temp_var = NaN.*ones(len_yr,1);
                        end
                        
                        fill_data(1:num_to_shift,i) = temp_var(end-num_to_shift+1:end);
                        clear temp_var;
                    end
                    output_test = [fill_data(:,:); output(1:end-num_to_shift,:)];
                    clear fill_data;
                    clear output;
                    output = output_test;
                    clear output_test;
                    %%%%%%%%%%%%%%%%%%%%% END SHIFTING %%%%%%%%%%%%%%%%%%
                    
                    % Swap mislabeled HMPs - For 2002, the ground and top
                    % HMPs need to be swapped:
                    Ta_abv_orig = output(:,1); RH_abv_orig = output(:,4);
                    Ta_gnd_orig = output(:,3); RH_gnd_orig = output(:,6);
                    output(:,1)=Ta_gnd_orig;
                    output(:,3)=Ta_abv_orig;
                    output(:,4)=RH_gnd_orig;
                    output(:,6)=RH_abv_orig;
                    clear *abv_org *gnd_orig;
                    
                    % Fix a data offset issue, by moving data back by 1
                    % halfhour KEEP THIS AT THE END
                    output = [output(2:9638,:);NaN.*ones(1,size(output,2));output(9639:17520,:)];
                case '2003' % TP39 2003
                    for i = 1:1:length(vars30)
                        try
                            temp_var = load([load_path site '_2002.' vars30_ext(i,:)]);
                        catch
                            disp(['could not load the 2002 variable: ' names30_str(i,:)]);
                            disp(['Check if column should exist -- making NaNs']);
                            temp_var = NaN.*ones(len_yr,1);
                        end
                        
                        fill_data(1:8,i) = temp_var(end-8+1:end);
                        clear temp_var;
                    end
                    output = [fill_data(:,:); output(9:end,:)];
                    clear fill_data;
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = 100;
                    % Swap some mixed up Ts sensors:
                    Ts5B_orig = output(:,output_cols(strcmp(output_names,'SoilTemp_B_5cm')==1));
                    Ts2B_orig = output(:,output_cols(strcmp(output_names,'SoilTemp_B_2cm')==1));
                    
                    output(:,output_cols(strcmp(output_names,'SoilTemp_B_5cm')==1)) = Ts2B_orig(1:end,1);
                    output(:,output_cols(strcmp(output_names,'SoilTemp_B_2cm')==1)) = Ts5B_orig(1:end,1);
                    
                    % Remove bad PAR_down data
                    output(11405:11406,9)=NaN;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                    % Fix bad LWdown data
                    output([9204:9218 9295:9304 9971:9978 10005:10025 10069:10072 10158:10171 10207 10693:10701 10735:10748 10776:10785 10826:10843 10873:10892 10921:10947 10973:10991 11017 11026 11036 11037 11064:11072 11115:11124 11164:11182 11259 11277 11319:11324 11368:11373 11406:11410 11449:11469 11497:11517 12332:12334 13577:13579],18) = NaN;
                    
                    % Add PPT data from the /Final_Cleaned/TP39_PPT_2003-2007 directory
                    load([output_path(1:end-1) '_PPT_2003-2007/TP39_PPT_met_cleaned_' yr_str '.mat']);
                    output(:,output_cols(strcmp(output_names,'CS_Rain')==1)) = ppt;
                    clear ppt;
                    
                    % Swap mislabeled HMPs - For 2003, the ground and top
                    % HMPs need to be swapped:
                    Ta_abv_orig = output(:,1); RH_abv_orig = output(:,4);
                    Ta_gnd_orig = output(:,3); RH_gnd_orig = output(:,6);
                    output(:,1)=Ta_gnd_orig;
                    output(:,3)=Ta_abv_orig;
                    output(:,4)=RH_gnd_orig;
                    output(:,6)=RH_abv_orig;
                    clear *abv_org *gnd_orig;
                    % Fix a data offset issue, by moving data back by 1
                    % halfhour KEEP THIS AT THE END
                    output = [output(1:17468,:);output(17470:end,:);NaN.*ones(1,size(output,2))];
                    
                case '2004' % TP39 2004
                    % Add PPT data from the /Final_Cleaned/TP39_PPT_2003-2007 directory
                    load([output_path(1:end-1) '_PPT_2003-2007/TP39_PPT_met_cleaned_' yr_str '.mat']);
                    output(:,output_cols(strcmp(output_names,'CS_Rain')==1)) = ppt;
                    clear ppt;
                    % Swap mislabeled HMPs - For 2004, the ground and top
                    % HMPs need to be swapped:
                    Ta_abv_orig = output(:,1); RH_abv_orig = output(:,4);
                    Ta_gnd_orig = output(:,3); RH_gnd_orig = output(:,6);
                    output(:,1)=Ta_gnd_orig;
                    output(:,3)=Ta_abv_orig;
                    output(:,4)=RH_gnd_orig;
                    output(:,6)=RH_abv_orig;
                    clear *abv_org *gnd_orig;
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = 100;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2005' % TP39 2005
                    % Add PPT data from the /Final_Cleaned/TP39_PPT_2003-2007 directory
                    load([output_path(1:end-1) '_PPT_2003-2007/TP39_PPT_met_cleaned_' yr_str '.mat']);
                    output(:,output_cols(strcmp(output_names,'CS_Rain')==1)) = ppt;
                    clear ppt;
                    % Fix a data offset issue, by moving data back by 1
                    % halfhour KEEP THIS AT THE END
                    output = [output(2:17520,:);NaN.*ones(1,size(output,2))];
                    
                    % Swap mislabeled HMPs - For 2005, ground and top
                    % HMPs need to be swapped for the first 7 hhrs only:
                    Ta_abv_orig = output(:,1); RH_abv_orig = output(:,4);
                    Ta_gnd_orig = output(:,3); RH_gnd_orig = output(:,6);
                    output(1:8,1)=Ta_gnd_orig(1:8,1);
                    output(1:8,3)=Ta_abv_orig(1:8,1);
                    output(1:8,4)=RH_gnd_orig(1:8,1);
                    output(1:8,6)=RH_abv_orig(1:8,1);
                    clear *abv_org *gnd_orig;
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = 100;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2006' % TP39 2006
                    % Remove obvious bad data in PAR down abv cnpy
                    bad_data = [4341 4438 4725 4773 4821 5301 5684 5732 6500 ...
                        7075 7123 7171 7459 7507 7555 7603 7651 7699 7747 7843 ...
                        7939 7987 8035 8083 8179 8227 8371 8419 8659];%8852?
                    
                    output(bad_data,output_cols(strcmp(output_names,'DownPAR_AbvCnpy')==1))=NaN;
                    output(bad_data+1,output_cols(strcmp(output_names,'DownPAR_AbvCnpy')==1))=NaN;
                    
                    output(12290:12310,output_cols(strcmp(output_names,'DownPAR_AbvCnpy')==1))=0;
                    
                    % Remove obvious bad data in PAR down blw cnpy
                    output(12250:12600,35) = NaN;
                    %                     output(:,75:80)= NaN; output(:,82:85)= NaN; output(:,89:90)= NaN;
                    %                     output(12284:17520,69:91) = NaN;
                    %                     %%%% Move PAR bottom down to zero:
                    %                     output(output(:,33) < 10,33) = 0;
                    % Add PPT data from the /Final_Cleaned/TP39_PPT_2003-2007 directory
                    load([output_path(1:end-1) '_PPT_2003-2007/TP39_PPT_met_cleaned_' yr_str '.mat']);
                    output(:,output_cols(strcmp(output_names,'CS_Rain')==1)) = ppt;
                    clear ppt;
                    
                    %                     Fix a data offset issue, by moving data back by 1
                    %                     halfhour KEEP THIS AT THE END
                    output = [output(1:6490,:);output(6492:11050,:);NaN.*ones(1,size(output,2));output(11051:end,:)];
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = 100;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2007' % TP39 2007
                    
                    %                 %% Corrects for inverted Net Radiation for a period of time
                    %                 %% in the data -- due to backwards wiring of sensor into
                    %                 %% datalogger.
                    %                 %% use the mean of one day during the period to make sure
                    %                 %% the data hasn't already been flipped once (mean of the
                    %                 %% day is -24.707)
                    if mean(input_data(6015:6063,18)) < 0
                        output(459:7842,1) = -1.*output(459:7842,1);
                    end
                    % clean Ta14m&Ta2m for bad data
                    output(2758:2812,2:3) = NaN;
                    %Clean bad wind speed and direction data;
                    output(683:1070,output_cols(strcmp(output_names,'WindSpd')==1)) = NaN;
                    output(683:1070,output_cols(strcmp(output_names,'WindDir')==1)) = NaN;
                    
                    % Clean bad data in blw_cnpy PAR:
                    
                    output(694:763,output_cols(strcmp(output_names,'DownPAR_BlwCnpy')==1)) = NaN;
                    % Clean bad data in canopy and blw_cnpy CO2:
                    bad_CO2_cpy = [2339:2340 3629 4306 5737 7659 14478 17372:17377]';
                    output(bad_CO2_cpy, output_cols(strcmp(output_names,'CO2_Cnpy')==1)) = NaN;
                    bad_CO2_blw = [4305 4724 5203 5258 5737 13126 16017 16922 17372:17377]';
                    output(bad_CO2_blw, output_cols(strcmp(output_names,'CO2_BlwCnpy')==1)) = NaN;
                    % Clean bad HFT data:
                    bad_HFT2 = [7647:7658]';
                    output(bad_HFT2, output_cols(strcmp(output_names,'SoilHeatFlux_HFT_2')==1)) = NaN;
                    % Clean bad soil data:
                    bad_soil_data = [694:763 7626:1:7658]';
                    bad_soil_cols = [79:100]';
                    output(bad_soil_data, bad_soil_cols) = NaN;
                    % SM 100 B probe -- before it was installed properly.
                    output(1:8200,output_cols(strcmp(output_names,'SM_B_100cm')==1)) = NaN;
                    % Swap mislabeled HMPs - For 2007--2015:
                    % labeled as    | should be
                    %   abv         | gnd
                    %   gnd         | cpy
                    %   cpy         | abv
                    Ta_abv_orig = output(:,1); RH_abv_orig = output(:,4);
                    Ta_cpy_orig = output(:,2); RH_cpy_orig = output(:,5);
                    Ta_gnd_orig = output(:,3); RH_gnd_orig = output(:,6);
                    output(:,1)=Ta_cpy_orig(:,1);
                    output(:,2)=Ta_gnd_orig(:,1);
                    output(:,3)=Ta_abv_orig(:,1);
                    output(:,4)=RH_cpy_orig(:,1);
                    output(:,5)=RH_gnd_orig(:,1);
                    output(:,6)=RH_abv_orig(:,1);
                    clear *abv_org *gnd_orig *cpy_orig;
                    
                    %%%%%%%%%%%%%%%%%%%%% START SHIFTING %%%%%%%%%%%%%%%%%%
                    % Shift data so that it's all in UTC: %%%%%%%%%%%%%%%%%%%%
                    % need to load last 8 datapoints from 2006
                    num_to_shift = 8;
                    for i = 1:1:length(vars30)
                        try
                            temp_var = load([load_path site '_2006.' vars30_ext(i,:)]);
                        catch
                            disp(['could not load the 2006 variable: ' names30_str(i,:)]);
                            disp(['Check if column should exist -- making NaNs']);
                            
                            temp_var = NaN.*ones(len_yr,1);
                        end
                        
                        fill_data(1:num_to_shift,i) = temp_var(end-num_to_shift+1:end);
                        clear temp_var;
                    end
                    output_test = [fill_data(:,:); output(1:end-num_to_shift,:)];
                    clear fill_data;
                    clear output;
                    output = output_test;
                    clear output_test;
                    %%%%%%%%%%%%%%%%%%%%% END SHIFTING %%%%%%%%%%%%%%%%%%
                    % Add PPT data from the /Final_Cleaned/TP39_PPT_2003-2007 directory
                    load([output_path(1:end-1) '_PPT_2003-2007/TP39_PPT_met_cleaned_' yr_str '.mat']);
                    output(:,output_cols(strcmp(output_names,'CS_Rain')==1)) = ppt;
                    clear ppt;
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = NaN;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2008' % TP39 2008
                    % Fix CO2_cpy offset during late 2008 (if hasn't already been done)
                    right_col = quick_find_col( names30, 'CO2_BlwCnpy');
                    if output(15821,right_col) - output(15822,right_col) > 20
                        output(15822:17568,right_col) = output(15822:17568,right_col)+33;
                    elseif output(15821,right_col) - output(15822,right_col) < 20
                        output(15822:17568,right_col) = output(15822:17568,right_col)-33;
                    end
                    clear right_col;
                    % Fix SnowDepth -- remove a bad point:
                    right_col = quick_find_col( names30, 'SnowDepth');
                    output(9664,right_col) = output(9663,right_col); clear right_col;
                    % Fix Problems with Atm. Pres sensor for a couple periods:
                    right_col = quick_find_col( names30, 'Pressure');
                    output(12380:13120,right_col) = NaN;
                    output(13980:14480,right_col) = NaN; clear right_col;
                    
                    % Shift data so that it's all in UTC:
                    % need to load last 8 datapoints from 2007
                    for i = 1:1:length(vars30)
                        temp_var = load([load_path site '_2007.' vars30_ext(i,:)]);
                        fill_data(1:8,i) = temp_var(end-7:end);
                        clear temp_var;
                    end
                    output_test = [fill_data(:,:); output(1:end-8,:)];
                    clear fill_data;
                    clear output;
                    output = output_test;
                    clear output_test;
                    
                    % Swap mislabeled HMPs - For 2007--2015:
                    % labeled as    | should be
                    %   abv         | gnd
                    %   gnd         | cpy
                    %   cpy         | abv
                    Ta_abv_orig = output(:,1); RH_abv_orig = output(:,4);
                    Ta_cpy_orig = output(:,2); RH_cpy_orig = output(:,5);
                    Ta_gnd_orig = output(:,3); RH_gnd_orig = output(:,6);
                    output(:,1)=Ta_cpy_orig(:,1);
                    output(:,2)=Ta_gnd_orig(:,1);
                    output(:,3)=Ta_abv_orig(:,1);
                    output(:,4)=RH_cpy_orig(:,1);
                    output(:,5)=RH_gnd_orig(:,1);
                    output(:,6)=RH_abv_orig(:,1);
                    clear *abv_org *gnd_orig *cpy_orig;
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = 100;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2009' % TP39 2009
                    
                    % Bad CO2_cnpy data:
                    output(8940:12240,71) = NaN; % broken
                    output(12241:12762,71) = output(12241:12762,71) + 236; % bad offset
                    
                    % Bad Snow Depth Data:
                    output(9000:17000,31) = 0;
                    
                    % Bad SMA20cm data:
                    bad_pts = [11688 12458 12613 12650:12661 13234:13251 13662 ...
                        13725:13752 13866 13915:13982 14053 14056 14101]';
                    output(bad_pts,93) = NaN;
                    clear bad_pts;
                    
                    % We
                    
                    % Shift data so that it's all in UTC:
                    % need to load last 8 datapoints from 2008
                    
                    for i = 1:1:length(vars30)
                        temp_var = load([load_path site '_2008.' vars30_ext(i,:)]);
                        fill_data(1:8,i) = temp_var(end-7:end);
                        clear temp_var;
                    end
                    output_test = [fill_data(:,:); output(1:704,:); output(713:end,:)];
                    clear fill_data;
                    clear output;
                    output = output_test;
                    clear output_test;
                    
                    % We need to keep 50 datapoints that would otherwise be
                    % removed from RH because they are >100.  If we remove
                    % them, we do not have data for any site at these
                    % times, and therefore, have gaps.
                    find_big = find(output(10810:10969,4)>= 100);
                    output(10810-1+find_big,4) = 100;
                    clear find_big;
                    
                    % Swap mislabeled HMPs - For 2007--2015:
                    % labeled as    | should be
                    %   abv         | gnd
                    %   gnd         | cpy
                    %   cpy         | abv
                    Ta_abv_orig = output(:,1); RH_abv_orig = output(:,4);
                    Ta_cpy_orig = output(:,2); RH_cpy_orig = output(:,5);
                    Ta_gnd_orig = output(:,3); RH_gnd_orig = output(:,6);
                    output(:,1)=Ta_cpy_orig(:,1);
                    output(:,2)=Ta_gnd_orig(:,1);
                    output(:,3)=Ta_abv_orig(:,1);
                    output(:,4)=RH_cpy_orig(:,1);
                    output(:,5)=RH_gnd_orig(:,1);
                    output(:,6)=RH_abv_orig(:,1);
                    clear *abv_org *gnd_orig *cpy_orig;
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = NaN;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2010' % TP39 2010
                    %%% Bad CO2 cpy data:
                    output([1625 4598 5611 6004 6005 6014 8027 15375 16607], 71) = NaN;
                    output([1196 1197 4598 5611 6004 6005 6014 6241 7910], 72) = NaN;
                    output([6005:6013],99) = NaN;
                    output(16840,97) = NaN;
                    % Bad Snow Depth Data:
                    output([3412 3415 9675 9798],31) = NaN;
                    
                    % Swap mislabeled HMPs - For 2007--2015:
                    % labeled as    | should be
                    %   abv         | gnd
                    %   gnd         | cpy
                    %   cpy         | abv
                    Ta_abv_orig = output(:,1); RH_abv_orig = output(:,4);
                    Ta_cpy_orig = output(:,2); RH_cpy_orig = output(:,5);
                    Ta_gnd_orig = output(:,3); RH_gnd_orig = output(:,6);
                    output(:,1)=Ta_cpy_orig(:,1);
                    output(:,2)=Ta_gnd_orig(:,1);
                    output(:,3)=Ta_abv_orig(:,1);
                    output(:,4)=RH_cpy_orig(:,1);
                    output(:,5)=RH_gnd_orig(:,1);
                    output(:,6)=RH_abv_orig(:,1);
                    clear *abv_org *gnd_orig *cpy_orig;
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = NaN;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2011' % TP39 2011
                    % Missing data in all fields
                    output([3905:3910 5109:5116 5661 7078:7083], 1:32) = NaN;
                    % Bad data in some fields
                    output([9601 9602], [1 2 4 28:31]) = NaN;
                    % Bad Up Shortwave Radiation
                    output(3154, 15) = NaN;
                    % Bad Air Temperature at Canopy
                    output(6279, [1 3]) = NaN;
                    % Bad Wind Direction data:
                    output(6281:9595,8) = NaN;
                    % Bad Radiation data:
                    %output(3156:3157,17) = NaN;
                    output(3157:6279,[14:26])= NaN;
                    % Bad SMB100 data
                    output(:,100) = NaN;
                    % Bad SR50 (snow depth) data
                    output([290 699:704 976 1153:1155 1189:1226 1248:1281 1365 1405 1408:1420 2329:2333 2664 2801 2802 2810 3030 3079 3088 3102 3104 3121 3328 3337 3342 3346 3349 3351 3904 3912 5118 9859 9911 ...
                        9918 10111 10131 10159 10171 10417 10542 10555 10559 10595 10620 10635 10838 11144 11737 11824 12667 12669 12683 12892 12927 13012 13085 ...
                        13079 13672 13755 13993 14060 14064 14065 15093 15326 16239 16728 17419 17420 17429 17435], 31) = NaN;
                    % Bad CO2 Canopy
                    output([473 3911 13870:14345],71) = NaN;
                    % Bad soil heat flux data
                    output(15258,69) = NaN;
                    % Bad CO2BLW Canopy
                    output(15694:end,72) = NaN;
                    % Bad RMY rain data
                    output(:,11) = NaN;
                    % Snow Depth Distance Spikes
                    output([11:33 290 699:704 976 1153:1158 1185:1190 1194 1197:1209 1214 1215 1218 1221:1226 1230 ...
                        1248 1252:1281 1365 1374 1387:1389 1393:1395 1405:1420 1724:1726 1729 2035:2044 2084 2329:2333 ...
                        2464 2664 2768 2801 2802 2810 2811 3030 3079 3088 3102:3104 3121 3328 3337 3342:3354 3904:3912 ...
                        5118 9859 9907:9911 9918 9955 10108 10109 10111 10123 10127 10131 10159 10171:10175 10349 10368 ...
                        10369 10417:10419 10452:10456 10464 10512 10542 10554 10555 10559 10595 10620 10635 10838 11144 ...
                        11359 11450:11453 11737:11740 11824 11978 12186 12560:12562 12650:12652 12667:12671 12680:12683 ...
                        12843 12892 12921:12927 13012 13079:13086 13672 13713 13732 13753:13755 13988 13992 13993 14060:14067 14533 ...
                        14960 15019:15029 15093 15326 16239 16720 16728:16744 17339 17419 17420 17427:17447],[27 28]) = NaN;
                    % Set snow depth <0 to zero
                    output(output(:,31)<0,31) = 0;
                    %%% Fill in missing wind direction data with adjusted
                    %%% TP74 Wind direction data:
                    tmp_TP74 = load([loadstart 'Matlab/Data/Met/Final_Cleaned/TP74/TP74_met_cleaned_2011.mat']);
                    WD_TP74 = tmp_TP74.master.data(:,5);
                    tmp_dt = (1:1:17520)'; WD_TP39_estTP74 = NaN.*ones(17520,1);
                    WD_TP39_estTP74(1:3154,1) = WD_TP74(1:3154,1)+27.2;
                    WD_TP39_estTP74(tmp_dt>=1 & tmp_dt<=3154 & WD_TP39_estTP74 >= 360) = ...
                        WD_TP39_estTP74(tmp_dt>=1 & tmp_dt<=3154 & WD_TP39_estTP74 >= 360)-360;
                    WD_TP39_estTP74(3155:9596,1) = WD_TP74(3155:9596,1) +51.9;
                    WD_TP39_estTP74(tmp_dt>=3155 & tmp_dt<=9596 & WD_TP39_estTP74 >= 360) = ...
                        WD_TP39_estTP74(tmp_dt>=3155 & tmp_dt<=9596 & WD_TP39_estTP74 >= 360)-360;
                    WD_TP39_estTP74(9597:end,1) = WD_TP74(9597:end,1) +33.6;
                    WD_TP39_estTP74(tmp_dt>=9597 & tmp_dt<=17520 & WD_TP39_estTP74 >= 360) = ...
                        WD_TP39_estTP74(tmp_dt>=9597 & tmp_dt<=17520 & WD_TP39_estTP74 >= 360)-360;
                    
                    tmp_TP02 = load([loadstart 'Matlab/Data/Met/Final_Cleaned/TP02/TP02_met_cleaned_2011.mat']);
                    WD_TP02 = tmp_TP02.master.data(:,4); WD_TP39_estTP02 = NaN.*ones(17520,1);
                    WD_TP39_estTP02(1:3154,1) = WD_TP02(1:3154,1)+11.4;
                    WD_TP39_estTP02(tmp_dt>=1 & tmp_dt<=3154 & WD_TP39_estTP02 >= 360) = ...
                        WD_TP39_estTP02(tmp_dt>=1 & tmp_dt<=3154 & WD_TP39_estTP02 >= 360)-360;
                    WD_TP39_estTP02(3155:9596,1) = WD_TP02(3155:9596,1) +32.7;
                    WD_TP39_estTP02(tmp_dt>=3155 & tmp_dt<=9596 & WD_TP39_estTP02 >= 360) = ...
                        WD_TP39_estTP02(tmp_dt>=3155 & tmp_dt<=9596 & WD_TP39_estTP02 >= 360)-360;
                    WD_TP39_estTP02(9597:end,1) = WD_TP02(9597:end,1) +15.5;
                    WD_TP39_estTP02(tmp_dt>=9597 & tmp_dt<=17520 & WD_TP39_estTP02 >= 360) = ...
                        WD_TP39_estTP02(tmp_dt>=9597 & tmp_dt<=17520 & WD_TP39_estTP02 >= 360)-360;
                    
                    %                 tmp4 = output(:,8);
                    % Fill the Data: Fill from TP74 first, and then TP02:
                    output(isnan(output(:,8))==1,8) = WD_TP39_estTP74(isnan(output(:,8))==1,1);
                    output(isnan(output(:,8))==1,8) = WD_TP39_estTP02(isnan(output(:,8))==1,1);
                    
                    %
                    %                 figure(80);clf;
                    %                 plot(output(:,8),'r'); hold on;
                    %                 plot(tmp4); hold on;
                    %
                    % clear unneeded variables:
                    clear WD_TP39_estTP74 WD_TP39_estTP02 tmp*
                    
                    % Fill missing CNR1 data with the temporary NR-Lite
                    % data:
                    TP39_NRL = load([loadstart 'Matlab/Data/Met/Final_Cleaned/TP39_NRL/TP39_NRL_met_cleaned_2011.mat']);
                    NRL = TP39_NRL.master.data(:,4);
                    output(isnan(output(:,24)),24) = NRL(isnan(output(:,24)),1);
                    
                    % Swap mislabeled HMPs - For 2007--2015:
                    % labeled as    | should be
                    %   abv         | gnd
                    %   gnd         | cpy
                    %   cpy         | abv
                    Ta_abv_orig = output(:,1); RH_abv_orig = output(:,4);
                    Ta_cpy_orig = output(:,2); RH_cpy_orig = output(:,5);
                    Ta_gnd_orig = output(:,3); RH_gnd_orig = output(:,6);
                    output(:,1)=Ta_cpy_orig(:,1);
                    output(:,2)=Ta_gnd_orig(:,1);
                    output(:,3)=Ta_abv_orig(:,1);
                    output(:,4)=RH_cpy_orig(:,1);
                    output(:,5)=RH_gnd_orig(:,1);
                    output(:,6)=RH_abv_orig(:,1);
                    clear *abv_org *gnd_orig *cpy_orig;
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = NaN;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2012' % TP39 2012
                    % Bad SMB100 data
                    output([1:221 7806:7809 10415:12894 17317],100) = NaN;
                    % Bad SMB50 data
                    output([7805:7809 10416 14562:14575 17316 17317],99) = NaN;
                    % Bad CO2 canopy data
                    output([598:601 6855:6860 1053 10416:10417 16597 16598 17318], 71) = NaN;
                    % Bad SM 20cm A Pit
                    output([7074:7075 8276:10212],93) = NaN;
                    % Bad SM 5cm B Pit
                    output([17316:17317],96) = NaN;
                    % Bad SM 20cm B Pit
                    output([7805:7809 17316:17317],98) = NaN;
                    % Bad CO2 below canopy data
                    output([1:1568],72) = NaN;
                    % Bad RMY Rain data
                    output(:,11) = NaN;
                    % Bad snow temp data
                    output([173 4785 5500 5536 5542 7574 7810 8805 8907 10417],30) = NaN;
                    % Bad 2m NR-Lite data
                    output([766 1076:1078 1468:1471 2190:2192],12) = NaN;
                    % Removal of 2m NR-Lite (sensor stolen)
                    output(9275:end,12) = NaN;
                    % Bad group temp data
                    output([4785 8907],29) = NaN;
                    % Bad snow depth data ***SOMEONE NEEDS TO CLEAN THIS***              
                    output([620:631 768 782 799 910 955 974 996 1001 1036 1109 1220 1223 1340 1404:1408 1423 1434 1441 ...
                        1473 1501 1523 1981 1992 2016 2231 2289 2489 2502 2515 2536 2537 2588 2872 2875 5812 5813 5921 ...
                        5927 9671 10033 10106 10145 10146 10155 10228 10378 10388 10473 10519 10781 10804 10949 10973 11055 ...
                        11691 12083 12101 12255 12301 12307 12567 12753 13822:13832 14030 14072 14082 14085 14090:14092 14096 ...
                        14136 14189 14190 14220 14249 14424 14425 14538 14540 14547 14550 14583 14594 15105 15632 15847 15866 ...
                        15882:15884 16019 16210 16241 16267 16428 16429 16450 16810 16819 16857 17014 17052 17066 17074 17086 ...
                        17369:end],31) = NaN;
                    
                    %%%%%%%%%%%%%%%%%%%% correcting too-low PAR values %%%
                    % using correlation with SW down:
                    PAR_tmp = output(:,9); SWdown_tmp = output(:,14);
                    figure(77);clf; plot(PAR_tmp,SWdown_tmp,'k.');
                    % line of best-fit
                    p = polyfit(SWdown_tmp(~isnan(PAR_tmp+SWdown_tmp)),PAR_tmp(~isnan(PAR_tmp+SWdown_tmp)),1);
                    PAR_pred = polyval(p,SWdown_tmp);
%                     PAR_diffn = (PAR_tmp - PAR_pred)./PAR_pred;
%                     figure(78);plot(PAR_diffn,'k.')
%                     figure(79);clf;plot(PAR_tmp,'b'); hold on; plot(PAR_pred,'r');
                    % fix for the affected period:
                    output(11200:11530,9) = PAR_pred(11200:11530,1);
                     clear PAR_tmp SWdown_tmp PAR_pred p;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    % Offset (0.05) 12568:17568
                    output(12568:17568,[31]) = output(12568:17568,[31])+0.048;
                    
                    % Swap mislabeled HMPs - For 2007--2015:
                    % labeled as    | should be
                    %   abv         | gnd
                    %   gnd         | cpy
                    %   cpy         | abv
                    Ta_abv_orig = output(:,1); RH_abv_orig = output(:,4);
                    Ta_cpy_orig = output(:,2); RH_cpy_orig = output(:,5);
                    Ta_gnd_orig = output(:,3); RH_gnd_orig = output(:,6);
                    output(:,1)=Ta_cpy_orig(:,1);
                    output(:,2)=Ta_gnd_orig(:,1);
                    output(:,3)=Ta_abv_orig(:,1);
                    output(:,4)=RH_cpy_orig(:,1);
                    output(:,5)=RH_gnd_orig(:,1);
                    output(:,6)=RH_abv_orig(:,1);
                    clear *abv_org *gnd_orig *cpy_orig;
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = 100;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2013' % TP39 2013
                    %%% Important Note: all of these data point values refer
                    %%% to those plotted during the first check of the data.
                    %%% The data is time shifted after tehse corrections are
                    %%% made, so data point numbers in the 'final check' may
                    %%% be different.
                    
                    % Bad RMY Rain data
                    output(:,11) = NaN;
                    % Bad 2m NR-Lite
                    output(:,12) = NaN;
                    % Bad ground temp
                    output([7122 8572 9610 9615 10523 13612 13428],29) = NaN;
                    output([1320 1431:1435 1723:1724 4075 5801:5802 7760 8482 8567 9602],71) = NaN;
                    % Bad snow sensor data
                    output(7759,27) = NaN;
                    % Bad snow temp data
                    output([7122 9610 9615 13428],30) = NaN;
                    % Bad snow depth data ***SOMEONE NEEDS TO CLEAN THIS***
                    output([16 19 20 25 26 28 158 362 382 411 412 418 421 425 433:435 439 470 498 828 879 887 1197 1459 ...
                        1879 1900 1903 1944 2053 2444 2447 2467 2473 2475 2530 2637 2734 2824 3262 3268:3276 3292 3305 ...
                        3337 3338 3380 3691 3717 3827 3918 3926 3977 3978 4009 4712 4759 4761 5131 6171 7123 8529:8531 ...
                        8845 9004 9473 9475 9482 9603 9605 10251 10530 10533 10763 11432 11433 11485 11748 15856 16213 ...
                        16504],31) = NaN;
                     
                    % Shift everything the offset? (0.05) 1:17568 ****
                    % Delhi data shows 20 cm December 16th, measured here
                    output(1:17520,[31]) = output(1:17520,[31])+0.05;
                    
                    % Bad tree temperature and snow temperature data (no sensors)
                    output(:,33:64) = NaN;
                    
                    % Bad Soil Heat Flux HFP1 data point
                    output(1557:1560,65) = NaN;
                    % Bad Soil Heat Flux HFP2 data (flatlines/spike)
                    output(6570:16819,66) = NaN;
                    % Bad SHFC1 data
                    output([1351:1356 14365:1437 14359:14362],69) = NaN;
                    % bad CO2 canopy data
                    output([1:5802 7760 8482 8567],71) = NaN;
                    % Bad CO2 below canopy data (no sensor)
                    output(:,72) = NaN;
                    
                    % Bad SM B 50cm data
                    output([1320:1322 1723 13611],99) = NaN;
                    % Bad SM B 100 data
                    output(13611,100) = NaN;
                    
                    %%% Fix time shifts introduced into flux data by computer
                    %%% timing issues (KEEP THESE LINES AT THE END OF FIXES FOR 2013)
                    output = [output(1:4274,:);output(4277:9106,:);NaN.*ones(2,size(output,2));output(9107:12924,:);output(12927:13863,:);...
                        NaN.*ones(2,size(output,2)); output(13864:17520,:)];
                    %
                    % Round 2 of fixes - found issues in the internal data logger clock
                    output = [output(1:4740,:);NaN.*ones(1,size(output,2)); output(4741:5051,:); output(5053:11533,:); output(11535:12119,:);NaN.*ones(1,size(output,2));...
                        output(12120:17520,:)];
                    %                     output = [output(1:4274,:);output(4277:4741,:);NaN.*ones(1,size(output,2));output(4742:5051,:); output(5053:9106,:);NaN.*ones(2,size(output,2));...
                    %                         output(9107:11532,:); output(11534:12118);  output(9107:12924,:);output(12927:13863,:);...
                    %                         NaN.*ones(2,size(output,2)); output(13864:17520,:)];
                    
                    % Swap mislabeled HMPs - For 2007--2015:
                    % labeled as    | should be
                    %   abv         | gnd
                    %   gnd         | cpy
                    %   cpy         | abv
                    Ta_abv_orig = output(:,1); RH_abv_orig = output(:,4);
                    Ta_cpy_orig = output(:,2); RH_cpy_orig = output(:,5);
                    Ta_gnd_orig = output(:,3); RH_gnd_orig = output(:,6);
                    output(:,1)=Ta_cpy_orig(:,1);
                    output(:,2)=Ta_gnd_orig(:,1);
                    output(:,3)=Ta_abv_orig(:,1);
                    output(:,4)=RH_cpy_orig(:,1);
                    output(:,5)=RH_gnd_orig(:,1);
                    output(:,6)=RH_abv_orig(:,1);
                    clear *abv_org *gnd_orig *cpy_orig;
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = 100;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2014' % TP39 2014
                    % Wind sensor not working
                    output(14525:16159,7:8) = NaN;
                    % Up Par in mid-summer not working
                    output(7132:8782,10) = NaN;
                    % Bad RMY Rain data
                    output(:,11) = NaN;
                    % Missing 2m NR-Lite
                    output(:,12) = NaN;
                    % Bad snow depth data
                    output([4109 4905 5635 6185 8782 9116 10892 11719 13387 13894 14571 15485:15487 15494 15504 15505 15507 15529 15537 15737 15781 ],[27:28 31]) = NaN;
                    % Bad ground temp data
                    output([8993 8995 9116 10892 11719],29) = NaN;
                    % Bad snow temp and depth data
                    output([8995 9116 10892 15751],30) = NaN;
                    
                    output(1323,31) = NaN; % Snow depth point
                    
                    % Bad tree temperature and snow temperature data (no sensors)
                    output(:,33:64) = NaN;
                    
                    % Spike in SHF HFP1
                    output([1542 14311 14331],65) = NaN;
                    % Spikes in SHF MV1 and MV2
                    output([1535:1536 1542],67:68) = NaN;
                    % Bad SHFC1 data - Not sure if we need to do this one
                    % (Cal)
                    %output([348 1669],69) = NaN;
                    
                    % bad CO2 canopy data
                    output([323 7091 10122 13874 15778],71) = NaN;
                    % Bad CO2 below canopy data (no sensor)
                    output(:,72) = NaN;
                    
                    % Bad pressure points
                    output(9697:9699,76) = NaN;
                    % Bad SM B 50cm data
                    output([1316:1322 7872:7876 13873:13894 15737:15751 15777:15781],99) = NaN;
                    % Bad SM B 100 data
                    output([7872:7876 11492:11494 13875:13894 15738:15751 15779:15780],100) = NaN;
                    % Soil temperature spikes
                    output(11415,79) = NaN;
                    %%% Fix time shifts introduced into flux data by computer
                    %%% timing issues (KEEP THESE LINES AT THE END OF FIXES FOR 2014)
                    output = [output(1:4276,:);output(4279:14307,:);NaN.*ones(2,size(output,2));output(14308:17520,:)];
                    
                    % Swap mislabeled HMPs - For 2007--2015:
                    % labeled as    | should be
                    %   abv         | gnd
                    %   gnd         | cpy
                    %   cpy         | abv
                    Ta_abv_orig = output(:,1); RH_abv_orig = output(:,4);
                    Ta_cpy_orig = output(:,2); RH_cpy_orig = output(:,5);
                    Ta_gnd_orig = output(:,3); RH_gnd_orig = output(:,6);
                    output(:,1)=Ta_cpy_orig(:,1);
                    output(:,2)=Ta_gnd_orig(:,1);
                    output(:,3)=Ta_abv_orig(:,1);
                    output(:,4)=RH_cpy_orig(:,1);
                    output(:,5)=RH_gnd_orig(:,1);
                    output(:,6)=RH_abv_orig(:,1);
                    clear *abv_org *gnd_orig *cpy_orig;
                    
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = 100;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2015' % TP39 2015
                    % Bad Ta points
                    output([6906 8615:8623 11508:11509 12365],1) = NaN;
                    output([8691:8787],2) = NaN;
                    output([8617:8737],3) = NaN;
                    
                    % Bad snow depth data
                    output([396 404 417 419 422 470 472 474 4670 4790 8320 8534 9016 10652 11746 11934 12922 12927 12923 12932 12983 14487 14503],27:28) = NaN;
                    output([7251 8615 8616 8623 10652 11508:12365 12926 14487],28) = NaN;
                    output([396 404 417 419 422 470 472 474 4670 8615:8623 11508:12365 12922 12927 12923 12932 12983 14503 15159],31) = NaN;
                    
                    % Bad ground and snow temp
                    output([7251 8320 8534 8615:8623 9016 10652 11507:11509 12365 11934 12922 12927 12923 12932 12983 14487],29:30) = NaN;
                    
                    %%% Fix Gain and Offset errors in RHdata (column 4) data after point 12365
                    mean_RH1 = nanmean(output(1:12365,4)); std_RH1 = nanstd(output(8000:12365,4));
                    mean_RH2 = nanmean(output(12366:17520,4));std_RH2 = nanstd(output(12366:17520,4));
                    tmp1 = output(1:12365,4); tmp2 = output(12366:17520,4);
                    tmp2 = tmp2 - (mean_RH2 - mean_RH1); % correct offset;
                    tmp2_dev = tmp2-nanmean(tmp2);
                    tmp2_adj = tmp2_dev.*(std_RH1./std_RH2) + nanmean(tmp2); % correct gain error.
                    output(:,4) = [tmp1; tmp2_adj];
                    clear tmp* mean_* std_*
                    
                    % Bad soil heat flux cal
                    output([14487:14490],69:70) = NaN;
                    
                    % Bad CO2 cnpy
                    output([4687 5309 5310 7251 7808 8623 9014:9016 12922 12923 12927 12932 12983 14487],71) = NaN;
                    % Bad Pressure data
                    output([2265:2816 2821 2917 3251 3252 3389 4356 4793 4974 4991 6129:6192 6390:6413 6688:7809 9732:10432 10913:10943 11012 11493:1150 15660:15824],76) = NaN;
                    % N2 tank pressure
                    output([3044],77) = NaN;                    
                    % Soil temp B 2 cm
                    output([15159],90) = NaN;                    
                    % Bad SM B 5cm
                    output([9012:9015],96) = NaN;
                    % Bad SM B 20cm + 50cm
                    output([7248:7250 9012:9015 ],98:99) = NaN;
                    output([11745],[98 99]) = NaN;
                    output([7248:7250 15159],98:100) = NaN;                    
                    % Bad SM B 100cm
                    output([7249 7250 9013:9015],100) = NaN;                    
                    
                    %%% Fix time shifts introduced into flux data by computer
                    %%% timing issues (KEEP THESE LINES AT THE END OF FIXES FOR 2015)
                    output = [output(1:4178,:);output(4181:11124,:);NaN.*ones(2,size(output,2));output(11125:17520,:)];
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Wind speed (col 7) is bad from ~5650 onwards -- the bearing had broken
                    % Need to fix it by replacement with CSAT data:
                    ws = output(:,7);
                    ws(5651:16393) = NaN; % bearing started to wear out after this point. Replaced on Dec 8(~16393)
                    CPEC = load([loadstart 'Matlab/Data/Flux/CPEC/TP39/Final_Cleaned/TP39_CPEC_cleaned_2015.mat']);
                    u = CPEC.master.data(:,19);v = CPEC.master.data(:,20);
                    WS_CPEC = sqrt(u.^2 + v.^2);
                    p = polyfit(ws(~isnan(ws.*WS_CPEC)),WS_CPEC(~isnan(ws.*WS_CPEC)),1);
                    WS_CPEC_corr = WS_CPEC;
                    ws(isnan(ws),1) = WS_CPEC_corr(isnan(ws),1);
                    ws(ws<0) = 0;
                    output(:,7) = ws;
                    clear u v ws p WS*;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Swap mislabeled HMPs - For 2007--2015:
                    % labeled as    | should be
                    %   abv         | gnd
                    %   gnd         | cpy
                    %   cpy         | abv
                    Ta_abv_orig = output(:,1); RH_abv_orig = output(:,4);
                    Ta_cpy_orig = output(:,2); RH_cpy_orig = output(:,5);
                    Ta_gnd_orig = output(:,3); RH_gnd_orig = output(:,6);
                    output(:,1)=Ta_cpy_orig(:,1);
                    output(:,2)=Ta_gnd_orig(:,1);
                    output(:,3)=Ta_abv_orig(:,1);
                    output(:,4)=RH_cpy_orig(:,1);
                    output(:,5)=RH_gnd_orig(:,1);
                    output(:,6)=RH_abv_orig(:,1);
                    clear *abv_org *gnd_orig *cpy_orig;
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = 100;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2016' % TP39 2016
                    % Remove bad RH_cpy 
                    output(6095:8089,5) = NaN;
                    % Air Temp below canopy
                    output([177 3922 6091 6273 6376],1:6) = NaN;
                    % Wind Speed & Dir of Zero Removed
                    output([1898:1900 2933:3109 3841 6081:6088 9910 13427 13738 17330:17337],7:8) = NaN;
                    % Panel Temp dip
                    output([2767:2777],13) = NaN;
                    output([2767:2777],78) = NaN;
                    % Upward Shortwave Rad
                    output([2925:2941],15) = NaN;
                    % Upward Longwave Rad
                    output([5994 5995],17) = NaN;
                    % Bad snow depth data
                    output([99 107 126 131 253 393 415 553 1453 2777 3687 3922 4206 4211 4256 5793 6090 6273],27:28) = NaN;
                    output([106],28) = NaN;
                    output([99 106 107 126 131 253 393 415 553 2620 3919 3922 4206 4211 4256 6090 6273 14528],31) = NaN;
                    % Ground and Snow Temp
                    output([4206 4211 6273 10046 10991],29:30) = NaN;
                    % Soil Heat Flux H1
                    output(17323:17334,[65 67]) = NaN;
                    % Soil Heat Flux Cal
                    output([2118:2418 6374:6378],69) = NaN;
                    % CO2 canopy dips
                    output([1960 2620 4210 6765 13228 13459],71) = NaN;
                    % Down PAR
                    output([5466 5651 5658 5794 5947 5985 6080],75) = NaN;
                    % Pressure
                    output([852:1572 2768:3132 3461:3530 3918 5983 12222],76) = NaN;
                    % SM B 50 cm
                    output([10984:10985 13228],99) = NaN;
                    % SM B 100 cm
                    output([2374 2380 17333:17335],100) = NaN;
                    % Swap mislabeled HMPs - For 2007--2016:
                    % labeled as    | should be
                    %   abv         | gnd
                    %   gnd         | cpy
                    %   cpy         | abv
                    Ta_abv_orig = output(:,1); RH_abv_orig = output(:,4);
                    Ta_cpy_orig = output(:,2); RH_cpy_orig = output(:,5);
                    Ta_gnd_orig = output(:,3); RH_gnd_orig = output(:,6);
                    output(:,1)=Ta_cpy_orig(:,1);
                    output(:,2)=Ta_gnd_orig(:,1);
                    output(:,3)=Ta_abv_orig(:,1);
                    output(:,4)=RH_cpy_orig(:,1);
                    output(:,5)=RH_gnd_orig(:,1);
                    output(:,6)=RH_abv_orig(:,1);
                    clear *abv_org *gnd_orig *cpy_orig;
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = 100;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2017' % TP39 2017
                    % Panel Temp Dips
                    output([1568 2096:2099 3104 3250:3255 15632:15635 16214:16218 16276:16279],13) = NaN;
                    % Up Longwave Below Canopy
                    output([8628],17) = NaN;
                    % Net Longwave Abv Canopy
                    output([1208 2817],[22 23]) = NaN;
                    % Bad snow depth data
                    output([491 1620 3248 3992 7108 13822 14209 15556 16276],[27 28 30 31]) = NaN;
                    % Ground Temp Outliers
                    output([3992 13822 14209],29) = NaN;
                    % Soil Heat Flux HFP
                    output([3248:3260 5764:5766 10710:10712],[65 66]) = NaN;
                    % Soil Heat Flux Cal 1
                    output([289:300 480 703:732 798 10333 10338],69) = NaN;
                    % Soil Heat Flux Cal 2
                    output([265:480 685:697 2281:2304 10333:10338 10363:10368],70) = NaN;
                    % CO2 Canopy Spikes
                    output([3205 3248 8919 10490 14209 14726 15556 16214],71) = NaN;
                    % Down PAR Below Canopy
                    output([38 278 3018 3834 3871 4694 4973 6171],75) = NaN;
                    % Panel Temperature
                    output([2096:2098 3205:3252],78) = NaN;
                    % Soil Temperature A 2cm
                    output([10711:10764],79) = NaN;
                    % Soil Temperature B 2cm
                    output([13822 15556],90) = NaN;
                    % Soil Temperature A 50 cm
                    output(9340:17520,80) = NaN;
                    % SM A 20cm
                    output([9950:17520],93) = NaN;
                    % SM B 5cm, 20cm, 50cm
                    output([13815 13816 14208 16275],[96 98 99]) = NaN;
                    % SM B 100cm
                    output([1:11699 13815 13816 14208 16275],100) = NaN;
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = 100;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2018' % TP39 2018
                    % Panel Temp Dips     
                    output([225:233 463:471 896 897 2144:2150 2889:2899 3200:3208 4493:4524 4995:5003 5029:5038 ...
                        13779 13949:13955 14881:14884 15160:15164 15923:15929 16495:16499],13) = NaN;
                    % Longwave (Down & Net)
                    output([6554 11707],[18 22]) = NaN;                                       
                    % Snow Depth Distance
                    output([4469 4493 4513 5029 5947 12675 13761 13779 14071 14091 14881],[27 28 30]) = NaN;
                    % Ground Temp
                    output([4469 4513 5029 5947 12675],29) = NaN;
                    % Soil Heat Flux Cal 1
                    output([7249:7254],69) = NaN;
                    % CO2 Canopy Spikes
                    output([2768 2889:2892 3882 4927 6186 8153 11366 14917 16497],71) = NaN;  
                    % Down PAR below canopy
                    output([6517 6565 6613 16886],75) = NaN;  
                    % Ts50A - incorrect values all year. Removing, but can change to an offset correction if a value can be found
                    output(:,80) = NaN;  
                    % Ts2A - bad data for ~20 data points. Really high spike.
                    output(10533:10559,79) = NaN;
                    % SM20A - Removing all values. Sensor appears broken
                    output(:,93) = NaN; 
                    % Set whether RH > 100 should be set to 100 or NaN:
                    RH_max = 100;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                case '2019' % TP39 2019
                    %%%% PAR DOWN corrections, related to the intercomparison
                    %%%% project that was run at the site from 20190829 to
                    %%%% 20191024. 
                    % Data should be inserted at 20190829 19:30 UTC
                     [PAR_comp_H, PAR_comp_C] = read_textfile_with_headers([loadstart 'Matlab/Data/Met/Raw1/TP39/2019/TP39_PAR_Comparison_20190829-20191024.csv'],',',4);
                    rt_col = find(strcmp(PAR_comp_H(:,2),'TP39_DN_umol_Avg')==1);
                    PAR_to_fill = str2double(PAR_comp_C(:,rt_col));
                    % Correct using the scaling function that Keegan
                    % supplied. Note that this is not perfect--the
                    % datalogger calculation is non-linear, meaning that the parameters need to be changed in the system!!!! 
                    output(11559:11559+size(PAR_to_fill,1)-1,9) = PAR_to_fill./1.127 + (4.585/1.127);
                    clear PAR_comp* PAR_to_fill rt_col
%                     % There's a difference between the value that was
%                     % collected in the CR23x vs the CR1000 when the sensor
%                     % was spliced. 
%                     figure(30);clf;
%                     plot(input_data(11850:12170,9),'b');
%                     hold on;
%                     plot(output(11850:12170,9),'r');
%                     p_PAR1 = polyfit(input_data(11850:12170,9),output(11850:12170,9),1); % Gives us: 0.9804, -0.6064
%                     PAR_corr = output(11850:12170,9)./1.127 + (4.585/1.127);
%                     plot(PAR_corr,'g');
%                     %%%%%%%%%%%%%%%%%%%%%%%
%                     
%                     %%%% Figure out how to correct magnitude of new sensor
%                     %%%% at TP39. It's way too high. Must be a multiplier
%                     %%%% issue.
%                     % Plot original PAR_DN sensor (from intercomp
%                     % experiment) vs new refurbished sensor
%                     PAR_refurb1 = str2double(PAR_comp_C(:,8)); 
%                     
%                     figure(31);clf;
%                     plot(PAR_to_fill,PAR_refurb1,'k.');
%                     p_PAR = polyfit(PAR_to_fill,PAR_refurb1,1); % Gives us: 0.9804, -0.6064
%                     % new sensor corrected by regression shared by Keegan:                    
%                     tmp_PAR = output(14242:end,9)./1.127 + (4.585/1.127);
%                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
					%%% Correct the PAR down values by comparing the regression equations between SW and PAR for the pre- and post- rewiring periods
					% The following coefficients are calculated in /Diagnostic/TP39_par_correction_factor.m
                    p_SW_PAR = [2.02204246046177	-1.26137100579115]; % slope and intercept of SWdown - PARdown relationship for 2017 and 2018.
					PARdn = output(:,9);
					SWdn = output(:,14);
                    
                    SWdn_b = SWdn(1:14242); PARdn_b = PARdn(1:14242); 
					p1 = polyfit(SWdn_b(~isnan(SWdn_b.*PARdn_b),1),PARdn_b(~isnan(SWdn_b.*PARdn_b),1),1);
                    SWdn_a = SWdn(14250:end); PARdn_a = PARdn(14250:end); 
					p2 = polyfit(SWdn_a(~isnan(SWdn_a.*PARdn_a),1),PARdn_a(~isnan(SWdn_a.*PARdn_a),1),1);
					% According to this test, p1 (before re-wiring the PARdn sensor) coefficients are [1.960128445238033,1.224844308758671]
					%						p2 (after re-wiring the sensor) coefficients are [3.687950947587812,6.966335856351974];
					PAR_corr = PARdn; 
					PAR_corr(14242:end) = (p1(1).*PARdn(14242:end))./p2(1) - (p1(1).*p1(2))./p2(1) + p1(2);
					% PAR_corr(14242:end) = (p2(1).*PARdn(14242:end))./p1(1) - (p2(1).*p2(2))./p2(2) + p1(2);
					%figure(14); clf;
					%plot(PARdn,'b'); hold on; 
					%plot(PAR_corr,'r'); 
					output(:,9) = PAR_corr; 
					clear p_SW_PAR p1 p2 SWd* PARd* PAR_corr; 
                    %%%%%%%%%%%%%%%%%%%%%
                    
                    % Remove PAR_UP during intercomparison period
                    output(11559:14242,10)= NaN;
                    output(10022,11) = NaN;
                    
                    
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                    % bad wind data
                    output([1757:1824 16065:16197],[7,8]) = NaN;
                    
                    % Bad NetRad BlwCnpy
                    output(:,12) = NaN;
                    
                    % Remove bad Net LW AbvCnpy
                    output(11844:14859,[22,23]) = NaN;
                    
                    output([14860],24) = NaN;
                    output([6843 8595 8673 9591 9663 14861],29) = NaN;
                    output([6843 8673 9591 9663 14861],30) = NaN;
                    
                    % Bad snow depth data
                    tmp_snow = output(:,31);
                    ind_snow = find(tmp_snow(4000:16000) > 0.025);
                    output(ind_snow+3999,31) = NaN;
                    clear tmp_snow ind_snow;
                    
                    output([3115 4880 11510 14598],71) = NaN;
                    
                    % bad soil data
                    output(10539:10546,79) = NaN;
                    output(:,93) = NaN;
                    
                    output([7376],99) = NaN;
                    RH_max = 100; 
				
				case '2020' % TP39 2020
                    RH_max = 100;
				%%% Proactively correct PAR down data that is not scaled
				%%% properly -- Updated by JJB on 2021-03-07
					% According to this test, p1 (before re-wiring the PARdn sensor) coefficients are [1.960128445238033,1.224844308758671]
					%						p2 (after re-wiring the sensor) coefficients are [3.687950947587812,6.966335856351974];
				p1 = [1.960128445238033,1.224844308758671]; p2 = [3.687950947587812,6.966335856351974];
					PAR_corr = output(1:10549,9); 
					PAR_corr(1:end) = (p1(1).*PAR_corr(1:end))./p2(1) - (p1(1).*p1(2))./p2(1) + p1(2);
					output(1:10549,9) = PAR_corr; 
					clear p1 p2 PAR_corr; 
                    
                    output([10540 5212:5213],10) = NaN;
                    output(:,11) = NaN; % removing all RMY Rain
                    output(:,12) = NaN; % removing all NetRadBlwCnpy
                    output([522:523 11747],18) = NaN;
                    output([1292 12027],25) = NaN; %spikes in albedo
                    output([856 1226 4269 8298 10552 11514 11648 16152 17240 17245],[27 28]) = NaN;%snow depth
                    output([4269 8298 897 10552 11514 11648],[29 30]) = NaN; %ground temp
                    output(11485,31) = NaN;
                    
                    %soil heat flux bad data
                    output([4796 4800],66) = NaN;
                    output([856:858 4269:4272 6459:6462 14502 14947:14952 8292:8298 11388:11394 11648:11652 15351:15372],[69 70]) = NaN;
                    
                    output([11460 14346 15347:15370 15824],71) = NaN; %canopy Co2
                    %%%%% Pressure
                    output([4132:4154 4255:4559 4755:4821 5478:5584 5778:5792 5803:5804 5933:5939 8885:8973 9097:9785 11112:11113 10545:10552 12665 12669 13217:13293 14521],76) = NaN; %pressure
                    % Fix offset in pressure toward end of year
                    output(16550:end,76) = output(16550:end,76) + (output(16549,76)-output(16550,76));
                    
                    % Invert sign for LW BC Up- and Down-welling
%                     output(:,[16,17]) = output(:,[16,17]).*-1;
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                    
                    output([11390:11485],79) = NaN; %bad soil temp data
                    output(11485,[83 87 91 92 96 97]) = NaN; %soil temp and moisture spike
                    output(:,93) = NaN; % Remove all SM_A_20cm
               
                case '2021' % TP39 2021   
                    RH_max = 100;
                    
                    %%%%% Fix offset (lower magnitude) values for PAR in
                    %%%%% 2021 by correcting to equal 2019 magnitudes
                    TP39_2018_tmp = load([loadstart 'Matlab\Data\Met\Final_Cleaned\TP39\TP39_met_cleaned_2018']);
                    TP39_2018_tmp_PAR = TP39_2018_tmp.master.data(:,9);
                    top_5000_2018 = sort(TP39_2018_tmp_PAR,'descend','MissingPlacement','last'); top_5000_2018 = top_5000_2018(1:2500);
                    top_5000_current = sort(output(:,9),'descend','MissingPlacement','last');top_5000_current = top_5000_current(1:2500);
%                     figure(89);clf
%                     plot(top_5000_2018,top_5000_current,'k.');
%                     hold on; 
%                     plot([200 2500],[200 2500],'r--');
%                     ylabel('2023'); xlabel('2018');
%                     p = median(top_5000_2018)./median(top_5000_current); 
                    p2 = polyfit(top_5000_current,top_5000_2018,1);
                    output(output(:,9)>900,9) = polyval(p2,output(output(:,9)>900,9));
                    
                    
                    
                    
                    
                    
                    %AirTempAbvCnpt spike
                    output([11660 11663 11666],1) = NaN;
                    %AirTempCnpy spike
                    output([11660 11663 11666],2) = NaN;
                    %AirTempBlwCnpy spike
                    output([11662 11666],3) = NaN;
                    %RelHumBlwCnpy 
                    output([11660],6) = NaN;
                    %UpPARAbvCnpy spike
%                     output([848 1904 5308],10) = NaN; % JJB: I don't
%                     believe these are spikes.
                    output(:,11) = NaN; % No RMY_Rain data
                    output(:,12) = NaN; % removing all NetRadBlwCnpy

                    %GroundTemp spike
                    output([6225 7087 10200 10690 12280 13860 15460],29) = NaN;
                    %SnowTemp
                    output([6225 10200 13860 15460],30) = NaN;
                    %%%%% Pressure
                    output([1:2892 3447:4217],76) = NaN; %pressure
                    output(:,93) = NaN; % Remove all SM_A_20cm
             
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;

                 case '2022' % TP39 2022; EAR, LL & NH
                    RH_max = 100;
                    output([2195],9) = NaN;
                    output([7331 7709],11) = NaN;
                    output(:,12) = NaN;
                    output([671 5313],13) = NaN;
                    output([2320 2381 5363 6494 7332 7333 7431 7680 7681 7709 10388:10389 11224 12500 15478 15480 15492 15529 17120:17122 17163:17177 17226],27) = NaN;
                    output([2320 2381 5363 6494 7332 7333 7431 7680 7681 7709 10388:10390 11220 12500 15478 15480 15492 15529 17120:17122 17163:17177 17226],28) = NaN; 
                    output([2320 2381 5363 6494 7332 7333 7431 7680 7681 7709 10388:10390 11224 12500 15201 15478 15480 15492 15529 17226],29) = NaN;
                    output([2320 2381 5363 6494 7332 7333 7431 7680 7681 7709 10388:10390 12500 15201],30) = NaN; 
                    output([1650 2320 2374:2381 2398 2413 2414 15419:15420 15478 15480 15492 15505 15529:15531 15539 17121 17139 17164:17165 17174 17176 17182:17183 17226 17269 17287:17288],31) = NaN;
                    output([7331 7709],32) = NaN;
                    output([10980:10984 11697 13962 17200:17300],71) = NaN;
                    output([2433 10980],73) = NaN;
                    output([2433 9834 10980:10984 17269:17290 17310:17330],74) = NaN;
                    output([2433 9834 10980:17520],75) = NaN;
%                     output([5313 5363 7711 16190 17230],78) = NaN;
                    output([17270:17340],79) = NaN;
                    output([9824 9834:9835 10264:10272 11165:11171 11283 11541 17269:17357],80) = NaN;
                    output([17269:17337],81) = NaN;
                    output([17269:17359],82) = NaN;
                    output([10271 17269:17360],83) = NaN;
                    output([7994 10266:10277 10982 11283 11803:11805 17269:17359],84) = NaN;
                    output([9824 9834 10269:10271 10937 11283:11285 17269:17359],85) = NaN;
                    output([9823:9824 9834:9835 10266:10273 11283 17269:17359],86) = NaN;
                    output([9824 9834 10266:10273 17269:17335],87) = NaN;
                    output([9824 9834 10266:10278 17269:17360],88) = NaN;
                    output([10266:10273 17135 17269:17335],89) = NaN;
                    output([10266:10273 17135 17269:17340],90) = NaN;
                    output(:,93) = NaN;
                    output([1:1542 11695:11697],100) = NaN;
                    
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                    
                    % 2024-04-28: Try to fix wind data by swapping in u_rot from CPEC data
                    u_rot = csvread([loadstart 'Matlab/Data/Flux/CPEC/TP39/Final_Cleaned/TP39_2022.u_rot']);
%                     figure(56); clf;
%                     plot(output(:,7)); hold on;
%                     plot(u_rot,'r');
                    output(4379:end,7) = u_rot(4379:end,1);
                    clear u_rot;
                                        %%%%% Fix offset (lower magnitude) values for PAR in
                    %%%%% 2022 by correcting to equal 2018 magnitudes
                    TP39_2018_tmp = load([loadstart 'Matlab\Data\Met\Final_Cleaned\TP39\TP39_met_cleaned_2018']);
                    TP39_2018_tmp_PAR = TP39_2018_tmp.master.data(:,9);
                    top_5000_2018 = sort(TP39_2018_tmp_PAR,'descend','MissingPlacement','last'); top_5000_2018 = top_5000_2018(1:2500);
                    top_5000_current = sort(output(:,9),'descend','MissingPlacement','last');top_5000_current = top_5000_current(1:2500);
%                     figure(89);clf
%                     plot(top_5000_2018,top_5000_current,'k.');
%                     hold on; 
%                     plot([200 2500],[200 2500],'r--');
%                     ylabel('2023'); xlabel('2018');
%                     p = median(top_5000_2018)./median(top_5000_current); 
                    p2 = polyfit(top_5000_current,top_5000_2018,1);
                    output(output(:,9)>900,9) = polyval(p2,output(output(:,9)>900,9));
                    
                 case '2023' % TP39 2023  EAR
                    RH_max = 100;
                    output([15102],1) = NaN;
                    output([15102],2) = NaN;
                    output([15102],3) = NaN;
                    output([7009:14867],[7,8]) = NaN; % Bad wind data; prev start: 7720
                    % 2024-04-28: Try to fix wind data by swapping in u_rot from CPEC data
                    u_rot = csvread([loadstart 'Matlab/Data/Flux/CPEC/TP39/Final_Cleaned/TP39_2023.u_rot']);
%                     figure(56); clf;
%                     plot(output(:,7)); hold on;
%                     plot(u_rot,'r');
                    output(1:14867,7) = u_rot(1:14867,1);
                    clear u_rot
                    
                    
                    % 2024-07-21: Try to fill in bad Wind Direction data
                    % from TP74, TP02: 
                    tmp_TP74 = load([loadstart 'Matlab/Data/Met/Final_Cleaned/TP74/TP74_met_cleaned_2023.mat']);
                    WD_TP74 = tmp_TP74.master.data(:,5);
                    
                    figure(66); 
                    plot(WD_TP74); hold on;
                    plot(output(:,8),'r');
                    output(isnan(output(1:14870,8)),8) = WD_TP74(isnan(output(1:14870,8)),1);
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    output(13745:end,9) = NaN; % Remove PAR values at end of year. Something is wrong.
                    
                    output([1088 3150 3345 3347 15102],10) = NaN;
                    output([1:end],11) = NaN;
                    output([1:end],12) = NaN;
                    output([15102],14) = NaN;
                    output([1080 3151 12750 15102],15) = NaN;
                    output([15102],19) = NaN;
                    output([15102],20) = NaN;
                    output([15102],21) = NaN;%NetShortwaveRaAbvCnpy
                    output([14867 14979 15102 17394],22) = NaN;%NetLongwaveAboveCnpy
                    output([15102],24) = NaN;
                    output([15102],25) = NaN;%Albedo
                    output([15102],26) = NaN;
                    output([1927 2599 5526 6252 15102 16220 ],27) = NaN;
                    output([1927 2598 2726 2989 3306 5528 6252 9645 11501 12208 16211 16235],28) = NaN;
                    output([15102],29) = NaN;%GroundTemp
                    output([1927 2599 2982 5526 6252 11261 11335 12019 12030:12031 12130 12122 15102 16220],30) = NaN;%SnowTemp
                    output([2594:2599 2982 3306 5526:5528 11017:11022 11261 11335 12016 11966 12019 12030:12031 12122 15102 16220 16636 17298],31) = NaN;%SnowDepth
                    output([2984 8065:16558],65) = NaN;%SoilHeatFluxHFP1
                    output([2984 8005:16558],66) = NaN;
                    output([2984 5609 8065:16558],67) = NaN;
                    output([2984 3974 5609 4741 4789 4885 4933 4981 5077 8065:16558],68) = NaN;
                    output([1213:1218 1645:1729 1927:1932 2593:2604 2726:2730 2982:2994 4027:4029 4076:4080 4331:4332 5526 6252 7991:7992 8065:16558 17298],69) = NaN;
                    output([1213:1218 1627:1632 1927:1932 2593:2604 2726:2730 2982 2989:2994 4027:4029 4331:4332 5526 5695:5706 6252 6691:6720 7991:7992 8065:16558 17298],70) = NaN;
%                     output([1213 1927 2594:2597 2982:2989 4076 5693:5701 6252 7002:7008 7154:16558],71) = NaN;%CO2Cnpy
                    output(:,71) = NaN; % CO2_cpy
                    %output([2982 2984 8060:16560],73) = NaN;
                    % Try to remove offset error with SoilHeatFlux_HFT1 (column 73)
%                     output([8060:16556],73) = output([8060:16556],73) - (output(8060,73) - output(8059,73));
%                     % Try to remove offset error with SoilHeatFlux_HFT2 (column 74)
%                     output([8060:16556],74) = output([8060:16556],74) - (output(8060,74) - output(8059,74));
                    output(8060:end,[73,74]) = NaN; % bad SHF data

%                   output([2982 2984 8060:16560],74) = NaN;
%                   output([1:1922 2258:2551 2983 8060:16560],75) = NaN;
%                     output([1:16558],75) = NaN;
                    output(:,75) = NaN;
                    output([16939:end],76) = NaN;%Pressure
                    output([1348:1358 1370:1381 1418:1420 1433:1447 2982 3692 3748 5659:5672 5691:5701 5718 5737:5744 5836:5840],79) = NaN;
%                   output([1352:1358 1376 1439:1445 2982 3678:3679 3692 3699 5658:5670 5689:5703 5718 5737:5745 5802 5810 5834:5842 5853 5858 5876 5885 5901 5947 6252 7055 7081 8008 17080],80) = NaN;
                    output(:,80) = NaN;
                    output([1349:1355 1367 1376 1380 1391 1433 1438:1445 2982 3634 3678 3693 3699:3700 3725 3706 3748],81) = NaN;
                    output([1352 1364 1376 1382 1391 1418:1423 1433 1440:1445 2982 3634 3678 3684 3685 3706 5651 5658:5670 5675 5692:5705 5710 5718 5725 5734:5744 5765 5806 5838:5860 5887:5894 5977],82) = NaN;
                    output([1348:1359 1364 1369 1374:1381 1391 1417:1421 1433 1445 2982 3678:3685 3699:3707 3722],83) = NaN;
                    output([1348:1356 1370:1382 1415:1418 1423 1438:1444 1449 2982 2984 3678 3693 3700 3706 3748 3932 3936 4445 5658:5671 5685:5719 5738:5750 5763:5765 5806 5835:5844 5852:5860 5886:5889 5932 5950:5952 5968 5977],84) = NaN;
                    output([1348:1354 1366 1376 1396 1415 1418 1437:1444 2982 3678 3699 3701 3725 3748 3986 5637 5650:5667 5689:5711 5736:5751 5805:5809 5828:5859 5876 5887:5895 5947 5977],85) = NaN;
                    output([1348:1455 2982 3634 3678 3679 3692 3699 3701 3886 5649:5670 5689:5749 5765 5834:5861 5887:5897 5931:5948 5977],86) = NaN;
                    output([1347:1382 1417:1421 1433 1437:1443 2982],87) = NaN;
                    output([1346:1451 1951 2379 2982 3678 3694 3699 3700],88) = NaN;
                    output([1213:1449 2982 3678 3696:3701 3725 3733:3738],89) = NaN;
                    output([1213:1447 3678 3699],90) = NaN;
                    output([1:end],93) = NaN;
                    output([7756:9113 10069:10096 11379:11419 15617:15681],94) = NaN;
                    output([2593 8765],96) = NaN;
                    output([2593],98) = NaN;
                    output([2593],99) = NaN;
                    output([],100) = NaN;
                    
                    % Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                                        %%%%% Fix offset (lower magnitude) values for PAR in
                    %%%%% 2023 by correcting to equal 2019 magnitudes
                    TP39_2018_tmp = load([loadstart 'Matlab\Data\Met\Final_Cleaned\TP39\TP39_met_cleaned_2018']);
                    TP39_2018_tmp_PAR = TP39_2018_tmp.master.data(:,9);
                    top_5000_2018 = sort(TP39_2018_tmp_PAR,'descend','MissingPlacement','last'); top_5000_2018 = top_5000_2018(1:2500);
                    top_5000_current = sort(output(:,9),'descend','MissingPlacement','last');top_5000_current = top_5000_current(1:2500);
%                     figure(89);clf
%                     plot(top_5000_2018,top_5000_current,'k.');
%                     hold on; 
%                     plot([200 2500],[200 2500],'r--');
%                     ylabel('2023'); xlabel('2018');
%                     p = median(top_5000_2018)./median(top_5000_current); 
                    p2 = polyfit(top_5000_current,top_5000_2018,1);
                    output(output(:,9)>900,9) = polyval(p2,output(output(:,9)>900,9));
                    
                    %%% Attempt to smooth TS 5cm data cols (83 and 89)
%                     Ts5_a = smoothdata(output(:,89),20);
%                     Ts5_b = smoothdata(output(:,89),'rlowess',20);
%                     Ts5_c = smoothdata(output(:,89),'rloess',20);
%                     Ts5a_smooth = smoothdata(output(:,83),'sgolay',20);
%                     Ts5b_smooth = smoothdata(output(:,89),'sgolay',20);
                    %%% Smooth all soil pit data using the smoothdata
                    %%% function
                    for m = 79:1:90
                        output(:,m) = smoothdata(output(:,m),'sgolay',20);
%                         output(:,m) = Ts_smooth;
                    end
%                     figure(48);clf;
%                     plot(output(:,83),'b'); hold on;
%                     plot(output(:,89),'r'); hold on;
% %                     plot(Ts5_a,'r');
%                     plot(Ts5a_smooth,'k');
%                     plot(Ts5b_smooth,'m');

%                     output(:,83) = Ts5a_smooth;
%                     output(:,89) = Ts5b_smooth;
                    
                    clear Ts5a_smooth clear Ts5b_smooth 
                case '2024'% TP39 2024 %Abdullah %AH
                    % REVIEW THIS: Invert sign for LW BC Up- and Down-welling
                    output(:,[16,17]) = output(:,[16,17]).*-1;
                    RH_max = 100;
                    output([1:end],12) = NaN;
                    output([9646:9649 12330],18) = NaN;
                    output([1232 5483 9646:9648],22) = NaN;%Net Longwve Abve cnpy
                    output([1232 9646:9648 11900],23) = NaN;
                    output([2556:2561 4573 6636:6637 7554 10513 13242],25) = NaN;%Abdullah
                    output([16570 2973 8537 16864 16869 17228 17324 12807 15738 15974:15976],25) = NaN;%AH
                    output([632 633 782 797 805 897 1206 1207 1290 1322 1323 2198 3248 3256 3257 3372 3925 3946 4329 4407 5135 5161 5162 5226 5305 5306 5316 5320 5379:5381 5608 5609 6482 6541 6859 6967 7687 7723 8220 8430 9546 9726 9985 10036 10042 10127 13209 13423 15324 16016 15354],27) = NaN;
                    output([672 806 1290 1321:1331 2316 2320 3925 3924 3946 4250 4329 4407 5219 5660 5134:5135 5158 5161:5162 5178:5179 5222 5225:5227 5660 5407 5453:5454 5380 5458 6514:6515 6534 6541 6560 6577 6600 6608 8220 8108 8145:8147 8151 8491 8638 8702 8786 8819:8820 8822 8857 8932:8933 8944:8945 8948:8949 8982:8983 9007 9063 9106:9108 9128:9129 9188 9546 9624 9684:9685 9726 9981 9985 9988:9989 10034 10042 10066 10548 10502 10497 10290 10550 10558 10573 10671 10611 10699:10700 11524 11526 11561 11697 13209 13426 15167 15174 15354 16016 16021 16791],28) = NaN;
                    output([409 1614 1882 1922 2052 2102 2100 2143 2390 2737 3083 3248 3372 3592 3785 4087 4140 4206 4304 4407 4441 4598 4711 4734 4742:4746 4889 5034 5263 5269 5466 5695 5835 5860 5932 5936 6086 6153 6163 6464:6465 6567 6803 6850 6985 6995 7035 7060 7135 7189:7191 7339 7623 7626 7668 7671 7807 7914 8094 8099 8096:8097 8220 8296 8441 8717 9586 9872 10452 10548 11979 13209 13423 13472 13478 10448 11649 10631 10598 11301:11303 10631 10600 9974:9975 9923 8821:8822 8825:8827 8829 8838 6162:6166 8095 8098 8716 8718 9296 9873:9874 11980],29) = NaN;
                    output([56 287 336 372 408 573 616 618 622 627 633 793 951 1478 1503 1564 2195 1778 1788 1882 1922 2102 2213 2295 2868 2866 2840 3011 3083 3184 3194 3207 3222 3277 3272 3347 3350 3372 3397 3403 3543 3556 3592 3693 3682 4407 4243 3686 3715 3758 3830 3915 3954 4020 4027 4077 4084 4096 4129 4100 4153  4161 4198 4206 4216 4243 4262 4264 4268 4310 4540 4554 4598 4650 4744 4734 4773 5034 5140 5157 5172 5171 5175 5190 5225 5263:5264 5267 5588 5610 5932 6118 6135 6153 6163 6234 6761 7623 7809 7913:7914 8094 8099 8144 8220 8838 9872 10542 10548 10730 11062 11067 11110 11133 11154 11256 11511 11650 12130 12134 12137 12405 12664 12666 12658 12983 12997 13209 13423 8167 8178 8151 8144 7809],30) = NaN;
                    output([215 286 287 298 308 324 367 373 391 435 511:512 522 550 574 582 608:610 612 614 616 622 633 635 646 651 653 658 666 672 752 758:760 744:745 755:756 782 797 800 803 805:806 858 897 1053 1088 1090 1112 1116 1206:1207 1217 1221 1239:1240 1290 1322 1324 2320 2333 3115 3249 3256 3273 3276 3924:3926 3946 4699 4695 4742 4832 5135:5136 5158 5168 5178:5179 5221:5222 5226 5273:5274 5306 5312 5316 5320 5367:5382 5407 5453:5454 5458 5608 5848:5850 5863 6320:6321 6465 6470 6473 6482 6488:6491 6507 6509 6512:6516 6534 6541 6538 6560 6577 6608 6703:6704 6722 6859 6961 6967 7432 7469:7470 7472 7576 7686:7687 7768 7854 7872 7910 7907 7910 7930:7931 7948 7933 7953 7957 7970 7985 8000 8004 8044 8049 8051 8067 8094 8102 8115 8141 8145:8146 8151 8258 8265 8339 8345 8354 9546 9624 9684:9685 9701:9702 9844 9848 9985 10034 10036 10066 10127 11524 11526 11701 12223 12225 16017 17186],31) = NaN;
                    output([91 412:419 516:525 576:585 1098:1116 1215:1230 1329:1334 5184:5190 5396:5401 5820 6154:6157 8382:8388 8538:8542 10494:10501 10703:10705 13214:13224 13795:13802 13739:13741 11469:11475 10344:10356 5486:5491],65) = NaN;
                    output([1:13 90:98 410:421 594:600 2795:2799 4404:4408 10548:10551 11469:11476 10630],66) = NaN;
                    output([91 411:422 516:525 576:585 1215:1225 1329:1338 5820 6154:6157 8381:8388 8538:8544 9871 10451 10597 10704 11469],67) = NaN;
                    output([91 4789 5077 5125 5413 6180 6948 7476 7956 8244 8292 8340 8436 10630 11469 15628:15637],68) = NaN;
                    output([3924:3931 4249:4255 5659:5665 8219:8226 8539:8544 10309:10314 10548 11473:11478 11512:11515 12787:12792 13209:13212 15353:15355 15166:15169 15174 15354 11560:11563 16015:16027 11685:11689 16790:16795],69) = NaN;
                    output([2767:2772 3925:3931 4249:4255 5659:5665 8220 10548 11513:11514 11561:11562 11686:11688 11697:11700 11794:11796 13209:13212 13423:13428 13437:13440 15167:15174 15354 16016:16026 16790:16795],70) = NaN;
                    output([429 3127 10243:10244 10429 11340 11433 12455 15171 15174 15504 16021],71) = NaN;
                    output([91 9438 9495 10154],73) = NaN;
                    output([91 744 8536:8537 8669 10155 10974 11674 13209:13211 15167 15625:15655 16852],74) = NaN;
                    output([91 182 4697 5072 4733 16021:16022],75) = NaN;
                    output([90 4823:4824 4826 4875 4880 4813:5839 11137:11560 11673:11750 11937:11950 12518:13939 14065:14068 14075:14095 14140:15245 15578:15580 15613:16031],76) = NaN;
                    output([1:89 92 427:428 1820 2768:2772 2815 3650 3661 4050:4051 5838 6205 6990 9199 9488 10153:10154 10347:10349 13209 13437 13440 15174 15354 16021 16791 16927:16946],77) = NaN;
                    output([428 1895:1964 2483:2491 2587 2722:2733 2761:2821 2967 2971 3008:3023 4250 4402:4416 16021:16026 16925:16939],78) = NaN;
                    output([224:233 1919:1924 ],79) = NaN;
                    output([720 768 939 1325 1332 1924 3936 4062 4086 4287 5267 6882 8256 10531 11412 14546 14688 14812 14843 15008 15020 15156 15169 15174 15600 16021:16022 16300 16905 ],80) = NaN;
                    output([91],81) = NaN;
                    output([6990],84) = NaN;
                    output([],85) = NaN;
                    output([],86) = NaN;
                    output([],87) = NaN;
                    output([],88) = NaN;
                    output([],89) = NaN;
                    output([],90) = NaN;
                    output([],91) = NaN;
                    output([],92) = NaN;
                    output([6629],93) = NaN;
                    output([2791 4637 6068:6071 6073],94) = NaN;
                    output([],95) = NaN;
                    output([],96) = NaN;
                    output([],97) = NaN;
                    output([],98) = NaN;
                    output([],99) = NaN;
                    output([],100) = NaN;
            end                    
            %%% Corrections applied to all years of data:
            % 1: Set any negative PAR and nighttime PAR to zero:
            PAR_cols = [];
            PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'DownPAR_AbvCnpy')==1)];
            PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'UpPAR_AbvCnpy')==1)];
            PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'DownPAR_BlwCnpy')==1)];
            %Plot uncorrected:
            figure(97);clf;
            subplot(211)
            plot(output(:,PAR_cols)); legend(output_names_str(PAR_cols,:))
            title('Uncorrected PAR');
            %         if year <= 2008
            [sunup_down] = annual_suntimes(site, year_ctr, 0);
            %         else
            %             [sunup_down] = annual_suntimes(site, year, 0);
            %         end
            ind_sundown = find(sunup_down< 1);
            
            switch yr_str
                case {'2002';'2003';'2004'};
            DownParBot = 15;
            UpParBot = 15;
            DownParBlwBot = 80;
                otherwise
               DownParBot = 15;
               UpParBot = 15;
            DownParBlwBot = 15;
            end
            
            figure(55);clf;
            plot(output(:,PAR_cols(1)))
            hold on;
            plot(ind_sundown,output(ind_sundown,PAR_cols(1)),'.','Color',[1 0 0])
            title('Check to make sure timing is right')
            output(output(:,PAR_cols(1)) < DownParBot & sunup_down < 1,PAR_cols(1)) = 0;
            output(output(:,PAR_cols(2)) < DownParBot & sunup_down < 1,PAR_cols(2)) = 0;
            output(output(:,PAR_cols(3)) < DownParBlwBot & sunup_down < 1,PAR_cols(3)) = 0;
            output(output(:,PAR_cols(1)) < 0 , PAR_cols(1)) = 0;
            output(output(:,PAR_cols(2)) < 0 , PAR_cols(2)) = 0;
            output(output(:,PAR_cols(3)) < 0 , PAR_cols(3)) = 0;
            
            % Plot corrected data:
            figure(97);
            subplot(212);
            plot(output(:,PAR_cols)); legend(output_names_str(PAR_cols,:))
            title('Corrected PAR');
            
            % 2: Set any RH > 100 to NaN -- This is questionable whether to make
            % these values NaN or 100.  I am making the decision that in some
            % cases
            RH_cols = [];
            RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_AbvCnpy')==1)];
            RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_Cnpy')==1)];
            RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_BlwCnpy')==1)];
            % Adjust columns to match output:
            %     RH_cols = RH_cols - 6;
            figure(98);clf;
            subplot(211)
            plot(output(:,RH_cols)); legend(output_names_str(RH_cols,:))
            title('Uncorrected RH')
%             commandwindow;
            if ~isempty(RH_max)
                RH_resp = RH_max; % RH_max should be set within each year of data.
            else
                commandwindow;
                RH_resp = input('Enter value to set RH > 100 to? (100 or NaN): ');
            end
%             RH_resp = input('Enter value to set RH > 100 to? (100 or NaN): ');
            for j = 1:1:length(RH_cols)
                output(output(:,RH_cols(j)) > 100,RH_cols(j)) = RH_resp;
            end
            subplot(212);
            plot(output(:,RH_cols)); legend(output_names_str(RH_cols,:))
            title('Corrected RH');
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
        case 'TP74'
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%% TP74  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            switch yr_str
                case '2002' % TP74 2002
                    [r c] = size(output);
                    % there's a 1/2 hour offset in data from first half of 2002
                    output_tmp(:,:) = [output(2:9070,1:c); NaN.*ones(1,c); output(9071:end,1:c)];
                    clear output;
                    output = output_tmp;
                    clear r c output_tmp;
                    
                    
                    %%%%%%%%%%%%%%%%%%%%% START SHIFTING %%%%%%%%%%%%%%%%%%
                    % Shift data so that it's all in UTC: %%%%%%%%%%%%%%%%%%%%
                    % need to load last 8 datapoints from 2001
                    num_to_shift = 8;
                    for i = 1:1:length(vars30)
                        try
                            temp_var = load([load_path site '_2001.' vars30_ext(i,:)]);
                        catch
                            %                         disp(['could not load the 2001 variable: ' names30_str(i,:)]);
                            %                         disp(['Check if column should exist -- making NaNs']);
                            
                            temp_var = NaN.*ones(len_yr,1);
                        end
                        
                        fill_data(1:num_to_shift,i) = temp_var(end-num_to_shift+1:end);
                        clear temp_var;
                    end
                    output_test = [fill_data(:,:); output(1:end-num_to_shift,:)];
                    clear fill_data;
                    clear output;
                    output = output_test;
                    clear output_test;
                    %%%%%%%%%%%%%%%%%%%%% END SHIFTING %%%%%%%%%%%%%%%%%%
                    
                case '2003' % TP74 2003
                    for i = 1:1:length(vars30)
                        try
                            temp_var = load([load_path site '_2002.' vars30_ext(i,:)]);
                        catch
                            disp(['could not load the 2002 variable: ' names30_str(i,:)]);
                            disp(['Check if column should exist -- making NaNs']);
                            temp_var = NaN.*ones(len_yr,1);
                        end
                        
                        fill_data(1:8,i) = temp_var(end-8+1:end);
                        clear temp_var;
                    end
                    output = [fill_data(:,:); output(9:end,:)];
                    clear fill_data;
                    % It appears there is a shift in data at the 15535 point,
                    % where data is shifted back until 17464
                    [r c] = size(output);
                    output_tmp(:,:) = [output(1:15534,1:c); NaN.*ones(1,c); output(15535:17464,1:c); output(17466:r,1:c)];
                    clear output;
                    output = output_tmp;
                    clear r c output_tmp;
                    
                case '2005' % TP74 2005
                    
                    %%%%%%%%%%%%%%%%%%%%% START SHIFTING %%%%%%%%%%%%%%%%%%
                    % Shift data so that it's all in UTC: %%%%%%%%%%%%%%%%%%%%
                    % need to load first 1 datapoint from 2006
                    num_to_shift = -1;
                    for i = 1:1:length(vars30)
                        try
                            temp_var = load([load_path site '_2006.' vars30_ext(i,:)]);
                        catch
                            %                         disp(['could not load the 2001 variable: ' names30_str(i,:)]);
                            %                         disp(['Check if column should exist -- making NaNs']);
                            
                            temp_var = NaN.*ones(len_yr,1);
                        end
                        
                        fill_data(1:abs(num_to_shift),i) = temp_var(1:0-num_to_shift);
                        clear temp_var;
                    end
                    output_test = [ output(1-num_to_shift:end,:); fill_data(:,:)];
                    clear fill_data;
                    clear output;
                    output = output_test;
                    clear output_test;
                    %%%%%%%%%%%%%%%%%%%%% END SHIFTING %%%%%%%%%%%%%%%%%%
                    output(608,22) = NaN; % Bad Ts data (Pit B, 5cm)
                    
                case '2007' % TP74 2007
                    
                case '2008' % TP74 2008
                    
                    
                    % Remove Spike from SM data:
                    output(11077:11080,12:32) = NaN;
                    output(12570:12571,12:32) = NaN;
                    output(9732:9733,12) = NaN;
                    output(13129:13130,12) = NaN;
                    output(1:10444,24) = NaN; % 80-100cm sensor doesn't work for first part of year.
                    % Remove Spikes from SHF Data:
                    output(1:10452,11) = NaN;
                    % Remove Spikes from Ts Data (there are a lot of them):
                    %                 ctr2 = 1;
                    resp = 'y';
                    for col = 12:1:23
                        
                        try
                            tracker = load([tracker_path 'TP74_2008_tr.0' num2str(col)]);
                            disp(['loading tracker for column ' num2str(col) '. ']);
                            if strcmp(resp,'q')~=1
                                resp = input('Do you want to continue to edit the tracker? (<y> to edit, <n> to skip, q to quit): ', 's');
                                
                                if strcmp(resp,'y') == 1;
                                    output(:,col) = output(:,col).*tracker;
                                    clear tracker
                                    
                                    [tracker] = jjb_remove_data(output(:,col));
                                    
                                    save([tracker_path 'TP74_2008_tr.0' num2str(col)],'tracker','-ASCII')
                                else
                                end
                            end
                            
                        catch
                            [tracker] = jjb_remove_data(output(:,col));
                            save([tracker_path 'TP74_2008_tr.0' num2str(col)],'tracker','-ASCII')
                            
                            
                        end
                        
                        output(:,col) = output(:,col).*tracker ;
                        clear tracker
                        %                    ctr2 = ctr2+1;
                    end
                    
                    % Remove bad HMP RH Data during 2008
                    right_col = quick_find_col( names30, 'RelHum_AbvCnpy');
                    output(11363:12475,right_col) = NaN; clear right_col;
                    
                    % Remove bad HMP Ta Data during 2008
                    right_col = quick_find_col( names30, 'AirTemp_AbvCnpy');
                    output(11363:12475,right_col) = NaN; clear right_col;
                    
                    % Shift data so that it's all in UTC:
                    % need to load last 8 datapoints from 2007
                    for i = 1:1:length(vars30)
                        try
                            temp_var = load([load_path site '_2007.' vars30_ext(i,:)]);
                        catch
                            disp(['could not load the 2007 variable: ' names30_str(i,:)]);
                            disp(['Check if column should exist -- making NaNs']);
                            
                            temp_var = NaN.*ones(len_yr,1);
                        end
                        
                        fill_data(1:8,i) = temp_var(end-7:end);
                        clear temp_var;
                    end
                    % only the starting 747 points were in EDT -- the rest is
                    % in UTC already:
                    output_test = [fill_data(:,:); output(1:747,:); output(756:end,:)];
                    clear fill_data;
                    clear output;
                    output = output_test;
                    clear output_test;
                    
                    % Fix change in windspeed that results from moving wind
                    % sensor to new tower halfway through season -- we'll use the windspeed
                    % values from the CPEC system to fill in first half of
                    % season:
                    u = load([loadstart 'SiteData/TP74/MET-DATA/annual/TP74_2008.u']);
                    v = load([loadstart 'SiteData/TP74/MET-DATA/annual/TP74_2008.v']);
                    WS_CPEC = sqrt(u.^2 + v.^2);
                    
                    figure(77)
                    right_col2 = quick_find_col( names30, 'WindSpd');
                    ind = find(output(1:10454,right_col2)>0.3 & WS_CPEC(1:10454,1)>0.3) ;
                    plot(output(ind,right_col2),WS_CPEC(ind),'b.');
                    ylabel('CPEC WS'); xlabel('MET WS');
                    p = polyfit(output(ind,right_col2),WS_CPEC(ind),1);
                    output(1:10454,right_col2) = output(1:10454,right_col2).*p(1) + p(2);
                    output(isnan(output(:,right_col2)),right_col2) = WS_CPEC(isnan(output(:,right_col2)),1);
                    %                 output(1:10454,4) = NaN;
                    %                 output(isnan(output(:,4)),4) = WS_CPEC(isnan(output(:,4)),1);
                    clear u v WS_CPEC ind p right_col2;
                    
                    
                    %%% Cycle through variables
                    %                 for i = 1:1:length(vars30)
                    %                     temp_var = load([load_path site '_2008.' vars30_ext(i,:)]);
                    %                     fill_data(1:8,i) = temp_var(end-7:end);
                    %                     clear temp_var;
                    %                 end
                    
                    %                 for i = 1:1:length(vars30)
                    %                     [spike_tracker] = jjb_find_spike(output(:,i), 2);
                    %                 end
                    
                case '2009' % TP74 2009
                    % Remove spikes in soil data:
                    output(6128:8494,1:2) = NaN;
                    output(2004,12) = NaN;
                    bad_data = [10741:10981 12759 12765];
                    output(bad_data,12:32) = NaN;
                    output([10134;10135; 10217],29) = NaN;
                    
                case '2010' % TP74 2010
                    output(6316, [12:32]) = NaN;
                    % Bad Soil Temperature data at Pit A, 100cm:
                    bad_data = [11794 12410 12411 13215:13229 13748:13752 15362:15366 15627 16008:16011];
                    % Bad Point in all Soil Data:
                    output(bad_data, 12) = NaN;
                    output(6316,12:32) = NaN;
                case '2011' % TP74 2011
                    % Missing Data in all fields
                    output(6476:6708, 1:51) = NaN;
                    % Remove bad spikes in soil data at Pits A and B, all depths:
                    output(15259,13:32) = NaN;
                    output(15259,48:51) = NaN;
                    % Remove bad data from CO2 Canopy
                    output([3911 9166],47) = NaN;
                    % Remove Spikes from Ts Data (there are a lot of them):
                    %                 ctr2 = 1;
                    resp = 'y';
                    for col = 12:1:23
                        
                        try
                            if exist([tracker_path 'TP74_2011_tr.0' num2str(col)],'file')==2
                                tracker = load([tracker_path 'TP74_2011_tr.0' num2str(col)]);
                                disp(['loading tracker for column ' num2str(col) '. ']);
                            else
                                tracker = ones(yr_length(2011,30),1);
                                disp(['create tracker for column ' num2str(col) '. ']);
                            end
                            
                            
                            if strcmp(resp,'q')~=1
                                resp = input('Do you want to continue to edit the tracker? (<y> to edit, <n> to skip, q to quit): ', 's');
                                
                                if strcmp(resp,'y') == 1;
                                    output(:,col) = output(:,col).*tracker;
                                    clear tracker
                                    
                                    [tracker] = jjb_remove_data(output(:,col));
                                    
                                    save([tracker_path 'TP74_2011_tr.0' num2str(col)],'tracker','-ASCII')
                                else
                                end
                            end
                            
                        catch
                            [tracker] = jjb_remove_data(output(:,col));
                            save([tracker_path 'TP74_2011_tr.0' num2str(col)],'tracker','-ASCII')
                            
                            
                        end
                        
                        output(:,col) = output(:,col).*tracker ;
                        clear tracker
                        %                    ctr2 = ctr2+1;
                    end
                    
                case '2012' % TP74 2012
                    % Bad CO2 canopy data
                    output([601 7805 10417 16632],47) = NaN;
                    % Bad tree temp sensors
                    output(:,33:43) = NaN;
                    % Bad Ts 100cm Pit A
                    output([5345:5349 5465:5468],12) = NaN;
                    
                case '2013' % TP74 2013
                    % Bad windspeed data (broken instrument)
                    output(10303:12087,4) = NaN;
                    % Bad wind direction data (broken instrument)
                    output(10303:12087,5) = NaN;
                    % Bad UpPAR Above Canopy data
                    output(6764:8100,6) = NaN;
                    % Missing DownPAR Above Canopy data
                    output(:,9) = NaN;
                    % Bad ST A100cm data
                    output([6806 8031 8485],12) = NaN;
                    % Bad ST A50cm data
                    output([5790 6806 8031 8101 8485],13) = NaN;
                    % Bad ST A20cm data
                    output([5790 6806 8031 8101 8485],14) = NaN;
                    % Bad ST A10cm data
                    output([5790 6806 8031 8101 8485],15) = NaN;
                    % Bad ST A5cm data
                    output([5790 6806 8031 8101 8485],16) = NaN;
                    % Bad ST A2cm data
                    output([5790 6806 8031 8101 8485],17) = NaN;
                    % Bad ST B100cm data
                    output([6806 8031 8485],18) = NaN;
                    % Bad ST B50cm data
                    output([5790 6806 8031 8101 8485],19) = NaN;
                    % Bad ST B20cm data
                    output([5790 6806 8031 8101 8485],20) = NaN;
                    % Bad ST B10cm data
                    output([5790 6806 8031 8101 8485],21) = NaN;
                    % Bad ST B5cm data
                    output([5790 6806 8031 8101 8485],22) = NaN;
                    % Bad ST B2cm data
                    output([5790 6806 8031 8101 8485],23) = NaN;
                    % Bad SM B80-100cm data
                    output([6806 8031 8485],24) = NaN;
                    % Bad SM A50cm data
                    output([5790 6806 8031 8101 8485],25) = NaN;
                    % Bad SM A20cm data
                    output([5790 6806 8031 8101 8485],26) = NaN;
                    % Bad SM A10cm data
                    output(8031,27) = NaN;
                    % Bad SM A5cm data
                    output([8031],28) = NaN;
                    % Bad SM B50cm data
                    output([6806 8031 8485],29) = NaN;
                    % Bad SM B20cm data
                    output(8031,30) = NaN;
                    % Bad SM B10cm data
                    output(8031,31) = NaN;
                    % Bad SM B5cm data
                    output(8031,32) = NaN;
                    % Bad tree temp sensors
                    output(:,33:43) = NaN;
                    % Bad CO2 canopy data
                    output([1:8444 8565 13610],47) = NaN;
                    % Bad SM DR100cm data
                    output([5790 6806 8031 8101 8485],48) = NaN;
                    % Bad SM DR50cm data
                    output([5790 6806 8031 8101 8485],49) = NaN;
                    % Bad SM DR20cm data
                    output(8031,50) = NaN;
                    % Bad SM DR5cm data
                    output([6806 8031],51) = NaN;
                    
                case '2014' % TP74 2014
                    % Bad UpPAR Above Canopy data
                    output(3433:3452,6) = NaN;
                    % Questionable Rn
                    output([4068 4800 10707 10709],9) = NaN;
                    % Missing DownPAR Above Canopy data
                    output(:,9) = NaN;
                    % Bad ST A100cm data
                    output([10402 11715:11720 11908:11912 11095:11100 ],12) = NaN;
                    % Bad ST A20cm data
                    output(5894:5898,14) = NaN;
                    output(9815:12271,14) = NaN; % Shift upwards (>10 deg in a few hrs)
                    % Bad tree temp sensors
                    output(:,33:43) = NaN;
                    % Bad CO2 canopy data
                    output([1316:1324 11508 12363:12364 13872:13874],47) = NaN;
                    % Spikes in SM DR 100 cm
                    output([12743 12781 12791 12977],48) = NaN;
                    
                    
                case '2015' % TP74 2015
                    % Bad Ta data
                    output(9149,1) = NaN;
                    % Bad Rn sensor
                    output([12975:16212],8) = NaN;
                    % Spike in Ts A 100cm
                    output([7211 7237 8671 10649 10653],12) = NaN;
                    % Remove spike in Ts A 20cm
                    output(3920,14) = NaN;
                    % Spike in Ts B 100 cm
                    output([1751:1752],18) = NaN;
                    % Remove spike in Ts Pit B 20cm
                    output(7248,20) = NaN;
                    % Ts A 20 cm seems to be too high most year
                    output(3654:17520,14) = NaN;
                    % Remove spike in Tank Pressure N2 Cal
                    output([614 2912 2913],45) = NaN;
                    % Bad CO2 IRGA
                    output([2915 6471 7433 7810 7899 11745:11746],47) = NaN;
                    % Try to rescale CO2 IRGA - simplest approach might be
                    % to multiply by 2:
                    output([8629:9149],47) = output([8629:9149],47).*2;
                    %                     tmp1 = output([8629:9149],47); tmp2 = output([9155:17520],47);
                    %                     std1 = nanstd(tmp1);std2 = nanstd(tmp2);
                    %     mean1 = nanmean(tmp1);mean2 = nanmean(tmp2);
                    
                case '2016' % TP74 2016
                    % Air Temp
                    output([4979],1) = NaN;
                    % Wind Speed
                    output([9764:9777],4) = NaN;
                    % Soil Heat Flux
                    output([2450:2627],10:11) = NaN;
                    % Soil temp A 100 cm
                    output([1392 2222 2250 2624:2625 5036 ...
                        8554 9764:9766 10199 10272 10273 12190],12) = NaN;
                    % Recent Soil dips
                    output([7103 7244 7245 14412:14414],12:24) = NaN;
                    % Soil temp B 50 cm
                    output([1390 1591 3198:3202 9763],19) = NaN;
                    % Soil temp B 20 cm
                    output([737 1392 3196:3198],20) = NaN;
                    % Recent Soil dips
                    output([7103 7244 7245],29) = NaN;
                    % Recent Soil dips
                    output([7103 7244 7245],32) = NaN;
                    % CO2 Canopy
                    output([2620 2651 2777 4210 4211 17337],47) = NaN;
                    % Recent Soil dips
                    output([7103 7244 7245],48:49) = NaN;
                    
                case '2017' % TP74 2017
                    % Relative Humidity
                    output([1954 2960 5441 7862 7956 8730 11077 13450 16400],2) = NaN;
                    % Soil Temp A 100cm
                    output([4503 5764:5797 8337 10712 10713 11777:11781 13500:13513],12) = NaN;
                    % Soil Temp B 50 cm
                    output([5765:6199],19) = NaN;   
                    % Soil Moisture A 20cm
                    output([10712],26) = NaN;
                    % Soil Moisture A 10cm
                    output([11776:11779],27) = NaN;
                    % CO2 Canopy Dips
                    output([491 3205 3249 4209 6132 8916 13822 14208 14209 14725 15555 15556 15635],47) = NaN;

                case '2018'     % TP74 2018
                    % Random Spike in all soil data
                    output([9968 10534 11941],[12:30 48:51]) = NaN;
                    % CO2 Canopy Dips
                    output([2770 2880 2890 4513 4930 5023 5029 7134 7138 7519 7569 7571 7575 8146 ...
                        8909 11221 13761 13779 14090 14091 14249 16500],47) = NaN;
                    % Down PAR Abv Cnpy
                    output([13175:17520],7) = NaN;
                    % SM DR 100 cm
                    output([4484],[48 49]) = NaN;
                    RH_max = 100;
                    
                  case '2019'    % TP74 2019
                     % Random Spike in all soil data
                    output([11517 14866 14867],[12:32 48:51]) = NaN;
                    output([10009 10010 10011],19) = NaN;
                    % CO2 Canopy Dips
                    output([1091 1196 1197 1198 1367 1368 2194 2195 4876 6419 8595 8668 10020 11562 11602 11757 16090],47) = NaN;
                    
                    RH_max = 100;
					
					% PAR down 
					% Values are missing until November 2019 due to broken sensor. Refurbished unit was installed in Nov 2019
					% However, magnitude is much too high and it needs to be re-scaled.
					% Given that there is no SW down at the site to correct with, JJB has decided to remove PARdn data from November onwards 
					% (when the refurbished unit was installed to replace the broken one). Will allow it to be filled from TP39.
					% If Keegan comes up with correction factor, we'll apply it. 
					output(:,7) = NaN; 
                    tmp = load([loadstart 'Matlab/Data/Met/Final_Cleaned/TP39/TP39_met_cleaned_2019.mat']);
                    TP39_PAR = tmp.master.data(:,9); % Load TP39 PAR
                    % Fill TP74 PAR with regression corrected correlation
                    % with TP39
                    TP74_PAR_est = polyval([1.057383953687917,-0.667374133564968],TP39_PAR);
                    output(:,7) = TP74_PAR_est;
                    clear tmp TP39_PAR TP74_PAR_est
                    
                case '2020' %TP74 2020 (Nur and Alanna)
                    RH_max = 100;
                    output(15353,4) = NaN; %wind speed
                    
                    %%%%%%%%%%%%%%%%% Scaling PAR DOWN %%%%%%%%%%
                    tmp = load([loadstart 'Matlab/Data/Met/Final_Cleaned/TP39/TP39_met_cleaned_2020.mat']);
                    TP39_PAR = tmp.master.data(1:9779,9); % Load TP39 PAR Down
                    TP74_PAR = output(1:9779,7);
%                     TP39_PAR_2 = tmp.master.data(10500:end,9);
%                     TP74_PAR_2 = output(10500:end,7);
%                     ind2 = find(~isnan(TP39_PAR_2.*TP74_PAR_2));
%                     p2 = polyfit(TP39_PAR_2(ind2),TP74_PAR_2(ind2),1);
                    ind = find(~isnan(TP39_PAR.*TP74_PAR));
%                     figure(65); clf;
%                     plot(TP39_PAR(ind),TP74_PAR(ind),'k.');
                    p = polyfit(TP74_PAR(ind),TP39_PAR(ind),1);
                    TP74_PAR_corr = polyval(p,TP74_PAR);
                    output(1:9779,7) = TP74_PAR_corr;
                    %%%%%%%%%%%%%%%%% Scaling PAR UP %%%%%%%%%%
                    TP39_PAR = tmp.master.data(1:10171,10); % Load TP39 PAR Up
                    TP74_PAR = output(1:10171,6);
                    ind = find(~isnan(TP39_PAR.*TP74_PAR));
                    p = polyfit(TP74_PAR(ind),TP39_PAR(ind),1);
                    TP74_PAR_corr = polyval(p,TP74_PAR);
                    output(1:10171,6) = TP74_PAR_corr;
                    clear tmp TP39_PAR TP74_PAR* p;
                    
                    % Random Spikes in all soil data
                    output([8776 9681 10175 11649 11838],[12:32 48:51]) = NaN;
                    output([4797 6951 6999 13064 13937],11) = NaN;
                    output(9243,16) = NaN;
                    output(9205,[12:32 48:51]) = NaN;
                    %PAR sensors were fixed/replaced this year on July 30th
                    %(half hour point 10166)
                    %correction factor can be applied (I believe values
                    %need to be doubled but can check site report sent July
                    %30 by Keegan) - AB
                    
                case '2021' % done by AB and EAR
                    RH_max = 100; % (will cause any RH > 100 to be set to 100
                    output([5308 5822],8) = NaN; %Net Radiation
                    output([408 460],10) = NaN; %soil heat flux
                    output([2884 2331:2337],47) = NaN; %CO2 canopy  
                    output([14000:end],[12:16 20 21 23]) = NaN; % removing spurious data points
                    output(:,[33:43]) = NaN; % Remove data from Tree Thremocouples (all values = 0)
                    
                case '2022' % EAR, LL & NH
                    RH_max = 100;
%                     output([2495], 14) = NaN;
%                     output([2495], 16) = NaN;
%                     output([1:2495], 17) = NaN;
%                     output(2489,[18,22]) = NaN;
%                     output([2495], 19) = NaN;
%                     output([2495], 20) = NaN;
%                     output([2495], 21) = NaN;
                    output([2495 11872:11875 13917:13920 16014:16021], 23) = NaN;

                    %%% Fix issues with soil sensors
                    % A. remove all points 2489 to 2495, where some sort of
                    % switch happened: 
                    output(1:2489,12:23) = NaN; % Added 2024-02-25 by JJB. The data looks completely wrong and I'm not sure how to fix.
                    output([2489:2495],[12:23]) = NaN;
                    % B. swap sensors after 2495 to correct for miswiring
%                     A100 = output(2495:end,17); % Pit A 100cm is wired into 2 cm
%                     A50 = output(2495:end,16); % Pit A 50cm is wired into 5 cm
%                     A20 = output(2495:end,15); % Pit A 20cm is wired into 10 cm
%                     A10 = output(2495:end,13); % Pit A 10cm is wired into 50 cm
%                     A5 = output(2495:end,14); % Pit A 5cm is wired into 20 cm
%                     A2 = output(2495:end,12); % Pit A 2cm is wired into 100 cm
%                     B100 = output(2495:end,23); % Pit B 100cm is wired into 2 cm
%                     B50 = output(2495:end,21); % Pit B 50cm is wired into 10 cm
%                     B20 = output(2495:end,20); % Pit B 20cm is wired into 20 cm
%                     B10 = NaN.*B20; % Pit B 10cm seems to have no data
%                     B5 = NaN.*B20; % Pit B 5cm seems to have no data
%                     B2 = output(2495:end,19); % Pit B 2cm is wired into 50 cm
                    A100 = output(2495:end,17); % Pit A 100cm is wired into 2 cm
                    A50 = output(2495:end,16); % Pit A 50cm is wired into 5 cm
                    A20 = output(2495:end,15); % Pit A 20cm is wired into 10 cm
                    A10 = output(2495:end,13); % Pit A 10cm is wired into 50 cm
                    A5 = output(2495:end,14); % Pit A 5cm is wired into 20 cm
                    A2 = output(2495:end,12); % Pit A 2cm is wired into 100 cm
                    B100 = NaN.*A100;  % Pit B 100 seems to have no data.
                    B50 = output(2495:end,23); % Pit B 50cm is wired into 2 cm
                    B20 = output(2495:end,21); % Pit B 20cm is wired into 10 cm
                    B10 = output(2495:end,20); % Pit B 10cm is wired into 20 cm
                    B5 = NaN.*A5; % Pit B 5cm seems to have no data
                    B2 = output(2495:end,19); % Pit B 2cm is wired into 50 cm
                    output(2495:end,12) = A100;
                    output(2495:end,13) = A50;
                    output(2495:end,14) = A20;
                    output(2495:end,15) = A10;
                    output(2495:end,16) = A5;
                    output(2495:end,17) = A2;
                    output(2495:end,18) = B100;
                    output(2495:end,19) = B50;
                    output(2495:end,20) = B20;
                    output(2495:end,21) = B10;
                    output(2495:end,22) = B5;
                    output(2495:end,23) = B2;
                    
                    output(:,24) = NaN;
                    output(:,33:43) = NaN;
                    output([1:2435 6781 9693 10252 10255 12207 13850 17226], 47) = NaN;
                    % Try to fix offset in CO2_cpy data: 
                    output(1:9692,47) = output(1:9692,47) + (output(9694,47)-output(9692,47));
                 case '2023' % EAR, NS completed 2024-12-13
                    RH_max = 100;
                    output([194 576:602 911:935 1182:1221 2788:2810 2900:2908 2977:3001 3122:3138], 2) = NaN;%RelHumAbvCnpy
                    output([15393:16207], 4) = NaN; %WindSpd
                    output([15393:16207], 5) = NaN; %WindDirection
                    output([1086:1090 3147:3154], 6) = NaN;%UpPARAbvCnpy
                    output([15421 15441 15457 15502 15566 15727 15766 16073 16175 16403 16481 16488 16690 16894:16897 17180 17202 17232 17324 17389 17452 17481], 12) = NaN;%SoilTempA100
                    output([16447 16494 12627 12809 13012 13018 13209 13244 13276 13384 13397 13474 13504 13579 13634 13756 13763 13870 13946 13961 13966 13970 14014 14062 14071 14102 14104 14107 14110 14139 2553 9775 9982 10029 10308 10313 10317 10319 10363 10411 10455 10504 10516 10549 10602 10608 10611 10740 10822 10924 10941 10984 11188:11189 11413 11468 11791 11803 11807 11810 11842 11848 11850 11854 11857 11869 11892 11898 11941 11944 11946 11988 11998 12054 12183 12194 12208 12480  9918 10225 10310 10542 10970 11266 11613 11683 11789 11837 11933 12002 12457 13226 13227 13282 13391 13658 13730 13795 14047 14094:14097 14114 14174 14242:14243 14290 14298 14339 14354 14395 14423:14424 14431 14435 14440 14451 14453 14457:14458 14473 14476 14479 14494 14252:14254 14300 14323 14346:14349 14393 14401 14412 14446 14460 14465 14515 14519 14523:14527 14556 14558 14532 14565 14606 14654:14655 14664 14671 14675 14703 14731 14797 14847 14744 14759 14774 14782 14800 14814 14819 14821 14829:14832 14841 14857:14858 14862:14865 14872 14877:14879 14884 14895 14902 14917 14924 14926 14930 14934 14938:14940 14943 14951 14969 14954 14984 14988 14992 14995 15001 15115:15116 15006 15020 15036:15037 15050 15057:15074 15086 15090 15116:15117 15134:15135 15141 15185 15191:15198 15211 15223 15225 15230 15236 15242:15243 15252:15253 15263 15270:15281 15285 15294 15302 15314:15318 15322 15327 15336 15340 15350 15359 15367:15392 15412:15413 15431 15442 15452:15455 15459 15461 15467:15475 15491 15494 15498 15500 15504:15505 15519:15527 15567 15588 15596 15614:15624 15636 15638:15639 15646 15650 15652:15653 15662 15666 15683 15687:15688 15705 15708 15726 15728 15753:15754 15758 15771 15783 15794 15797 15810 15830 15839 15856 15861 15869 15872 15880:15883 15920 15898 15912 15953], 13) = NaN; %SoilTempA50
                    output([16004:16006  16008 16012 16015 16019 16025 16027 16031 16034 16039 16041:16042 16049 16051 16060:16061 16068 16071 16076 16088 16092:16097 16132 16150 16172 16183:16189 16195:16196 16206 16233 16237:16238 16254 16257 16264 16281 16287 16319 16337 16340 16350 16352 16357 16366 16378 16406:16407 16410 16416 16418 16427:16428 16431:16432 16434 16436 16438 16440 16443:16444 16445:16446 16454 16465 16469:16470 16476 16480 16482:16485 16491 14694 16502:16503 16524 16529 16546 16590 16603 16618 16625 16627 16731:16733 16737 16749 16762 16767:16769 16803 16837 16840 16847 16849 16852 16856 16858 16868:16869 16874 16883 16897 16901 16905 16910 16914 16916 16920 16923 16934:16935 16959 16976 16992 16997 17005 17010 17015:17016 17027:17034 17078 17101:17102 17106 17109 17112 17125 17139:17140 17144:17145 17155:17157 17161 17167 17172 17178 17182 17184 17192 17204:17209 17220 17232:17238 17247 17257 17268 17273 17282 17287 17290 17292 17294:17296 17301 17305 17311 17313:17314 17316 17323:17324 17328:17329 17333 17336 17377 17385:17389 17393 17416 17421 17430:17434 17437 17440 17465:17470 17478], 13) = NaN; %SoilTempA50
                    output([2554 4076 14040 14505 14483 14874 14867 14883 14886 14902 15003 15067 15072 15219 15335 15430 15566 15585 15598 15624 15649 15675 11839 13759 14543 14663 14749 14810 14830 14851 14878 14929 15019 15083 15147 15188 15230 15234 15269 15356 15373 15392 15415 15451 15474 15507 15531 15551 15579 15667 15671 15704 15730 15752 15760 15763 15767:15768 15792 15806 15880 15884 15937 15965:15966 16178 16211 16449 16033 16062 16070 16085 16130 16160 16173 16194 16348 16457 16472:16474 16483 16505 16514 16545 16600 16706 16715 16739:16740 16859 16865:16866 16872 16888 16918 16922 16927 16950 16956 16983 16997 17139 17176 17191 17195 17201 17203 17230 17239 17298 17304 17306 17322 17330 17334 17343 17345:17347 17350 17356 17401 17405 17425:17426 17437 17467 17504], 14) = NaN; %SoilTempA20
                    output([4076 11375 13954 13986 14062 14097 15422 15456 15750 15757 1209 2553 9775 9813 11851 14394 14423 14477 14537 14813:14814 14843 14907 14914:14920 14930 14937:14939 14945:14951 14990 15031 15034 15075 15093 15132 15146 15160 15181 15185 15205 15211 15224 15255 15277 15342 15366 15379 15383 15390 15399 15437:15438 15449 15457 15466 15471 15505 15525 15529 15589 15599 15608 15623 15633:15645 15667 15699 15714 15795 15808 15833 16257 15877:15882 15948 15964 16033:16034 16078:16083 16111 16170 16198 16245 16267 16345 16394 16402 16409 16444 16451 16484 16517 16531 16576 16594 16667 16804 16842 16855 16885 16913 16958 16984:16985 16996 17000 17021 17069 17073 17148 17159 17171 17175 17181 17202 17214 17237 17254 17278 17283 17308 17317 17333 17367 17377 17394 17420 17443 17471 17479], 15) = NaN;%SoilTempA10
                    output([1925 2553 2979 4217 9940 14053 14103 14241 14340 14324 14383:14386 14399 14432 14576 14670 14673 14678 14909 14893 15062 15072 4076 8924 10375 10648 11790:11805 11814 11849 11851 11854 11890 11903 11909 12475 13238 13282 13296 13377 13391 13539 13880 13934 13942 13946 13994 14012:14013 14051 14071 14076 14739 14861 14901 14913 14950 15097 15137 15195 15243 15285 15301 15305 15352 15364:15373 15378 15387 15390 15399 15423 15428 15471 15501 15511 15559 15568 15640:15646 15655 15658 15696 15757 15761 15789 15907 15967 16004 16007 16021:16022 16037 16085 16127:16128 16153 16155 16193 16291 16314 16340 16359 16361 16367 16379 16389 16442 16452:16456 16478 16482 16497 16707 16730 16752 16779 16793 16824:16825 16863 16902 16910 16921 16981 16999 17023 17026:17028 17039 17064 17103 17113 17152 17169 17199 17221 17245 17247 17285 17292 17321 17327 17336 17345:17347 17362  17372 17389 17393 17395 17402 17406 17417 17486 15391], 16) = NaN;%SoilTempA5
                    output([4076 9407 9449 9594 9773 9926 9927 9978:9982 10023 10029 10078 10108 10304 10363 10371 10398:10401 10410 10513 10556 10594 10608 10641 10777 10789 10826 10982 11213 11322 11332 11418 11701 11784 11789 11806 11837:11851 11862 11887:11902 11911 11941 11944 11983 11995:12003 12207 12394:12395 12806 13195 13291 13431 13433 13504 13779 13796 13849 13892 13949 13972 14025 14041 14062 14084 14093:14104 14123 14170 14212 14235 14248:14257 14276:14282 14299:14300 14306 14331 14340 14350:14353 14375:14414 14434:14440 14457:14461 14474 14479 14507 14534 14638 14684 14715 14725 14752 14775:14779 14823 14836 14857:14874 14895 14906 14914 14921:14926 14936 14984 15012 15046 15059 15083 15089 15143 15161 15187 15216 15228 15252 15260 15288 15294 15300:15305 15318 15324 15328:15337 15344:15367 15377:15381 15389 15393:15398 15411:15412 15441:15442 15462 15500 15540 15567 15592 15612 15622 15651 15729 15766 15994 16023 16052 16130  16264 16371 16431 16454 16466 16474:16490 16664 16692 16694 16720 16727 16805:16807 16816 16829 16849:16850 16947 16987 16991 16998 17040 17071 17081 17115 17139:17141 17160 17238 17242 17247 17256 17314:17315 17344 17415 17421 17434 17436 17441 17467:17468 9775 9823 9844 9891 9983 10028 10123 10663 10851 10882 10991 11033 11115 11124 11215 11285 11741 11785 14005 14026], 17) = NaN; %SoilTempA2
                    output([4076 8766:8767 11115:11116 11332 11365 11371 11418 11470 11607 11689 11787 11791:11780 11796 11801 11809 11838 11894 11901 12093 12194 11265 11322 11564 11707 11766 11785 11805 11810 11840 11844 11846 11853 11857 11889 11898 11911 11919 11931 11935 11941 11943 11966 11993 11999 12034 12187:12189 12330 12401 12627 12634 13149:13150 13152 13193:13195 13244:13246 13254 13436 13439 13510 13543 13638 13768 13784 13797 13811 13847 13849 13854 13859 13862 13870 13879 13931 13986 13989 14015 14017 14026:14027 14116 14123 14151 14156:14157 14161:14162 14214 14235 14264 14334:14335 14223 13718 13727 12200 12574 12743 12747 13242 13292 13295 13341 13389 13454 13477 13672 13750 13765 13796 13808 13824 13829 13884 13945 13961 13968 13997 14019 14025 14052 14059 14062 14073 14084 14090 14095 14105 14108 14137 14141 14168 14216 14232 14237 14249 14278 14282 14288:14289 14298:14300 14341 14343 14347 14350 14352:14353 14357 14359 14368 14375 14382 14385:14389 14392 14408 14412 14415 14396 14418 14432:14434 14440:14441 14460 14468 14473:14474 14484 14487 14492 14497 14503 14543 14559 14562 14578 14583 14613 14616 14621 14644 14662:14663 14673 14681 14690 14693 14697 14705 14759 14762 14779 14791 14813 14819:14821 14832:14834 14838 14845:14846 16378 16414 14848 14854 14872 14874:14882 14888:14895 14900:14913 14921 14924 14931:14936 14943 14966 14985 14989 14994 15002 15010 15015 15018:15019 15022 15026 15031 15056 15059 15070 15113 15129:15134 15150 15155 15166 15168 15179 15184 15188 15200:15203 15208 15223 15227 15243 15246 15249 15255:15256 15260 15271 15284 15290 15300 15308 15310 15318 15328 15332 15335 15341 15344 15347 15349:15350 15353 15355 15359 15362:15370 15392:15403 15431 15437 15440 15448 15450 15458 15460 15469:15470 15488 15491:15500 15525:15526 15532 15543 15563 15568:15569 15572 15589 15592 15597 15606 15613 15619 15628:15629 15635 15640 15656 15665:15680 15688 15708 15713 15730 15737 15746 15752:15762 15775 15783 15786 15816 15829 15846 15854 15870 15875 15897 15918:15920 15928 15947 15954 15969 15981 16008 16013 16018 16020 16024 16039 16056:16068 16088 16102:16103 16121 16129:16136 16146:16154 16165 16184 16188 16204 16214 16233 16253:16254 16280 16283 16286:16287 16296 16299 16306 16312 16318 16337 16355:16356 16366 16373 16387 16399 16403 16430 16443 16450:16452 16456:16457 16460 16474 16478 16481 16483 16487 16494 16505 16515 16519 16523 16555 16559 16571 16582 16593 16598:16599 16605 16609 16619 16624:16625 16637 16668 16688 16718 16723 16726 16729 16741:16747 16753:16756 16770 16775 16783 16800:16801 16828:16831 16836 16840 16844 16853 16861 16863 16866 16870 16874 16876 16884 16893:16898 16903 16909 16920 16934 16977:16979 16989 16997 17014 17018 17021 17027 17037 17042 17111 17114 17124 17139 17153 17158 17161 17163 17182 17186 17188 17191 17228 17195 17210 17212 17222 17226 17234 17236 17240 17247:17251 17256:17257 17268:17273 17277 17449 17457 17296 17301:17308 17317:17319 17326 17330:17331 17340:17341 17352 17363 17374 17376 17387 17396 17403:17404 17415 17420 17425:17426 17433 17438 17441 17446:17447 17470 17493 17507 17194 16899 16344], 19) = NaN;%SoilTempB50
                    output([16171 16284 16383 16394 16654 16831 16890 16914 17013 17031:17032 17122 17132 17192 17230 17406 16687], 20) = NaN;%SoilTempB20
                    output([1923 1209 4076 8734:8738 8968 9021 9449 9593 9594 9605 9729 9779 9823 9844 9880 9926:9927 9965 9978 9983 9988 10023:10028 10060:10062 10075 10078 10108 10127 10172 10220 10227 10305 10315 10361 10363 10367 10373 10375 10398 10407 10411 10416 10421 10497 10502 10514 10549 10553 10557 10570 10598 10601 10669 10701:10702 10709 10733 10740 10746 10754 10846 10942 10976:10977 10990 11076 11120 11181 11238 11285 11314 11322 11332 11362 11366 11393 11400 11403 11417:11418 11426 11544 11600 11605 11686 11691 11694 11729 11746 11755 11762 11785:11791 11803:11806 11812 11831 11833 11837 11842:11843 13380 11850:11857 11888 11892 11897 11900 11910 11930 11933 11937 11940:11941 11981 11993 11997 12037 12059 12175 12179 12195 12274 12327 12384 12394 12480 12779 12788 12798 13085 13102 13220 13242 13244 13276:13277 13292 13295 13342 13345 13368 13373 13376 13383:13387 13419 13428 13439 13441 13449 13458 13473 13502 13516 13534 13648 13661 13664 13713 13721 13730 13734 13737 13760 13768 13785 13790 13802 13806:13807 13811 13813 13817 13821 13823 13853:13854 13864 13878 13919 13937 13947 13971 13986 13999 14017 14019 14024 14026 14058:14062 14074 14084:14099 14104 14108 14111 14114 14116:14118 14132:14133 14202:14204 14227 14233 14246 14248 14252 14256 14264 14276:14277 14282 14305 14324 14327 14352 14357 14375 14381:14391 14398:14403 14411:14418 14421 14423 14429 14433 14440:14441 14444 14448 14468 14452 14466 14474 14492 14496 14501 14519 14526 14530:14534 14543:14544 14561 14581:14583 14603 14607 14611 14620 14623 14640 14651 14656 14658 14670 14693:14700 14705 14725 14733:14734 14744 14752 14759:14779 14789 14787 14792 14799 14804 14810 14828 14840:14841 14843 14847 14853 14855 14859:14860 14867:14868 14872 14876:14878 14880 14883:14885 14887:14890 14892 14894 14898:14900 14902:14903 14906:14908 14921 14924 14927 14931:14932 14936 14942 14953 14960 14967 14978 14981:14982 14984 15001 15005 15010 15014 15017 15020 15030:15031 15035 15039:15040 15044 15046 15049 15058 15063:15070 15078 15085:15087 15094 15119:15120 15135 15139 15143 15147 15149:15150 15156 15159 15161 15168 15172 15176 15179 15184 15202 15208 15212 15214 15220 15229 15233:15234 15237 15244:15245 15250 15259:15261 15265 15270 15272 15291 15293:15294 15300 15302 15310 15317:15318 15321 15328:15382 15391:15397 15403 15414 15418 15421:15425 15442 15447 15453 15459 15467 15485:15486 15489 15496:15500 15508 15514 15524 15533 15538:15539 15542 15553 15569 15572:15573 15582 15591:15595 15607:15612 15616 15618:15619 15623 15626 15628 15630 15635 15637 15639:15640 15643 15648 15652 15654 15657 15660 15668 15678 15686 15691 15693 15698:15700 15711:15712 15716 15720 15731:15732 15759 15762 15765:15772 15789 15802 15832 15836 15843 15854:15858 15867 15880 15883 15919 15992 15995 16003 16008 16014 16016 16019 16024:16029 16032 16039 16044 15162 16868:16870 17508 17514 16049 16055:16057 16066 16069 16073 16076 16078 16081 16086:16087 16117 16121 16126 16134 16137 16143 16164:16165 16172 16178 16181 16186 16190:16191 16198 16201:16202 16206 16212:16213 16218:16219 16232 16246 16264:16269 16278:16279 16297 16304 16312 16315 16338 16348 16351 16357 16401 16409 16412 16414 16418 16420 16422 16426:16427 16432 16434 16436:16438 16440:16441 16443 16445:16446 16452 16455 16461:16462 16468 16472:16474 16477 16479 16481:16484 16495:16497 16502 16510 16513 16516 16523:16526 16531 16543 16564:16565 16577 16589:16591 16596 16615 16628 16643 16645 16670 16676 16683 16699 16703 16707 16717 16719 16726 16732:16738 16745 16760 16764:16765 16775 16796 16798 16801 16814 16821:16823 16825 16829 16848 16854 16856 16862 16865 16868:15870 16877 16887 16913 16961 16973 16975 16986 16988 16995:16996 16999 17020 17025 17031 17033 17036 17041 17051 17054 17059 17079 17097 17104 17108 17110 17113 17119 17124 17133:17140 17145:17146 17156:17157 17159 17167 17181:17184 17190 17193 17195 17199 17204 17215 17219 17230 17234 17239 17244:17245 17247 17262 17277 17280 17295:17298 17301:17302 17306 17309 17315 17318 17323 17326 17331 17339 17343:17344 17362 17367 17377 17379 17388:17389 17392 17396 17402 17406 17413 17418:17426 17430 17435 17438 17451 17473 17480 17485 17497 17501 17505 17508 17514], 21) = NaN;%SoilTempB10
                    output([4076 9888 10060:10068 11967:11969 12016 14907 14928 15055 15339 16360:16361], 23) = NaN;%SoilTempB2
                    output([4112 4127 4189 4244 4414 4436 4448 4458 4466 4446 4540 4545 4539 4552 4558 9300 12965 13523 13569 14016 14023 14212 14218 14774 14806 15354 15360 15369 15389 15805 16007 16176:16177 16454 16596 16758 16826 16862 16882 16880 16997 17070 17135 17150 17181 17206 17226 17268 17271 17294 17305 17318 17343 17356 17363 17413 17428 4076 4144 4163 4211 4430 9301 12017 12566 12737 12739 12788 13145 13155 13165 13313 13331 13339 13349 13351 13359 13360 13363 13370 13401 13425 13434 13720 13764 13810 13817 13853 14216 14232 14235 14340 14480 14616 14636 14766 14772 14778:14779 14790:14792 14794 14797 14800 14802 14811 14915 14925 14928 14946 14964 15048 15060 15063:15064 15096 15106 15154:15155 15160 15165:15166 15168 15181 15183 15186 15188 15191 15198 15202 15207 15210 15212 15214:15218 15222 15224:15225 15227 15231:15234 15240 15244 15249 15253:15259 15266 15268 15272:15273 15276 15280 15284 15289 15292:15293 15297 15302 15306 15311 15313 15316 15321:15323 15331 15337 15342 15345:15346 15348 15350 15353 15404 15406 15408 15417 15419:15420 15427 15430 15436 15446 15485 15489 15493 15499 15501 15503 15507:15508 15514 15522:15523 15560 15569 15571 15607 15615 15625 15628 15631 15633:15634 15638:15640 15644 15647:15648 15655:15656 15663 15676 15685 15688 15705 15710 15714 15718 15741 15786 15791:15793 15804 15845 15847 15855 15862:15865 15884 15886 15890 15903 15906 15909 15922 15961:15962 15966 15991 16008 16012:16013 16031 16044 16053:16064 16094 16101 16116 16144 16199 16298 16425 16448 16475 16761 16857 16861 16920 17007 17204 17260 17297 17307:17309 17486], 25) = NaN;%SMA50
                    output([1716 4127 4144 4206 4414 4418 4420 4430 4436 4446 4455 4466 4458 4457 12469 13214 14875 15614 15616 15629 4076 4146 4163 4188 4230 4403 4415 7791 9852 12471 12487 12490 12494 12561 12678 12687 12697 12724:12728 12734 12738:12739 12828 12866 12869 12873 12875 12880 12891 12915 12965 13008 13016:13018 13145 13160 13162 13124 13290 13297 13299:13315 13327 13331 13333:13336 13340 13344:13346 13350:13351 13363 13367 13375 13400:13401 13414 13424 13427:13429 13434 13437 13443:13444 13714 13721 13747:13748 13755 13761 13766 13958 13988:13989 14009 14018 14210:14226 14237:14239 14266 14268 14274 14337 14341 14344 14481 14487 14495 14512 14641 14750 14754 14758 14762:14763 14769 14772 14775:14776 14778 14781 14785:14786 14794 14815 14819 14833 14844:14845 14848 14850:14864 14869 13875 14882:14892 14911 14913:14914 14917:14918 14932 14937 14942 14951 14963 14972 14984 14989 14993 14998 15015 15020 15026:15028 15041 15059 15068 15081 15112 15139 15142 15151 15157 15160 15171:15178 15183 15186:15187 15190 15193 15202 15205 15209 15213 15216:15219 15224 15228 15236:15237 15245 15249:15250 15261 15264 15268 15277 15279:15280 15290:15297 15304 15310 15315:15317 15321 15323:15324 15326 15333 15338 15347:15348 15351 15355 15357:15374 15380 15385 15388 15391:15392 15397 15400 15402 15407:15408 15416:15420 15429 15443 15447 15450 15452 15462 15468:15470 15489 15494 15508 15513 15533 15538 15563 15592 15608 15621 15654 15664 15669 15677 15692 15707 15716 15732 15832 15868 15875 15877 15891 16044 16057 16132 16150 16159 16163 16191 16235 16242 16413 16456 16461 16468 16473 16499 16506 16559 16586 16590 16696 16764 16788 16918 16939 17037 17079 17075 17111 17146:17147 17202 17232 17242 17322 17433  15637:15643 15649 15678 15706 15740 15748 15751 15780 15835 15852 15856 15863 15879 15913 15953 15963:15964 16004 16020 16023 16062 16137 16140:16141 16273 16307 16326 16408 16613 16705 16737 16796 16801 16820 16840 16845 16848 16868 16924 16983 16987 17020 17137 17158 17189 17192 17263 17282 17315 17331 17354 17362 17369 17380 17404 17419 17426 17430 17461 17485 17498 17512], 26) = NaN;%SMA20
                    output([12675:12676 12915 13363 14590 14733 14752 14906 14911 15012 15023 15052 15056 15129 15199:15200 15509 15543 15592 15739 16100 16162 16179 16465 16446 16936 17393 17430 17518:17520 2556 3588 4076 4146 4188 4216 4230 4370 4415 4435 4437 9852 9854 10049 10064 10908:10909 11198 11250 12020 12030 12459:12481 12488 12493:12496 12515 12544 12548 12561 12564 12579 12581 12584 12587 12615 12633 12636 12660 12669 12681 12688 12696:12701 12707 12709 12713 12716 12720 12725:12729 12734:12739 12757 12761 12775 12777 12781 12791 12819:12829 12836 12844 12853:12854 12858:12859 12864 12873:12877 12890 12896 12903 12913 13915 12924 12965:12966 12969 12990 12994:12995 13000 13006:13016 13025 13054 13128 13145 13149 13154:13155 13160:13164 13213:13215 13218:13219 13240 13256 13261 13266 13271 13285 13290 13292 13303 13309:13324 13331 13341:13343 13367 13369 13371 13375 13378 13381 13383 13386 13395 13400 13403 13405 13410 13413 13416 13422 13429 13431 13435 13439 13453 13466 13473 13484 13495 13505 13520 13524 13537 13579 13585:13586 13589 13603 13655 13659:13660 13695 13714 13717 13731 13733 13738 13751 13755:13756 13759:13766 13773 13777 13988 14005 14009 14015:14016 14019 14084 14208 14211 14215 14219 14222:14239 14242 14246 14253 14264 14271 14274:14275 14277 14294 14299 14316 14334:14335 14341 14350 14396:14397 14408 14461 14470 14479 14486 14490:14491 14497 14501 14504 14512 14530 14534 14600 14607 14618:14619 14627 14637:14638 14648 14653 14656 14663 14676 14678 14680 14696 14705 14709 14716:14718 14750 14754 14759:14770 14777:14788 14793:14803 14813 14820 14823 14827:14828 14832 14835 14846:14847 14861 14867 14870 14872 14880:14891 14902:14904 14916 14920:14929 14935 14941:14943 14961 14965 14985 14988 15002:15007 15024 15028 15032 15035 15040:15041 15045 15047 15058 15061 15064:15065 15068:15069 15074 15076 15081 15086 15091 15102 15108 15122 15134 15144 15148 15153:15157 15165:15181 15189 15205:15210 15218 15221 15225 15227 15231:15235 15240 15244 15246 15250 15255 15261 15283 15296 15303:15304 15312:15318 15331:15332 15337:15341 15344 15350:15360 15364:15372 15381:15389 15395:15398 15419:15435 15437:15448 15453:15462 15474 15477 15485:15496 15505 15511:15514 15521 15553 15565 15570 15575 15593 15601 15610:15612 15617 15626 15628 15632 15638 15672 15680 15685 15699:15703 15722:15727 15743 15758 15761 15767 15802 15848 15858 15860 15865 15878 15964 15999 16043 16067 16090 16102 16169 16173 16180 16192 16202 16231 16306 16312 16321 16327 16339 16356 16376 16405 16411 16420 16447 16461 16466 16468 16685 16690 16744 16746 16777 16791 16794 16800 16812 16840 16846:16851 16856 16860 16884 16888 16894 16904 16917 16937 16980 16993 17036 17045 17072 17083 17090:17091 17102 17124 17134 17150 17174 17194 17200 17214:17215 17231 17244 17248 17264 17266 17280 17320 17324:17326 17369 17373 17378:17379 17383 17394 17431 17446 17449 17460:17461 17484 17509], 27) = NaN;%SMA10
                    output([16168 16619 16621 16733 17417 4223 9941 12781 13721 1539 1551 2556 2989 4076 4124 4134 4146 4188 4196 4211 4380 4414 4420 4433 4435 4441 4447 4455 5351 6692:6693 9131 9852 9940 11260:11261 11436 11826 12021 12491 12494 12496 12535:12536 12565 12587 12660 12678:12679 12701 12724 12733:12734 12739:12740 12863:12864 12870:12872 12875 12878 13025 13160:13170 13214 13246 13272 13290 13298 13300 13302:13303 13306 13308 13310 13313 13315 13320 13349 13358 13360:13361 13371 13384 13399:13400 13405 13410 13434 13438 13440 13442 13445 13651 13714 13723 13736 13758 13764 13768 13988 14032 14216 14224 14229:14232 14639 14650 14655:14656 14754 14761 14769 14774 14776 14778 14780 14785 14787:14798 14808:14815 14819 14829 14834:14835 14840 14851 14854:14855 14862 14866 14877 14881:14882 14886 14888:14889 14894 14897 14900 14903 14910 14914 14922 14932 14936 14941 14971 14986 14996 15004 15019 15026 15034 15045 15054 15064 15070:15078 15101:15102 15109 15120 15150 15155:15157 15160 15168 15171:15172 15179:15180 15186 15192 15200 15207 15212:15213 15216:15224 15229:15231 15240 15244 15253 15257 15268 15277 15284 15302 15305 15311:15312 15326 15328 15336 15348 15351:15374 15381 15384 15386 15393 15403 15419 15421 15424 15453 15461 15471 15473 15475 15491 15498 15500 15508 15510 15515 15582 15592 15630 15645 15653 15660 15679:15680 15708 15732 15753 15771 15823 15863 15867 15870 15872 15926 15956 15961 16023:16024 16031 16042 16045 16169 16204 16250 16323 16358 16368 16394 16433 16442 16460 16481 16510 16516 16518 16530 16534:16539 16552:16554 16584 16597:16598 16602 16620 16638 16646:16647 16727 16729 16732 16734 16738:16739 16758 16762 16770 16773:16774 16794 16806:16808 16836 16839 16843 16866:16867 16878:16879 16887 16891 16895 16954 16961 16975 17009 17012 17015 17038 17046 17058 17075 17081 17103 17131 17153 17173 17189 17227 17232 17257 17279:17280 17290:17294 17304 17309 17314 17316:17317 17327 17336:17338 17357 17404 17410 17416 17419 17436:17439 17447 17481 17488 17512 17516], 28) = NaN;%SMA5
                    output([3614 4153 4188 4192 4196 4244 4362 4414:4415 4426 4433 4435 4439 4441 4455 7395 7544 7622 7632 7711 7732 7734 7778 7779 7801 7802 7832 7862 12687 12855 12860 12906:12908 13152 15375 15395 15421 15373 15420 15478 15929 16033 16331 16265 16688 16751 17021 17183 17212 17233 17238:17239 17296 17345 17332 17362 17369:17371 17420 17425:17428 17468  3587:3588 4076 7439 9299 12466 12486 12495 12585 12635 12679 12701 12731 12734:12736 12739 12821 12831 12848 12868 12878 12880 12883 12885:12886 12891:12892 12918 13015 13020 13023 13025 13067 13162 13166:13168 13214 13302 13306 13308 13311 13315 13319:13321 13323 13326 13330:13331 13334 13336 13345 13355 13359 13363 13370 13375 13382 13396 13407 13410 13534:13537 13545:13547 13564 13577 13602 13607 13653 13669 13714 13719 13736 13744 13753 13758 13766 13779 13821 13824 13835 13853 13872 13874 13889 13904:13908 13956 13964:13966 13987:13989 14088 14092 14096 14098 14105 14145 14211 14217 14219 14221 14226:14230 14238 14262 14275 14278 14331 14338 14341:14348 14513 14543 14557 14561 14563 14570:14583 14586 14588 14591 14595 14596 14598 14602 14612 14615:14617 14625:14642 14650 14652:14661 14669:14680 14682 14687 14690 14707 14708 14711 14728 14733 14737 14748 14757 14761:14791 14801:14802 14810 14815:14821 14835 14840 14851 14864 14872 14880 14882:14883 14887 14906:14907 14910 14914 14921:14922 14935 14938 14944:14946 14979 15011 15013:15014 15022 15025 15027 15034 15036 15054 15061 15063 15077 15112 15149 15156 15182 15185:15186 15189 15202 15206 15212 15214 15226 15233 15238 15245 15254 15257 15262 15265 15269:15277 15288 15297 15300 15309 15311 15323 15328:15329 15333:15334 15342 15346 15348 15351 15359 15363 15371:15372 15376 15382 15390 15393 15397:15398 15400 15430 15434 15437 15442 15449 15452:15453 15464 15469 15500:15502 15506:15507 15529 15533 15551 15553 15557 15566 15574 15577:15578 15581 15633 15638 15647 15650 15652 15689 15703 15727 15769 15778 15828 15867 15869 15900 15924 15930 15937 15964 15997 16034 16060 16063 16196 16210 16233 16266 16275 16290 16321 16323 16332 16352 16377 16403 16429 16458 16465 16475 16493:16494 16513 16541 16561 16564 16579 16591 16639 16669 16711 16713 16715 16745 16823:16825 16853:16854 16894 16905:16907 16915:16916 16929 16940:16941 16944 16976 16992 17006 17022 17029 17037 17080 17102 17123 17138 17142 17175 17185 17193 17243:17244 17253:17254 17260 17266 17286 17298 17307 17335:17340 17386:17392 17398:17399 17407 17423:17424 17429 17432 17452 17469 17478 17482 17512 17518], 30) = NaN;%SMB20
                    output([4192 3587 3588 4435 4450 4436 4460 5740 9129 9852 12471 12548 13399:13400 13464:13465 14272 14274 14987:14988 15064:15067 15373 15618 15681 15689 15937 16055 17018 17415 4076 4142 4153 4430 9131 12024 12029:12030 12460:12461 12464:12465 12469 12482 12493 12514 12542 12546 12551 12585 12701 12730 12734:12735 12737 12741 12875:12876 12878:12880 12884 12892 12896 12904 12915 12920 12955 12967 13020 13022 13026 13032 13165:13168 13171 13238 13240 13276 13301 13303 13306 13309:13310 13312 13315:13316 13320 13323 13327 13339 13344 13351:13352 13355 13358:13360 13375 13397 13399:13340 13408 13410 13414 13422 13443 13454 13459 13461 13463 13466 13564 13577 13598 13650 13659 13669 13705 13714 13736 13745 13748 13756:13762 13791 13987 14020 14023 14033 14035 14037 14047 14092 14137 14145 14172 14212 14214 14218:14238 14247 14260 14266 14269 14272:1474 14290 14332 14340:14344 14349 14463 14473 14485 14510:14513 14518 14543 14655 14769:14771 14776 14784 14786 14791:14792 14797:14806 14815 14823 14826 14836 14839 14841 14851 14856 14861 14863 14871 14880 14882 14888 14897:14899 14904 14908 14912 14917 14921 14926 14933 14939 14950 14952 14996 15000 15005 15017 15021 15026 15028 15033 15038 15052:15053 15058 15060 15068:15069 15081 15086 15090:15092 15098 15102:15103 15112 15121 15124 15151 15153 15173 15177:15178 15183 15198:15204 15215 15220 15224 15231:15232 15235:15237 15247:15250 15266 15268 15276 15284 15294 15297:15298 15304:15317 15323 15326 15328:15329 15338:15339 15345:15347 15351 15358 15360 15365 15372 15375 15377:15387 15395 15401 15409 15415 15432 15440:15441 15443:15444 15446 15458 15461 15463 15467 15474:15477 15494 15507 15522 15551 15565 15570:15571 15575 15588 15596 15608 15612 15616 15624 15628 15638 15662 15666 15673 15676 15680 15688 15692 15704 15764 15783 15805:15806 15871 15882 15899 15908 15955 15963:15964 16036 16059 16070 16145 16166 16174 16177 16199 16218 16233 16242 16258 16319 16328 16346 16398 16431 16450 16484 16545 16575 16584 16628 16632 16638 16643:16644 16675 16685 16687 16745 16748 16753 16755 16758 16762 16787 16798 16802 16814 16824 16843 16852 16854:16855 16861 16884 16893 16916:16917 16930 16944 16957:16959 16989 17019 17024 17031 17128 17183 17197 17212 17219 17239 17248:17250 17254 17264:17265 17270 17286 17293:17300 17309 17324 17326:17327 17333 17340 17352 17356 17358 17362 17369 17375 17378 17382 17385 17387 17393 17399 17402 17405 17414 17422:17423 17426 17430 17433 17442 17446 17456 17459 17465 17470 17473 17476 17484 17486 17488 17493 17498:17500 17507 17512 17516:17517 17519:17520], 32) = NaN;%SMB5
                    output([1208 2552 2594 2597 2982 14155], 47) = NaN;%CO2Cnpy
                    output([4076 8684 8766 9168 9852 10424 10616 11080 11234 12863 13482 14215 14466], 50) = NaN;%SMDR20
                    output([4076 8413 8759 8860 8923 9129 9185 9263 9865 10505 11182  11862], 51) = NaN;%SMDR5
                    
                    
                    % Swap columns to fix sensor miswiring:
                    A100 = output(:,17); % Pit A 100cm is wired into 2 cm
                    A50 = output(:,16); % Pit A 50cm is wired into 5 cm
                    A20 = output(:,15); % Pit A 20cm is wired into 10 cm
                    A10 = output(:,13); % Pit A 10cm is wired into 50 cm
                    A5 = output(:,14); % Pit A 5cm is wired into 20 cm
                    A2 = output(:,12); % Pit A 2cm is wired into 100 cm
                    B100 = NaN.*A100;  % Pit B 100 seems to have no data.
                    B50 = output(:,23); % Pit B 50cm is wired into 2 cm
                    B20 = output(:,21); % Pit B 20cm is wired into 10 cm
                    B10 = output(:,20); % Pit B 10cm is wired into 20 cm
                    B5 = NaN.*A5; % Pit B 5cm seems to have no data
                    B2 = output(:,19); % Pit B 2cm is wired into 50 cm
                    output(:,12) = A100;
                    output(:,13) = A50;
                    output(:,14) = A20;
                    output(:,15) = A10;
                    output(:,16) = A5;
                    output(:,17) = A2;
                    output(:,18) = B100;
                    output(:,19) = B50;
                    output(:,20) = B20;
                    output(:,21) = B10;
                    output(:,22) = B5;
                    output(:,23) = B2;
                    
                 case '2024' % AH
                    RH_max = 100;
                    output([4850 8219:8239], 1) = NaN;%AirTempAbvCnpy
                    output([4998 5868 6017 6022 6047 6064 6150 6156 6175 6181 6187 6447 6454 6491 6502 6546 6552 6590 6619 6625 6646 6707 6734 6756 6766 6831 6882 6899 7028 7029 7032 7046 7079 7109 7114 7115 7162 7181 7293 7391 7393 7415 7432 7493 7505 7689 7711 7932 7948 7986 8070 8109 8198 8227], 2) = NaN;%RelHumAbvCnpy
                    output([3796 4852 5059 5266 5367 5501 5598 5852:8218 9150], 3) = NaN; %Pressure 
                    output([4643 17025 17553], 6) = NaN; %UpPARAbvCnpy
                    output([4978 5269 17553], 7) = NaN; %DownPARAbvCnpy
                    output([5363 8003 14291], 8) = NaN; %netRadAbvCnpy
                    output([2428 4998 9492 9636 10260], 10) = NaN; %SoilHeatFlux1
                    output([4402 5026], 11) = NaN; %SoilHeatFlux2
                    output([85:86 153 175 183 185 207 239 367 492 576 1075 1092 1125 1126 1142 1153 1209 1277 1316 1362 1424 1500 1520 1582 1613 1631 1644 1707 1817 1830 1838 1854 1885 1893 1901 1918 1927 1946 1951 1986 2041 2048 2065 2105 2387 2465 2468 2604 2621 2631 2684 2959 2988 3027 3037 3058 3068 3075 3098 3123 3126 3143 3246 3298 3304 3309 3411 3412 3129 3447 3464 3507 3540 3565 3650 3693 3796 3838 3849 4062 4069 4101 4143 4224 4237 4242 4243 4251 4252 4258 4259 4267 4339 4426 4812 4838 4856 4917 4953 1834 1845 1847 1858:1860 1864 1869:1870 1875 1879:1880 1884 1902 1904 1906:1907 1909:1911 1914 1917 1920 1924:1925 1929 1932 1934 1940 1942:1943 1953 1963 1966 1972:1973 1982:1983 1988 1999:2001 2004 2015 2017 2020 2022:2023 2029 2036:2037 2045 2051 2061 2092 2097:2098 2115 2133 2135 2140 2160 2163 2183 2191 2196 2198 2202 2205 2218 2225 2228:2229 2243 2324 2326 2352 2360 2355 2367 2392 2399 2449 2451 2489 2494 2496 2502 2511 2513 2518 2526:2527 2529:2530 2536 2541 2544 2549 2552 2557 2567 2578 2582 2588 2606 2623 2634 2637 2647 2649 2667 2676 2693 2703:2704 2710:2711 2716 2719 2721 2722 2728:2729 2731 2747:2748 2750 2753 2762 2771 2775 2785 2787:2788 2793:2794 2797:2798 2800 2803:2806 2808 2811 2816:2817 2819:2820 2826:2827 2845 2848 2856 2859 2864 2868 2873 2877 2882 2886:2887 2891:2893 2898 2901 2912:2915 2917], 12) = NaN; %SoilTempA1_00cm
                    %SoilTempA5_0cm:
                    output([7 9 54 56 60 65 80 96 108 109 112 132 149 163 164 177 184 198 202 209 231 301 320 330 343 349 351 381 402 403 409 416 423 430 438 439 445 447 452 454 458 459 480 481 483 489 497 498 503 519:521 553], 13) = NaN;
                    output([560:562 567 580 583 598 602 621 637 650 651 654 667 684 689 767 847 853 859 884 997 1001 1035 1041 1058 1066 1070 1075 1120 1143 1154 1156 1167 1174 1191 1192 1208 1212 1213 1223 1266 1274 1277 1284 1309 1359:1361 1380 1381 1432 1460 1467 1475 1478 1502 1506 1513 1546 1562 1566 1622 1623 1658 1697 1710 1817 1820 1823:1825 1827 1830 1833:1836 1840 1842 1850 1857], 13) = NaN; 
                    output([1866 1867 1880 1884 1886:1888 1864 1900 1904 1909 1917:1919 1923 1930 1943 1944 1947 1951 1953 1984 1990 1992 1998 2002 2003 2004 2015 2022 2028 2034 2048 2067 2068 2094:2098 2116 2122 2124 2125 2128:2130 2133:2136 2139 2143 2146 2148 2150 2152 2154 2161 2163 2164 2166 2171 2173 2174 2179 2183 2184 2188 2189 2191 2193 2195:2197 2201 2202 2209:2211 2213:2216 2222:2224 2227],13) = NaN;
                    output([2230 2232 2235 2239 2244 2246:2248 2250 2252 2255 2256 2258 2266 2270 2272 2277 2282 2287 2296 2299 2313 2319 2322 2338 2345 2349 2360 2362 2365 2380 2384 2385 2387:2389 2393 2395 2399 2402 2404 2405 2408 2412 2415 2417 2421 2429 2430 2432 2434:2437 2441 2443:2445 2448 2449 2457 2460 2465 2469 2470 2476:2479 2482 2484:2486 2488 2489 2492 2513:2515 2533 2534 2553 2554 2556:2559 2561:2563 2573 2574 2578:2583 2589 2592 2594 2595 2597:2599 2601 2605 2606 2611 2621 2628 2630:2633 2648 2656 2671 2676 2678 2686 2689 2692 2696 2698 2700 2702 2705 2707 2709 2713 2715 2716 2781 2783 2800 2815:2819 2825 2829 2831],13) = NaN;

            end
            %% Corrections applied to all years of data:
            % 1: Set any negative PAR and nighttime PAR to zero:
            PAR_cols = [];
            try
                PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'DownPAR_AbvCnpy')==1)];
                PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'UpPAR_AbvCnpy')==1)];
                PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'DownPAR_BlwCnpy')==1)];
            catch
            end
            %%% Set the bottoms of PAR (a
            if strcmp(site,'TP74')==1 && year_ctr == 2003
                DownParBot = 19;
                UpParBot = 21.5;
                DownParBlwBot = 15;
            else
                DownParBot = 10;
                UpParBot = 10;
                DownParBlwBot = 10;
            end
            %Plot uncorrected:
            figure(97);clf;
            subplot(211)
            plot(output(:,PAR_cols)); legend(output_names_str(PAR_cols,:))
            title('Uncorrected PAR');
            %         if year <= 2008
            [sunup_down] = annual_suntimes(site, year_ctr, 0);
            %         else
            %             [sunup_down] = annual_suntimes(site, year, 0);
            %         end
            ind_sundown = find(sunup_down< 1);
            figure(55);clf;
            plot(output(:,PAR_cols(1)))
            hold on;
            plot(ind_sundown,output(ind_sundown,PAR_cols(1)),'.','Color',[1 0 0])
            title('Check to make sure timing is right')
            try
                %             output(output(:,PAR_cols(1)) < 10 & sunup_down < 1,PAR_cols(1)) = 0;
                %             output(output(:,PAR_cols(2)) < 10 & sunup_down < 1,PAR_cols(2)) = 0;
                %             output(output(:,PAR_cols(3)) < 10 & sunup_down < 1,PAR_cols(3)) = 0;
                output(output(:,PAR_cols(1)) < DownParBot & sunup_down < 1,PAR_cols(1)) = 0;
                output(output(:,PAR_cols(2)) < UpParBot & sunup_down < 1,PAR_cols(2)) = 0;
                output(output(:,PAR_cols(3)) < DownParBlwBot & sunup_down < 1,PAR_cols(3)) = 0;
            catch
            end
            try
                output(output(:,PAR_cols(1)) < 0 , PAR_cols(1)) = 0;
                output(output(:,PAR_cols(2)) < 0 , PAR_cols(2)) = 0;
                output(output(:,PAR_cols(3)) < 0 , PAR_cols(3)) = 0;
            catch
            end
            % Plot corrected data:
            figure(97);
            subplot(212);
            plot(output(:,PAR_cols)); legend(output_names_str(PAR_cols,:))
            title('Corrected PAR');
            
            % 2: Set any RH > 100 to NaN -- This is questionable whether to make
            % these values NaN or 100.  I am making the decision that in some
            % cases
            RH_cols = [];
            try
                RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_AbvCnpy')==1)];
                RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_Cnpy')==1)];
                RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_BlwCnpy')==1)];
            catch
            end
            % Adjust columns to match output:
            %     RH_cols = RH_cols - 6;
            figure(98);clf;
            subplot(211)
            plot(output(:,RH_cols)); legend(output_names_str(RH_cols,:))
            title('Uncorrected RH')
            if ~isempty(RH_max)
                RH_resp = RH_max; % RH_max should be set within each year of data.
            else
                commandwindow;
                RH_resp = input('Enter value to set RH > 100 to? (100 or NaN): ');
            end
%             RH_resp = input('Enter value to set RH > 100 to? (100 or NaN): ');
            for j = 1:1:length(RH_cols)
                output(output(:,RH_cols(j)) > 100,RH_cols(j)) = RH_resp;
            end
            subplot(212);
            plot(output(:,RH_cols)); legend(output_names_str(RH_cols,:))
            title('Corrected RH');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'TP89'
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%% TP89  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            switch yr_str
                case '2002'
                    %%%%%%%%%%%%%%%%%%%%% START SHIFTING %%%%%%%%%%%%%%%%%%
                    % Shift data so that it's all in UTC: %%%%%%%%%%%%%%%%%%%%
                    % need to load last 8 datapoints from 2001
                    num_to_shift = 8;
                    for i = 1:1:length(vars30)
                        try
                            temp_var = load([load_path site '_2001.' vars30_ext(i,:)]);
                        catch
                            %                         disp(['could not load the 2001 variable: ' names30_str(i,:)]);
                            %                         disp(['Check if column should exist -- making NaNs']);
                            temp_var = NaN.*ones(len_yr,1);
                        end
                        
                        fill_data(1:num_to_shift,i) = temp_var(end-num_to_shift+1:end);
                        clear temp_var;
                    end
                    output_test = [fill_data(:,:); output(1:end-num_to_shift,:)];
                    clear fill_data;
                    clear output;
                    output = output_test;
                    clear output_test;
                    %%%%%%%%%%%%%%%%%%%%% END SHIFTING %%%%%%%%%%%%%%%%%%
                case '2003'
                    for i = 1:1:length(vars30)
                        try
                            temp_var = load([load_path site '_2002.' vars30_ext(i,:)]);
                        catch
                            disp(['could not load the 2002 variable: ' names30_str(i,:)]);
                            disp(['Check if column should exist -- making NaNs']);
                            temp_var = NaN.*ones(len_yr,1);
                        end
                        
                        fill_data(1:8,i) = temp_var(end-8+1:end);
                        clear temp_var;
                    end
                    output = [fill_data(:,:); output(9:end,:)];
                    clear fill_data;
                case '2005'
                    
                    %%%%%%%%%%%%%%%%%%%%% START SHIFTING %%%%%%%%%%%%%%%%%%
                    % Shift data so that it's all in UTC: %%%%%%%%%%%%%%%%%%%%
                    % need to load first 1 datapoint from 2006
                    num_to_shift = -1;
                    for i = 1:1:length(vars30)
                        try
                            temp_var = load([load_path site '_2006.' vars30_ext(i,:)]);
                        catch
                            %                         disp(['could not load the 2001 variable: ' names30_str(i,:)]);
                            %                         disp(['Check if column should exist -- making NaNs']);
                            
                            temp_var = NaN.*ones(len_yr,1);
                        end
                        
                        fill_data(1:abs(num_to_shift),i) = temp_var(1:0-num_to_shift);'/1/fielddata/Matlab/Scripts'
                        clear temp_var;
                    end
                    output_test = [ output(1-num_to_shift:end,:); fill_data(:,:)];
                    clear fill_data;
                    clear output;
                    output = output_test;
                    clear output_test;
                    %%%%%%%%%%%%%%%%%%%%% END SHIFTING %%%%%%%%%%%%%%%%%%
                case '2007'
                case '2008'
                    % Adjust nighttime PAR to fix offset:
                    output(output(:,6) < 8,6) = 0;
                    % Adjust RH to be 100 when it is >100
                    output(output(:,2) > 100,2) = 100;
                    
                    % Shift data so that it's all in UTC:
                    % need to load last 8 datapoints from 2007
                    for i = 1:1:length(vars30)
                        temp_var = load([load_path site '_2007.' vars30_ext(i,:)]);
                        fill_data(1:8,i) = temp_var(end-7:end);
                        clear temp_var;
                    end
                    output_test = [fill_data(:,:); output(1:end-8,:)];
                    clear fill_data;
                    clear output;
                    output = output_test;
                    clear output_test;
                    
                    
            end
            %% Corrections applied to all years of data:
            % 1: Set any negative PAR and nighttime PAR to zero:
            PAR_cols = [];
            try
                PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'DownPAR_AbvCnpy')==1)];
                PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'UpPAR_AbvCnpy')==1)];
                PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'DownPAR_BlwCnpy')==1)];
            catch
            end
            
            %Plot uncorrected:
            figure(97);clf;
            subplot(211)
            plot(output(:,PAR_cols)); legend(output_names_str(PAR_cols,:))
            title('Uncorrected PAR');
            %         if year <= 2008
            [sunup_down] = annual_suntimes(site, year_ctr, 0);
            %         else
            %             [sunup_down] = annual_suntimes(site, year, 0);
            %         end
            ind_sundown = find(sunup_down< 1);
            figure(55);clf;
            plot(output(:,PAR_cols(1)))
            hold on;
            plot(ind_sundown,output(ind_sundown,PAR_cols(1)),'.','Color',[1 0 0])
            title('Check to make sure timing is right')
            
            
            try
                output(output(:,PAR_cols(1)) < 10 & sunup_down < 1,PAR_cols(1)) = 0;
                output(output(:,PAR_cols(2)) < 10 & sunup_down < 1,PAR_cols(2)) = 0;
                if year >=2005 && year <=2006
                output(output(:,PAR_cols(3)) < 100 & sunup_down < 1,PAR_cols(3)) = 0;
                else
                output(output(:,PAR_cols(3)) < 10 & sunup_down < 1,PAR_cols(3)) = 0;
                end
            catch
            end
            try
                output(output(:,PAR_cols(1)) < 0 , PAR_cols(1)) = 0;
                output(output(:,PAR_cols(2)) < 0 , PAR_cols(2)) = 0;
                output(output(:,PAR_cols(3)) < 0 , PAR_cols(3)) = 0;
            catch
            end
            % Plot corrected data:
            figure(97);
            subplot(212);
            plot(output(:,PAR_cols)); legend(output_names_str(PAR_cols,:))
            title('Corrected PAR');
            
            % 2: Set any RH > 100 to NaN -- This is questionable whether to make
            % these values NaN or 100.  I am making the decision that in some
            % cases
            RH_cols = [];
            try
                RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_AbvCnpy')==1)];
                RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_Cnpy')==1)];
                RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_BlwCnpy')==1)];
            catch
            end
            % Adjust columns to match output:
            %     RH_cols = RH_cols - 6;
            figure(98);clf;
            subplot(211)
            plot(output(:,RH_cols)); legend(output_names_str(RH_cols,:))
            title('Uncorrected RH')
            if ~isempty(RH_max)
                RH_resp = RH_max; % RH_max should be set within each year of data.
            else
                commandwindow;
                RH_resp = input('Enter value to set RH > 100 to? (100 or NaN): ');
            end
%             RH_resp = input('Enter value to set RH > 100 to? (100 or NaN): ');
            for j = 1:1:length(RH_cols)
                output(output(:,RH_cols(j)) > 100,RH_cols(j)) = RH_resp;
            end
            subplot(212);
            plot(output(:,RH_cols)); legend(output_names_str(RH_cols,:))
            title('Corrected RH');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'TP02'
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%% TP02  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% PAR Correction factors for 2002, 2013--2017 % Determined from TP02_par_correction_factor.m
            %%% 2024-07-08: Values for 2024 and 2025 are copied from 2023
            

            par_correction_factor = [2002, 1.23; 2013, 1.38199647061725; 2014, 1.26172364359607; 2015,1.03313933608525; 2016,0.874165785537350; 2017,0.659991285147933; 2018,0.585666951857723; 2019,0.568972797317526; ...
									2020, 0.560100471025222; 2021, 0.538677529088550; 2022, 0.439130078950065; 2023, 0.429167158196256 ; 2024, 0.429167158196256; 2025, 0.429167158196256];
                                
            par_correction_factor = par_correction_factor(par_correction_factor(:,1)==year_ctr,2);
            switch yr_str
                case '2002'
                    % Swap some mixed up SM sensors:
                    SM50B_orig = output(:,output_cols(strcmp(output_names,'SM_B_50cm')==1));
                    SM20B_orig = output(:,output_cols(strcmp(output_names,'SM_B_20cm')==1));
                    
                    output(:,output_cols(strcmp(output_names,'SM_B_50cm')==1)) = SM20B_orig(1:end,1);
                    output(:,output_cols(strcmp(output_names,'SM_B_20cm')==1)) = SM50B_orig(1:end,1);
                    clear SM50B_orig SM20B_orig;
                    
                    % Perform a scaling correction for PAR (use correction
                    % factor that was derived by inter-year comparison at
                    % the site).
                    output(:,5) = output(:,5).*par_correction_factor;
                    
                    %%%%%%%%%%%%%%%%%%%%% START SHIFTING %%%%%%%%%%%%%%%%%%
                    % Shift data so that it's all in UTC: %%%%%%%%%%%%%%%%%%%%
                    % need to load last 8 datapoints from 2001
                    num_to_shift = 7;
                    for i = 1:1:length(vars30)
                        try
                            temp_var = load([load_path site '_2001.' vars30_ext(i,:)]);
                        catch
                            %                         disp(['could not load the 2001 variable: ' names30_str(i,:)]);
                            %                         disp(['Check if column should exist -- making NaNs']);
                            temp_var = NaN.*ones(len_yr,1);
                        end
                        
                        fill_data(1:num_to_shift,i) = temp_var(end-num_to_shift+1:end);
                        clear temp_var;
                    end
                    output_test = [fill_data(:,:); output(1:end-num_to_shift,:)];
                    clear fill_data;
                    clear output;
                    output = output_test;
                    clear output_test;
                    %%%%%%%%%%%%%%%%%%%%% END SHIFTING %%%%%%%%%%%%%%%%%%
                case '2003'
                    for i = 1:1:length(vars30)
                        try
                            temp_var = load([load_path site '_2002.' vars30_ext(i,:)]);
                        catch
                            disp(['could not load the 2002 variable: ' names30_str(i,:)]);
                            disp(['Check if column should exist -- making NaNs']);
                            temp_var = NaN.*ones(len_yr,1);
                        end
                        
                        fill_data(1:8,i) = temp_var(end-8+1:end);
                        clear temp_var;
                    end
                    output = [fill_data(:,:); output(9:end,:)];
                    clear fill_data;
                    
                case '2004'
                    % Swap some mixed up SM sensors:
                    SM5B_orig = output(:,output_cols(strcmp(output_names,'SM_B_5cm')==1));
                    SM20B_orig = output(:,output_cols(strcmp(output_names,'SM_B_20cm')==1));
                    
                    output(:,output_cols(strcmp(output_names,'SM_B_5cm')==1)) = SM20B_orig(1:end,1);
                    output(:,output0_cols(strcmp(output_names,'SM_B_20cm')==1)) = SM5B_orig(1:end,1);
                    
                    clear SM5B_orig SM20B_orig;
                    
                case '2005'
                    %%%%%%%%%%%%%%%%%%%%% START SHIFTING %%%%%%%%%%%%%%%%%%
                    % Shift data so that it's all in UTC: %%%%%%%%%%%%%%%%%%%%
                    % need to load first 1 datapoint from 2006
                    num_to_shift = -1;
                    for i = 1:1:length(vars30)
                        try
                            temp_var = load([load_path site '_2006.' vars30_ext(i,:)]);
                        catch
                            %                         disp(['could not load the 2001 variable: ' names30_str(i,:)]);
                            %                         disp(['Check if column should exist -- making NaNs']);
                            
                            temp_var = NaN.*ones(len_yr,1);
                        end
                        
                        fill_data(1:abs(num_to_shift),i) = temp_var(1:0-num_to_shift);
                        clear temp_var;
                    end
                    output_test = [ output(1-num_to_shift:end,:); fill_data(:,:)];
                    clear fill_data;
                    clear output;
                    output = output_test;
                    clear output_test;
                    %%%%%%%%%%%%%%%%%%%%% END SHIFTING %%%%%%%%%%%%%%%%%%
                    set_to_zero = [6241:6262 7492:7509 7539:7557 7588:7605 7636:7653]';
                    output(set_to_zero,output_cols(strcmp(output_names,'DownPAR_AbvCnpy')==1))=0;
                    output(set_to_zero,output_cols(strcmp(output_names,'UpPAR_AbvCnpy')==1))=0;
                    
                    clear set_to_zero
                    
                    
                case '2006'
                    % Swap some mixed up Ts sensors:
                    Ts5B_orig = output(:,output_cols(strcmp(output_names,'SoilTemp_B_5cm')==1));
                    Ts2B_orig = output(:,output_cols(strcmp(output_names,'SoilTemp_B_2cm')==1));
                    
                    output(:,output_cols(strcmp(output_names,'SoilTemp_B_5cm')==1)) = Ts2B_orig(1:end,1);
                    output(:,output_cols(strcmp(output_names,'SoilTemp_B_2cm')==1)) = Ts5B_orig(1:end,1);
                    
                    clear Ts5B_orig Ts2B_orig;
                    
                case '2007'
                    
                case '2008'
                    
                    % step 1 - remove bad data:
                    output(3037:7181,1:2) = NaN; %broken HMP caused problems for HMP, Wind
                    output(4753:7181,3:4) = NaN; %broken HMP caused problems for HMP, Wind
                    % PAR up and down sensors backwards for short period
                    temp = output(4446:4752,5);
                    output(4446:4752,5) = output(4446:4752,6);
                    output(4446:4752,6) = temp;
                    clear temp
                    
                    % Remove spikes in soil variables:
                    %Ts
                    output([966:1:990 3357 11056 11060 11062 11063 11295],11) = NaN;
                    output([966:1:990 3357 4057 5899 7181 10782],12) = NaN;
                    output([966:1:990 3357 11274],13) = NaN;
                    output([966:1:990 3357],16) = NaN;
                    output([966:1:990 5899],17) = NaN;
                    output([966:1:990 3357 11345],18) = NaN;
                    output([966:1:990 3346 11345],20) = NaN;
                    output([966:1:990 11295 11345 12020],21) = NaN;
                    output([966:1:990 11191 11249 11297 11345],22) = NaN;
                    %SM
                    output([966:1:990 11191 11295 11329 12068],23) = NaN;
                    output([966:1:990 6015 5903 5904 11345 11191 11295 12008],25) = NaN;
                    output([966:1:990 5899 5900 5903 5904 5936:5939 6015 11191 11295 11345 11590 12008 12020 12068],26) = NaN;
                    output([966:1:990 3361 5899 5900 5903 5904 11191 11345 11590 12008 12020 12068],27) = NaN;
                    output([966:1:990 5903 5904 5935:5939 6015 11590 12008],28) = NaN;
                    output([966:1:990 11191 12018 12068],29) = NaN;
                    output([966:1:990 11590 12008],30) = NaN;
                    output([966:1:990 4286 11191 11295],31) = NaN;
                    
                    
                    % step 2 - re-arrange soil variables:
                    SM80B = output(:,31); SM50B = output(:,27); SM20B = output(:,28);
                    SM10B = output(:,29); SM5B = output(:,30);
                    output(:,27) = SM80B; output(:,28) = SM50B; output(:,29) = SM20B;
                    output(:,30) = SM10B; output(:,31) = SM5B;
                    
                    clear SM80B SM50B SM20B SM10B SM5B;
                    
                    SM5A = output(:,25); SM10A = output(:,26);
                    output(:,25) = SM10A; output(:,26) = SM5A;
                    clear SM5A SM10A;
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %   Step 3
                    % Shift data so that it's all in UTC:
                    % need to load first 8 datapoint from 2007
                    for i = 1:1:length(vars30)
                        try
                            temp_var = load([load_path site '_2007.' vars30_ext(i,:)]);
                        catch
                            temp_var = NaN.*ones(17520,1);
                        end
                        fill_data(1:8,i) = temp_var(end-7:end);
                        clear temp_var;
                    end
                    output_test = [fill_data(:,:); output(1:6319,:); NaN.*ones(2,length(vars30)); output(6320:7178,:); output(7181:11713,:); output(11744:12068,:); NaN.*ones(22,length(vars30)); output(12069:end,:)];
                    clear fill_data;
                    clear output;
                    output = output_test;
                    clear output_test;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                case '2009'
                    % Bad Data in HMP:
                    output(4906:5650,1:2) = NaN;
                    % Bad data in other variables:
                    output(4906:5115,5:10) = NaN;
                    
                    bad_pts = [5116 10755 10984]';
                    output(bad_pts, 11:31) = NaN;
                    clear bad_pts;
                    output(14477,23:31) = NaN;
                    
                    % Clean up spikes in soil data:
                    %                 output(
                    % run [tracker] = jjb_remove_data(output(:,col)); on
                    % columns 11--22
                    % spot clean 23--31.
                    for col = 11:1:22
                        try
                            tracker = load([tracker_path 'TP02_2009_tr.0' num2str(col)]);
                            disp(['loading tracker for column ' num2str(col) '. ']);
                            
                            resp = input('Do you want to continue to edit the tracker? (<y> to edit, <n> to skip: ', 's');
                            
                            if strcmp(resp,'y') == 1;
                                output(:,col) = output(:,col).*tracker;
                                clear tracker
                                
                                [tracker] = jjb_remove_data(output(:,col));
                                
                                save([tracker_path 'TP02_2009_tr.0' num2str(col)],'tracker','-ASCII')
                            else
                            end
                            
                        catch
                            disp('cannot find tracker -- making a new one');
                            [tracker] = jjb_remove_data(output(:,col));
                            save([tracker_path 'TP02_2009_tr.0' num2str(col)],'tracker','-ASCII')
                            
                        end
                        
                        output(:,col) = output(:,col).*tracker ;
                        clear tracker
                        %                    ctr2 = ctr2+1;
                    end
                    
                    % Step 4: fill gaps in data with available data from the
                    % OPEC system:
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% WORKING
                    tmp4 = load([loadstart 'Matlab/Data/Flux/OPEC/TP02/Cleaned/TP02_30min_Master_2008.dat']);
                    %Ta_temp2 = load([loadstart 'Matlab/Data/Flux/OPEC/old/Cleaned3/TP02/Column/TP02_HHdata_2008.069']);
                    Ta_temp = tmp4(:,69);
                    Ta = [NaN.*ones(11,1); Ta_temp(1:end-11,1)];%Ta_temp(1:10778,1); NaN.*ones(5,1); Ta_temp(10779:length(Ta_temp)-8,1)];
                    Ta(5800:5805,1) = NaN;
                    %                 Ta(1:5796,1) = NaN;
                    %WS_temp2 = load([loadstart 'Matlab/Data/Flux/OPEC/old/Cleaned3/TP02/Column/TP02_HHdata_2008.046']);
                    WS_temp =  tmp4(:,46);
                    WS = [NaN.*ones(11,1); WS_temp(1:end-11,1)];
                    %                 WS = [WS_temp(1:10781,1); NaN.*ones(8,1); WS_temp(10782:length(Ta_temp)-8,1)];
                    % rWS = load([loadstart 'Matlab/Data/Flux/OPEC/Cleaned3/TP02/Column/TP02_HHdata_2008.047']);
                    %Wdir_temp2 = load([loadstart 'Matlab/Data/Flux/OPEC/old/Cleaned3/TP02/Column/TP02_HHdata_2008.044']);
                    Wdir_temp =  tmp4(:,44);
                    Wdir = [NaN.*ones(11,1); Wdir_temp(1:end-11,1)];
                    %                 Wdir = [Wdir_temp(1:10781,1); NaN.*ones(8,1); Wdir_temp(10782:length(Ta_temp)-8,1)];
                    
                    %%% Fill in blanks:
                    output(isnan(output(:,1)),1) = Ta(isnan(output(:,1)),1);
                    output(isnan(output(:,3)),3) = WS(isnan(output(:,3)),1);
                    %                 output(isnan(output(:,4)),4) = Wdir(isnan(output(:,4)),1);
                case '2010'
                case '2011'
                    %                     output(1126:1128,1) = NaN; % just a test:
                    % Missing in data for all fields
                    output(5988:6088, 1:38) = NaN;
                    % Bad Soil moisture data
                    output(10588,12) = NaN;
                    output(10584:10587,14) = NaN;
                    output([10590 10599],16) = NaN;
                    output(10586:10594,17) = NaN;
                    output(11987:end,10) = NaN;
                    
                case '2012'
                    % Bad precipitation data
                    output([1:3164 5792:5845], 10) = NaN;
                    % Bad Down PAR above canopy
                    output(16600:end,5) = NaN;
                    % Bad Net radiometer data (sensor replaced Jan. 8/13)
                    output(15113:end,7) = NaN;
                    % Bad Up PAR Above canopy
                    output(17170:17172,6) = NaN;
                    % Bad Atm pressure
                    output(807:943, 35) = NaN;
                    
                case '2013'
                    % Missing data in all sensors
                    output(7765:8060,:) = NaN;
                    % Bad Down PAR above canopy (missing)
                    output([1:1083 1284:1719],5) = NaN;
                    % Correction factor to correct for wrong multiplier used from February to June in Down PAR sensor.
                    % (Correct multipler/wrong multipler) = (282.05/170.36) = 1.65561
                    output([2675:8064],5) = output([2675:8064],5)*1.65561;
                    % Perform a scaling correction for PAR (use correction
                    % factor that was derived by inter-year comparison at
                    % the site).
                    output(:,5) = output(:,5).*par_correction_factor;
                    
                    % Bad Up Par abv cnpy
                    output([9609:9633 10058:10062 10204:10205 10502:10542 11423:12069],6) = NaN;
                    % Missing SM sensors
                    output(:,32:34) = NaN;
                    % Remove bad P data
                    output([6130:12091],10) = NaN;
                    
                    output([1384:1719 ],35) = NaN;
                    
                    
                case '2014'
                    % downPar and upPar abv canopy... not sure what to do
                    % (reduced/huge increase respectively)
                    % These two variables are swapped because the sensor is
                    % wired in upside-down.
                    tmp = output(10068:11552,5);
                    output(10068:11552,5) = output(10068:11552,6);
                    output(10068:11552,6) = tmp;
                    clear tmp;
                    output([3437:3449 7093 10170:10171],6) = NaN;
                    
                    %%% Fix an magnitude issue with PAR down between points
                    %%% 10068 and 11552. Inspection showed that PAR should
                    %%% be increased by a factor of 1.1765.
                    %%%
                    output(10068:11552,5) = NaN;
                    
                    % Perform a scaling correction for PAR (use correction
                    % factor that was derived by inter-year comparison at
                    % the site).
                    output(:,5) = output(:,5).*par_correction_factor;

                    
                    % Jan. 13 2015 - Removing PAR data after sensor down
                    % mid-summer (whole year or until re-started in winter?
                    output(9831:16507,6) = NaN;
                    
                    % Remove spikes in Ta
                    output(10975:10988,1) = NaN;
                    % Remove questionable points in RH
                    output([1533:1541],8:9) = NaN;
                    % Bad Rn points
                    output([465 4799 11093 12671 13774],7) = NaN;
                    % Remove questionable points in SHF
                    output([10973 11174 11181 11191:11200],2) = NaN;
                    % Bad Precip Points
                    output(11600:end,10) = NaN;
                    % Bad soil temp data points
                    output([10160:10162 10492 10187:10202 10244:10246 10348 10378:10380 10387:10396 10420:10455 10466:10493 10525:10543 10561:10591 10611:10640 10658:10687 10698:10734 10740:10828 10849:10876 10898:10973],[11:19 21:29 31]) = NaN;
                    output([10992:11018 11054:11068 11103:11110 11118 11137:11164 11200:11214 11235:11268],[11:19 21:29 31]) = NaN;
                    output([11278:11312 11339:11356 11540:11554 15705 16500],[11:19 21:29 31]) = NaN; % Pts in all sensors (abv)
                    output([12387:12413 12526 13707:13714],11)  = NaN; % Specific sensors
                    output(12526,12:13)  = NaN;
                    output(8004,14)  = NaN;
                    output([10878 12526],17)  = NaN;
                    output([10397 10878 12526],18)  = NaN;
                    output([10878 12526 14779:14812],19)  = NaN;
                    output([10397 10878],22)  = NaN;
                    %%% Ts b10 stopped working
                    output(9830:end,20) = NaN;
                    output(8004,20)  = NaN;
                    
                    % Poor SM a 50cm  and 20cm points
                    output([9830 10878 15705 16500],23) = NaN;
                    % Poor SM a 10cm and 5cm points
                    output([8736 8753 8761:8762 14698 14975:14977 14987 14991:14996 15006:15020 15025:15026 15030:15032 15037:15044 15048:15053 15066:15095 15705 16500],25:26) = NaN;
                    % SM B 0-100 points
                    output([10068:10159 ],27) = NaN;
                    % Poor SM b 10cm points
                    output([9294 10404 10444 10746 10493 10542 10590 10639 10686 10734 10745 10746],30) = NaN;
                    % Poor SM b 5cm points
                    output([8004 10068:10076],31) = NaN;
                    % Other bad SM data (all sensors)
                    output([10068:10076 10878 12526 13097 15705 16500],23:31) = NaN;
                    % Missing SM 10-12 sensors
                    output(:,32:34) = NaN;
                    
                    % Spikes in Pressure data
                    output([ 5700:5706 6053:6057 6360:6365 6745:6750 10068 10161 10201:10296 10406:10412 11552],35) = NaN;
                    
                    
                case '2015'
                    % Perform a scaling correction for PAR (use correction
                    % factor that was derived by inter-year comparison at
                    % the site).
                    output(:,5) = output(:,5).*par_correction_factor;

                    % Spike in Net Rad Above Canopy
                    output([2977 4067 7587 15586],7) = NaN;
                    % Bad Soil Heat Flux points
                    output([14260:14263],8) = NaN;
                    % TBRG (col 10) data is useless -- in an enclosed gap
                    % in trees
                    output(:,10) = NaN;
                    % Bad soil temp data points
                    output([260 1251 2059],[11 12 13 15 16 17 18 19 21:22 27:31]) = NaN; %
                    % Spikes Ts A 100 cm
                    output([2965 3116 3818 4417:4448 4745:4778 5046 5195 5360 5750 5872 6235 6289:6302 7216:7218 7362 7590:7602 7623:7626 7642:7643 7907 7923:7931 ...
                        8549:8555 8563:8578 8588:8599 8949:8956 8995:9001 9103:9106 9128 9336:9340 9491:9495 10283:10299 10320:10328 10383 ...
                        10651:10652 11147 11225 11252:11261 11369 11678:11694 12019 12165:12174 12190:12195 12545:12548 12567:12571 12595:12596 ...
                        12940:12965 13249:13253 13499:13519 13753:13755 14062:14065 14146 14242:14264 14416:14418 14470 ...
                        14602:14605 14855:14856 15051:15052 15148:15151 15585:15589 15883:15885 15894:15895 16091:16096],11) = NaN;
                    
                    
                    output([3652 4067 4545 7136 8108 8739 9707 10596 12238 13346 13590 14652 14770 15308 15339:15342 15423:15424 15814:15819 16448:16453 16485:16492],12) = NaN;
                    output([3314 3869 4006 4033 4274 5072 5221 8672 8937 9319 9656 9682 10212 11173 11509 11546 12357 12454 12498 13279 13397 14387 ],13) = NaN;
                    output([2939 3600 3792 3989 4232 4247 4638 4664 4749 13684 13736 14508 14575 15376 16365 16531 16557],14) = NaN;
                    output([1251 2059  ],[14 23:31]) = NaN;
                    
                    %                     output([
                    
                case '2016'
                    % Perform a scaling correction for PAR (use correction
                    % factor that was derived by inter-year comparison at
                    % the site).
                    output(:,5) = output(:,5).*par_correction_factor;
                    % Spike in Down PAR above canopy
                    output([2770 6582 12226],5) = NaN;
                    % Spike in Net Radiation Above Canopy
                    output([2242 3932 4371 4860 6852 12226 17449 17450],7) = NaN;
                    % Spike in Soil Heat Flux 1
                    output([8550 8552 9763 10200 10201 14727],8) = NaN;
                    % Remove all of SHF 2 (sensor is broken):
                    output(:,9) = NaN;
                    % Spike in Soil Temperature Pit A 100cm
                    output([1592 1593 2623 2624 4061:4063 4107 10501 11424 11425 11685 17034 17035 17072 17303:17305],11) = NaN;
                    % Spike in Soil Temperature Pit A 50cm
                    output([1261 1644 1766 2483 4105 4561 4710 5809 6300],12) = NaN;
                    % Spike in Soil Temperature Pit A 20cm
                    output([1332 2018 3403 5021 5863 6226],13) = NaN;
                    % Spike in Soil Temperature Pit A 10cm
                    output([1670 2248 3183 14052 14053],14) = NaN;
                    % Spikes in Soil Temperature Pit A 5cm
                    output([1065 1165 1235 1280 1403 1714 1740 1992 2078 2319 2561 3280 3818 4832 14052 14053],15) = NaN;
                    % Spike in Soil Temperature Pit A 2cm
                    output([1209 2155 3956 4588 4632 4857 14052],16) = NaN;
                    % Spike in Soil Temperature Pit B 100cm
                    output([1332 2631 2924 4105 4131 4995 5190 14052 14053],17) = NaN;
                    % Spike in Soil Temperature Pit B 50cm
                    output([3376 5232 5646 5950 6274 14052 14053],18) = NaN;
                    % Spike in Soil Temperature Pit B 20cm
                    output([1228 1280 1489 1992 2334 2844 3058 4517 4663 5782 5783 8261:8263 9780 17203],19) = NaN;
                    % Spike in Soil Temperature Pit B 5cm
                    output([1116 1332 2631 3142 4562 13287 13288],21) = NaN;
                    % Spike in Soil Temperature Pit B 2cm
                    output([1455 2052 5404 5837 14052],22) = NaN;
                    % Spike in Soil Moisture Pit A 50cm
                    output([2475 4762],23) = NaN;
                    
                 case '2017'
                    % Relative Humidity
                    output([181 451 2960 6326 8013 16222 16399],2) = NaN;
                    % Down PAR Above Canopy
                    output([3305 7228 7672 8197 8434 9060 9250 11893],5) = NaN;
                    % Perform a scaling correction for PAR (use correction
                    % factor that was derived by inter-year comparison at
                    % the site).
                    output(:,5) = output(:,5).*par_correction_factor;

                    % Net Radiation Spikes
                    output([5138 7229 11893 14339],7) = NaN;
                    % Soil Heat Flux1
                    output([5763 5764 5795 5796 10745],8) = NaN;                                               
                    % Soil Heat Flux1
                    output(:,9) = NaN;                                               
                    % Soil Temp A 100cm Spikes
                    output([708 709 715 782:789 2025 2140 2193 2288 2475 3770 3771 3813 3818 6257 7815:7821 7910:7919 7943 7944 7979 7996 8251 8252 8289:8296 8326:8382 8672:8674 8729 8864 8904:8912 8953:8964 8978:8983 9012 9076:9079 9093:9122 9435:9453 9520:9555 9575:9605 9907:9990 10023:10040 10065:10084 10110:10129 10162:10173 10212:10226 10354:10368 10544:10563 10580:10603 10629:10750 15154 15296 15300:15400 15540:15580 15726:15730 15841:15877 16247:16282 16917:17300],11) = NaN;                                                 
                    % Soil Temp Spikes
                    output([7940:8297 8729 8864 8885:8912 8953:8985 9012:9123 9145:9207 9521:9538 9575:9640 15295:15399 15537:15583 15726:15731 15841:15846 15874:15877 16247:16282 16917:17300],[11:22]) = NaN; 
                    % SM A 10cm Spikes
                    output([11870 11929:11937 11963:11979 12020 12051:12053 12065:12067 12121:12128 12135 12164 12273 12274 12311 12344:12346 12364:12366 12385:12400 12448 12528:12557 12572 12586:12600 12649 12650 12668:12749 12798 12812:12866 12880:12894 12919:12930 13131:13233],25) = NaN;
                    % No good data in Ts 10B
                    output(:,20) = NaN;   
                    
                 case '2018' 
                    % Air Temp & RH
                    output([11649:11651 15292],[1:2]) = NaN;
                    % No good data from points 14579-14625
                    output([14579:14625],:)= NaN;
                    % Soil Heat Flux 2 (HFT_2) 
                    output([1:5420 8920:9102],9) = NaN;
                    % Data Loss in all Soil Data
                    output([5469:14676],[11:22]) = NaN;      
                    % Bad Ts and SM data
                    output([15294:15296],[11:30]) = NaN;      
                    % Negative Spike in all SM Pits
                    output([8253 8254 8481 8623 9102 9112 9968 11178 11538 14000:15296],[23:31]) = NaN;
                    % Pressure
                    output([8251 9103 15293],35) = NaN;
                    % Perform a scaling correction for PAR (use correction
                    % factor that was derived by inter-year comparison at
                    % the site).
                    output(:,5) = output(:,5).*par_correction_factor;
                    
                    % LW up and LW down look to be swapped 
%                     tmp = output(:,)
                    
                    RH_max = 100;
                    
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Fix data shift that occurs ~ half hour 14670 (Nov 2). At this time, the datalogger was switched to EDT (GMT - 4 hours). 
                    % Need to shift data up by 8 data points from this time to the end of the year. 
                    output_test = [output(1:14669,:); NaN.*ones(8,length(vars30)); output(14670:end-8,:)];
                    clear fill_data;
                    %%% Save the last 8 half-hours fromt output (which are
                    %%% going to get removed here). We'll need these for
                    %%% 2019
                    end_2018 = output(end-7:end,:);
                    save([output_path site '_end_2018.mat'], 'end_2018');
                    clear output end_2018;
                    output = output_test;
                    clear output_test;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                 case '2019' 
                    %%% CR1000 was returned to site on Feb 11. Need to shift forward all data from this time, and load in end of 2018 data.
%                     Also need to load last 8 data points from 2018 and add to the start.
% We can't take it from the fixed data, though, because the last 8 have
% been trimmed off. Have to take it from cleaned 2018 data. ugh.

%                     for i = 1:1:length(vars30)
%                         try
%                             temp_var = load([load_path site '_2019.' vars30_ext(i,:)]);
%                         catch
%                             temp_var = NaN.*ones(17520,1);
%                         end
%                         fill_data(1:8,i) = temp_var(1:8);
%                         clear temp_var;
%                     end
                  
                    
                    
                    % bad par down
                    output(8595:8611,5) = 0;
                    % soil heat flux spikes
                    output([8588:8633 8809 10053],8) = NaN;
                    output(output(:,9)==0,9) = NaN;
                    
                    %soil temp and moisture sensors 
                        % we saw a large portion of the growing season
                        % affected by faulty sensors
                    output([7046 10075 11220],11) = NaN;
                    output([6538 6547 6551 6554 6555 6658 7046 7568:11220 11859],[12 14 16 18 22] ) = NaN; % this deletes a large portion of crappy data. PLZ CHECK
                    output([6567],12) = NaN;
                    output([7046 10075],13) = NaN;
                    output([6556 6567],[14 22]) = NaN;
                    
                    
                    output([9109 7046],15) = NaN; 
                    output([7046 1122 11859],17) = NaN;
                    output([6567],18) = NaN;
                    
                    output([9650:10001 10075 10123],24) = NaN;
                    output([11770:11856],25) = NaN;
                    output(11220,28) = NaN;
                    output([7046],[19 21 23 24 25 31]) = NaN;
                    output(7046:11210,27) = NaN; % this deletes a large portion of crappy data. PLZ CHECK
                    output([8776:8794 8807:8921 8939 8999 9000],8) = NaN;
                    
                    output([7046 7730:7732 8409:8412 8464 8465 8494:8499 8504:8506 10134:10189 10209 10270:10281 10325],24) = NaN;
                    output([6538 6547 6551 6556 6567 6658 7568:7569 7046 7591 7595 7609 7614 7695 7713 7716 7718 7732 7736 7738 7741 7799 7805 7809 7816 7846 7867 7876 7881 7882 7886 7926 7933 7937 7940 7944 7951 7958 8057:10189 10209 10271 10281 10327 10328 10394 10399:10492],16) = NaN;
                    output([7046 7502:7509 7515 7566 7791:7987 8054:8221 8405:8413 10101:10109 10075 14854 10396:10500],26) = NaN;
                    output([7046 7502:7509 7515 7566 7731 7797:7987 8056:8508 9687 9709 9712 9723 9725 10075 10492 10135:10188 10209 10269:10280],29) = NaN;
                    
                    % Perform a scaling correction for PAR (use correction
                    % factor that was derived by inter-year comparison at
                    % the site).
                    output(:,5) = output(:,5).*par_correction_factor;
                    RH_max = 100;
                    %%% Holy moly -- what a mess this is. Need to: 
                    % - add last 8 data points from 2018 and put them in
                    % the front of the dataset
                    % - Move points 1 to 316 ahead by 8 half hours
                    % - 
                    load([output_path site '_end_2018.mat']); %loads as 'end_2018'
                    output_tmp = [end_2018; output(1:1990,:); NaN.*ones(6,length(vars30)); output(1991:2809,:); output(2824:end,:)]; 
                    output = output_tmp; 
                    clear output_tmp end_2018;
                    
                case '2020'
                    RH_max = 100;
                    % Perform a scaling correction for PAR (use correction
                    % factor that was derived by inter-year comparison at
                    % the site).
                    output(:,5) = output(:,5).*par_correction_factor;
                    
                    % col 6. Up par has spikes with multiple points. I
                    % can't figure out if its bad data or perhaps
                    % reflection from recent snowfall
                    
                    output([3325 3956 7357 14253],7) = NaN; %net radiation (JJB changed point 142535 to 14253 
                    
                    %bad soil data
                    
                    output([4102 4163:4185 4283 4430 4458:4486 4522:4707 5030:5094 5241 5242 5256 5258 5367 5383 5563 5566 5622:5635 5977:5987 6002 6004 6036 6061 6126 6324 6364:6367 6453 6616 6624 6720 6727 6739 6782 6791],[17 18 22]) = NaN;
                    output ([4737 4751 4753 4780 4783 4848 4850 4863 4868 4921 5699],[17 18]) = NaN;
                    output ([4735:4783 4845:4945 5010:5016 5365 5388 5389 5417:5472 5482 5527:5587 5615:5641 5681 5740:5742 5966:5972 6001:6447 6740 6761:6794 6817:6862],22) = NaN;
                    output ([4202:9242],25) = NaN;
                    output ([4417:6871],26) = NaN;
                    output (15808:17568,29) = NaN;
                    %all data from column 20 is bad but don't know what to
                    %do with it | Update - deleting
                    output(:,20) = NaN; 
                   output(15364,21) = NaN;
                   
                   
                   output([14500:14512 14785:14793 15800:17568],29) = NaN;
                   
                   case '2021' % EAR & LL
                    RH_max = 100; % sets RH > 100 = 100; only do this once inspecting the data and confirming that the max data are only a few percentages over 100
                       output ([13576],7) = NaN; %NetRadAbvCnpy
                    output ([13578 14374 16094],8) = NaN; %Soil Heat Flux 1
                    output ([13562],11) = NaN; %Soil Temp 100cm
                    output ([13562],12) = NaN; %Soil Temp 50cm 
                    output ([13562],13) = NaN; %Soil Temp 20cm 
                    output ([13562],14) = NaN; %Soil Temp 10cm 
                    output ([13560:13562],[15:22]) = NaN; %All soil T sensors 
                    output(1:8525,29) = NaN ; %Bad data for SM_B_20cm 
%                     output ([13560:13562],16) = NaN; %Soil Temp 2cm 
%                     output ([13560:13562],17) = NaN; %Soil Temp B 100cm
%                     output ([13560:13562],18) = NaN; %Soil Temp B 50cm 
%                     output ([13560:13562],19) = NaN; %Soil Temp B 20cm
%                     output ([13560:13562],21) = NaN; %Soil Temp B 5cm
%                     output ([13560:13562],22) = NaN; %Soil Temp B 2cm
                    output(:,5) = output(:,5).*par_correction_factor;
                    output(:,20) = NaN; % bad TSB10CM data 

                    case '2022' % EAR, LL & NH
                     RH_max = 100; % sets RH > 100 = 100; only do this once inspecting the data and confirming that the max data are only a few percentages over 100
                     output([7286:7288], 8) = NaN;
                     output([10928], 17) = NaN;%SoilTempB100
                     output([10928], 18) = NaN;%SoilTempB50
                     output([1:end],20) = NaN;
                     output(:,22) = output(:,22)+10; % JJB 2024-02-25 - This is a rather arbitrary fix that shifts Ts2cm (Pit B) up by 10 degrees.
                     output([15749:end], 29) = NaN;%SMB20
                     
                     %%% Fixing what seem to be incorrectly labeled SM
                     %%% sensors in pit B
                     SMB80_100 = output(:,31);
                     SMB50 = output(:,27);
                     SMB20 = output(:,28);
                     SMB10 = output(:,29);
                     SMB5 = output(:,30);
                     
                     output(:,27) = SMB80_100; output(:,28) = SMB50; output(:,29) = SMB20; output(:,30) = SMB10; output(:,31) = SMB5; 
                     output(:,5) = output(:,5).*par_correction_factor;
                    
                     
                    case '2023' % EAR, NS completed 2024-01-12
                     RH_max = 100; % sets RH > 100 = 100; only do this once inspecting the data and confirming that the max data are only a few percentages over 100
                     output(:,2) = NaN; %Added 2024-05-09 by JJB to remove all RH data. (see data cleaning notes: https://docs.google.com/document/d/13Ilk2EiRpkPT8-WovDziEnNSxXxXGrY8/edit#heading=h.h2qlevxp02wq)
                     output([1086:1089 3147:3156 3341:3350], 6) = NaN;
                     output([4863:4864 4932:4937 5083:5085 5095:5097 6519:6528 7144:7155], 17) = NaN;%SoilTempB100
                     output([4863:4864 4932:4937 5083:5085 5095:5097  5121:5130 6519:6528 7144:7155], 18) = NaN;%SoilTempB50
                     output([1:end], 20) = NaN;
                     output([11334:11339], 23) = NaN;%SMA50
                     output([6520 6527 7104:7148], 26) = NaN;
                     output([1:7814], 29) = NaN;%SMB20
                     
                     %%% Fixing what seem to be incorrectly labeled SM
                     %%% sensors in pit B
                     SMB80_100 = output(:,31);
                     SMB50 = output(:,27);
                     SMB20 = output(:,28);
                     SMB10 = output(:,29);
                     SMB5 = output(:,30);
                     
                     output(:,27) = SMB80_100; output(:,28) = SMB50; output(:,29) = SMB20; output(:,30) = SMB10; output(:,31) = SMB5; 
                    output(:,5) = output(:,5).*par_correction_factor;
%                     Fill in RH from TPD (since it is empty all year). 
                % linear line of best fit parameters: [0.918184413544947,7.340496782655547]
                TPD_tmp = load([loadstart 'Matlab\Data\Met\Final_Cleaned\TPD\TPD_met_cleaned_2023']);
                output(:,2) = polyval([0.918184413544947,7.340496782655547],TPD_tmp.master.data(:,4));
                
                     clear TPD_tmp;

                    case '2024' % LK
                     RH_max = 100; % sets RH > 100 = 100; only do this once inspecting the data and confirming that the max data are only a few percentages over 100
                     output([7540:9157], 1) = NaN;
                     output([8774 ], 6) = NaN;
                     output([514 579 14835:14837 17192], 7) = NaN;
                     output ([8669],8) = NaN; %Soil Heat Flux 1
                     output ([8829:9154],11) = NaN; 
                     output ([8829:9154],15) = NaN; 
                     output([8769 13212 13371 14275 15031 15603 15978 16164 16312], 17) = NaN;%SoilTempB100
                     output([8769 13212 13371 14275 15031 15603 15978 16164 16312], 18) = NaN;%SoilTempB50
                     output([8768:8774 13367 13371 13400 13407 13491 13671 15031 15047 15053 15604 15766 15793 15821 15898 15922 15936 15951 15959 15999 16164 16177 16469 16483 16593:16808 16209 16302:16311 16331:16394 17095:17124], 20) = NaN;
                     output([5212 13367:13371 13400:13407 15047:15053 15604 15766 13491:13671 15793:15821 15898:15922 15936:15951 15959:15967 15999:16164 16177:16209 16301:16312 16330:16395 16469:16483 16593:16809 17094:17125], 22) = NaN;%SMB20
                     output([5212 13367:13371 13400:13407 15047:15053 15603:15604], 23) = NaN;
                     output([5212 5213 15047:15054], 24) = NaN;
                     output([5212 5213 15604], 26) = NaN;%sma5c
                     output([5212 5213], 27) = NaN;%sma5c
            
          %All that's below and the rirst line including RH I believe should be included for this
          %year,seems to be applied from year to year
          
                     %%% Fixing what seem to be incorrectly labeled SM
                     %%% sensors in pit B
                     SMB80_100 = output(:,31);
                     SMB50 = output(:,27);
                     SMB20 = output(:,28);
                     SMB10 = output(:,29);
                     SMB5 = output(:,30);
                     
                     output(:,27) = SMB80_100; output(:,28) = SMB50; output(:,29) = SMB20; output(:,30) = SMB10; output(:,31) = SMB5; 
                    output(:,5) = output(:,5).*par_correction_factor;
            end
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%% Corrections applied to all years of data:
            % 1: Set any negative PAR and nighttime PAR to zero:
            PAR_cols = [];
            try
                PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'DownPAR_AbvCnpy')==1)];
                PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'UpPAR_AbvCnpy')==1)];
                PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'DownPAR_BlwCnpy')==1)];
            catch
            end
            
            %%% Set the bottoms of PAR (a
            %         if strcmp(site,'TP74')==1 && year == 2003
            %             DownParBot = 19;
            %             UpParBot = 21.5;
            %             DownParBlwBot = 15;
            %         else
            switch yr_str
                case {'2008';'2009'};
            DownParBot = 100;
            UpParBot = 50;
            DownParBlwBot = 50;
                otherwise
               DownParBot = 15;
               UpParBot = 15;
            DownParBlwBot = 15;
            end
            
            %         end
            
            %Plot uncorrected:
            figure(97);clf;
            subplot(211)
            plot(output(:,PAR_cols)); legend(output_names_str(PAR_cols,:))
            title('Uncorrected PAR');
            %         if year <= 2008
            [sunup_down] = annual_suntimes(site, year_ctr, 0);
            %         else
            %             [sunup_down] = annual_suntimes(site, year, 0);
            %         end
            ind_sundown = find(sunup_down< 1);
            figure(55);clf;
            plot(output(:,PAR_cols(1)))
            hold on;
            plot(ind_sundown,output(ind_sundown,PAR_cols(1)),'.','Color',[1 0 0])
            title('Check to make sure timing is right')
            try
                output(output(:,PAR_cols(1)) < DownParBot & sunup_down < 1,PAR_cols(1)) = 0;
                output(output(:,PAR_cols(2)) < UpParBot & sunup_down < 1,PAR_cols(2)) = 0;
                output(output(:,PAR_cols(3)) < DownParBlwBot & sunup_down < 1,PAR_cols(3)) = 0;
            catch
            end
            try
                output(output(:,PAR_cols(1)) < 0 , PAR_cols(1)) = 0;
                output(output(:,PAR_cols(2)) < 0 , PAR_cols(2)) = 0;
                output(output(:,PAR_cols(3)) < 0 , PAR_cols(3)) = 0;
            catch
            end
            % Plot corrected data:
            figure(97);
            subplot(212);
            plot(output(:,PAR_cols)); legend(output_names_str(PAR_cols,:))
            title('Corrected PAR');
            
            % 2: Set any RH > 100 to NaN -- This is questionable whether to make
            % these values NaN or 100.  I am making the decision that in some
            % cases
            RH_cols = [];
            try
                RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_AbvCnpy')==1)];
                RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_Cnpy')==1)];
                RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_BlwCnpy')==1)];
            catch
            end
            % Adjust columns to match output:
            %     RH_cols = RH_cols - 6;
            figure(98);clf;
            subplot(211)
            plot(output(:,RH_cols)); legend(output_names_str(RH_cols,:))
            title('Uncorrected RH')
            if ~isempty(RH_max)
                RH_resp = RH_max; % RH_max should be set within each year of data.
            else
                commandwindow;
                RH_resp = input('Enter value to set RH > 100 to? (100 or NaN): ');
            end
            for j = 1:1:length(RH_cols)
                output(output(:,RH_cols(j)) > 100,RH_cols(j)) = RH_resp;
            end
            subplot(212);
            plot(output(:,RH_cols)); legend(output_names_str(RH_cols,:))
            title('Corrected RH');
            
            
        case 'TPD'
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%% TPD  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% Convert wind speed to m/s for years 2012-2014
            if year < 2015
                output(:,22) = output(:,22)./3.6;
            end
            
            %%% Convert Pressure to kPa
            output(:,5) = output(:,5)./10;
            %%% Convert SHF to W/m2 ** NOTE: Change calibration values to
            %%% REAL values ***
            output(:,18) = output(:,18).*42;
            output(:,19) = output(:,19).*42;
            output(:,20) = output(:,20).*42;
            output(:,21) = output(:,21).*42;
            
            
            switch yr_str
                case '2012'
                    %%% Swap reversed SW and LW data (up & down are
                    %%% reversed)
                    tmp = output(:,10);
                    output(:,10)=output(:,11);
                    output(:,11)=tmp;
                    
                    tmp = output(:,12);
                    output(:,12)=output(:,13);
                    output(:,13)=tmp;
                    
                    %%% Bad Temperature data:
                    output([784 795 1071],3)= NaN;
                    output([9037],3)= NaN;
                    output([9496:9498],3)= NaN;
                    output([9547:9548],3)= NaN;
                    output([9563:9620],3)= NaN;
                    output([9855 9857],3)= NaN;
                    output([9859],3)= NaN;
                    output([10376:10478],3)= NaN;
                    output([11360:11368],3)= NaN;
                    output([11380],3)= NaN;
                    output([11415:11540],3)= NaN;
                    output([11552:11583],3)= NaN;
                    output([11711:12106],3)= NaN;
                    output([12270],3)= NaN;
                    output([12291:12455],3)= NaN;
                    output([12773:12815],3)= NaN;
                    output([12733:12734],3)= NaN;
                    output([12831:12832],3)= NaN;
                    output([13278:13567],3)= NaN;
                    output([14886],3)= NaN;
                    output([16756],3)= NaN;
                    output([9036 9037 9518 9532 9856 9858 9893],3)=NaN;
                    
                    
                    %%% Bad RH data:
                    output([225 591 784 795 1071 3028 12297],4)= NaN;
                    output([12310:12314],4)= NaN;
                    output([12776],4)= NaN;
                    output([12787:12788],4)= NaN;
                    output([12790:12814],4)= NaN;
                    output([13279:13567],4)= NaN;
                    output([12298],4)= NaN;
                    output([12315],4)= NaN;
                    output([12341],4)= NaN;
                    output([12777],4)= NaN;
                    output([12815],4)= NaN;
                    output([12452],4)= NaN;
                    %%% Bad Pressure data:
                    output([180:212 225:239],5)= NaN;
                    output([591 789 795 1071],5)= NaN;
                    %%% Bad Snow Depth data:
                    output([1071 5210:14349],6)= NaN;
                    
                    %%% Bad PAR data:
                    output([209 231 5838 12268],8)= NaN;
                    
                    %%% Bad WindSpeed data:
                    output([2865 4326],16)=NaN;
                    
                    %             %%% Bad SWP data:
                    %             output([241:510],26)= NaN;
                    %             output([241:510],27)= NaN;
                    %             output([241:510],28)= NaN;
                    %             output([241:510],29)= NaN;
                    %             output([241:510],30)= NaN;
                    %             %%% Bad Ohms data:
                    %             output([241:510],38)= NaN;
                    %             output([241:510],39)= NaN;
                    %             output([241:510],40)= NaN;
                    %             output([241:510],41)= NaN;
                    %             output([241:510],42)= NaN;
                    %%% Bad tipping bucket RG data:
                    output([1:4000],85)= NaN;
                    
                    %%% Remove bad CO2_cpy data:
                    output([5842:5844],86) = NaN;
                    output([6589 7434 7770 8106 8442 9131 9786 10122 10458 10794 11130 11466 11819 12155 12491 12827 13163 13547 13567],86) = NaN;
                    %%% Bad SWP Pit A
                    output([5838],25)= NaN;
                    output([5838],26)= NaN;
                    output([5838],27)= NaN;
                    output([5838],28)= NaN;
                    output([5838],29)= NaN;
                    output([5838],30)= NaN;
                    
                    %%% Bad SWP Pit B
                    output([5838],31)= NaN;
                    output([5838],32)= NaN;
                    output([5838],33)= NaN;
                    output([5838],34)= NaN;
                    output([5838],35)= NaN;
                    output([5838],36)= NaN;
                    %%% Bad KOhms Pit A
                    output([5838],37)= NaN;
                    output([5838],38)= NaN;
                    output([5838],39)= NaN;
                    output([5838],40)= NaN;
                    output([5838],41)= NaN;
                    output([5838],42)= NaN;
                    
                    %%% Bad kOhms Pit B
                    output([5838],43)= NaN;
                    output([5838],44)= NaN;
                    output([5838],45)= NaN;
                    output([5838],46)= NaN;
                    output([5838],47)= NaN;
                    output([5838],48)= NaN;
                    
                    
                    
                    %%% Fix incorrect soil sensor tensiometer wiring at start of
                    %%% year:
                    %%%% Checking plot used to fix the sensors -- not needed %%%%%%%%%%%%%
                    % %             clrs = jjb_get_plot_colors;
                    % %             figure(99);clf;
                    % %             ctr = 1;
                    % %             for i = 25:1:36
                    % %             plot(output(:,i),'Color',clrs(ctr,:),'LineWidth',2);hold on;
                    % %             ctr = ctr + 1;
                    % %             end
                    % %             legend(num2str((25:1:36)'))
                    %             clrs = jjb_get_plot_colors;
                    %             figure(99);clf;
                    %             ctr = 1;
                    %             for i = 37:1:48
                    %             plot(output(:,i),'Color',clrs(ctr,:),'LineWidth',2);hold on;
                    %             ctr = ctr + 1;
                    %             end
                    %             legend(num2str((37:1:48)'))
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%% Switch sensors for SWP:
                    switch_time = [241:510]';
                    tmp29 = output(switch_time,29);
                    tmp27 = output(switch_time,27);
                    output(switch_time,27) = output(switch_time,26); output(switch_time,26) = NaN;
                    output(switch_time,29) = tmp27;
                    output(switch_time,35) = output(switch_time,30); output(switch_time,30) = NaN;
                    output(switch_time,33) = tmp29;
                    output(switch_time,31) = output(switch_time,28); output(switch_time,28) = NaN;
                    %%% Switch sensors for Ohms:
                    tmp41 = output(switch_time,41);
                    tmp39 = output(switch_time,39);
                    output(switch_time,39) = output(switch_time,38); output(switch_time,38) = NaN;
                    output(switch_time,41) = tmp39;
                    output(switch_time,47) = output(switch_time,42); output(switch_time,42) = NaN;
                    output(switch_time,45) = tmp41;
                    output(switch_time,43) = output(switch_time,40); output(switch_time,40) = NaN;
                    clear tmp29 tmp27 tmp39 tmp41 switch_time
                    
                    %%% Fix shifts in met data logger throughout the first part of
                    %%% 2012:
                    % shift forward 13 points
                    output(193:225,:) = output(180:212,:); output(180:192,:) = NaN;
                    % shift backward 1 point
                    output(591:781,:) = output(592:782,:); output(782,:) = NaN;
                    % shift backward 2 points
                    output(783:791,:) = output(785:793,:); output(792:793,:) = NaN;
                    % shift backward 3 points
                    output(793:1066,:) = output(796:1069,:); output(1067:1069,:) = NaN;
                    % shift backward 4 points
                    output(1068:1577,:) = output(1072:1581,:); output(1578:1581,:) = NaN;
                    % shift backward 1 point
                    output(3028:5835,:) = output(3029:5836,:); output(5836,:) = NaN;
             
                case '2013'
                    %%% Swap reversed SW and LW data (up & down are
                    %%% reversed)
                    tmp = output(:,10);
                    output(:,10)=output(:,11);
                    output(:,11)=tmp;
                    
                    tmp = output(:,12);
                    output(:,12)=output(:,13);
                    output(:,13)=tmp;
                    % Remove bad snow depth point
                    output(16851,6) = NaN;
                    % Bad SWP Pit A
                    output(1026:1384,25:26) = NaN;
                    % Bad SWP Pit B
                    %output(817:3329,31:32) = NaN;
                    % output([3534 3659:4083 16364:16444 16483:16496],31) = NaN;
                    %output(16556:16842,32) = NaN;
                    % output(1026:1496,33) = NaN;
                    % Bad K0hms pit A
                    %output(1026:1386,37:38) = NaN;
                    % Bad K0hms pit B
                    %output([817:4084 16361:16501],43) = NaN;
                    %output([817:3153 16554:16842],44) = NaN;
                    %output(1026:1496,45) = NaN;
                    
                    
                case '2014'
                    %%% Swap reversed SW and LW data (up & down are
                    %%% reversed)
                    tmp = output(:,10);
                    output(:,10)=output(:,11);
                    output(:,11)=tmp;
                    
                    tmp = output(:,12);
                    output(:,12)=output(:,13);
                    output(:,13)=tmp;
                    
                    % Spike in LW Rad Abv Cnpy
                    output(13485,12:13) = NaN;                    
                    % SWP spikes until spring in some sensors
                    output(1:4354,[31:33 37 38 43 44 45]) = NaN;
                    % Other SWP points
                    output(14114,42) = NaN;
                    output([17485:17520 15125],43) = NaN;                    
                    
                    % Remove bad snow depth point
                    output(3390,6) = NaN;
                    % Remove SHF HFT1 point
                    output(13485,18) = NaN;
                    % Remove SHF HFT2 points
                    output([1534 7354 8344 8637 8998 9060 9293:9295 10741],19) = NaN;
                    
                    % Remove bad SHF HFT3 point
                    output([13485 13707 ],20) = NaN;
                    % Wind Spd & Dir not working
                    output(11399:end,22:24) = NaN;
                    % Remove bad CO2 cnpy points
                    output([3390 13484:14828],86) = NaN;
                    
                    % Unsure about early year kOhms
                    
                    % Unsure why LW Rn is cutoff, it is not in the TH in
                    % the same format..
                    
                    %%%%%%%%%%%
                    % Fill in gaps in Wind speed and wind direction with final cleaned CPEC data:
                    %%% wind speed
                    ws = output(:,22);
                    CPEC = load([loadstart 'Matlab/Data/Flux/CPEC/TPD/Final_Cleaned/TPD_CPEC_cleaned_2014.mat']);
                    u = CPEC.master.data(:,19);v = CPEC.master.data(:,20);
                    WS_CPEC = sqrt(u.^2 + v.^2);
                    p = polyfit(ws(~isnan(ws.*WS_CPEC)),WS_CPEC(~isnan(ws.*WS_CPEC)),1);
                    WS_CPEC_corr = (WS_CPEC-p(2))./p(1);
                    ws(isnan(ws),1) = WS_CPEC_corr(isnan(ws),1);
                    ws(ws<0) = 0;
                    output(:,22) = ws;
                    %%% wind direction
                    wdir = output(:,23);
                    WDIR_CPEC = rad2deg(atan2(u,v))+180;
                    wdir(isnan(wdir),1) = WDIR_CPEC(isnan(wdir),1);
                    output(:,23) = wdir;
                    clear u v WDIR* wdir ws p WS*;
                    
                case '2015'                    
                    % Bad snow depth
                    output([2897 4452 4453 4455 4482 4538 4542 4545 4547 4662 7323],6) = NaN;                    
                    % Long wave up, above canopy
                    output([14473 14265],12) = NaN;
                    output([9000:end],[12 13]) = NaN; % JJB removed data where drift occurred                    
                    % Soil Heat Flux HFT 2cm, 3cm, 4cm
                    output(7235:7238,[19 20 21]) = NaN;                    
                    % Bad wind speed and direction data:
                    output(1:400,[22 23]) = NaN;                    
                    % Bad CO2_cnpy data:
                    output(9300:16744,86) = NaN;
                                        
                    %%% Swap reversed SW and LW data (up & down are reversed)
                    tmp = output(:,10);
                    output(:,10)=output(:,11);
                    output(:,11)=tmp;
                    tmp = output(:,12);
                    output(:,12)=output(:,13);
                    output(:,13)=tmp;
                    
                 case '2016'
                    % Spikes in Air Temp Abv Cnpy
                    output([16888],3) = NaN;                    
                    % Spikes in Snow Depth
                    output([1329 1337 2190 16878],6) = NaN;                    
                    % Spikes in Down PAR below Cnpy
                    output([4932],9) = NaN;                    
                    % Spikes in Down Shortwave Radiation
                    output([2149 8723],11) = NaN;                    
                    % Spikes in UpLongwave Radiation Abv Cnpy
                    output([17341],12) = NaN;                    
                    % Spikes in Net Longwave above canopy
                    output([2885 17341],15) = NaN;                    
                    % Spikes in Soil Heat Flux 2
                    output([3631 5583 5584 8553 13217],19) = NaN;                    
                    % Spikes in Soil Heat Flux 3
                    output([13217],20) = NaN;                    
                    % Spikes in SWP A 10cm
                    output([5584],27) = NaN;                    
                    % Spikes in SWP A 50cm
                    output([1474 6155 7416],29) = NaN;                    
                    % Spikes in SWP Pit A 100cm
                    output([1596 3789 5584 9765],30) = NaN;                    
                    % Spikes in SWP Pit B 50cm
                    output([9039 9765],35) = NaN;                    
                    % Spikes in KOhms A 10cm
                    output([5584],39) = NaN;                    
                    % Spikes in KOhms A 50cm
                    output([1474 1923 1930 6155 7416],41) = NaN;                    
                    % Spikes in KOhms A 100cm
                    output([1596 2812 3789 4034 4211 5544 5584 9765],42) = NaN;                    
                    % Spikes in KOhms Pit B 50cm
                    output([9039 9765],47) = NaN;                    
                    % Spikes in CO2 canopy
                    output([1965 5197 6451 6474 9777 9945 9998 10045 11970 12165 12166 13431 14821],86) = NaN;
                    
                    %%%% uncomment this if nothing has been changed as of 2016
                                        %%% Swap reversed SW and LW data (up & down are
                                        %%% reversed)
                                        tmp = output(:,10);
                                        output(:,10)=output(:,11);
                                        output(:,11)=tmp;
                    
                                        tmp = output(:,12);
                                        output(:,12)=output(:,13);
                                        output(:,13)=tmp;
                 case '2017'
             %%%% recommend this CNR wiring has been changed in 2016
                                        %%% Swap reversed SW and LW data (up & down are
                                        %%% reversed)
                                        tmp = output(:,10);
                                        output(:,10)=output(:,11);
                                        output(:,11)=tmp;
                    
                                        tmp = output(:,12);
                                        output(:,12)=output(:,13);
                                        output(:,13)=tmp;
                                                      
                    % Spikes in Air Temp Abv Canopy
                    output([429:440 1691 4883 4886 6129:6136 12663 12757:12759 12803 12804 13423:13447 13571:13584 13809 13818 14941:14959 16214:16231 16276 17272:17305 17322:17327 17364 17366 17495:17516],3) = NaN;
                    % Spikes in Snowdepth
                    output([429:435 448 3731 4883:4895 5886:5892 6129:6135 12388 12389 12711 12757:12759 12803 13424:13430 13444:13446 13571:13580 13808:13817 14720 14720:14937 14938:14947 16210:16241 16536:16538 17171 17274 17275 17287 17305 17364 17369 17381 17492 17501:17507 17516],6)= NaN;
                    % Spikes in DownPAR Abv Canopy
                    output([450 5471 5485 5493 5601 9593],7) = NaN;
                    % Spikes in UpPAR Abv Canopy
                    output([471 5477 5484],8) = NaN;
                    % Spikes in DownPAR Below Canopy
                    output([33:37 448 471 4980 5124 5172 5485 5486 5601 5615 5747 5891 6179 9593],9) = NaN;
                    % Spikes in UpShortwaveRad
                    output([5463:5493 6627 9593],10) = NaN;  
                    % Spikes in DownShortwaveRad
                    output([448:466 2913 5463:5488 5563 5601:5613 6560:6627 7766:7796 9584:9613],11) = NaN;
                    % Spikes in UpLongwaveRadAbvCnpy
                    output([448:460 5484:5493 5615 9593],12) = NaN;
                    % Spikes in DownLongwaveRadAbvCnpy
                    output([7 448:451 1208 5471:5527 5615 9593],13) = NaN;
                    
                    % Spikes in Net Longwave Abv Canopy
                    output([448:466 1208 3942 4210 5493 5600:5615 6560:6630 7767:7796 9593:9611],15) = NaN;
                    % Spikes in Soil Heat Flux 2
                    output([10990 10991 11859 11999 12000 14272],19) = NaN;
                    % Spikes in Soil Heat Flux 3
                    output([5279 5764 5796 8336],20) = NaN;
                    % Missing Wind Data (Repair)
                    output([10210:12365],[22:24]) = NaN;
                    % Spikes in SWP A 50cm
                    output([1520 3303 3998],29) = NaN;
                    % Spikes in SWP A 100cm
                    output([492 493 550 849 1284 2522 2523 3148],29) = NaN;
                    % Spikes in KOhms A 50cm
                    output([1520 3303 3998],41) = NaN;
                    % Spikes in KOhms A 100cm
                    output([492 493 550 849 1284 2522 2523 3148],42) = NaN;
                    % Spikes in CO2 Canopy
                    output([256 424 425 1573:1577 2941 2956 3107 6874 7107 7145 7217 8913 14721 16063 16209 16308 16309],86) = NaN;                    
            
                case '2018'
                    
                    % Air Temp Battery Issues
                    output([9558 9563 9623 9634 9771 9780 9826 9831],3) = NaN;
                    % Spikes in Snow Depth Data
                    output([14 18 41 90 213 230 282 296 324:327 3921 4534 9533:9557 9581:9590 9628:9633 9778:9831],6) = NaN;
                    % Down PAR Abv & Blw Canopy
                    output([7312:7351 7575:9454],[7 9 10 11 12 13]) = NaN;
                    % Up PAR Abv Canopy
                    output(8337:8338,8) = NaN;
                    % Up (col 12) and Down (col 13) Longwave Abv Canopy
                    output([9832 15604:15642 13192:13196 13476:13478 13523:13525 16393:16394 13682:13693],[12,13]) = NaN;
                    
                    % Net Longwave Blw Canopy
                    output([],15) = NaN;
                    
                     %%% Swap reversed SW and LW data (up & down are reversed) %%%%%%%
                     tmp = output(:,10);
                     output(:,10)=output(:,11);
                     output(:,11)=tmp;
                     
                     tmp = output(:,12);
                     output(:,12)=output(:,13);
                     output(:,13)=tmp;
                                        
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                     
                    % Soil Heat Flux Spikes
                    output([7312:7351 7575:9454],[18:21]) = NaN;
                    % All Soil Water Potential Spikes
                    output([7575:9454],[25:48]) = NaN;
                    % SWP A 10cm Spikes
                    output([5027 5028],27) = NaN;
                    % Spikes in CO2 Canopy
                    output([2773 4936 6445 9104 10313 12947 13270 13477 17310],86) = NaN;      
                    % SWP B50 
                    output(5020,35) = NaN;
                    RH_max = 100;
                case '2019'
                    % Air Temp Battery Issues
                    output([7526],3) = NaN;
                    output([7525],6) = NaN;
                    output(7248:7524,5) = output(7248:7524,5)-(nanmean(output(7248:7524,5))-nanmean(output(1:7247,5)));
                    
                    output([1675 2009 2198 2726 3112 3879 4372 8873 8996 11848 16072],86) = NaN;
                    
                    % This may be needed.
                    %%% Swap reversed SW and LW data (up & down are reversed) %%%%%%%
                     tmp = output(:,10);
                     output(:,10)=output(:,11);
                     output(:,11)=tmp;
                     
                     tmp = output(:,12);
                     output(:,12)=output(:,13);
                     output(:,13)=tmp;
                     RH_max = 100;
                     output([14854:end 14687:14761 13301:13503 9651:10361 8527:8898 5445 5580:5582 5239:5255 4168:4170 3443:3464 2660:2765 2259:2434 1906 768 774 917 1178 1191 1328:1344 1391 1565:1573 1089:1093 1097:1100 70:102 6:9 3486:4501 2168:2768 1612:1852 916:1036 3605:3628 3911:3915 4317:4347 3477:4501 6250:6514 6586:6685 6721:7524 593 1056 152:219 649 486 658 861 755:760 869 457 364 125:126 240:250 253 260:263 265:272 275 5500 5444 5793 5578:5584 13291:13600 13248:13290 12237:12256 12304:12370 12428:12601],12) = NaN;
                     output([14854:end 14687:14761 13301:13503 9651:10361 8527:8898 5445 5580:5582 5239:5255 4168:4170 3443:3464 2660:2765 2259:2434 1906 768 774 917 1178 1191 1328:1344 1391 1565:1573 1089:1093 1097:1100 70:102 6:9 3486:4501 2168:2768 1612:1852 916:1036 3605:3628 3911:3915 4317:4347 3477:4501 6250:6514 6586:6685 6721:7524 593 1056 152:219 649 486 658 861 755:760 869 457 364 125:126 240:250 253 260:263 265:272 275 5500 5444 5793 5578:5584 13291:13600 13248:13290 12237:12256 12304:12370 12428:12601],13) = NaN;
                    
                     %%% Calculated LWup using estimated Tair at 2m height using Tair at top to fill bad CNR4 data
                     LWup_temp = output(:,12);
                     Ta_2m = 0.9837.*output(:,3)-0.5059;
                     LWup_fill = 0.0000000567.*(Ta_2m+273.15).^4;
                     ind = find(isnan(LWup_temp));
                     LWup_temp(ind)= LWup_fill(ind); 
                     output(:,12) = LWup_temp;
                     
                     %%% Calculated LWdown using Tair to fill bad CNR4 data
                     LWdn_temp = output(:,13);
                     LWdn_fill = 0.0000000567.*(output(:,3)+273.15).^4;
                     ind = find(isnan(LWdn_temp));
                     LWdn_temp(ind)= LWdn_fill(ind); 
                     output(:,13) = LWdn_temp;
                                       
                     
                case '2020'
                    %%% Try to correct shifts in Up LW Rad
                    %%% UPDATE: The shifts look to be offset + gain errors.
                    %%% I think they're all going to have to go.
%                     output([6947:7371],12) = output([6947:7371],12)+(output(6946,12)-output(6947,12));
%                     output([12018:12491],12) = output([12018:12491],12)+(output(12017,12)-output(12018,12)); 
%                     output([1896:2112],12) = output([1896:2112],12)-(output(1896,12)-output(1894,12));
%                     output([1895 12492 2113],12) = NaN;
                    output([6947:7371 12018:12492 749 1035 216 2112:2115 2589 2676 2852 3037 3141 3177:3178 3519 3983 4358:4359 4449 4419:4430 4502 4476 4528 4614 4624:4646 5133:5140 4869 7372:7374 4774:4839 1:1895 2115:2731 6082 6510 6451 5474 5352 7434:7590 7675:7684: 7708:7723 6493 7779:7843 8412:8421 8815 12550 14252:14264 14822:14833 15009 15172:15173 12896:12949 13060:13088 13174:13176 13180:13181 13191:13194],12) = NaN;
                    %%% Try to correct shifts in Down LW Rad
                    %%% UPDATE: The shifts look to be offset + gain errors.
                    %%% I think they're all going to have to go.
%                     output([6947:7371],13) = output([6947:7371],13)+(output(6946,13)-output(6947,13));
%                     output([12018:12491],13) = output([12018:12491],13)+(output(12017,13)-output(12018,13)); 
%                     output([1896:2112],13) = output([1896:2112],13)-(output(1896,13)-output(1894,13));
%                     output([1895 12492 2113],13) = NaN;   
                    output([6947:7371 12018:12492 749 1035 216 2112:2115 2589 2676 2852 3037 3141 3177:3178 3519 3983 2732 4358:4359 4449 4419:4430 4502 4476 4528 4614 4624:4646 7372:7374 5133:5140 4869 4774:4839 1:1895 2115:2731 6082 6510 6451 5474 5352 7434:7590 7675:7684: 7708:7723 6493 7779:7843 8412:8421 8815 12550 14252:14264 14822:14833 15009 15172:15173 12896:12949 13060:13088 13174:13176 13180:13181 13191:13194],13) = NaN;
                    
                    %%% Swap reversed SW data (up & down are reversed) %%%%%%%
                     tmp = output(:,10);
                     output(:,10)=output(:,11);
                     output(:,11)=tmp;
                    
                    %soil variable spikes  
                    output([9237:9238 11039],26) = NaN;
                    output([11036 12019],29) = NaN;
                    output([9237 11245 11488 12019 12285],30) = NaN;
                    output(8306,32) = NaN;
                    output(13817,34) = NaN;
                    output(12005,35) = NaN;
                    output(9237:9238,37) = NaN;
                    output([9237 9238 11039],38) = NaN;
                    output([11036 12019],41) = NaN;
                    output([12019 12285 11488],42) = NaN;
                    output(8306,44) = NaN;
                    output(12005,47) = NaN;
                    RH_max = 100;
                    %Co2 Canopy
                    output([235 374:376 2513 3738 3740 5515 7380 13522 15457 15796],86) = NaN;
                    
                     %%% Calculated LWup using estimated Tair at 2m height using Tair at top to fill bad CNR4 data
                     LWup_temp = output(:,12);
                     Ta_2m = 0.9837.*output(:,3)-0.5059;
                     LWup_fill = 0.0000000567.*(Ta_2m+273.15).^4;
                     ind = find(isnan(LWup_temp));
                     LWup_temp(ind)= LWup_fill(ind); 
                     output(:,12) = LWup_temp;
                     
                     %%% Calculated LWdown using Tair to fill bad CNR4 data
                     LWdn_temp = output(:,13);
                     LWdn_fill = 0.0000000567.*(output(:,3)+273.15).^4;
                     ind = find(isnan(LWdn_temp));
                     LWdn_temp(ind)= LWdn_fill(ind); 
                     output(:,13) = LWdn_temp;
                     
%                      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                case '2021' % EAR & LL
                    %%% Swap reversed SW data (up & down are reversed) %%%%%%%
                     tmp = output(:,10);
                     output(:,10)=output(:,11);
                     output(:,11)=tmp;
                RH_max = 100;
                % UpPARAbvCnpy spike
%                 output([5309:5318],8) = NaN;
                % UpLongwaveRadAbvCnpy Spikes
                
                %%% Swap reversed SW data (up & down are reversed) %%%%%%%
                     tmp = output(:,10);
                     output(:,10)=output(:,11);
                     output(:,11)=tmp;
                     
                output([1828:1860 9713:end 2879:2880 6013 3141:3149 3589:3640 3709 3801 3410:3538 3251 4257 4330:4334 4496:4497 3985:3986 4167 5279:5457 5643:5645 5655:5661 5737:5774 5823 5845 5862:5872 6000:6012 6053 6065 6163 6260:6264 6317 6470 6492 6591 6607 6651 6881:6949 7013:7037 7305 7741:7759 7786:7792 7810 7816 7848 7850 7883:8196 8220 8258:8390 8532 8705:9009 9016 9018 9023 9042 9056 9066 9089 9104 9136:9173 9237 9238 9259:9264 9290:end],12) = NaN;
                % DownLongwaveRadAbvCnpy Spikes
                output([6035 6562 6166 2627 3712:3713 1828:1860 9713:end 2879:2880 6013 3141:3149 3589:3640 3709 3801 3410:3538 3251 4257 4330:4334 4496:4497 3985:3986 4167 5279:5457 5643:5645 5655:5661 5737:5774 5823 5845 5862:5872 6000:6012 6053 6065 6163 6260:6264 6317 6470 6492 6591 6607 6651 6881:6949 7013:7037 7305 7741:7759 7786:7792 7810 7816 7848 7850 7883:8196 8220 8258:8390 8532 8705:9009 9016 9018 9023 9042 9056 9066 9089 9104 9136:9173 9237 9238 9259:9264 9290:end],13) = NaN;
                % Albedo spikes
                output([4042:4044 4849 5247 6493 8600 9462 11540 15430 16010 16520 17450],16) = NaN;
                output([16110:16113],20) = NaN; % bad SHF3 data
                % SWPA20cm spike 
                output ([865 951 6379 6454 10540 14040],28) = NaN;
                % SWPA50cm spikes
                output ([3263 3508 4112 6039 10670 15610],29) = NaN;
                % SWPA100cm spikes
                output ([1724 2720 4109 4270],30) = NaN;
                % SWPB20cm spike 
                output ([11380],34) = NaN;
                % SWPB50cm spike 
                output ([2730],35) = NaN;
                % SWPB100cm spike 
                output ([6597 11280],36) = NaN;
                % kOhmsA100cm
                output ([1724 2720 4109 4270],42) = NaN;
                % kOhmsB20cm
                output ([2730],47) = NaN;
output(12331,[79 81]) = NaN;
output([178 4223 7430 14267],[86]) = NaN; % CO2 cnpy

                     %%% Calculated LWup using estimated Tair at 2m height using Tair at top to fill bad CNR4 data
                     LWup_temp = output(:,12);
                     Ta_2m = 0.9837.*output(:,3)-0.5059;
                     LWup_fill = 0.0000000567.*(Ta_2m+273.15).^4;
                     ind = find(isnan(LWup_temp));
                     LWup_temp(ind)= LWup_fill(ind); 
                     output(:,12) = LWup_temp;
                     
                     %%% Calculated LWdown using Tair to fill bad CNR4 data
                     LWdn_temp = output(:,13);
                     LWdn_fill = 0.0000000567.*(output(:,3)+273.15).^4;
                     ind = find(isnan(LWdn_temp));
                     LWdn_temp(ind)= LWdn_fill(ind); 
                     output(:,13) = LWdn_temp;
                
                case '2022' % EAR, LL & NH
                    RH_max = 100;
                    output([1:end],12:13) = NaN; % UpLongwaveRadAbvCnpy and DownLongwave - bad data.
                  output([10368], 15) = NaN;
                  output([10820], 17) = NaN;
                  output([4063], 26) = NaN;
                  output([2624 3494 4058 4589 4852 4882 5519 6157 17174], 28) = NaN;
                  output([1636 2003 3494 5272 5609 8003 8994 17157 17174 17461], 29) = NaN;
                  output([9826 11223], 30) = NaN;
                  output([450:1600 10360:12658 12740:12749 14888:17142], 31) = NaN;
                  output([3092 4142 5259], 33) = NaN;
                  output([17163 17171], 34) = NaN;
                  output([17171 17173], 36) = NaN;
                  output(5840:17034,86) = NaN;
                  
                     %%% Calculated LWup using estimated Tair at 2m height using Tair at top to fill bad CNR4 data
                     LWup_temp = output(:,12);
                     Ta_2m = 0.9837.*output(:,3)-0.5059;
                     LWup_fill = 0.0000000567.*(Ta_2m+273.15).^4;
                     ind = find(isnan(LWup_temp));
                     LWup_temp(ind)= LWup_fill(ind); 
                     output(:,12) = LWup_temp;
                     
                     %%% Calculated LWdown using Tair to fill bad CNR4 data
                     LWdn_temp = output(:,13);
                     LWdn_fill = 0.0000000567.*(output(:,3)+273.15).^4;
                     ind = find(isnan(LWdn_temp));
                     LWdn_temp(ind)= LWdn_fill(ind); 
                     output(:,13) = LWdn_temp;
                     
               case '2023' % EAR, NS completed 2024-01-13
                    RH_max = 100;
%                   output([3642:end], 6) = NaN; JJB commented this, as the
%                   data looks OK for the rest of the year.
                  output([14430], 8) = NaN;
                  output([1:end], 10) = NaN;%UpShortwaveRad
                  output([1:end], 11) = NaN;
                  output([1:end], 12) = NaN;
                  output([1:end], 13) = NaN;
                  output([1:end], 14) = NaN;
                  output([1:end], 15) = NaN;
                  output([1:end], 16) = NaN;
                  output([1:end], 17) = NaN;
                  output([14988], 18) = NaN;%SoilHeatFluxHFT1
                  output([139 1396:2997 7574 9944 10056:10063 10723:10725 10887:10890 10995 11265:11268 11336:11339 11575:11577 11967:11969 15586:15592 15837:15843 16067:16069 16467:16470 16832:16844 17301:17311 17517:end], 25) = NaN;%SWPA2
                  output([139 5946 8043 15840:15841 15929 16067:16069], 26) = NaN;%SWPA5
                  output([2609 2972:3003 12464 15929 16560], 27) = NaN;
                  output([2477 4975 10692 15919], 28) = NaN;%SWPA20
                  output([3629 4982 5946 8043 8280 17267:17268], 29) = NaN;%SWPA50
                  output([1484 2557 3036 3231 4982 5946 5983 7954 8040 9961 13510], 30) = NaN;%SWPA100
                  output([4265:end], 31) = NaN;%SWPB2
                  output([2972 10336 13835], 32) = NaN;%SWPB5
                  output([1181 3192 6615], 34) = NaN;%SWPB20
                  output([139 173  1428 1690 1758 1817 2321 2383 2619 3319 6512 8043 9201 12464:12465], 35) = NaN;%SWPB50
                  output([1189 1421 2899 4944 4982 6938 6938 7009 10030 10165 11235 12464:12465], 36) = NaN;%SWPB100
                  output([2595 5738 14156], 86) = NaN;%CO2Canopy
                  
                       %%% Calculated LWup using estimated Tair at 2m height using Tair at top to fill bad CNR4 data
                     LWup_temp = output(:,12);
                     Ta_2m = 0.9837.*output(:,3)-0.5059;
                     LWup_fill = 0.0000000567.*(Ta_2m+273.15).^4;
                     ind = find(isnan(LWup_temp));
                     LWup_temp(ind)= LWup_fill(ind); 
                     output(:,12) = LWup_temp;
                     
                     %%% Calculated LWdown using Tair to fill bad CNR4 data
                     LWdn_temp = output(:,13);
                     LWdn_fill = 0.0000000567.*(output(:,3)+273.15).^4;
                     ind = find(isnan(LWdn_temp));
                     LWdn_temp(ind)= LWdn_fill(ind); 
                     output(:,13) = LWdn_temp;
                     
                 case '2024' % LK, first two variables edited with AH as intro from NS
                    RH_max = 100;
                 output([15633:15634 15636 16352], 8) = NaN;    
                 output([10264:11071 ], 12) = NaN;    
                 output([10264:11071 ], 13) = NaN;  
                 output([610 13252:end ], 25) = NaN;   
                 output([11457 11659 13252:end ], 26) = NaN;
                 output([13252:end ], 27) = NaN;
                 output([1662 3248 3300 5731 9499 10107 10208 11463 13252:end ], 28) = NaN;
                 output([4412 5183 6284 9530 9838 11463 12886 13252:end ], 29) = NaN;
                 output([3167 9599 10107 10111 12741 13252:end ], 30) = NaN;
                 output([13252:end ], 31) = NaN;
                 output([9501 9863 9887 10107 13252:end ], 32) = NaN;
                 output([9499:9502 9548 10107 11263 13252:end ], 35) = NaN;
                 output([2244 5014 5172 11438 11463 13252:end ], 36) = NaN;
                 output([11457 11659 16354 16359 17463], 38) = NaN;                 
                 output([9499 10208 11463 ], 40) = NaN;
                 output([2588 2589 3925 4017 10597], 86) = NaN;   
                 
                     %%% Calculated LWup using estimated Tair at 2m height using Tair at top to fill bad CNR4 data
                     LWup_temp = output(:,12);
                     Ta_2m = 0.9837.*output(:,3)-0.5059;
                     LWup_fill = 0.0000000567.*(Ta_2m+273.15).^4;
                     ind = find(isnan(LWup_temp));
                     LWup_temp(ind)= LWup_fill(ind); 
                     output(:,12) = LWup_temp;
                     
                     %%% Calculated LWdown using Tair to fill bad CNR4 data
                     LWdn_temp = output(:,13);
                     LWdn_fill = 0.0000000567.*(output(:,3)+273.15).^4;
                     ind = find(isnan(LWdn_temp));
                     LWdn_temp(ind)= LWdn_fill(ind); 
                     output(:,13) = LWdn_temp;
                  
            end
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%% Corrections applied to all years of data:
            % 1: Set any negative PAR and nighttime PAR to zero:
            PAR_cols = [];
            try
                PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'DownPAR_AbvCnpy')==1)];
                PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'UpPAR_AbvCnpy')==1)];
                PAR_cols = [PAR_cols; output_cols(strcmp(output_names,'DownPAR_BlwCnpy')==1)];
            catch
            end
            
            %%% Set the bottoms of PAR (a
            %         if strcmp(site,'TP74')==1 && year == 2003
            %             DownParBot = 19;
            %             UpParBot = 21.5;
            %             DownParBlwBot = 15;
            %         else
            DownParBot = 10;
            UpParBot = 15;
            DownParBlwBot = 15;
            %         end
            
            %Plot uncorrected:
            figure(97);clf;
            subplot(211)
            plot(output(:,PAR_cols)); legend(output_names_str(PAR_cols,:))
            title('Uncorrected PAR');
            %         if year <= 2008
            [sunup_down] = annual_suntimes(site, year_ctr, 0);
            %         else
            %             [sunup_down] = annual_suntimes(site, year, 0);
            %         end
            ind_sundown = find(sunup_down< 1);
            figure(55);clf;
            plot(output(:,PAR_cols(1)))
            hold on;
            plot(ind_sundown,output(ind_sundown,PAR_cols(1)),'.','Color',[1 0 0])
            title('Check to make sure timing is right')
            try
                output(output(:,PAR_cols(1)) < DownParBot & sunup_down < 1,PAR_cols(1)) = 0;
                output(output(:,PAR_cols(2)) < UpParBot & sunup_down < 1,PAR_cols(2)) = 0;
                output(output(:,PAR_cols(3)) < DownParBlwBot & sunup_down < 1,PAR_cols(3)) = 0;
            catch
            end
            try
                output(output(:,PAR_cols(1)) < 0 , PAR_cols(1)) = 0;
                output(output(:,PAR_cols(2)) < 0 , PAR_cols(2)) = 0;
                output(output(:,PAR_cols(3)) < 0 , PAR_cols(3)) = 0;
            catch
            end
            % Plot corrected data:
            figure(97);
            subplot(212);
            plot(output(:,PAR_cols)); legend(output_names_str(PAR_cols,:))
            title('Corrected PAR');
            
            % 2: Set any RH > 100 to NaN -- This is questionable whether to make
            % these values NaN or 100.  I am making the decision that in some
            % cases
            RH_cols = [];
            try
                RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_AbvCnpy')==1)];
                RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_Cnpy')==1)];
                RH_cols = [RH_cols; output_cols(strcmp(output_names,'RelHum_BlwCnpy')==1)];
            catch
            end
            % Adjust columns to match output:
            %     RH_cols = RH_cols - 6;
            figure(98);clf;
            subplot(211)
            plot(output(:,RH_cols)); legend(output_names_str(RH_cols,:))
            title('Uncorrected RH')
            if ~isempty(RH_max)
                RH_resp = RH_max; % RH_max should be set within each year of data.
            else
                RH_resp = input('Enter value to set RH > 100 to? (100 or NaN): ');
            end
%             RH_resp = input('Enter value to set RH > 100 to? (100 or NaN): ');
            for j = 1:1:length(RH_cols)
                output(output(:,RH_cols(j)) > 100,RH_cols(j)) = RH_resp;
            end
            subplot(212);
            plot(output(:,RH_cols)); legend(output_names_str(RH_cols,:))
            title('Corrected RH');
            
            

        case 'TPD_PPT'
            %%%%%%%%%%%%%%%%%%% TPD_PPT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            switch yr_str
                case '2012'
                case '2013'
                    % Missing PrecipA,B data
                    output(10860:12472,1:2) = NaN;
                    % Missing AirTemp 2m data
                    output([5117:12472 14618:15104],3) = NaN;
                case '2014'
                    % Missing AirTemp 2m and Panel temp data
                    output([4918:5653 6722:17520],3:4) = NaN;
                case '2015'
                    % Poured hot water in to melt ice in the rain gauge
                    output(2821:2824,1:2) = NaN;
                    
                case '2022' % EAR, LL & NH - Checked out - 2023-05-05
                
                case '2023' % EAR & NS - Checked out - 2024-01-12
                case '2024' % LK checked out in comparison to 2023/2022

            end


        case 'TPAg'
            %% %%%%%%%%%%%%%%%%% TPAg %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            switch yr_str
                case '2020'
                    RH_max = 100;
                % Load WS and WDir from Flux (CSAT data): 
                CPEC_tmp = load([loadstart 'Matlab\Data\Flux\CPEC\TPAg\Final_Cleaned\TPAg_CPEC_cleaned_2020.mat']);
                output(:,26) = CPEC_tmp.master.data(:,38); output(12311,26) = NaN;% wind speed
                output(:,27) = CPEC_tmp.master.data(:,39); % wind direction
                output(:,28) = CPEC_tmp.master.data(:,15); output(11531:11543,28) = NaN; % Pressure
               
                % "D:\Matlab\Data\Flux\CPEC\TPAg\Final_Cleaned\TPAg_CPEC_cleaned_2020.mat"
                clear CPEC_tmp
               %%% Investigate wind direction offset between TPAg and TP74
                TP74 = load([loadstart 'Matlab\Data\Met\Final_Cleaned\TP74\TP74_met_cleaned_2020.mat']);
                TP74_WDir = TP74.master.data(:,5);
                dir_diff = output(:,27) - TP74_WDir;

                % Plot timeseries of TPAg and TP74 Wind Dir
%                 figure(73);clf;
%                 plot(output(:,27),'b'); hold on;
%                 plot(TP74_WDir,'r');
%                 legend('TPAg','TP74');
                % Plot histogram of TPAg - TP74 wind dir
                dir_diff(dir_diff<-180) = dir_diff(dir_diff<-180)+360; % Transform when TPAg when difference spans 0/360 boundary
                xbins = -200:10:200;
                figure(74);
                hist(dir_diff,xbins);
                axis([-100 100 0 3100]); hold on;
                h1(1) = plot([nanmean(dir_diff) nanmean(dir_diff)],[0 3100],'r-');
                h1(2) = plot([nanmedian(dir_diff) nanmedian(dir_diff)],[0 3100],'g--');
                legend(h1,{['mean = ' num2str(round(nanmean(dir_diff)))],['median = ' num2str(round(nanmedian(dir_diff)))]});
                xlabel('WDir Offset (TPAg - TP74)');
                ylabel('count');
               %%% Correct wind direction offset 
                output(:,27) = output(:,27) - nanmean(dir_diff);
                output(output(:,27)<0,27) = output(output(:,27)<0,27)+360;
                
               %TPAg point cleaning with Nur and Elizabeth
               %                                                                                                                 
               output([15199:15207],3) = NaN; 
               output ([9151:9327 9781:9834],6) = NaN; %Down SW issues
               output ([9151:9327 15225:15329],8) = NaN; %Up longwave
               output ([9152:9327 9781:9834 15225:15329],9) = NaN; %Down longwave
               output ([9152:9327 15225:15389 15499:end],11) = NaN; %Net Longwave
               
               %%%% Fill empty PAR with TP74 data:
%                TP74 = load([loadstart 'Matlab\Data\Met\Final_Cleaned\TP74\TP74_met_cleaned_2020.mat']);
               output(:,5) = TP74.master.data(:,7);
               clear TP74;
               
               %%%% Remove all data points before 8400 - these belong to TP_VDT
               output(1:8400,:) = NaN;
               


               
            case '2021' % EAR & LL
                RH_max = 100;
                % bad T_air
            output([5264:5409 6175],3) = NaN;
            %RelHumAbvCnpy spike
            output([4052:8493 10455:10464 10470],4) = NaN;
            %UpShortWaveRad
            output([1:1816 7816 7820],6) = NaN;
            %UpLongWaveRadAbvCnpy spike
            output([1:1816 7813],8) = NaN;
            %DownLongWaveRadAbvCnpy spike
            output([1:1816 7813],9) = NaN;
            %NetLongwaveAbvCnpy
            output([1:1816],11) = NaN;
            %SMA10-40cm spike
            output([15492  15881],15) = NaN;
            %SMA5cm spike
            output([6175:6183 15492 15881:15882],[15 17:21 ]) = NaN;
            %PAA5cm
            output([15882],18) = NaN;
            %SoilTempA50cm spike
            output([16370],21) = NaN;
            output([15882 16364:16365],[13 14 20 21]) = NaN;
            
            
            
            %%% Fill in wind speed data with TP74 data    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Load WS and WDir from Flux (CSAT data):
                CPEC_tmp = load([loadstart 'Matlab\Data\Flux\CPEC\TPAg\Final_Cleaned\TPAg_CPEC_cleaned_2021.mat']);
                output(:,26) = CPEC_tmp.master.data(:,38); %output(12311,26) = NaN;% wind speed
                output(:,27) = CPEC_tmp.master.data(:,39); % wind direction
                output(:,28) = CPEC_tmp.master.data(:,15); %output(11531:11543,28) = NaN; % Pressure
               
                % "D:\Matlab\Data\Flux\CPEC\TPAg\Final_Cleaned\TPAg_CPEC_cleaned_2020.mat"
                clear CPEC_tmp
               %%% Investigate wind direction offset between TPAg and TP74
                TP74 = load([loadstart 'Matlab\Data\Met\Final_Cleaned\TP74\TP74_met_cleaned_2021.mat']);
                TP74_WDir = TP74.master.data(:,5);
                dir_diff = output(:,27) - TP74_WDir;

               %%%% Fill empty PAR with TP74 data:
               output(:,5) = TP74.master.data(:,7);
               
               clear TP74;
               
               
                % Plot timeseries of TPAg and TP74 Wind Dir
%                 figure(73);clf;
%                 plot(output(:,27),'b'); hold on;
%                 plot(TP74_WDir,'r');
%                 legend('TPAg','TP74');
                % Plot histogram of TPAg - TP74 wind dir
                dir_diff(dir_diff<-180) = dir_diff(dir_diff<-180)+360; % Transform when TPAg when difference spans 0/360 boundary
                xbins = -200:10:200;
                figure(74);
                hist(dir_diff,xbins);
                axis([-100 100 0 3100]); hold on;
                h1(1) = plot([nanmean(dir_diff) nanmean(dir_diff)],[0 3100],'r-');
                h1(2) = plot([nanmedian(dir_diff) nanmedian(dir_diff)],[0 3100],'g--');
                legend(h1,{['mean = ' num2str(round(nanmean(dir_diff)))],['median = ' num2str(round(nanmedian(dir_diff)))]});
                xlabel('WDir Offset (TPAg - TP74)');
                ylabel('count');
               %%% Correct wind direction offset 
                output(:,27) = output(:,27) - nanmean(dir_diff);
                output(output(:,27)<0,27) = output(output(:,27)<0,27)+360;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              
            case '2022' % EAR & LL
                RH_max = 100;
            %%% TsA_5cm and TsA_50cm were swapped early in the season.
            %%% Swapping them
            tmp = output([1:7948],13); % hold the data to be moved to 50 cm
            output([1:7948],13) = output([1:7948],21);
            output([1:7948],21) = tmp;
            clear tmp;
            output([7949:7957],21) = NaN; % Remaining bad data at 50 cm due to sensor stabilization after moving.
            output([5021 7950:7952],15 ) = NaN;
            output([7949:7950], 17 ) = NaN;
            output([7949], 18) = NaN;
            output([1:6340],20) = NaN;
            
            %%% Fill in wind speed, wind direction, pressure from CPEC and %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% then correct wind direction with with TP74
            % Load WS and WDir from Flux (CSAT data):
                CPEC_tmp = load([loadstart 'Matlab\Data\Flux\CPEC\TPAg\Final_Cleaned\TPAg_CPEC_cleaned_2022.mat']);
                output(:,26) = CPEC_tmp.master.data(:,38); %output(12311,26) = NaN;% wind speed
                output(:,27) = CPEC_tmp.master.data(:,39); % wind direction
                output(:,28) = CPEC_tmp.master.data(:,15); %output(11531:11543,28) = NaN; % Pressure
               
                % "D:\Matlab\Data\Flux\CPEC\TPAg\Final_Cleaned\TPAg_CPEC_cleaned_2020.mat"
                clear CPEC_tmp
               %%% Investigate wind direction offset between TPAg and TP74
                TP74 = load([loadstart 'Matlab\Data\Met\Final_Cleaned\TP74\TP74_met_cleaned_2022.mat']);
                TP74_WDir = TP74.master.data(:,5);
                dir_diff = output(:,27) - TP74_WDir;

                % Plot timeseries of TPAg and TP74 Wind Dir
%                 figure(73);clf;
%                 plot(output(:,27),'b'); hold on;
%                 plot(TP74_WDir,'r');
%                 legend('TPAg','TP74');
                % Plot histogram of TPAg - TP74 wind dir
                dir_diff(dir_diff<-180) = dir_diff(dir_diff<-180)+360; % Transform when TPAg when difference spans 0/360 boundary
                xbins = -200:10:200;
                figure(74);
                hist(dir_diff,xbins);
                axis([-100 100 0 3100]); hold on;
                h1(1) = plot([nanmean(dir_diff) nanmean(dir_diff)],[0 3100],'r-');
                h1(2) = plot([nanmedian(dir_diff) nanmedian(dir_diff)],[0 3100],'g--');
                legend(h1,{['mean = ' num2str(round(nanmean(dir_diff)))],['median = ' num2str(round(nanmedian(dir_diff)))]});
                xlabel('WDir Offset (TPAg - TP74)');
                ylabel('count');
               %%% Correct wind direction offset 
                output(:,27) = output(:,27) - nanmean(dir_diff);
                output(output(:,27)<0,27) = output(output(:,27)<0,27)+360;
                
               %%%% Fill empty PAR with TP74 data:
%                TP74 = load([loadstart 'Matlab\Data\Met\Final_Cleaned\TP74\TP74_met_cleaned_2020.mat']);
               output(:,5) = TP74.master.data(:,7);
               clear TP74;                
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            case '2023' % NS
                RH_max = 100;
            output([17218:17230 17401],13) = NaN;%SoilTempA5
            %%% Fill in wind speed, wind direction, pressure from CPEC and %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% then correct wind direction with with TP74
            % Load WS and WDir from Flux (CSAT data):
                CPEC_tmp = load([loadstart 'Matlab\Data\Flux\CPEC\TPAg\Final_Cleaned\TPAg_CPEC_cleaned_2023.mat']);
                output(:,26) = CPEC_tmp.master.data(:,38); %output(12311,26) = NaN;% wind speed
                output(:,27) = CPEC_tmp.master.data(:,39); % wind direction
                output(:,28) = CPEC_tmp.master.data(:,15); %output(11531:11543,28) = NaN; % Pressure
               
                % "D:\Matlab\Data\Flux\CPEC\TPAg\Final_Cleaned\TPAg_CPEC_cleaned_2020.mat"
                clear CPEC_tmp
               %%% Investigate wind direction offset between TPAg and TP74
                TP74 = load([loadstart 'Matlab\Data\Met\Final_Cleaned\TP74\TP74_met_cleaned_2023.mat']);
                TP74_WDir = TP74.master.data(:,5);
                dir_diff = output(:,27) - TP74_WDir;

                % Plot timeseries of TPAg and TP74 Wind Dir
%                 figure(73);clf;
%                 plot(output(:,27),'b'); hold on;
%                 plot(TP74_WDir,'r');
%                 legend('TPAg','TP74');
                % Plot histogram of TPAg - TP74 wind dir
                dir_diff(dir_diff<-180) = dir_diff(dir_diff<-180)+360; % Transform when TPAg when difference spans 0/360 boundary
                xbins = -200:10:200;
                figure(74);
                hist(dir_diff,xbins);
                axis([-100 100 0 3100]); hold on;
                h1(1) = plot([nanmean(dir_diff) nanmean(dir_diff)],[0 3100],'r-');
                h1(2) = plot([nanmedian(dir_diff) nanmedian(dir_diff)],[0 3100],'g--');
                legend(h1,{['mean = ' num2str(round(nanmean(dir_diff)))],['median = ' num2str(round(nanmedian(dir_diff)))]});
                xlabel('WDir Offset (TPAg - TP74)');
                ylabel('count');
               %%% Correct wind direction offset 
                output(:,27) = output(:,27) - nanmean(dir_diff);
                output(output(:,27)<0,27) = output(output(:,27)<0,27)+360;
                
                
                %%%% Fill empty PAR with TP74 data:
%                TP74 = load([loadstart 'Matlab\Data\Met\Final_Cleaned\TP74\TP74_met_cleaned_2020.mat']);
               output(:,5) = TP74.master.data(:,7);
               clear TP74;  
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            

                    %%% Fill in wind speed, wind direction, pressure from CPEC and %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% then correct wind direction with with TP74
            % Load WS and WDir from Flux (CSAT data):
                CPEC_tmp = load([loadstart 'Matlab\Data\Flux\CPEC\TPAg\Final_Cleaned\TPAg_CPEC_cleaned_2024.mat']);
                output(:,26) = CPEC_tmp.master.data(:,38); %output(12311,26) = NaN;% wind speed
                output(:,27) = CPEC_tmp.master.data(:,39); % wind direction
                output(:,28) = CPEC_tmp.master.data(:,15); %output(11531:11543,28) = NaN; % Pressure
               
                % "D:\Matlab\Data\Flux\CPEC\TPAg\Final_Cleaned\TPAg_CPEC_cleaned_2020.mat"
                clear CPEC_tmp
               %%% Investigate wind direction offset between TPAg and TP74
                TP74 = load([loadstart 'Matlab\Data\Met\Final_Cleaned\TP74\TP74_met_cleaned_2024.mat']);
                TP74_WDir = TP74.master.data(:,5);
                dir_diff = output(:,27) - TP74_WDir;

                % Plot timeseries of TPAg and TP74 Wind Dir
%                 figure(73);clf;
%                 plot(output(:,27),'b'); hold on;
%                 plot(TP74_WDir,'r');
%                 legend('TPAg','TP74');
                % Plot histogram of TPAg - TP74 wind dir
                dir_diff(dir_diff<-180) = dir_diff(dir_diff<-180)+360; % Transform when TPAg when difference spans 0/360 boundary
                xbins = -200:10:200;
                figure(74);
                hist(dir_diff,xbins);
                axis([-100 100 0 3100]); hold on;
                h1(1) = plot([nanmean(dir_diff) nanmean(dir_diff)],[0 3100],'r-');
                h1(2) = plot([nanmedian(dir_diff) nanmedian(dir_diff)],[0 3100],'g--');
                legend(h1,{['mean = ' num2str(round(nanmean(dir_diff)))],['median = ' num2str(round(nanmedian(dir_diff)))]});
                xlabel('WDir Offset (TPAg - TP74)');
                ylabel('count');
               %%% Correct wind direction offset 
                output(:,27) = output(:,27) - nanmean(dir_diff);
                output(output(:,27)<0,27) = output(output(:,27)<0,27)+360;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  
            %%%% Fill empty PAR with TP74 data:
%                TP74 = load([loadstart 'Matlab\Data\Met\Final_Cleaned\TP74\TP74_met_cleaned_2020.mat']);
               output(:,5) = TP74.master.data(:,7);
               clear TP74;  
               
               case '2024' %LK
                RH_max = 100;
                 output([10538:10548 11692:11697 13423:13426 15171:15174 16017:16021 16790:16795],1) = NaN;
                 output([13730:13735 15091:15099 16765 8658 8826 7570 6733 5044 686:688 13397 13400 14280],3) = NaN;
                 output([324 452 444 455 1352:1354 2204 2212 2213 6867:6869 7068:7070 7634 10436 11240 11292 12872:12876 13342 13343 13396:13399 15129 15738 16290 17480:17486 ],6) = NaN;%look for negatives
                 output([212 213 438 1232 1289 1290 1659 1948:1950 2051 3188:3192 3556 4771 6701 7031:7036 8294:8298 9673 12219 14050 17294],9) = NaN;
                 output([173 848 2366:2398 3805:3848 16209 16338 16342 16707 17050:17060 17364 17217:17218 684 685 705 2238 2281 2301 2579:2583 2596 2597 2610 2676 3858 3859 3898 16110 16343 16344 16510 16700 16854 17169:17174],13) = NaN;%look agin for mor, alter range
                 output([13642:15217 15084 15666:15673 15729 15908:15968 15660 15677 15678 15748 15749 15751 15771:15773 15837 15997 15998 16001 16002 16016 16028 16045:16061 16065 ],20) = NaN;%look for more outliers, cut whole break in fall
                 
            end

        case 'TP_VDT'
            %% %%%%%%%%%%%%%%%%% TP_VDT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            switch yr_str
                case '2019'
               output ([7036 8776 9829 9839],3) = NaN; %Air Temp
               output (5845,4) = NaN; %RH
               output ([8783:9840],[7:12]) = NaN; %Net Radiometer was upside-down for this period. All radiation variables NaN
               output ([6666:6669 8409 10196:10201],[17:18]) = NaN;     % soil moisture
               
                case '2020'
                    RH_max = 100;
                % Load WS and WDir from Flux (CSAT data): 
                CPEC_tmp = load([loadstart 'Matlab\Data\Flux\CPEC\TP_VDT\Final_Cleaned\TP_VDT_CPEC_cleaned_2020.mat']);
                output(:,26) = CPEC_tmp.master.data(:,38); output(12311,26) = NaN;% wind speed
                output(:,27) = CPEC_tmp.master.data(:,39); % wind direction
                output(:,28) = CPEC_tmp.master.data(:,15); output(11531:11543,28) = NaN; % Pressure
               
                
         
                % "D:\Matlab\Data\Flux\CPEC\TPAg\Final_Cleaned\TP_VDT_CPEC_cleaned_2020.mat"
                clear CPEC_tmp
               %%% Investigate wind direction offset between TP_VDT and TP74
                CPEC_TP74 = load([loadstart 'Matlab\Data\Met\Final_Cleaned\TP74\TP74_met_cleaned_2020.mat']);
                TP74_WDir = CPEC_TP74.master.data(:,5);
                dir_diff = output(:,27) - TP74_WDir;

                % Plot timeseries of TP_VDT and TP74 Wind Dir
%                 figure(73);clf;
%                 plot(output(:,27),'b'); hold on;
%                 plot(TP74_WDir,'r');
%                 legend('TP_VDT','TP74');
                % Plot histogram of TP_VDT - TP74 wind dir
                dir_diff(dir_diff<-180) = dir_diff(dir_diff<-180)+360; % Transform when TP_VDT when difference spans 0/360 boundary
                xbins = -200:10:200;
                figure(74);
                hist(dir_diff,xbins);
                axis([-100 100 0 3100]); hold on;
                h1(1) = plot([nanmean(dir_diff) nanmean(dir_diff)],[0 3100],'r-');
                h1(2) = plot([nanmedian(dir_diff) nanmedian(dir_diff)],[0 3100],'g--');
                legend(h1,{['mean = ' num2str(round(nanmean(dir_diff)))],['median = ' num2str(round(nanmedian(dir_diff)))]});
                xlabel('WDir Offset (TP_VDT - TP74)');
                ylabel('count');
               %%% Correct wind direction offset 
                output(:,27) = output(:,27) - nanmean(dir_diff);
                output(output(:,27)<0,27) = output(output(:,27)<0,27)+360;
                
               %TP_VDT point cleaning with Nur and Elizabeth
               %                                                                                                                 
               output(15199:15207,3) = NaN; 
               output ([9151:9327 9781:9834],6) = NaN; %Down PAR issues
               output ([9151:9327 15225:15329],8) = NaN; %Up longwave
               output ([9152:9327 9781:9834 15225:15329],9) = NaN; %Down longwave
               output ([9152:9327 15225:15389 15499:end],11) = NaN; %Net Longwave
               
               %%%% Remove all data points after 8400 - these belong to TPAg
               output(8400:end,:) = NaN;
               
               case '2021'
                   output([1:1815],[6 11]) = NaN;
            end
    end
      
    %% @@@@@@@@@@@@@@@@@@ CHECK TIMECODE @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    if proc_flag == 1
        PAR_tmp = output(:,output_cols(strcmp(output_names,'DownPAR_AbvCnpy')==1));
        mcm_check_met_shifts(PAR_tmp,year_ctr, site)
        
        disp('Check to see if data is shifted relative to UTC.  If so, shift data.');
    end
    %%%%%%%%%% This part cascades all of the windows (if there is more
    %%%%%%%%%% than one figure
    % Check how many figures are open)
    hvis = get(0,'HandleVisibility');
    set(0,'HandleVisibility','on');
    nfigs = get(0,'Children');
    set(0,'HandleVisibility',hvis)                                                                                                                                      
    % Do cascade if >1 are open.
    if length(nfigs)>1
        cascade;
    else
    end
    %%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    %% Plot corrected/non-corrected data to make sure it looks right:
    f10 = figure(10); set(f10,'WindowStyle','docked')
    j = 1;
    while j <= length(vars30)
        figure(f10);clf;
        plot(input_data(:,j),'r.-'); hold on;
        plot(output(:,j),'b.-');
        grid on;
        %     title(var_names(vars30(j),:));
        title([var_names(vars30(j),:) ', column no: ' num2str(j)]);
        
        legend('Original','Fixed (output)');
        %% Gives the user a chance to move through variables:
        switch skipall_flag
            case 1
                response = '9';
            otherwise
        commandwindow;
        response = input('Press enter to move forward, enter "1" to move backward, 9 to skip all: ', 's');
        end
        
        if isempty(response)==1
            j = j+1;
        elseif strcmp(response,'9')==1;
            j = length(vars30)+1;
        elseif strcmp(response,'1')==1 && j > 1;
            j = j-1;
        else
            j = 1;
        end
    end
    clear j response accept
    
    if proc_flag == 1
        
        %% Plot Soil variables for final inspection:
        figure(5);clf;
        for i = 1:1:length(Ts_cols_A)
            subplot(2,1,1)
            hTsA(i) = plot(output(:,Ts_cols_A(i)),'Color',clrs(i,:)); hold on;
        end
        legend(hTsA,TsA_labels(:,12:end))
        title('Pit A - Temperatures -- Corrected')
        
        for i = 1:1:length(Ts_cols_B)
            subplot(2,1,2)
            hTsB(i) = plot(output(:,Ts_cols_B(i)),'Color',clrs(i,:)); hold on;
        end
        % legend(hTsB,TsB_labels(:,12:end))
        title('Pit B - Temperatures -- Corrected')
        
        
        % B. Soil Moisture:
        figure(6);clf;
        
        for i = 1:1:length(SM_cols_A)
            subplot(2,1,1)
            hSMA(i) = plot(output(:,SM_cols_A(i)),'Color',clrs(i,:)); hold on;
        end
        
        try legend(hSMA,SMA_labels(:,6:end));  catch; end
        
        title('Pit A - Moisture -- Corrected')
        
        for i = 1:1:length(SM_cols_B)
            subplot(2,1,2)
            hSMB(i) = plot(output(:,SM_cols_B(i)),'Color',clrs(i,:)); hold on;
        end
        try legend(hSMB,SMB_labels(:,6:end)); catch; end
        
        title('Pit B - Moisture -- Corrected')
    end
    %% Output
    % Here is the problem with outputting the data:  Right now, all data in
    % /Final_Cleaned/ is saved with the extensions corresponding to the
    % CCP_output program.  Alternatively, I think I am going to leave the output
    % extensions the same as they are in /Organized2 and /Cleaned3, and then
    % re-write the CCP_output script to work on 2008-> data in a different
    % manner.
    master(1).data = output;
    master(1).labels = names30_str;
    save([output_path site '_met_cleaned_' yr_str '.mat'], 'master');
    clear master;
    
    if auto_flag == 1
            resp2 = 'y';
    else
        commandwindow;
    resp2 = input('Are you ready to print this data to /Final_Cleaned? <y/n> ','s');
    end
    
    if strcmpi(resp2,'n')==1
        disp('Variables not saved to /Final_Cleaned/.');
    else
        for i = 1:1:length(vars30)
            temp_var = output(:,i);
            save([output_path site '_' yr_str '.' vars30_ext(i,:)], 'temp_var','-ASCII');
            
        end
        disp('Variables saved to /Final_Cleaned/.');
        
    end
    switch auto_flag
        case 0
            commandwindow;
            junk = input('Press Enter to Continue to Next Year');
        otherwise
    end
end
if auto_flag==0
    mcm_start_mgmt;
end
end

%subfunction
% Returns the appropriate column for a specified variable name
function [right_col] = quick_find_col(names30_in, var_name_in)

right_col = find(strncmpi(names30_in,var_name_in,length(var_name_in))==1);
end

