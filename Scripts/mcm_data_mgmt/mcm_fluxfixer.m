function [pts_to_shift] = mcm_fluxfixer(year, site,auto_flag)
% usage: mcm_fluxclean(year, site, auto_flag)
% auto_flag = 0 runs in standard mode
% auto_flag = 1 runs in automated mode

ls = addpath_loadstart;
%%%%%%%%%%%%%%%%%
if nargin == 1
    site = year;
    year = [];
    auto_flag = 0; % flag that determines if we're in automated mode or not
elseif nargin == 2
    auto_flag = 0; % flag that determines if we're in automated mode or not
    
end
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
%
% elseif nargin == 2
%     if numel(year) == 1 || ischar(year)==1
%         if ischar(year)
%             year = str2double(year);
%         end
%         year_start = year;
%         year_end = year;
%     end
% end
%
% if isempty(year)==1
%     year_start = input('Enter start year: > ');
%     year_end = input('Enter end year: > ');
% end
%%% Check if site is entered as string -- if not, convert it.
if ischar(site) == false
    site = num2str(site);
end
%%%%%%%%%%%%%%%%%

%%% Declare Paths:
% load_path = [ls 'SiteData/' site '/MET-DATA/annual/'];
load_path = [ls 'Matlab/Data/Flux/CPEC/' site '/Cleaned/'];
output_path = [ls 'Matlab/Data/Flux/CPEC/' site '/Final_Cleaned/'];
jjb_check_dirs(output_path,0);
% header_path = [ls 'Matlab/Data/Flux/CPEC/Docs/'];
header_path = [ls 'Matlab/Config/Flux/CPEC/']; % Changed 01-May-2012
met_path = [ls 'Matlab/Data/Met/Final_Cleaned/' site '/'];
% Load Header:
% header_old = jjb_hdr_read([header_path 'mcm_CPEC_Header_Master.csv'], ',', 3);
% header_tmp = mcm_get_varnames(site);
header_tmp = mcm_get_fluxsystem_info(site, 'varnames');

t = struct2cell(header_tmp);
t2 = t(2,1,:); t2 = t2(:);
% Column vector number
col_num = (1:1:length(t2))';
header = mat2cell(col_num,ones(length(t2),1),1);
header(:,2) = t2;er_old = jjb_hdr_read([header_path 'mcm_CPEC_Header_Master.csv'], ',', 3);

% Title of variable
var_names = char(header(:,2));
num_vars = max(col_num);

%% Main Loop

