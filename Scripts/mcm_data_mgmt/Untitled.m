site = 'TP02';
ls = addpath_loadstart;
load_path = [ls 'Matlab/Data/Master_Files/' site '/' site '_data_master.mat'];
%%% Load the master file:
load(load_path);

Ta = master.data(:,72);
Ts = master.data(:,80);

%%
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
%%
f3 = figure(3);
plot(master.data(:,1)+master.data(:,6)/366,master.data(:,85));

%% Predicted RE (110, 113, 116, 119, 122
f4 = figure(4);
plot(master.data(:,1)+master.data(:,6)/366,master.data(:,110));


%%
plot(master.data(:,1)+master.data(:,6)/366,master.data(:,103),'b')
plot(master.data(:,1)+master.data(:,6)/366,master.data(:,114),'b')