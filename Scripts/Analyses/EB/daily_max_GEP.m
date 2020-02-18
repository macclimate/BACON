ls = addpath_loadstart;
load([ls 'Matlab/Data/Master_Files/TPD/TPD_data_master.mat']);

GEP_filled = master.data(:,132);
GEP_sum_daily = mean(reshape(GEP_filled,48,[]),1)';

NEE= master.data(:,7);
NEE_filled = master.data(:,134);
R = master.data(:,133);

NEE_pass = NaN.*ones(length(NEE),1);

ind = find(NEE==NEE_filled);
NEE_pass(ind) = NEE(ind);

plot(NEE_pass)

GEP_pass = R - NEE_pass;

GEP_max = max(reshape(GEP_pass,48,[]))';

figure(3);clf;
plot(GEP_max,'bo');
hold on;
plot(GEP_sum_daily,'ro')

figure(4);clf;
plot(GEP_max, GEP_sum_daily,'k.');