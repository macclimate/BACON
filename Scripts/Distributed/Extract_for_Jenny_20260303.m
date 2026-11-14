clearvars;
load('D:\Matlab\Data\Master_Files\TPU\TPU_data_master.mat');

start_year = 2025;
end_year = 2026;
yr = master.data(:,1);
data_in = master.data(yr>=start_year & yr<=end_year,:);
to_export = find(strcmp(master.labels(:,15),'NaN')==0);
data_out = data_in(:,to_export);
data.labels = master.labels(to_export,:);
data.table = data_out;
data.site = 'TPU';
for i = 1:1:size(to_export,1)
    header{i,1} = [master.labels{to_export(i),1} '(' master.labels{to_export(i),2} ')']; 
end

% Create the table directly by mapping data to the labels
T = array2table(data_out, 'VariableNames', header);

% Write the table to an Excel file
writetable(T, 'D:\Matlab\Data\Master_Files\TPU\TPU_Jenny.xlsx');

save('D:\Matlab\Data\Master_Files\TPU\TPU_Jenny.mat','data');