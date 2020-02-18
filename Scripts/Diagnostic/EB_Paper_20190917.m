TP39 = load("\\130.113.210.243\fielddata\Matlab\Data\Master_Files\TP39\TP39_data_master.mat");
TPD = load("\\130.113.210.243\fielddata\Matlab\Data\Master_Files\TPD\TPD_data_master.mat");

close all;
clrs = colormap(parula(7));
ctr = 1;
for i = 2012:1:2018
  TP39_cum = -0.0216.*cumsum(TP39.master.data(TP39.master.data(:,1)==i,161));
  TPD_cum = -0.0216.*cumsum(TPD.master.data(TPD.master.data(:,1)==i,134));
  
    TP39_cum(:,2) = 0.0216.*cumsum(TP39.master.data(TP39.master.data(:,1)==i,159));
  TPD_cum(:,2) = 0.0216.*cumsum(TPD.master.data(TPD.master.data(:,1)==i,132));
  
  TP39_cum(:,3) = 0.0216.*cumsum(TP39.master.data(TP39.master.data(:,1)==i,160));
  TPD_cum(:,3) = 0.0216.*cumsum(TPD.master.data(TPD.master.data(:,1)==i,133));
  
  for k = 1:1:3
  figure(k)
  subplot(2,1,1)
  plot(TP39_cum(:,k),'Color',clrs(ctr,:));hold on;
  subplot(2,1,2)
  plot(TPD_cum(:,k),'Color',clrs(ctr,:));hold on;

  end
  ctr = ctr + 1;
end

for k = 1:1:3
  figure(k)
  legend(num2str((2012:1:2018)'));
end