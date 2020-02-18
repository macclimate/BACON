site = 'TP02';
ls = addpath_loadstart;
load_path = [ls 'Matlab/Data/Master_Files/' site '/' site '_data_master.mat'];

%%% Load the master file:
load(load_path);
%%% Load the gapfilling file: 
gapfilling_master = load([ls 'Matlab\Data\Flux\Gapfilling\' site '\NEE_GEP_RE\Default\' site '_Gapfill_NEE_default.mat']);


Ta = master.data(:,72);
Ts = master.data(:,80);

%% 20-August
clrs = colormap(parula(10));
f1 = figure(1);
clf(f1);
f2 = figure(2);
clf(f2);
f5 = figure(5);
clf(f5);
f6 = figure(6);
clf(f6);

plot_ctr = 1;
for year = 2010:1:2018
    yr{plot_ctr,1} = num2str(year);
    ind = find(master.data(:,1)==year);
    figure(f1);
    subplot(3,3,plot_ctr);
    plot(Ta(ind,1),Ts(ind,1),'.','Color',clrs(plot_ctr,:));
    xlabel('Ta');ylabel('Ts'); title(num2str(year));
    axis([-10 35 -10 35]); grid on;
    
    ind2 = find(master.data(:,1)==year & Ta > -5);
    p(plot_ctr,:) = polyfit(Ta(ind2,1),Ts(ind2,1),1);
    
    figure(f2);
    h2(plot_ctr,1) = plot([-5:5:35],polyval(p(plot_ctr,:),[-5:5:35]),'-','Color',clrs(plot_ctr,:),'LineWidth',2);
    hold on;
    
    figure(f5)
    h5(plot_ctr,1) = plot(master.data(ind,110),'-','Color',clrs(plot_ctr,:));
    hold on;
    
    figure(f6)
    h6(plot_ctr,1) = plot(Ts(ind,1),'-','Color',clrs(plot_ctr,:));
    hold on;
    
    plot_ctr = plot_ctr + 1;    
end
figure(f2);
legend(h2,yr, 'Location','NorthWest');
xlabel('Ta');ylabel('Ts');  

figure(f5);
legend(h5,yr, 'Location','NorthWest');

figure(f6);
legend(h6,yr, 'Location','NorthWest');
%%%
f3 = figure(3);
plot(master.data(:,1)+master.data(:,6)/366,master.data(:,85));

%%% Predicted RE (110, 113, 116, 119, 122
f4 = figure(4);
plot(master.data(:,1)+master.data(:,6)/366,master.data(:,110));

%%%
plot(master.data(:,1)+master.data(:,6)/366,master.data(:,103),'b')
plot(master.data(:,1)+master.data(:,6)/366,master.data(:,114),'b')

%% 27-Aug - 
clear f1 f2 h2 clrs
gf_model_num = 1;
year = gapfilling_master.master(gf_model_num).Year;
NEE_clean = gapfilling_master.master(gf_model_num).NEE_clean;
NEE_filled = gapfilling_master.master(gf_model_num).NEE_filled;
RE_pred = gapfilling_master.master(gf_model_num).RE_pred;
RE_filled = gapfilling_master.master(gf_model_num).RE_filled;

f1 = figure(1); clf(f1);
ind = find(RE_pred~=RE_filled);
plot(RE_pred,'b'); hold on;
plot(ind,RE_filled(ind),'ro');

clrs = colormap(parula(12));
f2 = figure(2); clf(f2);
num_RE_pts = [];
clr_ctr = 1;
for yr = 2008:1:2018
    ind2 = find(year==yr & RE_pred~=RE_filled);
    num_RE_pts(size(num_RE_pts,1)+1,:) = [yr length(ind2)];
    plot(Ts(ind2),RE_filled(ind2),'.','Color',clrs(clr_ctr,:));hold on;
    [x_out, y_out] = plot_TsQ10(gapfilling_master.master(1).c_hat(clr_ctr).RE(1:2), 0);
    h2(clr_ctr) = plot(x_out, y_out,'-','Color',clrs(clr_ctr,:),'LineWidth',2);
    clr_ctr = clr_ctr+1;
end
legend(h2,num2str((2008:1:2018)'),'Location','NorthWest');
axis([-5 30 0 20]);
ylabel('RE umol CO2 m-2 s-1')
xlabel('Ts @ 5cm')

T = table(num_RE_pts(:,1),num_RE_pts(:,2),'VariableNames',{'Year';'num_RE_pts'});