%%% Load TP02 Master file: 

ls = addpath_loadstart; 

%% Load PAR Down
%%% Load previous years data
current_year = 2024; % update this year each 
load([ls '/Matlab/Data/Master_Files/TP02/TP02_data_master.mat']);
Year = master.data(:,1);
dt = master.data(:,6);
year_plot = Year + (dt-min(dt))./366;
PARDn = master.data(:,39);

%%% Load current year's data (2020)
data_current = load([ls '/Matlab/Data/Met/Cleaned3/TP02/TP02_master_' num2str(current_year) '.mat']);
%%% Substitute 2020 PAR into the master file (remove this when
PARDn(Year==current_year) = data_current.master.data(:,5);

%%%% Plot for inspection
figure(2);clf;
plot(year_plot,PARDn,'b-');


PARDn_2017_sort = sort(PARDn(Year==2017),'descend');
PARDn_2017_sort = PARDn_2017_sort(~isnan(PARDn_2017_sort ));
PARDn_2018_sort = sort(PARDn(Year==2018),'descend');
PARDn_2018_sort = PARDn_2018_sort(~isnan(PARDn_2018_sort ));
PARDn_2019_sort = sort(PARDn(Year==2019),'descend');
PARDn_2019_sort = PARDn_2019_sort(~isnan(PARDn_2019_sort ));
PARDn_2020_sort = sort(PARDn(Year==2020),'descend');
PARDn_2020_sort = PARDn_2020_sort(~isnan(PARDn_2020_sort ));
PARDn_2021_sort = sort(PARDn(Year==2021),'descend');
PARDn_2021_sort = PARDn_2021_sort(~isnan(PARDn_2021_sort ));
PARDn_2022_sort = sort(PARDn(Year==2022),'descend');
PARDn_2022_sort = PARDn_2022_sort(~isnan(PARDn_2022_sort ));
PARDn_2023_sort = sort(PARDn(Year==2023),'descend');
PARDn_2023_sort = PARDn_2023_sort(~isnan(PARDn_2023_sort ));
PARDn_2024_sort = sort(PARDn(Year==2024),'descend');
PARDn_2024_sort = PARDn_2024_sort(~isnan(PARDn_2024_sort ));
% PARDn_2019 = PARDn(Year==2019);


%% 2018 correction factors

% linear relationship between 2017 and 2018 data: 

figure(1);clf
plot(PARDn_2017_sort(1:10000),PARDn_2018_sort(1:10000),'.');
p_2018 = polyfit(PARDn_2017_sort(1:10000),PARDn_2018_sort(1:10000),1);

pcf_2018 = 1/p_2018(1); % = 0.585666951857723

%% 2019 PAR correction factor
figure(1);clf
plot(PARDn_2017_sort(1:10000),PARDn_2019_sort(1:10000),'.');
p_2019 = polyfit(PARDn_2017_sort(1:10000),PARDn_2019_sort(1:10000),1);

pcf_2019 = 1/p_2019(1); % = 0.568972797317526


%% 2020 PAR correction factor
figure(1);clf
plot(PARDn_2017_sort(1:10000),PARDn_2020_sort(1:10000),'.');
p_2020 = polyfit(PARDn_2017_sort(1:10000),PARDn_2020_sort(1:10000),1);

pcf_2020 = 1/p_2020(1); % = 0.560100471025222

%% 2021 PAR correction factor
figure(1);clf
plot(PARDn_2017_sort(1:10000),PARDn_2021_sort(1:10000),'.');
p_2021 = polyfit(PARDn_2017_sort(1:10000),PARDn_2021_sort(1:10000),1);

pcf_2021 = 1/p_2021(1); % = 0.538677529088550

%% 2022 PAR correction factor
figure(1);clf
plot(PARDn_2017_sort(1:10000),PARDn_2022_sort(1:10000),'.');
p_2022 = polyfit(PARDn_2017_sort(1:10000),PARDn_2022_sort(1:10000),1);

pcf_2022 = 1/p_2022(1); % = 0.439130078950065

%% 2023 PAR correction factor
figure(1);clf
plot(PARDn_2017_sort(1:10000),PARDn_2023_sort(1:10000),'.');
p_2023 = polyfit(PARDn_2017_sort(1:10000),PARDn_2023_sort(1:10000),1);

pcf_2023 = 1/p_2023(1); % = 0.429167158196256

%% 2024 PAR correction factor
figure(1);clf
plot(PARDn_2017_sort(1:10000),PARDn_2024_sort(1:10000),'.');
p_2024 = polyfit(PARDn_2017_sort(1:10000),PARDn_2024_sort(1:10000),1);

pcf_2024 = 1/p_2024(1); % = 



%% All correction factors
% par_correction_factor = [2002, 1.23; 2013, 1.38199647061725; 2014, 1.26172364359607; 2015,1.03313933608525; 2016,0.874165785537350; 2017,0.659991285147933];
par_correction_factor = [2002, 1.23; 2013, 1.38199647061725; 2014, 1.26172364359607; 2015,1.03313933608525; 2016,0.874165785537350; 2017,0.659991285147933; 2018,0.585666951857723; 2019,0.568972797317526; ...
									2020, 0.560100471025222; 2021, 0.538677529088550; 2022, 0.439130078950065; 2023, 0.429167158196256];
