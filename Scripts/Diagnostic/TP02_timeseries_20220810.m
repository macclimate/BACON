load('D:\Matlab\Data\Flux\Gapfilling\TP02\NEE_GEP_RE\Default\TP02_Gapfill_NEE_default.mat');
[clrs, guide] = jjb_get_plot_colors;
clrs = [clrs(1,:); clrs(3,:);clrs(11,:);clrs(1,:); clrs(3,:);clrs(11,:);clrs(1,:); clrs(3,:);clrs(11,:)];
linetype = {'-','-','-','--','--','--',':',':',':'};

% Make a dt vector from Year
dt = master(1).Year;
for i = 2002:1: 2021
   allpts = find(master(1).Year == i);
   interval = 1/(length(allpts));
   to_add = (0:interval:1)';
   dt(allpts) = dt(allpts) + to_add(1:end-1);
    
end


%% NEE filled timeseries
f1 = figure(1);clf;
for i = 1:1:size(master,2)
  h1(i) = plot(dt,master(i).NEE_filled,'Color',clrs(i,:),'LineStyle',linetype{i}); hold on;
  labels{i,1} = master(i).tag;
  
  %%% Annual sum
  j = 1;
  for yr = 2008:1:2021
  NEE_sum(j,i) = sum(master(i).NEE_filled(master(i).Year == yr)).*0.0218;
  RE_sum(j,i) = sum(master(i).RE_filled(master(i).Year == yr)).*0.0218;
  GEP_sum(j,i) = sum(master(i).GEP_filled(master(i).Year == yr)).*0.0218;
  
  j = j + 1;
  end
end
legend(h1,labels)
ylabel('NEE')
xlabel('year')

%% NEE Cleaned
f2 = figure(2);clf;
labels2 = {'nofp','region','inbnds'}
plot(dt,master(7).NEE_clean,'b');
hold on;
plot(dt,master(1).NEE_clean,'r');
plot(dt,master(4).NEE_clean,'g');
legend(labels2);
ylabel('NEE')
xlabel('year')

%% Annual sums
f3 = figure(3);clf;

for i = 1:1:size(NEE_sum,2)    
subplot(3,1,1)    
h2(i) = plot(2008:1:2021,NEE_sum(:,i),'Color',clrs(i,:),'LineStyle',linetype{i});hold on;

subplot(3,1,2)    
plot(2008:1:2021,RE_sum(:,i),'Color',clrs(i,:),'LineStyle',linetype{i});hold on;
subplot(3,1,3)    
plot(2008:1:2021,GEP_sum(:,i),'Color',clrs(i,:),'LineStyle',linetype{i});hold on;
end

legend(h2,labels,'Location','best')
subplot(3,1,1); ylabel('NEE - gC')
subplot(3,1,2); ylabel('RE - gC')
subplot(3,1,3); ylabel('GEP - gC')

xlabel('year')

%% save figures
savefig(f1,'D:\Google Drive\Mac Climate - Shared Data\03 - TPFS Data\temp\TP02-NEE-filled','compact');
savefig(f2,'D:\Google Drive\Mac Climate - Shared Data\03 - TPFS Data\temp\TP02-NEE-cleaned','compact');
savefig(f3,'D:\Google Drive\Mac Climate - Shared Data\03 - TPFS Data\temp\NEE-annual-sums','compact');