for year_ctr = year_start:1:year_end
    close all
    if auto_flag == 1
        skipall_flag = 1;
    else
        skipall_flag = 0;
    end
    yr_str = num2str(year_ctr);
    disp(['Working on year ' yr_str '.']);
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Step 1: Cycle through all variables so the investigator can look at the
    %%% data closely
    
    % Load data:
    load([load_path site '_CPEC_clean_' yr_str '.mat' ]);
    input_data = master.data; clear master;
    output = input_data;
    
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
    
    while j <= num_vars
        %     temp_var = load([load_path site '_' year '.' char(header{k,2})]);
        %     input_data(:,j) = temp_var;
        %     output(:,j) = temp_var;
        temp_var = input_data(:,j);
        switch scrollflag
            case 1
                f1 = figure(1); set(f1,'WindowStyle','docked');
                clf;
                plot(temp_var);
                %     hold on;
                title([strrep(var_names(j,:),'_','-') ', column no: ' num2str(j)]);
                grid on;
                
                
                %% Gives the user a chance to change the thresholds
                commandwindow;
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
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Step 2: Specific Cleans to the Data
    
    switch site
    %% ********************** TP39 *********************************    
        case 'TP39'
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%% % Added 19-Oct-2010 by JJB
            %%%% Clean CSAT and flux data using value of std for Ts or w
            bad_CSAT = isnan(output(:,26))==1 | output(:,26) > 2.5;
            output(bad_CSAT, [16 22]) = NaN;
            bad_CSAT2 = isnan(output(:,25))==1 | output(:,25) > 2.5;
            output(bad_CSAT2, [1:5 19 20 21]) = NaN;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            switch yr_str
                case '2002'
                    output([7042:7043 10244:10269 14183:14210],17) = NaN;
                    %%% Shift flux data into UTC:
                    output = [NaN.*ones(9,size(output,2)); output(1:9063,1:end); ...
                        output(9065:14376,1:end); NaN.*ones(2,size(output,2)); output(14377:end-10,1:end)];
                    % Fix a data offset issue, by moving data back by 1
                    % halfhour KEEP THIS AT THE END
                    output = [output(2:9638,:);NaN.*ones(1,size(output,2));output(9639:17520,:)];
                    
                case '2003'
                    output([2329:2337 7752:7754 9878:9924],17) = NaN;
                    %%% Shift flux data into UTC:
                    try load([load_path site '_CPEC_clean_2002.mat' ]);TP39_2002 = master.data; clear master;
                    catch
                        disp('could not load 2002 cleaned flux data');   TP39_2002 = NaN.*ones(size(output));
                    end
                    output = [TP39_2002(end-10+1:end,1:end); output(1:6129,1:end); ...
                        output(6132:14512,1:end); output(14514:end-7,1:end)];
                    
                case '2004'
                    % CRazy looking Fc data in start of 2004:
                    output([2754:2959],1) = NaN;
                    output([613 2721:2774],17) = NaN;
                    % bad looking LE data:
                    output([6116:6238 6770:7142 8337:8859 9810:10423],5) = NaN;
                    %%% Shift flux data into UTC:
                    try load([load_path site '_CPEC_clean_2003.mat' ]);TP39_2003 = master.data; clear master;
                    catch
                        disp('could not load 2003 cleaned flux data');   TP39_2003 = NaN.*ones(size(output));
                    end
                    output = [TP39_2003(end-8+1:end,1:end); output(1:end-8,1:end)];
                    
                case '2005'
                    output(11029:11030,[16 22]) = NaN;
                    output([2186 8409:8425],17) = NaN;
                    output(11174,18) = NaN;
                    %%% Shift flux data into UTC:
                    try load([load_path site '_CPEC_clean_2004.mat' ]);TP39_2004 = master.data; clear master;
                    catch
                        disp('could not load 2004 cleaned flux data');   TP39_2004 = NaN.*ones(size(output));
                    end
                    %                 output = [TP39_2004(end-9+1:end,1:end); output(1:end-9,1:end)];
                    output = [TP39_2004(end-8+1:end,1:end); output(1:end-8,1:end)]; % Modified by JJB to fix a time shift offset issue
                    
                    
                case '2006'
                    bad_CO2 = [(3094:3103)';(8061:8077)'; (12602:12609)'];
                    bad_H2O = [(8061:8095)'];
                    output(bad_CO2, 17) = NaN;
                    output(bad_H2O, 18) = NaN;
                    clear bad_*
                    %%% Shift flux data into UTC (right now in EDT)
                    try            load([load_path site '_CPEC_clean_2005.mat' ]);  TP39_2005 = master.data; clear master;
                    catch
                        disp('could not load 2005 cleaned flux data');   TP39_2005 = NaN.*ones(size(output));
                    end
                    output = [TP39_2005(end-8+1:end,1:end); output(1:9652,1:end); ...
                        NaN.*ones(1,size(output,2)); output(9653:11832,1:end); output(11834:13027,1:end);...
                        NaN.*ones(1,size(output,2)); output(13028:end-9,1:end)];
                    % fix a data offset issue, by moving data back by 1 halfhour KEEP THIS AT THE END
                    output = [output(1:6490,:);output(6492:11050,:);NaN.*ones(1,size(output,2));output(11051:end,:)];
                    
                    
                case '2007'
                    output(650:950,:) = NaN; % Obviously bad data (in all variables)
                    output([8138:8177 12261],17) = NaN;
                    % Fix CO2 offset problems:
                    output(464:468,17) = NaN;
                    output(469:944,17) = output(469:944,17) + 100;
                    
                    %%% Shift flux data into UTC (right now in EDT)
                    try load([load_path site '_CPEC_clean_2006.mat' ]);  TP39_2006 = master.data; clear master;
                    catch
                        disp('could not load 2006 cleaned flux data');   TP39_2006 = NaN.*ones(size(output));
                    end
                    output = [TP39_2006(end-7:end,:); output(1:end-8,:)];
                    
                case '2008'
                    
                    output(5594:5599,17) = NaN; %
                    
                    clear bad_IRGA;
                    %%% Shift flux data into UTC (right now in EDT)
                    try load([load_path site '_CPEC_clean_2007.mat' ]);  TP39_2007 = master.data; clear master;
                    catch
                        disp('could not load 2007 cleaned flux data');   TP39_2007 = NaN.*ones(size(output));
                    end
                    output = [TP39_2007(end-7:end,:); output(1:end-8,:)];
                    
                case '2009'
                    output([13580:13589],17) = NaN;
                    output([13580:13711],18) = NaN;
                    
                    output(1:700,:) = NaN; % before installed.
                    output(output(:,17) == 455.6962,17) = NaN;
                    output(output(:,18) == 30.927267,18) = NaN;
                    output(output(:,22) == 5.0000019,22) = NaN;
                    
                    for jj = 19:1:26 % Remove zeros from CSAT data (bad data)
                        output(output(:,jj)==-1.5646218e-6,jj) = NaN;
                        if jj >= 23
                            output(output(:,jj)== 0,jj) = NaN;
                        end
                    end
                    %%% Remove concentration data during daily calibration:
                    %%% Cals were turned back on at data point 13, until the
                    %%% end of the year:
                    output((13:48:17520)',[17,18,1,5]) = NaN;
                case '2010'
                    output([3730 7907],17) = NaN;
                    
                    output(output(:,17) == 455.6962,17) = NaN;
                    output(output(:,17) == 450,17) = NaN;
                    
                    output(output(:,18) == 30.927267,18) = NaN;
                    output(output(:,22) == 5.0000019,22) = NaN;
                    for jj = 19:1:26 % Remove zeros from CSAT data (bad data)
                        output(output(:,jj)==-1.5646218e-6,jj) = NaN;
                        if jj >= 23
                            output(output(:,jj)== 0,jj) = NaN;
                        end
                    end
                    % Remove LE data when H2O is maxed out:
                    output((output(:,18)> 29.999 & output(:,18)< 29.9995) |...
                        (output(:,18)> 49.990 & output(:,18)< 50) | ...
                        (output(:,18)> 32.4999 & output(:,18) < 32.5001),[5 18]) = NaN;
                    
                    %%% Correct H2O and LE data for overestimation due to
                    %%% impropoper calibration:
                    output(3740:14296,18) = (output(3740:14296,18)-(-1.867)) ./ 1.7807;
                    output(3740:14296,5) = output(3740:14296,5).*0.57122;
                    %%% Remove concentration data during daily calibration:
                    %%% Cals were turned back on at data point 13, until the
                    %%% end of the year:
                    output((13:48:17520)',[17,18,1,5]) = NaN;
                case '2011'
                    %%% Remove concentration data during daily calibration:
                    %%% Cals were turned back on at data point 13, until the
                    %%% end of the year:
                    output((13:48:17520)',[17,18,1,5]) = NaN;
                    % Remove bad CO2 IRGA data
                    output([3911 5117:5118 5241:5243 10550:10605 14005 14062:14103 15483:15582],17) = NaN;
                    output([3911 5117:5118 5240:5243 9973:9974 10550:10605 14006 14103 15480:15520 16408:16430],18) = NaN;
                    output(output(:,17) == 455.6962,17) = NaN;
                    output(output(:,17) == 450,17) = NaN;
                    
                    output(output(:,18) == 30.927267,18) = NaN;
                    output(output(:,22) == 5.0000019,22) = NaN;
                    
                case '2012'
                    % Remove bad Fc data
                    output(176,1) = NaN;
                    % Remove bad CO2 IRGA data
                    output([174:175 1566:1568 4786:4836 5537 5849 7527:7531 7806:7807 10215 12569 14563 17317:17321 17323 17325 17327 17329 17331 17333 17335 17337 17339],17) = NaN;
                    % Remove bad H20 IRGA data (calibration)
                    output([599 600 602 1333:1335 1337 1339 1341 1343 1345 1347 1349 1351 1353:1355 4786:4788 4790 4792 4794 4796 4798 4800 4802 4804 4806 4808 4810 4812 5537:5539 5541 5543:5545 5547 5549 7806 7807 14563 7527:7531 17317:17321 17323 17325 17327 17329 17331 17333 17335 17337 17339],18) = NaN;
                    % Remove bad Penergy data
                    output(176,7) = NaN;
                    % Remove bad Le data
                    output(12568:12569,5) = NaN;
                    
                case '2013'
                    % Remove bad Fc data
                    output([6810 7364:7800 10523],1) = NaN;
                    % Remove bad LE data
                    output([5131 7364:7800 9610],5) = NaN;
                    % Remove bad pEnergy data
                    output(7364:7800,7) = NaN;
                    % Remove bad CO2 IRGA data
                    output([1246 1580:3452],17) = NaN;
                    % Remove bad H2O IRGA data
                    output([1246 1580:3452 7763: 8568:8569 15848 16541:16542],18) = NaN;
                    % Remove bad Ts data
                    output([7725:7794 8533:8569 10139:10170 11476:11496],22) = NaN;
                    % Remove bad IRGA Ta
                    output([1246 1323 1580:3452 5792:5806 6132 6804:6805 8568:8569 8570 9731 10748:10750 15857 16541:16542],27) = NaN;
                    % Remove bad IRGA pressure
                    output([1246 1580:3452],28) = NaN;
                    
                    %%% Fix time shifts introduced into flux data by computer
                    %%% timing issues (KEEP THESE LINES AT THE END OF FIXES FOR 2013)
                    output = [output(1:4274,:);output(4277:9106,:);NaN.*ones(2,size(output,2));output(9107:12924,:);output(12927:13863,:);...
                        NaN.*ones(2,size(output,2)); output(13864:17520,:)];
                    % Round 2 of fixes - found issues in the internal data logger clock
                    output = [output(1:4740,:);NaN.*ones(1,size(output,2)); output(4741:5051,:); output(5053:11533,:); output(11535:12119,:);NaN.*ones(1,size(output,2));...
                        output(12120:17520,:)];
                case '2014'
                    % Remove bad Fc data
                    output([2010 2097 3381 3356 15737 15830 15831],1) = NaN;
                    % Remove bad u* data
                    output([5701 5703 10405],2) = NaN;
                    % Missing HTc , HRcoeff, Bk sensors/data
                    output(:,[4 9 11]) = NaN;
                    % Remove bad LE data
                    output([2010 14004 15830],5) = NaN;
                    % Remove bad pEnergy data
                    output([2010 2097 3356 3381 5635 13387 15830 15831] ,7) = NaN;
                    % Remove bad CO2 IRGA data
                    output([ 1317 3381:3689 8777  15740 15779 15827:15833],17) = NaN;  %12046:12082
                    % Remove bad H2O IRGA data
                    output([ 1317  13875:13876],18) = NaN; % 12046:12082
                    % Remove bad Ts data
                    % output([ ],22) = NaN;
                    % Remove bad IRGA Ta
                    output([7877 7873 11493 13875 13894],27) = NaN;
                    % Remove bad IRGA pressure
                    output([1317 7873 8600:8778 11493 13875 15310 15740:15833],28) = NaN;
                    %%% Fix time shifts introduced into flux data by computer
                    %%% timing issues (KEEP THESE LINES AT THE END OF FIXES FOR 2014)
                    output = [output(1:4276,:);output(4279:14307,:);NaN.*ones(2,size(output,2));output(14308:17520,:)];
                    
                case '2015'
                    % Spikes in Fc
                    output([2918 4792 6503 9600 11336 13771 15089],1) = NaN;
                    % Spikes in UStar
                    output([4026 14613],2) = NaN;
                    % Big spikes in Penergy
                    output([207 601],7) = NaN;
                    % Bad periods in CO2-irga
                    output([2628:2918 6368:6473 14530:14532],17) = NaN;
                    % Spikes in H2O-irga
                    output([14532 15154],18) = NaN;
                    % Bad spikes in T-s
                    output([8553:8578 9106:9108 9362:9370 9530:9531 9601:9602 9605 9607:9609 10375 10653 10665 10667:10680 11119:11121 ...
                        12219 12989:12993 13029 13040:13055 13496:13505 15155:15156 16647:16667 17291:17299 17394:17408],22) = NaN;
                    % Bad spikes in T-irga
                    output([7249:7252 8003 9013 10159 10159:10167 11070:11087 11508],27) = NaN;
                    % Spikes in H2O-irga
                    %                 output([7249:7250 10159:10167 11070:11087], ) = NaN;
                    % Remove bad values for IRGA-related variables:
                    output([224:610],[17:18 1 5]) = NaN;
                    
                    %%% Fix time shifts introduced into flux data by computer
                    %%% timing issues (KEEP THESE LINES AT THE END OF FIXES FOR 2015)
                    output = [output(1:4178,:);output(4181:11124,:);NaN.*ones(2,size(output,2));output(11125:17520,:)];
                    
                case '2016'
                    % Spikes in Fc
                    output([514 736 1571:1573 1575 1957:1960 2290 4206 5168 6740 6754 7205 7590 8265 8320 10665 10964 11168 12357 13497 14780 17452],1) = NaN;
                    % Spikes in UStar
                    output([736 12540 12954 14144:14146],2) = NaN;
                    % Big spikes in Hs
                    output([412:416 2850 3779 3982 4352 5218 7137 8549:8553 9125 9374 9763 10271 11385 12513:12542 12955 12988 13132],3) = NaN;
                    % Spike in Le-L
                    output([2769 2777 2842 4211 5415 5793 7291 8265 8681 8727 9589 10046 11022],5) = NaN;
                    % Negative Spikes P-energy
                    output([514 736 1573 1575 1957:1960 2770:2778 4206 4935 5167 5168 6740 6754:6757 7205 7590 8265 8320 10387 10783 10964 12357 14780 16691 17452],7) = NaN;
                    % Tair Irregularities
                    output([736 747 1874 14423 14758],16) = NaN;
                    % CO2 irga
                    output([512 1571:1574 1957:1960 2769:2772 5933:5982 6090:6093 7088 7907 10077 10984:10986 11369 12598 12599 13229:13231 17334],17) = NaN;
                    % H20 - irga
                    output([6094 10984 11906],18) = NaN;
                    % T-s
                    output([10985 10986],22) = NaN;
                    % T - irga
                    output([512 5933:5994 6090:6095 7088 7907 10077 10985:10994 13229:13236 17334],27) = NaN;
                    % P - irga
                    output([512:515 5932:5982 6090:6095 6272:6275 7907 10077 10323:10409 13229:13231],28) = NaN;
                    
                case '2017'
                    % Spikes in Fc
                    output([161 2067 2097 4213],1) = NaN;
                    % Spikes in UStar
                    output([161 5764 5993],2) = NaN;
                    % Big spikes in Hs
                    output([124 130 157:161],3) = NaN;
                    % Negative Spikes P-energy
                    output([161 2067 2097 3992 6005 6615 10019],7) = NaN;
                    % CO2-irga and H2O-irga
                    output([9928:9930],[17 18]) = NaN;
                    output(10019,17) = NaN;
                    % T-irga dips
                    output([3206:3256 9931:10019],27) = NaN;
                    % P-irga dips
                    output([2058:2098 2722 3206:3256 5196:5310 9931:10019],28) = NaN;
                    % Remove data collected when IRGA was not working:
                    output(9929:10013,[1,5,17,18]) = NaN;
                    
                case '2018'
                    % Spikes in Fc
                    output([1529 2143 4991 5755 6155 6440 6849 7279 7454 8245 8792 ...
                        9087 9825 9901 9989 11007 11651 12317 12888 13957 17318],1) = NaN;
                    % U-star Values
                    output([4194],2) = NaN;   
                    % Spikes P-energy
                    output([586 1529 2143 4985 5755 6440 8035 8792 9087 9906 13409 13952 17318],7) = NaN;
                    % CO2-irga and H2O-irga
                    output([2881 4484 4503 4992 5023 5024 7279 7280 14876],17) = NaN;         
                    % w-wind Spikes
                    output([1011:1015 1027:1032 4128],21) = NaN;
                    % T-IRGA spikes
                    output([13778 14876],27) = NaN;
                    
                case '2019'
                    % Spikes in Fc
%                      output([916 1030 1363 9450 10589 12910 13391 15262],1) = NaN;
                    % Bad CO2 data
                    output([4208:4399 10365:10589 12658:13133],17) = NaN;
                    % Bad CO2 - where CO2 is flatlined around 450
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    output(bad_co2,[1 17]); % remove for Fc and CO2 concentration
                    % Bad H2O
                    output([4265:4400 10365:10589 12658:13133 17077:17083 14243 14863],18) = NaN;
                    output([8669 16059:16202],22) = NaN;
                
                case '2020'
                   bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                   output(bad_co2,[1 17]); % remove for Fc and CO2 concentration
                   
                   
                   output([7012 7469 8580],1) = NaN; %Fc spikes
                   output([15878 16086 16071:16073],2) = NaN; %ustar
                   output([7784 15701 16087],3) = NaN; %Hs
                   output([524 856 897 4260],5) = NaN; %LE-L
                   output([7012 12030 11945 15632],7) = NaN; 
                   output([3754 10554 11945 12189 15633],17) = NaN; %IRGA Co2
                   output([14569 16071 17029],18) = NaN;
                   output([10540:10544 11911:11912],22) = NaN;
                   output([15702 15878 16071 17031],23) = NaN;
                   output([5203 17031 16071 17031],26) = NaN;
                   output(856,30) = NaN;
                   output(output(:,15)<96,15) = NaN;
                  output([8681:9096 10545:10552 11109:11115 11869 12896 14502:14523 15846],15) = NaN; %BarometricP
                   
                case '2021' % EAR & LL
                   bad_co2 = find((output(:,17) > 449.9999 & output(:,17) < 450.0001) | (output(:,17) > 399.9999 & output(:,17) < 400.0001));
                   output(bad_co2,[1 17]) = NaN; % remove for Fc and CO2 concentration                    
                   output([607:810],17) = NaN; %IRGA Co2 
                   output([607:618 7996:8249],18) = NaN; %IRGA h2o 
                   badh2o = find(output(:,18)> 22.499 & output(:,18) < 22.501);
                    output(badh2o,18) = NaN;
                   bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
                    output(bad_csat,[19:27]) = NaN;
                    
               case '2022' % NH - Checked out - 2023-05-05
                   bad_co2 = find((output(:,17) > 449.9999 & output(:,17) < 450.0001) | (output(:,17) > 399.9999 & output(:,17) < 400.0001));
                   output(bad_co2,[1 17]) = NaN; % remove for Fc and CO2 concentration   
                   output([13919],3) = NaN; 
                   output([413:469 637:666 927:958 1885:1965 2279:2314 2487 3680:3690 5080:5082 5869:5885 6364:6393 7035:7038 7331:7354 8653:8689 8764:8767 9613:9640 10429:10450 11228:11242 11370 14710:14716 15553:15561 16187:16216 17217:17241],17) = NaN; %CO2irga
                   output([411:468 638:666 926:958 1885:1965 2279:2314 2487 3680:3690 5080:5082 5869:5885 6364:6393 7035:7038 7331:7354 8653:8689 8764:8767 9613:9640 10429:10450 11228:11242 11370 14710:14716 15553:15561 16187:16216 17217:17241],18) = NaN; %H2Oirga
                   output([1591 1603 2542 3071:3207 3660:3690 3714 3767 3947 4614:4634 5177:5184 5798 5809 5819:5821 5919 5925:5926 5931:5935 7031:7036 7331:7353 7568 9508:9511 9518:9519 9527:9530 9534:9537 9993:10003 10325:10333 10558:10565 10989:10990 11153:11156 11228:11241 11603 11884:11891 12201:12214 12557:12558 12679 12838 12848:12849 13690:13703 13905:13925 14061:14065 14663:14670 15113:15130 15330:15341 15876:15896 16186:16190 16727:16744 17095:17112 17216:17220 17458 17490:end],22) = NaN;%Ts
                  badh2o = find(output(:,18)> 22.499 & output(:,18) < 22.501);
                    output(badh2o,18) = NaN;
                   bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
                    output(bad_csat,[19:27]) = NaN;                   
                   
               case '2023' % EAR and NS - Checked out - 2024-01-12
                   bad_co2 = find((output(:,17) > 449.9999 & output(:,17) < 450.0001) | (output(:,17) > 399.9999 & output(:,17) < 400.0001));
                   output(bad_co2,[1 17]) = NaN; % remove for Fc and CO2 concentration   
                   output([573 578 587 5027 5747 5939 6895 8989 9104 16214],1) = NaN; %Fc
                   output([592 4027 8765 10006:10007 10995 11591],2) = NaN; %Ustar
                   output([1921:1923 7532 14152],5) = NaN; %LEL
                   output([11335 11343 11416],16) = NaN; %Tair
                   output([603:604 1209:1230 1924:1929 2553:2601 2727:2745 2845:2860 2990:3024 4031:4089 4765:4809 5053:5097 5526:5530 5988:5990 6249:6297 7141:7154 7788:7802 8659:8721 8749:8760 8820:8832 9805:9836 10717:10830 10847:10924 10957:10973 11967:12012 12123:12227 12425:12426 12541:12611 13213:13241 13789:13863 14152 16765:16811 17273:end],17) = NaN; %CO2irga
                   output([603:604 1209:1230 1924:1929 2553:2602 2727:2746 2845:2860 2981:3024 4031:4089 4765:4809 5053:5097 5526:5530 5988:5990 6249:6297 7141:7154 7788:7802 8659:8721 8749:8760 8820:8832 9805:9836 10717:10830 10847:10924 10957:10973 11967:12012 12123:12227 12541:12611 13213:13241 13789:13863 16765:16811 17273:end],18) = NaN;  %H2Oirga
                  badh2o = find(output(:,18)> 22.499 & output(:,18) < 22.501);
                    output(badh2o,18) = NaN;
                   bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
                    output(bad_csat,[19:27]) = NaN;                   
                   bad_Tirga = find(output(:,27) > 4.99999 & output(:,27) < 5.00001);
                    output(bad_Tirga,27) = NaN;    
                    
                case '2024' % LK and AH
                   bad_co2 = find((output(:,17) > 449.9999 & output(:,17) < 450.0001) | (output(:,17) > 399.9999 & output(:,17) < 400.0001));
                   output(bad_co2,[1 17]) = NaN; % remove for Fc and CO2 concentration 
                  output([2582 2585 3120 3129 6156 7813 12781 14907 16742],1) = NaN; %Fc
                  output([13743 17193 17495],2) = NaN;%Ustar
                  output([416 457 1312 3298 13790],3) = NaN; %Hs
                  output([578 11697 11702 16021],5) = NaN; %LE-L
                  output([14907],7) = NaN; %Penergy
                  output([578],17) = NaN; %CO2 IRGA
                  output([11518],18) = NaN; %H2O IRGA
                  output([13785],19) = NaN;
                  output([512 1102 3651 6021 9230 15598 16845 17192 17496],23) = NaN; %u-std
                  output([419 1337 2772 4453:4454 4457 5185 9230 12784 16492 16493 16845],24) = NaN; %v-std
                  output([419 1102 1337 2772 3651 4922 4938 6021 9230 12784 15598 16492 16493 16845 17192 17496],25) = NaN; %w-std
                  output([419 1337 2772 3651 4457 4922 4938 6021 8672 9230 12784 16493 17192],26) = NaN; %Ts-std
                  %lots of dips in col 28 (P-irga):
                  output([47:88 493:514 744:811 2653:2754 3325:3394 3927:4350 4939:4947 5312:5451 5454:5508 5661:5744 5965:6029 7261:7282 7549:7766 8221:8478 10547 10554:10592 11515:11518 11687:11696 11708:11712 12031:12085 12495:12517 15148:15166 15173 15517:15536 16017:16020 16035:16065 16825:16926],28) = NaN; %P-irga
                  output([578:580],29) = NaN; %CO2-std
                  output([579 8219 11518],30) = NaN; %H2O-std
                  output([1102 3651 11686 17488 17489 17496],31) = NaN; %u-rot
                  output([15358],33) = NaN;
                  
                  badh2o = find(output(:,18)> 22.499 & output(:,18) < 22.501);
                    output(badh2o,18) = NaN;
                   bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
                    output(bad_csat,[19:27]) = NaN;                   
                   bad_Tirga = find(output(:,27) > 4.99999 & output(:,27) < 5.00001);
                    output(bad_Tirga,27) = NaN;    

            end
        case 'TP74'
            %% ********************** TP74 *********************************
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%% % Added 19-Oct-2010 by JJB
            %%%% Clean CSAT and flux data using value of std for Ts or w
            bad_CSAT = isnan(output(:,26))==1 | output(:,26) > 2.5;
            output(bad_CSAT, [16 22]) = NaN;
            bad_CSAT2 = isnan(output(:,25))==1 | output(:,25) > 2.5;
            output(bad_CSAT2, [1:5 19 20 21]) = NaN;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            switch yr_str                
                %             case '2007'                
                case '2008'
                    bad_CO2 = [616 758 2075:2200 2680:2682 3201];
                    output(bad_CO2,18) = NaN;
                    clear bad_CO2;
                    output(9867,18) = NaN; % bad data point;
                    output(15366,2) = NaN; % bad data point;
                    output(1:400,:) = NaN; % before it was installed
                    bad_irga = [7804:7855 9025:9060 11367:11454]';
                    irga_cols = [1;5;6;7;8;17;18];
                    output(bad_irga,irga_cols) = NaN; %bad data
                    for jj = 19:1:26 % Remove zeros from CSAT data (bad data)
                        output(output(:,jj)==-1.5646218e-6,jj) = NaN;
                        if jj >= 23
                            output(output(:,jj)== 0,jj) = NaN;
                        end
                    end
                    clear irga_cols bad_irga;
                    %%% Remove concentration data during daily calibration:
                    %%% Cals were turned back on at data point 11, until the
                    %%% end of the year:
                    output([11:48:17568]',[17,18,1,5]) = NaN;
                    
                    %%% There is a lot of really noisy Fc data in the early
                    %%% part
                case '2009'
                    bad_irga1 = [ 8451:8492 14957:15147]';
                    bad_irga3 = [(6751:6795)'; bad_irga1];
                    bad_irga2 = [(5985:6408)' ; bad_irga3];
                    
                    output(bad_irga1,[1;7]) = NaN; % Fix Fc, Penergy, CO2, H2O
                    output(bad_irga3,[17;18]) = NaN; % Fix Fc, Penergy, CO2, H2O
                    output(bad_irga2,[5;6;8]) = NaN; % Fix LE, WUE
                    %                 output(5985:6408,7) = output(5985:6408,7).*-1; % Flip Penergy
                    output(8811,17) = NaN;
                    
                    for jj = 19:1:26 % Remove zeros from CSAT data (bad data)
                        output(output(:,jj)==-1.5646218e-6,jj) = NaN;
                        if jj >= 23
                            output(output(:,jj)== 0,jj) = NaN;
                        end
                    end
                    clear bad_irga*;
                    %%% Remove concentration data during daily calibration:
                    %%% Cals were turned back on at data point 11, until the
                    %%% end of the year:
                    output([11:48:17520]',[17,18,1,5]) = NaN;
                    %%% Remove flux data when computer undergoes auto-restart:
                    output([12:48:17520]',[1,5]) = NaN;
                    
                case '2010'
                    % bad Fc Data:
                    output(6014:6098,[1 3 5 7]) = NaN;
                    % bad CO2 data:
                    output([1182 3054 3733 3738 15014], 17) = NaN;
                    
                    for jj = 19:1:26 % Remove zeros from CSAT data (bad data)
                        output(output(:,jj)==-1.5646218e-6,jj) = NaN;
                        if jj >= 23
                            output(output(:,jj)== 0,jj) = NaN;
                        end
                    end
                    %%% Remove concentration data during daily calibration:
                    %%% Cals were turned back on at data point 3083, until the
                    %%% end of the year:
                    output([3083:48:17520]',[17,18,1,5]) = NaN;
                    
                    %%% Remove all data associated with IRGA for period of
                    %%% 12-Dec to 29-Dec, as IRGA was off...
                    output([16605:17421],[1 5 7 8 10 17 18]) = NaN;
                    %%% Remove flux data when computer undergoes auto-restart:
                    output([12:48:17520]',[1,5]) = NaN;
                case '2011'
                    % bad Fc data
                    output([1798:1824 3961:4220 5118:5214 6952:7281 7779:8335 9327:9334 12116],1) = NaN;
                    % bad LE data
                    output([1798:1824 3961:4220 5118:5214 6952:7281 7608:8335 9327:9334 12116],5) = NaN;
                    % bad CO2 data
                    output([1811:1812 6952:7080 8916:8919],17) = NaN;
                    % bad H2O data
                    output([1797:1818 6951:7080 7531 7581 15671:15675 16982:16987],18) = NaN;
                    
                case '2012'
                    % Bad CO2 - where CO2 is flatlined around 450
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    output(bad_co2,[1 17]); % remove for Fc and CO2 concentration
                    
                    % Bad Fc data
                    output([7524 10158:10164 ],1) = NaN;
                    % Bad Penergy data
                    output([7524 10155:10165],7) = NaN;
                    % bad CO2 IRGA data
                    output([12240:12250],17) = NaN;
                    
                case '2013'
                    % Bad CO2 - where CO2 is flatlined around 450
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    output(bad_co2,[1 17]) = NaN; % remove for Fc and CO2 concentration
                    
                    % Bad Fc data
                    output([1067 3035 16523],1) = NaN;
                    % Bad Penergy data
                    output([1067 3035 5387],7) = NaN;
                    % Bad CO2 IRGA data (flatline)
                    output([10109:10169],17) = NaN;
                    
                case '2014'
                    % Bad CO2 - where CO2 is flatlined around 450
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    output(bad_co2,[1 17]) = NaN; % remove for Fc and CO2 concentration
                    
                    % Bad Fc data
                    % output([2060 2095],1) = NaN;
                    % Spikes in T irga data
                    output([1326 7877 11493 13892 14139:14170 14709:14746 15751 ],27:28) = NaN;
                    
                case '2015'
                    % Bad CO2 - where CO2 is flatlined around 450
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    output(bad_co2,[1 17]) = NaN; % remove for Fc and CO2 concentration
                    % Spike in Fc
                    output([16811],1) = NaN;
                    %Spike in Ustar
                    output([2986 7647 17387],2) = NaN;
                    % Spike in H2O irga
                    output([2632:2645 5851:5866 6370:6394 6671:6682],18) = NaN;
                    
                    % Bad T-s data
                    output([133:161 4710 4740 4750 4754 5651:5743 6251 6299 7644:7646 7653 7658 7922:7936 8095:8102 ...
                        8523:8524 8555 8558:8569 8572:8575 8590 9150 9315 9346:9347 10654:10655 11085 11088 12225:12226 14439 ...
                        15582 17033:17035 17395:17408],22) = NaN;
                    
                    % Spike in T-irga & P-irga
                    output([2632:2645 5851:5866 6370:6394 6671:6682],[27 28]) = NaN;
                    output([7249:7256 11067:11087 15160:15161 16734],27) = NaN;
                    output([11067:11086],28) = NaN;
                    
                case '2016'
                    % Bad CO2 - where CO2 is flatlined around 450
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    output(bad_co2,[1 17]) = NaN; % remove for Fc and CO2 concentration
                    % Fc Spikes
                    output([4121 6370 6393 6417 6633 7044 7098 7099 7505 7590 7931 8621:8624 8937 9556 9606 9611 9800 9994 10042 10781 10860 11437 11442 12204 12665 13217 13218 13255 14278 14568 16715 17435],1) = NaN;
                    % Ustar Spikes
                    output([404 3010:3055 9910 10666 13738 16622:16626 17332],2) = NaN;
                    % Hs Spikes
                    output([407 2624 2657 6660 6710 7954 8433 8624 9369 11385 11602 13134 16902],3) = NaN;
                    % Le-L Spikes
                    output([2843 4435 6137 7044 7099 7284 8265 8266 8681 9351 9586 9972 11601 11700 11900 11901 12175 12325 14772 17337],5) = NaN;
                    % P energy spike
                    output([1604:1605 4121 6393 7098 7099 7165 7505 7590 7931 9556 9800 9994 10042 10666 10781 10964 11437 11442 12204 13217 13218 14568 16715 17435 17483],7) = NaN;
                    % C02 irga spikes
                    output([3961:3672 4211:4220 6826 7163 7164 8996 9775 12597:12602 13217],17) = NaN;
                    % H20 irga spikes
                    output([2142:2169 2183:2185 2211 6937:6952 7099 7356:7370 7539:7546 8625:8650 8864:8890 17330:17337],18) = NaN;
                    % Constant zero U,V, and W-values
                    output([2659 2660 2662:2678 2929:3049],[19:21]) = NaN;
                    % Bad T-s data
                    output([2164:2173 2179:2186 2190 2195 2198 2200 2202 2307:2308 2926:3055 10782 13229:13232 16627:16631 16890:16960 17334:17336],22) = NaN;
                    % T & P-irga
                    output([2142:2169 2184 2211 4211 6890:6924 6937:7100 7356:7370 7537:7546 8625:8650 8864:8890 9775 9776 9832:9834 10991:10993 11359:11367 13229:13235 17334:17338],27:28) = NaN;
                    
                case '2017'
                    % remove all irga variables when the pump died:
                    output(14787:15019,[1,5,17,18]) = NaN;
                    % Fc Spikes
                    output([11 203 347 443 491 1211 1979 2430 4235 5302 5312 5366 5531 5771 5819 5963 6002 6790 6799 7450 7520 7803 9535 9617 9682 9686 10350 12610 15556],1) = NaN;
                    % Ustar Spikes
                    output([134:170 1064 1819:1825 4309:4321 5969 8227 13623:13631 15323 15470],2) = NaN;
                    % Hs Spikes
                    output([1 875:891 1061 1062 1813 1820 1832 3137:3167 4011:4019 4314 4491 5366 5958:6010 8027 8511 9450 10331:10368 11765 11766 12721 13451:13457 13625:13627 15319 15465:15474],3) = NaN;
                    % LE-L Spikes
                    output([491 4495 7908 8730 9584 9590 9682 9686 10163 12721 15556 16276],5) = NaN; 
                    % P-Energy Spikes
                    output([11 203 347 443 491 1211 1499 1979 2430 2555 3386 4235 5312 5531 5819 5963 6002 6486 6633 6790 7161 7166 7416 7450 7520 7739 7908 8027 8309 9192 9616:9621 9682 9686 11911 12610 15556],7) = NaN;
                    
                    % T Air Spikes
                    output([6000 8334:8339 9295 10362 11864],16) = NaN;
                    % CO2 & H2O IRGA, T & P IRGA
                    output([1086:1114 1987:2011 3206:3251 7457:7459 9515:9584 9927:10030 10940 13816:13818 17319],[17 18 27 28]) = NaN;
                    % T-s Spikes
                    output([135:170 815:996 1835 3135 3715:3721 4299:4350 4474:4480 5997:6017 8214 8230 8332 8403:8406 9948 9949 9955:9957 9967 9968 9972 9978 9983 10006 10011 10012 10017 10020 10021 10333 10994:10999 11770:11785 13505:13516 13618 13816 14668 14833:14837 15456:15462 17109:17152],22) = NaN;
            
                    % U-V Wind Flat or Spike
                    output([143:172 815:874 930:941 946:995 1836:1840 3204:3240 3715:3721 4299:4308 4320:4351 4475:4484 6008:6017 8403:8406 10005:10030 10711 10994:11000 11769:11785 11865 13506:13516 13617 13629 13816 13817 14665:14668 14845:14847 15323 15456:15463 17106:17152],[19 20]) = NaN;
                    % W-Wind Spikes
                    output([1:5 132:175 815:893 1813 1830:1837 2142 2290 3138:3169 3204:3240 3708:3721 4298:4347 4473:4492 5268 5284 5296:5315 5957:5973 6009 7158 7803 8513 9962:9984 10016:10018 10889 11001:11003 11766:11784 13506:13516 13631 13815:13822 14846:14848 15325 15456:15462 17106:17152],21) = NaN;
                
                case '2018'
                    % Fc Spikes
                    output([2769 4985 5363 7015 7469:7475 7570 8557 9179 9989 11678 12341 15929],1) = NaN;
                    % u-star Spikes
                    output([370:372 6209 16085 16318],2) = NaN;
                    % Le-L Spikes
                    output([4985 7866:7869 8433 9105 11221 12953 14091 14864],5) = NaN;
                    % P-Energy Spikes
                    output([2769 4985 5065 7015 7470:7475 7570 8557 9179 9989 10814 12341 15929],7) = NaN;
                    % CO2 & H2O, T-IRGA
                    output([162:198 2474:2479 2881 2882 4484 4485 4503 4504 4992 4993 5024:5026 6021:6058 ...
                        7135:7137 7476 11221 13778 14876:14878],[17 18 27]) = NaN;
                    % U, V, W wind Flat line
                    output([16260:16841],[19:22]) = NaN;
                    % P-IRGA Spikes
                    output([468:473 2474:2479 2881 2882 4484 4485 4503 4504 4992 4993 5024:5026 ...
                        6021:6058 7135:7137 7476 13778 14876:14878],28) = NaN;
                case '2019'
                    % Bad Ustar
                    output([17432:17520],2) = NaN;
                    % Bad Ts - where Ts is flatlined around 5
                    bad_Ts = find(output(:,22) > 4.999 & output(:,22) < 5.001);
                    output(bad_Ts,[22]) = NaN; % remove for Ts
                    % Bad CO2 - where CO2 is flatlined around 450
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    output(bad_co2,[1 17]) = NaN; % remove for Fc and CO2 concentration
                    % bad H2O
                    bad_h2o = find(output(:,18) > 18.9999 & output(:,18) < 19.0001);
                    output(bad_h2o,[5 18]) = NaN;
                    
                case '2020' %Alanna
                    
                    output([1331 1355 4427 16570:16571 9825],1) = NaN; %Fc
                    output([529 5592 12025],2) = NaN; %Ustar
                    output([534 479 9155 16073:16084],3) = NaN; %Hs
                    output([4262 6461 8292 10160 11656:11661 14680 10163],5) = NaN; %LE-L
                    output([1355 4427 8791 9229 9918 9825 12650 12647],7) = NaN; %Penrgy
                    output([491:503 12310:12312 861:862 484:485],16) = NaN; %Tair
                    output([510:511 4415 4544 6460 8296:8297 11686:11687],17) = NaN; %CO2irga
                    output([510:511 4257],18) = NaN; %H2Oirga
                    output([169 482 859 4249 10039:10041 10050:10053 14052:14341 17020],[19:22]) = NaN; %u,v,w
                    output([862 8296 9636 10050 11400 10290 11520 11570 11660],[22 26]) = NaN; %Ts
                    output(output(:,22)>5.000001 & output(:,22)<5.000002,[22 26]) = NaN; %%% Filter out 
                    output([462:546 859 1216 2327 2964:2966 4239:4253 5201:5210 5595 7511 10050:10053 14052:14341 17021:17030],23:25) = NaN; %u,v,w-std
                    output([510 523 6460 8296 11520 15370],27) = NaN; %Tirga
                    output(output(:,27)>10.00000099 & output(:,27)<10.00000101,27) = NaN; %%% Filter out

                    output([510 6459 8296:8537 11520 15350],28) = NaN; %Pirga
                    output([1355 2507 3755 4544 6461 10160 11930 12170 12720 16570 12000 12650],29) = NaN; %CO2 std
                    output([6461 8298 11540 11660 14260],30) = NaN; %H2Ostd
                    output([532 859 1216 2327 2962:2967 4248 4776 5589 10050 14670 16070],34:36) = NaN; 
                    
                    output([8773:8774 8976 9022 9984 10320 10656 10992 11328 13008 17568],15) = NaN; % Barometric P
                            
                case '2021'  % EAR & LL
                     output([2573 9468:9469 9477 14512:14513 16279],2) = NaN; %Ustar
                     output([3453 6419 9728 13770],5) = NaN; %LE-L
                     output([8453 8456 8507:8768 8788:9407 9476 12011 12020 13260 14300 14506 16282 17338:17340],19) = NaN; %u
                     output([8507:8768 8788:9407 9456 13497 16277],20) = NaN; %v
                     output([4820 8219 8507:8768 8788:9407 12676:12677],21) = NaN; %w
                     output([8507:8768 8788:9407 12733],22) = NaN; %T-s
                     output([3057:3453 13759:13768]) = NaN; % CO2-irga
                     output(output(:,22)>5.000001 & output(:,22)<5.000002,[22 26]) = NaN; %%% Filter out bad csat data
                    output([10411 13759:13768],27) = NaN;
                    
               case '2022' % NH
                    
                    output([7718 10560 10980 12280 14096],5) = NaN; 
                    output([342 7613:7624 8183 10978],17) = NaN; 
                    output([9997],22) = NaN; 
                    output([53:56 1588 1617 2305 2546 5183 9511 11870 16743:16757],24) = NaN; 
                    output([53 54 1605 1618 2011 3756 16148:16150 16187 16743:16757 17217:17220],25) = NaN; 
                    output([50 53 401 1618 2011 2305 2545 3753 9516 16148:16150 16743:16757],26) = NaN; 
                    output([10940 17230],27) = NaN; %CO2irga
                    output([5098 5310 5355 7287 7430 7684 10254:10255 10937:10955 16189:16191 17215:17231],28) = NaN; 
                    % Bad Ts - where Ts is flatlined around 5
                    bad_Ts = find(output(:,22) > 4.999 & output(:,22) < 5.001);
                    output(bad_Ts,[22 27]) = NaN; % remove for Ts
                    % Bad CO2 - where CO2 is flatlined around 450
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    output(bad_co2,[1 17]) = NaN; % remove for Fc and CO2 concentration
                    % bad H2O
                    bad_h2o = find(output(:,18) > 18.9999 & output(:,18) < 19.0001);
                    output(bad_h2o,[5 18]) = NaN;
                    % bad CSAT
                    bad_csat = find(output(:,19) > -0.00001 & output(:,19) < 0.00001);
                    output(bad_csat,19:21) = NaN;
               case '2023' % EAR and NS Checked 2024-01-12
                    output([704 2726 2982 3123 5007 5027 5048 11380 16063 17298],1) = NaN; %Fc
                    output([571 586 895 931 934 1205 1378 1927 3635 4018:4030 5089:5092 5356 9645 9647 10995],2) = NaN; %Ustar
                    output([575 583:606 925 932 1204 1205 1207 1306 2979 3255 3604 3917 5351 6694 6564 7091 7786 8626 8868 9107  9215 9281 9587 9933 10529 11222 13346 16822:16824 14876:14877 ],3) = NaN; %Hs
                    output([2724 2982 6998 7619 8862 10889 12019 16440 17298],5) = NaN; %LEL
                    output([1464 1512 1656 1704],18) = NaN; %
                    % Bad Ts - where Ts is flatlined around 5
                    bad_Ts = find(output(:,22) > 4.999 & output(:,22) < 5.001);
                    output(bad_Ts,[22 27]) = NaN; % remove for Ts
                    % Bad CO2 - where CO2 is flatlined around 450
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    output(bad_co2,[1 17]) = NaN; % remove for Fc and CO2 concentration
                    % bad H2O
                    bad_h2o = find(output(:,18) > 18.9999 & output(:,18) < 19.0001);
                    output(bad_h2o,[5 18]) = NaN;
                    % bad CSAT
                    bad_csat = find(output(:,19) > -0.00001 & output(:,19) < 0.00001);
                    output(bad_csat,19:21) = NaN;
              
                case '2024' % LK, AH
                    output([2581 2585 3926 5660 6084 16791],1) = NaN; %Fc
                    output([3926 5660 7471 7476 10232 10315:10318 13423 16017:16018 16791],5) = NaN; %LEL
                    output([3121:3123 3623:3331 3404:3498 3261:3335],17) = NaN; %CO2irga
                    output([1210 7690 10155 10165 11685 17455 17568],19) = NaN; %u
                    output([9235 9488 17208],20) = NaN; %v
                    output([1221 3289:3297 3442 3784 7087 7192 7689 8667:8672 9188 9233 14902 15967 16944 16957 16959],21) = NaN; %w
                    output([7701 9188 9190 10998 10999 11675 11678 11679 11983 11984],22) = NaN; %T-s
                    output([6942:7522 10057 11380:11405 11694 11929 12505 12697 13425 15173 17071:17082 17170:17461],28) = NaN; %P-irga
                    
                    output([10057 11929 12505 12697 16021 ],27) = NaN; %Tirga
                    output([11406:11557],28) = NaN; %pirga
                     % Bad Ts - where Ts is flatlined around 5
                    bad_Ts = find(output(:,22) > 4.999 & output(:,22) < 5.001);
                    output(bad_Ts,[22 27]) = NaN; % remove for Ts
                    % Bad CO2 - where CO2 is flatlined around 450
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    output(bad_co2,[1 17]) = NaN; % remove for Fc and CO2 concentration
                    % bad H2O
                    bad_h2o = find(output(:,18) > 18.9999 & output(:,18) < 19.0001);
                    output(bad_h2o,[5 18]) = NaN;
                    % bad CSAT
                    bad_csat = find(output(:,19) > -0.00001 & output(:,19) < 0.00001);
                    output(bad_csat,19:21) = NaN;
           
            end
            
            %     case 'TP89'
            %% ********************** TP89 *********************************
            %         switch year
            %             case '2008'
            %             % Adjust nighttime PAR to fix offset:
            %              output(output(:,6) < 8,6) = 0;
            %              % Adjust RH to be 100 when it is >100
            %              output(output(:,2) > 100,2) = 100;
            %         end
            
            
        case 'TP02'
            %% ********************** TP02 *********************************
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%% % Added 19-Oct-2010 by JJB
            %%%% Clean CSAT and flux data using value of std for Ts or w
            bad_CSAT = isnan(output(:,26))==1 | output(:,26) > 2.5;
            output(bad_CSAT, [16 22]) = NaN;
            bad_CSAT2 = isnan(output(:,25))==1 | output(:,25) > 2.5;
            output(bad_CSAT2, [1:5 19 20 21]) = NaN;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            switch yr_str
                %             case '2007'
                case '2008'
                    output(1:8750,:) = NaN; %%%% Removing in-lab (test period)
                    output(14534:15836,:) = NaN; %%%% Removing bad period - PDQ problems??
                    for jj = 19:1:26 % Remove zeros from CSAT data (bad data)
                        output(output(:,jj)==-1.5646218e-6,jj) = NaN;
                        if jj >= 23
                            output(output(:,jj)== 0,jj) = NaN;
                        end
                    end
                    %%% Remove concentration data during daily calibration:
                    %%% Cals were turned back on at data point 11, until the
                    %%% end of the year:
                    output([11:48:17568]',[17,18,1,5]) = NaN;
                    %%% Remove flux data when computer undergoes auto-restart:
                    output([12:48:17568]',[1,5]) = NaN;
                case '2009'
                    for jj = 19:1:26 % Remove zeros from CSAT data (bad data)
                        output(output(:,jj)==-1.5646218e-6,jj) = NaN;
                        if jj >= 23
                            output(output(:,jj)== 0,jj) = NaN;
                        end
                    end
                    output([5953 9676:9695 14118:14167],17) = NaN;
                    %%% Remove concentration data during daily calibration:
                    %%% Cals were turned back on at data point 11, until the
                    %%% end of the year:
                    output([11:48:17520]',[17,18,1,5]) = NaN;
                    
                case '2010'
                    for jj = 19:1:26 % Remove zeros from CSAT data (bad data)
                        output(output(:,jj)==-1.5646218e-6,jj) = NaN;
                        if jj >= 23
                            output(output(:,jj)== 0,jj) = NaN;
                        end
                    end
                    %%% Remove LE data when H2O is maxed out:
                    output(output(:,18)> 39.999,5) = NaN;
                    %%% Remove bad CO2 data:
                    output([3068 3069 3724 3725 3781],17) = NaN;
                    
                    %%% Remove concentration data during daily calibration:
                    %%% Cals were turned back on at data point 3083, until the
                    %%% end of the year:
                    output([3083:48:17520]',[17,18,1,5]) = NaN;
                    %%% Remove flux data when computer undergoes auto-restart:
                    output([12:48:17520]',[1,5]) = NaN;
                    
                    %%% Correct H2O and LE data for overestimation due to
                    %%% impropoper calibration:
                    output(3750:14295,18) = (output(3750:14295,18)-(-4.2219)) ./ 1.4544;
                    output(3750:14295,5) = output(3750:14295,5).*0.68951;
                    
                case '2011'
                    % Bad Fc data
                    output([203 5016:5029 7259:7277 9341:9346],1) = NaN;
                    % Bad CO2 IRGA data
                    output(6282:6330,17) = NaN;
                    
                case '2012'
                    % Bad Fc data (for 3 days CO2 dropped to
                    % ~250, not entirely sure of cause but likely gas-related
                    output([11569:11710 14589:14895 15114:15313],1) = NaN;
                    % Bad CO2 IRGA data (same problem as above)
                    output([3878:3885 3926:3931 6711:6720 6753:6768 6806:6815  11569:11710 14589:14895 15114:15313],17) = NaN;
                    % Bad Penergy data (same problem as above)
                    output([11569:11710 14589:14895 15114:15313],7) = NaN;
                    % Bad H2O IRGA data
                    output([11709 14247 15127:15175],18) = NaN;
                    
                case '2013'
                    % Bad Fc data
                    output(17132,1) = NaN;
                    % Bad CO2 IRGA data
                    output([3695:3856 6130 6457:6463 17133],17) = NaN;
                    % Bad H2O IRGA data
                    output(3695:3856,18) = NaN;
                    % Bad Ts data
                    output(9114:9447,22) = NaN;
                    % Bad Tirga, Pirga data
                    output([3694:3857 10119:10177 14330 14618],27:28) = NaN;
                case '2014'
                    % missing Fc, u*, Hs, LE, Penergy, Bl, Eta, theta, beta, P& Tair,
                    % CO2irga, H2O irga, u,w,Ts  data,
                    % output(10525:12525,[1:3 5:6 7 10 12:22]) = NaN;
                    % Not sure - a couple hours in the midde, shuold we get rid
                    % of these?
                    %%% REMOVE IRGA DATA FOR MALFUNCTIONING PERIOD FOR ALL VARIABLES
                    output(4501:12500,[17,18,1,5,7,8,27,28,29,30])=NaN;
                    output(11550:11551,:) = NaN; % Bad points
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    bad_h2o = find(output(:,18) > 18.9999 & output(:,18) < 19.0001);
                    bad_CSAT = find(output(:,19)==-1.5646218e-6);
                    output(bad_CSAT,19:26)= NaN;
                    
                    % Bad CO2 irga (flatlines @ 400)
                    output(bad_co2,17) = NaN;
                    % Bad H2O irga (flatlines)
                    output(bad_h2o,18) = NaN;
                    % T Irga spikes
                    output([5825 6935 9890 15354 15780],27) = NaN;
                    
                case '2015'
                    % Fc spikes,
                    output([390 400 1958:1959 2147 6120 6446 7117:7118 13820 14811:14812 15771:15773],1) = NaN;
                    % Ustar spike
                    output([4065],2) = NaN;
                    % Penergy spikes
                    output([390 400 1958:1959 7117:7118 14811:14812 15771:15773],7) = NaN;
                    % Fc spikes, Penergy, IRGA
                    output([2146:2147 11913 13820 16744],[1 7 17 18]) = NaN;
                    % CO2-irga
                    output([376 399:400 2148 2248 6350:6393 8863:8896],17) = NaN;
                    
                    % H2O IRGA spikes
                    output([376 2148 2248 8892:8911 9077:9100 9733 13821],18) = NaN;
                    % Bad T-s points
                    output([10622 11054 11055 13406:13407],22) = NaN;
                    % Tirga only
                    output([175:177 4957:4958 13820:13821 14783:14784 16744:16745],27) = NaN;
                    
                case '2016'
                    %Fc Spikes
                    output([3149 5223 5413 6083 6837 7020 7376 7528 7614 7905 8237 8624 8679 8758 8813 9047 9368 9762 9850 10218 10898 10962 10964 11306 12110 12169 13034 13216 13904],1) = NaN;
                    %Ustar
                    output([4435 9368 9764 11890 11617],2) = NaN;
                    %LE-L Spikes
                    output([2622 2624 2625 2628 2629 3637 4197 5223 5413 7004 7528 7561 7676 9910 10615 10788 11123 13286 14421 17329],5) = NaN;
                    %Penergy Spikes
                    output([3149 3481 6083 6837 7020 8758 8813 9047 9368 9606 9850 10898 10964 11306 12169 13216],7) = NaN;
                    %CO2-IRGA spikes
                    output([182 7383 8852 10006 12640 14673],17) = NaN;
                    %H2O IRGA spikes
                    output([182 9778 10983:10986 15023 17332],18) = NaN;
                    %T-s spikes
                    output([1873:1880 2930:2952 9768],22) = NaN;
                    %u-std spikes
                    output([16907:16911],23) = NaN;
                    %v-std spikes
                    output([16907:16911],24) = NaN;
                    %w-std spikes
                    output([16907:16911],25) = NaN;
                    %Ts-std spikes
                    output([16907:16911],26) = NaN;
                    %T IRGA spikes
                    output([325 326 10986 11376 12132],27) = NaN;
                    %P IRGA spikes
                    output([182 7172 7173 7174 7175 7383 10983:10985],28) = NaN;
                    
                case '2017'
                    % Fc Spikes
                    output([180 327 728 986 1089 1564 2416 2807 3815 4184 4431 4448 4788 5316 5754 6129 6177 6538 6539 7189 7785 8361 8730 8989:8991 9188 9285 9619 10296 10865 10928 11956 13363 13455 14092 16278 16443 16585],1) = NaN;
                    % Ustar Spikes
                    output([4492 4805 5366 8209 8401 11956:11958 15463:15470 16911 17131],2) = NaN;
                    % Hs Spikes
                    output([874 2067 3953 4326 4492 6415 7228 8197 11856 11991 14270 15465],3) = NaN;
                    % LE-L Spikes
                    output([318 466 491 1822 2066:2073 2471 2881 3953 4657 5316 6128 6129 6177 6414 6813 7189 7217 7424 8508 8534 8658 8914 9638 10206 10556 10795 10937 11222 11893 11992 12369 12612 12755 13450 14717 16443],5) = NaN;
                    % Penergy Spikes
                    output([728 1088 2806 2807 3815 4184 4431 4788 5316 6177 6538 6539 7025 7785 8361 8730 8989:8992 9188 9619 10296 10865 10928 11956 13363 13791 16210],7) = NaN;
                    
                    % Tair Spikes
                    output([5796 14945:15148 15454:15467 16909 16911],16) = NaN;
                    % CO2-irga Spikes
                    output([2283 2517:2520 3205 3206 7408 8561:8564 8731 9180 9185 9520 9924:10028 10244:10248 10483 10928 11632 11897 15001],17) = NaN;
                    % H2O-irga Spikes
                    output([3205 3206 8730:8740 9924:10025 10927 12364],18) = NaN;
                    
                    % u Spikes
                    output([489:491 872:874 2647 4805 5763 7107 7156 8509 8731 10026 13511:13518 16905],19) = NaN;
                    % v Spikes
                    output([264 400 489:491 872:874 3693 4791 4792 5278 5763 8209 10888 13511:13519 13615 14699 15462 15463],20) = NaN;
                    % w Spikes
                    output([480 490 491 617 871 4326 4492 5278 6703 7189 8055 8340 10888 11111 13511:13519 14832 15106 15462:15470 16903:16906],21) = NaN;
                    
                    % T-s Spikes
                    output([5796 13511:13518 15462],22) = NaN;
                    % T-irga Spikes
                    output([1088 3216 3217 5315 6813 8737 8738 10026:10060 10205:10206 10328:10404 10421:10442 10520:10540 10911:10928 11897:11902 12369 12804:12811 13455 13456],27) = NaN;
                    % P-irga Spikes
                    output([3205 3206 6812 8336 8533 8731 9924:10025 11318 11897 12365 12612 14092],28) = NaN;                    
                
                case '2018'
                    % Fc Spikes
                    output([456 4227 4997 5459 7068 7184 7583 7985 8507 9101 9411 9565 ...
                        11838 12143 12471 14856 16504],1) = NaN;
                    % u-star Spikes
                    output([1301 1304 2175 2401 4481 5887 14026],2) = NaN;
                    % Hs Spikes
                    output([559 4481 5065 15353],3) = NaN;
                    % LE-L Spikes
                    output([4607 4997 5954 7959 9158 11600],5) = NaN;
                    % P-energy Spikes
                    output([456 4997 5037 5459 7068 7184 7583 7985 8507 8939 9100 9565 11006 11444 14856 16504],7) = NaN;
                    % CO2-irga & H2O-irga Spikes
                    output([4998:5028 5458 5459 5679:5746 7579:7584],[17 18]) = NaN;            
                    % T-irga Spikes
                    output([5016:5039 5078 5079 5954 5955 7166 7583 7874 14861],27) = NaN;
                    % P-irga Spikes
                    output([4998:5015 5021:5028 5679:5746 14861],28) = NaN;
                case '2019'
                    output([7750:8070],1:14) = NaN;
                    output([4213 4216 4402 4405 11217 13477 15861:15971 16258],17) = NaN;
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    bad_h2o = find(output(:,18) > 18.9999 & output(:,18) < 19.0001);
                    bad_CSAT = find(output(:,19)==-1.5646218e-6);
                    output(bad_CSAT,19:26)= NaN;
                    % Bad CO2 irga (flatlines @ 400)
                    output(bad_co2,[17 1]) = NaN;
                    % Bad H2O irga (flatlines)
                    output(bad_h2o,[18 5]) = NaN;
                    
                case '2020' %done by AB
                    % some large data gaps present
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    bad_h2o = find(output(:,18) > 18.9999 & output(:,18) < 19.0001);
                    bad_CSAT = find(output(:,19)==-1.5646218e-6);
                    output(bad_CSAT,19:26)= NaN;
                    % Bad CO2 irga (flatlines @ 400)
                    output(bad_co2,[17 1]) = NaN;
                    % Bad H2O irga (flatlines)
                    output(bad_h2o,[18 5]) = NaN;
                   output([639 862 3243 16552],1) = NaN; %Fc 
                   output([862 3331:3341 17524],2) = NaN; %Ustar
                   output([3332:3341],5) = NaN; %LE-L
                   output([3243 9511 16552],7) = NaN; %Penergy
                   output([499:504],16) = NaN; %Ta
                   
                   % significant dips/declines in CO2
                    output([2483 9104 14150:14489 16072:16704],17) = NaN; %CO2irga
                   
                   output([7786 16552],18) = NaN; %H2Oirga
                   output([860:962 2962 2959 5780:5794 15350:15399],19) = NaN; %u
                   output([2968:3024 3803:3804 9242:9252],20) = NaN; %v
                   output([454:504 855 9240:9241 11222:11232],21) = NaN; %w
                   output([489:493 8565:8566 9240:9253 11554:11561 ],22) = NaN; %T-s
                   output([858 2326 2959:3025 3331:3347 5761:5794 9240:9253 17523 ],[23:26 33:35]) = NaN; 
                   output([715 2484:2488 8301:8533 11221:11229 ],28) = NaN; %Pirga
                   output([2483 9104 9575 14150 16170 16550],29) = NaN; %CO2 std
                   output([524 2958 3014 3243 3331 9104 14150 16170 16550],30) = NaN; %H2O std
                   output([859 2966 3804 15350],31) = NaN; %urot
                   
                   output([8784 9984 9792 10176 10272 10464 10560 10896 11232 14064 14400 14736 15072 15792 16176 16896 17232 17568],15) = NaN; %barometric P

                case '2021' % EAR & LL
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    bad_h2o = find(output(:,18) > 18.9999 & output(:,18) < 19.0001);
                    % Bad CO2 irga (flatlines @ 400)
                    output(bad_co2,[17 1]) = NaN;
                    % Bad H2O irga (flatlines)
                    output(bad_h2o,[18 5]) = NaN;
                    
                    output([2469:2584 5152:5235],17) = NaN;
                    
                    
                    bad_CSAT = find(output(:,19)==-1.5646218e-6);
                    output(bad_CSAT,19:26)= NaN;
                    
                    %u spike
                    output([832 2576 7093 1692 9488 15285 16538],19) = NaN; 
                    %v spike
                    output([4059 7097 7099 9065 15264 16283],20) = NaN;
                    
                case '2022' % EAR & LL - 2023-05-05
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    bad_h2o = find(output(:,18) > 18.9999 & output(:,18) < 19.0001);
                    % Bad CO2 irga (flatlines @ 400)
                    output(bad_co2,[17 1]) = NaN;
                    % Bad H2O irga (flatlines)
                    output(bad_h2o,[18 5]) = NaN;
                    
                    output([2469:2584 5152:5235],17) = NaN;
                    
                    
                    bad_CSAT = find(output(:,19)==-1.5646218e-6);
                    output(bad_CSAT,19:26)= NaN; %Copied rows 1071 to 1082 from 2021. Is this correct?

                    output([3669], 1) = NaN;%Fc
                    output([15213], 17) = NaN;%CO2 irga
                    output([15213], 18) = NaN;%H2O irga
                    output([7549], 19) = NaN;
                    output([9817:9821], 22) = NaN;

                 case '2023' % EAR & NS - 2024-01-12
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    bad_h2o = find(output(:,18) > 18.9999 & output(:,18) < 19.0001);
                    % Bad CO2 irga (flatlines @ 400)
                    output(bad_co2,[17 1]) = NaN;
                    % Bad H2O irga (flatlines)
                    output(bad_h2o,[18 5]) = NaN;
                    
                    %output([2469:2584 5152:5235],17) = NaN;
                    
                    
                    bad_CSAT = find(output(:,19)==-1.5646218e-6);
                    output(bad_CSAT,[2, 19:26])= NaN; %Copied rows 1071 to 1082 from 2021. Is this correct?
                    bad_Tirga = find(output(:,27)> 9.9999 & output(:,27) < 10.0001);
                    output(bad_Tirga,27) = NaN;
                   % output([4354 5052 5139 6887 8370 8974 9522 9526 12327 12372 14157 14218:14219 14311], 1) = NaN; %Fc
                    %output([1377 1378 1922:1925 2265 2998 5086 5359:5360 5362:5363 9645 10063 10994 14147 14535 15848:15850],2) = NaN;%Ustar
                    %output([200 201 811 1308:1317 1924 5359 5363 6565 9645 9831 10353:10360 12517:12528 13400:13415 15848:15850 16069:16932 16983:17088 17300], 3) = NaN;%Hs
                    output([2725 4353 5139 5366 5753 6355 6694 6887 7259 8370 8423 8974 9224 9522 9526 9644:9646 9766 10047 5052 4354 2604 1922 1194 1038 954 10514], 1) = NaN;
                    output([4354 5052], 7) = NaN;%Penergy
                    %output([1926:1931 2562:2691 3303:3316 4022:4043 16642:17090], 18) = NaN;%H2O irga
                    
                case '2024' % LK
                    bad_co2 = find(output(:,17) > 449.9999 & output(:,17) < 450.0001);
                    bad_h2o = find(output(:,18) > 18.9999 & output(:,18) < 19.0001);
                    % Bad CO2 irga (flatlines @ 400)
                    output(bad_co2,[17 1]) = NaN;
                    % Bad H2O irga (flatlines)
                    output(bad_h2o,[18 5]) = NaN;
 
                    bad_CSAT = find(output(:,19)==-1.5646218e-6);
                    output(bad_CSAT,[2, 19:26])= NaN; %Copied rows 1071 to 1082 from 2021. Is this correct?
                    bad_Tirga = find(output(:,27)> 9.9999 & output(:,27) < 10.0001);
                    output(bad_Tirga,27) = NaN;
                    
                    output([284 1370], 1) = NaN;%Fc
                    output([15600:15601], 2) = NaN;%ustar
                    output([10595:10604 11166 17555 17556], 17) = NaN;%C02irga
                    output([17555 17556 10597:11167], 18) = NaN;%h20irga
                    output([573 601 993:1030 7851 8579 10448:10529 10594 11908:12231 14375:14867 ], 28) = NaN;
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TPD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
        case 'TPD'
            %% ********************** TPD *********************************
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%% % Added 19-Oct-2010 by JJB
            %%%% Clean CSAT and flux data using value of std for Ts or w
            %             bad_CSAT = isnan(output(:,26))==1 | output(:,26) > 2.5;
            %             output(bad_CSAT, [16 22]) = NaN;
            %             bad_CSAT2 = isnan(output(:,25))==1 | output(:,25) > 2.5;
            %             output(bad_CSAT2, [1:5 19 20 21]) = NaN;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            switch yr_str
                %             case '2007'
                case '2012'
                    output([809:822],1) = NaN;
                    output([808, 1524:1539 2484],17) = NaN;
                    badh2o = find(output(:,18)> 49.995 & output(:,18) < 50.005);
                    output(badh2o,18) = NaN;
                    %                  badh2o = find(output(:,18)> 22.495 & output(:,18) < 25.005);
                    %                  output(badh2o,18) = NaN;
                    
                    % remove bad IRGA data:
                    bad_P = [5291:5362, 5366];
                    output(bad_P,[17:18 27:30]) = NaN;
                    
                    %remove bad LE_L data
                    output([808 816],5) = NaN;
                    
                    % remove bad H20 IRGA data
                    output([14916:15632 15755:15924 11147:11259],18) = NaN;
                    
                    %remove bad u data
                    output([14916:14932 14962:14995 15009:15200 15207:15210 15228:15336 15391:15632],19) = NaN;
                    
                    %remove bad v data
                    output([14916:14932 14962:14995 15009:15200 15207:15210 15228:15336 15391:15632],20) = NaN;
                    
                    %remove bad w data
                    output([14916:14932 14962:14995 15009:15200 15207:15210 15228:15336 15391:15632],21) = NaN;
                    
                    %remove bad Ts data
                    output([14916:14932 14962:14995 15009:15200 15207:15210 15228:15336 15391:15632],22) = NaN;
                    
                    %remove bad T irga data
                    output([8251:8266 8300:8314 8783:8790 8974:8990 9015:9043 9056:9086 9116:9123 9179:9204 9310:9320 9357:9371 9541:9575 9839:9855 9882:9892 10361:10376 10407:10424 11147:11259 11421:11427 12059:12069 14916:14932 14962:14995 15009:15200 15207:15210 15228:15336 15391:15632 15755:15924],27) = NaN;
                    %
                    %                 % Remove bad CSAT data:
                    %                 bad_CSAT = find(output(:,19)==-1.5646218e-6);
                    %                 output(bad_CSAT,19:26)= NaN;
                    %                 bad_CSAT2 = find(output(:,23)< 0.005);
                    %                 output(bad_CSAT2,19:26)= NaN;
                    %                 for jj = 19:1:26 % Remove zeros from CSAT data (bad data)
                    %                     output(output(:,jj)==-1.5646218e-6,jj) = NaN;
                    %                     if jj >= 23
                    %                         output(output(:,jj)== 0,jj) = NaN;
                    %                     end
                    %                 end
                    
                case '2013'
                    bad_co2 = find(output(:,17) > 399.9999 & output(:,17) < 400.001);
                    bad_h2o = find(output(:,18) > 22.4999 & output(:,18) < 22.5001);
                    bad_CSAT = find(output(:,19)==-1.5646218e-6);
                    output(bad_CSAT,19:26)= NaN;
                    % Bad Fc data
                    output([1420 1862 2740:2840],1) = NaN;
                    % Bad P energy
                    output([1420 1862],7) = NaN;
                    % Bad CO2 irga (flatlines @ 400)
                    output(bad_co2,17) = NaN;
                    output([1595:1714 1856:1861 2727:2848 3131:4887 8897:9061 12299:12468],17) = NaN;
                    % Bad H2O irga (flatlines)
                    output(bad_h2o,18) = NaN;
                    output([1595:1714 1856:1861 2755:2841 3131:4887 8897:9061 12299:12468],18) = NaN;
                    % Bad Tirga (flatlines)
                    output([1595:1714 1856:1861],27) = NaN;
                    output(bad_h2o,27) = NaN;
                    % Bad Pirga (flatlines)
                    output([1595:1714 1856:1861],28) = NaN;
                    output(bad_h2o,28) = NaN;
                    
                case '2014'
                    % Spike in all
                    output(15492,:) = NaN;
                    % Fc - Penergy had some similar spikes, I'm not sure if these
                    % are issues or normal
                    output([2272 6936 1787 13077 15492],1) = NaN;
                    % H2O irga (flatlines)
                    output([2843:2943 5661 12630:12688 14826],18) = NaN;
                    
                case '2015'
                    % Hs
                    output([2036 17028],3) = NaN;
                    % Fc + Penergy spikes
                    output([703 1163 1247 17148 16475 17384:17385],[1 7]) = NaN;
                    % CO2 irga spikes
                    output([184 683 657 2972:2975 17384],17) = NaN;
                    % H20 irga spikes
                    output([10715:10718 10915:10916 11514:11515 12155:12158 16218:16219 17384],18) = NaN;
                    %  Bad T-s data
                    output([133:143 5107 6005 7661 7924:7925 8099 8539 8565:8570 10653:10659 10672:10676 11702 12216:12228 ...
                        16077:16079 16083:16113],22) = NaN;
                    % Bad T-irga
                    output([10715:10718 11514:11792 12154:12158],27) = NaN;
                    
                case '2016'
                    % Fc Spikes
                    output([831 2002 2849 3145 3835 4197 4207 4451 4684 5211 5596 5648 6896 7857 8048 11643 12166 12559 14053],1) = NaN;
                    %Ustar
                    output([397 2658 2846 3543 3566 4030 4680 4681 9124 9368 14113 14427  17028],2) = NaN;
                    %Hs Spikes
                    output([3542 4030 14116 14417 16913 16921:16924 16928:16929 17329],3) = NaN;
                    % LE-L Spikes
                    output([1669 1670 3397 3835 4678 6953 7809 7857 7918 8097 8962 9252 9971 10074 10746 12130 12325 12609],5) = NaN;
                    % Penergy
                    output([2849 5211 10665 10964 11643 11685 12166 12559 12600],7) = NaN;
                    % Tair Spikes
                    output([393 2657 14125],16) = NaN;
                    % CO2-irga Spikes
                    output([1499:1501 1964 1965 7378 10722 12590 12600 13835:13949 15431 16571:16695],17) = NaN;
                    % H2O-irga Spikes
                    output([1964 1965 12590 13835:13950 16571:16695],18) = NaN;
                    % u Spikes
                    output([2658:2674 2929:2979 3542 3543 4850:4859 5831:5841 5876 5877 14113:14116 14125 14417 14428 14432:14443 15532 16085 16914 16919 17452 17453],19) = NaN;
                    % T-s Spikes
                    output([393 2657:2674 2929:2979 2989 3335:3359 3523:3532 6409:6411 13228:13231 14125 14434:14443 17205 17451],22) = NaN;
                    % T-irga Spikes
                    output([11127 11129 13835:13949],27) = NaN;
                    
                case '2017'
                    % Fc Spikes
                    output([704 1494 1826:1829 2398 2433 2647 2650 2847:2849 2856 2860 2861 3125 3148 3161 3163 3282 3630:3639 3838 4133 4167 4184 4185 4489 4490 4518 4610 4802 4805 4832 4886 5097 5120 5216 5889 7761 8026 8209 9231 9944 10027 10525 10709 10866 11956 12210:12212 13551 13584 14404 16584 16889],1) = NaN;
                    % Ustar Spikes
                    output([874:876 906 907 3165 3166 3172 4117 4303 4311 4323 4518 4616 4805 5609 5946 5980:5995 6005 6940 15451 16022],2) = NaN;
                    % Hs Spikes
                    output([133 1818:1829 2062 3128:3171 4086 4320 4619 5797 5834 6023:6025 8334 8344 9288 9639 10212 13504:13509 14656 14814 14832 15314 15447:15468 16022 16887],3) = NaN;
                    % LE-L Spikes
                    output([2894 3221 3222 3297 3542 3925 3926 4690 5318 5365 5755 7284 7330 7617 7761 7854 8053 8097 8153 8394 8969 9011 9587 9639 10500 10543 10887 11121 11366 12226 12708],5) = NaN;
                    % Penergy Spikes
                    output([704 1828 2398 3148 3838 4133 4167 4802 4805 4886 5889 8026 9231 11956 12210 13551 14404 16889],7) = NaN;
                    % Tair Spikes
                    output([144 799 834 874:875 907 922 935:960 3162:3171 4108:4117 4303 5980:5991 6007 16888],16) = NaN;
                    % CO2-irga Spikes
                    output([443:618 1820:1825 1883:1907 2179 2522 3148 4824 5217:5315 7019:7186 7643:7674 8507:8531 8945:8950 9626 9941:9945 10820:10824 12210:12213 12398 12744],17) = NaN;
                    % H2O-irga Spikes
                    output([443:618 1883:1907 5204:5315 7019:7186 7643:7674 7855 8507:8531 9920 12211:12213 12398],18) = NaN;
                    
                    % U,V Spikes and Zero
                    output([133:154 552:559 799 815:822 832:866 929:996 1809 1835 2858 3128 3172 3716:3721 4087 4106:4117 4304 4311 4323:4340 4475:4479 4518 4615 5979:5989 6007:6018 6927:6933 8289 8401 8730 10696 14789 15454:15463 16737 16887:16889 17132:17137 17399:17403],[19:20]) = NaN;    
                    % W Spikes and Zero
                    output([133:154 552:559 799:803 815:822 832:866 877:881 906 922 929:996 1525 1766 1809 1834:1838 2583 2856:2858 3128 3169:3172 3538 3693:3704 3716:3721 4087:4089 4103:4117 4304 4311 4323:4340 4475:4479 4518 4615 4735:4740 5789:5797 5979:5989 6007:6018 6803 6927:6933 7809 8289 8401 8730 10500 10696 11775 11862 13504 13511 14275 14789 14802 15454:15463 16021 16260 16737 16887:16889 16905:16907 17132:17137],21) = NaN;    
                    
                    % T-s Spikes
                    output([137:156 552:559 799 814:819 836:866 874 907 935:937 939:941 946:996 1035 3165 3166 3171 4107 4110:4113 4154 4303:4305 4322:4339 4475:4479 5786 6008:6018 6927:6933 8338 13515 13516 15454:15461 16888],22) = NaN;
                    % T-irga Spikes
                    output([443:618 1883:1907 5217:5315 7019:7186 7643:7674 7838 7979 7980 8273 8507:8531 9176:9179 9920 9941:9964 9993 10146 10288:10295 10328:10344 10350:10353 10358:10362 10532:10534 10689:10691 10697 10709:10713 10932],27) = NaN;
                    % P-irga Spikes
                    output([9919:9922 13555 15462],28) = NaN;
                
                case '2018'
                    % Fc Spikes
                    output([1035 1683 2186 2187 2403 4216 5040 5046 5868 5928 8940 9804 ...
                        12359 12822 13408 13811 15000:15043 15338:15353],1) = NaN;
                    % LE-L Spikes
                    output([5462 10980 13614 15000 15041 15345],5) = NaN;
                    % P-Energy Spikes
                    output([1035 1683 2187 4479 5040 5868 8940 9804 10532 11007:11011 12176 ...
                        12177 12359 13408 13811 15000:15043 15338:15353],7) = NaN;
                    % CO2 and H2O irga Spikes
                    output([5036:5040 8110 8267:8377 8904 10966:10981 12110:12180 ...
                        12823:12843 13597:13615 15000:15043 15301:15355 17052:17314],[17 18 27]) = NaN;
                    % Bad Barometric Pressure
                    output(4552:end,15) = NaN;
                case '2019'
                    output([1678 2622:2623 7238 ],5) = NaN;
                    bad_co2 = find(output(:,17) > 399.9999 & output(:,17) < 400.001);
                    bad_h2o = find(output(:,18) > 22.4999 & output(:,18) < 22.5001);
                    output(bad_co2,[1 17]) = NaN;
                    output(bad_h2o,[5 18]) = NaN;
                    bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
                    output(bad_csat,[19:26]) = NaN;
                    
                case '2020' %done by AB
                    bad_co2 = find(output(:,17) > 399.9999 & output(:,17) < 400.001);
                    bad_h2o = find(output(:,18) > 22.4999 & output(:,18) < 22.5001);
                    output(bad_co2,[1 17]) = NaN;
                    output(bad_h2o,[5 18]) = NaN;
                    bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
                    output(bad_csat,[19:26]) = NaN;
                   % Fc Spikes
                    output([524 873 996 3820 4709 4712 8389 10303 12023 ...
                        13746 14667 15142 16989 17515:17527],1) = NaN; 
                   % Ustar Spikes
                    output([165 3978 4973 14256 14571 15353 15354 16070 17025],2) = NaN;
                   % Hs Spikes
                    output([525 2955 1255 5592 5778 7782 8558 11511 12311 13859 14258 14257 16067 16988:17040],3) = NaN;
                    % LE-L spikes
                    output([3813 4260 14666],5) = NaN;
                    
                    output([4475:4691 6778:7374 15142 15355:15356 16139:16412],[17 18 27 28]) = NaN;
                    output([545 2326 2955 4961 13064 15353:15356 15693:15705],19) = NaN;
                    output([450:547 8564:8570 3803 9248 9252 2971:3013 4961 13873 17000:17028 17219:17272],22) = NaN;
                    output([1097 9108],29) = NaN;
                    output(9108,30) = NaN;
                    
                case '2021' % EAR & LL
                    bad_co2 = find(output(:,17) > 399.9999 & output(:,17) < 400.001);
                    bad_h2o = find(output(:,18) > 22.4999 & output(:,18) < 22.5001);
                    output(bad_co2,[1 17]) = NaN;
                    output(bad_h2o,[5 18]) = NaN;
                    bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
                    output(bad_csat,[19:26]) = NaN;
                    % Fc Spikes
                    output([8219 16560],1) = NaN; 
                    % Ustar Spikes
                    output([64 14320 15790 16300 17210],2) = NaN;
                     % Hs Spikes
                    output([848 8465 14310 14320 15190 17210 17220],3) = NaN;
                      % LE-L spikes
                    output([4831],5) = NaN;
                    % Penergy spikes 
                    output([8219 10810 16560],7) = NaN;
                    % H2O-irga spikes
                    output([3812 11480:11650 14800:14870],18) = NaN;
                    % u spikes
                    output([4817 5931 7085 8464 8468 15190 15600 15790 16560 16890 17210 17430],19) = NaN;
                    % w spikes
                    output([82 844 5939 8219 8225 9058 10710 12700 13510 14300 16910 17210 17320],21) = NaN; 
                    % T-s spikes 
                    output([12250 12350 13240 13510 14300 14410:14430 14520 14530 14550:14570],22) = NaN; 
                    % P-irga spikes
                    output([3812 4768 11480:11660 12250 12350 14260 14800:14870],28) = NaN;
                    % u-rot spikes
                    output([7085 8468 14300 14510 15190 15600 15790 16300 16550 17210],31) = NaN;
                    % v-rot spikes
                    output([7085 14300 14510 17220],32) = NaN;
                    % w-rot spikes
                    output([720 818 835 849 7085 13520 14510 15190 15170 15600 15780 15790 16300 17210 17220 17430],33) = NaN;
                case '2022' % NH
                    bad_co2 = find(output(:,17) > 399.9999 & output(:,17) < 400.001);
                    bad_h2o = find(output(:,18) > 22.4999 & output(:,18) < 22.5001);
                    output(bad_co2,[1 17]) = NaN;
                    output(bad_h2o,[5 18]) = NaN;
                    bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
                    output(bad_csat,[19:26]) = NaN;
                    output([2547 3756 4402 5314 6446 6499 11842 13910 13915 15411 16743 16811 17034 17131 17455],1) = NaN; %Fc
                    output([2547 6499 13915 15475 17034 17131 17455],7) = NaN;%Penergy
                    output([9699 10926 13694:13717],18) = NaN;
                    output([55:62 1575 2545 3755 5185 13919],19) = NaN;%u
                    output([9527:9528 9532:9533 11470 13991:14193 17506:17508],22) = NaN;%Ts
                    output([53 54 1598 2299 3706:3756 4065:4070 13920 16740],23) = NaN;
                    output([53:60 399 1598 2299 3706 16736 16742],24) = NaN;
                    output([2505 5929 ],26) = NaN;
                 case '2023' % EAR and NS completed 2024-01-13
                    bad_co2 = find(output(:,17) > 399.9999 & output(:,17) < 400.001);
                    bad_h2o = find(output(:,18) > 22.4999 & output(:,18) < 22.5001);
                    output(bad_co2,[1 17]) = NaN;
                    output(bad_h2o,[5 18]) = NaN;
                    bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
                    output(bad_csat,[19:26]) = NaN;
                    output([45 190 2978  5024 5085 5088  5698 6313 6459 6981 8386 9814 10062 10625 10666 11401 11577 11980 12180 12326 12515 13275 14503 14988 15245 16153 16331 16474],1) = NaN; %Fc
                    output([608  2987 3638 4025 4031 9933 10060 10062 10994:10995 11339 11577 14049 14051 14061 14503 14988 15588 16150 17129:17131],2) = NaN;%Ustar
                    output([198 796 895 1203 8768 10724 10994:10995 14053 14988 15587 15598 16150 16841 16891:16892 17122:17129 17317],3) = NaN;%Hs
                    output([11578],16) = NaN;%Tair
                    output([328 2970:2984 5737 5856:5984 7221:7234 13770:13849],17) = NaN;%CO2irga
                    output([328 329 2978 5859:5984 13760:13849],18) = NaN;%H2Oirga
                 case '2024' % LK
                    bad_co2 = find(output(:,17) > 399.9999 & output(:,17) < 400.001);
                    bad_h2o = find(output(:,18) > 22.4999 & output(:,18) < 22.5001);
                    output(bad_co2,[1 17]) = NaN;
                    output(bad_h2o,[5 18]) = NaN;
                    bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
                    output(bad_csat,[19:26]) = NaN;                 
                    output([421 458 573:578 723 1189 1190 1759 2313 2314 2388 2586 2801 2796 2804:2814 3285:3292 3635 4127 4128 4360 5113 6109 6328:6330 7028 8219 10346 14045 14478 15969 17551],1) = NaN; %Fc
                    output([412 421 1515 4914 5482 5705 11685 14906 17493 17191 17193],2) = NaN;%Ustar
                    output([424:427 526 574 1189 1214 1530 5183 6990 8538 11685 17189 ],3) = NaN;%Hs
                    output([9486 12868 ],16) = NaN;%Tair
                    output([574:578 7028 7029 9872 16020:16064 17196 17217 17476:17482 17188:17551],17) = NaN;%CO2irga
                    output([579 15852 16064],18) = NaN;%H2Oirga
                    output([11508],27) = NaN;%Tirga

           end
    case 'TPAg'
        %% ********************** TPAg *********************************

        switch yr_str
        case '2020'
        bad_co2 = find(output(:,17) > 32.9995 & output(:,17) < 33.0005);
        bad_h2o = find(output(:,18) > 747.498 & output(:,18) < 747.502);
        output(bad_co2,[1 17]) = NaN;
        output(bad_h2o,[5 18]) = NaN;
        bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
        output(bad_csat,[19:26 38:39]) = NaN;
        bad_Tirga = find(output(:,27) > 4.9995 & output(:,27) < 5.0005);
        output(bad_Tirga,[27]) = NaN;
        
        % Try to clean out some spikes in Wind Speed and Direction
        bad_u_std = find(output(:,23) > 3);
        output(bad_u_std,[38:39]) = NaN;
        
        %manual cleaning below done by AB
        output([7156 1070 11590 12840 15330 15136:15147],1) = NaN; %Fc
        output([16083:16112 17512:17523 ],2) = NaN; %Ustar
        output([13060 12030 17230 17010 12025 17226 14264],3) = NaN; %Hs    
        output([12310 15140 15350 17040 17100 15139 11587 17039],5) = NaN; %LE-L  
        output([7181 9220 11550 13740 13860 14130 17400],7) = NaN; %Penergy
        output([7309],10) = NaN; %B-L
        
        output([11540:11543 15330:15350 17400:17434],15) = NaN; %Barometric P
        output([7257:7276 11389 11544:11552 16092:16094 12319:12321],16) = NaN; %Tair
        output([7124 9219 9237 9635 9643 10040 10100 10271:10300 10370 10400 10750 10980 11250 11567:11571 12692 12876:12890 13846:13877 13206 13256 13270 13352 13740 14665:14675 15002 15325:15366],17) = NaN; %CO2irga
        output([9251 9425 9499 9500 9488 9766:9771 10037:10038 11009:11015 11253:11255 11345:11353 11545:11546 12824:12841 12873:12893 9945:9957 10642:10643 10750 11568:11569 11672:11678 11939:11980 12351 13207:13208 13219:13225 13237:13246 13259:13266 13353:13369 13461:13469 15163:15147 15671:15677 17255:17256 15001:15003],18) = NaN; %H2Oirga  
       
        output([12311 15841 15848 16090:16110 17513 17522],19) = NaN; %U
        output([7146 7785 10286:10287 10291:10293 10296 10349:10350 11400:11401 11547 15842:15846 15862:15866 15872:15874 16998:17003],22) = NaN; %TS 
        output([13744 15367:15375 15848 16090:16112],20) = NaN; %V
        output([9240:9255 10040:10041 10289 11549:11552 12160:12176 13070 13074 13744 13876 14071 14136 15877 16072 16110 16995:16996 17039],21) = NaN; %W 
        output([13744 14672:14673 17039],31) = NaN; %U-rot
        output([9628 10299 13144 13478 13901 14264 15373 15374 15848 15869 16093],32) = NaN; %V-rot
        output([14675:14676 16093 16999:17000],33) = NaN; %W-rot
        
        output([9241:9249 10289:10296 12310:12314 13744 14672 15699 12173:12177 15841 15898 16071 16085:16110],38) = NaN; %WindSpeed
        output([7014 8220 8882 8939 9389:9390 9526 9757 10041 10138 10397 10520 11116 11485 14786 11393],39) = NaN; %Wind Direction (I did my best)
        
               %%%% Remove all data points before 8400 - these belong to TP_VDT
               output(1:8400,:) = NaN;
               
        case '2021' % EAR & LL
         bad_co2 = find(output(:,17) > 32.9995 & output(:,17) < 33.0005);
        bad_h2o = find(output(:,18) > 747.498 & output(:,18) < 747.502);
        output(bad_co2,[1 17]) = NaN;
        output(bad_h2o,[5 18]) = NaN;
        bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
        output(bad_csat,[19:26 38:39]) = NaN;
        bad_Tirga = find(output(:,27) > 4.9995 & output(:,27) < 5.0005);
        output(bad_Tirga,[27]) = NaN;
        
        % Hs spike 
         output([1693 9540 14280 17320],3) = NaN;
        % LE-L spike
        output([1228 3571 5747 14320 17320],5) = NaN;
        % u spike 
        output([1692 2524 2573 11580 12780 14270 14310 15170 16550],19) = NaN;
        % v spike 
        output([1693 11580 14270],20) = NaN;
        % w spike 
        output([1694 2576 4818 5928 9043 11590 12690 12780 15180 15190:15200 15260:15290],21) = NaN;
      
       case '2022' % NS
        output([2299 13923],3) = NaN;%Hs
        output([781 14842],5) = NaN;%LEL
        output([7026 7027 7029 7032:7038 7562:7564 7802 7803 8330:8341 9529 9530 9534:9537 11880:11883 12191:12192 12196:12197 15110:15127 15335:15337 17490:end],22) = NaN;
        
        case '2023' % NS
        output([37 40:42 45 74 95 241:252 287:291 541:605 776:804 814:833 841 882:954 1042:1058 1226 1249 1250 1257:1259 1262 1300:1309 1363:1382 1417:1425 1435 1589 1690 1718:1729 1808:1812 1883:1940 2074:2081 2137:2138 2169:2177 2232 2255 2261:2262 2275 2475 2532:2627 2667:2668 2775:2776 2839 3291:3319 3395 3399:3419 3439:3455 3600:3770 3799:3800 3891:3927 4002:4130 4215:4219 4296:4367 4695 4727:4756 5008 5055 5059 5083:5153 5154:5156 5242:5257 5351:5352 5370:5376 5447 5460:5462 5511:5555 5609 5677:5705 5718:5748 5785:5796 5812:5914 5952 5959 5973 5984 6002:6004 6037 6057 6084 6321 6348 6389 6454 6596:6601 6632:6639 6646 6682:6694 6725 6779:6791 6969:6996 7019 7070 7111 7267:7268 7634 7667 7778:7781 7805:7808 7866 7920 7959 7964 7996 8133:8135 8280 8292:8294 8317:8321 8342 8351:8357 8384 8399 8420 8479 8504 8779 8841:8856 8901 8974 9048 9273 9359 9401 9417 9810 9937:9942 10479 10630:10631 10738 10872 10881 11098 11215 11240:11247 11269 11312 11603:11604 11683:11685 11728 11752 11913 11916 11918 11928 11947 11961 11979 12016 12019 12030:12032 12084 12136 12161 12179 12200 12206 12216 12220 12234 12265 12306 12344 12350 12354 12388 12403 12437 12442 12446 12519 12560 12583 12588 12598:12601 12616 12629 12651 12728 12866:12885 13011 13013 13031 13034:13035 13057 13072:13083 13106:13124 13161 13172:13175 13213 13217 13220 13252 13258 13298:13299 13345:13367 13408 13442:13443 13460:13474 13521 13576:13595 13617 13629:13630 13643 13653 13656 13683 13721:13722 13760:13761 13771 13852:13856 13948:13950 14016:14055 14061 14092 14114 14147 14171:14175 14185:14186 14221 14270 14298 14310:14333 14383 14418:14421 14462:14481 14499:14524 14532 14589 14594:14595 14648 14663:14672 14748 14762:14763 14784:14790 14845 14962:14977 14991 15123 15127 15130:15131 15174:15179 15183 15271 15274 12679:12694 15802:15808 15817 15820 15832:15852 15847:15848 16056:16124 16337:16343 16377:16378 16440 16463:16482 16513 16779:16780 16865:16900 17003 17105:17140 17255:17260 17288:17299 17427:17443 17504:end],[1 17:18]) = NaN;%Fc
        output(output(:,29)>10,[1,17]) = NaN; % Let's see what happens when we remove all data points with CO2_std > 10
        output(output(:,30)>1,[5,18]) = NaN; % Let's see what happens when we remove all data points with H2O_std > 1
        
        output([570],3) = NaN;%Hs
        output([918:921],16) = NaN;%Tair
        output([7800 8766:8813 10059:10060 10632 11964:11978],22) = NaN;%Ts
        
         case '2024' %LK
         output([17569:end],1) = NaN;
         output([17569:end],2) = NaN;
         output([17569:end],3) = NaN;
         output([1:end],4) = NaN;
         output([17569:end],5) = NaN;
         output([1:end],6) = NaN;
         output([17569:end],7) = NaN;
         output([17569:end],8) = NaN;
         output([1:end],9) = NaN;
         output([17569:end],10) = NaN;
         output([1:end],11) = NaN;
         output([17569:end],12) = NaN;
         output([17569:end],13) = NaN;
         output([17569:end],14) = NaN;
         output([17569:end],15) = NaN;
         output([11685:11687 14901 14902 5204 5205 4922 4926 4933:4935 6156 6157],16) = NaN;
         output([858 2552:2563 2566 2567 2713 4521 5204 5205 6690 12741 13555:13558 13648:13650 13704 13705 13931 13938 14019 14024 14068 14069 14072 14077 14182:14184 14509 14706 14708],17) = NaN;
         output([462 470 576 596 1105 1221 1223 1281 1311:1322 1335:1344 2202 2569 2720 2802 2963 3289:3302 3572 4881 4925 5163 5737 6345 7063:7091 7550:7558 8658:8679 9187 9190 9488:9492 10306:10313 11684:11688 10329:10336 13030 13035 13743:13801 14900:14906 15110:15115 16286 16509 16515 16811 16814 17200 17462 17464 17494 17497 10501 10507:10509 17191 17192 4888 48981 4896 4903 4908 4936 23 24 25 9:18 ],21) = NaN;
         output([432:433 511 576:578 1103:1211 1226:1281 2796:2798 3289:3307 4899:4908 5200:5203 5735:5741 5735 6624:6650 7379:7401 7418:7424 7521 7548:7563 7695:7705 8224 8232 8663:8675 9183:9197 9230:9239 9437:9443 10150:10167 10305:10310 10985:11005 10346:10350 10352:10354 11675:11692 11983:11985 11997 12786:12794 12795:12797 12798 12799 13032:13034 13050:13053 13056 13211:13219 14901 14904:14910 15110:15112 15121 15122 16287 16500:16502 16512:16514 16565:16585 17189:17192 17466:17477],22) = NaN;  
         output([11506:11566],27) = NaN;
         
        end
        case 'TP_VDT'
        %% ********************** TP_VDT *********************************

        switch yr_str
            
            case '2019'
        bad_co2 = find(output(:,17) > 32.9995 & output(:,17) < 33.0005);
        bad_h2o = find(output(:,18) > 747.498 & output(:,18) < 747.502);
        output(bad_co2,[1 17]) = NaN;
        output(bad_h2o,[5 18]) = NaN;
        bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
        output(bad_csat,[19:26 38:39]) = NaN;
        bad_Tirga = find(output(:,27) > 4.9995 & output(:,27) < 5.0005);
        output(bad_Tirga,[27]) = NaN;
        
        % Try to clean out some spikes in Wind Speed and Direction
        bad_u_std = find(output(:,23) > 3);
        output(bad_u_std,[38:39]) = NaN;
        
        output(7876:7877,1) = NaN;
        output([1078:1154 2059:2088 2458 3514 6358:6359],2) = NaN;
        output([1678 1827 2619 3508 3518 4996 6309 7875 13850:13852],3) = NaN;
        output([3514 6076:6081 6342 7845 7878],19) = NaN;
        
            case '2020'
        bad_co2 = find(output(:,17) > 32.9995 & output(:,17) < 33.0005);
        bad_h2o = find(output(:,18) > 747.498 & output(:,18) < 747.502);
        output(bad_co2,[1 17]) = NaN;
        output(bad_h2o,[5 18]) = NaN;
        bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
        output(bad_csat,[19:26 38:39]) = NaN;
        bad_Tirga = find(output(:,27) > 4.9995 & output(:,27) < 5.0005);
        output(bad_Tirga,[27]) = NaN;
        
        % Try to clean out some spikes in Wind Speed and Direction
        bad_u_std = find(output(:,23) > 3);
        output(bad_u_std,[38:39]) = NaN;
        
        %manual cleaning below done by AB
        output([7156 1070 11590 12840 15330 15136:15147],1) = NaN; %Fc
        output([16083:16112 17512:17523 ],2) = NaN; %Ustar
        output([13060 12030 17230 17010 12025 17226 14264],3) = NaN; %Hs    
        output([12310 15140 15350 17040 17100 15139 11587 17039],5) = NaN; %LE-L  
        output([7181 9220 11550 13740 13860 14130 17400],7) = NaN; %Penergy
        output([7309],10) = NaN; %B-L
        
        output([11540:11543 15330:15350 17400:17434],15) = NaN; %Barometric P
        output([7257:7276 11389 11544:11552 16092:16094 12319:12321],16) = NaN; %Tair
        output([7124 9219 9237 9635 9643 10040 10100 10271:10300 10370 10400 10750 10980 11250 11567:11571 12692 12876:12890 13846:13877 13206 13256 13270 13352 13740 14665:14675 15002 15325:15366],17) = NaN; %CO2irga
        output([9251 9425 9499 9500 9488 9766:9771 10037:10038 11009:11015 11253:11255 11345:11353 11545:11546 12824:12841 12873:12893 9945:9957 10642:10643 10750 11568:11569 11672:11678 11939:11980 12351 13207:13208 13219:13225 13237:13246 13259:13266 13353:13369 13461:13469 15163:15147 15671:15677 17255:17256 15001:15003],18) = NaN; %H2Oirga  
       
        output([12311 15841 15848 16090:16110 17513 17522],19) = NaN; %U
        output([7146 7785 10286:10287 10291:10293 10296 10349:10350 11400:11401 11547 15842:15846 15862:15866 15872:15874 16998:17003],22) = NaN; %TS 
        output([13744 15367:15375 15848 16090:16112],20) = NaN; %V
        output([9240:9255 10040:10041 10289 11549:11552 12160:12176 13070 13074 13744 13876 14071 14136 15877 16072 16110 16995:16996 17039],21) = NaN; %W 
        output([13744 14672:14673 17039],31) = NaN; %U-rot
        output([9628 10299 13144 13478 13901 14264 15373 15374 15848 15869 16093],32) = NaN; %V-rot
        output([14675:14676 16093 16999:17000],33) = NaN; %W-rot
        
        output([9241:9249 10289:10296 12310:12314 13744 14672 15699 12173:12177 15841 15898 16071 16085:16110],38) = NaN; %WindSpeed
        output([7014 8220 8882 8939 9389:9390 9526 9757 10041 10138 10397 10520 11116 11485 14786 11393],39) = NaN; %Wind Direction (I did my best)
        
               %%%% Remove all data points before 8400 - these belong to TPAg
               output(8400:end,:) = NaN;
        end
    end
        
    %% Plot corrected/non-corrected data to make sure it looks right:
    
    f4 = figure(4); set(f4,'WindowStyle','docked'); 
    j = 1;
    while j <= num_vars
        figure(4);clf;
        plot(input_data(:,j),'r'); hold on;
        plot(output(:,j),'b');
        grid on;
        title([strrep(var_names(j,:),'_','-') ', column no: ' num2str(j)]);
        legend('Data Removed', 'Data Kept');
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
            j = num_vars+1;
        elseif strcmp(response,'1')==1 && j > 1;
            j = j-1;
        else
            j = 1;
        end
    end
    clear j response accept
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Compare with met data to shift data appropriately to UTC if necessary:
    
    % %%% Set overrides for shifts here, or remove data points, or make shifts:
    switch site
        case 'TP74'
            shift_override = [];
        case 'TP89'
            shift_override = [];
        case 'TP02'
            shift_override = [];
    end
    
    %%% Load the met wind speed data (to be used for comparison):
    try
    met = load([met_path site '_met_cleaned_' yr_str '.mat']);
    MET_DAT = met.master.data(:,mcm_find_right_col(met.master.labels,'WindSpd'));
    u = output(:,mcm_find_right_col(var_names,'u')); v = output(:,mcm_find_right_col(var_names,'v'));
    CPEC_DAT = sqrt(u.^2 + v.^2); clear u v;
    u_orig = input_data(:,mcm_find_right_col(var_names,'u')); v_orig = input_data(:,mcm_find_right_col(var_names,'v'));
    CPEC_ORIG = sqrt(u_orig.^2 + v_orig.^2); clear u_orig v_orig;
    
    num_lags = 16;
    win_size = 500; % one-sided window size
    increment = 100;
    
    [pts_to_shift] = mov_window_xcorr(MET_DAT, CPEC_DAT, num_lags,win_size,increment);
    
    %%% Plot the unshifted timeseries, along with Met data
    close(findobj('Tag','Pre-Shift'));
    figure('Name','Data_Alignment: Pre-Shift','Tag','Pre-Shift');
    figure(findobj('Tag','Pre-Shift'));clf;
    plot(MET_DAT,'b');hold on;
    plot(CPEC_ORIG,'Color',[0.8 0.8 0.8]);
    plot(CPEC_DAT,'Color',[1 0 0]);
    % plot(shifted_master(:,find_right_col(master.labels,'u_mean_ms-1')),'g');
    legend('Met WSpd', 'Orig CPEC WSpd', 'Corrected CPEC WSpd');%, 'Orig EdiRe WSpd',  'Corrected EdiRe WSpd');
    grid on;
    set(gca, 'XMinorGrid','on');
    
    disp('Investigate Data Alignment through attached figure ');
    disp(' and by looking at output of this function.  Fix if needed.');
    catch
        disp('Data alignment check failed -- likely because met data hasn''t run through final cleaning');
    end
    
    %% Output
    % Here is the problem with outputting the data:  Right now, all data in
    % /Final_Cleaned/ is saved with the extensions corresponding to the
    % CCP_output program.  Alternatively, I think I am going to leave the output
    % extensions the same as they are in /Organized2 and /Cleaned3, and then
    % re-write the CCP_output script to work on 2008-> data in a different
    % manner.
    
    
    continue_flag = 0;
    while continue_flag == 0
        commandwindow;
        if auto_flag == 1
            resp2 = 'y';
        else
            resp2 = input('Are you ready to print this data to /Final_Cleaned? <y/n> ','s');
        end
        if strcmpi(resp2,'n')==1
            continue_flag = 1;
            
        elseif strcmpi(resp2,'y')==1
            continue_flag = 1;
            for i = 1:1:num_vars
                temp_var = output(:,i);
                save([output_path site '_' yr_str '.' char(header{i,2})], 'temp_var','-ASCII');
            end
            master(1).data = output;
            master(1).labels = var_names;
            save([output_path site '_CPEC_cleaned_' yr_str '.mat' ], 'master');
            
        else
            continue_flag = 0;
            
        end
    end
    switch skipall_flag
        case 0
            commandwindow;
            junk = input('Press Enter to Continue to Next Year');
        otherwise
    end
end
if auto_flag~=1 && ispc==0
    mcm_start_mgmt;
end
end
%subfunction
% Returns the appropriate column for a specified variable name
function [right_col] = quick_find_col(names30_in, var_name_in)

right_col = find(strncmpi(names30_in,var_name_in,length(var_name_in))==1);
end