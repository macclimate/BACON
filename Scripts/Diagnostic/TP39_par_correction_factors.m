%%% Load TP39 Master file: 

ls = addpath_loadstart; 

load([ls '/Matlab/Data/Master_Files/TP39/TP39_data_master.mat']);

% Load PAR Down
Year = master.data(:,1);
SWDn = master.data(:,41);
PARDn = master.data(:,47);
 
clrs = colormap(jet(20));
figure(1); clf
ctr = 1;
for year = 2003:1:2018
    ind = find(Year == year & ~isnan(SWDn) & ~isnan(PARDn));
    figure(1);
    h(ctr,1) = plot(SWDn(ind,1),PARDn(ind,1),'.','MarkerFaceColor',clrs(ctr,:)); hold on;
%     s = input('pause','s');
p(ctr,:) = polyfit(SWDn(ind,1),PARDn(ind,1),1);
    ctr = ctr + 1;
end
xlabel('SWDn')
ylabel('PARDn');
legend(h,num2str((2003:1:2018)'));

% PARDn_2017_sort = sort(PARDn(Year==2017),'descend');
% PARDn_2017_sort = PARDn_2017_sort(~isnan(PARDn_2017_sort ));
% PARDn_2018_sort = sort(PARDn(Year==2018),'descend');
% PARDn_2018_sort = PARDn_2018_sort(~isnan(PARDn_2018_sort ));
% 
% % PARDn_2019 = PARDn(Year==2019);
% 
% 
% % linear relationship between 2017 and 2018 data: 
% figure(1);
% plot(PARDn_2017_sort(1:10000),PARDn_2018_sort(1:10000),'.');
% p_2018 = polyfit(PARDn_2017_sort(1:10000),PARDn_2018_sort(1:10000),1);
% 
% pcf_2018 = 1/p_2018(1); % = 0.585666951857723
% % 2018 correction factors
% par_correction_factor = [2002, 1.23; 2013, 1.38199647061725; 2014, 1.26172364359607; 2015,1.03313933608525; 2016,0.874165785537350; 2017,0.659991285147933];
