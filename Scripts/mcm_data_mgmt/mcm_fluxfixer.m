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
                case '2025' % NS
                   bad_co2 = find((output(:,17) > 449.9999 & output(:,17) < 450.0001) | (output(:,17) > 399.9999 & output(:,17) < 400.0001));
                   output(bad_co2,[1 17]) = NaN; % remove for Fc and CO2 concentration   
                   output([854 1492 665	1568	1789	1887	1902	2000	2728	2731	3184	3251	3261	3270	3347	3443	3555	3589	3759	3774	3784	3830	3868	3916],1) = NaN; %Fc
                   output([24	850	1491	1492	2235	2240	2249	2626	3587	3774	3877],2)=NaN; 
                   output([17	18	850	1486	1488	2233	2240	3585	3770	3771	3952	3956],3)=NaN;
                   output([39	140	594	613	1629	1652	1667	1790	1904	2001	2294	2340	2443	2630	2717	2728	2731	2960	2964	3251	3443	3537	3584	3640	3747	3749	3759	3776	3832],5)=NaN;
                   output([24	73	133	280	468	512	665	710	807	854	1088	1108	1145	1190	1370	1490	1492	1568	1789	1790	1887	1902	1963	2000	2025	2043	2045	2051	2480	2508	2704	2728	2731	2867	2960	2967	3011	3172	3184	3229	3230	3251	3261	3270	3346	3347	3389	3442	3443	3457	3544	3555	3589	3606	3731	3759	3784	3805	3830	3868],7)=NaN;
                   output([1477	1478	1479	1481	1482	1483	1484],16)=NaN;
                   output([1477	1478	1479	1480	1481	1482	1483	1484	1485	1486	1487	1488	1489	1490	1491	2507	2508],17)=NaN;
                   output([2142],19)=NaN;
                   output([1484	2066	2067	2068	2069	2070],22)=NaN;
                   output([16	18	845	848	850	851	854	1492	1612	1651	2142	2244	2245	2246	3087	3088	3089	3100	3585	3587	3769	3770	3773	3774	3947	3952],23)=NaN;
                   output([16	18	1491	1492	1612	2232	2244	2245	2246	2859	3587	3873	3947],24)=NaN;
                   output([16	24	845	848	851	854	1492	2232	2244	2245	2246	3087	3088	3089	3769	3773	3774	3877	3952],25)=NaN;
                   output([16	18	843	845	848	851	1312	1486	1611	1612	1629	1651	2232	2244	2245	2246	3056	3087	3088	3089	3309	3313	3456	3585	3769	3770	3773	3774	3947	3952],26)=NaN;
                   output([781	782	783	784	785	786	787	788	789	790	791	792	793	794	795	796	797	798	799	800	1535	1536	1537	1538	1539	2415	2416	2417	2418	2419	2420	2421	2422	2423	2424	2425	2426	2427	2428	2429	2430	2431	2432	2433	2434	2435	2436	2437	2438	2439	2440	2441	2509	2510	2511	2512	2513	2514	2515	2516	2517	2518	2519	2520	2521	2522	2523	2524	2525	2526	2527	2528	2529	2530	2531	2532	2533	2534	2535	2536	2537	2538	2539	2540	2541	2542	2543	2544	2545	2546	2547	2548	2549	2550	2551	2552	2553	2554	2555	2556	2557	2558	2559	2560	2561	2562	2563	2564	2565	2566	2567	2568	2569	2570	2571	2572	2573	2574	2575	2576	2577	2578	2579	2580	2581	2582	2583	2584	2585	2586	2587	2588	2589	2590	2591	2592	2593	2594	2595	2596	2597	2598	2599	2600	2601	2602	2603	2604	2605	2606	2607	2608	2609	2610	2611	2612	2613	2614	2615	2616	2617	2618	2619	2620	2621	2622],28)=NaN;
                   output([23	280	452	710	735	755	829	854	1037	1173	1312	1481	1486	1545	1551	1634	1747	1789	1902	2087	2238	2461	2626	2731	3099	3184	3458	3459	3589	3661	3752],29)=NaN;
                   output([594	755	837	838	878	1312	1455	1457	1629	1789	2731	2849	3039	3075	3184	3354	3355	3443	3500	3531	3587	3640	3695	3756	3759	3774	3869	3870],30)=NaN;
                   output([848	2231	2232	2859	3087	3089	3587	3773	3952],31)=NaN;
                   output([33	66	85	88	584	814	815	822	947	1063	1370	1375	1379	1380	1384	1385	1794	1797	2232	2235	2268	2274	2278	2288	2336	2341	2625	2631	2849	2853	2859	3099	3211	3549	3551	3585	3681	3722	3728	3769],32)=NaN;
                   output([17	18	22	594	814	837	845	1087	1650	1773	1784	2142	2143	2144	2233	2236	2628	2968	3087	3089	3274	3302	3769	3780	3828	3847	3963	3969],33)=NaN;
                   output([18	845	848	850	854	1612	1649	1651	2142	2232	2233	2249	3087	3088	3089	3100	3585	3587	3769	3770	3773	3774	3947	3952],34)=NaN;
                   output([18	28	1491	1492	1612	2232	2249	2859	3587	3947],35)=NaN;
                   output([18	24	845	848	854	1492	1612	2232	2249	3087	3088	3089	3769	3773	3774	3877	3952],36)=NaN;
                   
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
                 case '2025' 
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
                    
                    output([2242],2)=NaN;
                    output([1785	1786	1787	3537	3952	3953	3955	4573	4574	4795	4796	4797	4798],13)=NaN;
                    output([1037	1078	1355	1370	1441	1478	1481	1482	1486	1680	1738	1746	1747	1866	1868	1902	1963	1999	2043	2629	2718	3184	3448	3759	3899	3931	4115	4159	4163	4199	4209	4212	4251	4254	4303	5364	5478	5530	5535	5653],7)=NaN;
                    output([1666:2683],17)=NaN;
                    output([2128	4416	4417	4418],19)=NaN;
                    output([34	2128	3074	4416	4440	4801],20)=NaN;
                    output([2070	4420	4422	4423],22)=NaN;
                    output([1545:1685],27)=NaN;
                    output([1545:1685],28)=NaN;
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
                    output([15213 1:378], 17) = NaN;%CO2 irga
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
                    output([8727 11759:12038], 17) = NaN;
                    output([11759:12038], 18) = NaN;
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
                 case '2025' % 
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
               
                    output([1143 2678],1)=NaN;
                    output([1143	2678	7206	8448	8791	9225	9952	9953	9962	10624	11829	14848],7)=NaN;
                    output([2680],17)=NaN;
                    output([2094 2679],18)=NaN;
                    output([2073	2074	2075	2076	2077	2078	2079	2080	2081	2082	2083	2084	2085	2086	2087	2088	2089	2090	2091	2092	2093	2094	2095	2096	2097	2098	2099	2100	2101	2102	2103	2104	2105	2106	2107	2108	2109	2110	2111	2112	2113	2114	2115	2116	2117	2118	2119	2120	2121	2122	2123	2124	2125	2752	2753	2754	2755	2756	2757	2758	2759	2761	2763	2764	3045	3046	3047	3048	3049	3050	3051	3052	3053	3054	3055	3056	3057	3058	3059	3060	4176	4178	4179	4180	4181	4182	4183	4184	4185	4186	4240	4245	4247	4248	4250	4254	4255	4256	4257	4258	4259	4260	4261	4262	4266	4404	4405	4406	4407	4411	4412	4413	4420	4421	4422	4425	4428	4773	4774	4775	4816	4817	4818	4819	4820	4821	4822	4823	4824	4825	4826	4827	4828	4829	6754	6755	6756	6757	6758	6759	6760	6761	6762	6763	6764	6765	6766	6767	6768	6769	6770	6771	6772	6773	6774	6776	6777	6778	6779	6780	6781	6782	6784	6785	6786	6787	6788	6789	6791	6792	6793	6795	6797	6798	6799	6800	6801	6802	6803	6804	6805	6806	6807	6808	6809	6810	6811	6812	6813	6814	6815	6816	6817	6818	7128	7129	7130	7131	7132	7133	7934	7935	7936	7937	7938	7939	7940	7941	7942	7943	7944	7945	7946	7947	7948	7949	7950	7951	7952	7953	7954	7955	7956	7957	7958	7959	7960	7961	7962	7963	7964	7965	7966	7967	7968	7969	7970	7971	7972	7973	7974	7975	7976	7977	7978	7979	7980	7981	7982	7983	7984	7985	7986	7987	7988	7989	7990	7991	7992	7993	7994	7995	7996	7997	7998	7999	8000	8001	8002	8003	8004	8005	8006	8007	8008	8009	8010	8011	8012	8013	8014	8015	8016	8017	8018	8019	8020	8021	8022	8023	8024	8025	8026	8027	8028	8029	8030	8031	8032	8033	8034	8035	8036	8037	8038	8039	8040	8041	8042	8043	8044	8045	8046	8047	8048	8049	8050	8051	8052	8053	8054	8055	8056	8057	8058	8059	8060	8061	8062	8063	8064	8065	8066	8067	8068	8069	8070	11902	11903	11904	11905	11906	11907	11908	11909	11910	11911	11912	11913	11914	11915	11916	11917	11918	11919	11920	11921	11922	11923	11924	11925	11926	11927	11928	11929	11930	11931	11932	11933	11934	11935	11936	11937	11938	11939	11940	11941	11942	11943	11944	11945	11946	11947	11948	11949	11950	11951	11952	11953	11954	11955	11956	11957	11958	11959	11960	11961	11962	11963	11964	11965	11966	11967	11968	11969	11970	11971	11972	11973	11974	11975	11976	11977	11978	11979	11980	11981	11982	11983	11984	11985	11986	11987	11988	11989	11990	11991	11992	11993	11994	11995	11996	11997	11998	11999	12000	12001	12002	12003	12004	12005	12006	12007	12008	12009	12010	12011	12012	12013	12014	12015	12016	12017	12018	12019	12020	12021	12022	12023	12024	12025	12026	12027	12028	12029	12030	12031	12032	12033	12034	12035	12036	12037	12038	12039	12040	12041	12042	12043	12044	12045	12046	12047	12048	12049	12050	12051	12052	12053	12054	12055	12056	12057	12058	12059	12060	12061	12062	12063	12064	12065	12066	12067	12068	12069	12070	12071	12072	12073	12074	12075	12076	12077	12078	12079	12080	12081	12082	12083	12084	12085	12086	12087	12088	12089	12090	12091	12092	12093	12094	12095	12096	12097	12098	12099	12100	12101	12102	12103	12104	12105	12106	12107	12108	12109	12110	12111	12112	12113	12114	12115	12116	12117	12118	12119	12120	12121	12122	12123	12124	12125	12126	12127	12128	12129	12130	12131	12132	12133	12134	12135	12136	12137	12138	12139	12140	12141	12142	12143	12144	12145	12146	12147	12148	12149	12150	12151	12152	12153	12154	12155	12156	12157	12158	12159	12160	12161	12162	12163	12164	12165	12166	12167	12168	12169	12170	12171	12172	12173	12174	12175	12176	12177	12178	12179	12180	12181	12182	12183	12184	12185	12186	12187	12188	12189	12190	12191	12192	12193	12194	12195	12196	12197	12198	12199	12200	12201	12202	12203	12204	12205	12206	12207	12208	12209	12210	12211	12212	12213	12214	12215	12216	12217	12218	12219	12220	12221	12222	12223	12224	12225	12226	12227	12228	12229	12230	12231	12232	12233	12234	12235	12236	12237	12238	12239	12240	12241	12242	12243	12244	12245	12246	12247	12248	12249	12250	12251	12252	12253	12254	12255	12256	12257	12258	12259	12260	12261	12262	12263	12264	12265	12266	12267	12268	12269	12270	12271	12272	12273	12274	12275	12276	12277	12278	12279	12280	12281	12282	12283	12284	12285	12286	12287	12288	12289	12290	12291	12292	12293	12294	12295	12296	12297	12298	12299	12300	12301	12302	12303	12304	12305	12306	12307	12308	12309	12310	12311	12312	12313	12314	12315	12316	12317	12318	12319	12320	12321	12322	12323	12324	12325	12326	12327	12328	12329	12330	12331	12332	12333	12334	12335	12336	12337	12338	12339	12340	12341	12342	12343	12344	12345	12346	12347	12348	12349	12350	12351	12352	12353	12354	12355	12356	12357	12358	12359	12360	12361	12362	12363	12364	12365	12366	12367	12368	12369	12370	12371	12372	12373	12374	12375	12376	12377	12378	12379	12380	12381	12382	12383	12384	12385	12386	12387	12388	12389	12390	12391	12392	12393	12394	12395	12396	12397	12398	12399	12400	12401	12402	12403	12404	12405	12406	12407	12408	12409	12410	12411	12412	12413	12414	12415	12416	12417	12418	12419	12420	12421	12422	12423	12424	12425	12426	12427	12428	12429	12430	12431	12432	12433	12434	12435	12436	12437	12438	12439	12440	12441	12442	12443	12444	12445	12446	12447	12448	12449	12450	12451	12452	12453	12454	12455	12456	12457	12458	12459	12460	12461	12462	12463	12464	12465	12466	12467	12468	12469	12470	12471	12472	12473	12474	12475	12476	12477	12478	12479	12480	12481	12482	12483	12484	12485	12486	12487	12488	12489	12490	12491	12492	12493	12494	12495	12496	12497	12498	12499	12500	12501	12502	12503	12504	12505	12506	12507	12508	12509	12510	12511	12512	12513	12514	12515	12516	12517	12518	12519	12520	12521	12522	12523	12524	12525	12526	12527	12528	12529	12530	12531	12532	12533	12534	12535	12536	12537	12538	12539	12540	12541	12542	12543	12544	12545	12546	12547	12548	12549	12550	12551	12552	12553	12554	12555	12556	12557	12558	12559	12560	12561	12562	12563	12564	12565	12566	12567	12568	12569	12570	12571	12572	12573	12574	12575	12576	12577	12578	12579	12580	12581	12582	12583	12584	12585	12586	12587	12588	12589	12590	12591	12592	12593	12594	12595	12596	12597	12598	12599	12600	12601	12602	12603	12604	12605	12606	12607	12608	12609	12610	12611	12612	12613	12614	12615	12616	12617	12618	12619	12620	12621	12622	12623	12624	12625	12626	12627	12628	12629	12630	12631	12632	12633	12634	12635	12636	12637	12638	12639	12640	12641	12642	12643	12644	12645	12646	12647	12648	12649	12650	12651	12652	12653	12654	12655	12656	12657	12658	12659	12660	12661	12662	12663	12664	12665	12666	12667	12668	12669	12670	12671	12672	12673	12674	12675	12676	12677	12678	12679	12680	12681	12682	12683	12684	12685	12686	12687	12688	12689	12690	12691	12692	12693	12694	12695	12696	12697	12698	12699	12700	12701	12702	12703	12704	12705	12706	12707	12708	12709	12710	12711	12712	12713	12714	12715	12716	12717	12718	12719	12720	12721	12722	12723	12724	12725	12726	12727	12728	12729	12730	12731	12732	12733	12734	12735	12736	12737	12738	12739	12740	12741	12742	12743	12744	12745	12746	12747	12748	12749	12750	12751	12752	12753	12754	12755	12756	12757	12758	12759	12760	12761	12762	12763	12764	12765	12766	12767	12768	12769	12770	12771	12772	12773	12774	12775	12776	12777	12778	12779	12780	12781	12782	12783	12784	12785	12786	12787	12788	12789	12790	12791	12792	12793	12794	12795	12796	12797	12798	12799	12800	12801	12802	12803	12804	12805	12806	12807	12808	12809	12810	12811	12812	12813	12814	12815	12816	12817	12818	12819	12820	12821	12822	12823	12824	12825	12826	12827	12828	12829	12830	12831	12832	12833	12834	12835	12836	12837	12838	12839	12840	12841	12842	12843	12844	12845	12846	12847	12848	12849	12850	12851	12852	12853	12854	12855	12856	12857	12858	12859	12860	12861	12862	12863	12864	12865	12866	12867	12868	12869	12870	12871	12872	12873	12874	12875	12876	12877	12878	12879	12880	12881	12882	12883	12884	12885	12886	12887	12888	12889	12890	12891	12892	12893	12894	12895	12896	12897	12898	12899	12900	12901	12902	12903	12904	12905	12906	12907	12908	12909	12910	12911	12912	12913	12914	12915	12916	12917	12918	12919	12920	12921	12922	12923	12924	12925	12926	12927	12928	12929	12930	12931	12932	12933	12934	12935	12936	12937	12938	12939	12940	12941	12942	12943	12944	12945	12946	12947	12948	12949	12950	12951	12952	12953	12954	12955	12956	12957	12958	12959	12960	12961	12962	12963	12964	12965	12966	12967	12968	12969	12970	12971	12972	12973	12974	12975	12976	12977	12978	12979	12980	12981	12982	12983	12984	12985	12986	12987	12988	12989	12990	12991	12992	12993	12994	12995	12996	12997	12998	12999	13000	13001	13002	13003	13004	13005	13006	13007	13008	13009	13010	13011	13012	13013	13014	13015	13016	13017	13018	13019	13020	13021	13022	13023	13024	13025	13026	13027	13028	13029	13030	13031	13032	13033	13034	13035	13036	13037	13038	13039	13040	13041	13042	13043	13044	13045	13046	13047	13048	13049	13050	13051	13052	13053	13054	13055	13056	13057	13058	13059	13060	13061	13062	13063	13064	13065	13066	13067	13068	13069	13070	13071	13072	13073	13074	13075	13076	13077	13078	13079	13080	13081	13082	13083	13084	13085	13086	13087	13088	13089	13090	13091	13092	13093	13094	13095	13096	13097	13098	13099	13100	13101	13102	13103	13104	13105	13106	13107	13108	13109	13110	13111	13112	13113	13114	13115	13116	13117	13118	13119	13120	13121	13122	13123	13124	13125	13126	13127	13128	13129	13130	13131	13132	13133	13134	13135	13136	13137	13138	13139	13140	13141	13142	13143	13144	13145	13146	13147	13148	13149	13150	13151	13152	13153	13154	13155	13156	13157	13158	13159	13160	13161	13162	13163	13164	13165	13166	13167	13168	13169	13170	13171	13172	13173	13174	13175	13176	13177	13178	13179	13180	13181	13182	13183	13184	13185	13186	13187	13188	13189	13190	13191	13192	13193	13194	13195	13196	13197	13198	13199	13200	13201	13202	13203	13204	13205	13206	13207	13208	13209	13210	13211	13212	13213	13214	13215	13216	13217	13218	13219	13220	13221	13222	13223	13224	13225	13226	13227	13228	13229	13230	13231	13232	13233	13234	13235	13236	13237	13238	13239	13240	13241	13242	13243	13244	13245	13246	13247	13248	13249	13250	13251	13252	13253	13254	13255	13256	13257	13258	13259	13260	13261	13262	13263	13264	13265	13266	13267	13268	13269	13270	13271	13272	13273	13274	13275	13276	13277	13278	13279	13280	13281	13282	13283	13284	13285	13286	13287	13288	13289	13290	13291	13292	13293	13294	13295	13296	13297	13298	13299	13300	13301	13302	13303	13304	13305	13306	13307	13308	13309	13310	13311	13312	13313	13314	13315	13316	13317	13318	13319	13320	13321	13322	13323	13324	13325	13326	13327	13328	13329	13330	13331	13332	13333	13334	13335	13336	13337	13338	13339	13340	13341	13342	13343	13344	13345	13346	13347	13348	13349	13350	13351	13352	13353	13354	13355	13356	13357	13358	13359	13360	13361	13362	13363	13364	13365	13366	13367	13368	13369	13370	13371	13372	13373	13374	13375	13376	13377	13378	13379	13380	13381	13382	13383	13384	13385	13386	13387	13388	13389	13390	13391	13392	13393	13394	13395	13396	13397	13398	13399	13400	13401	13402	13403	13404	13405	13406	13407	13408	13409	13410	13411	13412	13413	13414	13415	13416	13417	13418	13419	13420	13421	13422	13423	13424	13425	13426	13427	13428	13429	13430	13431	13432	13433	13434	13435	13436	13437	13438	13439	13440	13441	13442	13443	13444	13445	13446	13447	13448	13449	13450	13451	13452	13453	13454	13455	13456	13457	13458	13459	13460	13461	13462	13463	13464	13465	13466	13467	13468	13469	13470	13471	13472	13473	13474	13475	13476	13477	13478	13479	13480	13481	13482	13483	13484	13485	13486	13487	13488	13489	13490	13491	13492	13493	13494	13495	13496	13497	13498	13499	13500	13501	13502	13503	13504	13505	13506	13507	13508	13509	13510	13511	13512	13513	13514	13515	13516	13517	13518	13519	13520	13521	13522	13523	13524	13525	13526	13527	13528	13529	13530	13531	13532	13533	13534	13535	13536	13537	13538	13539	13540	13541	13542	13543	13544	13545	13546	13547	13548	13549	13550	13551	13552	13553	13554	13555	13556	13557	13558	13559	13560	13561	13562	13563	13564	13565	13566	13567	13568	13569	13570	13571	13572	13573	13574	13575	13576	13577	13578	13579	13580	13581	13582	13583	13584	13585	13586	13587	13588	13589	13590	13591	13592	13593	13594	13595	13596	13597	13598	13599	13600	13601	13602	13603	13604	13605	13606	13607	13608	13609	13610	13611	13612	13613	13614	13615	13616	13617	13618	13619	13620	13621	13622	13623	13624	13625	13626	13627	13628	13629	13630	13631	13632	13633	13634	13635	13636	13637	13638	13639	13640	13641	13642	13643	13644	13645	13646	13647	13648	13649	13650	13651	13652	13653	13654	13655	13656	13657	13658	13659	13660	13661	13662	13663	13664	13665	13666	13667	13668	13669	13670	13671	13672	13673	13674	13675	13676	13677	13678	13679	13680	13681	13682	13683	13684	13685	13686	13687	13688	13689	13690	13691	13692	13693	13694	13695	13696	13697	13698	13699	13700	13701	13702	13703	13704	13705	13706	13707	13708	13709	13710	13711	13712	13713	13714	13715	13716	13717	13718	13719	13720	13721	13722	13723	13724	13725	13726	13727	13728	13729	13730	13731	13732	13733	13734	13735	13736	13737	13738	13739	13740	13741	13742	13743	13744	13745	13746	13747	13748	13749	13750	13751	13752	13753	13754	13755	13756	13757	13758	13759	13760	13761	13762	13763	13764	13765	13766	13767	13768	13769	13770	13771	13772	13773	13774	13775	13776	13777	13778	13779	13780	13781	13782	13783	13784	13785	13786	13787	13788	13789	13790	13791	13792	13793	13794	13795	13796	13797	13798	13799	13800	13801	13802	13803	13804	13805	13806	13807	13808	13809	13810	13811	13812	13813	13814	13815	13816	13817	13818	13819	13820	13821	13822	13823	13824	13825	13826	13827	13828	13829	13830	13831	13832	13833	13834	13835	13836	13837	13838	13839	13840	13841	13842	13843	13844	13845	13846	13847	13848	13849	13850	13851	13852	13853	13854	13855	13856	13857	13858	13859	13860	13861	13862	13863	13864	13865	13866	13867	13868	13869	13870	13871	13872	13873	13874	13875	13876	13877	13878	13879	13880	13881	13882	13883	13884	13885	13886	13887	13888	13889	13890	13891	13892	13893	13894	13895	13896	13897	13898	13899	13900	13901	13902	13903	13904	13905	13906	13907	13908	13909	13910	13911	13912	13913	13914	13915	13916	13917	13918	13919	13920	13921	13922	13923	13924	13925	13926	13927	13928	13929	13930	13931	13932	13933	13934	13935	13936	13937	13938	13939	13940	13941	13942	13943	13944	13945	13946	13947	13948	13949	13950	13951	13952	13953	13954	13955	13956	13957	13958	13959	13960	13961	13962	13963	13964	13965	13966	13967	13968	13969	13970	13971	13972	13973	13974	13975	13976	13977	13978	13979	13980	13981	13982	13983	13984	13985	13986	13987	13988	13989	13990	13991	13992	13993	13994	13995	13996	13997	13998	13999	14000	14001	14002	14003	14004	14005	14006	14007	14008	14009	14010	14011	14012	14013	14014	14015	14016	14017	14018	14019	14020	14021	14022	14023	14024	14025	14026	14027	14028	14029	14030	14031	14032	14033	14034	14035	14036	14037	14038	14039	14040	14041	14042	14043	14044	14045	14046	14047	14048	14049	14050	14051	14052	14053	14054	14055	14056	14057	14058	14059	14060	14061	14062	14063	14064	14065	14066	14067	14068	14069	14070	14071	14072	14073	14074	14075	14076	14077	14078	14079	14080	14081	14082	14083	14084	14085	14086	14087	14088	14089	14090	14091	14092	14093	14094	14095	14096	14097	14098	14099	14100	14101	14102	14103	14104	14105	14106	14107	14108	14109	14110	14111	14112	14113	14114	14115	14116	14117	14118	14119	14120	14121	14122	14123	14124	14125	14126	14127	14128	14129	14130	14131	14132	14133	14134	14135	14136	14137	14138	14139	14140	14141	14142	14143	14144	14145	14146	14147	14148	14149	14150	14151	14152	14153	14154	14155	14156	14157	14158	14159	14160	14161	14162	14163	14164	14165	14166	14167	14168	14169	14170	14171	14172	14173	14174	14175	14176	14177	14178	14179	14180	14181	14182	14183	14184	14185	14186	14187	14188	14189	14190	14191	14192	14193	14194	14195	14196	14197	14198	14199	14200	14201	14202	14203	14204	14205	14206	14207	14208	14209	14210	14211	14212	14213	14214	14215	14216	14217	14218	14219	14220	14221	14222	14223	14224	14225	14226	14227	14228	14229	14230	14231	14232	14233	14234	14235	14236	14237	14238	14239	14240	14241	14242	14243	14244	14245	14246	14247	14248	14249	14250	14251	14252	14253	14254	14255	14256	14257	14258	14259	14260	14261	14262	14263	14264	14265	14266	14267	14268	14269	14270	14271	14272	14273	14274	14275	14276	14277	14278	14279	14280	14281	14282	14283	14284	14285	14286	14287	14288	14289	14290	14291	14292	14293	14294	14295	14296	14297	14298	14299	14300	14301	14302	14303	14304	14305	14306	14307	14308	14309	14310	14311	14312	14313	14314	14315	14316	14317	14318	14319	14320	14321	14322	14323	14324	14325	14326	14327	14328	14329	14330	14331	14332	14333	14334	14335	14336	14337	14338	14339	14340	14341	14342	14343	14344	14345	14346	14347	14348	14349	14350	14351	14352	14353	14354	14355	14356	14357	14358	14359	14360	14361	14362	14363	14364	14365	14366	14367	14368	14369	14370	14371	14372	14373	14374	14375	14376	14377	14378	14379	14380	14381	14382	14383	14384	14385	14386	14387	14388	14389	14390	14391	14392	14393	14394	14395	14396	14397	14398	14399	14400	14401	14402	14403	14404	14405	14406	14407	14408	14409	14410	14411	14412	14413	14414	14415	14416	14417	14418	14419	14420	14421	14422	14423	14424	14425	14426	14427	14428	14429	14430	14431	14432	14433	14434	14435	14436	14437	14438	14439	14440	14441	14442	14443	14444	14445	14446	14447	14448	14449	14450	14451	14452	14453	14454	14455	14456	14457	14458	14459	14460	14461	14462	14463	14464	14465	14466	14467	14468	14469	14470	14471	14472	14473	14474	14475	14476	14477	14478	14479	14480	14481	14482	14483	14484	14485	14486	14487	14488	14489	14490	14491	14492	14493	14494	14495	14496	14497	14498	14499	14500	14501	14502	14503	14504	14505	14506	14507	14508	14509	14510	14511	14512	14513	14514	14515	14516	14517	14518	14519	14520	14521	14522	14523	14524	14525	14526	14527	14528	14529	14530	14531	14532	14533	14534	14535	14536	14537	14538	14539	14540	14541	14542	14543	14544	14545	14546	14547	14548	14549	14550	14551	14552	14553	14554	14555	14556	14557	14558	14559	14560	14561	14562	14563	14564	14565	14566	14567	14568	14569	14570	14571	14572	14573	14574	14575	14576	14577	14578	14579	14580	14581	14582	14583	14584	14585	14586	14587	14588	14589	14590	14591	14592	14593	14594	14595	14596	14597	14598	14599	14600	14601	14602	14603	14604	14605	14606	14607	14608	14609	14610	14611	14612	14613	14614	14615	14616	14617	14618	14619	14620	14621	14622	14623	14624	14625	14626	14627	14628	14629	14630	14631	14632	14633	14634	14635	14636	14637	14638	14639	14640	14641	14642	14643	14644	14645	14646	14647	14648	14649	14650	14651	14652	14653	14654	14655	14656	14657	14658	14659	14660	14661	14662	14663	14664	14665	14666	14667	14668	14669	14670	14671	14672	14673	14674	14675	14676	14677	14678	14679	14680	14681	14682	14683	14684	14685	14686	14687	14688	14689	14690	14691	14692	14693	14694	14695	14696	14697	14698	14699	14700	14701	14702	14703	14704	14705	14706	14707	14708	14709	14710	14711	14712	14713	14714	14715	14716	14717	14718	14719	14720	14721	14722	14723	14724	14725	14726	14727	14728	14729	14730	14731	14732	14733	14734	14735	14736	14737	14738	14739	14740	14741	14742	14743	14744	14745	14746	14747	14748	14749	14750	14751	14752	14753	14754	14755	14756	14757	14758	14759	14760	14761	14762	14763	14764	14765	14766	14767	15020	15027	15028	15029	15030	15031	15032	15033	15034	15035	15036	15037	15038	15039	15040	15041	15042],19)=NaN;
                    output([2073	2074	2075	2076	2077	2078	2079	2080	2081	2082	2083	2084	2085	2086	2087	2088	2089	2090	2091	2092	2093	2094	2095	2096	2097	2098	2099	2100	2101	2102	2103	2104	2105	2106	2107	2108	2109	2110	2111	2112	2113	2114	2115	2116	2117	2118	2119	2120	2121	2122	2123	2124	2125	2752	2753	2754	2755	2756	2757	2758	2759	2761	2763	2764	3045	3046	3047	3048	3049	3050	3051	3052	3053	3054	3055	3056	3057	3058	3059	3060	4176	4178	4179	4180	4181	4182	4183	4184	4185	4186	4240	4245	4247	4248	4250	4254	4255	4256	4257	4258	4259	4260	4261	4262	4266	4404	4405	4406	4407	4411	4412	4413	4420	4421	4422	4425	4428	4773	4774	4775	4816	4817	4818	4819	4820	4821	4822	4823	4824	4825	4826	4827	4828	4829	6754	6755	6756	6757	6758	6759	6760	6761	6762	6763	6764	6765	6766	6767	6768	6769	6770	6771	6772	6773	6774	6776	6777	6778	6779	6780	6781	6782	6784	6785	6786	6787	6788	6789	6791	6792	6793	6795	6797	6798	6799	6800	6801	6802	6803	6804	6805	6806	6807	6808	6809	6810	6811	6812	6813	6814	6815	6816	6817	6818	7128	7129	7130	7131	7132	7133	7934	7935	7936	7937	7938	7939	7940	7941	7942	7943	7944	7945	7946	7947	7948	7949	7950	7951	7952	7953	7954	7955	7956	7957	7958	7959	7960	7961	7962	7963	7964	7965	7966	7967	7968	7969	7970	7971	7972	7973	7974	7975	7976	7977	7978	7979	7980	7981	7982	7983	7984	7985	7986	7987	7988	7989	7990	7991	7992	7993	7994	7995	7996	7997	7998	7999	8000	8001	8002	8003	8004	8005	8006	8007	8008	8009	8010	8011	8012	8013	8014	8015	8016	8017	8018	8019	8020	8021	8022	8023	8024	8025	8026	8027	8028	8029	8030	8031	8032	8033	8034	8035	8036	8037	8038	8039	8040	8041	8042	8043	8044	8045	8046	8047	8048	8049	8050	8051	8052	8053	8054	8055	8056	8057	8058	8059	8060	8061	8062	8063	8064	8065	8066	8067	8068	8069	8070	11902	11903	11904	11905	11906	11907	11908	11909	11910	11911	11912	11913	11914	11915	11916	11917	11918	11919	11920	11921	11922	11923	11924	11925	11926	11927	11928	11929	11930	11931	11932	11933	11934	11935	11936	11937	11938	11939	11940	11941	11942	11943	11944	11945	11946	11947	11948	11949	11950	11951	11952	11953	11954	11955	11956	11957	11958	11959	11960	11961	11962	11963	11964	11965	11966	11967	11968	11969	11970	11971	11972	11973	11974	11975	11976	11977	11978	11979	11980	11981	11982	11983	11984	11985	11986	11987	11988	11989	11990	11991	11992	11993	11994	11995	11996	11997	11998	11999	12000	12001	12002	12003	12004	12005	12006	12007	12008	12009	12010	12011	12012	12013	12014	12015	12016	12017	12018	12019	12020	12021	12022	12023	12024	12025	12026	12027	12028	12029	12030	12031	12032	12033	12034	12035	12036	12037	12038	12039	12040	12041	12042	12043	12044	12045	12046	12047	12048	12049	12050	12051	12052	12053	12054	12055	12056	12057	12058	12059	12060	12061	12062	12063	12064	12065	12066	12067	12068	12069	12070	12071	12072	12073	12074	12075	12076	12077	12078	12079	12080	12081	12082	12083	12084	12085	12086	12087	12088	12089	12090	12091	12092	12093	12094	12095	12096	12097	12098	12099	12100	12101	12102	12103	12104	12105	12106	12107	12108	12109	12110	12111	12112	12113	12114	12115	12116	12117	12118	12119	12120	12121	12122	12123	12124	12125	12126	12127	12128	12129	12130	12131	12132	12133	12134	12135	12136	12137	12138	12139	12140	12141	12142	12143	12144	12145	12146	12147	12148	12149	12150	12151	12152	12153	12154	12155	12156	12157	12158	12159	12160	12161	12162	12163	12164	12165	12166	12167	12168	12169	12170	12171	12172	12173	12174	12175	12176	12177	12178	12179	12180	12181	12182	12183	12184	12185	12186	12187	12188	12189	12190	12191	12192	12193	12194	12195	12196	12197	12198	12199	12200	12201	12202	12203	12204	12205	12206	12207	12208	12209	12210	12211	12212	12213	12214	12215	12216	12217	12218	12219	12220	12221	12222	12223	12224	12225	12226	12227	12228	12229	12230	12231	12232	12233	12234	12235	12236	12237	12238	12239	12240	12241	12242	12243	12244	12245	12246	12247	12248	12249	12250	12251	12252	12253	12254	12255	12256	12257	12258	12259	12260	12261	12262	12263	12264	12265	12266	12267	12268	12269	12270	12271	12272	12273	12274	12275	12276	12277	12278	12279	12280	12281	12282	12283	12284	12285	12286	12287	12288	12289	12290	12291	12292	12293	12294	12295	12296	12297	12298	12299	12300	12301	12302	12303	12304	12305	12306	12307	12308	12309	12310	12311	12312	12313	12314	12315	12316	12317	12318	12319	12320	12321	12322	12323	12324	12325	12326	12327	12328	12329	12330	12331	12332	12333	12334	12335	12336	12337	12338	12339	12340	12341	12342	12343	12344	12345	12346	12347	12348	12349	12350	12351	12352	12353	12354	12355	12356	12357	12358	12359	12360	12361	12362	12363	12364	12365	12366	12367	12368	12369	12370	12371	12372	12373	12374	12375	12376	12377	12378	12379	12380	12381	12382	12383	12384	12385	12386	12387	12388	12389	12390	12391	12392	12393	12394	12395	12396	12397	12398	12399	12400	12401	12402	12403	12404	12405	12406	12407	12408	12409	12410	12411	12412	12413	12414	12415	12416	12417	12418	12419	12420	12421	12422	12423	12424	12425	12426	12427	12428	12429	12430	12431	12432	12433	12434	12435	12436	12437	12438	12439	12440	12441	12442	12443	12444	12445	12446	12447	12448	12449	12450	12451	12452	12453	12454	12455	12456	12457	12458	12459	12460	12461	12462	12463	12464	12465	12466	12467	12468	12469	12470	12471	12472	12473	12474	12475	12476	12477	12478	12479	12480	12481	12482	12483	12484	12485	12486	12487	12488	12489	12490	12491	12492	12493	12494	12495	12496	12497	12498	12499	12500	12501	12502	12503	12504	12505	12506	12507	12508	12509	12510	12511	12512	12513	12514	12515	12516	12517	12518	12519	12520	12521	12522	12523	12524	12525	12526	12527	12528	12529	12530	12531	12532	12533	12534	12535	12536	12537	12538	12539	12540	12541	12542	12543	12544	12545	12546	12547	12548	12549	12550	12551	12552	12553	12554	12555	12556	12557	12558	12559	12560	12561	12562	12563	12564	12565	12566	12567	12568	12569	12570	12571	12572	12573	12574	12575	12576	12577	12578	12579	12580	12581	12582	12583	12584	12585	12586	12587	12588	12589	12590	12591	12592	12593	12594	12595	12596	12597	12598	12599	12600	12601	12602	12603	12604	12605	12606	12607	12608	12609	12610	12611	12612	12613	12614	12615	12616	12617	12618	12619	12620	12621	12622	12623	12624	12625	12626	12627	12628	12629	12630	12631	12632	12633	12634	12635	12636	12637	12638	12639	12640	12641	12642	12643	12644	12645	12646	12647	12648	12649	12650	12651	12652	12653	12654	12655	12656	12657	12658	12659	12660	12661	12662	12663	12664	12665	12666	12667	12668	12669	12670	12671	12672	12673	12674	12675	12676	12677	12678	12679	12680	12681	12682	12683	12684	12685	12686	12687	12688	12689	12690	12691	12692	12693	12694	12695	12696	12697	12698	12699	12700	12701	12702	12703	12704	12705	12706	12707	12708	12709	12710	12711	12712	12713	12714	12715	12716	12717	12718	12719	12720	12721	12722	12723	12724	12725	12726	12727	12728	12729	12730	12731	12732	12733	12734	12735	12736	12737	12738	12739	12740	12741	12742	12743	12744	12745	12746	12747	12748	12749	12750	12751	12752	12753	12754	12755	12756	12757	12758	12759	12760	12761	12762	12763	12764	12765	12766	12767	12768	12769	12770	12771	12772	12773	12774	12775	12776	12777	12778	12779	12780	12781	12782	12783	12784	12785	12786	12787	12788	12789	12790	12791	12792	12793	12794	12795	12796	12797	12798	12799	12800	12801	12802	12803	12804	12805	12806	12807	12808	12809	12810	12811	12812	12813	12814	12815	12816	12817	12818	12819	12820	12821	12822	12823	12824	12825	12826	12827	12828	12829	12830	12831	12832	12833	12834	12835	12836	12837	12838	12839	12840	12841	12842	12843	12844	12845	12846	12847	12848	12849	12850	12851	12852	12853	12854	12855	12856	12857	12858	12859	12860	12861	12862	12863	12864	12865	12866	12867	12868	12869	12870	12871	12872	12873	12874	12875	12876	12877	12878	12879	12880	12881	12882	12883	12884	12885	12886	12887	12888	12889	12890	12891	12892	12893	12894	12895	12896	12897	12898	12899	12900	12901	12902	12903	12904	12905	12906	12907	12908	12909	12910	12911	12912	12913	12914	12915	12916	12917	12918	12919	12920	12921	12922	12923	12924	12925	12926	12927	12928	12929	12930	12931	12932	12933	12934	12935	12936	12937	12938	12939	12940	12941	12942	12943	12944	12945	12946	12947	12948	12949	12950	12951	12952	12953	12954	12955	12956	12957	12958	12959	12960	12961	12962	12963	12964	12965	12966	12967	12968	12969	12970	12971	12972	12973	12974	12975	12976	12977	12978	12979	12980	12981	12982	12983	12984	12985	12986	12987	12988	12989	12990	12991	12992	12993	12994	12995	12996	12997	12998	12999	13000	13001	13002	13003	13004	13005	13006	13007	13008	13009	13010	13011	13012	13013	13014	13015	13016	13017	13018	13019	13020	13021	13022	13023	13024	13025	13026	13027	13028	13029	13030	13031	13032	13033	13034	13035	13036	13037	13038	13039	13040	13041	13042	13043	13044	13045	13046	13047	13048	13049	13050	13051	13052	13053	13054	13055	13056	13057	13058	13059	13060	13061	13062	13063	13064	13065	13066	13067	13068	13069	13070	13071	13072	13073	13074	13075	13076	13077	13078	13079	13080	13081	13082	13083	13084	13085	13086	13087	13088	13089	13090	13091	13092	13093	13094	13095	13096	13097	13098	13099	13100	13101	13102	13103	13104	13105	13106	13107	13108	13109	13110	13111	13112	13113	13114	13115	13116	13117	13118	13119	13120	13121	13122	13123	13124	13125	13126	13127	13128	13129	13130	13131	13132	13133	13134	13135	13136	13137	13138	13139	13140	13141	13142	13143	13144	13145	13146	13147	13148	13149	13150	13151	13152	13153	13154	13155	13156	13157	13158	13159	13160	13161	13162	13163	13164	13165	13166	13167	13168	13169	13170	13171	13172	13173	13174	13175	13176	13177	13178	13179	13180	13181	13182	13183	13184	13185	13186	13187	13188	13189	13190	13191	13192	13193	13194	13195	13196	13197	13198	13199	13200	13201	13202	13203	13204	13205	13206	13207	13208	13209	13210	13211	13212	13213	13214	13215	13216	13217	13218	13219	13220	13221	13222	13223	13224	13225	13226	13227	13228	13229	13230	13231	13232	13233	13234	13235	13236	13237	13238	13239	13240	13241	13242	13243	13244	13245	13246	13247	13248	13249	13250	13251	13252	13253	13254	13255	13256	13257	13258	13259	13260	13261	13262	13263	13264	13265	13266	13267	13268	13269	13270	13271	13272	13273	13274	13275	13276	13277	13278	13279	13280	13281	13282	13283	13284	13285	13286	13287	13288	13289	13290	13291	13292	13293	13294	13295	13296	13297	13298	13299	13300	13301	13302	13303	13304	13305	13306	13307	13308	13309	13310	13311	13312	13313	13314	13315	13316	13317	13318	13319	13320	13321	13322	13323	13324	13325	13326	13327	13328	13329	13330	13331	13332	13333	13334	13335	13336	13337	13338	13339	13340	13341	13342	13343	13344	13345	13346	13347	13348	13349	13350	13351	13352	13353	13354	13355	13356	13357	13358	13359	13360	13361	13362	13363	13364	13365	13366	13367	13368	13369	13370	13371	13372	13373	13374	13375	13376	13377	13378	13379	13380	13381	13382	13383	13384	13385	13386	13387	13388	13389	13390	13391	13392	13393	13394	13395	13396	13397	13398	13399	13400	13401	13402	13403	13404	13405	13406	13407	13408	13409	13410	13411	13412	13413	13414	13415	13416	13417	13418	13419	13420	13421	13422	13423	13424	13425	13426	13427	13428	13429	13430	13431	13432	13433	13434	13435	13436	13437	13438	13439	13440	13441	13442	13443	13444	13445	13446	13447	13448	13449	13450	13451	13452	13453	13454	13455	13456	13457	13458	13459	13460	13461	13462	13463	13464	13465	13466	13467	13468	13469	13470	13471	13472	13473	13474	13475	13476	13477	13478	13479	13480	13481	13482	13483	13484	13485	13486	13487	13488	13489	13490	13491	13492	13493	13494	13495	13496	13497	13498	13499	13500	13501	13502	13503	13504	13505	13506	13507	13508	13509	13510	13511	13512	13513	13514	13515	13516	13517	13518	13519	13520	13521	13522	13523	13524	13525	13526	13527	13528	13529	13530	13531	13532	13533	13534	13535	13536	13537	13538	13539	13540	13541	13542	13543	13544	13545	13546	13547	13548	13549	13550	13551	13552	13553	13554	13555	13556	13557	13558	13559	13560	13561	13562	13563	13564	13565	13566	13567	13568	13569	13570	13571	13572	13573	13574	13575	13576	13577	13578	13579	13580	13581	13582	13583	13584	13585	13586	13587	13588	13589	13590	13591	13592	13593	13594	13595	13596	13597	13598	13599	13600	13601	13602	13603	13604	13605	13606	13607	13608	13609	13610	13611	13612	13613	13614	13615	13616	13617	13618	13619	13620	13621	13622	13623	13624	13625	13626	13627	13628	13629	13630	13631	13632	13633	13634	13635	13636	13637	13638	13639	13640	13641	13642	13643	13644	13645	13646	13647	13648	13649	13650	13651	13652	13653	13654	13655	13656	13657	13658	13659	13660	13661	13662	13663	13664	13665	13666	13667	13668	13669	13670	13671	13672	13673	13674	13675	13676	13677	13678	13679	13680	13681	13682	13683	13684	13685	13686	13687	13688	13689	13690	13691	13692	13693	13694	13695	13696	13697	13698	13699	13700	13701	13702	13703	13704	13705	13706	13707	13708	13709	13710	13711	13712	13713	13714	13715	13716	13717	13718	13719	13720	13721	13722	13723	13724	13725	13726	13727	13728	13729	13730	13731	13732	13733	13734	13735	13736	13737	13738	13739	13740	13741	13742	13743	13744	13745	13746	13747	13748	13749	13750	13751	13752	13753	13754	13755	13756	13757	13758	13759	13760	13761	13762	13763	13764	13765	13766	13767	13768	13769	13770	13771	13772	13773	13774	13775	13776	13777	13778	13779	13780	13781	13782	13783	13784	13785	13786	13787	13788	13789	13790	13791	13792	13793	13794	13795	13796	13797	13798	13799	13800	13801	13802	13803	13804	13805	13806	13807	13808	13809	13810	13811	13812	13813	13814	13815	13816	13817	13818	13819	13820	13821	13822	13823	13824	13825	13826	13827	13828	13829	13830	13831	13832	13833	13834	13835	13836	13837	13838	13839	13840	13841	13842	13843	13844	13845	13846	13847	13848	13849	13850	13851	13852	13853	13854	13855	13856	13857	13858	13859	13860	13861	13862	13863	13864	13865	13866	13867	13868	13869	13870	13871	13872	13873	13874	13875	13876	13877	13878	13879	13880	13881	13882	13883	13884	13885	13886	13887	13888	13889	13890	13891	13892	13893	13894	13895	13896	13897	13898	13899	13900	13901	13902	13903	13904	13905	13906	13907	13908	13909	13910	13911	13912	13913	13914	13915	13916	13917	13918	13919	13920	13921	13922	13923	13924	13925	13926	13927	13928	13929	13930	13931	13932	13933	13934	13935	13936	13937	13938	13939	13940	13941	13942	13943	13944	13945	13946	13947	13948	13949	13950	13951	13952	13953	13954	13955	13956	13957	13958	13959	13960	13961	13962	13963	13964	13965	13966	13967	13968	13969	13970	13971	13972	13973	13974	13975	13976	13977	13978	13979	13980	13981	13982	13983	13984	13985	13986	13987	13988	13989	13990	13991	13992	13993	13994	13995	13996	13997	13998	13999	14000	14001	14002	14003	14004	14005	14006	14007	14008	14009	14010	14011	14012	14013	14014	14015	14016	14017	14018	14019	14020	14021	14022	14023	14024	14025	14026	14027	14028	14029	14030	14031	14032	14033	14034	14035	14036	14037	14038	14039	14040	14041	14042	14043	14044	14045	14046	14047	14048	14049	14050	14051	14052	14053	14054	14055	14056	14057	14058	14059	14060	14061	14062	14063	14064	14065	14066	14067	14068	14069	14070	14071	14072	14073	14074	14075	14076	14077	14078	14079	14080	14081	14082	14083	14084	14085	14086	14087	14088	14089	14090	14091	14092	14093	14094	14095	14096	14097	14098	14099	14100	14101	14102	14103	14104	14105	14106	14107	14108	14109	14110	14111	14112	14113	14114	14115	14116	14117	14118	14119	14120	14121	14122	14123	14124	14125	14126	14127	14128	14129	14130	14131	14132	14133	14134	14135	14136	14137	14138	14139	14140	14141	14142	14143	14144	14145	14146	14147	14148	14149	14150	14151	14152	14153	14154	14155	14156	14157	14158	14159	14160	14161	14162	14163	14164	14165	14166	14167	14168	14169	14170	14171	14172	14173	14174	14175	14176	14177	14178	14179	14180	14181	14182	14183	14184	14185	14186	14187	14188	14189	14190	14191	14192	14193	14194	14195	14196	14197	14198	14199	14200	14201	14202	14203	14204	14205	14206	14207	14208	14209	14210	14211	14212	14213	14214	14215	14216	14217	14218	14219	14220	14221	14222	14223	14224	14225	14226	14227	14228	14229	14230	14231	14232	14233	14234	14235	14236	14237	14238	14239	14240	14241	14242	14243	14244	14245	14246	14247	14248	14249	14250	14251	14252	14253	14254	14255	14256	14257	14258	14259	14260	14261	14262	14263	14264	14265	14266	14267	14268	14269	14270	14271	14272	14273	14274	14275	14276	14277	14278	14279	14280	14281	14282	14283	14284	14285	14286	14287	14288	14289	14290	14291	14292	14293	14294	14295	14296	14297	14298	14299	14300	14301	14302	14303	14304	14305	14306	14307	14308	14309	14310	14311	14312	14313	14314	14315	14316	14317	14318	14319	14320	14321	14322	14323	14324	14325	14326	14327	14328	14329	14330	14331	14332	14333	14334	14335	14336	14337	14338	14339	14340	14341	14342	14343	14344	14345	14346	14347	14348	14349	14350	14351	14352	14353	14354	14355	14356	14357	14358	14359	14360	14361	14362	14363	14364	14365	14366	14367	14368	14369	14370	14371	14372	14373	14374	14375	14376	14377	14378	14379	14380	14381	14382	14383	14384	14385	14386	14387	14388	14389	14390	14391	14392	14393	14394	14395	14396	14397	14398	14399	14400	14401	14402	14403	14404	14405	14406	14407	14408	14409	14410	14411	14412	14413	14414	14415	14416	14417	14418	14419	14420	14421	14422	14423	14424	14425	14426	14427	14428	14429	14430	14431	14432	14433	14434	14435	14436	14437	14438	14439	14440	14441	14442	14443	14444	14445	14446	14447	14448	14449	14450	14451	14452	14453	14454	14455	14456	14457	14458	14459	14460	14461	14462	14463	14464	14465	14466	14467	14468	14469	14470	14471	14472	14473	14474	14475	14476	14477	14478	14479	14480	14481	14482	14483	14484	14485	14486	14487	14488	14489	14490	14491	14492	14493	14494	14495	14496	14497	14498	14499	14500	14501	14502	14503	14504	14505	14506	14507	14508	14509	14510	14511	14512	14513	14514	14515	14516	14517	14518	14519	14520	14521	14522	14523	14524	14525	14526	14527	14528	14529	14530	14531	14532	14533	14534	14535	14536	14537	14538	14539	14540	14541	14542	14543	14544	14545	14546	14547	14548	14549	14550	14551	14552	14553	14554	14555	14556	14557	14558	14559	14560	14561	14562	14563	14564	14565	14566	14567	14568	14569	14570	14571	14572	14573	14574	14575	14576	14577	14578	14579	14580	14581	14582	14583	14584	14585	14586	14587	14588	14589	14590	14591	14592	14593	14594	14595	14596	14597	14598	14599	14600	14601	14602	14603	14604	14605	14606	14607	14608	14609	14610	14611	14612	14613	14614	14615	14616	14617	14618	14619	14620	14621	14622	14623	14624	14625	14626	14627	14628	14629	14630	14631	14632	14633	14634	14635	14636	14637	14638	14639	14640	14641	14642	14643	14644	14645	14646	14647	14648	14649	14650	14651	14652	14653	14654	14655	14656	14657	14658	14659	14660	14661	14662	14663	14664	14665	14666	14667	14668	14669	14670	14671	14672	14673	14674	14675	14676	14677	14678	14679	14680	14681	14682	14683	14684	14685	14686	14687	14688	14689	14690	14691	14692	14693	14694	14695	14696	14697	14698	14699	14700	14701	14702	14703	14704	14705	14706	14707	14708	14709	14710	14711	14712	14713	14714	14715	14716	14717	14718	14719	14720	14721	14722	14723	14724	14725	14726	14727	14728	14729	14730	14731	14732	14733	14734	14735	14736	14737	14738	14739	14740	14741	14742	14743	14744	14745	14746	14747	14748	14749	14750	14751	14752	14753	14754	14755	14756	14757	14758	14759	14760	14761	14762	14763	14764	14765	14766	14767	15020	15027	15028	15029	15030	15031	15032	15033	15034	15035	15036	15037	15038	15039	15040	15041	15042],20)=NaN;
                    output([2073	2074	2075	2076	2077	2078	2079	2080	2081	2082	2083	2084	2085	2086	2087	2088	2089	2090	2091	2092	2093	2094	2095	2096	2097	2098	2099	2100	2101	2102	2103	2104	2105	2106	2107	2108	2109	2110	2111	2112	2113	2114	2115	2116	2117	2118	2119	2120	2121	2122	2123	2124	2125	2752	2753	2754	2755	2756	2757	2758	2759	2761	2763	2764	3045	3046	3047	3048	3049	3050	3051	3052	3053	3054	3055	3056	3057	3058	3059	3060	4176	4178	4179	4180	4181	4182	4183	4184	4185	4186	4240	4245	4247	4248	4250	4254	4255	4256	4257	4258	4259	4260	4261	4262	4266	4404	4405	4406	4407	4411	4412	4413	4420	4421	4422	4425	4428	4773	4774	4775	4816	4817	4818	4819	4820	4821	4822	4823	4824	4825	4826	4827	4828	4829	6754	6755	6756	6757	6758	6759	6760	6761	6762	6763	6764	6765	6766	6767	6768	6769	6770	6771	6772	6773	6774	6776	6777	6778	6779	6780	6781	6782	6784	6785	6786	6787	6788	6789	6791	6792	6793	6795	6797	6798	6799	6800	6801	6802	6803	6804	6805	6806	6807	6808	6809	6810	6811	6812	6813	6814	6815	6816	6817	6818	7128	7129	7130	7131	7132	7133	7934	7935	7936	7937	7938	7939	7940	7941	7942	7943	7944	7945	7946	7947	7948	7949	7950	7951	7952	7953	7954	7955	7956	7957	7958	7959	7960	7961	7962	7963	7964	7965	7966	7967	7968	7969	7970	7971	7972	7973	7974	7975	7976	7977	7978	7979	7980	7981	7982	7983	7984	7985	7986	7987	7988	7989	7990	7991	7992	7993	7994	7995	7996	7997	7998	7999	8000	8001	8002	8003	8004	8005	8006	8007	8008	8009	8010	8011	8012	8013	8014	8015	8016	8017	8018	8019	8020	8021	8022	8023	8024	8025	8026	8027	8028	8029	8030	8031	8032	8033	8034	8035	8036	8037	8038	8039	8040	8041	8042	8043	8044	8045	8046	8047	8048	8049	8050	8051	8052	8053	8054	8055	8056	8057	8058	8059	8060	8061	8062	8063	8064	8065	8066	8067	8068	8069	8070	11902	11903	11904	11905	11906	11907	11908	11909	11910	11911	11912	11913	11914	11915	11916	11917	11918	11919	11920	11921	11922	11923	11924	11925	11926	11927	11928	11929	11930	11931	11932	11933	11934	11935	11936	11937	11938	11939	11940	11941	11942	11943	11944	11945	11946	11947	11948	11949	11950	11951	11952	11953	11954	11955	11956	11957	11958	11959	11960	11961	11962	11963	11964	11965	11966	11967	11968	11969	11970	11971	11972	11973	11974	11975	11976	11977	11978	11979	11980	11981	11982	11983	11984	11985	11986	11987	11988	11989	11990	11991	11992	11993	11994	11995	11996	11997	11998	11999	12000	12001	12002	12003	12004	12005	12006	12007	12008	12009	12010	12011	12012	12013	12014	12015	12016	12017	12018	12019	12020	12021	12022	12023	12024	12025	12026	12027	12028	12029	12030	12031	12032	12033	12034	12035	12036	12037	12038	12039	12040	12041	12042	12043	12044	12045	12046	12047	12048	12049	12050	12051	12052	12053	12054	12055	12056	12057	12058	12059	12060	12061	12062	12063	12064	12065	12066	12067	12068	12069	12070	12071	12072	12073	12074	12075	12076	12077	12078	12079	12080	12081	12082	12083	12084	12085	12086	12087	12088	12089	12090	12091	12092	12093	12094	12095	12096	12097	12098	12099	12100	12101	12102	12103	12104	12105	12106	12107	12108	12109	12110	12111	12112	12113	12114	12115	12116	12117	12118	12119	12120	12121	12122	12123	12124	12125	12126	12127	12128	12129	12130	12131	12132	12133	12134	12135	12136	12137	12138	12139	12140	12141	12142	12143	12144	12145	12146	12147	12148	12149	12150	12151	12152	12153	12154	12155	12156	12157	12158	12159	12160	12161	12162	12163	12164	12165	12166	12167	12168	12169	12170	12171	12172	12173	12174	12175	12176	12177	12178	12179	12180	12181	12182	12183	12184	12185	12186	12187	12188	12189	12190	12191	12192	12193	12194	12195	12196	12197	12198	12199	12200	12201	12202	12203	12204	12205	12206	12207	12208	12209	12210	12211	12212	12213	12214	12215	12216	12217	12218	12219	12220	12221	12222	12223	12224	12225	12226	12227	12228	12229	12230	12231	12232	12233	12234	12235	12236	12237	12238	12239	12240	12241	12242	12243	12244	12245	12246	12247	12248	12249	12250	12251	12252	12253	12254	12255	12256	12257	12258	12259	12260	12261	12262	12263	12264	12265	12266	12267	12268	12269	12270	12271	12272	12273	12274	12275	12276	12277	12278	12279	12280	12281	12282	12283	12284	12285	12286	12287	12288	12289	12290	12291	12292	12293	12294	12295	12296	12297	12298	12299	12300	12301	12302	12303	12304	12305	12306	12307	12308	12309	12310	12311	12312	12313	12314	12315	12316	12317	12318	12319	12320	12321	12322	12323	12324	12325	12326	12327	12328	12329	12330	12331	12332	12333	12334	12335	12336	12337	12338	12339	12340	12341	12342	12343	12344	12345	12346	12347	12348	12349	12350	12351	12352	12353	12354	12355	12356	12357	12358	12359	12360	12361	12362	12363	12364	12365	12366	12367	12368	12369	12370	12371	12372	12373	12374	12375	12376	12377	12378	12379	12380	12381	12382	12383	12384	12385	12386	12387	12388	12389	12390	12391	12392	12393	12394	12395	12396	12397	12398	12399	12400	12401	12402	12403	12404	12405	12406	12407	12408	12409	12410	12411	12412	12413	12414	12415	12416	12417	12418	12419	12420	12421	12422	12423	12424	12425	12426	12427	12428	12429	12430	12431	12432	12433	12434	12435	12436	12437	12438	12439	12440	12441	12442	12443	12444	12445	12446	12447	12448	12449	12450	12451	12452	12453	12454	12455	12456	12457	12458	12459	12460	12461	12462	12463	12464	12465	12466	12467	12468	12469	12470	12471	12472	12473	12474	12475	12476	12477	12478	12479	12480	12481	12482	12483	12484	12485	12486	12487	12488	12489	12490	12491	12492	12493	12494	12495	12496	12497	12498	12499	12500	12501	12502	12503	12504	12505	12506	12507	12508	12509	12510	12511	12512	12513	12514	12515	12516	12517	12518	12519	12520	12521	12522	12523	12524	12525	12526	12527	12528	12529	12530	12531	12532	12533	12534	12535	12536	12537	12538	12539	12540	12541	12542	12543	12544	12545	12546	12547	12548	12549	12550	12551	12552	12553	12554	12555	12556	12557	12558	12559	12560	12561	12562	12563	12564	12565	12566	12567	12568	12569	12570	12571	12572	12573	12574	12575	12576	12577	12578	12579	12580	12581	12582	12583	12584	12585	12586	12587	12588	12589	12590	12591	12592	12593	12594	12595	12596	12597	12598	12599	12600	12601	12602	12603	12604	12605	12606	12607	12608	12609	12610	12611	12612	12613	12614	12615	12616	12617	12618	12619	12620	12621	12622	12623	12624	12625	12626	12627	12628	12629	12630	12631	12632	12633	12634	12635	12636	12637	12638	12639	12640	12641	12642	12643	12644	12645	12646	12647	12648	12649	12650	12651	12652	12653	12654	12655	12656	12657	12658	12659	12660	12661	12662	12663	12664	12665	12666	12667	12668	12669	12670	12671	12672	12673	12674	12675	12676	12677	12678	12679	12680	12681	12682	12683	12684	12685	12686	12687	12688	12689	12690	12691	12692	12693	12694	12695	12696	12697	12698	12699	12700	12701	12702	12703	12704	12705	12706	12707	12708	12709	12710	12711	12712	12713	12714	12715	12716	12717	12718	12719	12720	12721	12722	12723	12724	12725	12726	12727	12728	12729	12730	12731	12732	12733	12734	12735	12736	12737	12738	12739	12740	12741	12742	12743	12744	12745	12746	12747	12748	12749	12750	12751	12752	12753	12754	12755	12756	12757	12758	12759	12760	12761	12762	12763	12764	12765	12766	12767	12768	12769	12770	12771	12772	12773	12774	12775	12776	12777	12778	12779	12780	12781	12782	12783	12784	12785	12786	12787	12788	12789	12790	12791	12792	12793	12794	12795	12796	12797	12798	12799	12800	12801	12802	12803	12804	12805	12806	12807	12808	12809	12810	12811	12812	12813	12814	12815	12816	12817	12818	12819	12820	12821	12822	12823	12824	12825	12826	12827	12828	12829	12830	12831	12832	12833	12834	12835	12836	12837	12838	12839	12840	12841	12842	12843	12844	12845	12846	12847	12848	12849	12850	12851	12852	12853	12854	12855	12856	12857	12858	12859	12860	12861	12862	12863	12864	12865	12866	12867	12868	12869	12870	12871	12872	12873	12874	12875	12876	12877	12878	12879	12880	12881	12882	12883	12884	12885	12886	12887	12888	12889	12890	12891	12892	12893	12894	12895	12896	12897	12898	12899	12900	12901	12902	12903	12904	12905	12906	12907	12908	12909	12910	12911	12912	12913	12914	12915	12916	12917	12918	12919	12920	12921	12922	12923	12924	12925	12926	12927	12928	12929	12930	12931	12932	12933	12934	12935	12936	12937	12938	12939	12940	12941	12942	12943	12944	12945	12946	12947	12948	12949	12950	12951	12952	12953	12954	12955	12956	12957	12958	12959	12960	12961	12962	12963	12964	12965	12966	12967	12968	12969	12970	12971	12972	12973	12974	12975	12976	12977	12978	12979	12980	12981	12982	12983	12984	12985	12986	12987	12988	12989	12990	12991	12992	12993	12994	12995	12996	12997	12998	12999	13000	13001	13002	13003	13004	13005	13006	13007	13008	13009	13010	13011	13012	13013	13014	13015	13016	13017	13018	13019	13020	13021	13022	13023	13024	13025	13026	13027	13028	13029	13030	13031	13032	13033	13034	13035	13036	13037	13038	13039	13040	13041	13042	13043	13044	13045	13046	13047	13048	13049	13050	13051	13052	13053	13054	13055	13056	13057	13058	13059	13060	13061	13062	13063	13064	13065	13066	13067	13068	13069	13070	13071	13072	13073	13074	13075	13076	13077	13078	13079	13080	13081	13082	13083	13084	13085	13086	13087	13088	13089	13090	13091	13092	13093	13094	13095	13096	13097	13098	13099	13100	13101	13102	13103	13104	13105	13106	13107	13108	13109	13110	13111	13112	13113	13114	13115	13116	13117	13118	13119	13120	13121	13122	13123	13124	13125	13126	13127	13128	13129	13130	13131	13132	13133	13134	13135	13136	13137	13138	13139	13140	13141	13142	13143	13144	13145	13146	13147	13148	13149	13150	13151	13152	13153	13154	13155	13156	13157	13158	13159	13160	13161	13162	13163	13164	13165	13166	13167	13168	13169	13170	13171	13172	13173	13174	13175	13176	13177	13178	13179	13180	13181	13182	13183	13184	13185	13186	13187	13188	13189	13190	13191	13192	13193	13194	13195	13196	13197	13198	13199	13200	13201	13202	13203	13204	13205	13206	13207	13208	13209	13210	13211	13212	13213	13214	13215	13216	13217	13218	13219	13220	13221	13222	13223	13224	13225	13226	13227	13228	13229	13230	13231	13232	13233	13234	13235	13236	13237	13238	13239	13240	13241	13242	13243	13244	13245	13246	13247	13248	13249	13250	13251	13252	13253	13254	13255	13256	13257	13258	13259	13260	13261	13262	13263	13264	13265	13266	13267	13268	13269	13270	13271	13272	13273	13274	13275	13276	13277	13278	13279	13280	13281	13282	13283	13284	13285	13286	13287	13288	13289	13290	13291	13292	13293	13294	13295	13296	13297	13298	13299	13300	13301	13302	13303	13304	13305	13306	13307	13308	13309	13310	13311	13312	13313	13314	13315	13316	13317	13318	13319	13320	13321	13322	13323	13324	13325	13326	13327	13328	13329	13330	13331	13332	13333	13334	13335	13336	13337	13338	13339	13340	13341	13342	13343	13344	13345	13346	13347	13348	13349	13350	13351	13352	13353	13354	13355	13356	13357	13358	13359	13360	13361	13362	13363	13364	13365	13366	13367	13368	13369	13370	13371	13372	13373	13374	13375	13376	13377	13378	13379	13380	13381	13382	13383	13384	13385	13386	13387	13388	13389	13390	13391	13392	13393	13394	13395	13396	13397	13398	13399	13400	13401	13402	13403	13404	13405	13406	13407	13408	13409	13410	13411	13412	13413	13414	13415	13416	13417	13418	13419	13420	13421	13422	13423	13424	13425	13426	13427	13428	13429	13430	13431	13432	13433	13434	13435	13436	13437	13438	13439	13440	13441	13442	13443	13444	13445	13446	13447	13448	13449	13450	13451	13452	13453	13454	13455	13456	13457	13458	13459	13460	13461	13462	13463	13464	13465	13466	13467	13468	13469	13470	13471	13472	13473	13474	13475	13476	13477	13478	13479	13480	13481	13482	13483	13484	13485	13486	13487	13488	13489	13490	13491	13492	13493	13494	13495	13496	13497	13498	13499	13500	13501	13502	13503	13504	13505	13506	13507	13508	13509	13510	13511	13512	13513	13514	13515	13516	13517	13518	13519	13520	13521	13522	13523	13524	13525	13526	13527	13528	13529	13530	13531	13532	13533	13534	13535	13536	13537	13538	13539	13540	13541	13542	13543	13544	13545	13546	13547	13548	13549	13550	13551	13552	13553	13554	13555	13556	13557	13558	13559	13560	13561	13562	13563	13564	13565	13566	13567	13568	13569	13570	13571	13572	13573	13574	13575	13576	13577	13578	13579	13580	13581	13582	13583	13584	13585	13586	13587	13588	13589	13590	13591	13592	13593	13594	13595	13596	13597	13598	13599	13600	13601	13602	13603	13604	13605	13606	13607	13608	13609	13610	13611	13612	13613	13614	13615	13616	13617	13618	13619	13620	13621	13622	13623	13624	13625	13626	13627	13628	13629	13630	13631	13632	13633	13634	13635	13636	13637	13638	13639	13640	13641	13642	13643	13644	13645	13646	13647	13648	13649	13650	13651	13652	13653	13654	13655	13656	13657	13658	13659	13660	13661	13662	13663	13664	13665	13666	13667	13668	13669	13670	13671	13672	13673	13674	13675	13676	13677	13678	13679	13680	13681	13682	13683	13684	13685	13686	13687	13688	13689	13690	13691	13692	13693	13694	13695	13696	13697	13698	13699	13700	13701	13702	13703	13704	13705	13706	13707	13708	13709	13710	13711	13712	13713	13714	13715	13716	13717	13718	13719	13720	13721	13722	13723	13724	13725	13726	13727	13728	13729	13730	13731	13732	13733	13734	13735	13736	13737	13738	13739	13740	13741	13742	13743	13744	13745	13746	13747	13748	13749	13750	13751	13752	13753	13754	13755	13756	13757	13758	13759	13760	13761	13762	13763	13764	13765	13766	13767	13768	13769	13770	13771	13772	13773	13774	13775	13776	13777	13778	13779	13780	13781	13782	13783	13784	13785	13786	13787	13788	13789	13790	13791	13792	13793	13794	13795	13796	13797	13798	13799	13800	13801	13802	13803	13804	13805	13806	13807	13808	13809	13810	13811	13812	13813	13814	13815	13816	13817	13818	13819	13820	13821	13822	13823	13824	13825	13826	13827	13828	13829	13830	13831	13832	13833	13834	13835	13836	13837	13838	13839	13840	13841	13842	13843	13844	13845	13846	13847	13848	13849	13850	13851	13852	13853	13854	13855	13856	13857	13858	13859	13860	13861	13862	13863	13864	13865	13866	13867	13868	13869	13870	13871	13872	13873	13874	13875	13876	13877	13878	13879	13880	13881	13882	13883	13884	13885	13886	13887	13888	13889	13890	13891	13892	13893	13894	13895	13896	13897	13898	13899	13900	13901	13902	13903	13904	13905	13906	13907	13908	13909	13910	13911	13912	13913	13914	13915	13916	13917	13918	13919	13920	13921	13922	13923	13924	13925	13926	13927	13928	13929	13930	13931	13932	13933	13934	13935	13936	13937	13938	13939	13940	13941	13942	13943	13944	13945	13946	13947	13948	13949	13950	13951	13952	13953	13954	13955	13956	13957	13958	13959	13960	13961	13962	13963	13964	13965	13966	13967	13968	13969	13970	13971	13972	13973	13974	13975	13976	13977	13978	13979	13980	13981	13982	13983	13984	13985	13986	13987	13988	13989	13990	13991	13992	13993	13994	13995	13996	13997	13998	13999	14000	14001	14002	14003	14004	14005	14006	14007	14008	14009	14010	14011	14012	14013	14014	14015	14016	14017	14018	14019	14020	14021	14022	14023	14024	14025	14026	14027	14028	14029	14030	14031	14032	14033	14034	14035	14036	14037	14038	14039	14040	14041	14042	14043	14044	14045	14046	14047	14048	14049	14050	14051	14052	14053	14054	14055	14056	14057	14058	14059	14060	14061	14062	14063	14064	14065	14066	14067	14068	14069	14070	14071	14072	14073	14074	14075	14076	14077	14078	14079	14080	14081	14082	14083	14084	14085	14086	14087	14088	14089	14090	14091	14092	14093	14094	14095	14096	14097	14098	14099	14100	14101	14102	14103	14104	14105	14106	14107	14108	14109	14110	14111	14112	14113	14114	14115	14116	14117	14118	14119	14120	14121	14122	14123	14124	14125	14126	14127	14128	14129	14130	14131	14132	14133	14134	14135	14136	14137	14138	14139	14140	14141	14142	14143	14144	14145	14146	14147	14148	14149	14150	14151	14152	14153	14154	14155	14156	14157	14158	14159	14160	14161	14162	14163	14164	14165	14166	14167	14168	14169	14170	14171	14172	14173	14174	14175	14176	14177	14178	14179	14180	14181	14182	14183	14184	14185	14186	14187	14188	14189	14190	14191	14192	14193	14194	14195	14196	14197	14198	14199	14200	14201	14202	14203	14204	14205	14206	14207	14208	14209	14210	14211	14212	14213	14214	14215	14216	14217	14218	14219	14220	14221	14222	14223	14224	14225	14226	14227	14228	14229	14230	14231	14232	14233	14234	14235	14236	14237	14238	14239	14240	14241	14242	14243	14244	14245	14246	14247	14248	14249	14250	14251	14252	14253	14254	14255	14256	14257	14258	14259	14260	14261	14262	14263	14264	14265	14266	14267	14268	14269	14270	14271	14272	14273	14274	14275	14276	14277	14278	14279	14280	14281	14282	14283	14284	14285	14286	14287	14288	14289	14290	14291	14292	14293	14294	14295	14296	14297	14298	14299	14300	14301	14302	14303	14304	14305	14306	14307	14308	14309	14310	14311	14312	14313	14314	14315	14316	14317	14318	14319	14320	14321	14322	14323	14324	14325	14326	14327	14328	14329	14330	14331	14332	14333	14334	14335	14336	14337	14338	14339	14340	14341	14342	14343	14344	14345	14346	14347	14348	14349	14350	14351	14352	14353	14354	14355	14356	14357	14358	14359	14360	14361	14362	14363	14364	14365	14366	14367	14368	14369	14370	14371	14372	14373	14374	14375	14376	14377	14378	14379	14380	14381	14382	14383	14384	14385	14386	14387	14388	14389	14390	14391	14392	14393	14394	14395	14396	14397	14398	14399	14400	14401	14402	14403	14404	14405	14406	14407	14408	14409	14410	14411	14412	14413	14414	14415	14416	14417	14418	14419	14420	14421	14422	14423	14424	14425	14426	14427	14428	14429	14430	14431	14432	14433	14434	14435	14436	14437	14438	14439	14440	14441	14442	14443	14444	14445	14446	14447	14448	14449	14450	14451	14452	14453	14454	14455	14456	14457	14458	14459	14460	14461	14462	14463	14464	14465	14466	14467	14468	14469	14470	14471	14472	14473	14474	14475	14476	14477	14478	14479	14480	14481	14482	14483	14484	14485	14486	14487	14488	14489	14490	14491	14492	14493	14494	14495	14496	14497	14498	14499	14500	14501	14502	14503	14504	14505	14506	14507	14508	14509	14510	14511	14512	14513	14514	14515	14516	14517	14518	14519	14520	14521	14522	14523	14524	14525	14526	14527	14528	14529	14530	14531	14532	14533	14534	14535	14536	14537	14538	14539	14540	14541	14542	14543	14544	14545	14546	14547	14548	14549	14550	14551	14552	14553	14554	14555	14556	14557	14558	14559	14560	14561	14562	14563	14564	14565	14566	14567	14568	14569	14570	14571	14572	14573	14574	14575	14576	14577	14578	14579	14580	14581	14582	14583	14584	14585	14586	14587	14588	14589	14590	14591	14592	14593	14594	14595	14596	14597	14598	14599	14600	14601	14602	14603	14604	14605	14606	14607	14608	14609	14610	14611	14612	14613	14614	14615	14616	14617	14618	14619	14620	14621	14622	14623	14624	14625	14626	14627	14628	14629	14630	14631	14632	14633	14634	14635	14636	14637	14638	14639	14640	14641	14642	14643	14644	14645	14646	14647	14648	14649	14650	14651	14652	14653	14654	14655	14656	14657	14658	14659	14660	14661	14662	14663	14664	14665	14666	14667	14668	14669	14670	14671	14672	14673	14674	14675	14676	14677	14678	14679	14680	14681	14682	14683	14684	14685	14686	14687	14688	14689	14690	14691	14692	14693	14694	14695	14696	14697	14698	14699	14700	14701	14702	14703	14704	14705	14706	14707	14708	14709	14710	14711	14712	14713	14714	14715	14716	14717	14718	14719	14720	14721	14722	14723	14724	14725	14726	14727	14728	14729	14730	14731	14732	14733	14734	14735	14736	14737	14738	14739	14740	14741	14742	14743	14744	14745	14746	14747	14748	14749	14750	14751	14752	14753	14754	14755	14756	14757	14758	14759	14760	14761	14762	14763	14764	14765	14766	14767	15020	15027	15028	15029	15030	15031	15032	15033	15034	15035	15036	15037	15038	15039	15040	15041	15042],21)=NaN;
                    output([2073	2074	2075	2076	2077	2078	2079	2080	2081	2082	2083	2084	2085	2086	2087	2088	2089	2090	2091	2092	2093	2094	2095	2096	2097	2098	2099	2100	2101	2102	2103	2104	2105	2106	2107	2108	2109	2110	2111	2112	2113	2114	2115	2116	2117	2118	2119	2120	2121	2122	2123	2124	2125	2752	2753	2754	2755	2756	2757	2758	2759	2761	2763	2764	3045	3046	3047	3048	3049	3050	3051	3052	3053	3054	3055	3056	3057	3058	3059	3060	4176	4178	4179	4180	4181	4182	4183	4184	4185	4186	4240	4245	4247	4248	4250	4254	4255	4256	4257	4258	4259	4260	4261	4262	4266	4404	4405	4406	4407	4411	4412	4413	4420	4421	4422	4425	4428	4773	4774	4775	4816	4817	4818	4819	4820	4821	4822	4823	4824	4825	4826	4827	4828	4829	6754	6755	6756	6757	6758	6759	6760	6761	6762	6763	6764	6765	6766	6767	6768	6769	6770	6771	6772	6773	6774	6776	6777	6778	6779	6780	6781	6782	6784	6785	6786	6787	6788	6789	6791	6792	6793	6795	6797	6798	6799	6800	6801	6802	6803	6804	6805	6806	6807	6808	6809	6810	6811	6812	6813	6814	6815	6816	6817	6818	7128	7129	7130	7131	7132	7133	7934	7935	7936	7937	7938	7939	7940	7941	7942	7943	7944	7945	7946	7947	7948	7949	7950	7951	7952	7953	7954	7955	7956	7957	7958	7959	7960	7961	7962	7963	7964	7965	7966	7967	7968	7969	7970	7971	7972	7973	7974	7975	7976	7977	7978	7979	7980	7981	7982	7983	7984	7985	7986	7987	7988	7989	7990	7991	7992	7993	7994	7995	7996	7997	7998	7999	8000	8001	8002	8003	8004	8005	8006	8007	8008	8009	8010	8011	8012	8013	8014	8015	8016	8017	8018	8019	8020	8021	8022	8023	8024	8025	8026	8027	8028	8029	8030	8031	8032	8033	8034	8035	8036	8037	8038	8039	8040	8041	8042	8043	8044	8045	8046	8047	8048	8049	8050	8051	8052	8053	8054	8055	8056	8057	8058	8059	8060	8061	8062	8063	8064	8065	8066	8067	8068	8069	8070	11902	11903	11904	11905	11906	11907	11908	11909	11910	11911	11912	11913	11914	11915	11916	11917	11918	11919	11920	11921	11922	11923	11924	11925	11926	11927	11928	11929	11930	11931	11932	11933	11934	11935	11936	11937	11938	11939	11940	11941	11942	11943	11944	11945	11946	11947	11948	11949	11950	11951	11952	11953	11954	11955	11956	11957	11958	11959	11960	11961	11962	11963	11964	11965	11966	11967	11968	11969	11970	11971	11972	11973	11974	11975	11976	11977	11978	11979	11980	11981	11982	11983	11984	11985	11986	11987	11988	11989	11990	11991	11992	11993	11994	11995	11996	11997	11998	11999	12000	12001	12002	12003	12004	12005	12006	12007	12008	12009	12010	12011	12012	12013	12014	12015	12016	12017	12018	12019	12020	12021	12022	12023	12024	12025	12026	12027	12028	12029	12030	12031	12032	12033	12034	12035	12036	12037	12038	12039	12040	12041	12042	12043	12044	12045	12046	12047	12048	12049	12050	12051	12052	12053	12054	12055	12056	12057	12058	12059	12060	12061	12062	12063	12064	12065	12066	12067	12068	12069	12070	12071	12072	12073	12074	12075	12076	12077	12078	12079	12080	12081	12082	12083	12084	12085	12086	12087	12088	12089	12090	12091	12092	12093	12094	12095	12096	12097	12098	12099	12100	12101	12102	12103	12104	12105	12106	12107	12108	12109	12110	12111	12112	12113	12114	12115	12116	12117	12118	12119	12120	12121	12122	12123	12124	12125	12126	12127	12128	12129	12130	12131	12132	12133	12134	12135	12136	12137	12138	12139	12140	12141	12142	12143	12144	12145	12146	12147	12148	12149	12150	12151	12152	12153	12154	12155	12156	12157	12158	12159	12160	12161	12162	12163	12164	12165	12166	12167	12168	12169	12170	12171	12172	12173	12174	12175	12176	12177	12178	12179	12180	12181	12182	12183	12184	12185	12186	12187	12188	12189	12190	12191	12192	12193	12194	12195	12196	12197	12198	12199	12200	12201	12202	12203	12204	12205	12206	12207	12208	12209	12210	12211	12212	12213	12214	12215	12216	12217	12218	12219	12220	12221	12222	12223	12224	12225	12226	12227	12228	12229	12230	12231	12232	12233	12234	12235	12236	12237	12238	12239	12240	12241	12242	12243	12244	12245	12246	12247	12248	12249	12250	12251	12252	12253	12254	12255	12256	12257	12258	12259	12260	12261	12262	12263	12264	12265	12266	12267	12268	12269	12270	12271	12272	12273	12274	12275	12276	12277	12278	12279	12280	12281	12282	12283	12284	12285	12286	12287	12288	12289	12290	12291	12292	12293	12294	12295	12296	12297	12298	12299	12300	12301	12302	12303	12304	12305	12306	12307	12308	12309	12310	12311	12312	12313	12314	12315	12316	12317	12318	12319	12320	12321	12322	12323	12324	12325	12326	12327	12328	12329	12330	12331	12332	12333	12334	12335	12336	12337	12338	12339	12340	12341	12342	12343	12344	12345	12346	12347	12348	12349	12350	12351	12352	12353	12354	12355	12356	12357	12358	12359	12360	12361	12362	12363	12364	12365	12366	12367	12368	12369	12370	12371	12372	12373	12374	12375	12376	12377	12378	12379	12380	12381	12382	12383	12384	12385	12386	12387	12388	12389	12390	12391	12392	12393	12394	12395	12396	12397	12398	12399	12400	12401	12402	12403	12404	12405	12406	12407	12408	12409	12410	12411	12412	12413	12414	12415	12416	12417	12418	12419	12420	12421	12422	12423	12424	12425	12426	12427	12428	12429	12430	12431	12432	12433	12434	12435	12436	12437	12438	12439	12440	12441	12442	12443	12444	12445	12446	12447	12448	12449	12450	12451	12452	12453	12454	12455	12456	12457	12458	12459	12460	12461	12462	12463	12464	12465	12466	12467	12468	12469	12470	12471	12472	12473	12474	12475	12476	12477	12478	12479	12480	12481	12482	12483	12484	12485	12486	12487	12488	12489	12490	12491	12492	12493	12494	12495	12496	12497	12498	12499	12500	12501	12502	12503	12504	12505	12506	12507	12508	12509	12510	12511	12512	12513	12514	12515	12516	12517	12518	12519	12520	12521	12522	12523	12524	12525	12526	12527	12528	12529	12530	12531	12532	12533	12534	12535	12536	12537	12538	12539	12540	12541	12542	12543	12544	12545	12546	12547	12548	12549	12550	12551	12552	12553	12554	12555	12556	12557	12558	12559	12560	12561	12562	12563	12564	12565	12566	12567	12568	12569	12570	12571	12572	12573	12574	12575	12576	12577	12578	12579	12580	12581	12582	12583	12584	12585	12586	12587	12588	12589	12590	12591	12592	12593	12594	12595	12596	12597	12598	12599	12600	12601	12602	12603	12604	12605	12606	12607	12608	12609	12610	12611	12612	12613	12614	12615	12616	12617	12618	12619	12620	12621	12622	12623	12624	12625	12626	12627	12628	12629	12630	12631	12632	12633	12634	12635	12636	12637	12638	12639	12640	12641	12642	12643	12644	12645	12646	12647	12648	12649	12650	12651	12652	12653	12654	12655	12656	12657	12658	12659	12660	12661	12662	12663	12664	12665	12666	12667	12668	12669	12670	12671	12672	12673	12674	12675	12676	12677	12678	12679	12680	12681	12682	12683	12684	12685	12686	12687	12688	12689	12690	12691	12692	12693	12694	12695	12696	12697	12698	12699	12700	12701	12702	12703	12704	12705	12706	12707	12708	12709	12710	12711	12712	12713	12714	12715	12716	12717	12718	12719	12720	12721	12722	12723	12724	12725	12726	12727	12728	12729	12730	12731	12732	12733	12734	12735	12736	12737	12738	12739	12740	12741	12742	12743	12744	12745	12746	12747	12748	12749	12750	12751	12752	12753	12754	12755	12756	12757	12758	12759	12760	12761	12762	12763	12764	12765	12766	12767	12768	12769	12770	12771	12772	12773	12774	12775	12776	12777	12778	12779	12780	12781	12782	12783	12784	12785	12786	12787	12788	12789	12790	12791	12792	12793	12794	12795	12796	12797	12798	12799	12800	12801	12802	12803	12804	12805	12806	12807	12808	12809	12810	12811	12812	12813	12814	12815	12816	12817	12818	12819	12820	12821	12822	12823	12824	12825	12826	12827	12828	12829	12830	12831	12832	12833	12834	12835	12836	12837	12838	12839	12840	12841	12842	12843	12844	12845	12846	12847	12848	12849	12850	12851	12852	12853	12854	12855	12856	12857	12858	12859	12860	12861	12862	12863	12864	12865	12866	12867	12868	12869	12870	12871	12872	12873	12874	12875	12876	12877	12878	12879	12880	12881	12882	12883	12884	12885	12886	12887	12888	12889	12890	12891	12892	12893	12894	12895	12896	12897	12898	12899	12900	12901	12902	12903	12904	12905	12906	12907	12908	12909	12910	12911	12912	12913	12914	12915	12916	12917	12918	12919	12920	12921	12922	12923	12924	12925	12926	12927	12928	12929	12930	12931	12932	12933	12934	12935	12936	12937	12938	12939	12940	12941	12942	12943	12944	12945	12946	12947	12948	12949	12950	12951	12952	12953	12954	12955	12956	12957	12958	12959	12960	12961	12962	12963	12964	12965	12966	12967	12968	12969	12970	12971	12972	12973	12974	12975	12976	12977	12978	12979	12980	12981	12982	12983	12984	12985	12986	12987	12988	12989	12990	12991	12992	12993	12994	12995	12996	12997	12998	12999	13000	13001	13002	13003	13004	13005	13006	13007	13008	13009	13010	13011	13012	13013	13014	13015	13016	13017	13018	13019	13020	13021	13022	13023	13024	13025	13026	13027	13028	13029	13030	13031	13032	13033	13034	13035	13036	13037	13038	13039	13040	13041	13042	13043	13044	13045	13046	13047	13048	13049	13050	13051	13052	13053	13054	13055	13056	13057	13058	13059	13060	13061	13062	13063	13064	13065	13066	13067	13068	13069	13070	13071	13072	13073	13074	13075	13076	13077	13078	13079	13080	13081	13082	13083	13084	13085	13086	13087	13088	13089	13090	13091	13092	13093	13094	13095	13096	13097	13098	13099	13100	13101	13102	13103	13104	13105	13106	13107	13108	13109	13110	13111	13112	13113	13114	13115	13116	13117	13118	13119	13120	13121	13122	13123	13124	13125	13126	13127	13128	13129	13130	13131	13132	13133	13134	13135	13136	13137	13138	13139	13140	13141	13142	13143	13144	13145	13146	13147	13148	13149	13150	13151	13152	13153	13154	13155	13156	13157	13158	13159	13160	13161	13162	13163	13164	13165	13166	13167	13168	13169	13170	13171	13172	13173	13174	13175	13176	13177	13178	13179	13180	13181	13182	13183	13184	13185	13186	13187	13188	13189	13190	13191	13192	13193	13194	13195	13196	13197	13198	13199	13200	13201	13202	13203	13204	13205	13206	13207	13208	13209	13210	13211	13212	13213	13214	13215	13216	13217	13218	13219	13220	13221	13222	13223	13224	13225	13226	13227	13228	13229	13230	13231	13232	13233	13234	13235	13236	13237	13238	13239	13240	13241	13242	13243	13244	13245	13246	13247	13248	13249	13250	13251	13252	13253	13254	13255	13256	13257	13258	13259	13260	13261	13262	13263	13264	13265	13266	13267	13268	13269	13270	13271	13272	13273	13274	13275	13276	13277	13278	13279	13280	13281	13282	13283	13284	13285	13286	13287	13288	13289	13290	13291	13292	13293	13294	13295	13296	13297	13298	13299	13300	13301	13302	13303	13304	13305	13306	13307	13308	13309	13310	13311	13312	13313	13314	13315	13316	13317	13318	13319	13320	13321	13322	13323	13324	13325	13326	13327	13328	13329	13330	13331	13332	13333	13334	13335	13336	13337	13338	13339	13340	13341	13342	13343	13344	13345	13346	13347	13348	13349	13350	13351	13352	13353	13354	13355	13356	13357	13358	13359	13360	13361	13362	13363	13364	13365	13366	13367	13368	13369	13370	13371	13372	13373	13374	13375	13376	13377	13378	13379	13380	13381	13382	13383	13384	13385	13386	13387	13388	13389	13390	13391	13392	13393	13394	13395	13396	13397	13398	13399	13400	13401	13402	13403	13404	13405	13406	13407	13408	13409	13410	13411	13412	13413	13414	13415	13416	13417	13418	13419	13420	13421	13422	13423	13424	13425	13426	13427	13428	13429	13430	13431	13432	13433	13434	13435	13436	13437	13438	13439	13440	13441	13442	13443	13444	13445	13446	13447	13448	13449	13450	13451	13452	13453	13454	13455	13456	13457	13458	13459	13460	13461	13462	13463	13464	13465	13466	13467	13468	13469	13470	13471	13472	13473	13474	13475	13476	13477	13478	13479	13480	13481	13482	13483	13484	13485	13486	13487	13488	13489	13490	13491	13492	13493	13494	13495	13496	13497	13498	13499	13500	13501	13502	13503	13504	13505	13506	13507	13508	13509	13510	13511	13512	13513	13514	13515	13516	13517	13518	13519	13520	13521	13522	13523	13524	13525	13526	13527	13528	13529	13530	13531	13532	13533	13534	13535	13536	13537	13538	13539	13540	13541	13542	13543	13544	13545	13546	13547	13548	13549	13550	13551	13552	13553	13554	13555	13556	13557	13558	13559	13560	13561	13562	13563	13564	13565	13566	13567	13568	13569	13570	13571	13572	13573	13574	13575	13576	13577	13578	13579	13580	13581	13582	13583	13584	13585	13586	13587	13588	13589	13590	13591	13592	13593	13594	13595	13596	13597	13598	13599	13600	13601	13602	13603	13604	13605	13606	13607	13608	13609	13610	13611	13612	13613	13614	13615	13616	13617	13618	13619	13620	13621	13622	13623	13624	13625	13626	13627	13628	13629	13630	13631	13632	13633	13634	13635	13636	13637	13638	13639	13640	13641	13642	13643	13644	13645	13646	13647	13648	13649	13650	13651	13652	13653	13654	13655	13656	13657	13658	13659	13660	13661	13662	13663	13664	13665	13666	13667	13668	13669	13670	13671	13672	13673	13674	13675	13676	13677	13678	13679	13680	13681	13682	13683	13684	13685	13686	13687	13688	13689	13690	13691	13692	13693	13694	13695	13696	13697	13698	13699	13700	13701	13702	13703	13704	13705	13706	13707	13708	13709	13710	13711	13712	13713	13714	13715	13716	13717	13718	13719	13720	13721	13722	13723	13724	13725	13726	13727	13728	13729	13730	13731	13732	13733	13734	13735	13736	13737	13738	13739	13740	13741	13742	13743	13744	13745	13746	13747	13748	13749	13750	13751	13752	13753	13754	13755	13756	13757	13758	13759	13760	13761	13762	13763	13764	13765	13766	13767	13768	13769	13770	13771	13772	13773	13774	13775	13776	13777	13778	13779	13780	13781	13782	13783	13784	13785	13786	13787	13788	13789	13790	13791	13792	13793	13794	13795	13796	13797	13798	13799	13800	13801	13802	13803	13804	13805	13806	13807	13808	13809	13810	13811	13812	13813	13814	13815	13816	13817	13818	13819	13820	13821	13822	13823	13824	13825	13826	13827	13828	13829	13830	13831	13832	13833	13834	13835	13836	13837	13838	13839	13840	13841	13842	13843	13844	13845	13846	13847	13848	13849	13850	13851	13852	13853	13854	13855	13856	13857	13858	13859	13860	13861	13862	13863	13864	13865	13866	13867	13868	13869	13870	13871	13872	13873	13874	13875	13876	13877	13878	13879	13880	13881	13882	13883	13884	13885	13886	13887	13888	13889	13890	13891	13892	13893	13894	13895	13896	13897	13898	13899	13900	13901	13902	13903	13904	13905	13906	13907	13908	13909	13910	13911	13912	13913	13914	13915	13916	13917	13918	13919	13920	13921	13922	13923	13924	13925	13926	13927	13928	13929	13930	13931	13932	13933	13934	13935	13936	13937	13938	13939	13940	13941	13942	13943	13944	13945	13946	13947	13948	13949	13950	13951	13952	13953	13954	13955	13956	13957	13958	13959	13960	13961	13962	13963	13964	13965	13966	13967	13968	13969	13970	13971	13972	13973	13974	13975	13976	13977	13978	13979	13980	13981	13982	13983	13984	13985	13986	13987	13988	13989	13990	13991	13992	13993	13994	13995	13996	13997	13998	13999	14000	14001	14002	14003	14004	14005	14006	14007	14008	14009	14010	14011	14012	14013	14014	14015	14016	14017	14018	14019	14020	14021	14022	14023	14024	14025	14026	14027	14028	14029	14030	14031	14032	14033	14034	14035	14036	14037	14038	14039	14040	14041	14042	14043	14044	14045	14046	14047	14048	14049	14050	14051	14052	14053	14054	14055	14056	14057	14058	14059	14060	14061	14062	14063	14064	14065	14066	14067	14068	14069	14070	14071	14072	14073	14074	14075	14076	14077	14078	14079	14080	14081	14082	14083	14084	14085	14086	14087	14088	14089	14090	14091	14092	14093	14094	14095	14096	14097	14098	14099	14100	14101	14102	14103	14104	14105	14106	14107	14108	14109	14110	14111	14112	14113	14114	14115	14116	14117	14118	14119	14120	14121	14122	14123	14124	14125	14126	14127	14128	14129	14130	14131	14132	14133	14134	14135	14136	14137	14138	14139	14140	14141	14142	14143	14144	14145	14146	14147	14148	14149	14150	14151	14152	14153	14154	14155	14156	14157	14158	14159	14160	14161	14162	14163	14164	14165	14166	14167	14168	14169	14170	14171	14172	14173	14174	14175	14176	14177	14178	14179	14180	14181	14182	14183	14184	14185	14186	14187	14188	14189	14190	14191	14192	14193	14194	14195	14196	14197	14198	14199	14200	14201	14202	14203	14204	14205	14206	14207	14208	14209	14210	14211	14212	14213	14214	14215	14216	14217	14218	14219	14220	14221	14222	14223	14224	14225	14226	14227	14228	14229	14230	14231	14232	14233	14234	14235	14236	14237	14238	14239	14240	14241	14242	14243	14244	14245	14246	14247	14248	14249	14250	14251	14252	14253	14254	14255	14256	14257	14258	14259	14260	14261	14262	14263	14264	14265	14266	14267	14268	14269	14270	14271	14272	14273	14274	14275	14276	14277	14278	14279	14280	14281	14282	14283	14284	14285	14286	14287	14288	14289	14290	14291	14292	14293	14294	14295	14296	14297	14298	14299	14300	14301	14302	14303	14304	14305	14306	14307	14308	14309	14310	14311	14312	14313	14314	14315	14316	14317	14318	14319	14320	14321	14322	14323	14324	14325	14326	14327	14328	14329	14330	14331	14332	14333	14334	14335	14336	14337	14338	14339	14340	14341	14342	14343	14344	14345	14346	14347	14348	14349	14350	14351	14352	14353	14354	14355	14356	14357	14358	14359	14360	14361	14362	14363	14364	14365	14366	14367	14368	14369	14370	14371	14372	14373	14374	14375	14376	14377	14378	14379	14380	14381	14382	14383	14384	14385	14386	14387	14388	14389	14390	14391	14392	14393	14394	14395	14396	14397	14398	14399	14400	14401	14402	14403	14404	14405	14406	14407	14408	14409	14410	14411	14412	14413	14414	14415	14416	14417	14418	14419	14420	14421	14422	14423	14424	14425	14426	14427	14428	14429	14430	14431	14432	14433	14434	14435	14436	14437	14438	14439	14440	14441	14442	14443	14444	14445	14446	14447	14448	14449	14450	14451	14452	14453	14454	14455	14456	14457	14458	14459	14460	14461	14462	14463	14464	14465	14466	14467	14468	14469	14470	14471	14472	14473	14474	14475	14476	14477	14478	14479	14480	14481	14482	14483	14484	14485	14486	14487	14488	14489	14490	14491	14492	14493	14494	14495	14496	14497	14498	14499	14500	14501	14502	14503	14504	14505	14506	14507	14508	14509	14510	14511	14512	14513	14514	14515	14516	14517	14518	14519	14520	14521	14522	14523	14524	14525	14526	14527	14528	14529	14530	14531	14532	14533	14534	14535	14536	14537	14538	14539	14540	14541	14542	14543	14544	14545	14546	14547	14548	14549	14550	14551	14552	14553	14554	14555	14556	14557	14558	14559	14560	14561	14562	14563	14564	14565	14566	14567	14568	14569	14570	14571	14572	14573	14574	14575	14576	14577	14578	14579	14580	14581	14582	14583	14584	14585	14586	14587	14588	14589	14590	14591	14592	14593	14594	14595	14596	14597	14598	14599	14600	14601	14602	14603	14604	14605	14606	14607	14608	14609	14610	14611	14612	14613	14614	14615	14616	14617	14618	14619	14620	14621	14622	14623	14624	14625	14626	14627	14628	14629	14630	14631	14632	14633	14634	14635	14636	14637	14638	14639	14640	14641	14642	14643	14644	14645	14646	14647	14648	14649	14650	14651	14652	14653	14654	14655	14656	14657	14658	14659	14660	14661	14662	14663	14664	14665	14666	14667	14668	14669	14670	14671	14672	14673	14674	14675	14676	14677	14678	14679	14680	14681	14682	14683	14684	14685	14686	14687	14688	14689	14690	14691	14692	14693	14694	14695	14696	14697	14698	14699	14700	14701	14702	14703	14704	14705	14706	14707	14708	14709	14710	14711	14712	14713	14714	14715	14716	14717	14718	14719	14720	14721	14722	14723	14724	14725	14726	14727	14728	14729	14730	14731	14732	14733	14734	14735	14736	14737	14738	14739	14740	14741	14742	14743	14744	14745	14746	14747	14748	14749	14750	14751	14752	14753	14754	14755	14756	14757	14758	14759	14760	14761	14762	14763	14764	14765	14766	14767	15020	15027	15028	15029	15030	15031	15032	15033	15034	15035	15036	15037	15038	15039	15040	15041	15042],22)=NaN;
                    output([2094	2095	2099	2135	2136	2139	2231	2232	2235	2256	2279	2280	2294	2295	2296	2392	2433	2679	4494	6340	7926	8129	8130	8131	8283	8284	8285	8286	8287	8288	8289	8290	8291	8292	8293	8294	8295	8296	8297	8298	8299	8300	8301	8302	8303	8304	8305	8306	8307	8308	8309	8310	8311	8312	8313	8314	8315	8316	8317	8318	8319	8320	8321	8322	8323	8324	8325	8326	8327	8328	8329	8330	8331	8332	8333	8334	8335	8336	8337	8338	8339	8340	8341	8342	8343	8344	8345	8346	8347	8348	8349	8350	8351	8352	8353	8354	8355	8356	8357	8358	8359	8360	8361	8362	8363	8364	8365	8366	8367	8368	8369	8370	8371	8372	8373	8374	8375	8376	8377	8378	8379	8380	8381	8382	8383	8384	8385	8386	8387	8388	8389	8390	8391	8392	8393	8394	8395	8396	8397	8398	8399	8400	8401	8402	8403	8404	8405	8406	8407	8408	8409	8410	8411	8412	8413	8414	8415	8416	8417	8418	8419	8420	8421	8422	8423	8424	8425	8426	8427	8428	8429	8430	8431	8432	8433	8434	8435	8436	8437	8438	8439	8440	8441	8442	8443	8444	8445	8446	8447	8448	10444	10445	10446	10447	10448	10449	10450	10451	10452	10453	10454	10455	10456	10457	10458	10459	10460	10461	10462	10463	10464	10465	10466	10467	10468	10469	10470	10471	10472	10473	10474	10475	10476	10477	10478	10479	10480	10481	10482	10483	10484	10485	10486	10487	10488	10489	10490	10491	10492	10493	10494	10495	10496	10497	10498	10499	10500	10501	10502	10503	10504	10505	10506	10507	10508	10509	10510	10511	10512	10513	10514	10515	10516	10517	10518	10519	10520	10521	10522	10523	10524	10525	10526	10527	10528	10529	10530	10531	10532	10533	10534	10535	10536	10537	10538	10539	10540	10541	10542	10543	10544	10545	10546	10547	10548	10549	10550	10551	10552],28)=NaN;
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
                 case '2025' 
                    bad_co2 = find(output(:,17) > 399.9999 & output(:,17) < 400.001);
                    bad_h2o = find(output(:,18) > 22.4999 & output(:,18) < 22.5001);
                    output(bad_co2,[1 17]) = NaN;
                    output(bad_h2o,[5 18]) = NaN;
                    bad_csat = find(output(:,19) > -0.001 & output(:,19) < 0.001);
                    output(bad_csat,[19:26]) = NaN;  
                    output([1999	2000	2002	2961 2001	2296	2680	2961],1)=NaN;
                    output([13	847	1491	1492	1493	1499	2071	2296	2757	3764],2)=NaN;
                    output([14	15	27	838	839	848	849	855	1493	1500	2757	2769	2774	3076	3088	3728	3765	3943],3)=NaN;
                    output([13	558	560	594	1370	1528	1635	1900	1998	1999	2000	2001	2002	2003	2026	2045	2296	2680	2720	2778	2793	2821	2866	2961	2963	3229	3254	3258	3589	3759	3868	4169],7)=NaN;
                    output([849	2757],16)=NaN;
                    output([26	27	2757	2759	2760	3088	3944],19)=NaN;
                    output([26	27	2240	2250	2252	2253	2272	2273	2274	2280	2281	2759],20)=NaN;
                    output([14	853	2071	4121],21)=NaN;
                    output([416	417	418	419	420	2098	2099	2100	2101	2102	2103	2104	2105	2106	2107	2108	2109	2110	2111	2112	2113	2114	2115	2116	2117	2118	2119	2120	2121	2122	2123	2124	2125	2126	2127	2128	2129	2130	2131	2132	2133	2134	2135	2136	2137	2138	2139	2140	2141	2142	2143	2144	2145	2146	2147	2148	2149	2150	2151	2152	2153	2154	2155	2156	2157	2158	2159	2160	2161	2162	2163	2164	2165	2166	2167	2168	2169	2170	2171	2172	2173	2174	2175	2176	2177	2178	2179	2180	2181	2182	2183	2184	2185	2186	2187	2188	2189	2190	2191	2192	2193	2194	2195	2196	2197	2198	2199	2200	2201	2202	2203	2204	2205	2206	2207	2208	2209	2210	2211	2212	2213	2214	2215	2216	2217	2218	2219	2220	2221	2222	2223	2224	2225	2226	2227	2228	2229	2230	2231	2232	2233	2234	2235	2236	2237	2238	2239	2240	2241	2242	2243	2244	2245	2246	2247	2248	2249	2250	2251	2252	2253	2254	2255	2256	2257	2258	2259	2260	2261	2262	2263	2264	2265	2266	2267	2268	2269	2270	2271	2272	2273	2274	2275	2276	2277	2278	2279	2280	2281	2282	2283	2284	2285	2286	2287	2288	2289	2290	2291	2292	2293	2294	2295	3727],27)=NaN;
                    output([416	1607	1617	1618	1619],28)=NaN;
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
        output([8683	8685	8686	8771	8791	8822	8862	8863	8912	9013	9036	9057	9093	9205	9235	9297	9397	9427	9465	9644	9645	9735	9955	9956	9992	10121	10167	10229	10276	10278	10281	10306	10347	10351	10356	10369	10402	10502	10573	10595	10625	10626	10641	10642	10643	10670	10671	10691	10712	10716	10751	10789	10808	11039	11140	11173	11192	11249	11268	11301	11382	11386	11398	11529	11530	11544	11675	11681	11713	11766	11767	11790	11861	11892	11943	12055	12178	12181	12485	12510	12694	12780	12824	12834	12835	12839	12875	12879	12885	12887	12914	12923	12962	12965	13017	13065	13071	13080	13109	13112	13113	13119	13133	13149	13201	13202	13203	13206	13207	13208	13217	13220	13238	13253	13255	13270	13278	13283	13286	13312	13321	13328	13330	13331	13342	13351	13355	13363	13364	13365	13369	13396	13403	13451	13460	13482	13483	13508	13509	13510	13552	13555	13559	13560	13561	13562	13563	13580	13595	13631	13643	13691	13744	13781	13787	13801	13835	13852	13855	13857	13870	13874	13928	13937	13938	13939	13942	13944	13947	13970	13971	14017	14018	14037	14038	14039	14041	14042	14045	14049	14057	14059	14076	14078	14080	14081	14082	14088	14121	14122	14123	14128	14129	14133	14162	14165	14166	14175	14179	14181	14183	14186	14224	14226	14228	14229	14233	14255	14260	14261	14267	14315	14371	14372	14373	14376	14401	14402	14442	14466	14468	14474	14651	14664	14665	14679	14691 14651	14664	14665	14679	14690	14691	14747	14773	14795	14843	14891	14939	14947	15001	15002	15032	15052	15053	15083	15131	15198	15208	15209	15216	15217	15218	15219	15220	15221	15222	15223	15225	15226	15228	15233	15312	15313	15323	15327	15339	15340	15343	15345	15346	15367	15369	15371	15374	15418	15474	15515	15552	15563	15611	15659	15672	15677	15678	15679	15680	15682	15683	15690	15692	15724	15796	15798	15801	15804	15824	15825	15828	15829	15830	15831	15832	15835	15839	15852	15854	15859	15861	15869	15870	15871	15878	15947	15995	16047	16058	16061	16065	16074	16075	16080	16081	16082	16088	16089	16091	16093	16094	16112	16122	16124	16126	16133	16134	16135	16136	16153	16187	16201	16235	16249	16402	16475	16489	16490	16763	16862	16866	16952	16996	16997	16998	16999	17004	17008	17009	17010	17017	17038	17043	17088	17089	17091	17092	17093	17095	17102	17120	17121	17189	17192	17193	17198	17199	17201	17215	17216	17217	17220	17222	17225	17235	17254	17261	17272	17291	17292	17294	17310	17311	17317	17318	17319	17381	17399	17403	17404	17405	17417	17428	17429	17430	17431	17432	17433	17434	17450	17469	17489	17490	17491	17492	17503	17504	17523 9426	9488	9498	9569	9764	10045	10267	10328	10368	10392	11531	11551	11587	11672	11792	11950	11956	12020	12300	12301	12308	12692	12830	12838	13063	13139	13141	13142	13191	13239	13240	13241	13280	13284	13285	13322	13324	13325	13332	13338	13343	13350	13462	13463	13465	13468	13469	13739	13851	13856	13862	13864	13865	13871	13930	13935	13979	14010	14019	14036	14040	14046	14047	14126	14190	14251	14262	14369	14440	14443	14445	14449	14672	14673	15224	15328	15332	15334	15335	15337	15344	15347	15673	15675	15676	15681	15684	15687	15688	15689	15793	15794	15795	15797	15827	15833	15834	15837	15838	15840	15853	15855	16059	16060	16062	16064	16067	16068	16070	16077	16079	16090	16988	16989	16990	16991	16992	16993	16994	16995	17005	17014	17035	17039	17041	17097	17101	17188	17195	17196	17197	17200	17203	17204	17206	17224	17227	17228	17229	17387	17388	17389	17391	17392	17395	17402	17505	17506	17507	17508	17509	17514	17515	17516	17518	17519	17520	17521	17522	17525 7156 1070 11590 12840 15330 15136:15147],1) = NaN; %Fc
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
        output([9910	9911	11440	12399	12439	12577	12579	12929	13110	13112	13113	13114	13117 11439	11492	11530	11538	11541	11542	11666	11668	11834	11866	11868	11910	12013	12015	12072	12087	12090	12161	12305	12312	12392	12410	12433	12440	12501	12513	12514	12578	12592	12593	12667	12673	12676	12706	12734	12763	12771	12773	12855	12901	12927	12928	12974	12975	13017	13111	13116	13118	13122	13168	13210	13211	13221	13222	13227	13268	13269	13359	13484	13527	13528	13531	13573	13586	13630	13632	13633	13643	13700	13704	13730	13733	13746	13777	13790	13791	13792	13804	13808	13820	13824	13825	13826	13832	13848	13849	13853	13856	13879	13893	13906	13908	13916	13919	13920	13922	13936	13937	13982	13989	13990	14027	14042	14072	14079	14080	14084	14097	14111	14112	14126	14209	14210	14212	14214	14215	14224	14236	14255	14261	14262	14263	14269	14272	14275	14282	14283	14284	14293	14308	14309	14310	14311	14324	14333	14362	14363	14364	14365	14405	14406	14407	14411	14413	14414	14415	14425	14437	14471	14472	14475	14503	14760	14769	14771	14783	14784	14796	14801	14803	14812	14814	14843	14848	14849	14852	14853	14854	14856	14857	14929	14930	14935	14945	14949	14952	14960	15026	15028	15042	15050	15078	15079	15081	15082	15083	15122	15123	15124	15125	15146	15147	15148	15168	15175	15184	15198	15210	15211	15227	15240	15250	15295	15301 14760	14769	14771	14783	14784	14801	14803	14812	14814	14842	14843	14848	14849	14852	14853	14854	14856	14857	14880	14930	14945	14949	14952	14960	15042	15044	15050	15079	15081	15082	15083	15122	15125	15147	15148	15168	15175	15184	15185	15210	15211	15227	15240	15250	15295	15301	15323	15417	15421	15422	15423	15426	15429	15431	15433	15435	15455	15563	15573	15580	15605	15612	15614	15659	15677	15748	15766	15768	15780	15782	15790	15792	15795	15798	15799	15800	15801	15802	15807	15808	15810	15813	15837	15838	15886	15902	15905	15908	15913	15917	15919	15925	15955	16000	16001	16014	16016	16033	16087	16091	16101	16106	16107	16139	16155	16159	16196	16197	16235	16267	16289	16305	16306	16307	16331	16381	16383	16386	16388	16389	16392	16394	16395	16396	16397	16399	16402	16404	16405	16406	16442	16447	16475	16510	16511	16512	16597	16619	16676	16680	16681	16683	16684	16686	16687	16702	16715	16741	16763	16794	16811	16871	16896	16903	16904	16906	17003	17051	17099	17120	17131	17135	17143	17212	17213	17214	17216	17217	17218	17223	17250	17289	17304	17307 3008	3009	3083	3207	3208	3237	3267	3275	3282	3289	3323	3331	3337	3371	3385	3419	3467	3477	3537	3563	3578	3579	3636	3707	4497	4498	4521	4522	4523	4537	4557	4559	4614	4615	4623	4667	4763	4772	4856	4862	4864	4867	4871	4873	4875	4899	4920	4921	4922	4951	4953	4958	4969	4994	4995	4996	4997	5003	5027	5036	5039	5040	5051	5170	5191	5202	5233	5234	5235	5239	5240	5515	5545	5549	5553	5625	5626	5627	5652	5653	5654	5708	5709	5712	5714	5717	5723	5737	5771	5819	5835	5849	5850	5857	5872	5873	5875	5877	5878	5886	5893	5900	5904	5914	5919	5920	5921	5922	5925	5926	5933	5935	5937	5963	6011	6055	6066	6114	6117	6136	6155	6165	6229	6275	6300	6301	6302	6303	6304	6310	6311	6312	6347	6368	6370	6397	6420	6468	6495	6537	6584	6665	6683	6684	6692	6704	6706	6707	6709	6712	6732	6751	6752	6753	6754	6756	6760	6785	6818	6827	6849	6860	6861	6869	6917	6929	6930	6954	6990	7002	7003	7019	7033	7036	7060	7067	7074	7076	7108	7109	7135	7156	7160	7163	7170	7180	7183	7184	7214	7237	7243	7274	7286	7319	7320	7322	7327	7342	7351	7353	7355	7362	7364	7367	7369	7370	7379	7405	7407	7422	7445	7468	7514	7543	7571	7575	7576	7595	7596	7604	7616	7617	7646	7658	7688	7690	7692	7693	7717	7758	7765	7771	7806	7807	7812	7847	7856	7857	7865	7896	7924	7944	8190	8196	8213	8216	8229	8231	8243	8244	8245	8298	8314	8336	8364	8384	8385	8386	8387	8388	8390	8406	8431	8442	8444	8447	8452	8456	8460	8466	8471	8473	8480	8481	8556	8576	8611	8626	8644	8667	8672	8674	8696	8708	8754	8755	8758	8760	8778	8780	8782	8784	8817	8849	8870	8912	8915	8935	8960	8983	8990	8992	9011	9012	9013	9037	9066	9078	9102	9158	9179	9180	9181	9183	9203	9211	9275	9276	9282	9286	9287	9288	9292	9296	9300	9307	9318	9319	9320	9321	9346	9348	9349	9377	9394	9423	9435	9440	9442	9449	9450	9452	9454	9463	9466	9468	9470	9482	9535	9536	9540	9542	9588	9589	9591	9634	9667	9735	9763	9781	9807	9809	9811	9812	9813	9822	9830	9842	9853	9861	9873	9902	9909	9925	9949	9972	9991	9992	9999	10035	10036	10051	10054	10213	10244	10298	10303	11454	11509	11556	11557	11602	11603	11648	11649	11748	11793	11797	11888	11937	12129	12175	12222	12369	12591	12630	12672	12717	12726	12728	12730	12770	12783	13121 106	126	151	154	155	170	278	443	453	454	455	485	490	492	494	508	559	560	561	562	563	565	566	568	571	572	574	578	582	589	594	595	606	607	635	653	656	657	671	675	676	683	697	713	714	715	726	730	744	745	779	793	818	821	822	826	827	831	868	874	889	893	894	918	919	923	971	985	992	1019	1034	1035	1036	1227	1235	1236	1237	1243	1245	1246	1339	1340	1372	1403	1506	1515	1516	1517	1518	1519	1520	1536	1595	1609	1643	1663	1664	1689	1690	1700	1704	1711	1718	1720	1766	1768	1796	1798	1800	1879	1881	1882	2049	2096	2101	2139	2356	2357	2360	2361	2383	2393	2414	2417 40	41	42	44	59	64	119	120	121	123	458	567	570	573	575	576	590	591	655	703	720	721	722	724	725	819	871	875	1225	1226	1228	1229	1231	1239	1656	1665	1691	1693	1878	1880	3215	3347	3351	3352	3571	3581	3672	3673	3674	3679	3680	4553	4555	4558	4618	4717	4718	4719	4720	4721	4722	4731	4811	4816	4848	4849	4852	4853	4854	4855	4857	4859	4868	4870	4919	5000	5001	5002	5029	5030	5031	5033	5034	5035	5236	5237	5238	5241	5242	5243	5244	5246	5247	5622	5636	5651	5688	5691	5692	5693	5694	5696	5697	5699	5701	5702	5703	5704	5705	5706	5710	5731	5804	5807	5808	5822	5831	5833	5836	5837	5840	5882	5883	5884	5885	5894	5895	5898	5899	5901	5902	5905	5906	5924	5930	5934	6054	6057	6058	6059	6061	6062	6065	6067	6068	6071	6073	6077	6078	6080	6108	6185	6187	6188	6189	6191	6192	6299	6305	6306	6307	6308	6309	6585	6805	6981	6982	6983	6988	6996	6999	7075	7087	7100	7101	7102	7103	7106	7110	7346	7347	7348	7349	7357	7358	7363	7599	7686	7901	7911	8218	8221	8224	8441	8454	8766	8770	8771	9205	9293	9465	9472	9478	10465	10480	10481	10512	10560	10581	10582	10609	10657	10691	10692	10753	10800	10848	10887	10888	10897	10945	10988	10989	10992	11040	11089	11090	11091	11137	11184	11192	11232	11869	12008	12088	12590	12640	12686	12722	12772	12854	13219	13228	13782	13794	13795	13798	13799	13805	13806	13844	13847	13921	14076	14083	14095	14237	14250	14251	14252	14256	14257	14258	14259	14260	14273	14294	14307	14322	14323	14408	14409	14410	14412	14476	14480	14483	14495	14498	14504	14770	14774	14775	14797	14798	14799	14800	14811	14813	14855	15022	15023	15025	15031	15037	15038	15080	15093	15127	15128	15129	15130	15131	15133	15134	15165	15167	15179	15182	15186	15241	15243	15244	15249	15251	15255	15258	15259	15262	15413	15415	15416	15418	15420	15424	15425	15427	15428	15430	15434	15499	15520	15588	15589	15596	15600	15611	15613	15676	15756	15758	15761	15762	15765	15771	15772	15774	15775	15776	15779	15785	15789	15793	15794	15803	15805	15806	15890	15895	15896	15899	15900	15903	15904	15906	15914	15918	15947	15954	15956	15961	15963	16002	16003	16006	16007	16008	16010	16012	16013	16015	16029	16030	16080	16081	16088	16089	16160	16161	16268	16269	16276	16277	16290	16298	16302	16384	16385	16387	16391	16393	16398	16400	16403	16528	16533	16731	16732	16733	16734	16738	16739	16740	16746	16747	16748	16874	16876	16879	16883	17134	17142	17193	17194	17196	17203	17210	17215	17219	17220	17221	17222	17305	17312	17313	17320	17321	17322],1) = NaN;
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
        output([6390	6398	6946	6947	6949	6950	12839	12910	12917	12919	12964	13063	13065	13068	13072	13074	13110	13261	13700	13732	13740	13894	13895	13907	13912	13914	13916	14005	14204	14205	14207	14210	14229	16005	16082	16148	16343 6680	6681	10375	10771	11828	12074	12447	12448	12450	13109	13111	15312	15321 8286	8289	8310	8311	8315	8342	8367	8371	8380	8381	8382	8383	8396	8423	8462	8486	8487	8521	8614	8623	8658	8661	8662	8685	8726	8731	8733	8738	8763	8813	8843	8856	8857	8860	8887	8893	8894	8901	8902	8905	8941	8946	8957	8964	8994	9004	9011	9027	9040	9075	9129	9139	9153	9154	9155	9181	9187	9188	9206	9247	9295	9301	9303	9325	9341	9379	9384	9423	9424	9425	9432	9446	9463	9474	9478	9479	9480	9538	9547	9562	9590	9606	9611	9628	9654	9719	9725	9753	9766	9784	10008	10146	10153	10185	10190	10227	10232	10261	10292	10322	10327	10341	10371	10376	10382	10383	10386	10387	10388	10389	10390	10392	10398	10407	10427	10428	10432	10435	10473	10537	10548	10549	10550	10551	10598	10694	10818	10851	10900	10917	10986	10998	11014	11015	11058	11063	11071	11108	11111	11142	11150	11169	11170	11203	11204	11205	11206	11220	11284	11286	11313	11348	11349	11350	11351	11352	11353	11390	11474	11480	11487	11494	11508	11526	11527	11530	11553	11573	11576	11598	11600	11605	11615	11618	11730	11736	11764	11765	11814	11818	11824	11825	11826	11827	11852	11861	11864	11865	11866	11869	11872	11909	11910	11911	11912	11915	11990	11991	11993	12005	12008	12014	12015	12016	12017	12018	12021	12023	12061	12063	12067	12068	12071	12075	12101	12102	12103	12104	12105	12106	12107	12108	12112	12146	12164	12165	12170	12172	12176	12182	12201	12213	12216	12218	12219	12229	12246	12258	12259	12262	12263	12265	12268	12270	12273	12326	12349	12385	12392	12393	12400	12418	12419	12434	12438	12464	12517	12562	12575	12581	12635	12660	12664	12677	12679	12743	12759	12795	12807	12808	12810	12819	12821	12822	12832	12837	12840	12848	12886	12895	12896	12898	12909	12914	12915	12921	12922	12923	12925	12927	12953	12959	12965	12966	12971	12987	12989	12990	13058	13059	13061	13064	13067	13069	13070	13108	13115	13163	13255	13262	13263	13264	13268	13269	13270	13273	13282	13301	13364	13383	13404	13406	13407	13409	13454	13457	13465	13466	13499	13546	13552	13570	13600	13643	13669	13681	13694	13696	13699	13702	13703	13704	13707	13714	13730	13733	13738	13739	13747	13749	13776	13797	13798	13845	13875	13876	13877	13878	13879	13899	13901	13903	13905	13913	13920	13922	13923	13924	13934	13944	13952	13953	13954	13956	13957	13958	13961	13965	13968	14006	14007	14008	14009	14027	14042	14048	14049	14051	14054	14056	14060	14062	14063	14073	14074	14075	14076	14123	14171	14178	14184	14186	14187	14206	14208	14209	14212	14215	14217	14225	14230	14231	14232	14233	14236	14255	14256	14257	14258	14259	14260	14261	14262	14263	14264	14340	14342	14352	14363	14385	14403	14404	14405	14406	14407	14408	14409	14458	14460	14461	14463	14465	14468	14470	14495	14499	14500	14501	14502	14503	14506	14509	14515	14516	14517	14519	14520	14542	14546	14555	14558	14559	14561	14564	14565	14569	14570	14586	14593	14606	14607	14621	14649	14651	14652	14653	14654	14655	14657	14658	14662	14665	14666	14670	14673	14698	14699	14701	14704	14708	14709	14710	14718	14735	14740	14741	14742	14744	14746	14795	14841	14843	14845	14879	14891	14940	14945	14946	14978	14987	14999	15000	15002	15003	15026	15035	15083	15099	15100	15128	15129	15131	15165	15166	15168	15213	15214	15313	15366	15368	15369	15370	15407	15408	15410	15411	15413	15419	15471	15474	15480	15486	15488	15492	15493	15504	15505	15506	15507	15508	15515	15626	15696	15700	15702	15703	15705	15706	15707	15708	15709	15715	15718	15726	15727	15757	15761	15765	15851	15870	15872	15882	15883	15886	15891	15892	15953	15995	16007	16015	16113	16124	16131	16138	16139	16294	16299	16304	16305	16306	16310	16327	16330	16337	16445	16450	16464	16503	16509	16511	16534	16535	16537	16538	16539	16548	16556	16584	16724	16767	16786	16787	16788	16793	16796	16800	16802	16806	16824	16833	16837	16842	16843	16844	16919	16920	17075	17097	17102	17113	17116	17117	17118	17119	17121	17122	17123	17125	17126	17127	17128	17129	17130	17131	17132	17133	17134	17167	17168	17172	17174	17175	17176	17177	17178	17179	17180	17182	17183	17197	17211	17219	17260	17263	17264	17387	17435	17444	17448	17449	17450	17459	17460	17461	17464	17465	17466	17468	17470	17471	17474	17478	17479	17480	17481	17482	17483	17484	17485	17486	17487	17488	17489	17503	17504	17520 5028	5121	5169	5172	5185	5188	5243	5291	5305	5315	5316	5339	5363	5386	5479	5481	5518	5524	5533	5535	5570	5572	5577	5584	5586	5591	5607	5611	5612	5613	5700	5724	5726	5732	5771	5789	5800	5809	5814	5816	5817	5818	5865	5866	5868	5880	5888	5892	5902	5903	5904	5906	5907	5910	5959	5960	5962	5964	5969	5971	5975	6011	6044	6107	6114	6155	6203	6208	6210	6212	6213	6246	6248	6253	6255	6290	6292	6293	6294	6295	6296	6299	6303	6304	6306	6307	6310	6339	6340	6341	6342	6343	6344	6349	6354	6396	6397	6406	6423	6437	6452	6453	6491	6501	6515	6559	6612	6625	6626	6628	6635	6636	6639	6640	6644	6645	6648	6676	6678	6679	6682	6695	6698	6731	6781	6799	6847	6848	6873	6877	6921	6922	6923	6952	6953	6955	6956	6964	6965	6966	6971	6983	7004	7009	7017	7018	7074	7077	7095	7101	7114	7211	7335	7360	7362	7364	7403	7421	7431	7464	7479	7480	7481	7483	7493	7495	7496	7497	7498	7523	7526	7529	7535	7542	7543	7552	7571	7572	7591	7593	7594	7605	7614	7627	7640	7642	7645	7649	7674	7679	7680	7737	7754	7756	7757	7758	7759	7762	7770	7771	7788	7804	7826	7861	7875	7876	7877	7878	7879	7880	7883	7902	7923	7924	7925	7927	7928	7930	7931	7938	7939	7940	7941	7942	7943	7955	7956	7957	7958	7979	7994	7995	7996	7997	7998	7999	8000	8001	8002	8003	8012	8013	8014	8015	8016	8017	8018	8019	8020	8021	8022	8023	8024	8025	8027	8035	8039	8054	8219	8247	8267 2459	2476	2518	2519	2555	2564	2565	2566	2569	2651	2654	2657	2660	2661	2662	2663	2667	2668	2932	2941	2955	2956	2957	3060	3096	3139	3152	3154	3158	3164	3182	3244	3275	3345	3352	3355	3356	3358	3361	3362	3363	3364	3365	3366	3367	3369	3370	3373	3385	3395	3434	3439	3443	3444	3445	3446	3447	3471	3476	3516	3544	3545	3549	3562	3570	3573	3574	3582	3585	3607	3608	3612	3613	3616	3619	3620	3621	3624	3702	3708	3709	3710	3715	3719	3721	3724	3725	3764	3765	3774	3776	3815	3835	3839	3840	3845	3847	3850	3898	3914	3927	3943	3945	3957	3962	4003	4008	4013	4021	4026	4056	4058	4101	4294	4331	4335	4337	4339	4340	4342	4346	4398	4447	4449	4484	4485	4486	4506	4540	4571	4596	4611	4613	4615	4617	4624	4627	4630	4638	4685	4720	4721	4759	4765	4767	4768	4769	4774	4859	4870	4871	4872	4883	4900	4901	4902	4907	4926	4927	4938	4944	4949	4955	4962	4970	4972	5003	5030	5031	5034	5064	5067	5109	5122	5148 35	36	37	38	39	40	52	53	55	56	59	61	62	69	203	224	231	232	233	245	255	256	260	261	262	263	264	274	275	276	362	363	365	392	415	416	417	418	419	421	443	446	494	539	730	770	771	786	787	789	791	793	794	795	971	974	989	990	1002	1023	1057	1134	1138	1139	1141	1142	1143	1145	1147	1422	1471	1472	1487	1488	1543	1544	1545	1547	1566	1584	1621	1624	1626	1627	1628	1631	1632	1635	1636	1637	1638	1639	1640	1643	1645	1647	1651	1739	1787	1906	1907	1931	1935	1936	1939	1945	1946	1947	1975	2000	2002	2003	2005	2025	2026	2028	2029	2030	2031	2102	2104	2106	2116	2117	2118	2120	2121	2124	2125	2137	2139	2143	2219	2252	2258	2259	2266	2267	2274	2283	2288	2290	2291	2317	2318	2319	2320	2323	2324	2325	2369	2370	2374	2375	2376	2391	2395 54	57	58	60	72	225	391	401	406	420	493	665	773	774	784	785	788	790	1056	1140	1144	1148	1149	1155	1570	1575	1583	1588	1908	1934	1937	1938	1976	2024	2103	2108	2119	2122	2126	2130	2132	2135	2136	2138	2140	2141	2142	2144	2146	2147	2249	2255	2256	2281	2328	2367	2529	2550	2551	2664	2665	2666	2933	3090	3140	3148	3150	3151	3153	3162	3163	3348	3354	3475	3479	3617	3618	3622	3703	3714	3726	3729	3767	3773	3846	3853	3854	3855	3908	3915	3918	3930	3941	3946	4001	4010	4023	4047	4054	4057	4062	4067	4068	4252	4258	4270	4283	4289	4295	4305	4334	4336	4338	4511	4529	4609	4610	4616	4620	4621	4677	4679	4680	4722	4763	4764	4847	4852	4853	4858	4861	4862	4863	4868	4917	4928	4947	4951	4960	5023	5025	5029	5049	5179	5299	5303	5304	5307	5314	5317	5381	5382	5383	5384	5505	5516	5523	5525	5534	5582	5585	5792	5905	5911	5927	5930	6291	6391	6392	6507	6510	6513	6614	6619	6631	6637	6646	6696	6707	6709	6753	6951	6954	7482	7488	7489	7538	7635	7637	7677	7678	7755	7929	8004	8005	8006	8007	8008	8009	8010	8011	8739	8903	9649	14504	14562	14583	14584	14656	14844	15102	15103	15167	15169	15170	15315	15316	15317	15319	15320	15323	15324	15327	15367	15412	15714	15753	15754	15762	15868	15869	15873	15881	15885	16008	16009	16122	16137	16145	16308	16339	16532	16533	16536	16809	17076	17093	17098	17100	17103	17109	17120	17166	17173	17447	17451	17452	17454	17455	17458	17463	17467	17472	17473	17476],1) = NaN;   
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
         output([17569:end 1	19	125	126	134	135	139	140	141	155	279	282	296	298	307	324	387	406	437	438	439	441	444	448	464	500	502	504	520	522	523	527	579	588	589	594	613	614	615	641	645	646	797	846	851	1054	1057	1061	1063	1064	1078	1079	1080	1081	1082	1085	1087	1092	1093	1094	1095	1297	1507	1509	1514	1519	1530	2197	2201	2202	2315	2319	2578	2585	2712	2713	2714	2761	2776	2811	2953	2954	2955	2956	2957	2960	2962	3001	3048	3073	3120	3270	3271	3276	3295	3322	3324	3325	3326	3328	3342	3536	3538	3556	3557	3558	3559	3561	3577	3654	3655	3661	3662	3667	3734	3775	3776	3787	3817	3916	3917	3920	3922	3926	3929	3949	4112	4115	4117	4135	4148	4287	4322	4333	4334	4437	4438	4445	4446	4458	4459	4461	4462	4468	4491	4497	4498	4500	4501	4505	4506	4507	4508	4521	4522	4523	4527	4528	4530	4531	4533	4535	4536	4545	4546	4547	4554	4564	4565	4571	4601	4605	4606	4610	5191	5216	5240	5261	5263	5335	5462	5482	5528	5531	5629	5630	5631	5637	5638	5652	5692	5732	5748	5764	5790 1295	1296	1303	4934	4935	5775	5883	5909	5910	5911	5912	5913	5914	5915	5932	5941	5943	5945	5948	5949	5964	6011	6012	6014	6017	6018	6020	6022	6028	6037	6078	6128	6155	6160	6221	6245	6270	6275	6282	6299	6306	6317	6318	6320	6328	6332	6338	6340	6341	6342	6343	6401	6402	6409	6412	6413	6446	6486	6557	6585	6586	6587	6588	6592	6593	6594	6595	6596	6607	6612	6613	6620	6621	6651	6677	6679	6680	6681	6682	6683	6684	6685	6686	6687	6689	6690	6693	6696	6700	6726	6727	6732	6737	6738	6739	6741	6743	6772	6774	6782	6785	6794	6822	6856	6867	6875	6880	6935	6975	6988	7020	7021	7027	7029	7033	7041	7060	7103	7111	7116	7147	7159	7160	7166	7167	7168	7169	7170	7171	7172	7173	7185	7191	7207	7263	7313	7350	7351	7353	7354	7355	7366	7369	7371	7373	7406	7450	7452	7457	7459	7461	7490	7491	7492	7493	7494	7495	7496	7498	7500	7501	7502	7503	7507	7509	7510	7511	7522	7547	7572	7616	7623	7625	7633	7638	7682	7769	7805	7843	7896	7909	8032	8034	8035	8036	8037	8038	8039	8070	8071	8072	8145	8164	8176	8178	8198	8201	8215	8216	8227	8231	8233	8260	8261	8262	8263	8264	8267	8270	8271	8273	8275	8278	8306	8311	8324	8347	8380	8381	8382	8383	8384	8385	8387	8388	8389	8390	8391	8443	8444	8465	8483	8484	8487	8488	8612	8613	8614	8615	8630	8642	8652	8653	8656	8659	8770	8795	8805	8823	8835	8836	8843	8885	8891	8900	8904	8933	8935	8936	8937	8938	8940	8942	8944	8949	8950	8951	8954	8972	8976	8991	9034	9095	9096	9097	9156	9157	9174	9179	9183	9197	9212	9228	9251	9274	9281	9288	9290	9316	9317	9318	9319	9320	9321	9329	9331	9382	9383	9420	9421	9434	9435	9436	9437	9478	9492	9506	9520	9522	9539	9540	9542	9543	9550	9616	9624	9631	9723	9765	9799	9800	9821	9850	9854	10091	10099	10157	10167	10237	10243	10249	10286	10293	10294	10310	10311	10355	10385	10436	10503	10510	10511	10548	10582	10612	10627	10632	10866	10912	10913	10914	10915	10922	10952	10957	10961	10962	10963	11074	11091	11402	11722	11725	11911	11916	11968	11978	11986	11993	12002	12004	12007	12011	12161	12168	12169	12246	12251	12310	12352	12354	12690	12696	12741	12742	12756	12875	12933	13023	13321	13341	13395	13541	13543	13729	13730	13731	13732	13753	13754	13763	13764	13765	13768	13769	13778	13802	13946	14070	14079	14184	14185	14254	14341	14470	14472	14473	14474	14508	14509	14510	14511	14513	14542	14642	14762	14814	14836	14837	14838	14894	14954	15094	15097	15099	15100	15101	15118	15120	15152	15153	15164	15174	15201	15249	15257 6300	14706	14707],1) = NaN;
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
         case '2025' %LK
         output([1501	3093	6741],2)=NaN;
         output([1501	1502	1746	2106	2121	3048	3051	4412	4413	4783	4785	4801	4811	4812	5219	6743	6787	6788	6793],3)=NaN;
         output([1129	1130	1131	1132	1133	1134	1135	1402	1403	1404	1405	1406	1407	1408	1409	1410	1411	1412	1413	1414	1415	1416	1465	1466	1468	1469	1470	1471	1472	1473	1482	1484	1485	1486	1487	1506	1507	1508	1509	1636	1646	1774	1874	1875	1876	1878	1879	1880	1883	1884	1985	1986	1987	1988	1989	1990	1991	1992	1993	1994	1995	1996	1997	1998	1999	2065	2066	2195	2196	2197	2249	2250	2251	2252	2460	2462	2661	2663	2664	2672	2697	2738	2739	2740	2767	2768	2769	2770	2771	2772	2778	3001	3004	3005	3006	3007	3009	3038	3047	3048	3049	3056	3057	3068	3072	3073	3075	3076	3077	3078	3079	3080	3081	3082	3083	3085	3086	3087	3088	3089	3091	3532	3533	3534	3537	3538	3556	3557	3558	3560	3561	3562	3563	3564	3578	3580	3581	3582	3583	3584	3586	3589	3590	3600	3602	3757	3760	3762	3765	3768	3770	3771	3772	3773	3774	3775	3776	3777	3778	3779	3780	3781	3782	3783	3784	3863	3864	3865	3866	3867	3868	3869	3939	3940	3941	3942	3945	3953	3954	4179	4181	4210	4212	4213	4215	4216	4217	4219	4220	4223	4224	4225	4226	4227	4228	4229	4231	4232	4233	4243	4245	4246	4250	4400	4401	4404	4409	4415	4419	4428	4429	4430	4431	4432	4433	4434	4435	4440	4519	4520	4521	4522	4529	4530	4531	4533	4534	4535	4536	4543	4544	4545	4552	4553	4554	4555	4557	4558	4559	4560	4561	4563	4564	4565	4569	4570	4571	4572	4652	4777	4786	4789	4790	4857	4858	4860	4912	4957	4961	5024	5025	5026	5041	5044	5049	5176	5185	5203	5205	5215	5217	5221	5222	5223	5312	5314	5316	5319	5482	5491	5500	5501	5502	5504	5505	5506	5524	5527	5528	5530	5531	5535	5536	5537	5538	5539	5695	5712	5768	5791	5800	5801	5805	5811	5814	5815	5817	5867	5873	5878	5884	5898	5900	5901	5902	5936	5937	5940	5942	5943	5944	5945	5946	5947	5948	5949	5951	5958	5959	5960	5961	5962	6001	6002	6005	6007	6008	6009	6010	6014	6015	6020	6021	6022	6023	6067	6070	6103	6343	6344	6345	6346	6347	6348	6355	6356	6357	6358	6359	6360	6369	6373	6377	6388	6403	6446	6447	6490	6491	6499	6500	6501	6502	6503	6587	6731	6739	6801	6803	6804	6808	6810	6811	6812	6813	6814	6823	6824	6825	6826	6864	6949	6966	7021	7085	7199	7200	7450	7451	7452	7453	7454	7477	7481	7482	7493	7497	7500	7501	7503	7537	7591	7647	7654	7661	7663	7664	7665	7666	7667	7685	7877	7878	7882	7883	8083	8105	8106	8107	8120	8121	8122	8200	8243	8487	8488	8489	8683	8685	8794	8924	8925	8926	9004	9048	9058	9081	9102	9103	9104	9105	9178	9179],17)=NaN;
         output([1129	1130	1131	1132	1133	1134	1135	1402	1403	1404	1405	1406	1407	1408	1409	1410	1411	1412	1413	1414	1415	1416	1465	1466	1468	1469	1470	1471	1472	1473	1482	1484	1485	1486	1487	1506	1507	1508	1509	1636	1646	1774	1874	1875	1876	1878	1879	1880	1883	1884	1985	1986	1987	1988	1989	1990	1991	1992	1993	1994	1995	1996	1997	1998	1999	2065	2066	2195	2196	2197	2249	2250	2251	2252	2460	2462	2661	2663	2664	2672	2697	2738	2739	2740	2767	2768	2769	2770	2771	2772	2778	3001	3004	3005	3006	3007	3009	3038	3047	3048	3049	3056	3057	3068	3072	3073	3075	3076	3077	3078	3079	3080	3081	3082	3083	3085	3086	3087	3088	3089	3091	3532	3533	3534	3537	3538	3556	3557	3558	3560	3561	3562	3563	3564	3578	3580	3581	3582	3583	3584	3586	3589	3590	3600	3602	3757	3760	3762	3765	3768	3770	3771	3772	3773	3774	3775	3776	3777	3778	3779	3780	3781	3782	3783	3784	3863	3864	3865	3866	3867	3868	3869	3939	3940	3941	3942	3945	3953	3954	4179	4181	4210	4212	4213	4215	4216	4217	4219	4220	4223	4224	4225	4226	4227	4228	4229	4231	4232	4233	4243	4245	4246	4250	4400	4401	4404	4409	4415	4419	4428	4429	4430	4431	4432	4433	4434	4435	4440	4519	4520	4521	4522	4529	4530	4531	4533	4534	4535	4536	4543	4544	4545	4552	4553	4554	4555	4557	4558	4559	4560	4561	4563	4564	4565	4569	4570	4571	4572	4652	4777	4786	4789	4790	4857	4858	4860	4912	4957	4961	5024	5025	5026	5041	5044	5049	5176	5185	5203	5205	5215	5217	5221	5222	5223	5312	5314	5316	5319	5482	5491	5500	5501	5502	5504	5505	5506	5524	5527	5528	5530	5531	5535	5536	5537	5538	5539	5695	5712	5768	5791	5800	5801	5805	5811	5814	5815	5817	5867	5873	5878	5884	5898	5900	5901	5902	5936	5937	5940	5942	5943	5944	5945	5946	5947	5948	5949	5951	5958	5959	5960	5961	5962	6001	6002	6005	6007	6008	6009	6010	6014	6015	6020	6021	6022	6023	6067	6070	6103	6343	6344	6345	6346	6347	6348	6355	6356	6357	6358	6359	6360	6369	6373	6377	6388	6403	6446	6447	6490	6491	6499	6500	6501	6502	6503	6587	6731	6739	6801	6803	6804	6808	6810	6811	6812	6813	6814	6823	6824	6825	6826	6864	6949	6966	7021	7085	7199	7200	7450	7451	7452	7453	7454	7477	7481	7482	7493	7497	7500	7501	7503	7537	7591	7647	7654	7661	7663	7664	7665	7666	7667	7685	7877	7878	7882	7883	8083	8105	8106	8107	8120	8121	8122	8200	8243	8487	8488	8489	8683	8685	8794	8924	8925	8926	9004	9048	9058	9081	9102	9103	9104	9105	9178	9179 6374	6375	6376	6379	6380	6381	6382	6383	6384	6385	6386	6387	6389	6390	6497	6732	6733	6734	6735	6736	6737	6738	6740	6741	6742	6743	6749	6750	6751	6766	6767	6768	6773	6774	6775	6776	6777	6778	6779	6780	6781	6782	6783	6784	6785	6786	6787	6788	6789	6790	6791	6794	6798	6799	6800	6807	7087	7088	7089	7090	7091	7092	7093	7094	7095	7096	7097	7098	7099	7100	7101	7102	7103	7104	7105	7106	7107	7108	7109	7478	7479	7494	7495	7496	7504	7536	7653	7660	7881	8686	8687	8793	9047	9051	9052	9055	9056	9057	9082	9099	9101	9106	9107	9180	9181	9183	9184	9186	9187	9188	9189	9190	9207	9230 993	1100	1125	1126	1136	1371	1459	1462	1463	1474	1475	1477	1478	1479	1481	1501	1502	1503	1504	1505	1577	1578	1581	1584	1615	1630	1631	1632	1647	1982	2064	2198	2199	2204	2209	2214	2215	2219	2220	2222	2223	2224	2225	2226	2227	2229	2230	2238	2465	2698	2779	3045	3046	3050	3051	3063	3064	3069	3070	3071	3531	3759	3761	3763	3764	3766	3767	3769	3943	3944	3946	3947	4167	4168	4169	4170	4173	4174	4175	4176	4177	4182	4221	4222	4247	4248	4402	4403	4408	4410	4411	4412	4549	4550	4551	4773	4774	4781	4796	4798	4804	4911	4959	4960	5175	5214	5218	5219	5220	5320	5498	5499	5525	5526	5792	5802	5803	5804	5806	5807	5808	5809	5810	5812	5816	5868	5869	5870	5871	5872	5874	5875	5876	5877	5879	5880	5881	5882	5883	5886	5887	5888	5889	5890	5891	5892	5893	5894	5895	5896	5897	5934	5935	5938	5956	5957	5999	6000	6003	6004	6011	6012	6013	6016	6017	6018	6068	6069 1458	1460	1773	1979	1980	1981	2063	3575	3576	3577	4782	4783	4784	4785	4791	4792	4793	4794	4910],18)=NaN;
         output([843	844	6742	6746	6755],19)=NaN;
         output([5	7	8	9	10	1753	1754	1755	1756	1757	1758	1759	1760	1761	1762	1763	1764	1765	1766	1767	2070	2071	2072	2073	2074	2075	2076	2077	2078	2079	2080	2081	2082	2083	2084	2085	2086	2087	2088	2089	2090	2091	2092	2093	2094	2095	2096	2097	2099	2100	2105	2234	2236	2242	3055	3080	3092	3093	3094	4263	4800	4829	4830	6025	6110	6111	6112	6113	6114	6115	6116	6117	6118	6119	6120	6121	6122	6123	6124	6125	6126	6127	6128	6129	6130	6131	6132	6133	6134	6135	6136	6137	6138	6139	6140	6141	6142	6143	6144	6145	6146	6147	6148	6149	6150	6151	6152	6153	6154	6155	6156	6157	6158	6159	6160	6161	6162	6163	6164	6165	6166	6167	6168	6169	6170	6171	6172	6758	6764	7111	7112	7113	7114	7115	7116	7117	7118	7119	7120	7121	7122	7123	7124	7125	7126	7127	7128	7129	7130],21)=NaN;
         output([1753	1754	1755	1756	1757	1758	1759	1760	1761	1762	1763	1764	1765	1766	1767	2070	2071	2072	2073	2074	2075	2076	2077	2078	2079	2080	2081	2082	2083	2084	2085	2086	2087	2088	2089	2090	2091	2092	2093	2094	2095	2096	2097	2099	2100	6034	6036	6037	6038	6039	6110	6111	6112	6113	6114	6115	6116	6117	6118	6119	6120	6121	6122	6123	6124	6125	6126	6127	6128	6129	6130	6131	6132	6133	6134	6135	6136	6137	6138	6139	6140	6141	6142	6143	6144	6145	6146	6147	6148	6149	6150	6151	6152	6153	6154	6155	6156	6157	6158	6159	6160	6161	6162	6163	6164	6165	6166	6167	6168	6169	6170	6171	6172	6741	6742	6743	6753	6757	6759	6760	6761	6762	6763	6769	6770	6771	6796	7111	7112	7113	7114	7115	7116	7117	7118	7119	7120	7121	7122	7123	7124	7125	7126	7127	7128	7129	7130],22)=NaN;
         output([956	958	994	995	996	997	998	999	1000	1001	1002	1003	1004	1005	1006	1007	1008	1009	1010	1011	1012	1013	1014	1015	1016	1017	1018	1019	1020	1021	1022	1023	1024	1025	1026	1027	1028	1029	1030	1031	1032	1033	1034	1036	1750	1751	6034	6036	6040	6110	6111	6112	6113	6114	6115	6116	6117	6118	6119	6120	6121	6122	6123	6124	6125	6126	6127	6128	6129	6130	6131	6132	6133	6134	6135	6136	6137	6138	6139	6140	6141	6142	6143	6144	6145	6146	6147	6148	6149	6150	6151	6152	6153	6154	6155	6156	6157	6158	6159	6160	6161	6162	6163	6164	6165	6166	6167	6168	6169	6170	6171	6172],27)=NaN;
             
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